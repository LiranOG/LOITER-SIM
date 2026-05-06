# Changelog

All notable changes to LOITER-SIM will be documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
LOITER-SIM adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased] — 2026-05

### Added — Initial Public Repository

The repository is published as a docs-first deliverable. No executable simulation code is included in this release.

- `README.md` — Project overview, status, and reading order for new visitors
- `ARCHITECTURE.md` — Full system architecture with subsystem diagrams, ECS layout, performance budget, and data flow
- `ROADMAP.md` — Nine-milestone plan from M1 (Q4 2026) through v1.0 (Q1 2028)
- `CONTRIBUTING.md` — Coding standards, branching strategy, commit standards, physics & numerics standards, testing requirements
- `GOVERNANCE.md` — Project governance model, decision types, role definitions, transparency commitments
- `SECURITY.md` — Vulnerability disclosure policy, response timelines, scope
- `CODE_OF_CONDUCT.md` — Community conduct expectations and enforcement process
- `CONTRIBUTORS.md` — Contributor and reviewer recognition policy
- `CITATION.cff` — Academic citation metadata
- `specs/PHYSICS_SPEC.md` — Authoritative physics specification with full literature citations: 6-DOF dynamics (Stevens, Lewis & Johnson), AMR (Berger & Oliger), atmosphere (ISA), aerodynamics
- `specs/SENSOR_SPEC.md` — Authoritative sensor & EW specification: radar (Richards et al.; Knott et al.), EO/IR (Lloyd), INS (Titterton & Weston), GPS (Kaplan & Hegarty), DRFM (Adamy)
- `docs/WHY.md` — Problem statement, comparative analysis vs. existing simulators, project origins, three-audience use cases
- `docs/FAQ.md` — Direct answers to common questions including a candid "is this vaporware?" response and licensing rationale
- `docs/DESIGN_DECISIONS.md` — Seven major architectural trade-offs with reasoning (DD-01 through DD-07)
- `docs/adr/ADR-001-ecs-architecture.md` — Custom ECS over EnTT/Flecs decision
- `docs/adr/ADR-002-determinism-model.md` — Bitwise determinism as hard requirement
- `docs/adr/ADR-003-rk4-fixed-timestep.md` — Fixed-timestep RK4 over adaptive integrators
- `docs/index.html` — GitHub Pages landing page (dark theme, responsive)
- `scenarios/mass_attack_500.yaml` — Reference scenario: 500 loitering munitions vs. point defense with EW
- `CMakeLists.txt` and `cmake/dependencies.cmake` — Build system with pinned dependencies
- `.clang-format`, `.clang-tidy` — Code style enforcement
- `.gitignore` — C++/Python project exclusions
- `.github/workflows/ci.yml` — Multi-compiler CI pipeline (GCC, Clang) with sanitizers, determinism regression, format/lint, Python bindings
- `.github/workflows/codeql.yml` — Weekly security analysis
- `.github/workflows/release.yml` — Automated release artifacts and Python wheels
- `.github/workflows/labels.yml` — Synchronized issue label taxonomy
- `.github/dependabot.yml` — Automated dependency updates
- `.github/ISSUE_TEMPLATE/{bug_report,feature_request,config}.yml` — Structured issue intake
- `.github/PULL_REQUEST_TEMPLATE.md` — PR review checklist with physics-change requirements
- `.github/labels.yml` — Project label taxonomy

### Notes on this release

This first public release contains **no executable code**. The decision to publish design documents before implementation is methodological — the architecture must be open to expert critique before code that depends on it is written. Implementation of M1 (Foundation) begins in Q4 2026.

Subsequent releases will follow Semantic Versioning. The first release with executable code will be `0.1.0-alpha`, target Q4 2026.

---

## [0.1.0-alpha] — Target: Q4 2026

*To be populated when M1 (Foundation) milestone is reached. Will include the core ECS, 6-DOF dynamics, determinism framework, and CI infrastructure.*

---

## [0.5.0-alpha] — Target: Q3 2027

*Public alpha milestone (M5). Will include the Python RL API, Gymnasium compatibility, and headless batch execution. First version installable via pip.*

---

## [1.0.0] — Target: Q1 2028

*Stable release. All M1–M9 exit criteria met. Q4 2027 is a stretch goal if all preceding milestones complete on time.*

---

<!-- Link definitions -->
[Unreleased]: https://github.com/LiranOG/LOITER-SIM/compare/HEAD
