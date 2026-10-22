# `mikrotik_ros` save: `main` vs the shared SSH export (containerlab#3517)

`compare-saves.sh` deploys two `mikrotik_ros` nodes from a vrnetlab image and runs `containerlab save` four
times in turn with a `main` binary and a binary built from the PR branch, on the same running routers. It checks
that every save exits 0 and writes both nodes, and that each branch save is identical to the `main` save of the
same router state, apart from RouterOS's own timestamp comment.

## Running it

On a Linux host with KVM, Docker and `sshpass`:

1. Build the image: clone [srl-labs/vrnetlab](https://github.com/srl-labs/vrnetlab), put
   `chr-7.24.5.vmdk` (from `https://download.mikrotik.com/routeros/7.24.5/chr-7.24.5.vmdk.zip`) in
   `mikrotik/routeros/`, run `make` (gives `vrnetlab/mikrotik_routeros:7.24.5`).
2. Put the two containerlab binaries at `~/clab-main` and `~/clab-change`.
3. `mkdir ~/vr2` with `vr.clab.yml`, `r1.rsc` and `r2.rsc` from this directory, then `bash compare-saves.sh`.
