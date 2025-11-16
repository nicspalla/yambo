# YAMBO Real-Time Theory Documentation {#yambo_rt_theory_doc}

@page yambo_rt_theory_doc YAMBO Real-Time Theory Documentation

**Comprehensive theoretical reference for YAMBO's real-time dynamics module**

@tableofcontents

---

## Table of Contents

1. [Introduction](#1-introduction)
2. [Theoretical Framework](#2-theoretical-framework)
3. [Kadanoff-Baym Equations](#3-kadanoff-baym-equations)
4. [Time-Dependent Hamiltonian](#4-time-dependent-hamiltonian)
5. [Time Integration Methods](#5-time-integration-methods)
6. [External Fields and Gauge Choices](#6-external-fields-and-gauge-choices)
7. [Scattering Mechanisms](#7-scattering-mechanisms)
8. [Physical Observables](#8-physical-observables)
9. [Approximations and Functionals](#9-approximations-and-functionals)
10. [Implementation Details](#10-implementation-details)
11. [References](#11-references)

---

## 1. Introduction

The YAMBO real-time (RT) module implements **non-equilibrium many-body dynamics** by solving the **Kadanoff-Baym equations** (KBE) for the time-dependent density matrix. This allows simulation of:

- **Ultrafast optical spectroscopy** (pump-probe, transient absorption)
- **High-harmonic generation** (HHG)
- **Carrier dynamics** (relaxation, thermalization, recombination)
- **Non-linear optical response** (second/third harmonic generation)
- **Time-resolved ARPES** (TR-ARPES)

### Key Features

- **Multiple time integrators**: Euler, Runge-Kutta (RK2/RK4/HEUN), Exponential (Magnus), Inverse
- **Flexible gauge choices**: Velocity gauge, length gauge
- **Mean-field approximations**: IP, Hartree, LDA/GGA, TDDFT, TDSEX, TDCOHSEX
- **Scattering mechanisms**: Electron-electron, electron-phonon, electron-photon
- **Adaptive time-stepping**: Automatic adjustment based on dynamics
- **Memory-efficient**: Circular buffers for time-dependent quantities

---

## 2. Theoretical Framework

### 2.1 Non-Equilibrium Green's Functions

The real-time module uses the **lesser Green's function** (density matrix) as the fundamental quantity:

```
G^<_{nm}(k,t,t') = i⟨c†_m(k,t')c_n(k,t)⟩
```

where:
- `n,m` are band indices
- `k` is the crystal momentum
- `t,t'` are time arguments
- `c†, c` are creation/annihilation operators

### 2.2 Time-Diagonal Approximation

YAMBO uses the **time-diagonal** (equal-time) approximation:

```
G^<_{nm}(k,t) ≡ G^<_{nm}(k,t,t)
```

This reduces the two-time Green's function to a **density matrix**:

```
ρ_{nm}(k,t) = -iG^<_{nm}(k,t)
```

**Physical interpretation:**
- Diagonal elements: `ρ_{nn}(k,t) = f_n(k,t)` (occupation factors)
- Off-diagonal elements: `ρ_{nm}(k,t)` (coherences between states n and m)

### 2.3 Equation of Motion

The time evolution is governed by the **Kadanoff-Baym equation**:

```
i∂G^<(t)/∂t - [H^RT(t), G^<(t)] = Σ^scatt(t)
```

or equivalently for the density matrix:

```
i∂ρ(t)/∂t = [H^RT(t), ρ(t)] - iΣ^scatt(t)
```

**Components:**
- `H^RT(t)`: Time-dependent Hamiltonian (mean-field + external field)
- `[H,ρ]`: Commutator (coherent evolution)
- `Σ^scatt(t)`: Collision self-energy (dissipation, scattering)

---

## 3. Kadanoff-Baym Equations

### 3.1 Full KBE Structure

The complete Kadanoff-Baym equations include:

**1. Lesser component:**
```
i∂G^<(t)/∂t = [H^RT(t), G^<(t)] + Σ^scatt(t)
```

**2. Greater component:**
```
i∂G^>(t)/∂t = [H^RT(t), G^>(t)] + Σ^scatt(t)
```

**3. Relation:**
```
G^>(t) - G^<(t) = G^R(t) - G^A(t)
```

where `G^R` (retarded) and `G^A` (advanced) are determined by causality.

### 3.2 Time-Diagonal Simplification

In the time-diagonal approximation:

```
G^<_{nm}(k,t) = i f_{nm}(k,t)
```

where `f_{nm}` is the **generalized occupation matrix**:
- `f_{nn} = f_n(k,t)`: Occupation of state n
- `f_{nm} (n≠m)`: Coherence between states n and m

### 3.3 Matrix Form

In band representation:

```
i∂f_{nm}(k,t)/∂t = Σ_l [H^RT_{nl}(k,t)f_{lm}(k,t) - f_{nl}(k,t)H^RT_{lm}(k,t)]
                    - i[Σ^scatt]_{nm}(k,t)
```

**Diagonal elements** (populations):
```
∂f_n(k,t)/∂t = 2Im[Σ_l H^RT_{nl}(k,t)f_{ln}(k,t)] - [Σ^scatt]_{nn}(k,t)
```

**Off-diagonal elements** (coherences):
```
i∂f_{nm}(k,t)/∂t = (E_n - E_m)f_{nm} + Σ_l [H^RT_{nl}f_{lm} - f_{nl}H^RT_{lm}]
                    - i[Σ^scatt]_{nm}
```

---

## 4. Time-Dependent Hamiltonian

### 4.1 Hamiltonian Decomposition

The RT Hamiltonian is decomposed as:

```
H^RT(t) = H^EQ + ΔΣ^Hxc[G(t)] + H^ext(t)
```

**Components:**

1. **Equilibrium Hamiltonian** `H^EQ`:
   ```
   H^EQ_{nm}(k) = δ_{nm} E_n(k)
   ```
   - Diagonal matrix with DFT or GW quasiparticle energies
   - Time-independent reference

2. **Mean-field correction** `ΔΣ^Hxc[G(t)]`:
   ```
   ΔΣ^Hxc = Σ^Hxc[G(t)] - Σ^Hxc[G_ref]
   ```
   - Variation of Hartree-exchange-correlation self-energy
   - Depends on instantaneous density `ρ(r,t)`

3. **External perturbation** `H^ext(t)`:
   ```
   H^ext = A(t)·p  (velocity gauge)
   H^ext = E(t)·r  (length gauge)
   ```
   - Laser fields, electric fields, etc.

### 4.2 Mean-Field Self-Energy

The mean-field self-energy is computed from the time-dependent density:

```
ρ(r,t) = Σ_{n,k} f_n(k,t)|ψ_{nk}(r)|²
```

**Hartree term:**
```
V^H(r,t) = ∫ dr' ρ(r',t)/|r-r'|
```

**Exchange-correlation term:**
```
V^xc(r,t) = δE^xc[ρ]/δρ(r,t)
```

**Matrix elements:**
```
[ΔΣ^Hxc]_{nm}(k,t) = ⟨ψ_{nk}|V^H(t) + V^xc(t)|ψ_{mk}⟩
                      - ⟨ψ_{nk}|V^H_ref + V^xc_ref|ψ_{mk}⟩
```

### 4.3 Computation Strategies

**Strategy (a): Kernel-based (collision integrals)**
```
ΔΣ^Hxc = K·[G(t) - G_ref]
```
- Exact for self-energies linear in G^< (Hartree, exchange, SEX)
- Kernel K computed at equilibrium
- Fast but limited to specific approximations

**Strategy (b): Direct functional evaluation**
```
ΔΣ^Hxc = Σ^Hxc[ρ(t)] - Σ^Hxc[ρ_ref]
```
- General, works for any functional
- Recompute density and potentials at each time step
- More expensive but more flexible

---

## 5. Time Integration Methods

### 5.1 General Integration Scheme

The formal solution is:

```
G^<(t+Δt) = U(t+Δt,t) G^<(t) U†(t+Δt,t) + ∫_t^{t+Δt} dt' U(t+Δt,t') Σ^scatt(t') U†(t+Δt,t')
```

where `U(t',t)` is the time evolution operator:

```
U(t',t) = T exp[-i∫_t^{t'} H^RT(τ)dτ]
```

### 5.2 Euler Method (EULER)

**First-order explicit:**
```
G^<(t+Δt) = G^<(t) - iΔt[H^RT(t), G^<(t)] + Δt Σ^scatt(t)
```

**Properties:**
- ✅ Simple, fast
- ✅ Explicit (no matrix inversion)
- ❌ First-order accurate: error ~ O(Δt²)
- ❌ Requires small time steps for stability
- ❌ Does not preserve unitarity

**Stability condition:**
```
Δt < 2/|E_max - E_min|
```

### 5.3 Exponential Integrator (EXP)

**Magnus expansion:**
```
G^<(t+Δt) = exp(-iH^RT Δt) G^<(t) exp(+iH^RT Δt)
```

Expanded as:
```
G^<(t+Δt) = G^<(t) - iΔt[H,G^<] - (Δt)²/2[H,[H,G^<]] 
            - i(Δt)³/6[H,[H,[H,G^<]]] + ...
```

**Implementation:**
```
G_1 = G^<
G_2 = [H, G_1]
G_3 = [H, G_2]
...
G^<(t+Δt) = Σ_{n=0}^{N_max} (-iΔt)^n/n! G_{n+1}
```

**Properties:**
- ✅ Higher-order accurate (up to 6th order)
- ✅ Preserves unitarity better than Euler
- ✅ Allows larger time steps
- ❌ More expensive per step (multiple commutators)
- ❌ Requires Hamiltonian to be slowly varying

**Typical order:** N_max = 4 or 6

### 5.4 Inverse Integrator (INV)

**Implicit Crank-Nicolson scheme:**
```
(1 + iH^RT Δt/2) G^<(t+Δt) + G^<(t+Δt) (1 - iH^RT Δt/2) 
  = (1 - iH^RT Δt/2) G^<(t) + G^<(t) (1 + iH^RT Δt/2)
```

Rearranged:
```
(1 + iH Δt/2) G^<(t+Δt) (1 - iH Δt/2)^{-1} = (1 - iH Δt/2) G^<(t) (1 + iH Δt/2)^{-1}
```

**Properties:**
- ✅ Unconditionally stable (no time step restriction)
- ✅ Second-order accurate
- ✅ Preserves unitarity exactly
- ❌ Requires matrix inversion at each step
- ❌ More expensive per step

**Best for:** Stiff problems, large time steps

### 5.5 Diagonalization-Based (DIAG)

**Exact evolution in eigenbasis:**

1. Diagonalize Hamiltonian:
   ```
   H^RT(t) = U(t) E(t) U†(t)
   ```

2. Transform density matrix:
   ```
   G̃^<(t) = U†(t) G^<(t) U(t)
   ```

3. Evolve in diagonal basis:
   ```
   G̃^<_{nm}(t+Δt) = G̃^<_{nm}(t) exp[-i(E_n - E_m)Δt]
   ```

4. Transform back:
   ```
   G^<(t+Δt) = U(t) G̃^<(t+Δt) U†(t)
   ```

**Properties:**
- ✅ Exact for time-independent H
- ✅ Preserves unitarity exactly
- ❌ Very expensive (diagonalization at each step)
- ❌ Only practical for small systems

### 5.6 Multi-Step Methods

Each integrator can be combined with multi-step schemes:

**RK2 (Runge-Kutta 2nd order):**
```
G_1 = U(Δt/2, H[G(t)]) G(t)
G(t+Δt) = U(Δt, H[G_1]) G(t)
```

**HEUN:**
```
G_1 = U(Δt, H[G(t)]) G(t)
G_2 = U(Δt, H[G_1]) G(t)
G(t+Δt) = (G_1 + G_2)/2
```

**RK4 (Runge-Kutta 4th order):**
```
k_1 = -i[H[G(t)], G(t)]
k_2 = -i[H[G(t) + k_1 Δt/2], G(t) + k_1 Δt/2]
k_3 = -i[H[G(t) + k_2 Δt/2], G(t) + k_2 Δt/2]
k_4 = -i[H[G(t) + k_3 Δt], G(t) + k_3 Δt]
G(t+Δt) = G(t) + Δt(k_1 + 2k_2 + 2k_3 + k_4)/6
```

---

## 6. External Fields and Gauge Choices

### 6.1 Electromagnetic Field Coupling

The coupling to electromagnetic fields depends on the **gauge choice**.

**Maxwell equations:**
```
E(t) = -∂A(t)/∂t - ∇φ(t)
B(t) = ∇×A(t)
```

where:
- `E(t)`: Electric field
- `A(t)`: Vector potential
- `φ(t)`: Scalar potential

### 6.2 Velocity Gauge (Coulomb Gauge)

**Gauge condition:** `∇·A = 0`, `φ = 0`

**Hamiltonian:**
```
H^RT = (p + A(t))²/2m + V(r)
     = p²/2m + A(t)·p/m + A²(t)/2m + V(r)
```

**Minimal coupling:**
```
H^ext = A(t)·p/m + A²(t)/2m
```

**Matrix elements:**
```
H^ext_{nm}(k,t) = A(t)·p_{nm}(k)/m - δ_{nm} A²(t)/2m
```

where `p_{nm}(k) = ⟨ψ_{nk}|p|ψ_{mk}⟩` is the momentum matrix element.

**Relation to velocity:**
```
v_{nm}(k) = p_{nm}(k)/m + (1/m)⟨ψ_{nk}|[V^NL, r]|ψ_{mk}⟩
```

The second term is the **non-local pseudopotential correction**.

**YAMBO implementation:**
- If `l_velocity_gauge_corr = .true.`: Use `p_{nm}` (correctly gauged pseudopotential)
- If `l_velocity_gauge_corr = .false.`: Use `v_{nm}` (approximate, linear expansion)

**Advantages:**
- ✅ Natural for periodic systems
- ✅ Preserves crystal momentum
- ✅ Efficient for plane-wave basis

**Disadvantages:**
- ❌ Requires momentum matrix elements
- ❌ Diamagnetic term `A²/2m` can be large

### 6.3 Length Gauge (Dipole Gauge)

**Gauge transformation:**
```
A → A' = A + ∇χ
φ → φ' = φ - ∂χ/∂t
```

Choose `χ = -r·A(t)` to eliminate A:

**Hamiltonian:**
```
H^RT = p²/2m + V(r) + E(t)·r
```

**Matrix elements:**
```
H^ext_{nm}(k,t) = E(t)·r_{nm}(k)
```

where `r_{nm}(k) = ⟨ψ_{nk}|r|ψ_{mk}⟩` is the position matrix element.

**Dipole approximation:**
Valid when wavelength λ >> lattice constant a:
```
exp(iq·r) ≈ 1 + iq·r
```

**Advantages:**
- ✅ Simpler (no diamagnetic term)
- ✅ Direct physical interpretation (dipole coupling)
- ✅ Easier to implement

**Disadvantages:**
- ❌ Breaks translational invariance in periodic systems
- ❌ Requires position matrix elements (ill-defined in periodic systems)
- ❌ Only valid for long-wavelength fields

### 6.4 Gauge Equivalence

The two gauges are **physically equivalent** but differ in:
- Numerical implementation
- Convergence properties
- Computational cost

**Relation between matrix elements:**
```
r_{nm}(k) = i p_{nm}(k)/(E_n(k) - E_m(k))  (n ≠ m)
```

This is the **dipole approximation** in the velocity gauge.

### 6.5 Field Shapes

YAMBO supports various field envelopes:

**1. Gaussian pulse:**
```
E(t) = E_0 exp[-(t-t_0)²/(2σ²)] cos(ω_0 t + φ)
```

**2. Sin² envelope:**
```
E(t) = E_0 sin²(πt/T) cos(ω_0 t + φ)  for 0 < t < T
```

**3. Constant (CW):**
```
E(t) = E_0 cos(ω_0 t + φ)
```

**4. Delta kick:**
```
E(t) = E_0 δ(t)
```

---

## 7. Scattering Mechanisms

### 7.1 Collision Self-Energy

The collision term `Σ^scatt(t)` describes **irreversible processes**:

```
Σ^scatt_{nm}(k,t) = Σ^{el-el}_{nm} + Σ^{el-ph}_{nm} + Σ^{el-photon}_{nm}
```

### 7.2 Electron-Electron Scattering

**Screened Coulomb interaction:**
```
Σ^{el-el}_{nm}(k,t) = Σ_{k',n',m'} W_{nn',mm'}(k,k',t) 
                       × [f_{n'}(k',t)f_{m'}(k',t) - f_n(k,t)f_m(k,t)]
```

where `W` is the screened Coulomb interaction.

**Approximations:**

1. **Static screening (SEX):**
   ```
   W(ω) = W(ω=0)
   ```

2. **Plasmon-pole (PPA):**
   ```
   W(ω) = Ω²/(ω² - ω_p²)
   ```

3. **Full frequency-dependent:**
   ```
   W(ω) = ε^{-1}(ω) v(q)
   ```

**Relaxation time approximation:**
```
Σ^{el-el}_{nn}(k,t) = -[f_n(k,t) - f^eq_n(k)]/τ_{el-el}(k)
```

### 7.3 Electron-Phonon Scattering

**Electron-phonon coupling:**
```
Σ^{el-ph}_{nm}(k,t) = Σ_{k',ν} |g_{nm}^ν(k,k')|² 
                       × [(n_ν(k-k',t) + f_m(k',t))δ(E_n(k) - E_m(k') - ω_ν)
                          + (n_ν(k-k',t) + 1 - f_m(k',t))δ(E_n(k) - E_m(k') + ω_ν)]
```

where:
- `g^ν`: Electron-phonon matrix element
- `n_ν`: Phonon occupation
- `ω_ν`: Phonon frequency

**Relaxation time approximation:**
```
Σ^{el-ph}_{nn}(k,t) = -[f_n(k,t) - f^eq_n(k)]/τ_{el-ph}(k)
```

### 7.4 Electron-Photon Scattering

**Radiative recombination:**
```
Σ^{el-photon}_{nm}(k,t) = -γ_{rad} [f_n(k,t)f_m(k,t) - f^eq_n f^eq_m]
```

where `γ_{rad}` is the radiative recombination rate.

### 7.5 Dephasing

**Pure dephasing** (T₂ processes):
```
Σ^{deph}_{nm}(k,t) = -f_{nm}(k,t)/T_2  (n ≠ m)
```

Destroys coherences without affecting populations.

---

## 8. Physical Observables

### 8.1 Current Density

**Definition:**
```
J(t) = -e Σ_{n,k} f_n(k,t) v_n(k)
```

where `v_n(k) = ∇_k E_n(k)` is the group velocity.

**Including off-diagonal elements:**
```
J(t) = -e Σ_{n,m,k} f_{nm}(k,t) v_{nm}(k)
```

**Velocity gauge:**
```
J(t) = -e Σ_{n,m,k} f_{nm}(k,t) [p_{nm}(k)/m - δ_{nm} A(t)]
```

The second term is the **diamagnetic current**.

### 8.2 Polarization

**Time integral of current:**
```
P(t) = ∫_0^t J(t') dt'
```

**Direct calculation:**
```
P(t) = -e Σ_{n,k} f_n(k,t) r_n(k)
```

### 8.3 Energy Components

**Total energy:**
```
E_tot(t) = E_kin(t) + E_H(t) + E_xc(t) + E_ext(t)
```

**Kinetic energy:**
```
E_kin(t) = Σ_{n,k} f_n(k,t) E^KS_n(k)
```

**Hartree energy:**
```
E_H(t) = (1/2) ∫ dr dr' ρ(r,t)ρ(r',t)/|r-r'|
```

**Exchange-correlation energy:**
```
E_xc(t) = ∫ dr ε_xc[ρ(r,t)] ρ(r,t)
```

**External field energy:**
```
E_ext(t) = -P(t)·E(t)
```

### 8.4 Carrier Populations

**Electron density:**
```
n_e(t) = Σ_{n∈CB,k} f_n(k,t)
```

**Hole density:**
```
n_h(t) = Σ_{n∈VB,k} [1 - f_n(k,t)]
```

**Carrier temperature:**
Fit to Fermi-Dirac distribution:
```
f_n(k,t) ≈ 1/(1 + exp[(E_n(k) - μ(t))/(k_B T(t))])
```

### 8.5 Entropy

**Von Neumann entropy:**
```
S(t) = -k_B Σ_{n,k} [f_n(k,t) ln f_n(k,t) + (1-f_n(k,t)) ln(1-f_n(k,t))]
```

Measures the **degree of thermalization**.

### 8.6 Magnetization

**Spin magnetization:**
```
M_s(t) = μ_B Σ_{n,k,σ} σ f_{nσ}(k,t)
```

**Orbital magnetization:**
```
M_L(t) = -(e/2m) Σ_{n,k} f_n(k,t) ⟨ψ_{nk}|r×p|ψ_{nk}⟩
```

---

## 9. Approximations and Functionals

### 9.1 Independent Particle (IP)

**Hamiltonian:**
```
H^RT(t) = H^EQ + H^ext(t)
```

No mean-field corrections: `ΔΣ^Hxc = 0`

**Properties:**
- ✅ Simplest, fastest
- ❌ No screening, no many-body effects
- ❌ Unphysical for interacting systems

### 9.2 Time-Dependent Hartree (TD-Hartree)

**Mean-field self-energy:**
```
ΔΣ^H_{nm}(k,t) = ⟨ψ_{nk}|V^H[ρ(t)] - V^H[ρ_ref]|ψ_{mk}⟩
```

**Hartree potential:**
```
V^H(r,t) = ∫ dr' ρ(r',t)/|r-r'|
```

**Properties:**
- ✅ Includes classical Coulomb repulsion
- ✅ Screening effects
- ❌ No exchange, no correlation

### 9.3 Time-Dependent LDA/GGA (TDDFT)

**Mean-field self-energy:**
```
ΔΣ^Hxc_{nm}(k,t) = ⟨ψ_{nk}|V^H[ρ(t)] + V^xc[ρ(t)] - V^H[ρ_ref] - V^xc[ρ_ref]|ψ_{mk}⟩
```

**Exchange-correlation potential:**
```
V^xc(r,t) = δE^xc[ρ]/δρ(r,t)
```

**Functionals:**
- **LDA**: Local density approximation (e.g., PZ, PW)
- **GGA**: Generalized gradient approximation (e.g., PBE, BLYP)

**Properties:**
- ✅ Includes exchange and correlation
- ✅ Computationally efficient
- ❌ Approximate (local/semi-local)
- ❌ Underestimates band gaps

### 9.4 Time-Dependent SEX (TDSEX)

**Screened exchange self-energy:**
```
Σ^SEX_{nm}(k,t) = -Σ_{k',m'} W_{nm,m'm'}(k,k',t=0) f_{m'}(k',t)
```

where `W` is the statically screened Coulomb interaction.

**Properties:**
- ✅ Includes dynamical screening
- ✅ Better band gaps than DFT
- ❌ Requires W from equilibrium GW
- ❌ Only valid for small perturbations

### 9.5 Time-Dependent COHSEX (TDCOHSEX)

**COHSEX = COH + SEX:**
```
Σ^COHSEX = Σ^COH + Σ^SEX
```

**COH (Coulomb hole):**
```
Σ^COH_{nm}(k) = (1/2) Σ_{k',m'} [W_{nm,m'm'}(k,k',ω=0) - v_{nm,m'm'}(k,k')]
```

**Properties:**
- ✅ Static approximation to GW
- ✅ Includes correlation
- ❌ Less accurate than full GW

### 9.6 Comparison Table

| Approximation | Hartree | Exchange | Correlation | Screening | Cost |
|---------------|---------|----------|-------------|-----------|------|
| IP            | ❌      | ❌       | ❌          | ❌        | Low  |
| TD-Hartree    | ✅      | ❌       | ❌          | Static    | Low  |
| TDDFT-LDA     | ✅      | ✅       | ✅          | Implicit  | Low  |
| TDDFT-GGA     | ✅      | ✅       | ✅          | Implicit  | Medium |
| TDSEX         | ✅      | ✅       | ❌          | Static    | High |
| TDCOHSEX      | ✅      | ✅       | ✅          | Static    | High |

---

## 10. Implementation Details

### 10.1 Code Structure

**Main driver:** `RT_driver.F`
```
RT_driver
├── RT_initialize          ! Setup, allocate memory
├── RT_start_and_restart   ! Initial conditions or restart
├── Time loop
│   ├── RT_Hamiltonian     ! Build H^RT(t)
│   ├── RT_Integrator      ! Propagate G^<(t) → G^<(t+Δt)
│   ├── RT_relaxation      ! Compute scattering terms
│   ├── RT_Observables     ! Compute J, P, E, etc.
│   └── RT_output_and_IO   ! Write to disk
└── RT_free                ! Cleanup
```

### 10.2 Key Data Structures

**Density matrix:**
```fortran
complex(SP) :: G_lesser(nb1:nb2, nb1:nb2, nk, n_sp_pol, n_mem_steps)
```
- `nb1:nb2`: Band range
- `nk`: Number of k-points
- `n_sp_pol`: Spin polarizations (1 or 2)
- `n_mem_steps`: Circular buffer size

**Hamiltonian:**
```fortran
complex(SP) :: Ho_plus_Sigma(nb1:nb2, nb1:nb2, nk, n_sp_pol)
```

**Observables:**
```fortran
type RT_observables_t
  real(SP) :: J(3, n_time_steps)      ! Current
  real(SP) :: P(3, n_time_steps)      ! Polarization
  real(SP) :: E_tot(n_time_steps)     ! Total energy
  real(SP) :: E_kin(n_time_steps)     ! Kinetic energy
  real(SP) :: entropy(n_time_steps)   ! Entropy
end type
```

### 10.3 Memory Management

**Circular buffer:**
```
i_MEM_now  = mod(i_time, G_MEM_steps) + 1
i_MEM_prev = mod(i_time-1, G_MEM_steps) + 1
i_MEM_old  = mod(i_time-2, G_MEM_steps) + 1
```

Stores only last `G_MEM_steps` time steps in memory.

### 10.4 Parallelization

**MPI distribution:**
- **k-points**: Distributed over `PAR_COM_Xk_ibz`
- **Bands**: Distributed over `PAR_COM_bands`
- **G-vectors**: Distributed over `PAR_COM_G`

**OpenMP threading:**
- Band loops
- k-point loops
- FFT operations

**GPU acceleration:**
- Matrix-matrix multiplications (commutators)
- FFT transforms
- Density computation

### 10.5 Adaptive Time-Stepping

**Criterion:**
```
Δt_new = Δt_old × min(treshold / max_change, safety_factor)
```

where `max_change` is the maximum relative change in:
- Occupations: `|f_n(t) - f_n(t-Δt)|/f_n(t)`
- Hamiltonian: `|H(t) - H(t-Δt)|/|H(t)|`

**Typical values:**
- `treshold = 0.01` (1% change)
- `safety_factor = 1.5`

### 10.6 Rotating Wave Approximation (RWA)

For near-resonant excitation, remove fast oscillations:

**Transformation:**
```
G̃^<(t) = exp(iω_0 t) G^<(t) exp(-iω_0 t)
H̃^RT(t) = H^RT(t) - ω_0
```

**Equation of motion:**
```
i∂G̃^<(t)/∂t = [H̃^RT(t), G̃^<(t)]
```

Allows much larger time steps when `ω_0 ≈ E_gap`.

---

## 11. References

### Foundational Papers

1. **Kadanoff-Baym Equations:**
   - L.P. Kadanoff and G. Baym, *Quantum Statistical Mechanics* (Benjamin, 1962)
   - L.V. Keldysh, *Sov. Phys. JETP* **20**, 1018 (1965)

2. **Real-Time TDDFT:**
   - E. Runge and E.K.U. Gross, *Phys. Rev. Lett.* **52**, 997 (1984)
   - M.A.L. Marques et al., *Time-Dependent Density Functional Theory* (Springer, 2006)

3. **Non-Equilibrium Green's Functions:**
   - H. Haug and A.-P. Jauho, *Quantum Kinetics in Transport and Optics of Semiconductors* (Springer, 2008)
   - G. Stefanucci and R. van Leeuwen, *Nonequilibrium Many-Body Theory of Quantum Systems* (Cambridge, 2013)

4. **YAMBO Real-Time:**
   - D. Sangalli et al., *J. Chem. Phys.* **134**, 034115 (2011)
   - C. Attaccalite et al., *Phys. Rev. B* **84**, 245110 (2011)
   - A. Marini et al., *Comp. Phys. Comm.* **180**, 1392 (2009)

### Numerical Methods

5. **Time Integration:**
   - W. Magnus, *Comm. Pure Appl. Math.* **7**, 649 (1954)
   - E. Hairer et al., *Solving Ordinary Differential Equations* (Springer, 1993)

6. **Gauge Choices:**
   - D.H. Dunlap and V.M. Kenkre, *Phys. Rev. B* **34**, 3625 (1986)
   - M.V. Ammosov et al., *Sov. Phys. JETP* **64**, 1191 (1986)

### Applications

7. **High-Harmonic Generation:**
   - P.B. Corkum, *Phys. Rev. Lett.* **71**, 1994 (1993)
   - M. Lewenstein et al., *Phys. Rev. A* **49**, 2117 (1994)

8. **Ultrafast Carrier Dynamics:**
   - C. Attaccalite et al., *Phys. Rev. Lett.* **98**, 097402 (2007)
   - E. Perfetto et al., *Phys. Rev. Lett.* **110**, 087001 (2013)

9. **Transient Absorption:**
   - F. Rossi and T. Kuhn, *Rev. Mod. Phys.* **74**, 895 (2002)
   - M. Grüning and C. Attaccalite, *Phys. Rev. B* **89**, 081102(R) (2014)

---

## Appendix A: Variable Name Reference

| Physical Quantity | YAMBO Variable | Units | Description |
|-------------------|----------------|-------|-------------|
| Lesser Green's function | `G_lesser` | - | Density matrix |
| Hamiltonian | `Ho_plus_Sigma` | Ha | RT Hamiltonian |
| Equilibrium Hamiltonian | `H_EQ` | Ha | DFT/QP energies |
| External field | `A_tot` | a.u. | Vector potential |
| Current | `J_tot` | e·a.u./fs | Current density |
| Polarization | `P_tot` | e·a.u. | Polarization |
| Time step | `RT_step` | fs | Integration time step |
| Total time | `NE_tot_time` | fs | Simulation duration |
| Density | `rho_n` | e/a.u.³ | Electron density |
| Hartree potential | `V_hartree_sc` | Ha | Hartree potential |
| XC potential | `V_xc_sc` | Ha | XC potential |
| Occupations | `RT_levels%f` | - | Occupation factors |

---

## Appendix B: Typical Simulation Parameters

### Time Steps

| System | Integrator | Time Step | Total Time |
|--------|------------|-----------|------------|
| Bulk Si (IP) | EULER | 0.01 fs | 10 fs |
| Bulk Si (TDDFT) | EXP | 0.05 fs | 50 fs |
| 2D MoS₂ (TDSEX) | INV | 0.1 fs | 100 fs |
| Molecules | RK4 | 0.001 fs | 1 fs |

### Field Strengths

| Process | Field Strength | Wavelength | Duration |
|---------|----------------|------------|----------|
| Linear response | 10⁻⁴ a.u. | 800 nm | 10 fs |
| Non-linear optics | 10⁻³ a.u. | 800 nm | 5 fs |
| High-harmonic generation | 10⁻² a.u. | 1600 nm | 2 fs |
| Strong-field ionization | 10⁻¹ a.u. | 800 nm | 1 fs |

**Conversion:** 1 a.u. = 5.14 × 10¹¹ V/m

---