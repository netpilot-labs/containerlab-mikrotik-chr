. ~/m/lib.sh; R3=clab-b-r3; R4=clab-b-r4; PW='p@ss w#rd/1'
cd ~/m/B && $CLAB deploy -t b.clab.yml --reconfigure > /tmp/b-deploy.txt 2>&1; echo "deploy rc=$?"
wait_healthy $R3 300; wait_marker $R4 'import FAILED' 240; sleep 20
sudo docker logs $R4 2>&1 | grep 'import FAILED'
check "custom creds (checked at healthy): ssh netops, password with space # @ /" "ros $R3 netops '$PW' '/system identity print' | grep -q 'name: r3'"
check "custom creds: netops in group full" "ros $R3 netops '$PW' '/user print terse where name=netops' | grep -q 'group=full'"
check "custom creds: factory admin disabled" "[ \"\$(ros $R3 netops '$PW' ':put [/user get admin disabled]')\" = true ]"
check "custom creds: blank admin rejected" "! curl -s -f -m 10 -u admin: http://\$(ip_of $R3)/rest/system/identity"
check "rejected config: RouterOS reason with line" "sudo docker logs $R4 2>&1 | grep 'import FAILED' | grep -q 'line 3'"
check "rejected config: never healthy" "[ \"\$(health $R4)\" != healthy ] && ! sudo docker logs $R4 2>&1 | grep -q 'RouterOS ready'"
check "rejected config: mgmt still works (SSH within 60s; a rejected node never runs the ready wait)" "for i in \$(seq 1 6); do ros $R4 admin admin '/system identity print' | grep -q 'name: r4' && exit 0; sleep 10; done; exit 1"
check "rejected config: lines before applied" "ros $R4 admin admin '/ip address print terse' | grep -q '172.16.0.2/30'"
check "rejected config: lines after not applied" "! ros $R4 admin admin '/ip address print terse' | grep -q 4.4.4.4"
wait_healthy clab-b-r5 300
check "ssh disabled by config: healthy, no SSH wait" "! sudo docker logs clab-b-r5 2>&1 | grep -q 'SSH did not answer' && [ \"\$(health clab-b-r5)\" = healthy ]"
check "ssh disabled by config: REST works, no SSH banner" "curl -s -m 10 -u admin:admin http://\$(ip_of clab-b-r5)/rest/system/identity | grep -q r5 && ! (sleep 2 | nc -w 3 \$(ip_of clab-b-r5) 22 2>/dev/null | grep -q SSH)"
check "data plane over applied lines" "ros $R3 netops '$PW' '/ping 172.16.0.2 count=3' | grep -q 'received=3'"
$CLAB destroy -t b.clab.yml --cleanup >/dev/null 2>&1
