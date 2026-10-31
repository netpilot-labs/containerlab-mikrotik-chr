. ~/m/lib.sh; cd ~/m; mkdir -p ~/src; tar xzf ~/full.tgz -C ~/src
GV=$(awk '/^go /{print $2}' ~/src/go.mod); sudo docker run --rm -v $HOME/src:/s -w /s golang:$GV go test ./nodes/mikrotik_chr/ ./nodes/ 2>&1 | tail -4 | sed 's/^/GO /'
for t in 7.23.8 7.24.5 7.25 7.25rc3 7.26beta4; do for s in N V Y; do echo "######## $s $t"; if [ $s = N ]; then CHR_TAG=$t bash N.sh 2>&1; else CHR_TAG=$t bash $s.sh pr 2>&1; fi; done; done
for n in 7.26beta4 7.25; do for s in 1 2; do echo "######## X $n x$s"; NEW=$n SAVES=$s bash X.sh pr 2>&1; done; echo "######## Z $n"; NEW=$n bash Z.sh 2>&1; done
. ~/m/m-all.sh; echo ALLDONE
