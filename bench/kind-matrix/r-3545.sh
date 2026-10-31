. ~/m/lib.sh; cd ~/m; mkdir -p ~/src; tar xzf ~/full.tgz -C ~/src; bash rb.sh 2>&1
for t in 7.23.8 7.24.5 7.25 7.25rc3 7.26beta4; do echo "######## Y $t"; CHR_TAG=$t bash Y.sh pr 2>&1; done
for n in 7.26beta4 7.25; do for s in 1 2; do for b in main pr; do echo "######## X $b $n x$s"; NEW=$n SAVES=$s bash X.sh $b 2>&1; done; done; done
. ~/m/m-all.sh; echo ALLDONE
