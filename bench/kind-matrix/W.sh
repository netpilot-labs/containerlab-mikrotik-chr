# A node deployed by main, restarted by the PR binary (PR #3547 says existing nodes are not migrated)
. ~/m/lib.sh; R1=clab-a-r1; cd ~/m/A; sed "s#\${CHR_TAG:=7.24.5}#7.24.5#" a.clab.yml > w.clab.yml
sudo $HOME/clab-main deploy -t w.clab.yml --reconfigure >/dev/null 2>&1; wait_healthy $R1 400; wait_healthy clab-a-r2 200
n=$(nmark $R1 'RouterOS ready'); $CLAB restart -t w.clab.yml --node r1 > /tmp/w.txt 2>&1; echo "restart rc=$?"; wait_new_marker $R1 'RouterOS ready' $n 300
sudo docker logs $R1 2>&1 | grep -E 'FAILED|VRF|management' | tail -3
check "existing node restarted by PR binary: ssh, data plane" "ros $R1 admin admin ':put ok' | grep -q ok && sudo docker exec clab-a-h1 ping -c 3 -W 2 2.2.2.2"
$CLAB destroy -t w.clab.yml --cleanup >/dev/null 2>&1
