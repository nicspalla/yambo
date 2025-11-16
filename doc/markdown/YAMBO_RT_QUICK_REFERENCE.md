# YAMBO Real-Time Quick Reference {#yambo_rt_quick_ref}

@page yambo_rt_quick_ref YAMBO Real-Time Quick Reference

**Fast lookup guide for RT formulas, variables, and common tasks**

@tableofcontents

---

## Core Equation

```
i∂G^<(t)/∂t = [H^RT(t), G^<(t)] + Σ^scatt(t)
```

**Components:**
- `G^<(t)`: Lesser Green's function (density matrix)
- `H^RT(t)`: Time-dependent Hamiltonian
- `Σ^scatt(t)`: Collision self-energy

---

## Key Formulas

### Density Matrix

```
G^<_{nm}(k,t) = i f_{nm}(k,t)
```

**Diagonal:** `f_{nn}(k,t)` = occupation of state n  
**Off-diagonal:** `f_{nm}(k,t)` = coherence between states n and m

### Hamiltonian Decomposition

```
H^RT(t) = H^EQ + ΔΣ^Hxc[G(t)] + H^ext(t)
```

**Equilibrium:**
```
H^EQ_{nm}(k) = δ_{nm} E_n(k)
```

**Mean-field correction:**
```
ΔΣ^Hxc = Σ^Hxc[G(t)] - Σ^Hxc[G_ref]
```

**External field (velocity gauge):**
```
H^ext = A(t)·p/m - A²(t)/2m
```

**External field (length gauge):**
```
H^ext = E(t)·r
```

### Time Evolution

**Formal solution:**
```
G^<(t+Δt) = U(Δt) G^<(t) U†(Δt)
```

where `U(Δt) = exp(-iH^RT Δt)`

---

## Time Integrators

### Euler (1st order)

```
G^<(t+Δt) = G^<(t) - iΔt[H, G^<]
```

**Pros:** Simple, fast  
**Cons:** Small time steps, no unitarity  
**Typical Δt:** 0.01 fs

### Exponential (Magnus)

```
G^<(t+Δt) = Σ_{n=0}^N (-iΔt)^n/n! [H,[H,...[H,G^<]...]]
```

**Pros:** Higher order, preserves unitarity  
**Cons:** Multiple commutators  
**Typical Δt:** 0.05 fs

### Inverse (Crank-Nicolson)

```
(1+iHΔt/2)G^<(t+Δt) + G^<(t+Δt)(1-iHΔt/2) = 2G^<(t) - iΔt[H,G^<]
```

**Pros:** Unconditionally stable, exact unitarity  
**Cons:** Matrix inversion  
**Typical Δt:** 0.1 fs

### Multi-Step Methods

**RK2:**
```
k_1 = -i[H[G], G]
k_2 = -i[H[G + k_1Δt/2], G + k_1Δt/2]
G(t+Δt) = G(t) + Δt(k_1 + k_2)/2
```

**RK4:**
```
k_1 = -i[H[G], G]
k_2 = -i[H[G + k_1Δt/2], G + k_1Δt/2]
k_3 = -i[H[G + k_2Δt/2], G + k_2Δt/2]
k_4 = -i[H[G + k_3Δt], G + k_3Δt]
G(t+Δt) = G(t) + Δt(k_1 + 2k_2 + 2k_3 + k_4)/6
```

---

## Gauge Choices

### Velocity Gauge

**Hamiltonian:**
```
H^ext = A(t)·p/m - A²(t)/2m
```

**Matrix elements:**
```
H^ext_{nm} = A·p_{nm}/m - δ_{nm}A²/2m
```

**Relation:** `E(t) = -∂A/∂t`

**Use when:**
- Periodic systems
- Plane-wave basis
- Strong fields

### Length Gauge

**Hamiltonian:**
```
H^ext = E(t)·r
```

**Matrix elements:**
```
H^ext_{nm} = E·r_{nm}
```

**Relation:** `r_{nm} = i p_{nm}/(E_n - E_m)` (n≠m)

**Use when:**
- Molecules
- Weak fields
- Long wavelengths

---

## Physical Observables

### Current

```
J(t) = -e Σ_{n,k} f_n(k,t) v_n(k)
```

