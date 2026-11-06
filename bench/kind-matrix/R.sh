# R.sh <N> <deploys> <reboots> <how: rest|ssh>: reboot r2 from inside RouterOS repeatedly, then 30 s and 150 s after it answers print one RES line: RouterOS interfaces, missing etherN, a ping out of etherN, health, and how often the launcher logged its reboot check, a re-plug and a failure. Binary at ~/clab, LABEL names it in the output
. ~/m/lib.sh; B=${LABEL:-pr}; N=$1; D=$2; RB=$3; HOW=${4:-rest}; L=rb; F=~/t/r-$B-$N.yml; mkdir -p ~/t
cat > $F <<Y
name: $L
topology:
  nodes:
    r1:
      kind: mikrotik_chr
      image: mikrotik/chr:7.24.5
      startup-config: |
        /ip address add address=10.0.1.1/30 interface=ether$N
    r2:
      kind: mikrotik_chr
      image: mikrotik/chr:7.24.5
      startup-config: |
        /ip address add address=10.0.1.2/30 interface=ether$N
  links:
    - endpoints: ["r1:ether$N", "r2:ether$N"]
Y
sudo cp ~/clab /usr/bin/containerlab; sudo chown root:root /usr/bin/containerlab; sudo chmod 4755 /usr/bin/containerlab
hl(){ for i in $(seq 1 96); do [ "$(health clab-$L-$1)" = healthy ] && return 0; sleep 5; done; echo "  $1 NOT healthy"; return 1; }
rep(){ c=clab-$L-r2; n=$(ros $c admin admin '/interface ethernet print terse'|grep -oE ' name=ether[0-9]+'|sed 's/ name=ether//'); m=$(comm -23 <(seq 1 $N|sort) <(echo "$n"|sort)|sort -n|tr '\n' ' '); p=$(ros $c admin admin "/ping 10.0.1.1 interface=ether$N count=3"|grep -oE 'received=[0-9]+'|tail -1); h=$(health $c); echo "RES $B N=$N $HOW $1 count=$(echo "$n"|grep -c .)/$N missing=[$m] ping=${p:-none} health=$h rebooted=$(sudo docker logs $c 2>&1|grep -c "RouterOS rebooted: checking") replug=$(sudo docker logs $c 2>&1|grep -c "re-plugging") failed=$(sudo docker logs $c 2>&1|grep -c "check FAILED after a reboot")"; }
for d in $(seq 1 $D); do sudo containerlab deploy -t $F >/tmp/dep.log 2>&1 || { tail -3 /tmp/dep.log; echo "DEPLOY FAILED $B $N"; sudo containerlab destroy -t $F --cleanup >/dev/null 2>&1; exit 1; }; hl r1; hl r2; sleep 5; rep fresh
 for x in $(seq 1 $RB); do
  if [ $HOW = ssh ]; then echo y | sshpass -p admin ssh $SSHO admin@$(ip_of clab-$L-r2) '/system reboot' >/dev/null 2>&1 || true; else curl -s -m 10 -u admin:admin -X POST -H 'Content-Type: application/json' -d '{}' http://$(ip_of clab-$L-r2)/rest/system/reboot >/dev/null 2>&1 || true; fi
  sleep 20; for i in $(seq 1 36); do ros clab-$L-r2 admin admin '/system identity print'|grep -q 'name: r2' && break; sleep 5; done; sleep 30; rep "reboot$x+30s"; sleep 120; rep "reboot$x+150s"; done
 sudo containerlab destroy -t $F --cleanup >/dev/null 2>&1; done
