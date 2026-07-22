# ADR 001: Begin with a modular Rails monolith

- Status: accepted
- Date: 2026-07-22

## Context

The first milestone must validate the educator workflow locally before AWS infrastructure is designed. Splitting the workflow into networked services now would increase deployment, authentication, observability, and data-consistency work without evidence that independent scaling is necessary.

## Decision

Build a Rails modular monolith with explicit service namespaces and a separate worker process from the same image. Keep domain boundaries visible in code so a high-load component can be extracted later from observed constraints.

## Consequences

Local setup remains one Compose command, domain transactions stay reliable, and background work can scale independently at the process level. Code review must preserve module boundaries so the monolith does not become unstructured.
