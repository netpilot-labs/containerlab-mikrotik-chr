# Combined #3545 #3546 #3547: overrides survive two saves on NEW, a deploy on OLD, then a save and redeploy on OLD
. ~/m/lib.sh; R1=clab-a-r1; R2=clab-a-r2; NEW=${NEW:-7.26beta4}; OLD=${OLD:-7.23.8}; L="[$NEW->$OLD]"
sv() { ros $1 admin admin ":put [/ip service get $2 vrf]" | tr -d ' \n'; }
dis() { ros $1 admin admin ":put [/ip service get $2 disabled]" | tr -d ' \n'; }
sn() { ros $1 admin admin ':put [/snmp get vrf]' | tr -d ' \n'; }
dl() { ros $1 admin admin ':put [/ip neighbor discovery-settings get discover-interface-list]' | tr -d ' \n'; }
verify() {
  check "$L $1: import ok, both healthy" "! sudo docker logs $R1 2>&1 | grep -q FAILED && ! sudo docker logs $R2 2>&1 | grep -q FAILED && [ \$(health $R1) = healthy ] && [ \$(health $R2) = healthy ]"
  check "$L $1: api in main, api-ssl in blue, ssh in mgmt" "[ \$(sv $R1 api) = main ] && [ \$(sv $R1 api-ssl) = blue ] && [ \$(sv $R1 ssh) = mgmt ]"
  check "$L $1: telnet disabled, snmp in main, one custom community" "[ \$(dis $R1 telnet) = true ] && [ \$(sn $R1) = main ] && [ \$(ros $R1 admin admin '/snmp community print terse where name=labcomm' | grep -c labcomm) = 1 ]"
  check "$L $1: discovery static on r1, custom list on r2, one mgmt VRF" "[ \$(dl $R1) = static ] && [ \$(dl $R2) = mylist ] && [ \$(ros $R1 admin admin '/ip vrf print terse where name=mgmt' | grep -c mgmt) = 1 ]"
  check "$L $1: data plane" "sudo docker exec clab-a-h1 ping -c 3 -W 2 2.2.2.2"
}
cd ~/m/A && sed "s#\${CHR_TAG:=7.24.5}#$NEW#" a.clab.yml > z-new.clab.yml
$CLAB deploy -t z-new.clab.yml --reconfigure >/dev/null 2>&1; wait_healthy $R1 400; wait_healthy $R2 200
ros $R1 admin admin '/ip vrf add name=blue interfaces=ether3; /ip service set [find where name=api dynamic=no] vrf=main; /ip service set [find where name=api-ssl dynamic=no] vrf=blue; /ip service disable [find where name=telnet dynamic=no]; /snmp set vrf=main; /snmp community add name=labcomm; /ip neighbor discovery-settings set discover-interface-list=static' | head -3
ros $R2 admin admin '/interface list add name=mylist; /ip neighbor discovery-settings set discover-interface-list=mylist' | head -3
for i in 1 2; do $CLAB save -t z-new.clab.yml > /tmp/z-save.txt 2>&1; echo "$L save $i rc=$?"; sleep 8; done
for n in r1 r2; do sudo cp clab-a/$n/ftpboot/config.auto.rsc $n-z.rsc; done; sudo chown $USER *-z.rsc
check "$L saved files hold no keymat header, dying-gasp or available-from" "! grep -q -E 'keymat-provider|dying-gasp|available-from' r1-z.rsc && ! grep -q -E 'keymat-provider|dying-gasp|available-from' r2-z.rsc"
sed -e "s#mikrotik/chr:$NEW#mikrotik/chr:$OLD#; s/r1.rsc/r1-z.rsc/; s/r2.rsc/r2-z.rsc/" z-new.clab.yml > z-old.clab.yml
$CLAB destroy -t z-new.clab.yml --cleanup >/dev/null 2>&1; $CLAB deploy -t z-old.clab.yml >/dev/null 2>&1; wait_healthy $R1 400; wait_healthy $R2 200
sudo docker logs $R1 2>&1 | grep -E 'import' | tail -2
verify "older deploy"
$CLAB save -t z-old.clab.yml >/dev/null 2>&1; for n in r1 r2; do sudo cp clab-a/$n/ftpboot/config.auto.rsc $n-z2.rsc; done; sudo chown $USER *-z2.rsc
sed -e 's/r1-z.rsc/r1-z2.rsc/; s/r2-z.rsc/r2-z2.rsc/' z-old.clab.yml > z-old2.clab.yml
$CLAB destroy -t z-old.clab.yml --cleanup >/dev/null 2>&1; $CLAB deploy -t z-old2.clab.yml >/dev/null 2>&1; wait_healthy $R1 400; wait_healthy $R2 200
verify "second save on older"
$CLAB destroy -t z-old2.clab.yml --cleanup >/dev/null 2>&1
