. ~/m/lib.sh
cd ~/m/A && sed "s#\${CHR_TAG:=7.24.5}#7.24.5#" a.clab.yml > a-7.24.5.clab.yml && $CLAB deploy -t a-7.24.5.clab.yml --reconfigure >/dev/null 2>&1; wait_healthy clab-a-r1 300; wait_healthy clab-a-r2 120
$CLAB save -t a-7.24.5.clab.yml > /tmp/e-save.txt 2>&1; echo "save rc=$?"
for n in r1 r2; do sudo cp clab-a/$n/ftpboot/config.auto.rsc $n-saved.rsc; done; sudo chown $USER *-saved.rsc
check "saved file has no launcher objects" "! grep -q -E 'name=mgmt|routing-table=mgmt|table=mgmt|interface=ether1' r1-saved.rsc"
sed -e 's/r1.rsc/r1-saved.rsc/; s/r2.rsc/r2-saved.rsc/' a-7.24.5.clab.yml > a-saved.clab.yml
$CLAB destroy -t a-7.24.5.clab.yml --cleanup >/dev/null 2>&1; $CLAB deploy -t a-saved.clab.yml > /tmp/e-redeploy.txt 2>&1
wait_healthy clab-a-r1 300; wait_healthy clab-a-r2 120
check "round trip: import ok on both" "! sudo docker logs clab-a-r1 2>&1 | grep -q FAILED && ! sudo docker logs clab-a-r2 2>&1 | grep -q FAILED"
check "round trip: config restored" "ros clab-a-r1 admin admin '/ip address print terse' | grep -q 10.0.0.1/30 && ros clab-a-r2 admin admin '/ip address print terse' | grep -q 2.2.2.2/32"
check "round trip: one mgmt table, one dhcp client" "[ \$(ros clab-a-r1 admin admin '/routing table print count-only where name=mgmt' | tr -dc 0-9) = 1 ] && [ \$(ros clab-a-r1 admin admin '/ip dhcp-client print count-only' | tr -dc 0-9) = 1 ]"
check "round trip: data plane" "sudo docker exec clab-a-h1 ping -c 3 -W 2 2.2.2.2"
$CLAB destroy -t a-saved.clab.yml --cleanup >/dev/null 2>&1
