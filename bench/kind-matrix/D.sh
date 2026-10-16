. ~/m/lib.sh; R1=clab-a-r1; R2=clab-a-r2; H1=clab-a-h1
B1=$(macs $R1); n=$(nmark $R1 'RouterOS ready')
cd ~/m/A && $CLAB restart -t a-7.24.5.clab.yml --node r1 > /tmp/d-restart.txt 2>&1; grep -i "restored link" /tmp/d-restart.txt
wait_new_marker $R1 'RouterOS ready' $n 300; wait_healthy $R1 60
check "clab restart --node: same names + MACs" "[ \"$B1\" = \"\$(macs $R1)\" ]"
check "clab restart --node: config kept" "ros $R1 admin admin '/ip address print terse' | grep -q '192.168.10.1/24.*ether4'"
check "clab restart --node: links restored (r1->r2)" "sleep 5; ros $R1 admin admin '/ping 10.0.0.2 count=3' | grep -q 'received=3'"
check "clab restart --node: links restored (h1->r2 via r1)" "sudo docker exec $H1 ping -c 3 -W 2 2.2.2.2"
check "clab restart --node: one mgmt route (idempotent)" "[ \$(ros $R1 admin admin '/ip route print count-only where routing-table=mgmt' | tr -dc 0-9) = 1 ]"
curl -s -m 10 -u admin:admin -X POST -H 'Content-Type: application/json' -d '{}' http://$(ip_of $R2)/rest/system/reboot >/dev/null 2>&1
check "in-router reboot: went down" "for i in \$(seq 1 15); do curl -s -m 2 -u admin:admin http://$(ip_of $R2)/rest/system/identity >/dev/null || exit 0; sleep 1; done; exit 1"
check "in-router reboot: back within 2 min" "for i in \$(seq 1 12); do ros $R2 admin admin '/system identity print' | grep -q 'name: r2' && exit 0; sleep 10; done; exit 1"
check "in-router reboot: data plane" "ros $R1 admin admin '/ping 10.0.0.2 count=3' | grep -q 'received=3'"
n=$(nmark $R1 'RouterOS ready'); sudo docker restart $R1 >/dev/null; wait_new_marker $R1 'RouterOS ready' $n 300
check "docker restart: same names + MACs" "[ \"$B1\" = \"\$(macs $R1)\" ]"
check "docker restart: mgmt + config kept" "ros $R1 admin admin '/ip address print terse' | grep -q '10.0.0.1/30.*ether2'"
check "docker restart: healthy again" "sleep 8; [ \"\$(health $R1)\" = healthy ]"
