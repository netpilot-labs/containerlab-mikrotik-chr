# The PR's own Robot suite and Go unit tests. rb.sh <7.25-style source tag> <older tag>, source unpacked at ~/src
cd ~/src; sudo cp ~/clab /usr/bin/containerlab; sudo chown root:root /usr/bin/containerlab; sudo chmod 4755 /usr/bin/containerlab
command -v uv >/dev/null || { curl -LsSf https://astral.sh/uv/install.sh | sh >/dev/null 2>&1; export PATH=$HOME/.local/bin:$PATH; }
uv sync --all-extras --dev >/dev/null 2>&1; . .venv/bin/activate
for pair in "7.24.5:" "7.25:7.23.8" "7.26beta4:7.23.8"; do s=${pair%%:*}; o=${pair##*:}
  sudo docker pull -q mikrotik/chr:$s >/dev/null; [ -n "$o" ] && sudo docker pull -q mikrotik/chr:$o >/dev/null
  echo "######## ROBOT $s -> ${o:-same}"; CLAB_BIN=/usr/bin/containerlab CHR_IMAGE=mikrotik/chr:$s CHR_REDEPLOY_IMAGE=${o:+mikrotik/chr:$o} bash ./tests/rf-run.sh docker ./tests/16-mikrotik-chr/01-chr.robot 2>&1 | grep -E '\| (PASS|FAIL) \||tests?, ' 
done
GV=$(awk '/^go /{print $2}' go.mod); sudo docker run --rm -u $(id -u):$(id -g) -e HOME=/tmp -e GOCACHE=/tmp/gc -e GOMODCACHE=/tmp/gm -v $HOME/src:/s -w /s golang:$GV go test ./nodes/mikrotik_chr/ ./nodes/ 2>&1 | grep -E '^(ok|FAIL|--- FAIL)' | sed 's/^/GO /'
