---
title: YPP RT DOCUMENTATION
---

# YAMBO YPP Real-Time Post-Processing Documentation {#ypp_rt_doc}

## Table of Contents

1. [Overview](#overview)
2. [YPP RT Capabilities Summary](#ypp-rt-capabilities-summary)
3. [Occupations and Carrier Dynamics](#occupations-and-carrier-dynamics)
4. [Response Functions and Optical Properties](#response-functions-and-optical-properties)
5. [Nonlinear Optics](#nonlinear-optics)
6. [Transient Absorption Spectroscopy](#transient-absorption-spectroscopy)
7. [Green's Functions Analysis](#greens-functions-analysis)
8. [Database Manipulation](#database-manipulation)
9. [Field Analysis](#field-analysis)
10. [Practical Examples](#practical-examples)
11. [Input Variables Reference](#input-variables-reference)

---

## Overview

**YPP** (Yambo Post-Processor) is the post-processing tool for YAMBO real-time simulations. It reads the output databases from `yambo_rt` calculations and performs various analyses including:

- **Carrier dynamics**: Occupations, lifetimes, density of states evolution
- **Optical response**: Linear and nonlinear susceptibilities, absorption spectra
- **Transient spectroscopy**: Time-resolved absorption, Kerr effect
- **Green's functions**: Two-time correlation functions, spectral functions
- **Database manipulation**: Manual carrier excitation, field analysis

YPP operates on the databases written by `yambo_rt` during the simulation, allowing you to extract physical observables without re-running expensive calculations.

---

## YPP RT Capabilities Summary

### Main RT Post-Processing Modes

| Mode | Runlevel | Description | Key Outputs |
|------|----------|-------------|-------------|
| **RT Occupations** | `ypp -y` | Carrier occupations vs time/energy/bands | `YPP-occ_*`, `YPP-carriers_*` |
| **RT Lifetimes** | `ypp -y` | Carrier lifetimes and scattering rates | `YPP-lifetime_*` |
| **RT Density** | `ypp -y` | Real-space carrier density plots | Density files |
| **RT Response (χ)** | `ypp -y` | Linear/nonlinear susceptibility | `YPP-X_probe_order_*` |
| **RT Polarization** | `ypp -y` | Polarization analysis and decomposition | `YPP-TD_P_*` |
| **NL Optics** | `ypp -n` | Nonlinear susceptibilities (χ^(n)) | `YPP-X_*_order_*` |
| **Transient Abs** | `ypp -t` | Time-resolved absorption/Kerr | `YPP-eps_along_*`, `YPP-Kerr_*` |
| **G^<(t,t')** | `ypp -y` | Two-time Green's functions | `YPP-G_lesser_*` |
| **RT DBs** | `ypp -r` | Manual carrier excitation | Modified carrier databases |
| **RT Fields** | `ypp -y` | Field analysis and chirping | `YPP-E_*` |

### Logical Flags (mod_YPP_real_time.F)

```fortran
! Main modes
l_RealTime          ! General RT post-processing
l_RT_DBs            ! Database manipulation

! What to analyze
l_RT_occupations    ! Carrier occupations
l_RT_lifetimes      ! Carrier lifetimes
l_RT_density        ! Real-space density
l_RT_G_two_times    ! G^<(t,t')
l_RT_X              ! Response functions
l_NL_X              ! Nonlinear response
l_RT_abs            ! Transient absorption
l_RT_pol            ! Polarization analysis
l_RT_ARPES          ! Time-resolved ARPES
l_RT_fields         ! Field analysis

! How to plot
l_RT_bands          ! Band structure interpolation
l_RT_time           ! Time evolution
l_RT_energy         ! Energy-resolved
l_RT_dos            ! Density of states
```

---

## Occupations and Carrier Dynamics

### Overview

Analyze carrier occupations `f_n(k,t)` and their evolution in time, energy, or band structure.

**Driver**: `RT_occupations_driver.F`

### Capabilities

#### 1. **Time Evolution** (`l_RT_time`)

Plot occupation changes vs time for selected states.

**Routine**: `RT_occ_time_plot.F`

**Outputs**:
- `YPP-occ_K*_B*_S*.dat`: Occupation vs time for each (k, band, spin)
- Includes lifetimes if scattering is present

**Key Features**:
- State selection via k-point circuits (`BANDS_path`)
- Separate electron/hole contributions (`SeparateEH`)
- Include equilibrium occupations (`IncludeEQocc`)
- Group states (`OCCgroup`)

**Input Example**:
```bash
ypp -y
RealTime
RToccupations
RTtime
BANDS_path= "G K M G"
%QPkrange
  1 | 10 | 5 | 8 |
%
```

#### 2. **Energy-Resolved** (`l_RT_energy`)

Plot occupations vs energy at different times, with Fermi function fitting.

**Routine**: `RT_components_energy_plot.F`

**Outputs**:
- `YPP-carriers_E.dat`: Occupation vs energy
- `YPP-Ef_and_T.dat`: Fitted Fermi level and temperature
- Separate files for e-e, e-ph scattering contributions

**Key Features**:
- Automatic Fermi function fitting: `f(E) = 1/(1 + exp[(E-μ)/kT])`
- Extracts effective temperature and chemical potential
- Separate electron/hole analysis
- Skip fitting with `SkipFermiFIT`

**Input Example**:
```bash
ypp -y
RealTime
RToccupations
RTenergy
%QPkrange
  1 | 10 | 1 | 10 |
%
```

#### 3. **Density of States** (`l_RT_dos`)

Time-dependent DOS with optional interpolation.

**Routine**: `RT_dos_time_plot.F`

**Outputs**:
- `YPP-TD_dos.dat`: DOS(E,t)
- `YPP-TD_INTERPOLATED_dos.dat`: Interpolated DOS (if `INTERP_grid` set)

**Key Features**:
- Gaussian/Lorentzian broadening (`DOSESteps`, `DOSERange`)
- k-space interpolation for smooth DOS
- Projected DOS on atoms (`Proj_DOS`)
- Spin-resolved DOS (spinor calculations)

**Input Example**:
```bash
ypp -y
RealTime
RToccupations
RTdos
DOSESteps= 1000
DOSERange= -5 | 10 | eV
%INTERP_Grid
 10 | 10 | 10 |
%
```

#### 4. **Band Structure Interpolation** (`l_RT_bands`)

Interpolate occupations along high-symmetry paths.

**Routine**: `RT_occ_bands_interpolation.F`

**Outputs**:
- `YPP-occ_BANDS_*`: Occupation along band structure
- Animated band structure evolution

**Key Features**:
- Uses INTERPOLATION_driver for smooth bands
- Follows time evolution of band occupations
- Useful for visualizing carrier relaxation

**Input Example**:
```bash
ypp -y
RealTime
RToccupations
RTbands
BANDS_path= "G K M G"
BANDS_steps= 100
```

### Lifetimes and Scattering Rates

When scattering is included in RT simulation, YPP extracts:

**Lifetimes**:
```
τ_n(k) = -ℏ / [2 Im Σ_n(k)]
```

**Scattering rates**:
```
Γ_n(k) = 1/τ_n(k)
```

**Outputs**:
- Separate e-e, e-ph, e-photon contributions
- Hole vs electron lifetimes
- Energy-dependent scattering rates

---

## Response Functions and Optical Properties

### Overview

Compute linear and nonlinear optical response from current/polarization.

**Driver**: `RT_X_response.F`

### Linear Response (`l_RT_X`)

Extract linear susceptibility χ^(1)(ω) from RT simulation.

**Routine**: `RT_X_LRR_real_field`

**Theory**:
```
χ^(1)(ω) = ∫ P(t) e^(iωt) dt / E(ω)
```

**Supported Field Types**:
- **DELTA/PULSE**: Broadband excitation → full χ(ω)
- **SIN/SOFTSIN**: Monochromatic → χ at specific ω
- **QSSIN**: Quasi-static → SHG analysis

**Outputs**:
- `YPP-X_probe_order_1`: Linear susceptibility
- `YPP-eps_along_*`: Dielectric function ε(ω) = 1 + 4πχ(ω)
- `YPP-alpha_along_*`: Absorption α(ω)

**Input Example (Delta Pulse)**:
```bash
ypp -y
RealTime
RTX
Xorder= 1
% Probe_Freq
 0.0 | 0.0 | eV
%
TimeRange= 0 | 100 | fs
ETStpsRt= 1001
```

**Input Example (Monochromatic)**:
```bash
ypp -y
RealTime
RTX
Xorder= 1
% Probe_Freq
 2.0 | 2.0 | eV    # Single frequency
%
```

### Polarization Analysis (`l_RT_pol`)

Decompose polarization into contributions from different transitions.

**Routine**: `RT_Polarization.F`

**Modes**:

1. **Slice mode** (`RT_pol_mode="slice"`):
   - Reads G^<(t,t') from database
   - Reconstructs P(t) from density matrix
   - Useful for checking consistency

2. **Transitions mode** (`RT_pol_mode="transitions"`):
   - Decomposes P(t) by transition energy
   - Shows which transitions contribute to each frequency

**Theory**:
```
P(t) = -e Σ_{nm,k} d_{nm}(k) ρ_{nm}(k,t)
```

where `d_{nm}(k)` are dipole matrix elements.

**Outputs**:
- `YPP-TD_P_decomposition`: P(ω) by transition energy
- Shows resonance structure

**Input Example**:
```bash
ypp -y
RealTime
RTpol
RT_pol_mode= "transitions"
% EnRngeRt
 0.0 | 10.0 | eV
%
```

### Time Configuration

All RT post-processing requires time range setup:

**Variables**:
```fortran
TimeRange    ! Time window [t_start, t_end] (fs)
DampMode     ! Damping: "NONE", "LORENTZIAN", "GAUSSIAN"
DampFactor   ! Damping strength (eV)
ETStpsRt     ! Energy steps for Fourier transform
% EnRngeRt    ! Energy range for FT (eV)
 E_min | E_max | eV
%
```

**Damping**:
- **LORENTZIAN**: `P(t) → P(t) exp(-Γt)` → Lorentzian broadening
- **GAUSSIAN**: `P(t) → P(t) exp(-Γ²t²)` → Gaussian broadening
- **NONE**: No damping (sharp features, may have artifacts)

---

## Nonlinear Optics

### Overview

Extract nonlinear susceptibilities χ^(n) from multi-frequency RT simulations.

**Driver**: `NL_ypp_driver.F`

**Runlevel**: `ypp -n`

### Theory

For monochromatic field `E(t) = E₀ cos(ωt)`:

**Polarization expansion**:
```
P(t) = χ^(1) E cos(ωt) + χ^(2) E² cos(2ωt) + χ^(3) E³ cos(3ωt) + ...
```

**Harmonic generation**:
- χ^(1): Linear response at ω
- χ^(2): Second harmonic at 2ω (SHG)
- χ^(3): Third harmonic at 3ω (THG)
- χ^(n): n-th harmonic at nω

### Workflow

1. **Run RT simulations** at different probe frequencies:
   ```bash
   # Run 1: ω₁
   yambo_rt -F input_w1.in
   
   # Run 2: ω₂
   yambo_rt -F input_w2.in
   
   # ... Run N: ωₙ
   ```

2. **Post-process with YPP**:
   ```bash
   ypp -n -F ypp_nl.in
   ```

### Capabilities

#### 1. **Frequency Scan** (`loop_on_frequencies`)

Compute χ^(n)(ω) for multiple probe frequencies.

**Input**:
```bash
ypp -n
NonLinear
Xorder= 3              # Up to χ^(3)
% Probe_Freq
 1.0 | 3.0 | 0.1 | eV  # ω from 1 to 3 eV, step 0.1 eV
%
TimeRange= 50 | 100 | fs  # Use steady-state region
```

**Outputs**:
- `YPP-X_probe_order_0`: DC component χ^(0)
- `YPP-X_probe_order_1`: Linear χ^(1)(ω)
- `YPP-X_probe_order_2`: SHG χ^(2)(2ω)
- `YPP-X_probe_order_3`: THG χ^(3)(3ω)

**Units**:
- χ^(1): Dimensionless
- χ^(n) (n≥2): [cm/statV]^(n-1)

#### 2. **Angular Scan** (`loop_on_angles`)

Compute χ^(n) for different field polarizations.

**Input**:
```bash
ypp -n
NonLinear
Xorder= 2
% Probe_Freq
 2.0 | 2.0 | eV
%
% Probe_Angles
 0 | 360 | 10 |    # Angles from 0° to 360°, step 10°
%
```

**Outputs**:
- `YPP-X_angle_order_*`: χ^(n) vs polarization angle
- Reveals anisotropy and tensor structure

#### 3. **Pump-Probe** (`N_pumps > 0`)

Separate pump and probe contributions.

**Setup**:
- Run 1: Pump + Probe
- Run 2: Pump only (reference)

**Input**:
```bash
ypp -n
NonLinear
Xorder= 1
Pump_path= "pump_only"   # Path to pump-only run
Probe_path= "pump_probe" # Path to pump+probe run
```

**Analysis**:
```
P_probe(t) = P_pump+probe(t) - P_pump(t)
```

**Outputs**:
- `YPP-pump-*`: Pump contribution
- `YPP-probe-*`: Isolated probe response
- `YPP-polarization`: Full pump+probe

### Inversion Method

For monochromatic fields, YPP uses **Fourier coefficient inversion**:

**Method**: `RT_coefficients_Inversion`

**Theory**:
```
P(t) = Σ_n P_n cos(nωt + φ_n)
```

Fit P(t) to extract {P_n, φ_n}, then:
```
χ^(n) = P_n / E₀^n
```

**Advantages**:
- Extracts all orders simultaneously
- Robust to noise
- Works for steady-state region

**Requirements**:
- Simulation must reach steady state
- Use `TimeRange` to select steady-state window
- At least one full period: `T = 2π/ω`

---

## Transient Absorption Spectroscopy

### Overview

Compute time-resolved optical properties: absorption, Kerr effect, reflectivity.

**Driver**: `RT_TRabs_driver.F` → `RT_transient_absorption`

**Runlevel**: `ypp -t` (if compiled with RT support)

### Theory

**Transient dielectric function**:
```
ε_ij(ω,t) = δ_ij + 4π Σ_trans R_i(trans,t) R_j*(trans,t) / [ω - E_trans(t) + iΓ]
```

**Transitions**:
- **cv**: Conduction-valence (equilibrium)
- **cc**: Conduction-conduction (excited carriers)
- **vv**: Valence-valence (holes)

**Observables**:
- **Absorption**: `α(ω,t) = ω Im[ε(ω,t)] / c`
- **Kerr angle**: `θ_K ∝ Im[ε_xy] / Re[ε_xx]`
- **Reflectivity**: `R(ω,t) = |(√ε - 1)/(√ε + 1)|²`

### Capabilities

#### 1. **Transient Absorption** (`TRabsWHAT="abs"`)

Time-resolved absorption spectrum.

**Input**:
```bash
ypp -t
TransAbs
TRabsWHAT= "abs"
TRabsMODE= "cv+cc+vv"   # Include all transitions
TRabsDIP_plane= "all"   # All ε_ij components
% TRabsEnRange
 0.0 | 10.0 | eV
%
TRabsEnSteps= 1000
TRabsDamp= 0.1 | eV
```

**Outputs**:
- `YPP-eps_along_E_*`: ε(ω,t) along field direction
- `YPP-alpha_along_E_*`: α(ω,t)
- Separate files for each time step

**Modes**:
- `cv`: Equilibrium transitions only
- `cc+vv`: Excited carrier contributions
- `cv+cc+vv`: Full spectrum

#### 2. **Kerr Effect** (`TRabsWHAT="kerr"`)

Time-resolved magneto-optical Kerr effect.

**Input**:
```bash
ypp -t
TransAbs
TRabsWHAT= "kerr"
TRabsDIP_plane= "xy"    # Off-diagonal component
```

**Outputs**:
- `YPP-Kerr_*`: Kerr angle vs ω and t
- `YPP-B_Hall_*`: Hall conductivity

**Theory**:
```
θ_K + i η_K = -ε_xy / [ε_xx √(ε_xx)]
```

#### 3. **BSE Transient Absorption** (`l_BS`)

Include excitonic effects in transient absorption.

**Requirements**:
- BSE databases from `yambo` calculation
- RT simulation with BSE kernel

**Input**:
```bash
ypp -t
TransAbs
TRabsMODE= "cv"         # Use BSE eigenstates
% TRabsExc
 1 | 10 |               # Excitons 1-10
%
```

**Features**:
- Uses BSE eigenstates instead of single-particle transitions
- Includes excitonic effects in ε(ω,t)
- Can compute inter-exciton transitions (`TRabsMODE="inter-exc"`)

#### 4. **Dipole Directions**

Control which ε_ij components to compute.

**Options**:
```bash
TRabsDIP_plane= "none"  # ε_xx only (default)
TRabsDIP_plane= "xy"    # ε_xx, ε_xy, ε_yx, ε_yy
TRabsDIP_plane= "xz"    # ε_xx, ε_xz, ε_zx, ε_zz
TRabsDIP_plane= "all"   # All 9 components
```

**Seed direction**:
```bash
% TRabsDIP_dir
 1.0 | 0.0 | 0.0 |      # x-direction
%
```

YPP automatically generates orthogonal directions for y and z.

### Gauge Considerations

**Velocity gauge** (default):
```
ε_ij(ω) = δ_ij - 4π Σ_trans v_i(trans) v_j*(trans) / ω²
```

**Length gauge**:
```
ε_ij(ω) = δ_ij + 4π Σ_trans r_i(trans) r_j*(trans) ω²
```

Use `TRabsVelFullExpr` to include 1/ω² term explicitly in velocity gauge.

---

## Green's Functions Analysis

### Overview

Analyze two-time lesser Green's function G^<(t,t').

**Driver**: `RT_G_two_times_driver.F`

**Runlevel**: `ypp -y` with `RTGtwotimes`

### Theory

**Lesser Green's function**:
```
G^<_{nm}(k,t,t') = i f_{nm}(k,t,t')
```

where `f_{nm}(k,t,t')` is the two-time density matrix.

**Physical meaning**:
- Diagonal (n=m): Occupation at time t
- Off-diagonal (n≠m): Coherence between states
- Time-diagonal (t=t'): Instantaneous density matrix
- Time-off-diagonal (t≠t'): Memory effects, correlations

### Capabilities

#### 1. **Build G^<(t,t')**

**Routine**: `RT_G_two_times_build.F`

Reads G^< from RT databases and prepares for analysis.

**Input**:
```bash
ypp -y
RealTime
RTGtwotimes
%QPkrange
  1 | 10 | 5 | 8 |
%
```

#### 2. **Interpolate and Plot**

**Routine**: `RT_G_two_times_interp_and_plot.F`

Interpolate G^< in k-space and plot.

**Outputs**:
- `YPP-G_lesser_K*_B*_t_tp.dat`: G^<(t,t') for each (k,band)
- 2D plots showing time-time correlations

**Applications**:
- **Dephasing analysis**: Off-diagonal decay
- **Memory effects**: How long system remembers past
- **Spectral functions**: Fourier transform to energy

#### 3. **Spectral Function**

From G^<(t,t'), compute spectral function:

**Theory**:
```
A(k,ω,t) = -2 Im ∫ G^<(k,t,t') e^(iω(t-t')) dt'
```

**Physical meaning**:
- Time-resolved band structure
- Shows how bands evolve during dynamics
- Includes broadening from scattering

**Input**:
```bash
ypp -y
RealTime
RTGtwotimes
Rho_deph= 0.1 | eV     # Additional dephasing
% GrEnRange
 -5.0 | 10.0 | eV
%
GrEnSteps= 1000
```

### Retarded Green's Function

For equilibrium or quasi-equilibrium analysis:

**Variables**:
```fortran
% Ret_GF_bands
 1 | 10 |              ! Band range
%
Gr_E_step= 0.01 | eV   ! Energy resolution
GF_T_step= 0.1  | fs   ! Time resolution
```

**Theory**:
```
G^R(ω) = 1 / [ω - E_n(k) - Σ^R(ω)]
```

---

## Database Manipulation

### Overview

Manually create carrier excitations for RT simulations.

**Driver**: `RT_DBs_carriers_setup.F`

**Runlevel**: `ypp -r`

### Purpose

Create initial non-equilibrium carrier distributions without running full RT simulation:
- Test different excitation scenarios
- Initialize pump-probe simulations
- Study specific carrier configurations

### Capabilities

#### 1. **Energy-Based Excitation** (`l_RTpump_energy`)

Excite carriers in specific energy windows.

**Input**:
```bash
ypp -r e
RTDBs
RTpumpNel= 0.1         # Electrons per unit cell
% RTpumpEhEn
 -0.5 | 0.5 | eV       # Energy window (relative to VBM/CBM)
%
RTpumpEhWd= 0.2 | eV   # Energy width (Gaussian)
RTpumpDE= 2.0 | eV     # Energy difference (e-h pairs)
```

**Method**: `RT_manual_excitation`

**Theory**:
- Select states in energy window around VBM (holes) and CBM (electrons)
- Create e-h pairs with specific energy separation
- Distribute carriers with Gaussian weight

**Use cases**:
- Resonant excitation
- Band-edge pumping
- Specific transition excitation

#### 2. **Fermi Function Excitation** (`l_RTpump_Fermi`)

Create thermal-like distributions.

**Input**:
```bash
ypp -r f
RTDBs
RTpumpNel= 0.1
% Eh_mu
 -0.2 | 0.2 | eV       # Chemical potential (holes | electrons)
%
% Eh_temp
 300 | 300 | K         # Temperature (holes | electrons)
%
h_mu_autotune_thr= 0.01  # Tolerance for Nel matching
```

**Method**: `RT_Fermi_excitation`

**Theory**:
```
f_h(E) = 1 - 1/(1 + exp[(E - μ_h)/k_B T_h])
f_e(E) = 1/(1 + exp[(E - μ_e)/k_B T_e])
```

**Features**:
- Automatic μ tuning to match target Nel
- Different T for electrons and holes
- Realistic thermalized distributions

**Use cases**:
- Hot carrier injection
- Thermal excitation
- Quasi-equilibrium initial states

#### 3. **K-Space Selection**

Restrict excitation to specific k-regions.

**Input**:
```bash
ypp -r e
RTDBs
BANDS_path= "G K"      # Use high-symmetry points
RTpumpBZWd= 0.1 | iku  # k-space width around points
% RTpumpBZReg
 0.0 | 0.0 | 0.0 |     # Additional k-points
 0.5 | 0.5 | 0.0 |
%
```

**Method**: `RT_select_k_space`

**Features**:
- Select k-points near high-symmetry points
- Define multiple k-regions
- Control k-space width

**Use cases**:
- Valley-selective excitation
- Momentum-resolved pumping
- Study k-dependent relaxation

### Output

**Database**: `ndb.RT_carriers`

Contains:
- Modified occupation factors `f_n(k,t=0)`
- Carrier density `Nel`, `Nhole`
- Scattering components (initialized to zero)

**Usage**:
```bash
# 1. Create excitation with ypp
ypp -r e -F ypp_pump.in

# 2. Use in RT simulation
yambo_rt -F rt_input.in
```

The RT simulation will start from the manually created carrier distribution.

---

## Field Analysis

### Overview

Analyze and manipulate external fields.

**Driver**: `RT_fields.F`

**Runlevel**: `ypp -y` with `RTfields`

### Capabilities

#### 1. **Field Fourier Transform**

Convert field between time and frequency domains.

**Routine**: `RT_Field_t_to_w`

**Input**:
```bash
ypp -y
RealTime
RTfields
TimeRange= 0 | 100 | fs
TimeStep= 0.01 | fs
```

**Outputs**:
- `YPP-E_time_*`: E(t) components
- `YPP-E_freq_*`: E(ω) components
- `YPP-A_time_*`: Vector potential A(t)
- `YPP-A_freq_*`: A(ω)

**Applications**:
- Verify field shape
- Check frequency content
- Analyze pulse spectrum

#### 2. **Field Chirping**

Apply frequency chirp to field.

**Input**:
```bash
ypp -y
RealTime
RTfields
ypp_chirp= 0.1 | eV/fs  # Chirp rate
```

**Routine**: `RT_1D_Fourier_Chirp`

**Theory**:
```
E_chirped(ω) = E(ω - α·t)
```

where α is the chirp rate.

**Applications**:
- Create chirped pulses
- Frequency-swept excitation
- Pump-probe with varying delay

#### 3. **Load Field from File**

Read field from external file.

**Input**:
```bash
ypp -y
RealTime
RTfields
Field(1)= "FROM_W_FILE filename"
```

**Format**: Custom frequency-domain field file

**Note**: Currently under development (`RT_Field_w_load`)

### Field Configuration

**Time setup**:
```fortran
TimeRange= t_start | t_end | fs
TimeStep= dt | fs
```

**Field definition** (from RT simulation):
```fortran
Field(1)= "DELTA"      ! Delta pulse
Field(1)= "PULSE"      ! Gaussian pulse
Field(1)= "SIN"        ! Monochromatic
Field(1)= "QSSIN"      ! Quasi-static
```

---

## Practical Examples

### Example 1: Linear Absorption from Delta Pulse

**Goal**: Compute ε(ω) and α(ω) from broadband excitation.

**Step 1**: RT simulation
```bash
# rt_input.in
negf
RT_Threads= 0
RTBands= 1 | 50 |
Integrator= "EULER"
RTstep= 0.01 | fs
NETime= 100 | fs
Field(1)= "DELTA"
Field_Freq(1)= 0.0 | eV
Field_Int(1)= 1.E-4 | kWLm2
Field_Dir(1)= 1.0 | 0.0 | 0.0 |
```

**Step 2**: YPP post-processing
```bash
# ypp_abs.in
RealTime
RTX
Xorder= 1
TimeRange= 5 | 100 | fs    # Skip initial transient
DampMode= "LORENTZIAN"
DampFactor= 0.05 | eV
% EnRngeRt
 0.0 | 10.0 | eV
%
ETStpsRt= 1000
```

**Step 3**: Run
```bash
yambo_rt -F rt_input.in
ypp -y -F ypp_abs.in
```

**Outputs**:
- `YPP-eps_along_E`: ε(ω)
- `YPP-alpha_along_E`: α(ω)

### Example 2: Second Harmonic Generation

**Goal**: Compute χ^(2) for SHG.

**Step 1**: RT simulations at different frequencies
```bash
# Loop over frequencies
for omega in 1.0 1.5 2.0 2.5 3.0; do
  mkdir run_w${omega}
  cd run_w${omega}
  
  # Create input
  cat > rt_shg.in << EOF
negf
RTBands= 1 | 50 |
RTstep= 0.05 | fs
NETime= 200 | fs
Field(1)= "SIN"
Field_Freq(1)= ${omega} | eV
Field_Int(1)= 1.E6 | kWLm2
Field_Dir(1)= 1.0 | 0.0 | 0.0 |
EOF
  
  yambo_rt -F rt_shg.in
  cd ..
done
```

**Step 2**: YPP analysis
```bash
# ypp_shg.in
NonLinear
Xorder= 2
% Probe_Freq
 1.0 | 3.0 | 0.5 | eV
%
TimeRange= 100 | 200 | fs  # Steady state
```

**Step 3**: Run
```bash
ypp -n -F ypp_shg.in
```

**Outputs**:
- `YPP-X_probe_order_1`: χ^(1)(ω)
- `YPP-X_probe_order_2`: χ^(2)(2ω)

### Example 3: Pump-Probe Transient Absorption

**Goal**: Time-resolved absorption after pump excitation.

**Step 1**: RT simulation with pump
```bash
# rt_pump.in
negf
RTBands= 1 | 50 |
RTstep= 0.05 | fs
NETime= 500 | fs

# Pump pulse
Field(1)= "PULSE"
Field_Freq(1)= 3.0 | eV
Field_Int(1)= 1.E8 | kWLm2
Field_FWHM(1)= 10 | fs
Field_Dir(1)= 1.0 | 0.0 | 0.0 |

# Include scattering
LifeInterpKIND= "FLAT"
LifeInterpSteps= 10 | fs
```

**Step 2**: YPP transient absorption
```bash
# ypp_trabs.in
TransAbs
TRabsWHAT= "abs"
TRabsMODE= "cv+cc+vv"
% TRabsEnRange
 0.0 | 8.0 | eV
%
TRabsEnSteps= 800
TRabsDamp= 0.1 | eV
```

**Step 3**: Run
```bash
yambo_rt -F rt_pump.in
ypp -t -F ypp_trabs.in
```

**Outputs**:
- `YPP-eps_along_E_T*`: ε(ω) at each time T
- `YPP-alpha_along_E_T*`: α(ω,T)

**Analysis**:
```python
import numpy as np
import matplotlib.pyplot as plt

# Load data
times = []
alphas = []
for t in range(0, 500, 10):
    data = np.loadtxt(f'YPP-alpha_along_E_T{t}.dat')
    times.append(t)
    alphas.append(data[:,1])

# Plot 2D map
plt.contourf(data[:,0], times, alphas)
plt.xlabel('Energy (eV)')
plt.ylabel('Time (fs)')
plt.title('Transient Absorption α(ω,t)')
```

### Example 4: Carrier Dynamics and Thermalization

**Goal**: Track carrier thermalization and extract effective temperature.

**Step 1**: RT simulation with scattering
```bash
# rt_therm.in
negf
RTBands= 1 | 50 |
RTstep= 0.05 | fs
NETime= 1000 | fs

# Initial excitation
Field(1)= "PULSE"
Field_Freq(1)= 4.0 | eV
Field_Int(1)= 1.E7 | kWLm2
Field_FWHM(1)= 20 | fs

# Scattering
LifeInterpKIND= "FLAT"
LifeInterpSteps= 10 | fs
```

**Step 2**: YPP carrier analysis
```bash
# ypp_carriers.in
RealTime
RToccupations
RTenergy
%QPkrange
  1 | 50 | 1 | 50 |
%
```

**Step 3**: Run
```bash
yambo_rt -F rt_therm.in
ypp -y -F ypp_carriers.in
```

**Outputs**:
- `YPP-carriers_E.dat`: f(E,t)
- `YPP-Ef_and_T.dat`: Fitted T(t) and μ(t)

**Analysis**:
```python
import numpy as np
import matplotlib.pyplot as plt

# Load fitted parameters
data = np.loadtxt('YPP-Ef_and_T.dat')
time = data[:,0]
T_e = data[:,1]   # Electron temperature
T_h = data[:,2]   # Hole temperature
mu_e = data[:,3]  # Electron chemical potential
mu_h = data[:,4]  # Hole chemical potential

# Plot thermalization
plt.figure(figsize=(10,6))
plt.subplot(2,1,1)
plt.plot(time, T_e, label='Electrons')
plt.plot(time, T_h, label='Holes')
plt.ylabel('Temperature (K)')
plt.legend()

plt.subplot(2,1,2)
plt.plot(time, mu_e, label='Electrons')
plt.plot(time, mu_h, label='Holes')
plt.xlabel('Time (fs)')
plt.ylabel('Chemical Potential (eV)')
plt.legend()
```

### Example 5: Manual Carrier Injection

**Goal**: Create specific carrier distribution for RT simulation.

**Step 1**: Create carrier database with YPP
```bash
# ypp_inject.in
RTDBs
RTpumpNel= 0.05        # 0.05 e/cell

# Energy-based excitation
% RTpumpEhEn
 -0.3 | 0.3 | eV       # ±0.3 eV around band edges
%
RTpumpEhWd= 0.15 | eV  # 0.15 eV width
RTpumpDE= 2.5 | eV     # 2.5 eV e-h separation

# K-space selection
BANDS_path= "G"        # Near Γ point
RTpumpBZWd= 0.2 | iku  # 0.2 iku radius
```

**Step 2**: Run YPP
```bash
ypp -r e -F ypp_inject.in
```

**Step 3**: Use in RT simulation
```bash
# rt_from_db.in
negf
RTBands= 1 | 50 |
RTstep= 0.05 | fs
NETime= 500 | fs

# No external field - just relaxation
# Carriers loaded from ndb.RT_carriers

LifeInterpKIND= "FLAT"
LifeInterpSteps= 10 | fs
```

**Step 4**: Run RT
```bash
yambo_rt -F rt_from_db.in
```

**Analysis**: Track how manually injected carriers relax.

---

## Input Variables Reference

### General RT Post-Processing

```fortran
! Mode selection
RealTime            ! Enable RT post-processing
RToccupations       ! Analyze occupations
RTlifetimes         ! Extract lifetimes
RTdensity           ! Real-space density
RTGtwotimes         ! G^<(t,t')
RTX                 ! Response functions
RTpol               ! Polarization analysis
RTfields            ! Field analysis

! Time configuration
TimeRange= t1 | t2 | fs        ! Time window
TimeStep= dt | fs              ! Time step (for fields)
DampMode= "LORENTZIAN"         ! Damping type
DampFactor= Γ | eV             ! Damping strength

! Energy configuration
% EnRngeRt
 E_min | E_max | eV
%
ETStpsRt= N                    ! Energy steps

! State selection
%QPkrange
 ib_min | ib_max | ik_min | ik_max |
%
BANDS_path= "G K M G"          ! High-symmetry path
```

### Occupations

```fortran
! Plot types
RTtime              ! f(t)
RTenergy            ! f(E)
RTdos               ! DOS(E,t)
RTbands             ! f along bands

! Options
IncludeEQocc        ! Add equilibrium f
SeparateEH          ! Separate e/h
NoOcc               ! Skip occupation plots
OCCgroup            ! Group states
SkipFermiFIT        ! Skip Fermi fitting
CarrEnRnge          ! Energy selection

! DOS parameters
DOSESteps= N
% DOSERange
 E_min | E_max | eV
%
DOSEBroad= σ | eV

! Interpolation
%INTERP_Grid
 n1 | n2 | n3 |
%
```

### Response Functions

```fortran
! Linear response
RTX                 ! Enable
Xorder= 1           ! Order (1 for linear)
UseFFT              ! Use FFT (faster)

! Probe configuration
% Probe_Freq
 ω_min | ω_max | dω | eV
%
N_probes= N         ! Number of probes
Probe_path(1)= "path"  ! Path to probe run

! Pump-probe
N_pumps= 1
Pump_path= "path"   ! Path to pump run

! Polarization
RTpol
RT_pol_mode= "slice"       ! or "transitions"
```

### Nonlinear Optics

```fortran
! Nonlinear response
NonLinear           ! Enable NL mode
Xorder= N           ! Max order (0 to N)

! Frequency scan
% Probe_Freq
 ω_min | ω_max | dω | eV
%

! Angular scan
% Probe_Angles
 θ_min | θ_max | dθ |
%

! Options
PrtPwrSpec          ! Print power spectrum
```

### Transient Absorption

```fortran
! Transient absorption
TransAbs            ! Enable
TRabsWHAT= "abs"    ! "abs", "kerr", "trans", "refl"
TRabsMODE= "cv"     ! "cv", "cc", "vv", "cv+cc+vv", "inter-exc"

! Energy range
% TRabsEnRange
 E_min | E_max | eV
%
TRabsEnSteps= N
TRabsDamp= Γ | eV

! Dipole configuration
TRabsDIP_plane= "xy"  ! "none", "xy", "xz", "all"
% TRabsDIP_dir
 dx | dy | dz |
%

! BSE options
% TRabsExc
 i_min | i_max |    ! Exciton range
%
% TRabs_Exc_pol
 px | py | pz |     ! Exciton polarization
%

! Options
TRabsVelFullExpr    ! Full velocity gauge expression
```

### Green's Functions

```fortran
! G^<(t,t')
RTGtwotimes         ! Enable

! Retarded GF
% Ret_GF_bands
 ib_min | ib_max |
%
Gr_E_step= dE | eV
GF_T_step= dt | fs

! Dephasing
Rho_deph= Γ | eV

! Energy range
% GrEnRange
 E_min | E_max | eV
%
GrEnSteps= N
```

### Database Manipulation

```fortran
! RT databases
RTDBs               ! Enable DB mode

! Excitation type
! Use: ypp -r e  (energy-based)
!      ypp -r f  (Fermi function)

! Energy-based
RTpumpNel= Nel      ! Electrons per cell
% RTpumpEhEn
 E_h | E_e | eV     ! Energy (holes | electrons)
%
RTpumpEhWd= σ | eV  ! Energy width
RTpumpDE= ΔE | eV   ! e-h energy difference

! Fermi-based
% Eh_mu
 μ_h | μ_e | eV     ! Chemical potential
%
% Eh_temp
 T_h | T_e | K      ! Temperature
%
h_mu_autotune_thr= tol  ! μ tuning tolerance

! K-space selection
BANDS_path= "G K"
RTpumpBZWd= w | iku
% RTpumpBZReg
 k1x | k1y | k1z |
 k2x | k2y | k2z |
%
```

### Field Analysis

```fortran
! Fields
RTfields            ! Enable

! Chirping
ypp_chirp= α | eV/fs  ! Chirp rate

! Load from file
Field(1)= "FROM_W_FILE filename"
```

### Output Control

```fortran
! General
SkipOBS_IO          ! Skip observable I/O
FrMinDamp           ! Force minimum damping

! Projection
Proj_DOS            ! Project DOS on atoms
PROJECT_mode= "ATOM"  ! "ATOM", "LINE", "PLANE"

! Normalization
NormN               ! Normalize to Nel
```

---

## Summary Table: YPP RT Capabilities

| **Analysis Type** | **Runlevel** | **Key Variables** | **Main Outputs** | **Use Cases** |
|-------------------|--------------|-------------------|------------------|---------------|
| **Occupations (time)** | `ypp -y` | `RToccupations`, `RTtime` | `YPP-occ_*.dat` | Track carrier dynamics, relaxation |
| **Occupations (energy)** | `ypp -y` | `RToccupations`, `RTenergy` | `YPP-carriers_E.dat`, `YPP-Ef_and_T.dat` | Thermalization, temperature extraction |
| **DOS evolution** | `ypp -y` | `RToccupations`, `RTdos` | `YPP-TD_dos.dat` | Time-dependent electronic structure |
| **Band structure** | `ypp -y` | `RToccupations`, `RTbands` | `YPP-occ_BANDS_*.dat` | Visualize carrier distribution |
| **Linear response** | `ypp -y` | `RTX`, `Xorder=1` | `YPP-eps_*.dat`, `YPP-alpha_*.dat` | Absorption, dielectric function |
| **Polarization** | `ypp -y` | `RTpol` | `YPP-TD_P_*.dat` | Transition analysis |
| **Nonlinear χ^(n)** | `ypp -n` | `NonLinear`, `Xorder=N` | `YPP-X_*_order_*.dat` | SHG, THG, high-harmonic generation |
| **Transient abs** | `ypp -t` | `TransAbs`, `TRabsWHAT` | `YPP-eps_*_T*.dat` | Pump-probe spectroscopy |
| **Kerr effect** | `ypp -t` | `TransAbs`, `TRabsWHAT="kerr"` | `YPP-Kerr_*.dat` | Magneto-optical response |
| **G^<(t,t')** | `ypp -y` | `RTGtwotimes` | `YPP-G_lesser_*.dat` | Correlations, spectral functions |
| **Manual pump** | `ypp -r e/f` | `RTDBs`, `RTpumpNel` | `ndb.RT_carriers` | Initialize RT simulations |
| **Field analysis** | `ypp -y` | `RTfields` | `YPP-E_*.dat` | Verify fields, chirping |

---

## Tips and Best Practices

### 1. **Time Range Selection**

**For Fourier transforms** (RTX, NonLinear):
- Skip initial transient: `TimeRange= 10 | 100 | fs`
- Use steady-state region for monochromatic fields
- Longer time → better frequency resolution: `Δω ~ 1/T`

**For occupations** (RToccupations):
- Include full dynamics: `TimeRange= 0 | T_max | fs`
- Sample at reasonable intervals

### 2. **Damping**

**LORENTZIAN** (recommended):
- Physical broadening
- Corresponds to finite lifetime
- Use `DampFactor ~ Γ_scatt`

**GAUSSIAN**:
- Smoother spectra
- Better for noisy data
- Use for inhomogeneous broadening

**NONE**:
- Only if data is very clean
- May show numerical artifacts

### 3. **Energy Resolution**

Balance resolution vs computational cost:
```
ETStpsRt= 1000      ! Good for most cases
ETStpsRt= 2000      ! High resolution
ETStpsRt= 500       ! Quick check
```

Energy range should cover all relevant features:
```
% EnRngeRt
 -2.0 | 12.0 | eV   ! Include below VBM and above CBM
%
```

### 4. **State Selection**

**For occupations**:
- Include all active bands: `QPkrange= 1 | N_bands | 1 | N_kpts |`
- Or select specific region: `BANDS_path= "G K M G"`

**For transient absorption**:
- BSE: Use exciton range `TRabsExc= 1 | 10 |`
- IP: Include enough bands for convergence

### 5. **Nonlinear Analysis**

**Frequency scan**:
- Cover resonances: `Probe_Freq= 0.5 | 5.0 | 0.1 | eV`
- Finer steps near resonances
- Ensure steady state: `TimeRange= T_transient | T_max | fs`

**Order selection**:
- Start with `Xorder= 1` (linear)
- Increase if higher harmonics visible
- `Xorder= 3` usually sufficient

### 6. **Pump-Probe**

**Setup**:
1. Run pump+probe: `yambo_rt -F input_full.in`
2. Run pump only: `yambo_rt -F input_pump.in -J pump_only`
3. Post-process: `ypp -n` with `Pump_path= "pump_only"`

**Analysis**:
- Check pump alone first
- Verify probe isolation
- Look for pump-induced changes

### 7. **Memory Management**

**Large systems**:
- Use `SkipOBS_IO` to reduce I/O
- Select specific k-points/bands
- Process time slices separately

**Interpolation**:
- Use `INTERP_Grid` for smooth DOS
- Balance accuracy vs cost
- Check convergence

### 8. **Troubleshooting**

**Problem**: Noisy spectra
- **Solution**: Increase `DampFactor`, use longer `TimeRange`

**Problem**: Missing features
- **Solution**: Check `EnRngeRt`, increase `ETStpsRt`

**Problem**: Unphysical results
- **Solution**: Verify RT simulation converged, check gauge consistency

**Problem**: Slow post-processing
- **Solution**: Reduce `ETStpsRt`, use `UseFFT`, select fewer states

---

## Code Structure Reference

### Main Drivers

```
ypp/real_time/
├── RT_ypp_driver.F              # Main RT post-processing driver
├── NL_ypp_driver.F              # Nonlinear optics driver
├── RT_occupations_driver.F      # Occupations analysis driver
├── RT_TRabs_driver.F            # Transient absorption driver
└── RT_G_two_times_driver.F      # Green's function driver
```

### Analysis Routines

```
ypp/real_time/
├── RT_occ_time_plot.F           # f(t) plots
├── RT_components_energy_plot.F  # f(E) and Fermi fitting
├── RT_dos_time_plot.F           # DOS(E,t)
├── RT_occ_bands_interpolation.F # Band structure
├── RT_X_response.F              # Linear response
├── RT_Polarization.F            # Polarization analysis
├── RT_X_effective.F             # Effective susceptibility
├── RT_transient_absorption.F    # Transient spectra
├── RT_G_two_times_build.F       # Build G^<(t,t')
└── RT_fields.F                  # Field analysis
```

### Database Manipulation

```
ypp/real_time/
├── RT_DBs_carriers_setup.F      # Main DB setup
├── RT_manual_excitation.F       # Energy-based excitation
└── RT_Fermi_excitation.F        # Fermi function excitation
```

### Utilities

```
ypp/real_time/
├── RT_1D_Fourier_setup.F        # Fourier transform setup
├── RT_coefficients_Fourier.F    # FT of observables
├── RT_damp_it.F                 # Apply damping
├── RT_OBSERVABLES_IO.F          # Read observables
├── RT_OBSERVABLES_damp_and_write.F  # Process and write
└── RT_time_configuration_setup.F    # Time grid setup
```

### Module

```
ypp/YPPmodules/mod_YPP_real_time.F  # RT variables and types
```

---

## References

### YAMBO Documentation
- Main manual: https://www.yambo-code.eu/wiki/
- RT tutorial: https://www.yambo-code.eu/wiki/index.php/Real_time_approach_to_linear_response
- NL tutorial: https://www.yambo-code.eu/wiki/index.php/Nonlinear_optics

### Key Papers
1. **RT-TDDFT in YAMBO**: Sangalli et al., J. Chem. Phys. 134, 034115 (2011)
2. **Nonlinear optics**: Attaccalite et al., Phys. Rev. B 88, 235113 (2013)
3. **Transient absorption**: Grüning & Attaccalite, Phys. Rev. B 89, 081102(R) (2014)
4. **Pump-probe**: Marini & Attaccalite, Phys. Rev. Lett. 120, 107401 (2018)

### Related Tools
- **yambo_rt**: Real-time propagation
- **yambo**: Ground-state and BSE calculations
- **ypp**: General post-processing (bands, DOS, etc.)

---

## Appendix: Quick Command Reference

### Basic Usage

```bash
# Linear absorption
ypp -y -F ypp_abs.in

# Nonlinear optics
ypp -n -F ypp_nl.in

# Transient absorption
ypp -t -F ypp_trabs.in

# Manual carrier injection
ypp -r e -F ypp_pump.in  # Energy-based
ypp -r f -F ypp_pump.in  # Fermi function
```

### Input File Templates

**Linear absorption**:
```
RealTime
RTX
Xorder= 1
TimeRange= 5 | 100 | fs
DampMode= "LORENTZIAN"
DampFactor= 0.05 | eV
% EnRngeRt
 0.0 | 10.0 | eV
%
ETStpsRt= 1000
```

**Carrier dynamics**:
```
RealTime
RToccupations
RTtime
RTenergy
%QPkrange
  1 | 50 | 1 | 50 |
%
BANDS_path= "G K M G"
```

**Second harmonic**:
```
NonLinear
Xorder= 2
% Probe_Freq
 1.0 | 3.0 | 0.2 | eV
%
TimeRange= 100 | 200 | fs
```

**Transient absorption**:
```
TransAbs
TRabsWHAT= "abs"
TRabsMODE= "cv+cc+vv"
% TRabsEnRange
 0.0 | 8.0 | eV
%
TRabsEnSteps= 800
TRabsDamp= 0.1 | eV
TRabsDIP_plane= "all"
```

---

**Document Version**: 1.0  
**Last Updated**: 2025  
**YAMBO Version**: 5.x  
**Author**: Generated from YAMBO source code analysis

For questions and support, visit: https://www.yambo-code.eu