**With coherences:**
```
J(t) = -e Σ_{n,m,k} f_{nm}(k,t) v_{nm}(k)
```

**Velocity gauge:**
```
J(t) = -e Σ_{n,m,k} f_{nm}(k,t) [p_{nm}/m - δ_{nm}A(t)]
```

### Polarization

```
P(t) = ∫_0^t J(t') dt'
```

or

```
P(t) = -e Σ_{n,k} f_n(k,t) r_n(k)
```

### Energy

**Total:**
```
E_tot = E_kin + E_H + E_xc + E_ext
```

**Kinetic:**
```
E_kin = Σ_{n,k} f_n(k,t) E_n(k)
```

**Hartree:**
```
E_H = (1/2) ∫∫ ρ(r)ρ(r')/|r-r'| dr dr'
```

**External:**
```
E_ext = -P·E
```

### Carrier Populations

**Electrons:**
```
n_e = Σ_{n∈CB,k} f_n(k,t)
```

**Holes:**
```
n_h = Σ_{n∈VB,k} [1 - f_n(k,t)]
```

### Entropy

```
S = -k_B Σ_{n,k} [f_n ln f_n + (1-f_n) ln(1-f_n)]
```

---

## Approximations

### Independent Particle (IP)

```
H^RT = H^EQ + H^ext
```

**No mean-field corrections**

### Time-Dependent Hartree

```
ΔΣ^H_{nm} = ⟨n|V^H[ρ(t)] - V^H[ρ_ref]|m⟩
```

**Hartree potential:**
```
V^H(r,t) = ∫ ρ(r',t)/|r-r'| dr'
```

### TDDFT (LDA/GGA)

```
ΔΣ^Hxc_{nm} = ⟨n|V^H[ρ(t)] + V^xc[ρ(t)] - V^H[ρ_ref] - V^xc[ρ_ref]|m⟩
```

**XC potential:**
```
V^xc(r,t) = δE^xc[ρ]/δρ(r,t)
```

### TDSEX

```
Σ^SEX_{nm}(k,t) = -Σ_{k',m'} W_{nm,m'm'}(k,k') f_{m'}(k',t)
```

**Screened interaction:** `W = ε^{-1}v`

### TDCOHSEX

```
Σ^COHSEX = Σ^COH + Σ^SEX
```

**COH:**
```
Σ^COH_{nm} = (1/2) Σ_{k',m'} [W_{nm,m'm'} - v_{nm,m'm'}]
```

---

## Scattering Terms

### Relaxation Time Approximation

**Electron-electron:**
```
Σ^{el-el}_{nn} = -[f_n(k,t) - f^eq_n(k)]/τ_{el-el}
```

**Electron-phonon:**
```
Σ^{el-ph}_{nn} = -[f_n(k,t) - f^eq_n(k)]/τ_{el-ph}
```

**Dephasing:**
```
Σ^{deph}_{nm} = -f_{nm}(k,t)/T_2  (n≠m)
```

---

## Variable Reference

### Core Variables

| Variable | Type | Dimensions | Description |
|----------|------|------------|-------------|
| `G_lesser` | complex(SP) | (nb,nb,nk,nsp,nmem) | Density matrix |
| `Ho_plus_Sigma` | complex(SP) | (nb,nb,nk,nsp) | RT Hamiltonian |
| `H_EQ` | complex(SP) | (nb,nb,nk,nsp) | Equilibrium H |
| `dG_lesser` | complex(SP) | (nb,nb,nk,nsp,nmem) | Density variation |
| `A_tot` | type(gauge_field) | - | Vector potential |
| `RT_step` | real(SP) | - | Time step (fs) |
| `NE_time` | real(SP) | - | Current time (fs) |
| `NE_tot_time` | real(SP) | - | Total time (fs) |

### Observables

| Variable | Type | Dimensions | Description |
|----------|------|------------|-------------|
| `J_tot` | real(SP) | (3,nt) | Current (e·a.u./fs) |
| `P_tot` | real(SP) | (3,nt) | Polarization (e·a.u.) |
| `E_tot` | real(SP) | (nt) | Total energy (Ha) |
| `E_kin` | real(SP) | (nt) | Kinetic energy (Ha) |
| `entropy` | real(SP) | (nt) | Entropy (k_B) |

