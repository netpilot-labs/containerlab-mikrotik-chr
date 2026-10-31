. ~/m/lib.sh; cd ~/m; mkdir -p ~/src; tar xzf ~/full.tgz -C ~/src; bash rb.sh 2>&1
for t in 7.23.8 7.24.5 7.25 7.25rc3 7.26beta4; do echo "######## N $t"; CHR_TAG=$t bash N.sh 2>&1; done
for n in 7.26beta4 7.25; do echo "######## X pr $n"; NEW=$n bash X.sh pr 2>&1; done
. ~/m/m-all.sh; echo ALLDONE
