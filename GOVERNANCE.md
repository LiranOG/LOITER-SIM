# Project Governance

## Overview

LOITER-SIM is currently a **solo-architect project** with a clear path to community governance as it matures. This document defines how decisions are made, how roles are assigned, and how the governance model will evolve as the project grows.

Transparency about governance is especially important for a project operating in the defence and dual-use research space. Every significant decision — technical, licensing, community — will be documented and publicly accessible.

---

## Current Phase: Founding Architect

**Phase applies through: v1.0 release (target Q3 2028)**

During pre-alpha and alpha, decision-making authority rests with the founding architect (**Liran M. Schwartz** — GitHub: [LiranOG](https://github.com/LiranOG)). This is not because community input is unwelcome — it is — but because architectural decisions during the foundation phase have long-lasting consequences that require a single point of accountability.

During this phase:

- The founding architect has final authority on all technical decisions.
- Architecture changes are documented in `docs/adr/` (Architecture Decision Records).
- All significant decisions are made in public, via GitHub Issues or documented ADRs.
- The founding architect commits to responding to community input within 10 business days.

---

## Decision Types

### Type 1 — Reversible (Community Input Welcomed)

Examples: naming conventions, documentation improvements, test case additions, scenario library content, minor API ergonomics.

Process: Open a GitHub Issue or PR. Founding architect reviews and merges or closes with explanation. No formal approval process required.

### Type 2 — Architectural (Expert Review Required)

Examples: changes to the ECS architecture, modifications to the determinism model, new physical subsystems, changes to the Python API contract, changes to the licensing model.

Process:
1. Author opens a GitHub Issue describing the proposed change and its rationale.
2. A minimum 14-day review window opens for community comment.
3. The founding architect publishes an Architecture Decision Record (ADR) in `docs/adr/` documenting the decision and the reasoning, including dissenting views.
4. The ADR is final once published.

### Type 3 — Governance and Licensing (Public Record Required)

Examples: changes to the open-source license, commercial licensing terms, accepting major sponsorship, establishing a foundation.

Process: Full public discussion via GitHub Discussions (when enabled), minimum 30-day comment period, documented decision published to this file.

---

## Architecture Decision Records (ADRs)

Every Type 2 decision generates an ADR in `docs/adr/`. ADRs follow this format:

```
# ADR-NNN: Title

**Date:** YYYY-MM-DD
**Status:** Proposed | Accepted | Deprecated | Superseded by ADR-NNN
**Deciders:** Schwartz, Liran M. [+ reviewers]

## Context
What is the problem and why does it need a decision?

## Decision
What was decided?

## Rationale
Why was this the right choice? What alternatives were considered?

## Consequences
What are the trade-offs and implications?

## Dissenting Views
What concerns were raised that were ultimately not decisive?
```

ADRs are permanent records. They are never deleted, only superseded.

---

## Roles

### Founding Architect

**Current holder:** Liran M. Schwartz (GitHub: LiranOG)

Responsibilities:
- Final decision authority on all Type 1, 2, and 3 decisions during pre-v1.0
- Maintaining the physics specification and architecture documents
- Reviewing and merging PRs
- Responding to community issues
- Managing commercial licensing relationships

### Reviewer

Reviewers are domain experts who have provided substantive, documented review of one or more specification documents. Reviewers are listed in [CONTRIBUTORS.md](./CONTRIBUTORS.md) with the scope of their review.

Reviewers have no formal authority but their expert input is weighted heavily in Type 2 decisions.

To become a Reviewer: open an issue tagged `[review]` with your credentials and the document you wish to review.

### Contributor

Any person who has had at least one pull request merged. Contributors are listed in CONTRIBUTORS.md.

### Community Member

Anyone who participates in GitHub Issues or Discussions. No formal process required.

---

## Post-v1.0 Governance Evolution

After v1.0 is released, governance will evolve based on the size and diversity of the contributor community. Possible directions include:

- **Technical Steering Committee** — a small group of established contributors with collective decision authority on Type 2 decisions
- **Foundation model** — governance transferred to a neutral foundation (similar to the Linux Foundation or Apache Software Foundation model)
- **Maintainer model** — designated maintainers for specific subsystems (physics, Python API, CI, documentation)

The founding architect commits to not making this decision unilaterally — the post-v1.0 governance model will be developed with community input and documented as a Type 3 decision.

---

## Conflict Resolution

Technical disagreements are resolved by the founding architect (pre-v1.0) or the Technical Steering Committee (post-v1.0), with reasoning documented in an ADR.

Community conduct violations are handled according to the [Code of Conduct](./CODE_OF_CONDUCT.md).

Commercial disputes are handled under the terms of the applicable commercial license agreement.

---

## Transparency Commitments

The founding architect commits to:

1. **All significant decisions are made in public.** No backroom deals on architecture, licensing, or community direction.
2. **ADRs are published for all Type 2 decisions** — including decisions that were controversial.
3. **Commercial licensing terms** will be disclosed at a category level (what is licensed, under what general conditions) even if specific contract details remain confidential.
4. **Roadmap changes** will be documented with explanations in this repository.
5. **If the project is discontinued,** the community will be notified with at least 90 days' notice and the codebase will remain publicly accessible indefinitely.

---

*Governance last reviewed: 2026-05. Questions about governance: open a GitHub Issue tagged `[governance]`.*
