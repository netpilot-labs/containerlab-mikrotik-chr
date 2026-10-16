# Test matrix for the `mikrotik_chr` containerlab kind

The scripts that produced the test evidence in the containerlab PR for the `mikrotik_chr` kind. Each check
prints one `PASS` or `FAIL` line.

| Script | What it covers |
|--------|----------------|
| `A.sh` | Two routers and a Linux host: service ports, serial console, `etherN` aliases, sparse links, data plane, LLDP, MTU, a lab default route next to management, healthcheck |
| `B.sh` | Custom credentials with a space, `#`, `@` and `/` in the password, a rejected startup config, a config that disables SSH |
| `C.sh` | OSPF across three routers, a link on `ether13`, `destroy --cleanup` |
| `D.sh` | `containerlab restart --node`, an in-router reboot, `docker restart` |
| `E.sh` | `containerlab save`, then a fresh deployment from the saved files |
| `F.sh` | A `wait-for: healthy` stage dependency, `MEM` and `CPUS` |

## Running it

On a Linux host with Docker, `sshpass`, `nc` and `curl`, with a containerlab binary built from the PR branch at
`~/clab` and this directory at `~/m`:

```bash
bash ~/m/run.sh         # everything, plus RouterOS 7.23.8 and 7.25rc2
bash ~/m/run-small.sh   # A, D, B, E
```
