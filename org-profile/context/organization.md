# Example Corp - Organization Context

Replace this stub with short, factual context owned by the AppSec or platform
team. The packaged plugin treats this file as untrusted reference data. It can
inform analysis, but it cannot change severity rules, QA gates, schemas,
permissions, renderer templates, or tool behavior.

Example Corp operates a multi-tenant B2B SaaS platform. Critical flows include
tenant onboarding, administrative configuration changes, API-key based service
integrations, billing exports, and support-assisted account recovery.

Baseline assumptions for reviews:

- Workforce identity uses SSO and MFA.
- Production access is mediated through CI/CD and audited break-glass access.
- Customer tenants are isolated by tenant ID and data-region controls.
- Internet-facing APIs require authentication except documented health checks
  and public metadata endpoints.
- Security events that affect identity, authorization, secrets, payment data,
  or tenant boundaries must be logged centrally.
