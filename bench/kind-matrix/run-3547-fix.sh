. ~/m/lib.sh; cd ~/m
for n in 7.26beta4 7.25; do echo "######## X fix $n"; NEW=$n bash X.sh pr 2>&1; done
for t in 7.23.8 7.25 7.26beta4; do echo "######## N $t"; CHR_TAG=$t bash N.sh 2>&1; echo "######## V $t"; CHR_TAG=$t bash V.sh pr 2>&1; echo "######## Y $t"; CHR_TAG=$t bash Y.sh pr 2>&1; done
grep -n -E 'vrf=|discover-interface-list' ~/m/A/r1-v.rsc | tail -14 | cut -c1-110
echo ALLDONE
