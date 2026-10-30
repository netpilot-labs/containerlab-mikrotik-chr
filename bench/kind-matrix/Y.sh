# Keymat placeholder (containerlab PR #3545). Y.sh [main]: save after repeated exports, import on a fresh router. CHR_TAG picks the version
. ~/m/lib.sh; T=${CHR_TAG:-7.24.5}; B=${1:-pr}; R1=clab-a-r1; R2=clab-a-r2
[ "$1" = main ] && CLAB="sudo $HOME/clab-main"
cd ~/m/A && sed "s#\${CHR_TAG:=7.24.5}#$T#" a.clab.yml > y-$T.clab.yml
sudo docker pull -q mikrotik/chr:$T >/dev/null
$CLAB deploy -t y-$T.clab.yml --reconfigure >/dev/null 2>&1; wait_healthy $R1 400; wait_healthy $R2 200
for i in 1 2 3 4; do ros $R1 admin admin '/export' > /tmp/y-raw-$i.txt; sleep 4; done
echo "[$B][$T] keymat default in raw exports 1-4: $(for i in 1 2 3 4; do grep -c 'name=default' /tmp/y-raw-$i.txt; done | tr '\n' ' ')"
$CLAB save -t y-$T.clab.yml > /tmp/y-save.txt 2>&1; echo "[$B][$T] save rc=$?"
for n in r1 r2; do sudo cp clab-a/$n/ftpboot/config.auto.rsc $n-y.rsc; done; sudo chown $USER *-y.rsc
echo "[$B][$T] saved r1 keymat lines: $(tr -d '\n' < r1-y.rsc | grep -o 'add [^/]*type=qkd' | tr -s ' ' | cut -c1-140)"
sed -e 's/r1.rsc/r1-y.rsc/; s/r2.rsc/r2-y.rsc/' y-$T.clab.yml > y-saved.clab.yml
$CLAB destroy -t y-$T.clab.yml --cleanup >/dev/null 2>&1; $CLAB deploy -t y-saved.clab.yml >/dev/null 2>&1
wait_healthy $R1 400; wait_healthy $R2 200
sudo docker logs $R1 2>&1 | grep -E 'import' | tail -2
check "[$B][$T] saved config imports on a fresh router" "! sudo docker logs $R1 2>&1 | grep -q FAILED && ! sudo docker logs $R2 2>&1 | grep -q FAILED && [ \$(health $R1) = healthy ]"
$CLAB destroy -t y-saved.clab.yml --cleanup >/dev/null 2>&1
