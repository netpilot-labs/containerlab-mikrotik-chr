# does the placeholder appear with no keymat command at all? fresh node, exports only, timestamps from healthy
. ~/m/lib.sh; T=${CHR_TAG:-7.25}; R1=clab-a-r1; cd ~/m/A; sed "s#\${CHR_TAG:=7.24.5}#$T#" a.clab.yml > y2.clab.yml
sudo $HOME/clab-main deploy -t y2.clab.yml --reconfigure >/dev/null 2>&1; wait_healthy $R1 400 >/dev/null
for i in 1 2 3 4 5 6; do echo "[$T] export $i at +$((i*4-4))s: placeholder=$(ros $R1 admin admin '/export' | grep -c 'name=default')"; sleep 4; done
sudo $HOME/clab-main destroy -t y2.clab.yml --cleanup >/dev/null 2>&1
echo "[$T] with one save right at healthy:"; sudo $HOME/clab-main deploy -t y2.clab.yml --reconfigure >/dev/null 2>&1; wait_healthy $R1 400 >/dev/null
sudo $HOME/clab-main save -t y2.clab.yml >/dev/null 2>&1; sudo grep -c 'name=default' clab-a/r1/ftpboot/config.auto.rsc
sudo $HOME/clab-main destroy -t y2.clab.yml --cleanup >/dev/null 2>&1; echo Y2DONE
