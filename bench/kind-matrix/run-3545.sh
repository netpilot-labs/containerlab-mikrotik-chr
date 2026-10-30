. ~/m/lib.sh; cd ~/m; for t in 7.23.8 7.24.5 7.25 7.25rc3 7.26beta4; do echo "######## Y main $t"; CHR_TAG=$t bash Y.sh main 2>&1; echo "######## Y pr $t"; CHR_TAG=$t bash Y.sh pr 2>&1; done
for s in A B C D E F; do echo "######## $s"; bash $s.sh 2>&1; done; $CLAB destroy -a -c -y >/dev/null 2>&1; echo ALLDONE
