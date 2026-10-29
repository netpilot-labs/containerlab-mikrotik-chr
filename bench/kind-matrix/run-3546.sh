. ~/m/lib.sh; cd ~/m; echo "######## CONTROL (main, binary at ~/clab-main)"; bash N.sh main 2>&1
echo "######## N"; bash N.sh 2>&1
for s in A B C D E F; do echo "######## $s"; bash $s.sh 2>&1; done
$CLAB destroy -t ~/m/A/a-7.24.5.clab.yml --cleanup >/dev/null 2>&1
for t in 7.23.8 7.25 7.25rc3 7.26beta4; do echo "######## N $t"; CHR_TAG=$t bash N.sh 2>&1; echo "######## A $t"; CHR_TAG=$t bash A.sh 2>&1; sudo $HOME/clab destroy -t ~/m/A/a-$t.clab.yml --cleanup >/dev/null 2>&1; done
echo ALLDONE
# cross-version save: main as control, then the PR
for b in main pr; do for n in 7.26beta4 7.25; do echo "######## X $b $n -> 7.23.8"; NEW=$n bash X.sh $b 2>&1; done; done
echo XDONE
