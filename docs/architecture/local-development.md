# Local development

## Lifecycle

```bash
docker compose up --build
docker compose exec web ./bin/rails db:seed
docker compose logs -f web worker
docker compose down
```

Compose creates the PostgreSQL databases and MinIO bucket automatically. Named volumes preserve database and object-storage state between restarts.

Curriculum uploads accept text-based PDFs up to 25 MB. The web process stores the source in MinIO and enqueues extraction on the worker. Poppler's `pdftotext` runs inside the application image; scanned image-only PDFs fail visibly until an OCR pipeline is added. Duplicate files are rejected within the same organization using the Active Storage checksum.

Student data imports are available at `/student_data_imports`. Import a roster before mastery history, use synthetic records only, and download the in-app CSV templates for the exact headers. Each file is validated in full and previewed before an atomic confirmation step. CSV files are limited to 5 MB and 2,000 nonblank rows.

To rebuild synthetic data without deleting local records, rerun `db:seed`; the seed script is idempotent. To intentionally reset the local databases, use the Rails database tasks rather than deleting Docker volumes unless the data loss is desired.

## Provider development

Keep `AI_PROVIDER=deterministic` for normal development and CI. This provider produces repeatable embeddings and grounded output without sending student data off-machine.

To exercise OpenAI, place the key only in ignored `.env`, set `AI_PROVIDER=openai`, and restart `web` and `worker`. Never add a key to `.env.example`, source control, test fixtures, logs, or screenshots.

The `compatible` provider is intended for a local or alternate service exposing OpenAI-compatible `/responses` and `/embeddings` endpoints. Contract specs ensure both HTTP drivers construct the same strict request shape.
