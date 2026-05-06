# ADR-003: Fixed-Timestep RK4 Over Adaptive Integrators

**Date:** 2026-05
**Status:** Accepted
**Deciders:** Schwartz, Liran M.

---

## Context

The choice of numerical integrator for the 6-DOF rigid body dynamics is one of the most consequential decisions in the simulation engine. It determines:

- The accuracy of every flight trajectory
- The energy conservation properties over long simulations
- The reproducibility (determinism) of the simulation
- The performance of the physics hot loop

Two broad families of methods are available:

**Fixed-timestep methods:** integrate the state at constant `Δt` regardless of how rapidly the state is changing.
- Examples: Euler, RK2 (midpoint), RK4 (classical Runge-Kutta), Verlet, Symplectic Euler

**Adaptive-timestep methods:** dynamically adjust `Δt` based on local error estimates.
- Examples: RK45 (Dormand-Prince), RK78, DOP853, Adams-Bashforth-Moulton

This ADR documents the decision to use fixed-timestep RK4 as the default integrator for LOITER-SIM.

---

## Decision

Use **classical 4th-order Runge-Kutta (RK4)** at a **fixed timestep** (default 10 ms / 100 Hz, configurable per-scenario) as the standard integrator for all 6-DOF rigid body dynamics.

---

## Rationale

### Why RK4 over lower-order methods (Euler, RK2)

For a unit-mass body in free flight (no external forces), total mechanical energy must be conserved. Numerical integrators introduce energy drift proportional to a power of the timestep:

| Method | Order | Energy drift over 10s @ 100Hz | Notes |
|--------|-------|------------------------------|-------|
| Euler (1st order) | O(Δt) | ~1–10 % | Unacceptable; visible in RL signal |
| RK2 (2nd order) | O(Δt²) | ~0.01 % | Acceptable for short missions |
| **RK4 (4th order)** | O(Δt⁴) | **< 1e-6** | Acceptable for all missions |
| RK6+ | O(Δt⁶+) | < 1e-12 | Diminishing returns; computational cost not justified |

RK4 is the standard for real-time flight simulation precisely because it sits at the sweet spot: high enough order to be physically credible over long simulations, low enough cost to be feasible at 100+ Hz across many agents.

### Why fixed timestep over adaptive

Adaptive methods (RK45, DOP853) achieve better accuracy per integration step by dynamically adjusting `Δt` based on a local error estimate. They are mathematically superior for single-trajectory integration.

However, they are **incompatible with bitwise determinism** for several reasons:

1. **Step count is data-dependent.** Two runs with identical inputs may take different numbers of steps because of accumulated floating-point error in the error estimator. Different step counts → different state at any given simulated time.

2. **Step rejection breaks parallel synchronization.** When some agents reject a step (and others don't), the parallel execution model becomes irregular and harder to keep deterministic across thread counts.

3. **State sampling becomes ambiguous.** RL agents observe state at fixed simulated times (every 10 ms). With variable steps, interpolation is required — and interpolation introduces its own non-determinism if not carefully controlled.

4. **The physics doesn't need it.** UAV / loitering munition flight envelopes do not exhibit the stiffness that would justify adaptive methods. Stiff problems (atmospheric reentry, hypersonic vehicles) might benefit from adaptive integration; subsonic and transonic UAV dynamics do not.

### Why 10 ms (100 Hz) as the default timestep

UAV autopilot control loops typically run at 100–400 Hz. A 10 ms simulation timestep:
- Matches the lower end of real autopilot rates
- Gives ~1000 timesteps per 10-second engagement (sufficient for accurate energy conservation under RK4)
- Allows 50 Hz observation sampling (every 2 simulation ticks) for RL agents — a comfortable balance between sample efficiency and information freshness

Faster timesteps (configurable to 1 ms / 1 kHz) are available for:
- High-agility platforms (acrobatic UAS, fast interceptors)
- Validation runs that compare against analytic solutions
- Edge cases where 10 ms produces visible discretization artifacts

### Why not symplectic / Verlet integrators

Symplectic integrators (Verlet, leapfrog) have superior long-term energy conservation properties for Hamiltonian systems. They are the standard for molecular dynamics, orbital mechanics, and any problem where energy drift over millions of timesteps matters.

For LOITER-SIM, this advantage does not apply:
- Engagements last seconds to minutes, not millions of steps
- Forces are non-conservative (drag, thrust) — symplectic advantage is reduced
- Symplectic integration of rotation requires special care (quaternion representation makes the standard symplectic schemes non-trivial to apply)

RK4 with renormalized quaternions is the standard choice for aerospace dynamics simulation. Symplectic methods may be revisited if a specific use case (e.g., long-duration loiter scenarios, orbital extension) emerges.

---

## Consequences

**Positive:**
- Bitwise-deterministic integration across runs and platforms
- Predictable per-tick computational cost (no step-size variability)
- Easy to vectorize: every agent executes the same number of operations per tick
- Energy conservation < 1e-6 over 10 s satisfies all RL training requirements
- Simple to implement, audit, and unit-test

**Negative:**
- Less accurate per integration step than adaptive methods (mitigated by smaller fixed timestep when needed)
- Wastes computation on agents that could tolerate larger timesteps
- Requires user judgment to choose appropriate timestep for unusual scenarios

**Cost:** ~5–10 % computational overhead vs. RK2, ~50 % overhead vs. Euler. Both are acceptable given the 50,000-agent target with substantial performance headroom.

---

## Implementation Notes

The integrator interface is generic to allow future extension:

```cpp
template <typename StateVector, typename Dynamics>
StateVector rk4_step(const StateVector& x,
                     const Dynamics& f,
                     double t, double dt);
```

Alternative integrators (Euler for unit-tests, symplectic Verlet if added later) can be implemented behind the same interface and selected via scenario configuration.

---

## Dissenting Views

*None recorded at time of decision.*

---

## Alternatives Reconsidered

This decision should be revisited if:
- A use case emerges that requires hours-to-days simulation duration where energy drift over 100,000+ timesteps becomes significant (would suggest symplectic integrator)
- Hardware-in-the-loop integration requires variable-rate execution to match physical autopilot timing (would suggest interpolation layer over fixed-step core, not adaptive integration)
- A specific platform exhibits stiffness that 10 ms fixed timestep cannot resolve (would suggest per-platform timestep scaling, not full adaptivity)
