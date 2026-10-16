# MikroTik CHR in containerlab, official image

Run MikroTik RouterOS (CHR) as a [containerlab](https://containerlab.dev) node using the **official
[`mikrotik/chr`](https://hub.docker.com/r/mikrotik/chr) image from Docker Hub**, unmodified. No vrnetlab
build, no image download from a portal.

One shell script, `chr-launch.sh`, is bind-mounted into the node and replaces the image's `/start.sh` as
the entrypoint. It gives you what you expect from a containerlab node:

- **Transparent management.** The node's management IPv4/IPv6 address is RouterOS's own `ether1` address:
  SSH, REST, Winbox, the API, SNMP and every other service answer on it directly, with the credentials from
  the topology. Nothing is port-forwarded.
- **Data links that line up.** Container `eth1` is RouterOS `ether2`, `eth2` is `ether3`, and so on. Gaps
  keep the numbering (a link on `eth12` lands on `ether13`). MTU follows the veth, and LLDP/MNDP neighbors
  show up.
- **Startup config.** `startup-config: r1.rsc` is imported on first boot. If RouterOS rejects a line, the
  container log quotes RouterOS's own reason with the line number.
- **A ready line.** `chr-launch: RouterOS ready` on the container log means login and startup config are
  done, not just "container running".
- **Management that survives your lab.** The management return path lives in its own routing table, so a
  default route, PPPoE client or dual-WAN setup in your config never cuts SSH to the node.
- **Restarts that keep the router.** `containerlab restart --node` and an in-router `/system reboot` keep
  the interface names, MACs, config and links.
- **amd64 and arm64, with or without KVM.** The image's own QEMU and firmware are used for each
  architecture. Without `/dev/kvm` the router boots under TCG emulation, so it also runs where KVM is
  not available.

Background: containerlab [#3116](https://github.com/srl-labs/containerlab/issues/3116) and
[#3464](https://github.com/srl-labs/containerlab/issues/3464). The same launcher is proposed as a native
containerlab kind, `mikrotik_chr`, in [containerlab#3498](https://github.com/srl-labs/containerlab/pull/3498): with that kind a node needs only `kind` and
`image`.

## Quick start

Requirements: containerlab and Docker. KVM (`/dev/kvm`) makes the boot fast but is optional.

```bash
git clone https://github.com/netpilot-labs/containerlab-mikrotik-chr
cd containerlab-mikrotik-chr/examples/two-routers
sudo containerlab deploy -t lab.clab.yml
docker logs -f clab-chr-two-routers-r1     # wait for "chr-launch: RouterOS ready" (about 40 to 70 s)
ssh admin@clab-chr-two-routers-r1          # password: admin
```

## Use it in your own topology

Put `chr-launch.sh` next to your topology file and set three fields on the `mikrotik_ros` kind:

```yaml
topology:
  kinds:
    mikrotik_ros:
      image: mikrotik/chr:7.24.5
      binds:
        - chr-launch.sh:/chr-launch.sh:ro
      entrypoint: /bin/sh /chr-launch.sh
  nodes:
    r1:
      kind: mikrotik_ros
      startup-config: r1.rsc        # optional, RouterOS .rsc syntax
    r2:
      kind: mikrotik_ros
      credentials:                  # optional, default admin / admin
        username: netops
        password: "s3cret#pass"
  links:
    - endpoints: ["r1:eth1", "r2:eth1"]   # r1 ether2 <-> r2 ether2
```

With custom credentials the script creates that user in group `full` and disables the factory `admin`
account, which has a blank password on a fresh CHR disk.

`containerlab save` writes each node's `/export` to its lab directory. With the `mikrotik_ros` kind that
export still contains the management objects the launcher creates at every boot, and RouterOS stops an
import at the first one, so remove these lines before using a saved file as a startup config: every
`comment=clab-mgmt` line, and the `interface=ether1` lines under `/ip dhcp-client` and `/ipv6 nd`. The `mikrotik_chr` kind ([containerlab#3498](https://github.com/srl-labs/containerlab/pull/3498)) drops them for you.

## Log lines

`docker logs clab-<lab>-<node>`:

| Line | Meaning |
|------|---------|
| `chr-launch: RouterOS ready` | Credentials set, startup config imported and SSH answering: the node is ready to use. The launcher also creates `/.chr-launch-ready` in the container, usable as a healthcheck |
| `chr-launch: startup config import FAILED: Script Error: … (line N column M)` | RouterOS rejected that line. Lines before it were applied, the rest were not. No ready line follows |
| `chr-launch: credential bootstrap FAILED: …` | The user or password step failed. No ready line follows |
| `chr-launch: already bootstrapped (restart): skipping config` | A restarted node keeps its existing config |

## Options

Set under the node's `env:`. `MEM`, `CPUS` and `DISK` are the official image's own variables:

| Variable | Default | Purpose |
|----------|---------|---------|
| `MEM` | 256 MiB + 8 MiB per data NIC | VM memory (a QEMU `-m` value) |
| `CPUS` | 1 | VM vCPUs |
| `DISK` | 128M | Minimum disk size (the disk only grows) |
| `CHR_INTF_WAIT` | 60 | Seconds to wait for containerlab's links before boot |
| `CHR_BOOT_WAIT` | 300 | Seconds to wait for RouterOS to answer, also the startup config import limit |

## How it works

1. Waits for the data interfaces containerlab attaches (`CLAB_INTFS`).
2. Bridges the VM's `ether1` tap with the container's `eth0` and takes `eth0`'s IPv4/IPv6 addresses and
   gateways for RouterOS. The image ships busybox only (no `tc`), so this is a Linux bridge where
   vrnetlab's transparent management uses tc-mirred. The container keeps no address on the management
   network.
3. Creates one tap per container interface and bridges `ethN` with `tapN`, in index order, so RouterOS
   numbering follows the container's. A veth that appears later is bridged as it arrives.
4. Reaches RouterOS's REST API over IPv6 link-local on that bridge, sets the credentials and the identity,
   configures `ether1` with the management addresses (return path in its own `mgmt` routing table, CHR's
   DHCP client off, router advertisements with a zero lifetime so no host takes the router as its IPv6
   gateway), joins `eth0` to the bridge, then fetches and `/import`s the startup config. The management
   objects carry `comment=clab-mgmt` and are re-applied at boot when the container's address changed.
5. Waits for the gateway to answer from the management address and for the SSH banner (unless the config
   disables SSH), prints the ready line and stays in the foreground with qemu. The serial console is on
   port 5000 inside the container (`docker exec -it <node> nc 127.0.0.1 5000`).

NIC MACs are derived from the container and persisted on first boot, so RouterOS sees the same
interfaces after a restart.

## Tested

As the `mikrotik_chr` kind, on amd64 with and without KVM and on arm64 without KVM, RouterOS 7.24.5
(stable), 7.23.8 (long-term) and 7.25rc2 (testing): 244 checks, the scripts in
[`bench/kind-matrix`](bench/kind-matrix) and the results in
[containerlab#3498](https://github.com/srl-labs/containerlab/pull/3498). In standalone mode with the
`mikrotik_ros` kind on containerlab 0.77.0: the example lab above, SSH by node name, transparent
management, the data plane and the console.

Restart a node with `containerlab restart --node` or redeploy. A plain `docker restart` keeps the router
and its management but Docker deletes the node's veths, so its data links stay down until the next
containerlab restart or redeploy.

## License

BSD-3-Clause, the same as containerlab, so the logic can move into a native containerlab kind.

---

Maintained by the NetPilot team. [NetPilot](https://netpilot.io) is AI for network engineers: you describe
a change in plain English and it designs, builds and validates a multi-vendor containerlab lab on real
CLIs before production.
