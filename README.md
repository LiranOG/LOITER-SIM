<div align="center">

# LOITER-SIM
### The Deterministic Drone Swarm Engine for Mission-Critical AI Training

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-green.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![Status](https://img.shields.io/badge/status-pre--alpha-2d3936)]()
[![Phase](https://img.shields.io/badge/phase-design-lightgreen)]()

[![C++17](https://img.shields.io/badge/C++-17-007acc)]()
[![Python](https://img.shields.io/badge/Python-3.10%2B-007acc)]()

[![Target](https://img.shields.io/badge/v1.0--target-Q1%202028-orange)]()

***Train your autonomous systems against 10,000 threats before the first one ever leaves the ground.***

</div>

LOITER-SIM is a standalone, high-performance C++17 simulation engine for loitering munitions, suicide drones, and autonomous UAV swarms. It is designed for training reinforcement learning agents at scale, exercising human operators in mass-attack scenarios, and evaluating counter-UAS tactics in congested, electronically contested environments.

The engine delivers three guarantees that no existing open-source simulator provides simultaneously: **bitwise-deterministic execution**, **physics-grade adaptive mesh refinement**, and a **production-ready RL API capable of 1000× real-time batch inference**. No game-engine black boxes. No floating-point non-determinism. Just repeatable, rigorous numerics.

---

## 🚦 Status — Pre-Alpha · Design Phase · v1.0 Target: Q1 2028

> **No executable simulation code is published yet.** This repository currently contains the architecture specification, physics specification, design rationale, and engineering roadmap. Implementation of the core engine begins in Q4 2026.

LOITER-SIM is the formal product of an extended period of design thinking around high-performance simulation engineering. The architectural patterns and physics models documented here draw on the author's prior work in numerical simulation; the decision to crystallize that thinking into a dedicated open-source project — and to publish the design before writing the code — was made in early 2026.

This is intentional. A simulator built on a flawed architecture is worse than no simulator: it produces incorrect results that mislead the researchers and operators who rely on it. The architecture must be public, reviewable, and open to expert critique **before** implementation begins. The specifications you see in this repository are the first deliverable.

The first executable milestone — a single agent in deterministic free flight, with a complete CI pipeline and test infrastructure — targets **Q4 2026**. The first externally-usable public alpha (with the Python RL API) targets **Q3 2027**. The stable v1.0 release targets **Q1 2028** (with Q4 2027 as a stretch goal). See [ROADMAP.md](./ROADMAP.md) for the full milestone breakdown.

---

## ❓ "Why So Much Documentation and No Code Yet?"

Three honest reasons:

1. **Architecture decisions made in the absence of public review tend to be wrong.** Domain experts in aerodynamics, radar physics, and military simulation standards must have the opportunity to critique the design *before* it is locked in by code that depends on it.
2. **The specifications represent a methodological choice, not elapsed time.** This is a docs-first project by design. The author has chosen to publish the architecture before the implementation precisely because the credibility of a simulator depends on the verifiability of its physics — and that verifiability begins with publishing the equations and citations openly.
3. **The author is a solo architect, not a funded team.** Open-source defense-adjacent simulation work at this scope from a single contributor will move deliberately. The Q1 2028 v1.0 target reflects realistic effort estimates for the work involved. Implementation begins immediately, with public commits visible from day one of M1.

If, by Q1 2027, this repository still has no committed code, the project is fairly classified as vaporware and reasonable observers should treat it as such. Until then, judge the project by the rigor and correctness of the documents you can read today.

---

## ✈️ Core Capabilities (v1.0 Roadmap)

| Capability | Status | Target | Description |
|------------|--------|--------|-------------|
| **6-DOF rigid body dynamics** | 📐 Spec complete | Q4 2026 | Quaternion-based flight model, Euler-Newton integration (RK4), AoA-dependent aerodynamics, configurable propulsion |
| **Bitwise-deterministic execution** | 📐 Spec complete | Q4 2026 | Identical seed → identical floating-point result, every run, on any IEEE 754-compliant platform |4
| **Adaptive Mesh Refinement** | 📐 Spec complete | Q1 2027 | Custom Berger-Oliger AMR engine — high resolution only where it matters |
| **Multi-agent swarm scaling** | 📅 Planned | Q2 2027 | ECS architecture targeting 50,000+ simultaneous agents on consumer hardware |
| **Physics-based sensor simulation** | 📅 Planned | Q2 2027 | Radar (RCS-based), EO/IR (FoV raycasting), INS/GPS with configurable jamming and spoofing |
| **YAML scenario definition** | 📅 Planned | Q3 2027 | Complex missions described entirely in YAML — no recompilation |
| **Python RL API (Gymnasium)** | 📅 Planned | Q3 2027 | `step()` interface for PyTorch/TensorFlow; headless batch execution up to 1000× real-time |
| **Dynamic mesh networking** | 📅 Planned | Q4 2027 | Realistic packet loss, latency, and range constraints for inter-drone and C2 links |
| **DIS / HLA interoperability** | 📅 Planned | Q4 2027 | Connect to existing C4I systems and multi-player tactical trainers |
| **Human-in-the-loop VR/FPV** | 📅 Planned | Q4 2027 | Point-and-fly interface with behavior trees for supervised autonomy |
| **v1.0 Stable Release** | 🎯 Target | **Q1 2028** | Full engine, commercial licensing infrastructure, complete documentation |

---

## 🏗️ Architecture

LOITER-SIM is a **physically-decoupled engine**. The C++ HPC core is independent of the Python layer. The Python layer is independent of the rendering layer. Each layer can be replaced or removed without affecting the others.

```
loiter-sim/
├── core/           # 6-DOF, integrators, AMR, sensors, mesh networks
├── bindings/       # PyBind11 → Gymnasium-compatible Python API
├── scenarios/      # YAML mission definitions
├── tools/          # Logging, replay, HDF5 analysis
├── specs/          # Authoritative physics & sensor specifications
├── docs/           # Whitepapers, FAQ, design decisions, ADRs
└── tests/          # Unit, integration, and determinism regression tests
```

The core is built around a bespoke AMR solver that dynamically adapts the simulation grid in three dimensions, concentrating computational resolution where it matters most — near vehicles, sensors, and terrain features. All integration uses fixed-timestep RK4, tuned for energy conservation over long-duration swarm engagements.

For complete architectural detail, read [ARCHITECTURE.md](./ARCHITECTURE.md).

---

## 🌐 Project Website

The full project landing page — including the milestone timeline, 
audience overview, and licensing details — is available at:

**[liranog.github.io/LOITER-SIM](https://liranog.github.io/LOITER-SIM)**

---

## 📚 Reading Order for New Visitors

If you have ten minutes, read in this order:

1. **[docs/WHY.md](./docs/WHY.md)** — The problem LOITER-SIM exists to solve, and why existing solutions are inadequate.
2. **[docs/FAQ.md](./docs/FAQ.md)** — Direct answers to the obvious questions, including "is this vaporware?"
3. **[ROADMAP.md](./ROADMAP.md)** — The nine-milestone plan from now through v1.0 in Q1 2028.

If you have an hour and a technical background:

4. **[ARCHITECTURE.md](./ARCHITECTURE.md)** — The full system architecture.
5. **[specs/PHYSICS_SPEC.md](./specs/PHYSICS_SPEC.md)** — All physical models with citations.
6. **[specs/SENSOR_SPEC.md](./specs/SENSOR_SPEC.md)** — Sensor and electronic warfare models.
7. **[docs/DESIGN_DECISIONS.md](./docs/DESIGN_DECISIONS.md)** — The trade-offs that shaped the project.

---

## 🤝 Contributing

LOITER-SIM welcomes contributions, particularly from domain experts. At the current pre-alpha stage, **the most valuable contribution is rigorous critique of the specifications** — open a GitHub Issue tagged `[review]` if you have expertise in aerodynamics, radar, electronic warfare, INS/GPS, multi-agent RL, or military simulation standards.

When core development begins (Q4 2026), code contributions will be accepted under the process documented in [CONTRIBUTING.md](./CONTRIBUTING.md). All contributions must follow the [Code of Conduct](./CODE_OF_CONDUCT.md).

---

## 🔒 Security

For responsible disclosure of vulnerabilities, see [SECURITY.md](./SECURITY.md). **Do not open public issues for security reports.**

---

## 📄 License

Licensed under the GNU General Public License v3.0. See [LICENSE](./LICENSE) for the full text.

---

## 👤 Author

**Liran M. Schwartz** ([LiranOG](https://github.com/LiranOG)) — Founder & Lead Architect. Independent researcher in high-performance simulation, deterministic numerics, and autonomous systems engineering.
