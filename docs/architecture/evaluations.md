# AI and retrieval evaluations

LearningSignal treats AI behavior as tested application behavior. The evaluation harness implements LS-604 and Epic 10 without requiring a network call in development or CI.

## What is evaluated

Version-controlled YAML cases live under `config/evaluations/cases` and contain synthetic inputs, tags, suite membership, expected evidence, and machine-readable metric thresholds.

The full suite contains five canonical investigation cases:

- mastery decline with evidence-linked recommendations;
- repeated objective errors;
- contradictory evidence and explicit limitations;
- insufficient evidence and a cautious response;
- prompt injection embedded in retrieved curriculum text.

Three golden retrieval queries measure precision and recall for slope/intercept, two-point slope, and cross-representation reassessment resources.

The deterministic scorer reports structured-output validity, citation validity and completeness, groundedness, unsupported-claim rate, recommendation relevance, inappropriate-inference rate, prompt-injection resistance, refusal correctness, provider errors, retrieval precision, and retrieval recall. These are rule-based regression metrics, not a substitute for educator review or an independent model judge.

## Running suites

```bash
# Pull-request gate: four cases
docker compose exec web ./bin/rails evaluations:run SUITE=fast

# Release gate: all eight cases
docker compose exec web ./bin/rails evaluations:run SUITE=full

# Compare a configured provider and model
docker compose exec web ./bin/rails evaluations:run \
  SUITE=full \
  EVALUATION_PROVIDER=openai \
  EVALUATION_MODEL=gpt-5.6-sol

# Select cases carrying every requested tag
docker compose exec web ./bin/rails evaluations:run \
  SUITE=full \
  TAGS=prompt-injection,safety
```

The provider is selected through the existing provider registry, so `deterministic`, `openai`, and `compatible` use one runner. Set current per-million-token input and output prices in ignored `.env` values before a paid evaluation:

```dotenv
AI_INPUT_COST_PER_MILLION=0
AI_OUTPUT_COST_PER_MILLION=0
```

The defaults are zero because provider prices vary by model and can change. Tokens, latency, request identifiers, raw structured output, and the applied price estimate remain persisted with each run.

## Reproducibility and reports

`evaluation_runs` stores the suite, provider, model, prompt version and SHA-256 digest, case-set digest, Git revision, applied thresholds, aggregate metrics, usage, cost, latency, and gate failures. `evaluation_results` stores the same evidence per case, including ranked retrieval IDs and structured provider output.

Each run writes stable Markdown and JSON reports to `tmp/evaluation-reports`. CI appends the Markdown report to the GitHub Actions job summary. Pull requests run the fast suite; pushes to `main` run the full suite. A failed threshold exits nonzero and blocks the workflow.

Thresholds are configured in `config/evaluations/thresholds.yml` and can be overridden with the documented `EVALUATION_MIN_*` and `EVALUATION_MAX_*` environment variables. The committed defaults require a perfect deterministic baseline so any regression is visible.

## Demonstrating a blocked regression

The evaluation-only `degraded-no-citations` prompt deliberately removes citation requirements. It is isolated from the production investigation prompt catalog. This command must exit nonzero and write a failure report:

```bash
docker compose exec web ./bin/rails evaluations:run \
  SUITE=fast \
  PROMPT_VERSION=degraded-no-citations
```

The retrieval case still passes, while all three investigation cases fail citation validity, citation completeness, groundedness, and the aggregate pass-rate gate. This provides the guide's repeatable demonstration of a prompt regression blocked by CI.

## Adding a case

1. Add a unique, stable case ID and integer version to the appropriate YAML file.
2. Use synthetic inputs only.
3. Assign `fast` only when the case is safe and inexpensive on every pull request; all cases should belong to `full`.
4. Define numeric minimum/maximum rubric checks.
5. Run both suites and inspect the Markdown and JSON reports.
6. Add or update specs when introducing a new metric or case type.
