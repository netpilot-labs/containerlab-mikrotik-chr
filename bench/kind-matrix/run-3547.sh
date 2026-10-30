. ~/m/lib.sh; cd ~/m; echo "######## V control"; bash V.sh main 2>&1; for t in 7.23.8 7.24.5 7.25 7.25rc3 7.26beta4; do echo "######## V $t"; CHR_TAG=$t bash V.sh pr 2>&1; done
for s in A B C D E F; do echo "######## $s"; bash $s.sh 2>&1; done; $CLAB destroy -a -c -y >/dev/null 2>&1
echo "######## W"; bash W.sh 2>&1
for n in 7.26beta4 7.25; do echo "######## X pr $n"; NEW=$n bash X.sh pr 2>&1; done; echo ALLDONE
