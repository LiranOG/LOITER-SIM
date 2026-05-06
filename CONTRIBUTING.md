# Contributing to LOITER-SIM

Thank you for your interest in contributing. This document outlines the standards, workflow, and expectations for all contributors. Please read it in full before opening issues or submitting pull requests.

---

## Table of Contents

1. [Code of Conduct](#code-of-conduct)
2. [Project Status](#project-status)
3. [How to Contribute](#how-to-contribute)
4. [Development Environment](#development-environment)
5. [Branching Strategy](#branching-strategy)
6. [Commit Standards](#commit-standards)
7. [Pull Request Process](#pull-request-process)
8. [Coding Standards](#coding-standards)
9. [Physics & Numerics Standards](#physics--numerics-standards)
10. [Testing Requirements](#testing-requirements)
11. [Documentation Requirements](#documentation-requirements)
12. [Licensing](#licensing)

---

## Code of Conduct

All contributors are expected to adhere to the [Code of Conduct](./CODE_OF_CONDUCT.md). Violations will result in removal from the project.

---

## Project Status

LOITER-SIM is in **pre-alpha design phase**. No executable code exists yet — implementation begins in Q4 2026 (M1). Contributions at this stage are most valuable in the following areas:

- Physics specification review and critique (`specs/`)
- Architecture design feedback (open an issue)
- Domain expertise (aerodynamics, sensor physics, C2 networks, RL environments)
- Documentation improvements

When core development begins, this guide will be updated to include build instructions and test procedures, and code contributions will become the primary focus.

---

## How to Contribute

### Reporting Bugs

Bug reports are tracked via [GitHub Issues](https://github.com/LiranOG/LOITER-SIM/issues). Use the **Bug Report** template and include:

- A minimal reproducible example
- Expected vs. actual behavior
- Your environment (OS, compiler version, GPU if relevant)
- Relevant log output or assertion failures

### Suggesting Features

Feature requests use the **Feature Request** template. Before submitting:

1. Search existing issues to avoid duplicates.
2. Clearly state the use case — who benefits, and how.
3. If the feature involves new physics or numerics, cite the relevant literature.

### Domain Expertise

If you are a subject-matter expert in aerodynamics, radar physics, electronic warfare, military simulation standards (DIS/HLA), or multi-agent RL, your review of the `specs/` documents is highly valued. Open an issue tagged `[review]` with your feedback.

---

## Development Environment

### Required Tools

| Tool | Minimum Version | Purpose |
|------|----------------|---------|
| GCC or Clang | GCC 12 / Clang 16 | C++17 compilation |
| CMake | 3.20 | Build system |
| Python | 3.10 | Bindings and tooling |
| GoogleTest | 1.14 | Unit testing |
| PyBind11 | 2.11 | Python/C++ bindings |
| HDF5 | 1.12 | Checkpoint/replay format |
| clang-format | 17+ | Code formatting |
| clang-tidy | 17+ | Static analysis |

### Build (when available, target M1 Q4 2026)

```bash
git clone https://github.com/LiranOG/LOITER-SIM.git
cd LOITER-SIM
cmake -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build --parallel $(nproc)
ctest --test-dir build --output-on-failure
```

---

## Branching Strategy

LOITER-SIM uses **GitHub Flow**:

| Branch | Purpose |
|--------|---------|
| `main` | Stable, reviewed code. Direct pushes prohibited. |
| `dev` | Active integration branch. All PRs target `dev`. |
| `feature/<name>` | Feature branches, forked from `dev`. |
| `fix/<name>` | Bug fix branches, forked from `dev`. |
| `docs/<name>` | Documentation-only changes. |
| `release/vX.Y.Z` | Release preparation branches. |

**Never commit directly to `main`.** All changes enter via pull request with at least one review approval.

---

## Commit Standards

LOITER-SIM follows the [Conventional Commits](https://www.conventionalcommits.org/) specification.

### Format

```
<type>(<scope>): <short description>

[optional body]

[optional footer(s)]
```

### Types

| Type | When to Use |
|------|------------|
| `feat` | New feature or capability |
| `fix` | Bug fix |
| `perf` | Performance improvement |
| `refactor` | Code restructuring, no behavior change |
| `test` | Adding or updating tests |
| `docs` | Documentation only |
| `ci` | CI/CD pipeline changes |
| `chore` | Build system, dependency updates |
| `physics` | Changes to numerical methods or physical models |

### Scope Examples

`6dof`, `amr`, `sensors`, `ecs`, `gymnasium-api`, `yaml-parser`, `hdf5`, `ci`

### Examples

```
feat(6dof): implement quaternion-based rigid body integrator

Implements RK4 integration of Newton-Euler equations with quaternion
rotation state. Energy conservation verified over 10 s flight envelope.

Refs #42
```

```
physics(amr): correct Berger-Oliger refinement criterion

Previous implementation used L1 norm for refinement trigger. Replaced
with second-derivative magnitude per Berger & Oliger (1984) §3.2.

Closes #67
```

---

## Pull Request Process

1. **Fork** the repository and create your branch from `dev`.
2. **Make your changes** following the coding and testing standards below.
3. **Run all tests** locally before opening a PR.
4. **Fill in the PR template** completely. Incomplete PRs will be closed.
5. **Request review** — at least one maintainer approval is required to merge.
6. **Squash-merge** is preferred for feature branches to keep `dev` history clean.

### PR Checklist

- [ ] Branch targets `dev`, not `main`
- [ ] All existing tests pass
- [ ] New functionality has accompanying tests
- [ ] `clang-format` applied (`make format`)
- [ ] `clang-tidy` passes with no new warnings
- [ ] Documentation updated if behavior changes
- [ ] Physics changes cite relevant literature in commit body
- [ ] CHANGELOG.md updated under `[Unreleased]`

---

## Coding Standards

LOITER-SIM enforces strict C++17 standards. The configuration is in `.clang-format` and `.clang-tidy` at the repository root.

### Core Principles

**Determinism is sacred.** Any code that introduces floating-point non-determinism (e.g., unordered parallel reductions, `std::unordered_map` with pointer keys, platform-dependent math) will be rejected. If you are unsure, add a determinism regression test.

**Performance is a feature.** The engine must sustain 50,000+ agents at real-time. Avoid heap allocations in hot loops. Use data-oriented design (SoA layouts, ECS patterns). Cache misses are bugs.

**No undefined behavior.** All code must compile clean under `-fsanitize=address,undefined`. UBSan and ASan must be run in CI.

### Style Rules

```cpp
// Namespaces: lowercase, snake_case
namespace loiter::core::dynamics { }

// Classes: PascalCase
class RigidBody6DOF { };

// Methods and variables: snake_case
void integrate_state(double dt);
double angle_of_attack = 0.0;

// Constants: UPPER_SNAKE_CASE prefixed with k
constexpr double kGravity = 9.80665;

// Template parameters: PascalCase
template <typename ScalarType>

// File names: snake_case.cpp / snake_case.hpp
rigid_body_6dof.cpp
rigid_body_6dof.hpp
```

### Forbidden Patterns

```cpp
// ❌ Raw owning pointers — use smart pointers or value types
RigidBody* body = new RigidBody();

// ❌ Exceptions — use std::expected or error codes
throw std::runtime_error("...");

// ❌ Global mutable state
static double g_timestep = 0.01;

// ❌ Magic numbers
position += 9.81 * dt * dt;  // What is 9.81? Name it.

// ✅ Correct
constexpr double kGravity = 9.80665;  // m/s², WGS-84 standard
position += kGravity * dt * dt;
```

---

## Physics & Numerics Standards

Any contribution touching numerical methods or physical models must meet the following bar:

1. **Literature citation required.** Every non-trivial formula must reference the source (paper, textbook, standard). Include author, title, year, and equation number in the code comment.

2. **Units must be explicit.** All physical quantities must document their units. Use SI throughout the core engine.

   ```cpp
   double airspeed_m_s = 0.0;      // True airspeed [m/s]
   double altitude_m   = 0.0;      // MSL altitude [m]
   double mass_kg      = 5.0;      // Total mass including payload [kg]
   ```

3. **Dimensional analysis comment required** for any non-obvious calculation.

4. **Energy / momentum conservation test required** for any new integrator or dynamics module. The test must verify conservation over at least 10 seconds of simulated time.

5. **Determinism regression test required** for any new stateful module: run twice with identical seed, assert bitwise equality.

---

## Testing Requirements

- All new features require unit tests using GoogleTest.
- Physics modules require conservation property tests.
- All new code paths must be covered by at least one test.
- Tests live in `tests/` mirroring the `core/` structure.
- Test names follow `TEST(ModuleName, DescriptiveBehavior)`.

```cpp
TEST(RigidBody6DOF, EnergyConservationFreeFlight) {
    // Setup: unit-mass body, no drag, no thrust
    // Assert: total mechanical energy constant to 1e-9 over 10 s
}

TEST(RigidBody6DOF, DeterministicReplay) {
    // Assert: two runs with identical seed produce bitwise-identical state vectors
}
```

---

## Documentation Requirements

- All public API headers must be documented with Doxygen-compatible comments.
- New `specs/` documents must follow the structure of existing spec files.
- Physics changes must update the relevant spec document.
- Type-2 (architectural) decisions require an ADR in `docs/adr/`.

---

## Licensing

By submitting a contribution, you agree that your contribution is licensed under the **GNU General Public License v3.0**, and that you have the right to license it as such. You retain copyright over your own contributions.

Contributors who wish to retain compatibility with the commercial license must sign a **Contributor License Agreement (CLA)** — details provided on request.

---

*Last updated: 2026-05. Questions? Open an issue tagged `[question]` or contact the maintainer directly.*
