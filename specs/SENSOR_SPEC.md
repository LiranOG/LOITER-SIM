# LOITER-SIM Sensor Specification

**Document version:** 0.1-draft  
**Status:** Design phase  
**Scope:** Defines all sensor models, their physical basis, parameters, and validation requirements.

---

## 1. Design Philosophy

Sensors in LOITER-SIM are not abstract "detection oracles." They are physics-based models of specific sensor phenomenology. An agent does not know whether another agent is within range — it knows what its radar returns, what its EO/IR sensor sees, and what its INS/GPS reports. The gap between ground truth and sensor output is where the interesting AI problems live.

All sensor models satisfy:
- **Physics citation:** Every model traces to peer-reviewed literature or a recognized technical standard
- **Configurable fidelity:** Fidelity parameters (RCS table resolution, INS drift rate, radar noise floor) are set per-platform in YAML, not hardcoded
- **Deterministic output:** All stochastic elements are driven by the simulation's seeded PRNG

---

## 2. Radar Detection Model

### 2.1 Physical Basis

Detection is governed by the **Radar Range Equation**:

```
SNR = (P_t · G_t · G_r · λ² · σ) / ((4π)³ · R⁴ · L · k · T₀ · B · F)
```

Where:
| Symbol | Meaning | Unit |
|--------|---------|------|
| P_t | Transmit power | W |
| G_t | Transmit antenna gain | linear |
| G_r | Receive antenna gain | linear |
| λ | Wavelength (= c/f) | m |
| σ | Target RCS | m² |
| R | Slant range | m |
| L | System losses | linear |
| k | Boltzmann constant = 1.38 × 10⁻²³ | J/K |
| T₀ | System noise temperature | K |
| B | Receiver bandwidth | Hz |
| F | Noise figure | linear |

**Reference:** Richards, Scheer & Holm, *Principles of Modern Radar Vol. I* (SciTech, 2010), Ch. 2.

Detection occurs when `SNR > SNR_min`, where `SNR_min` is the configurable detection threshold (default: 13 dB).

### 2.2 Radar Cross Section (RCS)

RCS is a function of the target platform, the radar frequency, and the aspect angle:

```
σ = σ(θ_az, θ_el, f)  [m², or dBsm]
```

Each platform has an associated RCS table stored as a 3D HDF5 dataset:
- Dimensions: azimuth angle × elevation angle × frequency band
- Resolution: ≥ 5° angular resolution, ≥ 1 frequency band
- Values: stored in dBsm, interpolated bilinearly at runtime

**Reference:** Knott, Shaeffer & Tuley, *Radar Cross Section* (2nd ed., SciTech, 2004), Ch. 2–4.

### 2.3 Clutter and Noise

**Thermal noise:** modeled as additive white Gaussian noise with power `kT₀BF`.

**Ground clutter:** for ground-based radars, a simple σ₀ model (constant normalized RCS per unit area) is used for terrain below the radar line-of-sight. Urban clutter is not modeled in v1.0.

**Rain clutter:** configurable attenuation (dB/km) applied to the two-way path based on precipitation rate from the scenario weather model.

### 2.4 Platform Parameters (YAML)

```yaml
radar:
  type: ground_search       # ground_search | airborne_fcr | airborne_ew
  peak_power_w: 50000
  frequency_ghz: 9.5        # X-band
  antenna_gain_dbi: 34.0
  noise_figure_db: 4.0
  bandwidth_mhz: 5.0
  losses_db: 3.0
  snr_threshold_db: 13.0
  scan_rate_deg_s: 60.0     # For scanning radars; 0 = fixed beam
  scan_sector_deg: 360.0
```

---

## 3. Electro-Optical / Infrared (EO/IR) Sensor

### 3.1 Detection Model

EO/IR detection uses **field-of-view raycasting** combined with an irradiance threshold model.

