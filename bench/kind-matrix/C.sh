. ~/m/lib.sh
cd ~/m/C && $CLAB deploy -t c.clab.yml --reconfigure > /tmp/c-deploy.txt 2>&1; echo "deploy rc=$?"
for n in o1 o2 o3; do wait_healthy clab-c-$n 300; done; sleep 45
check "o3: 13 ethers (ether13 alias)" "ros clab-c-o3 admin admin '/interface ethernet print count-only' | grep -q 13"
check "OSPF: o2 two Full neighbors" "[ \$(ros clab-c-o2 admin admin '/routing ospf neighbor print count-only where state=Full' | tr -dc 0-9) = 2 ]"
check "OSPF: o1 lo -> o3 lo" "ros clab-c-o1 admin admin '/ping 3.3.3.3 src-address=1.1.1.1 count=3' | grep -q 'received=3'"
$CLAB destroy -t c.clab.yml --cleanup >/dev/null 2>&1
check "destroy --cleanup: no containers" "! sudo docker ps -a --format '{{.Names}}' | grep -q '^clab-c-'"
check "destroy --cleanup: lab dir removed" "[ ! -d ~/m/C/clab-c ]"
