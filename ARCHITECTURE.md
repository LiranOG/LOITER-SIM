# LOITER-SIM Architecture

**Version:** Pre-Alpha Design Specification (v0.3-draft)
**Last updated:** 2026-05
**Status:** Design phase — subject to revision based on expert review and implementation experience

---

## Table of Contents

1. [Design Philosophy](#1-design-philosophy)
2. [System Overview](#2-system-overview)
3. [Core Engine (C++)](#3-core-engine-c)
4. [Entity Component System](#4-entity-component-system)
5. [Physics Subsystems](#5-physics-subsystems)
6. [Adaptive Mesh Refinement](#6-adaptive-mesh-refinement)
7. [Sensor Simulation](#7-sensor-simulation)
8. [Networking & Communications](#8-networking--communications)
9. [Python Bindings & RL API](#9-python-bindings--rl-api)
10. [Persistence Layer](#10-persistence-layer)
11. [Determinism Guarantee](#11-determinism-guarantee)
12. [Performance Architecture](#12-performance-architecture)
13. [Build System](#13-build-system)
14. [Dependency Graph](#14-dependency-graph)

---

## 1. Design Philosophy

LOITER-SIM is built on four non-negotiable engineering principles. Every architectural decision in this document traces back to one of them.

### 1.1 Determinism is Correctness

A simulation that produces different results from the same input is not a simulation — it is an expensive random-number generator with graphics. LOITER-SIM enforces bitwise-identical output for identical (scenario, seed) pairs across:

- Different invocation times
- Different numbers of threads (within the deterministic execution model)
- Different machines with the same IEEE 754 floating-point behavior

Any code change that breaks this guarantee is a regression, regardless of how much it improves any other metric.

### 1.2 Performance is a Physical Constraint

The physical world runs at 1× real-time. Training useful AI requires 100×–1000× real-time throughput. This is not an optimization target — it is a hard requirement. Architecture decisions are made with this constraint as a first-class concern:

- Cache-friendly data layouts (Structure-of-Arrays, not Array-of-Structures)
- Zero heap allocation in hot paths
- SIMD-friendly data widths
- Headless-first design (rendering is always optional)

### 1.3 Physics Must Be Cited

Every numerical method and physical model in this codebase must be traceable to peer-reviewed literature or established military / aerospace standards. No ad-hoc approximations without documented justification and measured error bounds. The physics specification (`specs/PHYSICS_SPEC.md`) is authoritative — code that conflicts with the spec is wrong by definition.

### 1.4 Clean Layered Interface

The C++ core must be entirely independent of the Python layer. The Python layer must be entirely independent of the rendering layer. Each layer can be replaced or removed without affecting the others. This is enforced by the build system — circular dependencies are caught at link time.

---

## 2. System Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        EXTERNAL LAYER                           │
│  RL Agents (PyTorch/TF)  │  VR/FPV Operator  │  C4I / DIS/HLA  │
└──────────────┬──────────────────────┬───────────────────┬───────┘
               │                      │                   │
┌──────────────▼──────────────────────▼───────────────────▼───────┐
│                      PYTHON API LAYER                            │
│         Gymnasium-compatible step() / reset() interface          │
│              PyBind11 bindings  │  YAML scenario loader          │
└──────────────────────────────────┬───────────────────────────────┘
                                   │
┌──────────────────────────────────▼───────────────────────────────┐
│                       C++ CORE ENGINE                             │
│                                                                   │
│  ┌─────────────┐  ┌──────────────┐  ┌────────────────────────┐  │
│  │  ECS World  │  │  AMR Solver  │  │  Determinism Manager   │  │
│  │  (Entities, │  │  (Berger-    │  │  (PRNG, tick counter,  │  │
│  │  Components,│  │   Oliger)    │  │   FP-mode enforcement) │  │
│  │  Systems)   │  └──────────────┘  └────────────────────────┘  │
│  └──────┬──────┘                                                  │
│         │                                                         │
│  ┌──────▼─────────────────────────────────────────────────────┐  │
│  │                    PHYSICS SUBSYSTEMS                       │  │
│  │  6-DOF Dynamics │ Aerodynamics │ Propulsion │ Collisions   │  │
│  └────────────────────────────────────────────────────────────┘  │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │                    SENSOR SUBSYSTEMS                        │  │
│  │  Radar (RCS) │ EO/IR │ INS/GPS │ EW (Jamming/Spoofing)    │  │
│  └─────────────────────────────────────────────────────────────┘  │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │                  COMMUNICATIONS SUBSYSTEM                   │  │
│  │  Mesh networking │ Packet loss model │ C2 link simulation  │  │
│  └─────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────┘
                                   │
┌──────────────────────────────────▼───────────────────────────────┐
│                      PERSISTENCE LAYER                            │
│          HDF5 checkpoints  │  CSV telemetry  │  Replay files      │
└───────────────────────────────────────────────────────────────────┘
```

---

## 3. Core Engine (C++)

### 3.1 Directory Structure

```
core/
├── ecs/                    # Entity-Component-System runtime
│   ├── world.hpp           # Central ECS world
│   ├── entity.hpp          # Entity ID type
│   ├── component_pool.hpp  # Typed, cache-aligned component storage
│   └── system.hpp          # System base class
├── dynamics/
│   ├── rigid_body_6dof.hpp # 6-DOF state and integrator
│   ├── integrators.hpp     # RK4, Euler (reference)
│   └── quaternion.hpp      # Rotation math
├── aerodynamics/
│   ├── aero_model.hpp      # Abstract aerodynamics interface
│   ├── lookup_table.hpp    # Multi-dim interpolation
│   └── isa_atmosphere.hpp  # International Standard Atmosphere
├── sensors/
│   ├── radar.hpp           # RCS-based detection model
│   ├── eo_ir.hpp           # Electro-optical / infrared
│   ├── ins_gps.hpp         # Inertial navigation + GPS
│   └── ew_jammer.hpp       # Electronic warfare effects
├── amr/
│   ├── grid.hpp            # AMR grid structure
│   ├── refinement.hpp      # Berger-Oliger criterion
│   └── patch.hpp           # AMR patch type
├── comms/
│   ├── mesh_network.hpp    # Inter-agent communication
│   └── c2_link.hpp         # Command and control link model
├── scenario/
│   ├── loader.hpp          # YAML scenario parser
│   └── scenario.hpp        # Scenario data structures
└── determinism/
    ├── prng.hpp             # Deterministic PRNG (xoshiro256**)
    └── fp_guard.hpp         # Floating-point mode enforcement
```

### 3.2 Simulation Loop

```
tick(dt):
  1. DeterminismManager::begin_tick(tick_id)
  2. ECS: run input systems (C2 commands, sensor updates)
  3. AMR: evaluate refinement criterion, refine/coarsen grid
  4. ECS: run physics systems (6-DOF integration, collisions)
  5. ECS: run sensor systems (radar, EO/IR, INS/GPS, EW)
  6. ECS: run comms systems (mesh network propagation)
  7. ECS: run agent decision systems (behavior trees / RL policy)
  8. PersistenceLayer::write_telemetry(tick_id, world_state)
  9. DeterminismManager::end_tick(tick_id, checksum)
```

The order of these steps is not arbitrary. Sensor systems execute *after* physics so that detections reflect post-integration state. Comms execute after sensors so that detection reports can be transmitted. Decision systems execute last so that this tick's policy decisions become next tick's actions.

---

## 4. Entity Component System

LOITER-SIM uses a **custom data-oriented ECS** designed for 50,000+ simultaneous agents at real-time speeds. The decision to implement custom rather than adopt EnTT or Flecs is documented in [ADR-001](./docs/adr/ADR-001-ecs-architecture.md).

### 4.1 Design Choices

- **Structure of Arrays (SoA)** component storage for SIMD vectorization
- **Archetype-based** storage (entities with the same component set share contiguous memory)
- **Fixed-size component pools** — no dynamic allocation after world initialization
- **Deterministic iteration order** — entities iterated in creation order, guaranteed across runs and platforms

### 4.2 Core Component Types

| Component | Data | Notes |
|-----------|------|-------|
| `Transform` | position (vec3), orientation (quat) | World frame (NED) |
| `RigidBody` | velocity (vec3), angular velocity (vec3), mass | Body frame |
| `AeroState` | AoA, sideslip, airspeed, Mach | Computed each tick |
| `SensorSuite` | radar cross-section, IR signature | Platform-specific |
| `NavState` | GPS fix, INS accumulated error | EW-affected |
| `CommNode` | transmit power, frequency band, range | Mesh networking |
| `AgentPolicy` | policy type (RL/BT/scripted), policy handle | Decision-making |
| `Health` | structural integrity, warhead state | Terminal logic |

---

## 5. Physics Subsystems

### 5.1 6-DOF Rigid Body Dynamics

**Reference:** Stevens, Lewis & Johnson, *Aircraft Control and Simulation* (3rd ed., Wiley, 2015), Ch. 2–3.

State vector per entity (13 scalars):

```
x = [px, py, pz,         # Position (NED) [m]
     vx, vy, vz,         # Velocity (body frame) [m/s]
     q0, q1, q2, q3,     # Orientation quaternion (unit)
     p, q, r]            # Angular velocity (body frame) [rad/s]
```

Integration: **4th-order Runge-Kutta (RK4)** with fixed timestep. The decision to use fixed-timestep RK4 over adaptive integrators is documented in [ADR-003](./docs/adr/ADR-003-rk4-fixed-timestep.md).

Equations of motion:

- Translational: `F = ma` in body frame, rotated to world via quaternion
- Rotational: Euler's equations with inertia tensor `I`
- Quaternion kinematics: `dq/dt = 0.5 * q ⊗ ω`

### 5.2 Aerodynamics

Lift and drag computed via **multi-dimensional lookup tables** (not real-time CFD).

- Coefficients `C_L(α, M, δe)`, `C_D(α, M)` interpolated from tabulated data
- **International Standard Atmosphere (ISA)** for density, pressure, speed of sound
- Tables stored as binary HDF5 datasets for fast load and compact storage

Full derivation: [specs/PHYSICS_SPEC.md §4](./specs/PHYSICS_SPEC.md#4-aerodynamics).

### 5.3 Propulsion

Configurable propulsion models:
- Fixed-thrust (simple loitering munition)
- Throttle-controlled (multi-rotor UAS)
- Fuel-burning (turbine / piston)

---

## 6. Adaptive Mesh Refinement

**Reference:** Berger & Oliger, *Adaptive Mesh Refinement for Hyperbolic Partial Differential Equations*, J. Comput. Phys. 53 (1984).

LOITER-SIM's AMR solver dynamically refines the 3D spatial grid to concentrate computational resolution where entities, sensors, and terrain features require it.

### Refinement Criterion

Refinement triggered when the second-derivative magnitude of the entity-density field exceeds a configurable threshold `τ_r`. Coarsening triggered when it falls below `τ_c < τ_r`.

```
|∂²ρ/∂x²| + |∂²ρ/∂y²| + |∂²ρ/∂z²| > τ_r  →  refine
                                            < τ_c  →  coarsen
```

### Patch Hierarchy

- Base grid: coarse resolution covering full scenario area
- Refined patches: up to 4 levels of refinement (16× linear resolution increase)
- Sensor patches: always refined around active radar / EO-IR emitters
- C2 patches: refined around communication nodes during active transmission

---

## 7. Sensor Simulation

### 7.1 Radar (RCS-Based)

Detection based on **Radar Range Equation**:

```
P_r = (P_t · G_t · G_r · λ² · σ) / ((4π)³ · R⁴ · L)
```

Where `σ` is the target's Radar Cross Section as a function of aspect angle, loaded from per-platform lookup tables.

Detection threshold: configurable SNR in dB above noise floor.

Full specification: [specs/SENSOR_SPEC.md §2](./specs/SENSOR_SPEC.md#2-radar-detection-model).

### 7.2 EO/IR

Field-of-view raycasting against entity bounding volumes. IR signature model accounts for:
- Engine exhaust temperature
- Airframe heating at high Mach
- Background clutter (terrain IR) from ISA + solar model

### 7.3 INS/GPS

- **GPS:** configurable fix quality, HDOP, and jamming radius
- **INS:** accumulated error model (drift rate configurable per-platform)
- **Spoofing:** GPS position injection attack model (moves reported position)

### 7.4 Electronic Warfare

- **Jamming:** noise-floor elevation within configurable frequency band and geometry
- **Spoofing:** false-target injection for radar and GPS
- **DRFM:** Digital Radio Frequency Memory jammer (stretch-pulse spoofing)

---

## 8. Networking & Communications

### 8.1 Mesh Network Model

Each agent has a `CommNode` component with:
- Transmit power `P_t` [W]
- Frequency band [GHz]
- Directional antenna gain pattern (isotropic default)
- Data rate [Mbps]

Link quality computed per-pair using free-space path loss + terrain obstruction (raycasted against AMR terrain geometry).

### 8.2 Packet Model

For each inter-agent message:
- **Latency:** distance-dependent + queuing model
- **Packet loss:** Bernoulli process with probability derived from link SNR
- **Bandwidth constraint:** per-node capacity shared among active links

### 8.3 C2 Link

Command-and-control link from operator / C2 system to agents modeled as a privileged communication channel with configurable:
- Uplink/downlink bandwidth
- Latency
- Jamming susceptibility

---

## 9. Python Bindings & RL API

### 9.1 PyBind11 Interface

```python
import loiter_sim

# Load a scenario
world = loiter_sim.World("scenarios/mass_attack_500.yaml")
world.reset(seed=42)

# Gymnasium-compatible step
obs, reward, terminated, truncated, info = world.step(actions)

# Headless batch: multiple worlds in parallel
batch = loiter_sim.BatchWorld(["scenarios/mass_attack_500.yaml"] * 64)
batch.reset(seeds=list(range(64)))
obs_batch, reward_batch, done_batch, info_batch = batch.step(action_batch)
```

### 9.2 Observation Space

Per-agent observation vector:
- Ego state: position, velocity, orientation, angular rate
- Sensor detections: up to N nearest contacts (configurable)
- Comm status: link quality to N nearest teammates
- Health: structural integrity, fuel/battery state

### 9.3 Action Space

Per-agent action vector:
- Thrust command [0, 1]
- Control surface deflections (roll, pitch, yaw) or rotor speed differentials
- Warhead release (binary)
- Comm transmit (binary + payload)

### 9.4 Reward Structure

Reward function is scenario-defined (YAML) and composable:
- Terminal: target destroyed, self destroyed, mission timeout
- Shaping: distance to target, formation quality, communication success rate

---

## 10. Persistence Layer

### 10.1 HDF5 Checkpoints

Full world state written to HDF5 at configurable intervals. Supports:
- Complete replay from any checkpoint
- State diff between two checkpoints
- Parallel reads for batch training data loading

### 10.2 CSV Telemetry

Lightweight per-tick telemetry for quick analysis:
- Agent positions, velocities, health
- Detection events
- Communication events

### 10.3 Replay Format

Binary replay files store the sequence of (action, seed) pairs sufficient to deterministically reproduce any simulation from scratch. Replay files are small (actions only, no state) because the simulation is deterministic — this is one of the practical payoffs of the determinism guarantee.

---

## 11. Determinism Guarantee

The full reasoning behind the bitwise-determinism requirement is documented in [ADR-002](./docs/adr/ADR-002-determinism-model.md). This section describes the implementation.

### 11.1 PRNG

Uses **xoshiro256\*\*** (Blackman & Vigna, 2019) — a fast, high-quality, splittable PRNG. Each agent receives a unique sub-stream derived from the global seed, ensuring per-agent determinism even when agent count changes.

### 11.2 Floating-Point Mode

At startup, the engine enforces:
- `fesetround(FE_TONEAREST)` — IEEE 754 round-to-nearest
- Denormal flush-to-zero **disabled** (consistent denormal handling)
- Compiler flags: `-mfpmath=sse -msse2` (x86) — no x87 80-bit extended precision
- Compiler flag: `-fno-unsafe-math-optimizations` — no FP reassociation
- Compiler flag: `-ffp-contract=off` — no fused multiply-add reordering

### 11.3 Parallel Determinism

Multi-threaded physics is deterministic because:
- Entities are partitioned into independent groups (no cross-entity writes during physics)
- Reduction operations (swarm statistics) use a fixed, ordered reduction tree
- Thread count is fixed at scenario load time

### 11.4 Determinism Testing

A CI regression test runs every commit:
1. Run scenario `benchmark_swarm_1000.yaml` with seed 42 for 1,000 ticks
2. Record final state checksum (SHA-256 of full state vector)
3. Run again independently
4. Assert checksums match

---

## 12. Performance Architecture

### 12.1 Targets

| Metric | Target |
|--------|--------|
| Agents (real-time) | 50,000 |
| Agents (10× real-time) | 5,000 |
| Agents (1000× real-time, headless) | 500 |
| Tick latency (50 k agents) | < 20 ms |
| Memory per agent | < 2 KB |

### 12.2 Critical Hot Path

The physics update loop (6-DOF integration) processes all agents in a single vectorized pass:
- Component data stored in SoA layout, aligned to 64-byte cache lines
- RK4 inner loop amenable to AVX2 (8× float32) or AVX-512 (16× float32) vectorization
- No virtual dispatch in hot path — system dispatch resolved at compile time via templates

### 12.3 Memory Budget (50,000 agents)

| Data | Per-Agent | Total |
|------|-----------|-------|
| Transform + RigidBody | 160 B | 7.6 MB |
| AeroState + NavState | 128 B | 6.1 MB |
| SensorSuite | 64 B | 3.1 MB |
| CommNode | 96 B | 4.6 MB |
| AgentPolicy handle | 16 B | 0.8 MB |
| **Total** | **464 B** | **22.2 MB** |

Well within L3 cache on modern server CPUs (typically 32–128 MB).

---

## 13. Build System

CMake 3.20+ with the following targets:

```cmake
loiter_sim_core      # Static library: all C++ engine code
loiter_sim_bindings  # Shared library: PyBind11 Python module
loiter_sim_tests     # GoogleTest test binary
loiter_sim_bench     # Google Benchmark binary
```

Build types:
- `Release` — full optimization (`-O3 -march=native -DNDEBUG`)
- `Debug` — sanitizers enabled (`-fsanitize=address,undefined`)
- `RelWithDebInfo` — profiling build

---

## 14. Dependency Graph

```
loiter_sim_core
├── yaml-cpp          (YAML scenario parsing)
├── HDF5              (checkpoints, aero tables)
├── Eigen3            (linear algebra)
└── {no other external deps — determinism requires control}

loiter_sim_bindings
├── loiter_sim_core
└── pybind11

loiter_sim_tests
├── loiter_sim_core
└── googletest

loiter_sim_bench
├── loiter_sim_core
└── benchmark (Google Benchmark)
```

All dependencies are pinned to exact versions in `cmake/dependencies.cmake` and fetched via CMake FetchContent for reproducible builds.

---

*This document is the authoritative architecture specification for LOITER-SIM. All implementation decisions should be traceable to a section here. Deviations require an Architecture Decision Record (ADR) in `docs/adr/`.*

*Last updated: 2026-05.*
