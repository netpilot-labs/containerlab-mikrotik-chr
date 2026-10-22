# mikrotik_ros (vrnetlab kind) SaveConfig through the shared SSH export helper, with this branch's binary
. ~/m/lib.sh
rm -rf ~/gvr && mkdir -p ~/gvr && cp ~/m/pub-example/* ~/gvr/; cd ~/gvr
$CLAB deploy -t lab.clab.yml --reconfigure > /tmp/g-deploy.txt 2>&1; echo "deploy rc=$?"
wait_marker clab-chr-two-routers-r1 'RouterOS ready' 300; wait_marker clab-chr-two-routers-r2 'RouterOS ready' 300
$CLAB save -t lab.clab.yml > /tmp/g-save.txt 2>&1; echo "save rc=$?"
check "mikrotik_ros save (shared helper): r1 export written" "sudo grep -q 'add address=10.0.0.1/30 interface=ether2' ~/gvr/clab-chr-two-routers/r1/ftpboot/config.auto.rsc"
check "mikrotik_ros save (shared helper): vr_ros ether1 address filter still applied" "! sudo grep -q -E 'add address=172.20.20.[0-9]+/24 .*interface=ether1' ~/gvr/clab-chr-two-routers/r1/ftpboot/config.auto.rsc"
check "mikrotik_ros save: logged path" "grep -q 'Saved configuration to path' /tmp/g-save.txt"
$CLAB destroy -t lab.clab.yml --cleanup >/dev/null 2>&1
