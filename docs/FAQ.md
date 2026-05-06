# Frequently Asked Questions

---

## General

### What is LOITER-SIM?

LOITER-SIM is an open-source C++17 simulation engine for loitering munitions and autonomous drone swarms. It is designed for three primary use cases: training reinforcement learning agents at scale, exercising human operators in simulated mass-attack engagements, and evaluating counter-UAS tactics and electronic warfare effects.

It is not a game, not a weapon system, and not a commercial product (yet). It is a physics simulation engine — a rigorous mathematical model of flight dynamics, sensor physics, and communications — released under the GNU GPL v3.

### Why does this exist?

The short answer: because no adequate open-source alternative exists.

The defense and academic research communities urgently need a deterministic, high-fidelity, high-throughput simulation environment for autonomous drone systems. Existing open-source simulators are either not deterministic (making them unsuitable for reproducible RL research), not fast enough (making them unsuitable for RL training at scale), or not domain-specific (making them inadequate for loitering munition and swarm physics).

For the full argument, read [docs/WHY.md](./WHY.md).

### Is this a weapon?

No. LOITER-SIM is a simulation engine — software that runs on a computer and models physics mathematically. It controls no physical hardware, generates no real targeting data, and falls in the same category as flight simulators used by pilots or driving simulators used by automotive engineers.

The analogy is exact: a flight simulator is not an aircraft. LOITER-SIM is not a drone.

### Who is building this?

