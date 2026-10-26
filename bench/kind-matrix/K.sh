. ~/m/lib.sh; cd ~/m/I; sudo ~/clab destroy -a -c -y >/dev/null 2>&1
for p in 64 128; do
  $CLAB deploy -t s$p.clab.yml >/dev/null 2>&1; t=0; until [ "$(sudo docker inspect -f '{{.State.Health.Status}}' clab-s$p-r1)" = healthy ] || [ $t -ge 360 ]; do sleep 10; t=$((t+10)); done
  have=$(ros clab-s$p-r1 admin admin '/interface ethernet print terse' | sed -n 's/.*default-name=\(ether[0-9]*\).*/\1/p' | sed 's/ether//' | sort -n | tr '\n' ' ')
  missing=""; for i in $(seq 1 $p); do echo " $have " | grep -q " $i " || missing="$missing ether$i"; done
  echo "RESULT ether$p: present=$(echo $have | wc -w) missing:${missing:- none}"
  echo "RESULT ether$p: RouterOS log: $(ros clab-s$p-r1 admin admin '/log print without-paging' | grep -i -E 'pci|irq|interface|virtio|error' | head -3 | tr '\n' '|')"
  $CLAB destroy -t s$p.clab.yml --cleanup >/dev/null 2>&1
done
$CLAB deploy -t s192.clab.yml >/dev/null 2>&1; t=0; until [ "$(sudo docker inspect -f '{{.State.Health.Status}}' clab-s192-r1)" = healthy ] || [ $t -ge 900 ]; do sleep 15; t=$((t+15)); done
echo "RESULT ether192 (15 min budget): health=$(sudo docker inspect -f '{{.State.Health.Status}}' clab-s192-r1) after ${t}s, qemu cpu=$(sudo docker exec clab-s192-r1 sh -c 'top -b -n 1 | grep qemu-system | head -1' | awk '{print $8}'), last: $(sudo docker logs clab-s192-r1 2>&1 | grep chr-launch | tail -1 | cut -c1-80)"
$CLAB destroy -t s192.clab.yml --cleanup >/dev/null 2>&1
echo ALLDONE
