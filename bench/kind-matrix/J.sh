. ~/m/lib.sh; cd ~/m/I
sudo ~/clab destroy -a -c -y >/dev/null 2>&1
for p in 64 128 192 230 250; do
  sed -e "s/name: b$p/name: s$p/" b$p.clab.yml > s$p.clab.yml 2>/dev/null || { e=1; }
  [ -s s$p.clab.yml ] || sed -e "s/name: imax/name: s$p/; s/ether256/ether$p/; s/10.56.0/10.$((p % 250)).0/g; s/startup-config: r1.rsc/startup-config: b$p.rsc/" max.clab.yml > s$p.clab.yml
  [ -s b$p.rsc ] || printf "/ip address add address=10.$((p % 250)).0.1/30 interface=ether$p\n" > b$p.rsc
  $CLAB deploy -t s$p.clab.yml > /tmp/s$p.txt 2>&1; rc=$?
  t=0; until [ "$(sudo docker inspect -f '{{.State.Health.Status}}' clab-s$p-r1 2>/dev/null)" = healthy ] || [ $t -ge 360 ]; do sleep 10; t=$((t+10)); done
  h=$(sudo docker inspect -f '{{.State.Health.Status}}' clab-s$p-r1 2>/dev/null)
  if [ "$h" = healthy ]; then
    c=$(ros clab-s$p-r1 admin admin '/interface ethernet print count-only' | tr -dc 0-9)
    pg=$(sudo docker exec clab-s$p-h1 ping -c 3 -W 2 10.$((p % 250)).0.1 >/dev/null 2>&1 && echo ok || echo FAIL)
    echo "RESULT ether$p: deploy rc=$rc, healthy after ~${t}s, RouterOS interfaces=$c (want $p), ping over ether$p: $pg"
  else
    cpu=$(sudo docker exec clab-s$p-r1 sh -c "top -b -n 1 | grep qemu-system | head -1" | awk '{print $8}')
    echo "RESULT ether$p: deploy rc=$rc, NOT healthy in 360s (health=$h, qemu cpu=$cpu, last: $(sudo docker logs clab-s$p-r1 2>&1 | grep chr-launch | tail -1 | cut -c1-70))"
  fi
  $CLAB destroy -t s$p.clab.yml --cleanup >/dev/null 2>&1
done
echo ALLDONE
