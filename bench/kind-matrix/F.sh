. ~/m/lib.sh
cd ~/m/F && $CLAB deploy -t f.clab.yml --reconfigure > /tmp/f-deploy.txt 2>&1; echo "deploy rc=$?"
rh=$(sudo docker inspect -f '{{range .State.Health.Log}}{{if eq .ExitCode 0}}{{.Start}}|{{end}}{{end}}' clab-f-r1 | cut -d'|' -f1 | cut -c1-19); hc=$(sudo docker inspect -f '{{.Created}}' clab-f-h1 | cut -c1-19)
echo "r1 first healthy: $rh   h1 created: $hc"
check "wait-for healthy: h1 created after r1 healthy" "[ -n \"$rh\" ] && [[ \"$hc\" > \"$rh\" ]]"
check "MEM=1024 -> ~1 GiB" "ros clab-f-r1 admin admin '/system resource print' | grep -E 'total-memory: (9[0-9][0-9]|10[0-9][0-9])\.?[0-9]*MiB'"
check "CPUS=2 -> cpu-count 2" "ros clab-f-r1 admin admin '/system resource print' | grep -q 'cpu-count: 2'"
$CLAB destroy -t f.clab.yml --cleanup >/dev/null 2>&1
