# run-3568.sh <rest|ssh>: R.sh at 26, 29 and 33 NICs, 2 deploys with 3 reboots each, then ALLDONE
cd ~/m; for n in 26 29 33; do bash R.sh $n 2 3 ${1:-rest}; done; echo ALLDONE
