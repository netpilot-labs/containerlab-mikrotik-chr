for s in A B C D E F; do echo "######## $s"; bash $s.sh 2>&1; done; $CLAB destroy -a -c -y >/dev/null 2>&1
