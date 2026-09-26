# Mizan: Architecture Decision Records

## ADR-001 Region & Models
- Region: UAE North for all resources (verified 2026-09-26 via az cognitiveservices model list).
- Models: gpt-5.4-mini (agent), gpt-5.4-nano (helper tasks), text-embedding-3-small (embeddings). Versions pinned.
- Deployment type: Global Standard in dev (cost/quota); Standard regional in prod (UAE data residency).
- Review model retirement schedule quarterly.

## ADR-002 Naming & Tags
- Pattern: <type>-mizan-<env>-<region>, e.g. rg-mizan-dev-uaen.
- Tags on every resource: project=mizan, env, owner=heart, costmode=core|temp.

## ADR-003 Cost Guardrails
- $30 monthly budget: alerts at 50% actual, 80% actual, 100% forecasted. Anomaly alerts on.
- Free Account limits: Linux B1s VM + Premium SSD ≤64 GB, Cosmos ≤400 RU/s & ≤25 GB, Blob Hot LRS ≤5 GB, SQL S0.
- Expensive services tagged costmode=temp and deleted same day.

## ADR-004 Shared Responsibility
- IaaS: jumpbox VM (I patch OS).
- PaaS: App Service, Functions, SQL, Cosmos, AI Search, Redis, AKS (Microsoft runs platform; I own code, config, data).
- SaaS: Entra ID (I own identities and access).
- AI layer: Microsoft secures model infra; I own grounding data, prompts, content filters, output validation, tool permissions.

## ADR-005 Subscription Model
- Free Trial ($200 credit) upgraded to Pay-As-You-Go before expiry to keep 12-month free services.
- After upgrade, budget + anomaly alerts are the main cost controls (no spending limit).

## Well-Architected Mapping
| Pillar | How Mizan addresses it |
|---|---|
| Reliability | Stateless API, managed PaaS, Bicep redeploy in minutes |
| Security | Managed identity, no keys, private endpoints, WAF, content safety |
| Cost | Free tiers, mini/nano models, semantic cache, costmode=temp cleanup |
| Operational Excellence | IaC, CI/CD, ADRs, App Insights tracing |
| Performance | Redis cache, hybrid search, autoscale |