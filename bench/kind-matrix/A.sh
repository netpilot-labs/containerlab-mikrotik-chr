. ~/m/lib.sh; T=${CHR_TAG:-7.24.5}; R1=clab-a-r1; R2=clab-a-r2; H1=clab-a-h1
cd ~/m/A && sed "s#\${CHR_TAG:=7.24.5}#$T#" a.clab.yml > a-$T.clab.yml && grep -q "mikrotik/chr:$T" a-$T.clab.yml || { echo "tag file broken"; exit 1; }
$CLAB deploy -t a-$T.clab.yml --reconfigure > /tmp/a-deploy.txt 2>&1; echo "[$T] deploy rc=$?"
wait_healthy $R1 300; wait_healthy $R2 120
check "[$T] ssh login (10 s timeout) works the moment r1 is healthy" "sshpass -p admin ssh $SSHO admin@\$(ip_of $R1) '/system identity print' | grep -q 'name: r1'"
check "[$T] version" "ros $R1 admin admin '/system resource print' | grep -q 'version: $T'"
check "[$T] ssh r1 identity" "ros $R1 admin admin '/system identity print' | grep -q 'name: r1'"
check "[$T] ssh r2 (lab default route in main)" "ros $R2 admin admin '/system identity print' | grep -q 'name: r2'"
check "[$T] REST :80" "curl -s -m 10 -u admin:admin http://\$(ip_of $R1)/rest/system/identity | grep -q '\"name\":\"r1\"'"
for p in 21 23 8291 8728; do check "[$T] tcp $p forwarded" "nc -z -w 5 \$(ip_of $R1) $p"; done
check "[$T] serial console telnet :5000" "(sleep 2; printf '\r'; sleep 3) | nc -w 6 \$(ip_of $R1) 5000 | grep -a -q -i -E 'login|MikroTik|r1'"
check "[$T] blank factory password rejected" "! curl -s -f -m 10 -u admin: http://\$(ip_of $R1)/rest/system/identity"
check "[$T] ether2 alias -> 10.0.0.1/30" "ros $R1 admin admin '/ip address print terse' | grep -q '10.0.0.1/30.*ether2'"
check "[$T] ether4 (gap) -> 192.168.10.1/24" "ros $R1 admin admin '/ip address print terse' | grep -q '192.168.10.1/24.*ether4'"
check "[$T] ether3 present (gap keeps numbering)" "ros $R1 admin admin '/interface print terse' | grep -q 'name=ether3'"
check "[$T] r1 ping r2" "ros $R1 admin admin '/ping 10.0.0.2 count=3' | grep -q 'received=3'"
check "[$T] h1 ping r2 loopback through r1" "sudo docker exec $H1 ping -c 3 -W 2 2.2.2.2"
check "[$T] LLDP/MNDP neighbor" "ros $R1 admin admin '/ip neighbor print detail' | grep -q 'identity=\"r2\"'"
check "[$T] tap MTU = veth MTU" "[ \"\$(sudo docker exec $R1 cat /sys/class/net/eth1/mtu)\" = \"\$(sudo docker exec $R1 cat /sys/class/net/tap1/mtu)\" ]"
check "[$T] r2: mgmt table default + lab default in main" "ros $R2 admin admin '/ip route print terse where dst-address=0.0.0.0/0' | grep -q 'routing-table=mgmt' && ros $R2 admin admin '/ip route print terse where dst-address=0.0.0.0/0' | grep -q 'gateway=10.0.0.1'"
check "[$T] docker health = healthy" "[ \"\$(health $R1)\" = healthy ] && [ \"\$(health $R2)\" = healthy ]"
check "[$T] launcher in labdir matches the bind" "[ \"\$(sudo sha256sum < ~/m/A/clab-a/r1/chr-launch.sh)\" = \"\$(sudo docker exec $R1 cat /chr-launch.sh | sha256sum)\" ]"
