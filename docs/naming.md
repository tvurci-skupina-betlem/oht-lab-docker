# Naming

## Nodes

```text
docker1 -> OHT-LAB1 (pve1)
docker2 -> OHT-LAB2 (pve2)
docker3 -> OHT-LAB3 (pve3)
docker4 -> OHT-LAB4 (pve4)
```

## Stacks

Use lowercase kebab-case for stack directories:

```text
stacks/uptime-kuma
stacks/globalping-probe
```

Container names should include the stack name when they are needed.
Prefer Compose service names where possible.
