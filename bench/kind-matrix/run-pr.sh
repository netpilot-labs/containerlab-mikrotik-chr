. ~/m/lib.sh; cd ~/m
for s in H I; do echo "######## $s"; bash $s.sh 2>&1; done
echo "######## OUR MATRIX"; bash ~/m/run.sh 2>&1
