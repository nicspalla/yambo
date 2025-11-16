# YAMBO Real-Time Visual Guide {#yambo_rt_visual}

@page yambo_rt_visual YAMBO Real-Time Visual Guide

**Diagrams, flowcharts, and visual representations of RT theory and implementation**

@tableofcontents

---

## Table of Contents

1. [RT Workflow Overview](#1-rt-workflow-overview)
2. [Kadanoff-Baym Equation Structure](#2-kadanoff-baym-equation-structure)
3. [Time Integration Schemes](#3-time-integration-schemes)
4. [Hamiltonian Construction](#4-hamiltonian-construction)
5. [Gauge Choices Comparison](#5-gauge-choices-comparison)
6. [Observable Computation](#6-observable-computation)
7. [Memory Management](#7-memory-management)
8. [Data Flow Diagrams](#8-data-flow-diagrams)

---

## 1. RT Workflow Overview

### Complete RT Simulation Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    YAMBO RT SIMULATION                      │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  INITIALIZATION PHASE                                       │
├─────────────────────────────────────────────────────────────┤
│  1. Read DFT/GW ground state                                │
│     • Wavefunctions ψ_nk                                    │
│     • Energies E_nk                                         │
│     • k-point sampling                                      │
│                                                             │
│  2. Setup RT parameters                                     │
│     • Time step Δt                                          │
│     • Total time T_max                                      │
│     • Band range [n_min, n_max]                             │
│     • Integrator type                                       │
│                                                             │
│  3. Initialize density matrix                               │
│     • G^<(t=0) = i·f_eq(E_nk)                               │
│     • Equilibrium occupations                               │
│                                                             │
│  4. Compute reference quantities                            │
│     • ρ_ref(r) = equilibrium density                        │
│     • V^H_ref, V^xc_ref                                     │
│     • H^EQ = diag(E_nk)                                     │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  TIME LOOP: t = 0 → T_max                                   │
├─────────────────────────────────────────────────────────────┤
│  ┌───────────────────────────────────────────────────────┐  │
│  │ STEP 1: Build RT Hamiltonian                          │  │
│  │ ────────────────────────────────────────────────────  │  │
│  │  a) Compute density: ρ(r,t) = Σ_nk f_nk(t)|ψ_nk|²   │ │  |
│  │  b) Compute Hartree: V^H[ρ(t)]                      │ │  |
│  │  c) Compute XC: V^xc[ρ(t)]                          │ │  |
│  │  d) Build matrix: ΔΣ^Hxc_nm = ⟨n|V^H+V^xc|m⟩        │ │  |
│  │  e) Add external field: H^ext(t)                    │ │  |
│  │  f) Total: H^RT = H^EQ + ΔΣ^Hxc + H^ext             │ │  |
│  └───────────────────────────────────────────────────────┘  │
│                            │                                │
│                            ▼                                │
│  ┌───────────────────────────────────────────────────────┐  │
│  │ STEP 2: Time Integration                              │  │
│  │ ────────────────────────────────────────────────────  │  │
│  │  Solve: i∂G^</∂t = [H^RT, G^<] + Σ^scatt            │ │  |
│  │                                                     | │  | 
│  │  Choose integrator:                                 | │  |
│  │  • EULER:  G^<(t+Δt) = G^< - iΔt[H,G^<]             │ │  |
│  │  • EXP:    G^<(t+Δt) = exp(-iHΔt)G^<exp(+iHΔt)      │ │  |
│  │  • INV:    (1+iHΔt/2)G^<(t+Δt)(1-iHΔt/2)^-1 = ...   │ │  |
│  │  • RK2/RK4: Multi-step Runge-Kutta                  │ │  |
│  └───────────────────────────────────────────────────────┘  |
│                            │                                │
│                            ▼                                │
│  ┌───────────────────────────────────────────────────────┐  │
│  │ STEP 3: Add Scattering                                │  │
│  │ ────────────────────────────────────────────────────  │  │
│  │  G^< → G^< + Δt·Σ^scatt                               │  │
│  │                                                       │  │
│  │  • Electron-electron: Σ^{el-el}                       │  │
│  │  • Electron-phonon: Σ^{el-ph}                         │  │
│  │  • Dephasing: Σ^{deph}                                │  │
│  └───────────────────────────────────────────────────────┘  │
│                            │                                │
│                            ▼                                │
│  ┌───────────────────────────────────────────────────────┐  │
│  │ STEP 4: Extract Observables                           │  │
│  │ ────────────────────────────────────────────────────  │  │
│  │  • Occupations: f_n(k,t) = Im[G^<_nn]               │ │  |
│  │  • Current: J(t) = -e Σ_nk f_nk v_nk                │ │  |
│  │  • Polarization: P(t) = ∫J dt'                      │ │  |
│  │  • Energy: E_tot = Tr[H·G^<]                        │ │  |
│  │  • Entropy: S = -Tr[G^<·ln G^<]                     │ │  |
│  └───────────────────────────────────────────────────────┘  |
│                            │                                │
│                            ▼                                │
│  ┌───────────────────────────────────────────────────────┐  │
│  │ STEP 5: Output & I/O                                  │  │
│  │ ────────────────────────────────────────────────────  │  │
│  │  • Write observables to file                          │  │
│  │  • Save restart databases                             │  │
│  │  • Update live timing                                 │  │
│  └───────────────────────────────────────────────────────┘  │
│                            │                                │
│                            ▼                                │
│  ┌───────────────────────────────────────────────────────┐  │
│  │ STEP 6: Check Convergence                             │  │
│  │ ────────────────────────────────────────────────────  │  │
│  │  • Adaptive time-stepping?                            │  │
│  │  • t < T_max? → Continue loop                         │  │
│  │  • t ≥ T_max? → Exit                                  │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  POST-PROCESSING (YPP)                                      │
├─────────────────────────────────────────────────────────────┤
│  • Fourier transform: J(t) → χ(ω)                           │
│  • Absorption spectrum: α(ω) = Im[χ(ω)]                     │
│  • High-harmonic spectrum: |J(ω)|²                          │
│  • Carrier dynamics analysis                                │
│  • Time-resolved ARPES                                      │
└─────────────────────────────────────────────────────────────┘
```

---

## 2. Kadanoff-Baym Equation Structure

### Equation Components

```
┌────────────────────────────────────────────────────────────┐
│  Kadanoff-Baym Equation for Lesser Green's Function        │
└────────────────────────────────────────────────────────────┘

    i ∂G^<(t)/∂t  =  [H^RT(t), G^<(t)]  +  Σ^scatt(t)
    │              │                     │
    │              │                     │
    ▼              ▼                     ▼
┌────────┐    ┌──────────┐         ┌──────────┐
│ Time   │    │ Coherent │         │ Collision│
│ deriv. │    │ evolution│         │ integral │
└────────┘    └──────────┘         └──────────┘
                    │                     │
                    │                     │
                    ▼                     ▼
            ┌──────────────┐      ┌──────────────┐
            │ Mean-field   │      │ Scattering   │
            │ Hamiltonian  │      │ processes    │
            │              │      │              │
            │ • H^EQ       │      │ • el-el      │
            │ • ΔΣ^Hxc     │      │ • el-ph      │
            │ • H^ext      │      │ • dephasing  │
            └──────────────┘      └──────────────┘
```

### Matrix Structure

```
┌────────────────────────────────────────────────────────────┐
│  Density Matrix G^< in Band Representation                 │
└────────────────────────────────────────────────────────────┘

        Band index m →
         1    2    3    4    5    ...   N
    ┌───────────────────────────────────┐
  1 │ f_1  ρ_12 ρ_13 ρ_14 ρ_15 ... ρ_1N │  ← Diagonal: populations
  2 │ ρ_21  f_2 ρ_23 ρ_24 ρ_25 ... ρ_2N │     f_n = occupation
  3 │ ρ_31 ρ_32  f_3 ρ_34 ρ_35 ... ρ_3N │
  4 │ ρ_41 ρ_42 ρ_43  f_4 ρ_45 ... ρ_4N │  ← Off-diagonal: coherences
  5 │ ρ_51 ρ_52 ρ_53 ρ_54  f_5 ... ρ_5N │     ρ_nm = coherence between
  . │  .    .    .    .    .   ...  .   │            states n and m
  . │  .    .    .    .    .   ...  .   │
  N │ ρ_N1 ρ_N2 ρ_N3 ρ_N4 ρ_N5 ...  f_N │
    └───────────────────────────────────┘
    ↑
    Band index n

Properties:
• Hermitian: ρ_nm = ρ*_mn
• Trace: Tr[G^<] = i·Σ_n f_n = i·N_electrons
• Positive semi-definite: 0 ≤ f_n ≤ 1
```

---

## 3. Time Integration Schemes

### Integrator Comparison

```
┌────────────────────────────────────────────────────────────┐
│  Time Integration Methods                                  │
└────────────────────────────────────────────────────────────┘

EULER (1st order, explicit)
────────────────────────────
  t          t+Δt
  │           │
  G^<(t) ────→ G^<(t+Δt) = G^< - iΔt[H,G^<]
  │
  └─ Single evaluation of [H,G^<]

  Pros: ✓ Simple, fast
  Cons: ✗ Small Δt, no unitarity


EXPONENTIAL (Magnus expansion)
───────────────────────────────
  t          t+Δt
  │           │
  G^<(t) ────→ G^<(t+Δt) = exp(-iHΔt) G^< exp(+iHΔt)
  │
  └─ Expanded as: G^< - iΔt[H,G^<] - (Δt)²/2[H,[H,G^<]] + ...

  Pros: ✓ Higher order, preserves unitarity
  Cons: ✗ Multiple commutators


INVERSE (Crank-Nicolson, implicit)
───────────────────────────────────
  t          t+Δt
  │           │
  G^<(t) ────→ G^<(t+Δt) via matrix equation:
  │           (1+iHΔt/2) G^<(t+Δt) (1-iHΔt/2)^-1 = ...
  │
  └─ Requires matrix inversion

  Pros: ✓ Unconditionally stable, exact unitarity
  Cons: ✗ Matrix inversion cost


RK4 (4th order, multi-step)
────────────────────────────
  t      t+Δt/2    t+Δt
  │        │        │
  G^<(t) ─┬→ G_1 ──┬→ G^<(t+Δt)
          │        │
          ├→ G_2 ──┤
          │        │
          └→ G_3 ──┘

  Four intermediate evaluations combined

  Pros: ✓ 4th order accurate
  Cons: ✗ 4× cost per step
```

### Stability Regions

```
┌────────────────────────────────────────────────────────────┐
│  Stability in Complex Plane (λΔt)                          │
└────────────────────────────────────────────────────────────┘

Im(λΔt)
   ▲
   │
 2 │     EULER                    EXP/INV
   │   ┌─────┐                  (Unconditionally
 1 │   │  ○  │                    stable)
   │   │     │                      ∞
 0 ├───┼─────┼────────────────────────► Re(λΔt)
   │   │     │                     
-1 │   │     │                   RK4
   │   └─────┘                 ┌───────┐
-2 │                           │   ○   │
   │                           └───────┘
   └────────────────────────────────────

Legend:
○ = Stable region
λ = Eigenvalue of -iH
Δt = Time step

EULER: |1 - iλΔt| < 1  →  Δt < 2/|λ_max|
RK4:   Larger stable region
EXP/INV: All λΔt stable
```

---

## 4. Hamiltonian Construction

### Hamiltonian Decomposition Flow

```
┌────────────────────────────────────────────────────────────┐
│  RT Hamiltonian Construction                                │
└────────────────────────────────────────────────────────────┘

                    H^RT(t)
                       │
        ┌──────────────┼──────────────┐
        │              │              │
        ▼              ▼              ▼
    ┌───────┐    ┌──────────┐   ┌─────────┐
    │ H^EQ  │    │ ΔΣ^Hxc   │   │ H^ext   │
    └───────┘    └──────────┘   └─────────┘
        │              │              │
        │              │              │
        ▼              ▼              ▼
  ┌─────────┐    ┌──────────┐   ┌─────────┐
  │Diagonal │    │Mean-field│   │External │
  │matrix   │    │correction│   │field    │
  │         │    │          │   │         │
  │E_n(k)   │    │V^H + V^xc│   │A·p or   │
  │         │    │          │   │E·r      │
  └─────────┘    └──────────┘   └─────────┘
                       │
        ┌──────────────┼──────────────┐
        │              │              │
        ▼              ▼              ▼
  ┌─────────┐    ┌──────────┐   ┌─────────┐
  │ Density │    │ Hartree  │   │   XC    │
  │ ρ(r,t)  │    │ V^H[ρ]   │   │ V^xc[ρ] │
  └─────────┘    └──────────┘   └─────────┘
        │              │              │
        └──────────────┴──────────────┘
                       │
                       ▼
              ┌─────────────────┐
              │ FFT: r-space    │
              │  ↕              │
              │ k-space matrix  │
              └─────────────────┘
```

### Mean-Field Computation Steps

```
┌────────────────────────────────────────────────────────────┐
│  Mean-Field Self-Energy Computation                        │
└────────────────────────────────────────────────────────────┘

Step 1: Compute density
───────────────────────
  G^<_nm(k,t)  →  ρ(r,t) = Σ_nk f_n(k,t)|ψ_nk(r)|²
                           │
                           ├─ Load wavefunctions ψ_nk
                           ├─ Extract occupations f_n = Im[G^<_nn]
                           └─ Sum over bands and k-points


Step 2: Compute Hartree potential
──────────────────────────────────
  ρ(r,t)  →  V^H(r,t) = ∫ ρ(r',t)/|r-r'| dr'
             │
             ├─ FFT: ρ(r) → ρ(G)
             ├─ Multiply: V^H(G) = 4π/G² · ρ(G)
             └─ FFT: V^H(G) → V^H(r)


Step 3: Compute XC potential
─────────────────────────────
  ρ(r,t)  →  V^xc(r,t) = δE^xc[ρ]/δρ
             │
             ├─ Evaluate XC functional (LDA/GGA)
             └─ Compute derivative


Step 4: Transform to matrix elements
─────────────────────────────────────
  V^H(r), V^xc(r)  →  ΔΣ^Hxc_nm(k) = ⟨ψ_nk|V^H + V^xc|ψ_mk⟩
                                      - (reference term)
                      │
                      ├─ Load wavefunctions
                      ├─ Multiply: ψ*_n · V · ψ_m
                      └─ Integrate over r (FFT)


Step 5: Add to Hamiltonian
───────────────────────────
  H^RT = H^EQ + ΔΣ^Hxc + H^ext
```

---

## 5. Gauge Choices Comparison

### Velocity vs Length Gauge

```
┌────────────────────────────────────────────────────────────┐
│  Gauge Choice Comparison                                   │
└────────────────────────────────────────────────────────────┘

VELOCITY GAUGE (Coulomb gauge)
───────────────────────────────
  ∇·A = 0,  φ = 0

  Hamiltonian:
  ┌─────────────────────────────────────┐
  │ H = (p + A)²/2m + V                 │
  │   = p²/2m + A·p/m + A²/2m + V       │
  └─────────────────────────────────────┘
           │         │         │
           │         │         └─ Diamagnetic term
           │         └─────────── Paramagnetic term
           └─────────────────────── Kinetic

  Matrix elements:
  H^ext_nm = A·p_nm/m - δ_nm A²/2m

  Field relation:
  E(t) = -∂A/∂t

  ┌─────────────────────────────────────┐
  │ Pros:                               │
  │ ✓ Natural for periodic systems      │
  │ ✓ Preserves crystal momentum        │
  │ ✓ Efficient for plane waves         │
  │                                     │
  │ Cons:                               │
  │ ✗ Requires momentum matrix elements │
  │ ✗ Diamagnetic term can be large     │
  └─────────────────────────────────────┘


LENGTH GAUGE (Dipole gauge)
────────────────────────────
  A = 0,  φ = -E·r

  Hamiltonian:
  ┌─────────────────────────────────────┐
  │ H = p²/2m + V + E·r                 │
  └─────────────────────────────────────┘
                      │
                      └─ Dipole coupling

  Matrix elements:
  H^ext_nm = E·r_nm

  Relation:
  r_nm = i p_nm/(E_n - E_m)  (n≠m)

  ┌─────────────────────────────────────┐
  │ Pros:                               │
  │ ✓ Simpler (no diamagnetic term)     │
  │ ✓ Direct physical interpretation    │
  │ ✓ Easier to implement               │
  │                                     │
  │ Cons:                               │
  │ ✗ Breaks translational invariance   │
  │ ✗ Only valid for long wavelengths   │
  └─────────────────────────────────────┘


GAUGE EQUIVALENCE
─────────────────
  Physical observables are gauge-independent:

  Velocity gauge:        Length gauge:
  J_v = -e Σ f_n v_n    J_l = -e Σ f_n v_n
  P_v = ∫ J_v dt        P_l = -e Σ f_n r_n

  Relation: P_v(t) = P_l(t) + e·A(t)·N_el
```

### Field Coupling Diagram

```
┌────────────────────────────────────────────────────────────┐
│  External Field Coupling                                   │
└────────────────────────────────────────────────────────────┘

Electromagnetic Field
        │
        ├─ E(t): Electric field
        └─ A(t): Vector potential
               │
               │ Gauge choice
               │
        ┌──────┴──────┐
        │             │
        ▼             ▼
  ┌──────────┐  ┌──────────┐
  │ Velocity │  │  Length  │
  │  Gauge   │  │  Gauge   │
  └──────────┘  └──────────┘
        │             │
        ▼             ▼
  ┌──────────┐  ┌──────────┐
  │ H = A·p  │  │ H = E·r  │
  │  + A²/2  │  │          │
  └──────────┘  └──────────┘
        │             │
        └──────┬──────┘
               │
               ▼
        ┌──────────────┐
        │ Same physics │
        │ Different    │
        │ numerics     │
        └──────────────┘
```

---

## 6. Observable Computation

### Current Calculation Flow

```
┌────────────────────────────────────────────────────────────┐
│  Current Density Computation                               │
└────────────────────────────────────────────────────────────┘

                G^<_nm(k,t)
                     │
                     ▼
        ┌────────────────────────┐
        │ Extract occupations    │
        │ f_n(k,t) = Im[G^<_nn]  │
        └────────────────────────┘
                     │
                     ▼
        ┌────────────────────────┐
        │ Load velocity matrix   │
        │ v_nm(k) or p_nm(k)     │
        └────────────────────────┘
                     │
                     ▼
        ┌────────────────────────┐
        │ Compute current        │
        │ J = -e Σ_nk f_n v_n    │
        └────────────────────────┘
                     │
                     ├─ Diagonal contribution
                     │  J_diag = -e Σ_n f_nn v_nn
                     │
                     └─ Off-diagonal contribution
                        J_off = -e Σ_{n≠m} f_nm v_mn
                     │
                     ▼
        ┌────────────────────────┐
        │ Add diamagnetic term   │
        │ (velocity gauge only)  │
        │ J → J + e·A·N_el       │
        └────────────────────────┘
                     │
                     ▼
        ┌────────────────────────┐
        │ Sum over k-points      │
        │ J_tot = Σ_k J(k)       │
        └────────────────────────┘
                     │
                     ▼
              J(t) [3 components]
```

### Observable Hierarchy

```
┌────────────────────────────────────────────────────────────┐
│  Observable Computation Hierarchy                          │
└────────────────────────────────────────────────────────────┘

                  G^<(t)
                     │
        ┌────────────┼────────────┐
        │            │            │
        ▼            ▼            ▼
  ┌──────────┐ ┌──────────┐ ┌──────────┐
  │Diagonal  │ │Off-diag  │ │ Density  │
  │elements  │ │elements  │ │ matrix   │
  └──────────┘ └──────────┘ └──────────┘
        │            │            │
        ▼            ▼            ▼
  ┌──────────┐ ┌──────────┐ ┌──────────┐
  │Occupat.  │ │Coherences│ │ ρ(r,t)   │
  │f_n(k,t)  │ │ρ_nm(k,t) │ │          │
  └──────────┘ └──────────┘ └──────────┘
        │            │            │
        ├────────────┼────────────┤
        │            │            │
        ▼            ▼            ▼
  ┌──────────┐ ┌──────────┐ ┌──────────┐
  │• Carrier │ │• Current │ │• Energy  │
  │  popul.  │ │  J(t)    │ │  E(t)    │
  │• Entropy │ │• Polar.  │ │• Hartree │
  │  S(t)    │ │  P(t)    │ │  V^H(t)  │
  │• Temp.   │ │          │ │• XC      │
  │  T(t)    │ │          │ │  V^xc(t) │
  └──────────┘ └──────────┘ └──────────┘
```

---

## 7. Memory Management

### Circular Buffer Structure

```
┌────────────────────────────────────────────────────────────┐
│  Circular Buffer for Time-Dependent Quantities             │
└────────────────────────────────────────────────────────────┘

Time steps:  t-4   t-3   t-2   t-1    t    t+1
             │     │     │     │     │     │
Memory:     [  1  ][  2  ][  3  ][  4  ][  5  ]
             │     │     │     │     │
             │     │     │     │     └─ i_MEM_now = 5
             │     │     │     └─────── i_MEM_prev = 4
             │     │     └─────────────  i_MEM_old = 3
             │     └───────────────────  (for RK4)
             └─────────────────────────  (oldest)

After one step (t → t+1):
             │     │     │     │     │     │
Memory:     [t+1  ][  2  ][  3  ][  4  ][  t  ]
             │                         │
             └─ Overwrite oldest ──────┘

Mapping:
  i_MEM_now  = mod(i_time, G_MEM_steps) + 1
  i_MEM_prev = mod(i_time-1, G_MEM_steps) + 1
  i_MEM_old  = mod(i_time-2, G_MEM_steps) + 1

Typical G_MEM_steps:
  • EULER/EXP: 2-3 (current + previous)
  • RK4: 4-5 (intermediate steps)
  • With memory integrals: 10-20
```

### Memory Layout

```
┌────────────────────────────────────────────────────────────┐
│  Data Structure Memory Layout                              │
└────────────────────────────────────────────────────────────┘

G_lesser(nb1:nb2, nb1:nb2, nk, nsp, nmem)
│         │       │        │   │    │
│         │       │        │   │    └─ Time steps (circular)
│         │       │        │   └────── Spin polarizations
│         │       │        └────────── k-points
│         │       └─────────────────── Band index (column)
│         └─────────────────────────── Band index (row)

Typical sizes:
  nb = 20 bands
  nk = 100 k-points
  nsp = 1 (non-magnetic) or 2 (magnetic)
  nmem = 5 time steps

Memory per time step:
  20 × 20 × 100 × 1 × 8 bytes (complex) = 640 KB

Total memory:
  640 KB × 5 = 3.2 MB

For large systems (nb=100, nk=1000):
  100 × 100 × 1000 × 1 × 8 bytes × 5 = 400 MB
```

---

## 8. Data Flow Diagrams

### Complete Data Flow

```
┌────────────────────────────────────────────────────────────┐
│  YAMBO RT Data Flow                                        │
└────────────────────────────────────────────────────────────┘

INPUT FILES                    MEMORY                    OUTPUT FILES
───────────                    ──────                    ────────────

┌──────────┐                                            ┌──────────┐
│ DFT/GW   │                                            │ Current  │
│ Database │──┐                                      ┌─→│ J(t)     │
└──────────┘  │                                      │  └──────────┘
              │                                      │
┌──────────┐  │    ┌────────────────────────┐        │  ┌──────────┐
│ Wave-    │  ├───→│  G^<(t)                │────────┼─→│ Polariz. │
│ functions│  │    │  [nb×nb×nk×nsp×nmem]   │        │  │ P(t)     │
└──────────┘  │    └────────────────────────┘        │  └──────────┘
              │              │                       │
┌──────────┐  │              ▼                       │ ┌──────────┐
│ Input    │  │    ┌────────────────────────┐        │ │ Energy   │
│ Parameters│─┘    │  H^RT(t)               │        ├→│ E(t)     │
└──────────┘       │  [nb×nb×nk×nsp]        │        │ └──────────┘
                   └────────────────────────┘        │
                             │                       │  ┌──────────┐
                             ▼                       │  │ Occupat. │
                   ┌────────────────────────┐        ├─→│ f_n(k,t) │
                   │  ρ(r,t)                │        │  └──────────┘
                   │  [fft_size]            │        │
                   └────────────────────────┘        │  ┌──────────┐
                             │                       │  │ Entropy  │
                             ▼                       ├─→│ S(t)     │
                   ┌────────────────────────┐        │  └──────────┘
                   │  V^H(r,t), V^xc(r,t)   │        │
                   │  [fft_size]            │        │  ┌──────────┐
                   └────────────────────────┘        └─→│ Restart  │
                                                        │ Database │
                                                        └──────────┘

Data flow per time step:
1. G^<(t) → ρ(r,t)           [FFT, ~10 MB/s]
2. ρ(r,t) → V^H, V^xc        [Poisson, XC functional]
3. V^H, V^xc → H^RT          [Matrix elements]
4. H^RT, G^<(t) → G^<(t+Δt)  [Time integration]
5. G^<(t+Δt) → Observables   [Trace operations]
```

### Parallel Distribution

```
┌────────────────────────────────────────────────────────────┐
│  MPI Parallelization Strategy                              │
└────────────────────────────────────────────────────────────┘

                    Total System
                         │
        ┌──────────────────────┼────────────────────┐
        │                      │                    │
        ▼                      ▼                    ▼
   ┌────────┐              ┌────────┐            ┌────────┐
   │ Rank 0 │              │ Rank 1 │            │ Rank N │
   └────────┘              └────────┘            └────────┘
        │                      │                      │
        ├─ k-points: 1-10      ├─ k-points: 1-10      ├─ k-points: 1-10 
        ├─ Bands: all          ├─ Bands: all          ├─ Bands: all     
        └─ G-vectors: all      └─ G-vectors: all      └─ G-vectors: all 

Each rank:
  1. Computes local G^<(k,t) for assigned k-points
  2. Computes local contribution to ρ(r,t)
  3. Reduces ρ(r,t) across all ranks (MPI_Allreduce)
  4. Computes V^H, V^xc (replicated on all ranks)
  5. Builds local H^RT(k,t)
  6. Propagates local G^<(k,t) → G^<(k,t+Δt)
  7. Computes local observables
  8. Reduces observables (MPI_Reduce to master)

Communication pattern:
  • All-reduce for density: O(fft_size)
  • Reduce for observables: O(1)
  • No communication during time integration
```

---

## Appendix: Symbol Legend

```
┌────────────────────────────────────────────────────────────┐
│  Symbol Reference                                          │
└────────────────────────────────────────────────────────────┘

G^<(t)      Lesser Green's function (density matrix)
H^RT(t)     Time-dependent RT Hamiltonian
H^EQ        Equilibrium Hamiltonian
ΔΣ^Hxc      Mean-field self-energy variation
Σ^scatt     Collision self-energy
f_n(k,t)    Occupation factor of state n at k
ρ_nm(k,t)   Off-diagonal density matrix element
ρ(r,t)      Electron density in real space
V^H(r,t)    Hartree potential
V^xc(r,t)   Exchange-correlation potential
A(t)        Vector potential (velocity gauge)
E(t)        Electric field (length gauge)
J(t)        Current density
P(t)        Polarization
p_nm        Momentum matrix element
v_nm        Velocity matrix element
r_nm        Position matrix element
ψ_nk(r)     Wavefunction of state n at k
E_n(k)      Band energy
Δt          Time step
```

---
