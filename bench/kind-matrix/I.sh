. ~/m/lib.sh; R1=clab-imax-r1
cd ~/m/I && $CLAB deploy -t max.clab.yml --reconfigure > /tmp/i-deploy.txt 2>&1; echo "ether256 deploy rc=$?"
wait_healthy $R1 900
sudo docker logs $R1 2>&1 | grep chr-launch | grep -E "qemu started|ready"
check "limit: ether256 deploys, RouterOS shows 256 ethernet interfaces" "[ \$(ros $R1 admin admin '/interface ethernet print count-only' | tr -dc 0-9) = 256 ]"
check "limit: traffic over ether256 (h1 -> r1)" "sudo docker exec clab-imax-h1 ping -c 3 -W 2 10.56.0.1"
$CLAB destroy -t max.clab.yml --cleanup >/dev/null 2>&1
$CLAB deploy -t over.clab.yml > /tmp/i-over.txt 2>&1; rc=$?; echo "ether257 deploy rc=$rc"
sed 's/\x1b\[[0-9;]*m//g' /tmp/i-over.txt | grep -i -E "ether257|interface|error" | head -3
check "limit: ether257 refused at deploy with a non-zero exit" "[ $rc != 0 ]"
check "limit: ether257 error names the interface" "grep -q 'ether257' /tmp/i-over.txt"
check "limit: no container left behind" "! sudo docker ps -a --format '{{.Names}}' | grep -q '^clab-iover-'"
$CLAB destroy -t over.clab.yml --cleanup >/dev/null 2>&1
