# ADR 003: Isolate AI providers and require educator approval

- Status: accepted
- Date: 2026-07-22

## Context

LearningSignal needs OpenAI first but must avoid coupling the product workflow to a single provider. Its output affects educator decisions, so provenance, grounding, and human control are product requirements.

## Decision

Define a provider interface for generation and embeddings. Ship deterministic, OpenAI Responses API, and compatible Responses API implementations. Require strict structured output, reject unknown evidence citations, preserve the original draft, and require an authenticated educator to approve or reject every plan.

## Consequences

Providers can be changed through environment configuration and contract tests. A new driver must satisfy the interface and grounding behavior. The AI can draft evidence-backed recommendations but cannot autonomously execute educational actions.
