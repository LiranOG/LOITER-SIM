# LOITER-SIM Physics Specification

**Document version:** 0.2-draft  
**Status:** Design phase — last updated 2026-05 — subject to revision  
**Scope:** Defines all physical models, numerical methods, and their authoritative sources.

---

## 1. Coordinate Systems

### 1.1 World Frame

LOITER-SIM uses a **local NED (North-East-Down)** coordinate system as the primary world frame for scenarios spanning ≤ 500 km.

- **x-axis:** North [m]
- **y-axis:** East [m]
- **z-axis:** Down [m]

Origin is defined per-scenario in the YAML configuration as a WGS-84 geodetic reference point.

For scenarios requiring global coverage, an ECEF (Earth-Centered, Earth-Fixed) frame is used. Conversion between frames follows WGS-84 standard.

### 1.2 Body Frame

Each rigid body has a body-fixed frame:

- **x-axis:** Forward (nose direction)
- **y-axis:** Right wing
- **z-axis:** Down (belly)

This follows the standard aerospace body frame convention.

**Reference:** Stevens, Lewis & Johnson, *Aircraft Control and Simulation* (3rd ed., Wiley, 2015), §1.3.

---

## 2. Rigid Body Dynamics (6-DOF)

### 2.1 State Vector

```
x = [p_x, p_y, p_z,       (position, world NED frame) [m]
     u, v, w,              (velocity, body frame) [m/s]
     q_0, q_1, q_2, q_3,  (orientation quaternion, body←NED) [unit]
     p, q, r]              (angular velocity, body frame) [rad/s]
```

Total: 13 scalar states per entity.

### 2.2 Equations of Motion

**Translational dynamics (body frame):**

```
m * (du/dt + q*w - r*v) = F_x
m * (dv/dt + r*u - p*w) = F_y
m * (dw/dt + p*v - q*u) = F_z
```

where `F = [F_x, F_y, F_z]` is the total external force in the body frame (aerodynamic + thrust + gravity rotated to body frame).

