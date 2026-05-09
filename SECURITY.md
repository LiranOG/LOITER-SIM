# Security Policy

## Supported Versions

LOITER-SIM is currently in pre-alpha (no executable code released). Security reports are accepted for any committed code or specification once implementation begins.

| Version | Supported |
|---------|-----------|
| `main` (pre-alpha, design phase) | ✅ |
| Future tagged releases | ✅ |
| Older commits / abandoned branches | ❌ |

Once versioned releases are published (target: 0.1.0-alpha in Q2 2027), this table will reflect the currently supported release line.

---

## Scope

LOITER-SIM is a simulation engine, not a networked service. The primary security concerns relevant to this codebase are:

### In Scope

- **Memory safety vulnerabilities** — buffer overflows, use-after-free, out-of-bounds reads/writes in the C++ core
- **Undefined behavior** — UB that could be exploited to corrupt simulation state or crash the process
- **Deserialization vulnerabilities** — malformed YAML scenario files or HDF5 checkpoint files causing unexpected behavior
- **Python binding vulnerabilities** — issues in the PyBind11 interface that could allow escape from the simulation sandbox
- **Dependency vulnerabilities** — known CVEs in bundled or required dependencies (HDF5, yaml-cpp, GoogleTest, PyBind11)
- **Supply-chain issues** — compromised dependencies or build artifacts

### Out of Scope

- Theoretical attacks requiring physical access to the machine running the simulator
- Issues in downstream applications built on top of LOITER-SIM
- GitHub Actions runner security (report those to GitHub)
- Social engineering

---

## Reporting a Vulnerability

**Do not open a public GitHub issue for security vulnerabilities.**

### Preferred Method

Use GitHub's **Private Security Advisory** feature:

1. Navigate to the [Security tab](https://github.com/LiranOG/LOITER-SIM/security) of this repository.
2. Click **"Report a vulnerability"**.
3. Fill in the advisory form with as much detail as possible.

### What to Include

- **Description** — A clear description of the vulnerability and its potential impact.
- **Affected component** — Which module, file, or dependency is affected.
- **Reproduction steps** — A minimal, self-contained reproduction case. If a specific input file (YAML scenario, HDF5 checkpoint) triggers the issue, attach it.
- **Impact assessment** — What can an attacker achieve? (crash, memory corruption, arbitrary code execution, data exfiltration, etc.)
- **Suggested fix** — If you have one. Not required, but appreciated.
- **Your environment** — OS, compiler version, relevant build flags.

### What Not to Include

- Do not include working exploit code in the initial report. Describe the vulnerability class and provide a crash reproducer only.

---

## Response Timeline

| Milestone | Target |
|-----------|--------|
| Acknowledgment of report | 48 hours |
| Initial triage and severity assessment | 5 business days |
| Status update to reporter | 10 business days |
| Patch or mitigation deployed | Dependent on severity (see below) |
| Public disclosure | Coordinated with reporter |

### Severity-Based Response

| Severity | CVSS Range | Target Patch Turnaround |
|----------|-----------|------------------------|
| Critical | 9.0–10.0 | 7 days |
| High | 7.0–8.9 | 14 days |
| Medium | 4.0–6.9 | 30 days |
| Low | 0.1–3.9 | Next scheduled release |

---

## Coordinated Disclosure

LOITER-SIM follows **responsible coordinated disclosure**. We ask that reporters:

1. Allow the response timeline above before public disclosure.
2. Notify of any planned publication so timing can be coordinated.
3. Work to understand the full impact before disclosure.

In return, the project commits to:

1. Keeping the reporter informed throughout the remediation process.
2. Crediting the reporter in the security advisory (unless anonymity is preferred).
3. Not pursuing legal action for good-faith security research.

---

## Security Best Practices for Users

When deploying LOITER-SIM (once code is available):

- **Run in a sandboxed environment.** The simulation engine is not designed to be exposed directly to untrusted network input. If exposing the Python API over a network, apply appropriate access controls.
- **Validate scenario files.** YAML scenario files should be treated as untrusted input if sourced from third parties. Run them in a restricted environment.
- **Keep dependencies updated.** Regularly update HDF5, yaml-cpp, and other dependencies to incorporate upstream security fixes.
- **Use compiler hardening flags.** Build with `-fstack-protector-strong`, `-D_FORTIFY_SOURCE=2`, and `-Wl,-z,relro` in production deployments.

---

## Commercial License Security

Commercial licensees with additional security requirements (classified environments, FIPS compliance, specific audit needs) should contact the maintainer for arrangements outside this public policy.

---

*This policy was last updated: 2026-05. For questions about this policy, open a public issue tagged `[security-policy]`.*
