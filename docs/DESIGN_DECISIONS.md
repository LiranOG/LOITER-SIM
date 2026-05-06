# Design Decisions

This document explains the key design decisions behind LOITER-SIM and the reasoning for each. Every decision here reflects a conscious trade-off — this document exists to make those trade-offs explicit.

For formal Architecture Decision Records (ADRs), see `docs/adr/`.

---

## DD-01: C++17 as the Core Language

**Decision:** The simulation core is written in C++17 with Python bindings via PyBind11.

**Why not Python?**
Python's GIL and interpreter overhead make it unsuitable for tight physics loops. A single 50,000-agent tick at 100 Hz involves ~5 billion floating-point operations. Python, even with NumPy, cannot sustain this without C extensions — which means writing C++ anyway, but with worse tooling.

**Why not Rust?**
Rust is an excellent language with superior memory safety guarantees. However:
- The scientific computing ecosystem (Eigen, HDF5, yaml-cpp, PyBind11) is C++ native. Rust equivalents exist but are less mature.
- The defense/aerospace simulation community uses C++. Interoperability with existing code, datasets, and expertise matters.
- clang-tidy, ASan, and UBSan provide sufficient safety guarantees for a non-networked simulation engine.

This decision will be revisited post-v2.0.

**Why C++17 specifically, not C++20/23?**
C++20 and C++23 compilers are not yet universally available on the Linux distributions used by defense contractors and HPC clusters (RHEL 8, Ubuntu 20.04 LTS). C++17 is the most recent standard with universal compiler support across the target deployment environments.

---

## DD-02: Fixed-Timestep RK4 Integration

**Decision:** All rigid body dynamics are integrated with 4th-order Runge-Kutta at a fixed timestep (default 10 ms / 100 Hz).

**Why RK4, not a simpler method?**
Euler integration (1st order) produces significant energy drift over long engagements. For a 10-minute swarm engagement at 100 Hz, Euler drift can exceed 1 % of total energy — large enough to affect RL training signal. RK4 is 4th-order accurate and has excellent energy conservation properties for autonomous system flight envelopes.

**Why fixed timestep, not adaptive?**
Adaptive timestep methods (e.g., RK45 with error control) are superior for accuracy in a single-trajectory integration. However, they introduce non-determinism: the same trajectory may use different numbers of steps in different runs due to floating-point accumulation differences. Fixed timestep eliminates this source of non-determinism and simplifies parallel execution.

**Why 10 ms (100 Hz)?**
UAV autopilot control loops typically run at 100–400 Hz. A 10 ms simulation timestep matches the lower end of this range, ensuring that control inputs are sampled at physically realistic frequencies. Faster timesteps are available via scenario configuration for high-agility platforms.

Full reasoning: [ADR-003](./adr/ADR-003-rk4-fixed-timestep.md).

---

## DD-03: Lookup-Table Aerodynamics, Not Real-Time CFD

**Decision:** Aerodynamic coefficients are pre-computed as multi-dimensional lookup tables stored in HDF5, not computed by real-time CFD.

**Why not real-time CFD?**
A single CFD solution (RANS / LES) for a drone geometry takes minutes to hours on an HPC cluster. Real-time CFD for 50,000 agents is not computationally feasible on any current or near-future hardware.

**Why not panel methods or vortex lattice (VLM)?**
Panel methods and VLM are faster than CFD but still too slow for real-time many-body simulation. They also fail at high angles of attack (post-stall) and in the transonic regime — conditions that occur regularly in loitering munition engagements.

**Why lookup tables?**
Lookup table interpolation is O(1) per agent per tick. It is the standard approach in all real-time flight simulation (civil and military) for exactly this reason. The tables are generated offline from higher-fidelity models and stored in a compact binary format (HDF5). This approach is used in JSBSim, X-Plane, and all military flight training devices.

**Accuracy trade-off:** Lookup tables do not capture real-time aerodynamic coupling between closely spaced agents (formation flying, slipstream effects). These effects are planned for a post-v1.0 aerodynamic interaction module.

---

## DD-04: Custom ECS Over Third-Party Framework

**Decision:** LOITER-SIM implements its own Entity-Component-System rather than adopting EnTT, Flecs, or another existing ECS library.

