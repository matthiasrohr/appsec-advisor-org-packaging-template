#!/usr/bin/env bash
# Creates a fresh org packaging repo for appsec-advisor.
# Usage: bash <(curl -fsSL https://raw.githubusercontent.com/matthiasrohr/appsec-advisor-org-packaging-example/main/scripts/init-org-repo.sh)
# Or locally: scripts/init-org-repo.sh
set -euo pipefail

# ── Helpers ──────────────────────────────────────────────────────────────────

ask() {
  local prompt="$1" default="${2:-}"
  local reply
  if [ -n "${default}" ]; then
    read -r -p "${prompt} [${default}]: " reply
    echo "${reply:-${default}}"
  else
    while true; do
      read -r -p "${prompt}: " reply
      [ -n "${reply}" ] && break
      echo "  (required)" >&2
    done
    echo "${reply}"
  fi
}

slug() {
  echo "$1" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/-\+/-/g' | sed 's/^-//;s/-$//'
}

# Escape a string for safe use as a sed replacement (escapes & \ and /).
sed_escape() {
  printf '%s' "$1" | sed 's/[&/\]/\\&/g'
}

# ── Intro ─────────────────────────────────────────────────────────────────────

echo ""
echo "appsec-advisor — org packaging repo setup"
echo "────────────────────────────────────────────"
echo "This script creates a ready-to-use packaging repo for appsec-advisor."
echo "You will need: git, python3 (3.10+), make"
echo ""

# ── Gather input ─────────────────────────────────────────────────────────────

ORG_NAME=$(ask "Organization name (e.g. Acme Corp)")
ORG_ID=$(slug "${ORG_NAME}")
ORG_ID=$(ask "Organization id (short lowercase, used in plugin name)" "${ORG_ID}")
PLUGIN_NAME=$(ask "Plugin name (Claude Code command prefix)" "${ORG_ID}-appsec")
OWNER=$(ask "Team owner (e.g. AppSec Team)" "${ORG_NAME} AppSec Team")
TARGET_DIR=$(ask "Target directory" "./${PLUGIN_NAME}-packaging")

echo ""

# ── Source files ──────────────────────────────────────────────────────────────

# Resolve absolute path so relative-path invocations work correctly.
SCRIPT_ABS="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)/$(basename "${BASH_SOURCE[0]}")" || true
TEMPLATE_BASE="${SCRIPT_ABS%/scripts/init-org-repo.sh}"

# When invoked via curl/pipe the path above resolves to something like /dev/fd/N
# which has no Makefile — fall back to cloning.
if [ ! -f "${TEMPLATE_BASE}/Makefile" ]; then
  TMPDIR_CLONE="$(mktemp -d)"
  trap 'rm -rf "${TMPDIR_CLONE}"' EXIT
  echo "==> Cloning template from GitHub …"
  git clone --depth 1 \
    "https://github.com/matthiasrohr/appsec-advisor-org-packaging-example.git" \
    "${TMPDIR_CLONE}"
  TEMPLATE_BASE="${TMPDIR_CLONE}"
fi

# ── Create repo ───────────────────────────────────────────────────────────────

if [ -e "${TARGET_DIR}" ]; then
  echo "ERROR: '${TARGET_DIR}' already exists." >&2
  exit 1
fi

mkdir -p \
  "${TARGET_DIR}/org-profile/context" \
  "${TARGET_DIR}/org-profile/actors" \
  "${TARGET_DIR}/scripts" \
  "${TARGET_DIR}/ci-templates/github/workflows"

# Copy fetch script verbatim; package-local.sh is rendered below with org substitutions
cp "${TEMPLATE_BASE}/scripts/fetch-upstream.sh" "${TARGET_DIR}/scripts/fetch-upstream.sh"
chmod +x "${TARGET_DIR}/scripts/fetch-upstream.sh"

cp "${TEMPLATE_BASE}/ci-templates/github/workflows/package.yml" \
   "${TARGET_DIR}/ci-templates/github/workflows/package.yml"
cp "${TEMPLATE_BASE}/ci-templates/gitlab-ci.yml" \
   "${TARGET_DIR}/ci-templates/gitlab-ci.yml"

cp "${TEMPLATE_BASE}/.gitignore" "${TARGET_DIR}/.gitignore"
cp "${TEMPLATE_BASE}/org-profile/package-policy.yaml" \
   "${TARGET_DIR}/org-profile/package-policy.yaml"

