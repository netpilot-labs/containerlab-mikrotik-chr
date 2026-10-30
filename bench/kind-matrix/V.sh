# Management VRF (containerlab PR #3547). V.sh [main]: main prints the control lines. CHR_TAG picks the version
. ~/m/lib.sh; T=${CHR_TAG:-7.24.5}; B=${1:-pr}; R1=clab-a-r1; R2=clab-a-r2; H1=clab-a-h1
[ "$1" = main ] && CLAB="sudo $HOME/clab-main"
sv() { ros $1 admin admin ":put [/ip service get $2 vrf]" | tr -d ' \n'; }
sn() { ros $1 admin admin ':put [/snmp get vrf]' | tr -d ' \n'; }
hport() { sudo docker exec $H1 nc -z -w 3 192.168.10.1 $1; }
offnet() { curl -s -m 8 --interface 198.51.100.1 -u admin:admin http://$(ip_of $1)/rest/system/identity | grep -q name; }
snmpq() { sudo docker run --rm --network clab alpine:3.20 sh -c "apk add -q net-snmp-tools >/dev/null 2>&1; snmpget -v2c -c $2 -t 3 -r 1 $(ip_of $1) 1.3.6.1.2.1.1.5.0" 2>&1 | grep -q STRING; }
cd ~/m/A && sed "s#\${CHR_TAG:=7.24.5}#$T#" a.clab.yml > v-$T.clab.yml
sudo docker pull -q mikrotik/chr:$T >/dev/null; sudo ip addr add 198.51.100.1/32 dev lo 2>/dev/null
$CLAB deploy -t v-$T.clab.yml --reconfigure > /tmp/v-deploy.txt 2>&1; echo "[$B][$T] deploy rc=$?"; wait_healthy $R1 400; wait_healthy $R2 200
ros $R2 admin admin '/snmp set enabled=yes' >/dev/null; ros $R2 admin admin '/snmp community add name=labcomm' >/dev/null
if [ "$1" = main ]; then
  echo "CONTROL [$T]: offnet REST r2=$(offnet $R2 && echo ok || echo FAIL), SNMP=$(snmpq $R2 public && echo ok || echo FAIL), ssh on data ip=$(hport 22 && echo open || echo closed), ftp mgmt=$(nc -z -w 3 $(ip_of $R1) 21 && echo open || echo closed)"
  $CLAB destroy -t v-$T.clab.yml --cleanup >/dev/null 2>&1; exit 0
fi
sudo docker logs $R1 2>&1 | grep -E 'VRF' | head -3
check "[$B][$T] ether1 in VRF mgmt, table dynamic" "ros $R1 admin admin '/ip vrf print terse' | grep -q 'name=mgmt.*interfaces=ether1'"
check "[$B][$T] ssh www www-ssl api api-ssl winbox telnet + snmp in mgmt" "for s in ssh www www-ssl api api-ssl winbox telnet; do [ \$(sv $R1 \$s) = mgmt ] || exit 1; done; [ \$(sn $R1) = mgmt ]"
check "[$B][$T] mgmt v4+v6 default routes, connected route in mgmt" "ros $R1 admin admin '/ip route print terse where routing-table=mgmt' | grep -q 'dst-address=0.0.0.0/0' && ros $R1 admin admin '/ipv6 route print terse where routing-table=mgmt' | grep -q 'dst-address=::/0'"
check "[$B][$T] no routing rules left" "[ \$(ros $R1 admin admin '/routing rule print count-only' | tr -dc 0-9) = 0 ]"
check "[$B][$T] ssh over IPv6 (r2, lab default in main)" "sshpass -p admin ssh $SSHO admin@\$(sudo docker inspect -f '{{range .NetworkSettings.Networks}}{{.GlobalIPv6Address}}{{end}}' $R2) ':put ok' | grep -q ok"
check "[$B][$T] REST from off-subnet client with a lab default in main (r2)" "offnet $R2"
check "[$B][$T] SNMP v2c on mgmt (r2)" "snmpq $R2 public"
check "[$B][$T] data plane h1 -> r2 loopback" "sudo docker exec $H1 ping -c 3 -W 2 2.2.2.2"
check "[$B][$T] ssh not answering on a data interface" "! hport 22"
ftp=$(nc -z -w 3 $(ip_of $R1) 21 && echo open || echo closed); echo "INFO [$B][$T] ftp on mgmt IP: $ftp, on data IP: $(hport 21 && echo open || echo closed)"
ros $R1 admin admin '/ip service set api vrf=main' >/dev/null; ros $R1 admin admin '/ip service disable telnet' >/dev/null
n=$(nmark $R1 'RouterOS ready'); $CLAB restart -t v-$T.clab.yml --node r1 >/dev/null 2>&1; wait_new_marker $R1 'RouterOS ready' $n 300
check "[$B][$T] restart --node: override + disabled service kept, one ether1 address" "[ \$(sv $R1 api) = main ] && [ \$(sv $R1 ssh) = mgmt ] && [ \$(ros $R1 admin admin ':put [/ip service get telnet disabled]' | tr -d ' \n') = true ] && [ \$(ros $R1 admin admin '/ip address print count-only where interface=ether1' | tr -dc 0-9) = 1 ]"
check "[$B][$T] api override answers on data interface" "hport 8728"
check "[$B][$T] restart --node: mgmt routes not duplicated (one v4 default, one v6 default)" "[ \$(ros $R1 admin admin '/ip route print count-only where comment=clab-mgmt' | tr -dc 0-9) = 1 ] && [ \$(ros $R1 admin admin '/ipv6 route print count-only where comment=clab-mgmt' | tr -dc 0-9) = 1 ]"
ros $R1 admin admin '/ip vrf add name=blue interfaces=ether3' >/dev/null
$CLAB save -t v-$T.clab.yml > /tmp/v-save.txt 2>&1; rc=$?
check "[$B][$T] save rc=0 per node" "[ $rc = 0 ] && [ \$(grep -c 'Saved configuration' /tmp/v-save.txt) = 2 ]"
for n in r1 r2; do sudo cp clab-a/$n/ftpboot/config.auto.rsc $n-v.rsc; done; sudo chown $USER *-v.rsc
sed -e 's/r1.rsc/r1-v.rsc/; s/r2.rsc/r2-v.rsc/' v-$T.clab.yml > v-saved.clab.yml
$CLAB destroy -t v-$T.clab.yml --cleanup >/dev/null 2>&1; $CLAB deploy -t v-saved.clab.yml > /tmp/v-redeploy.txt 2>&1; wait_healthy $R1 400; wait_healthy $R2 200
sudo docker logs $R1 2>&1 | grep -E 'import' | tail -1; sudo docker logs $R2 2>&1 | grep -E 'import' | tail -1
check "[$B][$T] redeploy: import ok on both, api override + telnet off kept" "! sudo docker logs $R1 2>&1 | grep -q FAILED && ! sudo docker logs $R2 2>&1 | grep -q FAILED && [ \$(sv $R1 api) = main ] && [ \$(ros $R1 admin admin ':put [/ip service get telnet disabled]' | tr -d ' \n') = true ]"
check "[$B][$T] redeploy: user VRF blue on ether3 kept, one mgmt VRF" "ros $R1 admin admin '/ip vrf print terse' | grep -q 'name=blue' && [ \$(ros $R1 admin admin '/ip vrf print count-only where name=mgmt' | tr -dc 0-9) = 1 ]"
check "[$B][$T] redeploy: r2 snmp enabled, one labcomm community, SNMP answers" "[ \$(ros $R2 admin admin '/snmp community print count-only where name=labcomm' | tr -dc 0-9) = 1 ] && snmpq $R2 labcomm"
check "[$B][$T] redeploy: ssh + data plane" "ros $R2 admin admin ':put ok' | grep -q ok && sudo docker exec $H1 ping -c 3 -W 2 2.2.2.2"
$CLAB destroy -t v-saved.clab.yml --cleanup >/dev/null 2>&1
