. ~/m/lib.sh; R1=clab-hp-r1; R2=clab-hp-r2
cd ~/m/H && $CLAB deploy -t h.clab.yml --reconfigure > /tmp/h-deploy.txt 2>&1; echo "deploy rc=$?"
wait_healthy $R1 400; wait_healthy $R2 200
check "ether33: r1 has 33 ethernet interfaces" "[ \$(ros $R1 admin admin '/interface ethernet print count-only' | tr -dc 0-9) = 33 ]"
check "ether33: 10.33.0.1/30 on ether33" "ros $R1 admin admin '/ip address print terse' | grep -q '10.33.0.1/30.*ether33'"
check "ether33: MAC scheme unchanged (index 32 -> :20)" "ros $R1 admin admin '/interface ethernet print terse where name=ether33' | grep -q -i 'mac-address=52:54:00:..:..:20'"
check "ether33: qemu runs data NICs behind pci-bridge devices" "sudo docker exec $R1 sh -c 'for p in /proc/[0-9]*; do tr \"\\\\0\" \" \" < \$p/cmdline 2>/dev/null; echo; done' | grep qemu-system | grep -q pci-bridge"
check "ether33: ping r1 -> r2 over ether2" "ros $R1 admin admin '/ping 10.0.0.2 count=3' | grep -q 'received=3'"
check "ether33: ping r1 -> r2 over ether33 (second PCI bridge)" "ros $R1 admin admin '/ping 10.33.0.2 count=3' | grep -q 'received=3'"
check "ether33: transparent mgmt kept (ether1 has the clab IP)" "ros $R1 admin admin '/ip address print terse where interface=ether1' | grep -q \"address=\$(ip_of $R1)/\""
B=$(macs $R1); n=$(nmark $R1 'RouterOS ready')
$CLAB restart -t h.clab.yml --node r1 > /tmp/h-restart.txt 2>&1; wait_new_marker $R1 'RouterOS ready' $n 300
check "ether33 after restart --node: same names + MACs" "[ \"$B\" = \"\$(macs $R1)\" ]"
check "ether33 after restart --node: ping over ether33" "sleep 5; ros $R1 admin admin '/ping 10.33.0.2 count=3' | grep -q 'received=3'"
$CLAB destroy -t h.clab.yml --cleanup >/dev/null 2>&1
