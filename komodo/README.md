# Komodo

Komodo is the deployment control plane for this repository.

The intended model is:

```text
GitHub repository
  -> Komodo Resource Sync and webhooks
  -> Komodo Core
  -> Periphery agents
  -> Docker nodes
```

## Resources

The files under `komodo/resources/` are placeholders for Komodo Resource Sync. Fill them in from the live Komodo installation after Git provider access, servers, and stack paths are known.

Expected mapping:

```text
docker1 -> OHT-LAB1 / pve1
docker2 -> OHT-LAB2 / pve2
docker3 -> OHT-LAB3 / pve3
docker4 -> OHT-LAB4 / pve4
```

## Initial Rollout

1. Add `docker1` through `docker4` as Komodo Servers with Periphery agents.
2. Configure the Git provider for this repository.
3. Create a Resource Sync that points at `komodo/resources/sync.toml`.
4. Start with detect-and-review sync behavior.
5. Enable automatic deployment only after webhook behavior is verified on a non-critical stack.