# ── Render Makefile ───────────────────────────────────────────────────────────

E_PLUGIN=$(sed_escape "${PLUGIN_NAME}")
sed "s/acme-appsec/${E_PLUGIN}/g" \
  "${TEMPLATE_BASE}/Makefile" > "${TARGET_DIR}/Makefile"

# ── Render org-profile.yaml ───────────────────────────────────────────────────

TODAY="$(date +%Y.%m.1)"
E_ORG_ID=$(sed_escape "${ORG_ID}")
E_ORG_NAME=$(sed_escape "${ORG_NAME}")
E_OWNER=$(sed_escape "${OWNER}")
sed \
  -e "s/id: acme/id: ${E_ORG_ID}/" \
  -e "s/name: Acme Corp/name: ${E_ORG_NAME}/" \
  -e "s/profile_version: \"2026.06.1\"/profile_version: \"${TODAY}\"/" \
  -e "s/owner: Acme AppSec Team/owner: ${E_OWNER}/" \
  -e "s/label: \"Acme Corp AppSec Requirements\"/label: \"${E_ORG_NAME} AppSec Requirements\"/" \
  "${TEMPLATE_BASE}/org-profile/org-profile.yaml" > "${TARGET_DIR}/org-profile/org-profile.yaml"

# ── Render organization.md ────────────────────────────────────────────────────

cat > "${TARGET_DIR}/org-profile/context/organization.md" <<EOF
# ${ORG_NAME} — Organization Context

Replace this stub with a short, factual description of your organization owned
by the AppSec or platform team. This file is loaded as reference data into
threat model analyses — it can inform findings, but it cannot change severity
rules, QA gates, schemas, permissions, or tool behavior.

Keep this under 50 KB. Plain Markdown only.
EOF

# ── Render actors stub ────────────────────────────────────────────────────────

cat > "${TARGET_DIR}/org-profile/actors/custom-actors.yaml" <<EOF
# Custom threat actors for ${ORG_NAME}.
# Add, edit, or delete entries as needed.
# Schema reference: https://github.com/matthiasrohr/appsec-advisor/blob/main/docs/org-profiles.md
actors: []
EOF

# ── Render AGENTS.md ──────────────────────────────────────────────────────────

sed \
  -e "s/acme-appsec/${E_PLUGIN}/g" \
  -e "s/Acme Corp/${E_ORG_NAME}/g" \
  "${TEMPLATE_BASE}/AGENTS.md" > "${TARGET_DIR}/AGENTS.md"

# ── Render README.md ──────────────────────────────────────────────────────────

cat > "${TARGET_DIR}/README.md" <<EOF
# ${PLUGIN_NAME} — Internal appsec-advisor Plugin

