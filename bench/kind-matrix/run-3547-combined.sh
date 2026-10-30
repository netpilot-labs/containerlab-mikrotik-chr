. ~/m/lib.sh; cd ~/m; for t in 7.23.8 7.25 7.26beta4; do echo "######## N $t"; CHR_TAG=$t bash N.sh 2>&1; echo "######## V $t"; CHR_TAG=$t bash V.sh pr 2>&1; echo "######## Y $t"; CHR_TAG=$t bash Y.sh pr 2>&1; done
for s in A B C D E F; do echo "######## $s"; bash $s.sh 2>&1; done; $CLAB destroy -a -c -y >/dev/null 2>&1
for n in 7.26beta4 7.25; do echo "######## X pr $n"; NEW=$n bash X.sh pr 2>&1; done; echo ALLDONE