Detection of target T by sensor S occurs when:
1. T falls within S's field of view (conical frustum, configurable half-angle)
2. The line-of-sight ray from S to T is unobstructed by terrain (raycasted against AMR terrain geometry)
3. The target irradiance at S exceeds the minimum detectable irradiance (MDI)

### 3.2 Irradiance Model

The irradiance (power per unit area) at the sensor from the target:

```
E = I_t / R²   [W/m² · sr⁻¹ → W/m² after solid angle integration]
```

Where `I_t` is the target's thermal radiant intensity [W/sr], dependent on:
- Engine exhaust temperature and nozzle area
- Aerodynamic heating (significant above Mach 0.8): `T_aero = T_ambient · (1 + 0.2 · M²)` (stagnation temperature)
- IR signature suppression factor (platform-configurable)

**Reference:** Lloyd, *Thermal Imaging Systems* (Plenum Press, 1975), Ch. 3.

Atmospheric transmission uses a simplified Beer-Lambert model:

```
τ(R) = exp(-α · R)
```

Where `α` is the atmospheric extinction coefficient [km⁻¹], configurable by scenario (clear air default: α = 0.01 km⁻¹ at 4–5 μm MWIR band).

### 3.3 Sensor Parameters (YAML)

```yaml
eo_ir:
  band: MWIR                # SWIR | MWIR | LWIR
  fov_half_angle_deg: 15.0
  minimum_detectable_irradiance_w_m2: 1.0e-7
  integration_time_ms: 16.7  # 60 Hz frame rate
  false_alarm_rate: 1.0e-6   # Per pixel per frame
```

---

## 4. Inertial Navigation System (INS)

### 4.1 Error Model

The INS position error model follows a random walk in position with drift rate `k_drift`:

```
σ_pos(t) = σ_0 + k_drift · √t   [m]
```

The velocity error follows:

```
σ_vel(t) = σ_v0 + k_v · t       [m/s]
```

The attitude error follows a random walk in angular space with rate `k_att`:

```
σ_att(t) = σ_att0 + k_att · t   [deg]
```

Error state is propagated each tick using the configured drift rates. The INS error vector is drawn from the PRNG at initialization (seeded deterministically) and propagated forward, ensuring reproducibility.

**Reference:** Titterton & Weston, *Strapdown Inertial Navigation Technology* (2nd ed., IET, 2004), Ch. 11–12.

### 4.2 IMU Grade Classes

| Grade | k_drift [m/√hr] | k_att [deg/hr] | Typical Platform |
|-------|----------------|----------------|-----------------|
| Navigation | 0.01 | 0.001 | Military aircraft, guided munitions |
| Tactical | 0.1 | 0.01 | Smart munitions, UAS |
| Commercial | 1.0 | 0.1 | Commercial drones |
| MEMS | 10.0 | 1.0 | Low-cost consumer drones |

### 4.3 GPS/INS Fusion

A discrete Kalman filter fuses GPS and INS. When GPS is available:
- Measurement update uses GPS position as observation
- Position error is bounded by GPS accuracy

When GPS is degraded or jammed:
- Filter propagates with INS-only prediction
- Position error grows at the INS drift rate

---

## 5. GPS Model

### 5.1 Nominal GPS Accuracy

```
σ_GPS = σ_0 · HDOP · DOP_scale(jamming_SNR)
```

Default parameters:
- `σ_0 = 2.0 m` (1-sigma, horizontal, SBAS-corrected C/A code)
- `HDOP = 1.2` (scenario-configurable)

GPS position sample drawn each tick from the PRNG with the above standard deviation.

### 5.2 Jamming Model

Jamming elevates the effective noise floor of the GPS receiver. The jam-to-signal ratio (J/S) in dB is computed from the jammer parameters and geometry:

```
J/S = EIRP_jammer - FSPL(R_jammer) - G_antenna(θ) - GPS_receiver_gain
```

The DOP scale factor as a function of J/S:

