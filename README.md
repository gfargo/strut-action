# strut-action

Deploy Docker Compose stacks to **any VPS over SSH** from GitHub Actions — powered by [strut](https://github.com/gfargo/strut). No Kubernetes, no proprietary runners.

```yaml
- uses: gfargo/strut-action@v1
  with:
    stack: my-app
    command: deploy
    env: prod
    host: ${{ secrets.STRUT_HOST }}
    user: ${{ secrets.STRUT_USER }}
    ssh-key: ${{ secrets.STRUT_SSH_KEY }}
```

This action installs strut, wires up the SSH key and connection config, and runs the strut command against your VPS. Your repository is the strut **project root** — it must contain `strut.conf` and `stacks/<stack>/` (run `strut init` + `strut scaffold` locally to create them).

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `stack` | ✅ | — | Stack name (a directory under `stacks/`). |
| `command` | | `deploy` | `deploy` \| `ship` \| `health` \| `stop` \| `status`. `deploy` goes to the host the stack maps to; the action adds `--require-remote` so a stack that resolves to no VPS fails instead of deploying to the runner. `release` is an accepted alias. |
| `env` | | `''` | Environment name; reads `.<env>.env` (e.g. `prod` → `.prod.env`). |
| `services` | | `''` | Service profile passed as `--services` (e.g. `full`). |
| `strict` | | `false` | Pass `--strict` (fail the deploy if migrations fail). |
| `dry-run` | | `false` | Pass `--dry-run` to preview without executing. |
| `args` | | `''` | Extra raw arguments appended to the command. |
| `ssh-key` | ✅ | — | Private SSH key authorized on the VPS. **Always pass via a secret.** |
| `host` | | `''` | VPS host/IP → `VPS_HOST`. |
| `user` | | `''` | VPS SSH user → `VPS_USER`. |
| `port` | | `22` | VPS SSH port → `VPS_PORT`. |
| `known-hosts` | | `''` | `known_hosts` entries. If empty, the host key is fetched via `ssh-keyscan`. |
| `env-file` | | `''` | Full contents of `.<env>.env`. **Always pass via a secret.** Optional. |
| `strut-version` | | `latest` | `latest` \| `main` \| `vX.Y.Z`. |
| `working-directory` | | `.` | Project root containing `strut.conf`. |

## How connection config works

The action writes the VPS connection variables (`VPS_HOST`, `VPS_USER`, `VPS_PORT`, `VPS_SSH_KEY`) into the target env file (`.<env>.env`). If you pass `env-file`, those contents are written first and the connection variables are appended last (so they take precedence). strut sources this file before connecting.

If your repo already configures hosts via `strut.conf` multi-host topology, you can omit `host`/`user` and just provide `ssh-key`.

## Security

- Pass `ssh-key` and `env-file` **only** as GitHub secrets — never inline.
- Secret values are written to files with `0600` perms on the ephemeral runner and are never echoed to logs.
- Scope the deploy key to the single VPS; rotate with `strut keys ssh:rotate` / regenerate with `strut <stack> ssh:keygen`.

## Versioning

Pin to the moving major tag `@v1` for automatic patch/minor updates, or pin an exact release (`@v1.2.3`) for full reproducibility.

## License

MIT © gfargo
