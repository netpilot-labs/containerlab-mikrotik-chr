SSHO="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -o ConnectTimeout=10"
chk() { if ( eval "$2" ) >/dev/null 2>&1; then echo "PASS  $1"; else echo "FAIL  $1"; fi; }
sshr() { sshpass -p "$2" ssh $SSHO admin@$(sudo docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $1) "$3" 2>&1 | tr -d '\r'; }
up() { t=0; until sshr $1 "$2" '/system identity print' | grep -q "name:" || [ $t -ge 400 ]; do sleep 5; t=$((t+5)); done; echo "$1 answering after ~${t}s"; }
cd ~/vr2; sudo ~/clab-main destroy -a -c -y >/dev/null 2>&1
sed -e 's/password: "pass word#1"/password: "Secr3t-pass"/' vr.clab.yml > vr3.clab.yml
sudo ~/clab-main deploy -t vr3.clab.yml > /tmp/v3-deploy.txt 2>&1; echo "deploy (main) rc=$?"
up clab-vr2-r1 admin; up clab-vr2-r2 'Secr3t-pass'; sleep 20
i=0; for b in main change main change; do i=$((i+1)); sudo ~/clab-$b save -t vr3.clab.yml > /tmp/v3-save-$i.txt 2>&1; echo "save $i ($b) rc=$? saved=$(grep -c 'Saved configuration to path' /tmp/v3-save-$i.txt) failed=$(grep -c -i 'save failed' /tmp/v3-save-$i.txt)"; for n in r1 r2; do sudo cp clab-vr2/$n/ftpboot/config.auto.rsc $n-$i-$b.rsc; done; sleep 2; done; sudo chown $USER *-[1-4]-*.rsc
for n in r1 r2; do chk "$n: every save (main and change) wrote a RouterOS export" "for f in $n-[1-4]-*.rsc; do head -1 \$f | grep -q 'by RouterOS 7.24.5' || exit 1; done"; done
for n in r1 r2; do chk "$n: change save 2 identical to main save 3 (same router state, timestamp line aside)" "diff <(sed 1d $n-2-change.rsc) <(sed 1d $n-3-main.rsc)"; chk "$n: main save 3 identical to change save 4 (timestamp line aside)" "diff <(sed 1d $n-3-main.rsc) <(sed 1d $n-4-change.rsc)"; done
chk "r1: same trailing byte, change vs main" "[ \"\$(tail -c1 r1-4-change.rsc | xxd -p)\" = \"\$(tail -c1 r1-3-main.rsc | xxd -p)\" ]"
chk "r1: export carries the startup config" "grep -q 'address=1.1.1.1' r1-4-change.rsc && grep -q 'dst-address=10.9.0.0/16' r1-4-change.rsc"
chk "r1: vr_ros ether1 filter applied (change and main)" "! grep -q -E 'add address=10.0.0.15/24 .*interface=ether1' r1-4-change.rsc && ! grep -q -E 'add address=10.0.0.15/24 .*interface=ether1' r1-3-main.rsc"
echo "-- r1 save 4 (change):"; cat r1-4-change.rsc | tr -d '\r'
echo ALLDONE