| J/S [dB] | Effect |
|---------|--------|
| < 0 | No effect |
| 0–20 | Degraded accuracy (σ scales by 2–10×) |
| 20–40 | Fix quality degrades (HDOP increases) |
| > 40 | Fix lost, INS-only navigation |

**Reference:** Kaplan & Hegarty, *Understanding GPS/GNSS* (3rd ed., Artech House, 2017), Ch. 7.

### 5.3 Spoofing Model

GPS spoofing injects a false position signal. The spoofer has:
- `spoof_position_m`: the false position injected
- `spoof_power_w`: transmit power (must exceed authentic signal power at receiver)
- `spoof_range_m`: maximum effective range

When an agent is within spoof range and the spoofer's J/S is sufficient to capture the receiver:
- The agent's reported GPS position is shifted toward the spoofed position
- The receiver's lock-on detection (signal quality metrics) may not flag the attack (configurable by platform sophistication level)

---

## 6. Electronic Warfare Subsystem

### 6.1 Radar Jammer

Active radar jamming elevates the noise floor of the target radar:

```
J/S_radar = EIRP_jammer - FSPL(R) - target_radar_antenna_gain(θ)
```

Effect on radar detection: the effective `SNR_min` of the jammed radar is reduced by J/S (i.e., the jamming power adds to the receiver's noise). Detection range is reduced.

### 6.2 DRFM Jammer (Digital Radio Frequency Memory)

A DRFM jammer records the incoming radar pulse, adds a time delay Δτ (creating a false range), optionally modifies the Doppler shift, and retransmits. This creates a false target at range:

```
R_false = R_true + c · Δτ / 2   [m]
```

The DRFM model generates a ghost contact in the target radar's detection output at `R_false`. The strength of the ghost is configurable (default: matched to true target RCS).

**Reference:** Adamy, *EW 102: A Second Course in Electronic Warfare* (Artech House, 2004), Ch. 5.

### 6.3 Communications Jamming

Communications jamming suppresses inter-agent and C2 communication links. A noise jammer within the communication frequency band of the target link elevates the bit error rate (BER):

```
BER(Eb/N0) = 0.5 · erfc(√(Eb/N0))   [BPSK modulation]
```

Above a threshold BER (~10⁻²), the link is considered unusable and packet loss probability is set to 1.0.

---

## 7. Sensor Data Representation in ECS

Sensor outputs are stored as ECS components, available for agent policy systems each tick:

```cpp
struct RadarDetection {
    EntityId  target_id;       // Ground-truth ID (for bookkeeping)
    Vec3      range_doppler;   // [range_m, azimuth_deg, elevation_deg]
    double    snr_db;
    bool      is_ghost;        // DRFM-generated false target
};

struct EoIrDetection {
    EntityId  target_id;
    Vec3      line_of_sight;   // Unit vector in body frame
    double    irradiance_w_m2;
    double    angular_size_mrad;
};

struct NavSolution {
    Vec3    position_m;        // NED, INS/GPS fused
    Vec3    velocity_m_s;      // NED, INS
    Quat    attitude;          // Body-to-NED
    double  position_sigma_m;  // 1-sigma position uncertainty
    bool    gps_fix;           // True if GPS contributing to solution
    bool    gps_spoofed;       // True if spoofing detected (platform-dependent)
};
```

---

## 8. Validation Requirements

| Sensor | Validation Case | Pass Criterion |
|--------|----------------|----------------|
| Radar | Single target at known range and RCS | Detected at ≤ theoretical max range; not detected 2× beyond |
| Radar jamming | Jammer at known J/S | Detection range reduction matches analytic prediction |
| EO/IR | Target at known temperature and range | Detection at ≤ theoretical NEID range |
| INS | Free-INS propagation over 10 minutes | Position error within 2σ of drift model |
| GPS jamming | Jammer at known J/S | Fix degradation matches J/S table |
| DRFM | Known delay Δτ | Ghost at correct false range |

All validation tests must be part of the test suite and pass in CI.

---

*This specification is subject to revision. All changes require an update to this document and a corresponding physics review.*
