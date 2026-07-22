# LearningSignal

LearningSignal helps educators notice meaningful changes in student mastery, investigate them against curriculum evidence, and approve a practical intervention plan. The current milestone is a local-first Rails vertical slice built from synthetic data.

## What works

- Password authentication using Rails' built-in session pattern
- Organization and school tenancy with Pundit authorization
- Deterministic mastery-decline signals
- Curriculum PDF upload, duplicate detection, page-level extraction, chunking, and embeddings
- Preview-first CSV imports for synthetic rosters, enrollments, and mastery timelines
- Preview-first assessment catalogs and raw response imports with deterministic scoring
- Tenant-scoped student academic profiles with objective mastery, responses, signals, and interventions
- Background investigations with live Turbo progress updates
- Hybrid curriculum retrieval using PostgreSQL full-text signals and pgvector similarity
- Strictly structured, citation-validated AI observations and intervention plans
- Teacher editing, approval, rejection, snapshots, and hash-chained audit events
- Closed-loop intervention outcomes with action completion, follow-up mastery, effectiveness, and generated-vs-reviewed comparisons
- Configurable deterministic, OpenAI, and OpenAI-compatible AI drivers
- Version-controlled AI and retrieval evaluations with persisted metrics, reproducible reports, and CI quality gates

AI output is advisory. It cannot diagnose a student, change grades, contact families, or execute an intervention without an educator's decision.

## Start locally

Requirements: Docker Desktop with Docker Compose.

```bash
cp .env.example .env
docker compose up --build
docker compose exec web ./bin/rails db:seed
```

Open [http://localhost:3000](http://localhost:3000) and sign in with:

```text
teacher@learningsignal.test
learning-signal-demo
```

Supporting services:

| Service | URL | Purpose |
| --- | --- | --- |
| Rails | http://localhost:3000 | Web application |
| Mailpit | http://localhost:8025 | Local email inbox |
| MinIO | http://localhost:9001 | S3-compatible object storage console |
| PostgreSQL | localhost:5432 | App data, pgvector, jobs, and cable |

The default `deterministic` provider requires no external network or API key, so the seeded workflow is repeatable.

## AI providers

Provider selection is configuration-only:

```dotenv
# Offline and deterministic
AI_PROVIDER=deterministic

# OpenAI Responses API
AI_PROVIDER=openai
OPENAI_API_KEY=your-key
OPENAI_MODEL=gpt-5.6-sol
OPENAI_EMBEDDING_MODEL=text-embedding-3-small

# Another service implementing compatible Responses and Embeddings endpoints
AI_PROVIDER=compatible
COMPATIBLE_AI_BASE_URL=http://host.docker.internal:11434/v1
COMPATIBLE_AI_API_KEY=
```

Both remote drivers implement the same application interface and strict JSON schema. The app sends `store: false`, records provider/model/token metadata, and rejects any citation identifier that was not retrieved for the investigation. See the official [Responses API reference](https://platform.openai.com/docs/api-reference/responses) and [Structured Outputs guide](https://platform.openai.com/docs/guides/structured-outputs).

## Verification

```bash
docker compose exec web bundle exec rspec
docker compose exec web bundle exec rubocop
docker compose exec web bundle exec brakeman --no-pager
docker compose exec web bundle exec bundler-audit check --update
docker compose exec web ./bin/rails evaluations:run SUITE=fast
docker build --tag learningsignal:local .
```

Run `SUITE=full` before a production release. Evaluation cases and machine-readable rubrics live in `config/evaluations`; Markdown and JSON regression reports are written to `tmp/evaluation-reports`. See [AI and retrieval evaluations](docs/architecture/evaluations.md) for provider comparison, pricing, threshold configuration, and the intentional regression demo.

## Project map

- `app/services/signals` — deterministic signal detection
- `app/services/curriculum` — PDF extraction, page-grounded chunking, and embedding ingestion
- `app/services/student_data_imports` — validated, atomic roster, mastery, assessment, and response imports
- `app/services/retrieval` — tenant-scoped hybrid evidence retrieval
- `app/services/ai` — provider interface, drivers, and output schema
- `app/services/investigations` — orchestration and grounding validation
- `app/services/intervention_outcomes` — audited outcome recording and follow-up mastery synchronization
- `app/services/evaluations` — versioned cases, scoring, persistence, reporting, and blocking quality gates
- `app/services/audit` — tamper-evident event recording
- `config/prompts` — versioned prompt assets
- `docs/architecture` — system design and local workflow
- `docs/decisions` — architecture decision records
- `docs/security` — initial threat model and data-handling boundaries

AWS infrastructure is deliberately deferred until this local foundation is accepted. It will live in the separate `learningsignal-infrastructure` repository.
