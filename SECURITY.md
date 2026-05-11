# Security Policy

## Secrets

Do not commit secrets, private keys, API tokens, production passwords, or real
`.env` files.

Use `.env.example` files to document required variables. Store runtime values in
Komodo, on the target host, or in another approved secret store.

## Reporting

For private security issues, report the issue through the repository owner or
the OHT-LAB maintainer channel instead of opening a public issue.

## Baseline Controls

- Protect `main`.
- Require pull request validation before merge.
- Use least-privilege tokens for GitHub and Komodo integrations.
- Review image updates through pull requests.
- Keep backups for Komodo state, stack configuration, and persistent volumes.