**Why not EnTT (the most popular C++ ECS)?**
EnTT is excellent and is the first choice considered. It was rejected for one reason: **deterministic iteration order is not guaranteed across versions**. EnTT's entity recycling and component pool management can produce different iteration orders as implementation details change between releases. For LOITER-SIM's determinism guarantee, the iteration order must be fixed, documented, and under our control.

**Why not Flecs?**
Flecs is powerful and performant. It is also a large dependency with a complex API surface. For a physics-first simulation engine, the ECS should be simple enough to reason about completely.

**The custom ECS is not ambitious.** It is a conservative design: archetype-based storage, SoA layout, fixed iteration order (entity creation order), no dynamic archetypes after world initialization. It does less than EnTT or Flecs. That is the point.

Full reasoning: [ADR-001](./adr/ADR-001-ecs-architecture.md).

---

## DD-05: HDF5 for Persistence

**Decision:** Simulation checkpoints, aerodynamic lookup tables, and replay data are stored in HDF5.

**Why HDF5 over alternatives (SQLite, MessagePack, FlatBuffers, custom binary)?**
- **Scientific ecosystem:** HDF5 is the standard format for large scientific datasets. Every major RL training framework and scientific Python library (NumPy, Pandas, h5py) reads HDF5 natively.
- **Structured hierarchy:** Checkpoint files need a hierarchical structure (world state → entity states → component arrays). HDF5 provides this natively.
- **Compression and chunking:** HDF5's transparent compression and chunking make it efficient for both small (single-entity) and large (50,000-entity) datasets.
- **Partial reads:** HDF5 supports reading a subset of an array without loading the full file — essential for large-scale training data pipelines.

**Trade-off:** HDF5 is a significant dependency with a complex C API. The yaml-cpp-compatible wrapper will hide this complexity from users.

---

## DD-06: GPL v3 with Commercial Licensing Option

**Decision:** The community edition is GPL v3 (not AGPL). Commercial licenses are available separately.

**Why open source at all?**
A simulation engine for defense research is most credible when it is open — when the physics can be inspected, critiqued, and validated by the community. Closed-source simulators in this space exist (AFSIM, OneSAF) but are inaccessible to academic researchers and foreign partners. Openness is a feature, not a concession.

**Why GPL v3 specifically, not MIT, Apache, or AGPL?**

*Vs. permissive (MIT/Apache):* The GPL copyleft provision ensures that organizations that improve the engine must contribute those improvements back to the community. This protects the long-term health of the project: defense contractors cannot fork, improve, and close-source the engine without triggering the copyleft obligation. MIT and Apache would allow this.

*Vs. AGPL:* The AGPL closes the so-called "SaaS loophole" by extending copyleft to network use. For a simulation engine that is run locally for RL training and operator drills (not as a SaaS), this loophole is rarely relevant — but AGPL is widely blacklisted in the defense industry. Most major integrators have blanket policies prohibiting AGPL software, which would significantly reduce the addressable audience for both community adoption and commercial licensing. GPL v3 is the right balance: enough copyleft to deter free-riding, not so much that legitimate users are blocked.

**Why a commercial license option?**
The GPL's copyleft obligation is incompatible with proprietary, classified, or export-controlled deployments. A commercial license exempts the licensee from the copyleft obligation, allowing them to embed LOITER-SIM in classified systems. This is a standard model (MySQL, Qt, MariaDB all use dual GPL/commercial licensing).

---

## DD-07: Headless-First Design

**Decision:** The simulation core has no rendering dependency. Visualization is always optional.

**Rationale:**
- RL training requires 100×–1000× real-time throughput. Rendering (even minimal debug rendering) on every tick is incompatible with this requirement.
- Server deployments (cloud RL training clusters) have no GPU or display. A rendering dependency would make headless deployment impossible.
- Rendering APIs (OpenGL, Vulkan, WebGL) introduce platform-specific non-determinism via driver behavior.

Visualization is provided by a separate optional module (`tools/visualizer/`) that reads from HDF5 replay files and does not affect the simulation core.

---

*This document reflects decisions as of the pre-alpha design phase. Decisions are not permanent — they will be revisited if new evidence or better alternatives emerge. Changes to Type 2 decisions will be documented in `docs/adr/`. Last updated: 2026-05.*