### Control Flags

| Flag | Type | Description |
|------|------|-------------|
| `l_NE_dynamics` | logical | Enable RT dynamics |
| `l_NE_with_fields` | logical | Include external fields |
| `eval_HARTREE` | logical | Compute Hartree term |
| `eval_DFT` | logical | Compute XC term |
| `l_RT_RWA` | logical | Rotating wave approx |
| `l_velocity_gauge_corr` | logical | Velocity gauge correction |

---

## File Locations

### Main Routines

| Routine | File | Purpose |
|---------|------|---------|
| `RT_driver` | `src/real_time_drivers/RT_driver.F` | Main driver |
| `RT_Hamiltonian` | `src/real_time_hamiltonian/RT_Hamiltonian.F` | Build H^RT |
| `RT_Integrator` | `src/real_time_propagation/RT_Integrator.F` | Time integration |
| `RT_EULER_step` | `src/real_time_propagation/RT_EULER_step.F` | Euler integrator |
| `RT_EXP_step_std` | `src/real_time_propagation/RT_EXP_step_std.F` | Exponential integrator |
| `RT_INV_step_std` | `src/real_time_propagation/RT_INV_step_std.F` | Inverse integrator |
| `RT_apply_field` | `src/real_time_hamiltonian/RT_apply_field.F` | Add external field |
| `RT_Observables` | `src/real_time_control/RT_Observables.F` | Compute observables |

### Initialization

| Routine | File | Purpose |
|---------|------|---------|
| `RT_initialize` | `src/real_time_initialize/RT_initialize.F` | Setup |
| `RT_G_lesser_init` | `src/real_time_initialize/RT_G_lesser_init.F` | Initial G^< |
| `RT_start_and_restart` | `src/real_time_initialize/RT_start_and_restart.F` | Start/restart |

### Modules

| Module | File | Contents |
|--------|------|----------|
| `real_time` | `src/modules/mod_real_time.F` | RT variables |
| `RT_lifetimes` | `src/modules/mod_RT_lifetimes.F` | Lifetimes |
| `RT_occupations` | `src/modules/mod_RT_occupations.F` | Occupations |
| `fields` | `src/modules/mod_fields.F` | External fields |

---

## Common Tasks

### 1. Linear Response (Weak Field)

**Setup:**
```
Integrator: EULER or EXP
Time step: 0.01-0.05 fs
Field: E_0 ~ 10^-4 a.u., Gaussian pulse
Approximation: TDDFT-LDA
```

**Extract:**
- Polarization P(t)
- Fourier transform → χ(ω)
- Absorption: α(ω) = Im[χ(ω)]

### 2. Pump-Probe Spectroscopy

**Setup:**
```
Integrator: EXP or INV
Time step: 0.05-0.1 fs
Pump: Strong pulse (E_0 ~ 10^-3 a.u.)
Probe: Weak pulse, delayed
Approximation: TDDFT or TDSEX
```

**Extract:**
- Transient absorption ΔA(ω,τ)
- Carrier populations n_e(t), n_h(t)
- Relaxation times τ_relax

### 3. High-Harmonic Generation

**Setup:**
```
Integrator: EXP or INV
Time step: 0.001-0.01 fs
Field: Very strong (E_0 ~ 10^-2 a.u.), few-cycle
Approximation: TDDFT or IP
Gauge: Velocity (better for strong fields)
```

**Extract:**
- Current J(t)
- Fourier transform → HHG spectrum
- Cutoff: E_cutoff = I_p + 3.17U_p

### 4. Carrier Dynamics

**Setup:**
```
Integrator: INV (for long times)
Time step: 0.1-1 fs
Scattering: el-el, el-ph
Approximation: TDDFT + scattering
```

**Extract:**
- Carrier populations n_e(t), n_h(t)
- Carrier temperatures T_e(t), T_h(t)
- Thermalization time τ_therm

---

## Typical Parameters

### Time Steps by Integrator

