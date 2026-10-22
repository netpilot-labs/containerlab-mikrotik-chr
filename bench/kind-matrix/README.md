# Test matrix for the `mikrotik_chr` containerlab kind

The scripts that produced the test evidence in the containerlab PR for the `mikrotik_chr` kind. Each check
prints one `PASS` or `FAIL` line.

| Script | What it covers |
|--------|----------------|
| `A.sh` | Two routers and a Linux host: transparent management (the containerlab IPv4/IPv6 on `ether1`, SSH over both, no address left on the container), services on the mgmt IP, no router advertisement making RouterOS a default router, serial console, `etherN` aliases, sparse links, data plane, LLDP, MTU, a lab default route next to management, healthcheck |
| `B.sh` | Custom credentials with a space, `#`, `@` and `/` in the password, a rejected startup config, a config that disables SSH |
| `C.sh` | OSPF across three routers, a link on `ether13`, `destroy --cleanup` |
| `D.sh` | `containerlab restart --node` (management left in place), an in-router reboot, `docker restart`, a restart with a new management IP (re-applied to `ether1`) |
| `E.sh` | `containerlab save`, then a fresh deployment from the saved files |
| `F.sh` | A `wait-for: healthy` stage dependency, `MEM` and `CPUS` |
| `G.sh` | `containerlab save` on a `mikrotik_ros` node (standalone mode, `pub-example/`: this repo's example lab and launcher) through the shared SSH export |

## Running it

On a Linux host with Docker, `sshpass`, `nc` and `curl`, with a containerlab binary built from the PR branch at
`~/clab` and this directory at `~/m`:

```bash
bash ~/m/run.sh         # everything, plus RouterOS 7.23.8 and 7.25rc2
bash ~/m/run-small.sh   # A, D, B, E
```
