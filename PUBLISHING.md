# Publishing strut-action to the GitHub Marketplace

The Marketplace listing is created from a **GitHub Release** in this repo. The CLI
can't publish to Marketplace, so this is a one-time manual step in the GitHub UI.

## 0. Prerequisites (already satisfied)

- [x] `action.yml` lives at the repo root with `name`, `description`, and `branding` (`icon: upload-cloud`, `color: yellow`). Marketplace requires all three.
- [x] `README.md` at the root (Marketplace renders it as the listing body).
- [x] A public repo with a semver tag (`v1.0.0` + moving `v1`).
- [ ] First time only: accept the **GitHub Marketplace Developer Agreement** (prompted during the first publish).

> ⚠️ **Action name must be globally unique on the Marketplace.** `action.yml` currently uses `name: strut deploy`. If the publish form says the name is taken, change `name:` to a unique variant (see options below), commit, and re-tag.

## 1. Draft the release

GitHub → the repo → **Releases → Draft a new release**:

- **Choose a tag:** `v1.0.0` (already pushed).
- **Release title:** `v1.0.0 — Deploy Docker stacks to any VPS from CI`
- **Description:** paste the release notes from the section below.
- ✅ Check **"Publish this Action to the GitHub Marketplace."** (Appears once `action.yml` metadata is valid.)
- Accept the Developer Agreement if prompted.

## 2. Categorize

- **Primary category:** Deployment
- **Secondary category:** Continuous integration
- Confirm the **icon** (`upload-cloud`) and **color** (`yellow`) preview looks right.

## 3. Publish

Click **Publish release**. The listing goes live at
`https://github.com/marketplace/actions/<slug>`. Verify the README renders and the
`uses:` snippet shows the right ref.

## 4. Keep the major tag moving (each future release)

```bash
git tag -fa v1 -m "strut-action v1 -> vX.Y.Z"
git push -f origin v1
```

Consumers pinned to `@v1` pick up the update automatically; `@vX.Y.Z` stays immutable.

---

## Listing copy (ready to paste)

**Name (primary choice):** `strut deploy`
**Name (fallbacks if taken):** `Deploy with strut` · `strut VPS Deploy` · `strut — Docker deploy over SSH`

**Short description (≤ 125 chars):**
> Deploy Docker Compose stacks to any VPS over SSH with strut — no Kubernetes, no self-hosted runner.

**Longer blurb (listing intro):**
> strut-action installs the strut CLI, wires up your SSH key and connection config, and runs a strut command (release, deploy, ship, health…) against your own server. Bring your `strut.conf` + `stacks/`, add three secrets, and ship on every push. Works on any Linux VPS — DigitalOcean, Hetzner, a Raspberry Pi, bare metal.

**Suggested tags/keywords:** `deployment`, `docker`, `docker-compose`, `vps`, `ssh`, `ci-cd`, `self-hosted`, `bash`

### Release notes (v1.0.0)

```markdown
First release of the official GitHub Action for [strut](https://github.com/gfargo/strut).

Deploy Docker Compose stacks to any VPS over SSH, straight from your workflow:

```yaml
- uses: gfargo/strut-action@v1
  with:
    stack: my-app
    command: release
    env: prod
    host: ${{ secrets.STRUT_HOST }}
    user: ${{ secrets.STRUT_USER }}
    ssh-key: ${{ secrets.STRUT_SSH_KEY }}
```

**Highlights**
- Runs any strut command: `release`, `deploy`, `ship`, `health`, `stop`, `status`, `exec`
- Secure by default: SSH key + env written with 0600, never echoed to logs
- Pin `@v1` for automatic updates, or an exact `@v1.0.0`
- No Kubernetes, no self-hosted runner

See the README for the full input reference.
```
