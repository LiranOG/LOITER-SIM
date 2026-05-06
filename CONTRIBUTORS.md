# Contributors & Acknowledgements

This document lists everyone who has contributed to LOITER-SIM — code, specification review, domain expertise, or other meaningful input.

---

## Founding Architect

| Name | GitHub | Role | Contributions |
|------|--------|------|---------------|
| **Liran M. Schwartz** | [LiranOG](https://github.com/LiranOG) | Founder & Lead Architect | Architecture, physics specification, sensor specification, design rationale, infrastructure, roadmap |

**BibTeX-style attribution:**
```
@software{schwartz_loiter_sim_2026,
    author    = {Schwartz, Liran M.},
    title     = {{LOITER-SIM}: A Deterministic Multi-Agent Simulation Engine for Autonomous UAV Swarms},
    year      = {2026},
    url       = {https://github.com/LiranOG/LOITER-SIM},
    license   = {GPL-3.0},
    version   = {0.0.1-pre-alpha}
}
```

---

## Specification Reviewers

*No external reviewers yet. This section will be populated as domain experts engage with the specification documents.*

If you have expertise in aerodynamics, radar physics, electronic warfare, INS/GPS, multi-agent RL, or military simulation standards (DIS/HLA/STANAG) and would like to review the specifications, open a GitHub Issue tagged `[review]`.

---

## How to Appear Here

Contributions that qualify for listing in this document:

- **Code contributions:** Any merged pull request
- **Specification review:** A substantive written review of a `specs/` or `docs/` document (via GitHub Issue or PR), identifying at least one non-trivial technical issue
- **Architecture review:** Written critique of `ARCHITECTURE.md` identifying a design trade-off that was not previously documented
- **Domain expertise:** Contribution of platform data, reference datasets, or scenario definitions based on domain knowledge

Listing is opt-in. If you have contributed and would prefer not to be listed, that is respected.

---

## Acknowledgements

LOITER-SIM builds on the following open-source projects and scientific literature:

### Software

- [Eigen](https://eigen.tuxfamily.org/) — linear algebra library (MPL 2.0)
- [yaml-cpp](https://github.com/jbeder/yaml-cpp) — YAML parsing (MIT)
- [HDF5](https://www.hdfgroup.org/) — data persistence (BSD-like)
- [GoogleTest](https://github.com/google/googletest) — unit testing (BSD 3-Clause)
- [PyBind11](https://github.com/pybind/pybind11) — Python bindings (BSD 3-Clause)
- [Google Benchmark](https://github.com/google/benchmark) — performance benchmarks (Apache 2.0)

### Scientific Literature

The physics specification cites these primary sources:

- Stevens, Lewis & Johnson, *Aircraft Control and Simulation* (3rd ed., Wiley, 2015)
- Berger & Oliger, *Adaptive Mesh Refinement for Hyperbolic PDEs*, J. Comput. Phys. 53 (1984)
- Richards, Scheer & Holm, *Principles of Modern Radar Vol. I* (SciTech, 2010)
- Knott, Shaeffer & Tuley, *Radar Cross Section* (2nd ed., SciTech, 2004)
- Titterton & Weston, *Strapdown Inertial Navigation Technology* (2nd ed., IET, 2004)
- Kaplan & Hegarty, *Understanding GPS/GNSS* (3rd ed., Artech House, 2017)
- Lloyd, *Thermal Imaging Systems* (Plenum Press, 1975)
- Adamy, *EW 102: A Second Course in Electronic Warfare* (Artech House, 2004)
- Blackman & Vigna, *Scrambled Linear Pseudorandom Number Generators* (2021) — xoshiro256**
- Hairer, Nørsett & Wanner, *Solving ODEs I* (2nd ed., Springer, 1993) — RK4

---

*Last updated: 2026-05.*
