# ADR 002: Use PostgreSQL for records, vectors, jobs, and live updates

- Status: accepted
- Date: 2026-07-22

## Context

The local milestone needs relational records, tenant-scoped semantic retrieval, durable jobs, and investigation progress updates. Operating Redis and a separate vector database would add moving parts before workload characteristics are known.

## Decision

Use PostgreSQL 17 with pgvector, Solid Queue, and Solid Cable. Use separate development databases for primary records, jobs, and cable state.

## Consequences

The stack has fewer services and consistent backup semantics. Retrieval and queue load must be measured before AWS sizing; later extraction remains possible if database contention or scale requires it.
