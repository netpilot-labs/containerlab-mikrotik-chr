# Cross-version: save on a newer RouterOS, deploy the saved files on an older one (PR #3546 verbose discovery export)
. ~/m/lib.sh; R1=clab-a-r1; R2=clab-a-r2; NEW=${NEW:-7.26beta4}; OLD=${OLD:-7.23.8}
[ "$1" = main ] && CLAB="sudo $HOME/clab-main"; B=${1:-pr}
cd ~/m/A && sed "s#\${CHR_TAG:=7.24.5}#$NEW#" a.clab.yml > x-new.clab.yml
$CLAB deploy -t x-new.clab.yml --reconfigure >/dev/null 2>&1; wait_healthy $R1 400; wait_healthy $R2 200
$CLAB save -t x-new.clab.yml > /tmp/x-save.txt 2>&1; echo "[$B] save on $NEW rc=$?"
for n in r1 r2; do sudo cp clab-a/$n/ftpboot/config.auto.rsc $n-x.rsc; done; sudo chown $USER *-x.rsc
sed -e "s#mikrotik/chr:$NEW#mikrotik/chr:$OLD#; s/r1.rsc/r1-x.rsc/; s/r2.rsc/r2-x.rsc/" x-new.clab.yml > x-old.clab.yml
$CLAB destroy -t x-new.clab.yml --cleanup >/dev/null 2>&1; $CLAB deploy -t x-old.clab.yml > /tmp/x-old.txt 2>&1
wait_healthy $R1 400; wait_healthy $R2 200
sudo docker logs $R1 2>&1 | grep -i -E 'import|FAILED|expected|unknown|bad' | tail -4
check "[$B] $NEW save -> $OLD deploy: import ok" "! sudo docker logs $R1 2>&1 | grep -q FAILED && [ \$(health $R1) = healthy ]"
$CLAB destroy -t x-old.clab.yml --cleanup >/dev/null 2>&1
