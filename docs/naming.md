# Naming

## Nodes

```text
docker1 -> OHT-LAB1 (pve1)
docker2 -> OHT-LAB2 (pve2)
docker3 -> OHT-LAB3 (pve3)
docker4 -> OHT-LAB4 (pve4)
docker5 -> OHT-LAB5 (Raspberry Pi, outside the Proxmox cluster)
docker-ha1 -> CT 205, Ceph RBD + Proxmox HA, runs on any of pve1-3
```

## Stacks

Use lowercase kebab-case for stack directories:

```text
stacks/uptime-kuma
stacks/globalping-probe
```

Container names should include the stack name when they are needed.
Prefer Compose service names where possible.
