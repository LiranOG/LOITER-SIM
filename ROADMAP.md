# LOITER-SIM Roadmap

> **Target Release: v1.0 — Q3 2028** (with Q2 2028 as a stretch goal)

This document is the authoritative public roadmap for LOITER-SIM. It reflects current planning and will be updated as the project progresses. All dates are *targets*, not commitments — slips will be communicated openly via this document.

---

## Milestone Overview

```
2027 Q2  ──┬── M1: Foundation
           │   Core ECS, 6-DOF dynamics, determinism framework, CI pipeline
           │
2027 Q2  ──┼── M2: Terrain & Physics
           │   AMR solver, aerodynamics, ISA atmosphere
           │
2027 Q3  ──┼── M3: Swarm Scale
           │   50,000-agent benchmark, SIMD optimization
           │
2027 Q3  ──┼── M4: Sensors & EW
           │   Radar, EO/IR, INS/GPS, jamming/spoofing
           │
2027 Q4  ──┼── M5: RL Interface (Public Alpha)
           │   Python bindings, Gymnasium API, batch execution
           │
2027 Q4  ──┼── M6: Scenario Engine
           │   YAML scenarios, HDF5 persistence, replay
           │
2027 Q1  ──┼── M7: Communications & C2
           │   Mesh networking, DIS/HLA interoperability
           │
2027 Q2  ──┼── M8: Human-in-the-Loop
           │   VR/FPV interface, behavior trees, operator tooling
           │
2028 Q2  ──┼── M9: Hardening & Certification
           │   Full test coverage, performance validation, docs
           │
2028 Q3  ──┴── v1.0 STABLE RELEASE
                (Q4 2027 — stretch goal if M1–M8 finish ahead of plan)
```

> **Honest assessment:** This timeline reflects realistic effort estimates for a solo project of this scope. Roughly 14 months of engineering work after M1 begins. Earlier estimates (Q4 2027) are kept as a stretch target if architectural decisions hold up perfectly and no major scope changes occur. If reality forces compromise, scope will be cut before quality. v1.1 / v1.2 can extend functionality post-release.

---

## Milestone Details

### M1 — Foundation (Q2 2027)

**Goal:** A single simulated agent that flies deterministically.

- [ ] CMake build system with all dependencies pinned
- [ ] ECS world with archetype storage and SoA component pools
- [ ] 6-DOF rigid body state vector and RK4 integrator
- [ ] Quaternion rotation math (unit-tested)
- [ ] Determinism framework: xoshiro256** PRNG, FP-mode enforcement, tick checksums
- [ ] CI pipeline: build, unit tests, sanitizers, determinism regression
- [ ] GoogleTest infrastructure
- [ ] Basic HDF5 state serialization
- [ ] `loiter_sim_core` static library target

**Exit criteria:** Single agent in free flight, 10,000 ticks, energy-conservation test passes (< 1e-6 relative drift), determinism regression passes.

---

### M2 — Terrain & Physics (Q2 2027)

**Goal:** Aerodynamically correct flight over simulated terrain.

- [ ] Berger-Oliger AMR grid with 4-level hierarchy
- [ ] AMR refinement / coarsening criterion and patch management
- [ ] ISA atmosphere model (temperature, pressure, density vs. altitude)
- [ ] Aerodynamic lookup table infrastructure (multi-dim HDF5)
- [ ] Lift/drag computation from AoA, Mach, control surface tables
- [ ] Basic propulsion model (fixed-thrust and throttle-controlled)
- [ ] Terrain geometry from elevation model (DTED or synthetic)
- [ ] Terrain collision detection

**Exit criteria:** Loitering munition on realistic flight profile; energy conservation maintained over 60 s mission; AMR refinement triggers correctly on agent density gradients.

---

### M3 — Swarm Scale (Q3 2027)

**Goal:** 50,000 simultaneous agents at real-time.

- [ ] SIMD vectorization of RK4 physics hot loop (AVX2)
- [ ] Multi-threaded ECS with deterministic parallel partitioning
- [ ] Basic Boids swarm behavior (separation, alignment, cohesion)
- [ ] Performance benchmark suite (Google Benchmark)
- [ ] Memory profiling and optimization to < 2 KB/agent
- [ ] Headless execution mode (no rendering dependency)
- [ ] Agent lifecycle management (spawn, death, recycle)

**Exit criteria:** 50,000 agents, Boids formation, sustained 50 Hz tick on consumer-grade 16-core CPU, < 20 ms per tick.

---

### M4 — Sensors & Electronic Warfare (Q3 2027)

