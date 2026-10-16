# shared test helpers (run on the bench as the default user, sudo for docker)
SSHO="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -o ConnectTimeout=10"
ip_of() { sudo docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$1"; }
ros() { # ros <container> <user> <pass> <cmd>
  sshpass -p "$3" ssh $SSHO "$2@$(ip_of "$1")" "$4" 2>&1 | tr -d '\r'
}
wait_marker() { # wait_marker <container> <regex> <timeout>
  t=0; while [ $t -lt "$3" ]; do sudo docker logs "$1" 2>&1 | grep -q -E "$2" && { echo "$1: '$2' after ~${t}s"; return 0; }; sleep 2; t=$((t+2)); done
  echo "$1: NO '$2' within $3s"; return 1
}
pass() { echo "PASS  $*"; }
fail() { echo "FAIL  $*"; }
check() { # check <desc> <shell string, eval'd in this shell so helpers resolve>
  if ( eval "$2" ) >/dev/null 2>&1; then pass "$1"; else fail "$1"; fi
}
nmark() { sudo docker logs "$1" 2>&1 | grep -c "$2"; }
wait_new_marker() { # wait_new_marker <container> <text> <count-before> <timeout>
  t=0; while [ $t -lt "$4" ]; do [ "$(nmark "$1" "$2")" -gt "$3" ] && { echo "$1: new '$2' after ~${t}s"; return 0; }; sleep 2; t=$((t+2)); done
  echo "$1: NO new '$2' within $4s"; return 1
}
CLAB="sudo $HOME/clab"
health() { sudo docker inspect -f '{{.State.Health.Status}}' "$1" 2>/dev/null; }
wait_healthy() { t=0; while [ $t -lt "$2" ]; do [ "$(health $1)" = healthy ] && { echo "$1 healthy after ~${t}s"; return 0; }; sleep 2; t=$((t+2)); done; echo "$1 NOT healthy within $2s ($(health $1))"; return 1; }
macs() { ros $1 ${2:-admin} ${3:-admin} '/interface ethernet print terse' | sed -n 's/.*name=\(ether[0-9]*\).*mac-address=\([0-9A-F:]*\).*/\1=\2/p' | sort | tr '\n' ' '; }
