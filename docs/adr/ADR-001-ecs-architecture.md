# ADR-001: Custom ECS Over Third-Party Library

**Date:** 2026-05
**Status:** Accepted
**Deciders:** Schwartz, Liran M.

---

## Context

LOITER-SIM requires an Entity-Component-System (ECS) to manage 50,000+ simultaneous agents with cache-friendly data layouts and deterministic execution. Several mature C++ ECS libraries exist. This ADR documents the decision to implement a custom ECS rather than adopt one.

**Libraries evaluated:**
- **EnTT** (skypjack/entt) — the most widely used C++ ECS; used in Minecraft: Bedrock, OpenMW, many game engines
- **Flecs** (SanderMertens/flecs) — feature-rich, excellent performance, active development
- **Entityx** — simpler, older; less maintained
- **Custom implementation** — purpose-built for LOITER-SIM's specific constraints

---

## Decision

Implement a custom ECS purpose-built for LOITER-SIM.

---

## Rationale

### Against EnTT

EnTT's entity recycling mechanism recycles entity IDs in a non-deterministic order relative to simulation state. When entities die and new entities are spawned (e.g., drone destroyed, replacement launched), the recycled IDs are assigned in an order that depends on the internal freelist state, which can diverge between runs even with identical seeds if entity death events occur in floating-point-dependent order.

Additionally, EnTT does not guarantee iteration order across library versions. LOITER-SIM's determinism guarantee requires that the same physics result is produced across different build environments. Pinning EnTT to a specific version is necessary but insufficient — the internal ordering guarantee is not part of EnTT's public API contract.

### Against Flecs

Flecs is excellent but introduces a large API surface and a complex internal model (queries, systems, pipelines, observers, prefabs). LOITER-SIM's ECS needs are narrow and well-defined. The added complexity of Flecs would make the codebase harder to reason about and audit for determinism.

Flecs also uses a more aggressive internal optimization model that makes deterministic iteration order harder to guarantee without deep understanding of its internals.

### For Custom ECS

The custom ECS can be designed with LOITER-SIM's constraints as first-class requirements:
- Entities iterate in **creation order**, always, guaranteed
- Entity ID assignment is deterministic (monotonically incrementing, no recycling until world reset)
- Component pools use **fixed-size pre-allocated arrays** — no dynamic allocation after world initialization
- The entire ECS implementation fits in under 500 lines — fully auditable

The custom ECS does less than EnTT or Flecs. It has no query optimization, no dynamic archetype transitions, no observers. These are features LOITER-SIM does not need, and their absence makes the determinism guarantee tractable to verify.

---

## Consequences

**Positive:**
- Deterministic iteration order is guaranteed by design, not by implementation assumption
- Full control over memory layout and allocation patterns
- Small, auditable codebase

**Negative:**
- Development time to implement and test the ECS (estimated: 2–3 weeks)
- No ecosystem of existing integrations (debugging tools, profilers that understand the ECS structure)
- More maintenance burden than using a library

**Risk mitigation:** The custom ECS is small enough that the maintenance burden is modest. The correctness and determinism properties are verified by a dedicated test suite (see `tests/ecs/`).

---

## Dissenting Views

*None recorded at time of decision.*

---

## Alternatives Reconsidered

If EnTT adds a formal deterministic iteration mode with stable guarantees in its public API, this decision should be revisited. Using EnTT would reduce maintenance burden and improve ecosystem compatibility. The trigger for revisiting is an EnTT release that documents guaranteed-deterministic entity ordering as a stable API contract.