- [ ] Radar detection: RCS lookup tables, range equation, SNR threshold
- [ ] EO/IR: FoV raycasting, IR signature model, background clutter
- [ ] INS/GPS: drift model, fix quality, HDOP
- [ ] GPS jamming: noise floor elevation within band and geometry
- [ ] GPS spoofing: injected false position
- [ ] Radar DRFM jammer: stretch-pulse spoofing
- [ ] Multi-spectral detection fusion
- [ ] Sensor data available as ECS components for agent systems

**Exit criteria:** Counter-UAS scenario: ground radar detects swarm, EW system degrades GPS fix for subset of agents, all detection events match analytic predictions within tolerance.

---

### M5 — RL Interface / Public Alpha (Q4 2027)

**This is the first public alpha release — first version available for external testing and open issue tracking on running code.**

- [ ] PyBind11 bindings: `World`, `BatchWorld`
- [ ] Gymnasium-compatible `step()` / `reset()` / `observation_space` / `action_space`
- [ ] Observation vector: ego state + N nearest contacts + comm status
- [ ] Action vector: thrust, control surfaces, warhead, comm
- [ ] YAML-defined reward function (composable terminal + shaping)
- [ ] Headless batch: 64 parallel worlds
- [ ] Python package installable via pip (wheel)
- [ ] Example RL training script (PPO via Stable-Baselines3)
- [ ] Public alpha documentation

**Exit criteria:** PPO agent trained to intercept single target in 1 M steps. Training throughput ≥ 1000× real-time on 8-core CPU. Wheels published to PyPI.

---

### M6 — Scenario Engine (Q4 2027)

- [ ] Full YAML scenario schema with JSON Schema validation
- [ ] Entity templates (threat library: DJI-class, Lancet-class, Shahed-class archetypes)
- [ ] Weather and environmental conditions (wind, turbulence, visibility)
- [ ] Mission objective system (waypoint, target, loiter, strike)
- [ ] HDF5 checkpoint: full world state at configurable intervals
- [ ] Replay system: (action, seed) → deterministic reproduction
- [ ] CSV telemetry export
- [ ] Scenario library: 10 reference scenarios

---

### M7 — Communications & C2 / Interoperability (Q1 2028)

- [ ] Mesh networking: link quality, packet loss, latency, bandwidth
- [ ] C2 link model with configurable jamming susceptibility
- [ ] DIS (IEEE 1278.1) entity state PDU export
- [ ] HLA (IEEE 1516) federation interface
- [ ] Multi-player tactical trainer integration example

---

### M8 — Human-in-the-Loop (Q2 2028)

- [ ] VR/FPV operator interface (headset + controller input)
- [ ] Behavior tree engine for supervised autonomy
- [ ] Point-and-fly command interface
- [ ] Mixed initiative: RL policy + human override
- [ ] Operator performance metrics and playback

---

### M9 — Hardening & Certification (Q2 2028)

- [ ] ≥ 90 % unit test line coverage
- [ ] Full API documentation (Doxygen)
- [ ] Performance validation report against M3 targets
- [ ] Formal physics validation: comparison against published simulation benchmarks
- [ ] Commercial license infrastructure
- [ ] CHANGELOG complete and accurate
- [ ] All `TODO` and `FIXME` resolved or tracked in issues

---

### v1.0 Stable Release (Q3 2028)

- [ ] All M1–M9 exit criteria met
- [ ] Community Edition (GPL v3) tagged and released
- [ ] Commercial license agreement published
- [ ] Academic paper submission (venue TBD)

---

## Post-v1.0 Backlog

These items are explicitly deferred to post-v1.0:

- GPU acceleration (CUDA / HIP) for > 500,000-agent scale
- Terminal ballistics (SPH / FEM warhead modeling)
- Orbital / exo-atmospheric intercept scenarios
- Classified threat-model library (commercial license only)
- Hardware-in-the-loop (HiL) interface for embedded autopilots
- Formal verification of determinism properties
- Maritime and littoral scenarios (USVs, naval point defense)

---

## How to Influence the Roadmap

- **Feature requests:** Open a GitHub Issue using the Feature Request template. Issues with well-documented use cases and multiple upvotes are more likely to influence milestone planning.
- **Commercial priorities:** Contact the maintainer. Commercial licensees may sponsor milestone acceleration.
- **Academic collaboration:** If you are a researcher with relevant expertise, reach out. Joint research arrangements are open for discussion.

---

*Roadmap last updated: 2026-05. Material changes will be communicated via GitHub releases and visible diffs on this document.*