LOITER-SIM is currently built by a single architect (**Liran M. Schwartz**, GitHub: [LiranOG](https://github.com/LiranOG)) — an independent researcher with a background in high-performance simulation, deterministic numerics, and computational physics. The project is structured to grow into a community project as the core engine matures.

### Is this related to any existing project?

LOITER-SIM is an independent project. It is not a fork or derivative of any existing simulator. It draws on the published scientific literature for its physical models and on established open-source libraries (Eigen, yaml-cpp, HDF5, GoogleTest) for infrastructure.

The architectural patterns it employs — deterministic execution, adaptive mesh refinement, ECS-based agent management — reflect the author's prior experience in high-performance simulation engineering.

---

## Status & Timeline

### Is there code I can run?

**Not yet.** The repository currently contains the architecture specification, physics specification, sensor specification, design rationale, ADRs, and roadmap. No executable simulation code has been published.

This is a deliberate choice, not a delay. The design must be correct before the implementation begins. A simulator built on a flawed architecture is worse than no simulator — it produces incorrect results that mislead the researchers and operators who depend on it.

### When will there be something to run?

The first executable milestone (M1 — Foundation) targets **Q4 2026**: a single simulated agent in deterministic free flight, with a CI pipeline and full test infrastructure committed and visible.

The first externally-usable public alpha (M5 — RL Interface) targets **Q3 2027**.

The v1.0 stable release targets **Q1 2028**, with Q4 2027 as a stretch goal.

See [ROADMAP.md](../ROADMAP.md) for the full milestone breakdown with technical exit criteria for each.

### Why publish the repository before the code exists?

Several reasons:

1. **Expert review.** The physics specification and architecture are the most consequential decisions in the project. Publishing them early allows domain experts to identify errors before they are baked into code that depends on them.

2. **Collaboration discovery.** Researchers and organizations interested in contributing or collaborating need to find the project. A GitHub presence is the standard discovery mechanism in the open-source world.

3. **Credibility through transparency.** Publishing a detailed, honest roadmap with explicit "no code yet" status is more credible, not less, than appearing suddenly with a finished product. Open architecture is a feature, not a concession.

4. **Commercial-licensing conversations.** Defence integrators with timeline-sensitive needs may wish to begin discussions before v1.0. That conversation requires a public presence.

### Is this vaporware?

This is a fair question and deserves a direct answer.

Vaporware is software announced with no serious intent or capability to deliver. By that definition, the answer is no — but the better way to evaluate the project is by the substance of what is currently published, not by claims about what is coming.

What you can verify *today*:

- The physics specification (`specs/PHYSICS_SPEC.md`) cites primary literature for every numerical method and physical model. The equations are reproducible. The references are checkable.
- The architecture specification (`ARCHITECTURE.md`) describes a self-consistent system with explicit data flows, performance targets, and trade-offs.
- The architecture decision records (`docs/adr/`) document the reasoning for the most consequential choices, including alternatives considered and rejected.
- The design rationale (`docs/DESIGN_DECISIONS.md`) explains why the project exists in the form it does.

What remains a claim until proven:

- All performance targets (50,000 agents at real-time, 1000× headless throughput).
- All milestone dates.
- The eventual quality of the implementation.

A reasonable observer should treat the documents as evidence and treat the targets as targets. If, by Q1 2027, this repository still has no committed code, treat the project as vaporware at that point. Until then, judge it by what is currently visible: the rigor, internal consistency, and citation quality of the published specifications.

### How do I know the timelines are realistic?

You don't, with certainty — and you shouldn't accept any solo developer's claims about future timelines on faith. What you can evaluate is whether the milestones have *technical exit criteria* (they do), whether the dependencies between milestones are *coherent* (they are), and whether the timeline is *conservative or aggressive* relative to the scope.

The honest assessment: **the v1.0 target of Q1 2028 reflects realistic effort estimates for a solo project of this scope.** Roughly 14 months of engineering work after M1 begins. It is not impossible — comparable open-source simulation projects have been built by individuals or very small teams within similar windows — but it requires that the architectural decisions are correct on the first attempt and that no major scope changes occur. If the project slips, the slip will be communicated openly via this repository.

---

## Technical

### Why C++17?

Physics simulation at the required throughput — 50,000+ agents at real-time — requires deterministic control over memory layout, SIMD vectorization, and floating-point behavior. C++17 is the only language that provides all of these while remaining cross-platform and having mature tooling (CMake, clang-format, clang-tidy, sanitizers, mature scientific libraries).

Python is used for the RL interface (via PyBind11) and tooling, but the simulation core must be C++.

### Why C++17 specifically, not C++20 or C++23?

C++20 and C++23 compilers are not yet universally available on the Linux distributions used by defense contractors and HPC clusters (RHEL 8, Ubuntu 20.04 LTS). C++17 is the most recent C++ standard with universal compiler support across the target deployment environments. This will be revisited for v2.0.

### What does "bitwise-deterministic" mean?

It means that running the simulation twice with the same scenario and random seed produces outputs that are **bit-for-bit identical** — not "approximately the same" or "statistically indistinguishable," but literally identical at the bit level.

This is essential for reinforcement learning: if the environment is non-deterministic, the agent's gradient estimates are noisy in a way that cannot be distinguished from signal. It is also essential for debugging: non-deterministic bugs are the hardest class of bug to find and fix. And it is essential for any path toward formal certification of the simulator's outputs.

Achieving bitwise determinism requires careful control over floating-point rounding mode, PRNG state management, and parallel-reduction ordering. See [ARCHITECTURE.md §11](../ARCHITECTURE.md#11-determinism-guarantee) and [ADR-002](./adr/ADR-002-determinism-model.md).

### Why not build on top of AirSim or Gazebo?

Both are excellent projects, but neither satisfies LOITER-SIM's core requirements:

- **AirSim/Colosseum** is built on Unreal Engine, which introduces rendering-related non-determinism that cannot be cleanly removed. It is also GPU-bound, making headless high-throughput batch execution impractical.
- **Gazebo** runs close to real-time speed and is not designed for the 50,000+ agent scales LOITER-SIM targets.

LOITER-SIM is a thinner, faster, more specialized tool. It does less than these general-purpose simulators — no photorealistic rendering, no ROS integration by default — but what it does, it does with guarantees those simulators cannot provide.

### What aerodynamic model does it use?

LOITER-SIM uses **lookup-table-based aerodynamics** rather than real-time computational fluid dynamics. Aerodynamic coefficients (lift, drag, side force, and moment coefficients) are pre-computed as a function of angle of attack, Mach number, and control surface deflection, stored in HDF5 tables, and interpolated at runtime.

This is the standard approach for real-time flight simulation in both civil and military domains. Full CFD (Navier-Stokes) takes hours per frame and cannot run at 100× real-time on any current hardware.

### Can it simulate GPS jamming and spoofing?

Yes — this is a first-class feature. The sensor subsystem models GPS jamming (elevated noise floor within a frequency band and geometry), GPS spoofing (false position injection), and radar electronic countermeasures (DRFM stretch-pulse jamming). See [ARCHITECTURE.md §7.4](../ARCHITECTURE.md#74-electronic-warfare) and [specs/SENSOR_SPEC.md](../specs/SENSOR_SPEC.md).

### What is the planned maximum number of simultaneous agents?

The v1.0 performance targets are:

| Mode | Target agent count |
|------|--------------------|
| Real-time (50 Hz tick) | 50,000 |
| 10× real-time | 5,000 |
| 1000× real-time (headless RL batch) | 500 |

These targets will be validated by the M3 benchmark suite (Q2 2027). They are based on memory-budget analysis (~464 bytes per agent → ~22 MB for 50k agents, well within L3 cache on modern CPUs) and SIMD-vectorization estimates of the physics hot loop. See [ARCHITECTURE.md §12](../ARCHITECTURE.md#12-performance-architecture).

### Does it support GPU acceleration?

Not in v1.0. The CPU implementation must be correct and thoroughly validated before GPU acceleration is added. GPU parallelism introduces additional complexity for determinism guarantees and is more architecturally invasive than initially apparent.

GPU acceleration (CUDA / HIP) is on the post-v1.0 backlog. See [ROADMAP.md](../ROADMAP.md#post-v10-backlog).

### Can I use it with PyTorch / TensorFlow?

Yes — this is a primary design goal. The Python API will expose a [Gymnasium](https://gymnasium.farama.org/)-compatible interface, which is the standard RL environment interface used by both PyTorch-based libraries (Stable-Baselines3, CleanRL, TorchRL) and TensorFlow-based libraries (TF-Agents).

---

## Licensing & Commercial Use

### Why GPL v3 and not AGPL v3?

This was a deliberate choice. The Affero variant of the GPL closes the so-called "SaaS loophole" by extending copyleft obligations to network use — anyone running modified AGPL software as a network service must publish their modifications.

For LOITER-SIM, this trade-off does not pay off:

1. **The threat model doesn't fit.** LOITER-SIM is a simulation engine run locally for RL training, operator drills, or scenario analysis. It is not the kind of software typically deployed as a SaaS — the loophole AGPL closes is rarely relevant here.

2. **AGPL is widely blacklisted in the defense industry.** Most major defense integrators have blanket policies prohibiting AGPL software in their codebases. Releasing under AGPL would significantly reduce the addressable audience for both community adoption and commercial licensing conversations.

3. **GPL v3 is already sufficient deterrent for the dual-licensing model.** The standard GPL copyleft is enough to push proprietary integrators toward the commercial license. The additional friction of AGPL would mostly hurt legitimate research users (university clusters, shared compute environments).

4. **GPL v3 is the industry-standard idiom.** Linux, GCC, GIMP, and many other foundational projects use GPL v3 (or v2). Defense-industry legal teams understand it without negotiation.

The dual GPL + commercial licensing model used by MySQL, Qt, and MariaDB is a strong fit for LOITER-SIM. AGPL would break that model.

### Can I use LOITER-SIM in my research?

Yes. The Community Edition is released under the GNU GPL v3.0, which permits free use, modification, and distribution for any purpose — including academic research — provided that derivative works are also released under the GPL.

Please cite the project if you publish research that uses it. A `CITATION.cff` is included in the repository for this purpose.

### Can my company use it in a closed-source product?

The GPL v3.0 requires that any software that incorporates GPL-licensed code also be released under the GPL. This is by design — it ensures that public improvements flow back to the community.

If your organization needs to embed LOITER-SIM in a proprietary, classified, or closed-source product, **a commercial license is available**. Contact the maintainer via GitHub Issues (tag `commercial-licensing`) to discuss terms.

Commercial licensing covers unlimited agents, advanced threat models, GPU acceleration modules, DIS/HLA integration, and priority support.

### What if I want to contribute classified threat models?

Classified data cannot be contributed to the public repository under any circumstances. The commercial-licensing framework provides a separate mechanism for organizations to commission private modules (classified threat-model libraries, country-specific platform signatures, classified terrain data) that sit alongside the open-source core without being subject to the GPL.

Contact the maintainer to discuss arrangements.

---

## Contributing

### How do I contribute?

Read [CONTRIBUTING.md](../CONTRIBUTING.md). At the current pre-alpha stage, the most valuable contributions are:

- **Physics specification review** — especially aerodynamics, radar, EW
- **Architecture critique** — especially determinism, ECS design, AMR
- **Domain expertise** — military simulation standards (DIS/HLA, STANAG)

When core development begins (Q4 2026), software contributions will be accepted according to the process in CONTRIBUTING.md.

### I am a domain expert in [aerodynamics / radar / EW / military simulation]. How do I help?

Open a GitHub Issue tagged `[review]` and describe your background and which part of the specification you'd like to review. Expert critique of the physics and architecture documents is the highest-value contribution at this stage.

### Can I collaborate on the project academically?

Yes. If you are at a research institution with relevant expertise and would like to explore joint research, open an Issue tagged `[collaboration]` or contact the maintainer directly.

---

*This document will be updated as the project progresses. Last updated: 2026-05.*
