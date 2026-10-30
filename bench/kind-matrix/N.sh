# Neighbor discovery on management (containerlab PR #3546). N.sh [main] ; CHR_TAG picks the RouterOS version
has_static() { sed -e ':a' -e '/\\$/{N;s/\\\n *//;ba' -e '}' "$1" | grep -Eq 'discover-interface-list=static( |$)'; } # joins RouterOS line wraps first
. ~/m/lib.sh; T=${CHR_TAG:-7.24.5}; R1=clab-a-r1; R2=clab-a-r2
[ "$1" = main ] && CLAB="sudo $HOME/clab-main"
nb() { ros $1 admin admin "/ip neighbor print count-only where interface=$2" | tr -dc 0-9; }
pol() { ros $1 admin admin ':put [/ip neighbor discovery-settings get discover-interface-list]' | tr -d ' \n'; }
nl() { ros $1 admin admin "/interface list print count-only where name=$2" | tr -dc 0-9; }
up() { wait_healthy $R1 400; wait_healthy $R2 200; sleep 75; }   # LLDP/MNDP announce every 30 s
cd ~/m/A && sed "s#\${CHR_TAG:=7.24.5}#$T#" a.clab.yml > a-$T.clab.yml
sudo docker pull -q mikrotik/chr:$T >/dev/null
$CLAB deploy -t a-$T.clab.yml --reconfigure > /tmp/n-deploy.txt 2>&1; echo "[$T] deploy rc=$?"; up
if [ "$1" = main ]; then
  echo "CONTROL main: r1 neighbors on ether1=$(nb $R1 ether1), on ether2=$(nb $R1 ether2), policy=$(pol $R1)"
  ros $R1 admin admin '/ip neighbor print terse' | cut -c1-150
  $CLAB destroy -t a-$T.clab.yml --cleanup >/dev/null 2>&1; exit 0
fi
sudo docker logs $R1 2>&1 | grep 'neighbor discovery'
check "[$T] default: no neighbor on ether1 (r1, r2)" "[ \$(nb $R1 ether1) = 0 ] && [ \$(nb $R2 ether1) = 0 ]"
check "[$T] default: r2 seen on data link ether2" "ros $R1 admin admin '/ip neighbor print detail where interface=ether2' | grep -q 'identity=\"r2\"'"
check "[$T] default: policy clab-discovery, both lists once" "[ \$(pol $R1) = clab-discovery ] && [ \$(nl $R1 clab-management) = 1 ] && [ \$(nl $R1 clab-discovery) = 1 ]"
check "[$T] default: data plane (h1 -> r2 2.2.2.2)" "sudo docker exec clab-a-h1 ping -c 3 -W 2 2.2.2.2"
n=$(nmark $R1 'RouterOS ready'); $CLAB restart -t a-$T.clab.yml --node r1 >/dev/null 2>&1; wait_new_marker $R1 'RouterOS ready' $n 300; sleep 75
check "[$T] restart --node: policy kept, no duplicate lists, still nothing on ether1" "[ \$(pol $R1) = clab-discovery ] && [ \$(nl $R1 clab-discovery) = 1 ] && [ \$(nb $R1 ether1) = 0 ] && [ \$(nb $R1 ether2) -ge 1 ]"
# save -> clean redeploy with the default policy
$CLAB save -t a-$T.clab.yml > /tmp/n-save1.txt 2>&1; rc=$?
check "[$T] save (default) rc=0 and logged per node" "[ $rc = 0 ] && [ \$(grep -c 'Saved configuration' /tmp/n-save1.txt) = 2 ]"
for n in r1 r2; do sudo cp clab-a/$n/ftpboot/config.auto.rsc $n-saved.rsc; done; sudo chown $USER *-saved.rsc
check "[$T] saved file: discovery policy kept, no launcher objects" "grep -q 'discover-interface-list=clab-discovery' r1-saved.rsc && ! grep -q -E 'clab-mgmt|routing-table=mgmt|interface=ether1' r1-saved.rsc"
sed -e 's/r1.rsc/r1-saved.rsc/; s/r2.rsc/r2-saved.rsc/' a-$T.clab.yml > a-saved.clab.yml
$CLAB destroy -t a-$T.clab.yml --cleanup >/dev/null 2>&1; $CLAB deploy -t a-saved.clab.yml > /tmp/n-redeploy1.txt 2>&1; up
check "[$T] redeploy (default): import ok, policy + lists once, nothing on ether1, r2 on ether2" "! sudo docker logs $R1 2>&1 | grep -q FAILED && ! sudo docker logs $R2 2>&1 | grep -q FAILED && [ \$(pol $R1) = clab-discovery ] && [ \$(nl $R1 clab-discovery) = 1 ] && [ \$(nb $R1 ether1) = 0 ] && [ \$(nb $R1 ether2) -ge 1 ]"
# user opts back in to discovery on management, then save -> clean redeploy
for r in $R1 $R2; do ros $r admin admin '/ip neighbor discovery-settings set discover-interface-list=static' >/dev/null; done; sleep 75
check "[$T] opt-in (static on both): r2 now seen on ether1" "[ \$(nb $R1 ether1) -ge 1 ]"
$CLAB save -t a-saved.clab.yml > /tmp/n-save2.txt 2>&1; rc=$?
for n in r1 r2; do sudo cp clab-a/$n/ftpboot/config.auto.rsc $n-saved2.rsc; done; sudo chown $USER *-saved2.rsc
check "[$T] save (opt-in) rc=0, file has static" "[ $rc = 0 ] && has_static r1-saved2.rsc"
sed -e 's/r1.rsc/r1-saved2.rsc/; s/r2.rsc/r2-saved2.rsc/' a-$T.clab.yml > a-saved2.clab.yml
$CLAB destroy -t a-saved.clab.yml --cleanup >/dev/null 2>&1; $CLAB deploy -t a-saved2.clab.yml > /tmp/n-redeploy2.txt 2>&1; up
check "[$T] redeploy (opt-in): import ok, static kept on both, lists once, r2 seen on ether1" "! sudo docker logs $R1 2>&1 | grep -q FAILED && [ \$(pol $R1) = static ] && [ \$(pol $R2) = static ] && [ \$(nl $R1 clab-discovery) = 1 ] && [ \$(nb $R1 ether1) -ge 1 ]"
check "[$T] redeploy (opt-in): one mgmt table, data plane" "[ \$(ros $R1 admin admin '/routing table print count-only where name=mgmt' | tr -dc 0-9) = 1 ] && sudo docker exec clab-a-h1 ping -c 3 -W 2 2.2.2.2"
$CLAB destroy -t a-saved2.clab.yml --cleanup >/dev/null 2>&1
