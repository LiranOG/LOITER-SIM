# ADR-002: Bitwise Determinism as a Hard Requirement

**Date:** 2026-05
**Status:** Accepted
**Deciders:** Schwartz, Liran M.

---

## Context

Simulation engines can be deterministic at different levels:

- **Statistical determinism:** Outputs have the same statistical distribution across runs
- **Approximate determinism:** Outputs are "close" across runs (within some epsilon)
- **Bitwise determinism:** Outputs are bit-for-bit identical across runs with the same seed

LOITER-SIM must choose which level to target. This ADR documents the decision to require bitwise determinism and the engineering implications.

---

## Decision

LOITER-SIM requires **bitwise determinism**: identical (scenario, seed) pairs must produce bit-for-bit identical output across all runs, on any IEEE 754-compliant platform with the same FP rounding mode.

---

## Rationale

### Why statistical determinism is insufficient

Statistical determinism — "the agent learns the same behavior on average" — is not sufficient for:

1. **Debugging.** When a simulation produces an unexpected result (a crash, an anomalous trajectory), the developer must be able to reproduce it exactly. Non-reproducible bugs are effectively unreported bugs.

2. **Regression testing.** A physics regression test must assert that a specific output matches a specific expected value exactly. "Approximately the same" requires setting a tolerance, which means the test can pass even when the physics has changed.

3. **Weapon system certification.** Certification of autonomous systems (DO-178C for aviation, MIL-STD-882 for defense) requires verifiable repeatability of all safety-relevant behaviors.

### Why approximate determinism is insufficient

Approximate determinism ("within 1e-6 relative error") fails for the same reasons as statistical determinism in the regression testing and certification contexts. It also fails for RL: small differences in observation accumulate over many timesteps, producing divergent policy gradients.

### Engineering cost of bitwise determinism

Bitwise determinism requires:

1. **Controlled FP rounding mode:** `fesetround(FE_TONEAREST)` at startup; compiler flag `-fno-unsafe-math-optimizations` to prevent reordering.
2. **No x87 extended precision:** Compiler flag `-mfpmath=sse -msse2` on x86 to force 64-bit FP throughout.
3. **Ordered reductions:** Parallel sum reductions must use a fixed, ordered reduction tree (not a work-stealing scheduler's arbitrary order).
4. **Deterministic PRNG:** xoshiro256** with per-agent sub-streams derived from the global seed.
5. **No hash maps with pointer keys:** Iteration order of `std::unordered_map` with pointer keys depends on ASLR and heap layout, which varies across runs.
6. **Fixed thread count:** The number of threads used for physics must be fixed at world initialization, not dynamically adjusted.

These constraints add non-trivial engineering complexity. They are accepted as necessary costs.

---

## Consequences

**Positive:**
- Reproducible debugging: any bug can be reproduced from its (scenario, seed) pair
- Deterministic regression tests: no tolerance windows, no flaky tests
- Replay-by-actions: replays store only the action sequence + seed, not full state (massive storage reduction)
- Certification-ready: verifiable repeatability satisfies DO-178C and MIL-STD-882 requirements at the simulation layer

**Negative:**
- Restricts use of some parallel algorithms (unordered parallel reductions)
- Cannot use `-ffast-math` or `-Ofast` (these break IEEE 754 guarantees)
- Requires careful management of any third-party library that uses FP internally (must verify their FP behavior)
- Platform portability: the guarantee holds only for IEEE 754-compliant platforms (covers all modern x86, ARM64, RISC-V)

**Non-consequence:** Bitwise determinism does NOT require single-threaded execution. It requires that the parallel execution model is deterministic (fixed thread count, ordered reductions). This is achievable with modern C++ thread management.

---

## Verification

The determinism guarantee is verified by a CI regression test that:
1. Runs benchmark scenario with seed 42 for 1,000 ticks
2. Computes SHA-256 of the full world state vector
3. Runs again from scratch independently
4. Asserts checksums match

This test runs on every commit to `dev` and `main`.

---

## Dissenting Views

A reviewer suggested that "approximate determinism with 1e-9 tolerance" would be sufficient for RL training while allowing more aggressive FP optimizations. This was rejected because:
- The certification requirement demands bitwise reproducibility, not approximate
- The performance cost of IEEE 754 compliance (vs. `-ffast-math`) is estimated at 5–15 %, which is acceptable given the 50,000-agent headroom in the performance budget

The reviewer's concern is acknowledged: if the performance budget becomes tight, this trade-off should be revisited before adding hardware or reducing agent count.