**Rotational dynamics (body frame, Euler's equations):**

```
I_xx * dp/dt - (I_yy - I_zz) * q * r = L
I_yy * dq/dt - (I_zz - I_xx) * r * p = M
I_zz * dr/dt - (I_xx - I_yy) * p * q = N
```

where `[L, M, N]` are the aerodynamic moments in the body frame. Cross-products of inertia are assumed zero (symmetric aircraft assumption); this will be relaxed in v1.1.

**Quaternion kinematics:**

```
dq/dt = 0.5 * Ω(ω) * q
```

where `Ω(ω)` is the skew-symmetric matrix form of the angular velocity vector.

Quaternion normalization is applied every tick to prevent drift: `q ← q / |q|`.

**Reference:** Stevens, Lewis & Johnson (2015), Ch. 1–2.

### 2.3 Numerical Integration — RK4

4th-order Runge-Kutta with fixed timestep `Δt`:

```
k1 = f(t,      x)
k2 = f(t + Δt/2, x + Δt/2 * k1)
k3 = f(t + Δt/2, x + Δt/2 * k2)
k4 = f(t + Δt,   x + Δt   * k3)

x(t + Δt) = x(t) + (Δt/6) * (k1 + 2*k2 + 2*k3 + k4)
```

Default timestep: `Δt = 0.01 s` (100 Hz). Configurable per-scenario.

**Energy conservation requirement:** Total mechanical energy must be conserved to within `1 × 10⁻⁶` relative error over 10 seconds of free-flight simulation (no thrust, no drag). This is a CI regression test.

**Reference:** Hairer, Nørsett & Wanner, *Solving Ordinary Differential Equations I* (2nd ed., Springer, 1993), §II.1.

---

## 3. Atmosphere Model

LOITER-SIM uses the **International Standard Atmosphere (ISA)** model.

### 3.1 Troposphere (0 – 11,000 m MSL)

```
T(h) = T_0 - L * h              [K]
p(h) = p_0 * (T(h)/T_0)^(g/(L*R))  [Pa]
ρ(h) = p(h) / (R * T(h))        [kg/m³]
a(h) = √(γ * R * T(h))          [m/s, speed of sound]
```

Constants:
- `T_0 = 288.15 K` (sea-level temperature)
- `p_0 = 101325 Pa` (sea-level pressure)
- `L = 0.0065 K/m` (lapse rate)
- `R = 287.058 J/(kg·K)` (specific gas constant, dry air)
- `g = 9.80665 m/s²` (standard gravity)
- `γ = 1.4` (ratio of specific heats, dry air)

### 3.2 Lower Stratosphere (11,000 – 20,000 m MSL)

Isothermal layer: `T = 216.65 K`, pressure decays exponentially.

### 3.3 Wind Model

Wind is modeled as a configurable steady-state vector in NED frame plus a Dryden turbulence model:

**Reference (Dryden):** MIL-HDBK-1797A, §3.6.2; MIL-F-8785C.

---

## 4. Aerodynamics

### 4.1 Aerodynamic Angles

```
α (AoA)   = atan2(w, u)         [rad] — angle of attack
β (slip)  = asin(v / V_tas)     [rad] — sideslip angle
V_tas     = √(u² + v² + w²)     [m/s] — true airspeed
M (Mach)  = V_tas / a(h)        [-]   — Mach number
```

### 4.2 Aerodynamic Coefficients

All aerodynamic coefficients are loaded from per-platform **HDF5 lookup tables** at simulation initialization.

```
C_L = C_L(α, M, δ_e)          (lift coefficient)
C_D = C_D(α, M)               (drag coefficient)
C_Y = C_Y(β, δ_r)             (side force coefficient)
C_l = C_l(α, β, δ_a, p, r)    (rolling moment)
C_m = C_m(α, M, δ_e, q)       (pitching moment)
C_n = C_n(β, δ_r, r, p)       (yawing moment)
```

Interpolation: **trilinear** for 3D tables, **bilinear** for 2D. All interpolation is monotone-aware.

### 4.3 Aerodynamic Forces and Moments

Dynamic pressure: `q_bar = 0.5 * ρ * V_tas²`

Forces in stability frame, then rotated to body frame:
```
L_aero = q_bar * S * C_L
D_aero = q_bar * S * C_D
Y_aero = q_bar * S * C_Y
```

Moments in body frame:
```
l_aero = q_bar * S * b * C_l
m_aero = q_bar * S * c_bar * C_m
n_aero = q_bar * S * b * C_n
```

Platform constants `S` (wing area), `b` (span), `c_bar` (MAC) defined in platform YAML configuration.

---

## 5. Radar Cross Section (RCS) Model

### 5.1 Detection Model

Detection is computed per (radar, target) pair using the **Radar Range Equation**:

```
P_r / P_n = (P_t * G_t * G_r * λ² * σ) / ((4π)³ * R⁴ * L * P_n)
```

Detection occurs when `SNR = P_r / P_n > SNR_threshold` (configurable in dB).

### 5.2 RCS Tables

Radar cross section `σ(θ_az, θ_el)` loaded from per-platform HDF5 tables, indexed by azimuth and elevation aspect angles relative to the target. Values in dBsm, interpolated bilinearly.

**Reference:** Knott, Shaeffer & Tuley, *Radar Cross Section* (2nd ed., SciTech Publishing, 2004), Ch. 2.

---

## 6. GPS & INS Model

### 6.1 GPS Fix Quality

GPS position error modeled as a zero-mean Gaussian with standard deviation:

```
σ_GPS = σ_0 * HDOP * DOP_scale(jamming_level)
```

Default: `σ_0 = 3.0 m` (SBAS-corrected), `HDOP = 1.2`.

### 6.2 INS Drift

Pure INS position error accumulates as a random walk:

```
σ_INS(t) = σ_INS_0 + k_drift * √t
```

Default: `σ_INS_0 = 0 m`, `k_drift = 0.01 m/√s` (representative of MEMS IMU grade).

### 6.3 GPS/INS Fusion

Kalman filter blends GPS and INS. When GPS is jammed or degraded, the filter weight shifts to INS, and position error grows.

---

## 7. Numerical Constants

All physical constants used in the simulation are centralized in `core/constants.hpp`:

```cpp
constexpr double kGravity     = 9.80665;      // m/s², WGS-84 standard
constexpr double kGasConstant = 287.058;       // J/(kg·K), dry air
constexpr double kGamma       = 1.4;           // dry air ratio of specific heats
constexpr double kT0          = 288.15;        // K, ISA sea-level temperature
constexpr double kP0          = 101325.0;      // Pa, ISA sea-level pressure
constexpr double kL           = 0.0065;        // K/m, ISA lapse rate
constexpr double kSpeedOfLight = 299792458.0;  // m/s
```

---

## 8. Validation Requirements

Each physical model must be accompanied by a validation case before being merged to `main`:

| Model | Required Validation |
|-------|-------------------|
| 6-DOF RK4 | Energy conservation < 1e-6 over 10s free flight |
| ISA atmosphere | Values match ICAO Doc 7488/3 tabulated data |
| Aerodynamics | Lift/drag polars match reference platform data |
| Radar RRE | Detection range matches analytic solution for simple geometry |
| INS/GPS fusion | RMSE bounds verified against filter theory |

---

*This document is a living specification. All changes require review by the lead architect. Physics PRs that conflict with this document without updating it will be rejected.*