Internal packaging repo for the [\`appsec-advisor\`](https://github.com/matthiasrohr/appsec-advisor) Claude Code plugin, maintained by ${OWNER}.

Developers get a single command with ${ORG_NAME} defaults already baked in:

\`\`\`text
/${PLUGIN_NAME}:create-threat-model
\`\`\`

The upstream plugin code is fetched at build time — this repo contains only
org-specific configuration and build scripts.

## Quick Start

**Prerequisites:** \`git\`, \`python3\` (3.10+), \`make\`

**1. Set up CI for your platform** — run one of:

\`\`\`bash
make ci-github   # copies ci-templates/github/workflows/package.yml → .github/workflows/
make ci-gitlab   # copies ci-templates/gitlab-ci.yml → .gitlab-ci.yml
\`\`\`

**2. Edit your org profile** in \`org-profile/org-profile.yaml\` — three fields are required:
- \`organization.id\` — short lowercase identifier, e.g. \`${ORG_ID}\`
- \`organization.name\` — display name, e.g. \`${ORG_NAME}\`
- \`organization.profile_version\` — a version string you control, e.g. \`2026.06.1\`

Point \`requirements.source.requirements_yaml_url\` to your internal requirements catalog
(or remove the block if you don't have one yet).

**3. Build the plugin locally:**

\`\`\`bash
make package
\`\`\`

This fetches the upstream plugin, overlays your org profile, runs a smoke test, and
writes the result to \`build/${PLUGIN_NAME}/\`. To force a clean rebuild:

\`\`\`bash
make rebuild
\`\`\`

**4. Load it in Claude Code:**

\`\`\`bash
claude --plugin-dir build/${PLUGIN_NAME}
\`\`\`

**5. Run your first threat model:**

\`\`\`text
/${PLUGIN_NAME}:check-permissions --update
/${PLUGIN_NAME}:create-threat-model
\`\`\`

That's it. For CI, tagging a release triggers the pipeline set up in step 1 automatically.

## Customization

Beyond the quick start, these files are yours to edit:

| File | Purpose |
|---|---|
| \`org-profile/org-profile.yaml\` | Presets, cost guardrails, requirements source, output formats |
| \`org-profile/context/organization.md\` | Short org context injected into analyses (max 50 KB) |
| \`org-profile/actors/*.yaml\` | Custom threat actors for threat models — edit or delete |
| \`org-profile/package-policy.yaml\` | Allowlist of which upstream skills and hooks to include |

\`build/\`, \`dist/\`, and \`upstream/\` are all generated — do not commit them.

## Build Reference

\`\`\`bash
# Validate org profile only
make validate

# Fetch upstream + build + smoke test
make package

# Force a clean rebuild (removes upstream/, build/, dist/ first)
make rebuild

# Remove all generated directories
make clean

# Pin a specific upstream release
APPSEC_ADVISOR_REF=v0.4.0-beta make package

# Build a distributable archive (.tgz + .sha256)
ARCHIVE=1 VERSION=1.0.0 make package-archive

# Use an existing local upstream checkout
APPSEC_ADVISOR_SOURCE=/path/to/local/appsec-advisor make package
\`\`\`

## CI

Run \`make ci-github\` or \`make ci-gitlab\` to install the CI pipeline (see Quick Start step 1).
Both do the same as the local build: fetch upstream, build, smoke test, and upload the
\`.tgz\` with its \`.sha256\` as a build artifact. The pipeline triggers on \`v*\` tags and
\`workflow_dispatch\`.

| Variable | Default | Description |
|---|---|---|
| \`APPSEC_ADVISOR_URL\` | upstream GitHub | Upstream repo or internal fork |
| \`APPSEC_ADVISOR_REF\` | \`latest\` | Release tag, branch, or commit — pin for reproducible builds |
| \`INTERNAL_NAME\` | \`${PLUGIN_NAME}\` | Plugin name and Claude Code command namespace |
| \`VERSION\` | derived from git tag or commit SHA | Version of the produced package |

## Reference

- [appsec-advisor upstream](https://github.com/matthiasrohr/appsec-advisor)
- [docs/org-profiles.md](https://github.com/matthiasrohr/appsec-advisor/blob/main/docs/org-profiles.md) — full org-profile.yaml reference
- [docs/internal-plugin-packaging.md](https://github.com/matthiasrohr/appsec-advisor/blob/main/docs/internal-plugin-packaging.md) — packaging runbook
EOF

# ── Render package-local.sh with correct org name ─────────────────────────────

sed \
  -e "s/acme-appsec/${E_PLUGIN}/g" \
  -e "s/Acme Corp/${E_ORG_NAME}/g" \
  "${TEMPLATE_BASE}/scripts/package-local.sh" > "${TARGET_DIR}/scripts/package-local.sh"
chmod +x "${TARGET_DIR}/scripts/package-local.sh"

# ── Render CI files with correct plugin name ──────────────────────────────────

sed -i \
  -e "s/acme-appsec/${E_PLUGIN}/g" \
  -e "s/Acme Corp/${E_ORG_NAME}/g" \
  "${TARGET_DIR}/ci-templates/github/workflows/package.yml" \
  "${TARGET_DIR}/ci-templates/gitlab-ci.yml"

# ── Init git repo ─────────────────────────────────────────────────────────────

cd "${TARGET_DIR}"
git init -q
git add .
git commit -q -m "init: ${PLUGIN_NAME} packaging repo for ${ORG_NAME}"

echo ""
echo "Done. Your packaging repo is ready at: ${TARGET_DIR}"
echo ""
echo "Next steps:"
echo "  1. Edit org-profile/org-profile.yaml — set your requirements URL and presets"
echo "  2. Edit org-profile/context/organization.md — describe your org for analyses"
echo "  3. Run: cd ${TARGET_DIR} && make package"
echo "  4. Set up CI: make ci-github  or  make ci-gitlab"
