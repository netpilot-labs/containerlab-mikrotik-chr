. ~/m/lib.sh; cd ~/m; for s in A D B E; do echo "######## $s"; bash $s.sh 2>&1; [ $s = D ] && $CLAB destroy -t ~/m/A/a-7.24.5.clab.yml --cleanup >/dev/null 2>&1; done; echo ALLDONE
