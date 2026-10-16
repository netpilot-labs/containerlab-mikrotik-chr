cd ~/m; for s in A B C D E F; do echo "######## $s"; bash $s.sh 2>&1; done
$CLAB destroy -t ~/m/A/a-7.24.5.clab.yml --cleanup >/dev/null 2>&1
for t in 7.23.8 7.25rc2; do sudo docker pull -q mikrotik/chr:$t >/dev/null; echo "######## G $t"; CHR_TAG=$t bash A.sh 2>&1; $CLAB destroy -t ~/m/A/a-$t.clab.yml --cleanup >/dev/null 2>&1; done
echo ALLDONE
