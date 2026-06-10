# appsec-advisor internes Plugin-Package

Dieses Repo ist ein Beispiel fuer ein internes Packaging von `appsec-advisor`. Es enthaelt nur die organisationsspezifische Konfiguration und Build-Dateien. Der eigentliche Plugin-Code wird aus dem Upstream-Repo nach `upstream/appsec-advisor` geholt.

Das gebaute Plugin heisst in diesem Beispiel `example-appsec` und wird spaeter so in Claude Code verwendet:

```text
/example-appsec:create-threat-model
```

## Upstream

Geklont wird die konkrete Git-Remote:

```text
https://github.com/matthiasrohr/appsec-advisor.git
```

`https://github.com/matthiasrohr?tab=repositories` ist nur die Browser-Uebersicht der Repositories und keine Clone-URL.

Der lokale Checkout liegt unter:

```text
upstream/appsec-advisor
```

Per Default wird `APPSEC_ADVISOR_REF=latest` verwendet. Das Script loest `latest` auf das hoechste versionierte Tag nach Muster `v*` auf. Fuer reproduzierbare Builds sollte ein konkretes Release-Tag gesetzt werden, zum Beispiel `v0.4.0-beta`.

## Dateien

- `org-profile/org-profile.yaml` - Defaults, Requirements-Quelle, Presets und Limits.
- `org-profile/context/organization.md` - kurzer Organisationskontext fuer Analysen.
- `org-profile/actors/insiders.yaml` - Beispiel fuer einen eigenen Enterprise Actor.
- `org-profile/package-policy.yaml` - Allowlist fuer Skills und Hooks im internen Package.
- `scripts/fetch-upstream.sh` - holt `appsec-advisor` nach `upstream/appsec-advisor`.
- `scripts/package-local.sh` - baut das interne Plugin lokal.
- `Makefile` - kurze lokale Befehle.
- `.github/workflows/package.yml` - GitHub Actions Beispiel.
- `.gitlab-ci.yml` - GitLab CI Beispiel.

## Lokal bauen

Standard: Upstream holen, Package bauen, Smoke-Test ausfuehren.

```bash
make package
```

Ein konkretes Release verwenden:

```bash
APPSEC_ADVISOR_REF=v0.4.0-beta make package
```

Ein Archiv fuer die Weitergabe bauen:

```bash
ARCHIVE=1 VERSION=0.4.0-example.20260610 make package-archive
```

Die Artefakte liegen danach hier:

```text
build/example-appsec
dist/example-appsec-<version>.tgz
dist/example-appsec-<version>.tgz.sha256
```

Wenn bereits ein lokaler Checkout verwendet werden soll:

```bash
APPSEC_ADVISOR_SOURCE=/home/mrohr/appsec-advisor make package
```

## Plugin starten

```bash
claude --plugin-dir build/example-appsec
```

In Claude Code:

```text
/example-appsec:check-permissions --update
/example-appsec:create-threat-model
/example-appsec:create-threat-model --preset release-review
```

## CI

Die CI-Jobs machen dasselbe wie der lokale Build: Upstream holen, Package bauen, Smoke-Test ausfuehren und das `.tgz` mit `.sha256` als Artefakt ablegen.

| Variable | Default | Bedeutung |
|---|---|---|
| `APPSEC_ADVISOR_URL` | `https://github.com/matthiasrohr/appsec-advisor.git` | Upstream-Repo oder interner Fork |
| `APPSEC_ADVISOR_REF` | `latest` | `latest`, Release-Tag, Branch oder Commit |
| `INTERNAL_NAME` | `example-appsec` | Name und Command-Namespace des internen Plugins |
| `VERSION` | CI-spezifisch | Version des erzeugten internen Packages |

## Anpassen

1. In `org-profile/org-profile.yaml` die Werte unter `organization` anpassen.
2. `requirements.source.requirements_yaml_url` auf den internen Requirements-Katalog setzen.
3. `org-profile/context/organization.md` durch echten, kurzen Organisationskontext ersetzen.
4. `org-profile/actors/insiders.yaml` anpassen oder entfernen.
5. `org-profile/package-policy.yaml` reviewen und nur freigegebene Skills oder Hooks aufnehmen.

## Referenz

- `/home/mrohr/appsec-advisor/README.md`
- `/home/mrohr/appsec-advisor/docs/internal-plugin-packaging.md`
- `/home/mrohr/appsec-advisor/docs/org-profiles.md`