| Integrator | Typical Δt | Max Δt | Stability |
|------------|------------|--------|-----------|
| EULER | 0.01 fs | 0.02 fs | Conditional |
| RK2 | 0.02 fs | 0.05 fs | Conditional |
| RK4 | 0.05 fs | 0.1 fs | Conditional |
| EXP | 0.05 fs | 0.2 fs | Good |
| INV | 0.1 fs | 1 fs | Unconditional |

### Field Strengths

| Regime | E_0 (a.u.) | E_0 (V/m) | Process |
|--------|------------|-----------|---------|
| Linear | 10^-5 - 10^-4 | 10^6 - 10^7 | Linear response |
| Weak non-linear | 10^-4 - 10^-3 | 10^7 - 10^8 | SHG, THG |
| Strong | 10^-3 - 10^-2 | 10^8 - 10^9 | Carrier excitation |
| Very strong | 10^-2 - 10^-1 | 10^9 - 10^10 | HHG, ionization |

**Conversion:** 1 a.u. = 5.14 × 10^11 V/m

### Simulation Times

| System | Process | Typical Time |
|--------|---------|--------------|
| Bulk semiconductors | Linear response | 10-50 fs |
| 2D materials | Exciton dynamics | 50-100 fs |
| Molecules | Electronic dynamics | 1-10 fs |
| Carrier thermalization | Relaxation | 100-1000 fs |
| HHG | Attosecond physics | 1-5 fs |

---

## Convergence Parameters

### k-point Sampling

| System | k-grid | Notes |
|--------|--------|-------|
| Bulk Si | 8×8×8 | Minimum for optical |
| 2D MoS₂ | 12×12×1 | Denser for 2D |
| Molecules | Γ-point | Single k-point |

### Band Range

```
RT_bands = [VB_top - 5, CB_bottom + 5]
```

**Typical:** 10-20 bands around gap

### Memory Steps

```
G_MEM_steps = 3-10
```

**Minimum:** 3 (for RK4)  
**Typical:** 5-10 (for memory integrals)

---

## Troubleshooting

### Problem: Simulation Crashes

**Possible causes:**
1. Time step too large → Reduce Δt
2. Field too strong → Reduce E_0 or use INV integrator
3. Memory overflow → Reduce G_MEM_steps or band range

### Problem: Unphysical Results

**Check:**
1. Unitarity: Tr[G^<] should be conserved
2. Energy conservation (for IP)
3. Gauge consistency
4. Convergence in k-points and bands

### Problem: Slow Convergence

**Solutions:**
1. Use adaptive time-stepping
2. Switch to INV integrator for stiff problems
3. Enable RWA for near-resonant excitation
4. Reduce band range if possible

---

## Quick Start Example

**Input file (yambo_rt.in):**
```
negf                           # RT dynamics
% RTBands
  10 | 20 |                    # Band range
%
RTstep= 0.05          fs       # Time step
NETime= 50.           fs       # Total time
Integrator= "EXP"              # Exponential integrator
% Field1_Freq
  2.0 | 2.0 | eV               # Field frequency
%
Field1_Int= 1.E-4     kWLm2    # Field intensity
Field1_Width= 10.     fs       # Pulse width
Field1_kind= "GAUSSIAN"        # Pulse shape
Field1_pol= "linear"           # Polarization
% Field1_Dir
  1.0 | 0.0 | 0.0 |            # Field direction
%
```

**Run:**
```bash
yambo_rt -F yambo_rt.in -J RT_run
```

**Output:**
- `o-RT_run.YPP-RT_current`: Current J(t)
- `o-RT_run.YPP-RT_energy`: Energy components
- `o-RT_run.YPP-RT_occupations`: Carrier populations

---

## Units and Conversions

| Quantity | Atomic Units | SI | Conversion |
|----------|--------------|-----|------------|
| Time | a.u. | fs | 1 a.u. = 0.02419 fs |
| Energy | Ha | eV | 1 Ha = 27.211 eV |
| Electric field | a.u. | V/m | 1 a.u. = 5.14×10^11 V/m |
| Current | e/a.u. | A | 1 e/a.u. = 6.62×10^-3 A |
| Polarization | e·a.u. | C·m | 1 e·a.u. = 8.48×10^-30 C·m |
| Intensity | a.u. | W/cm² | 1 a.u. = 3.51×10^16 W/cm² |

---