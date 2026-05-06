# Pull Request

## Summary

<!-- One paragraph: what does this PR do, and why? -->

## Type of Change

<!-- Mark all that apply with an X -->

- [ ] `feat` — New feature or capability
- [ ] `fix` — Bug fix
- [ ] `perf` — Performance improvement
- [ ] `refactor` — Code restructuring (no behavior change)
- [ ] `physics` — New or modified physical model / numerical method
- [ ] `test` — New or updated tests
- [ ] `docs` — Documentation only
- [ ] `ci` — CI/CD pipeline
- [ ] `chore` — Build system, dependencies

## Motivation & Context

<!-- Why is this change needed? Link to the relevant issue(s). -->

Closes #<!-- issue number -->

## What Changed

<!-- Describe the changes made. For physics changes, include the governing equations and the source reference. -->

## Physics & Numerics (if applicable)

<!-- For any new or modified physical model: -->
**Literature reference:**
> Author, *Title*, Year, Equation X.Y

**Units:** All new physical quantities use SI units with documented unit suffixes in variable names.

**Validation:** Describe how the physical correctness was verified.

## Testing

<!-- How did you test this? -->

- [ ] All existing tests pass locally (`ctest --test-dir build`)
- [ ] New tests added for new behavior
- [ ] Determinism regression test passes

**Specific tests added / modified:**
```
TEST(ModuleName, BehaviorUnderTest) — describe what it verifies
```

## Performance Impact

<!-- Does this PR affect simulation throughput? -->

- [ ] No performance impact
- [ ] Performance improved — benchmark before/after:
- [ ] Performance regressed (justified by correctness gain) — explain:

## Code Quality

- [ ] `clang-format` applied (`make format`)
- [ ] `clang-tidy` passes with no new warnings
- [ ] No heap allocations in hot paths introduced
- [ ] No UB introduced (ASan/UBSan clean)

## Documentation

- [ ] Inline Doxygen comments updated / added
- [ ] `ARCHITECTURE.md` updated (if architecture changed)
- [ ] `specs/PHYSICS_SPEC.md` updated (if physics model changed)
- [ ] `CHANGELOG.md` updated under `[Unreleased]`
- [ ] `ROADMAP.md` milestone updated (if milestone deliverable)

## Screenshots / Benchmarks (Optional)

<!-- If relevant, include before/after benchmark output or visualization. -->

---

**By submitting this pull request, I confirm that my contribution is licensed under the GPLv3 and that I have the right to license it as such.**
