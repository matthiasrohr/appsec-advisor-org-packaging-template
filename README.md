# appsec-advisor — Example Org Packaging Repo

This is an **example implementation** of an internal org packaging repo for the [`appsec-advisor`](https://github.com/matthiasrohr/appsec-advisor) Claude Code plugin. It demonstrates how to wrap the upstream plugin into a company-branded package with your own defaults, requirements catalog, and cost guardrails.

Fork this repo, replace the `Acme Corp` placeholders, and your developers get a single command with your org's configuration already baked in:

```text
/your-plugin-name:create-threat-model
```

The upstream plugin code is fetched at build time — this repo contains only your org-specific configuration and the build scripts. For all customization options, see the [org-profile reference](https://github.com/matthiasrohr/appsec-advisor/blob/main/docs/org-profiles.md) and the [full packaging runbook](https://github.com/matthiasrohr/appsec-advisor/blob/main/docs/internal-plugin-packaging.md) in the upstream repo.

## Quick Start

**Prerequisites:** `git`, `python3` (3.10+), `make`

**1. Fork this repo** and clone it locally.

**2. Set up CI for your platform** — run one of:

```bash
make ci-github   # copies ci-templates/github/workflows/package.yml → .github/workflows/
make ci-gitlab   # copies ci-templates/gitlab-ci.yml → .gitlab-ci.yml
```

Then replace `acme-appsec` in two places:

| File | What to change |
|---|---|
| `Makefile` | `INTERNAL_NAME ?= acme-appsec` |
| `.github/workflows/package.yml` or `.gitlab-ci.yml` | `INTERNAL_NAME` variable |

**3. Edit your org profile** in `org-profile/org-profile.yaml` — only three fields are required:
- `organization.id` — a short lowercase identifier, e.g. `acme`
- `organization.name` — display name, e.g. `Acme Corp`
- `organization.profile_version` — a version string you control, e.g. `2026.06.1`

Everything else (requirements catalog URL, context documents, custom actors, presets) is optional and can be added incrementally.

**4. Build the plugin locally:**

```bash
make package
```

This fetches the upstream plugin, overlays your org profile, runs a smoke test, and writes the result to `build/your-plugin-name/`.

**5. Load it in Claude Code:**

```bash
claude --plugin-dir build/your-plugin-name
```

**6. Run your first threat model:**

```text
/your-plugin-name:check-permissions --update
/your-plugin-name:create-threat-model
```

That's it. For CI, tagging a release triggers the pipeline set up in step 2 automatically.

## Customization

Beyond the quick start, these files are yours to edit:

| File | Purpose |
|---|---|
| `org-profile/org-profile.yaml` | Presets, cost guardrails, requirements source, output formats |
| `org-profile/context/organization.md` | Short org context injected into analyses (max 50 KB) |
| `org-profile/actors/insiders.yaml` | Custom threat actors for your threat models — edit or delete |
| `org-profile/package-policy.yaml` | Allowlist of which upstream skills and hooks to include |
| `scripts/package-local.sh` | Update `--description` to replace "Acme Corp" in the package manifest |

`build/`, `dist/`, and `upstream/` are all generated — do not commit them.

## Build Reference

```bash
# Validate org profile only (fetches upstream if APPSEC_ADVISOR_SOURCE is not set)
make validate

# Fetch upstream + build + smoke test
make package

# Pin a specific upstream release
APPSEC_ADVISOR_REF=v0.4.0-beta make package

# Build a distributable archive (.tgz + .sha256)
ARCHIVE=1 VERSION=0.4.0-example.20260610 make package-archive

# Use an existing local upstream checkout
APPSEC_ADVISOR_SOURCE=/path/to/local/appsec-advisor make package
```

Build artifacts:

```text
build/acme-appsec/
build/acme-appsec/.claude-plugin/package-surface.json
dist/acme-appsec-<version>.tgz
dist/acme-appsec-<version>.tgz.sha256
```

## CI

Run `make ci-github` or `make ci-gitlab` to install the CI pipeline for your platform (see Quick Start step 2). Both do the same as the local build: fetch upstream, build, smoke test, and upload the `.tgz` with its `.sha256` as a build artifact. The pipeline triggers on `v*` tags and `workflow_dispatch`.

The templates live in `ci-templates/` — edit them there before running `make ci-*` if you need to customize the pipeline.

| Variable | Default | Description |
|---|---|---|
| `APPSEC_ADVISOR_URL` | `https://github.com/matthiasrohr/appsec-advisor.git` | Upstream repo or internal fork |
| `APPSEC_ADVISOR_REF` | `v0.4.0-beta` | Release tag, branch, or commit — pin this for reproducible builds |
| `INTERNAL_NAME` | `acme-appsec` | Plugin name and Claude Code command namespace |
| `VERSION` | derived from git tag or commit SHA | Version of the produced package |

## Reference

- [github.com/matthiasrohr/appsec-advisor](https://github.com/matthiasrohr/appsec-advisor) — upstream plugin (this repo is an example packaging of it)
- [docs/internal-plugin-packaging.md](https://github.com/matthiasrohr/appsec-advisor/blob/main/docs/internal-plugin-packaging.md) — full packaging runbook with all build and distribution options
- [docs/org-profiles.md](https://github.com/matthiasrohr/appsec-advisor/blob/main/docs/org-profiles.md) — complete org-profile.yaml reference: all presets, guardrails, requirements, actors, and skill toggles
