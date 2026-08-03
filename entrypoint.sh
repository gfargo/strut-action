#!/usr/bin/env bash
# ==========================================================================
# strut-action entrypoint — install strut, wire up SSH + env, run the command.
# Invoked by action.yml (composite). All inputs arrive as INPUT_* env vars.
# ==========================================================================
set -euo pipefail

# ── Inputs ────────────────────────────────────────────────────────────────
stack="${INPUT_STACK:?stack input is required}"
command="${INPUT_COMMAND:-release}"
env_name="${INPUT_ENV:-}"
services="${INPUT_SERVICES:-}"
strict="${INPUT_STRICT:-false}"
dry_run="${INPUT_DRY_RUN:-false}"
extra_args="${INPUT_ARGS:-}"
ssh_key="${INPUT_SSH_KEY:-}"
ssh_host="${INPUT_HOST:-}"
ssh_user="${INPUT_USER:-}"
ssh_port="${INPUT_PORT:-22}"
known_hosts="${INPUT_KNOWN_HOSTS:-}"
env_file_contents="${INPUT_ENV_FILE:-}"
strut_version="${INPUT_STRUT_VERSION:-v0.45.3}"
workdir="${INPUT_WORKING_DIRECTORY:-.}"

# GitHub Actions log grouping helpers (no-ops outside Actions).
group() { echo "::group::$1"; }
endgroup() { echo "::endgroup::"; }

# ── 1. Install strut ──────────────────────────────────────────────────────
group "Install strut ($strut_version)"
install_dir="${RUNNER_TEMP:-/tmp}/strut-engine"
rm -rf "$install_dir"

case "$strut_version" in
  latest)
    ref="$(git ls-remote --tags --refs --sort=-v:refname \
            https://github.com/gfargo/strut.git 'v*' \
            | head -n1 | sed 's#.*/##')"
    [ -n "$ref" ] || ref="main"
    ;;
  main)
    ref="main"
    ;;
  v*)
    ref="$strut_version"
    ;;
  *)
    ref="v$strut_version"
    ;;
esac

echo "Installing strut ref: $ref"
git clone --depth 1 --branch "$ref" https://github.com/gfargo/strut.git "$install_dir"
echo "$install_dir" >> "${GITHUB_PATH:-/dev/null}"
export PATH="$install_dir:$PATH"
echo "strut $(strut --version)"
endgroup

# ── 2. SSH key + known_hosts ──────────────────────────────────────────────
key_path=""
if [ -n "$ssh_key" ]; then
  group "Configure SSH"
  mkdir -p "$HOME/.ssh"
  chmod 700 "$HOME/.ssh"
  key_path="$HOME/.ssh/strut_ci_key"
  printf '%s\n' "$ssh_key" > "$key_path"
  chmod 600 "$key_path"

  if [ -n "$known_hosts" ]; then
    printf '%s\n' "$known_hosts" >> "$HOME/.ssh/known_hosts"
  elif [ -n "$ssh_host" ]; then
    ssh-keyscan -p "$ssh_port" "$ssh_host" >> "$HOME/.ssh/known_hosts" 2>/dev/null || \
      echo "::warning::ssh-keyscan failed for $ssh_host:$ssh_port; relying on strut's StrictHostKeyChecking handling"
  fi
  [ -f "$HOME/.ssh/known_hosts" ] && chmod 600 "$HOME/.ssh/known_hosts"
  endgroup
fi

# ── 3. Materialize the env file ───────────────────────────────────────────
# strut reads .<env>.env (or .env) from the project root via `set -a; source`.
cd "$workdir"

target_env=".env"
[ -n "$env_name" ] && target_env=".${env_name}.env"

group "Prepare $target_env"
{
  [ -n "$env_file_contents" ] && printf '%s\n' "$env_file_contents"
  # Connection vars are appended last so they win over any in env-file.
  [ -n "$ssh_host" ] && echo "VPS_HOST=$ssh_host"
  [ -n "$ssh_user" ] && echo "VPS_USER=$ssh_user"
  [ -n "$ssh_port" ] && echo "VPS_PORT=$ssh_port"
  [ -n "$key_path" ] && echo "VPS_SSH_KEY=$key_path"
} >> "$target_env"
chmod 600 "$target_env" 2>/dev/null || true
echo "Wrote connection config to $target_env (values redacted)"
endgroup

# ── 4. Build and run the strut command ────────────────────────────────────
set -- "$stack" "$command"
[ -n "$env_name" ]      && set -- "$@" --env "$env_name"
[ -n "$services" ]      && set -- "$@" --services "$services"
[ "$strict" = "true" ]  && set -- "$@" --strict
[ "$dry_run" = "true" ] && set -- "$@" --dry-run

# A CI runner can never legitimately mean "deploy to this runner". Since strut
# 0.45.0 `deploy` resolves its target from the stack's topology, and falls back
# to the local Docker daemon when that resolves to nothing — on a runner that is
# a no-op which exits 0 and reports a successful deploy. --require-remote makes
# it a hard failure instead. `release` is an alias for `deploy --require-remote`
# and already implies it; passing it for both keeps the two spellings identical.
#
# Safe on older strut: unknown flags fall through the arg parser's catch-all and
# are ignored. On < 0.45.0 you simply don't get the guard.
case "$command" in
  deploy|release) set -- "$@" --require-remote ;;
esac

echo "+ strut $* $extra_args"
# extra_args is intentionally word-split to allow multiple raw flags.
# shellcheck disable=SC2086
strut "$@" $extra_args
