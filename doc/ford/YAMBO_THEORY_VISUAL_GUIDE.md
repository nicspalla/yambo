---
title: YAMBO THEORY VISUAL GUIDE
---

# YAMBO Theory Visual Guide {#yambo_theory_visual}

**Diagrams, flowcharts, and visual representations of YAMBO's theoretical framework**

---

## Table of Contents

1. [System Overview](#system-overview)
2. [Basis Set Visualization](#basis-set-visualization)
3. [GW Calculation Flow](#gw-calculation-flow)
4. [BSE Calculation Flow](#bse-calculation-flow)
5. [Symmetry Operations](#symmetry-operations)
6. [Data Structures](#data-structures)

---

## 1. System Overview

### YAMBO Workflow

```
┌─────────────────────────────────────────────────────────────────┐
│                     DFT CALCULATION                             │
│              (Quantum ESPRESSO, ABINIT, etc.)                   │
│                                                                 │
│  Output: Wavefunctions ψ_{n,k}, Eigenvalues ε_{n,k}             │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                    YAMBO INITIALIZATION                         │
│                                                                 │
│  • Read wavefunctions and setup                                 │
│  • Build k-point tables and symmetries                          │
│  • Setup G-vector grids                                         │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
         ┌───────────────┴───────────────┐
         │                               │
         ▼                               ▼
┌──────────────────┐           ┌──────────────────┐
│  GW CALCULATION  │           │  BSE CALCULATION │
│                  │           │                  │
│  1. Polarization │           │  1. Read QP or   │
│     χ₀(q,ω)      │           │     use DFT      │
│                  │           │                  │
│  2. Screening    │           │  2. Oscillators  │
│     W = ε⁻¹v     │           │     ρ_{vc}       │
│                  │           │                  │
│  3. Self-Energy  │           │  3. BSE Kernel   │
│     Σ = iGW      │           │     K = K^x+K^d  │
│                  │           │                  │
│  4. QP Energies  │───────────▶  4. Solve BSE    │
│     E^{QP}       │ (optional)│     HA = ΩA      │
│                  │           │                  │
└──────────────────┘           │  5. Optical      │
                               │     Spectrum     │
                               └──────────────────┘
```

### Many-Body Perturbation Theory Hierarchy

```
                    ┌─────────────────────┐
                    │   Exact Solution    │
                    │  (Intractable)      │
                    └──────────┬──────────┘
                               │
                               ▼
                    ┌─────────────────────┐
                    │  Many-Body Green's  │
                    │    Function G       │
                    └──────────┬──────────┘
                               │
                ┌──────────────┴──────────────┐
                │                             │
                ▼                             ▼
     ┌────────────────────┐        ┌────────────────────┐
     │  GW Approximation  │        │  Bethe-Salpeter    │
     │                    │        │     Equation       │
     │  Σ = iGW           │        │                    │
     │  W = ε⁻¹v          │        │  Two-particle      │
     │                    │        │  excitations       │
     │  Quasiparticles    │        │                    │
     └────────────────────┘        └────────────────────┘
                │                             │
                ▼                             ▼
     ┌────────────────────┐        ┌────────────────────┐
     │  Band Structure    │        │  Optical Spectra   │
     │  Band Gaps         │        │  Excitons          │
     │  Lifetimes         │        │  Absorption        │
     └────────────────────┘        └────────────────────┘
```

---

## 2. Basis Set Visualization

### Plane-Wave Expansion

```
Real Space                    Reciprocal Space
                             
    ψ(r)                          c(G)
     │                             │
     │  FFT ←──────────────────→   │
     │                             │
     ▼                             ▼
                             
┌─────────────┐              ┌─────────────┐
│   ●   ●   ● │              │  ●          │
│ ●   ●   ●   │              │    ●    ●   │
│   ●   ●   ● │              │  ●    ●     │
│ ●   ●   ●   │              │      ●   ●  │
│   ●   ●   ● │              │  ●       ●  │
└─────────────┘              └─────────────┘
 Real-space grid              G-vector grid
 (fft_size points)            (wf_ng vectors)
```

### Wavefunction at k-point

```
ψ_{n,k}(r) = (1/√Ω) Σ_G c_{n,k}(G) e^{i(k+G)·r}
             
             ┌─────────────────────────────────┐
             │  Plane-wave coefficients        │
             │  c_{n,k}(G)                     │
             │                                 │
             │  Stored in: WF%c(ig,ib,ik)      │
             │                                 │
             │  ig: G-vector index (1:wf_ng)   │
             │  ib: Band index                 │
             │  ik: k-point index              │
             └─────────────────────────────────┘
                          │
                          │ FFT
                          ▼
             ┌─────────────────────────────────┐
             │  Real-space wavefunction        │
             │  ψ_{n,k}(r)                     │
             │                                 │
             │  On FFT grid (fft_size points)  │
             └─────────────────────────────────┘
```

### G-Vector Sphere

```
                    k_z
                     │
                     │    ● ● ●
                     │  ● ● ● ● ●
                     │● ● ● ● ● ● ●
                    / ●─●─●─●─●─●─●─── k_y
                   / │ ● ● ● ● ●
                  /  │   ● ● ●
                 /   │
              k_x
              
    Cutoff sphere: |k+G|²/2 ≤ E_cut
    
    • Each dot represents a G-vector
    • Sphere radius determined by E_cut
    • Number of G-vectors: wf_ng
```

### Oscillator Strength Calculation

```
ρ_{nm}(k,q,G) = ⟨n,k|e^{-i(q+G)·r}|m,k+q⟩

Step 1: Load wavefunctions
┌──────────────┐         ┌──────────────┐
│ ψ_n(k)       │         │ ψ_m(k+q)     │
│ c_n(G')      │         │ c_m(G'+G)    │
└──────┬───────┘         └──────┬───────┘
       │                        │
       │  Transform to          │
       │  real space (FFT)      │
       ▼                        ▼
┌──────────────┐         ┌──────────────┐
│ ψ_n(r)       │         │ ψ_m(r)       │
└──────┬───────┘         └──────┬───────┘
       │                        │
       │  Multiply and          │
       │  phase factor          │
       └────────┬───────────────┘
                │
                ▼
       ┌─────────────────┐
       │ ψ*_n(r) ψ_m(r)  │
       │ × e^{-i(q+G)·r} │
       └────────┬────────┘
                │
                │ FFT back
                ▼
       ┌─────────────────┐
       │  ρ_{nm}(k,q,G)  │
       │                 │
       │  Stored in:     │
       │  isc%rhotw(ig)  │
       └─────────────────┘
```

---

## 3. GW Calculation Flow

### Overall GW Scheme

```
┌─────────────────────────────────────────────────────────────┐
│                    INPUT: DFT Results                       │
│  • Wavefunctions ψ_{n,k}                                    │
│  • Eigenvalues ε_{n,k}                                      │
│  • Exchange-correlation potential V^{xc}                    │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│              STEP 1: Polarization Function                  │
│                                                             │
│  χ₀(q,G,G',ω) = Σ_{n,m,k} f_{n,k} - f_{m,k+q}               │
│                 ────────────────────────────                │
│                  ω - (ε_m - ε_n) + iη                       │
│                                                             │
│                 × ρ_{nm}(k,q,G) ρ*_{nm}(k,q,G')             │
│                                                             │
│  Implementation: X_irredux_residuals.F                      │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│              STEP 2: Dielectric Function                    │
│                                                             │
│  ε(q,G,G',ω) = δ_{GG'} - v_G(q) χ₀(q,G,G',ω)                │
│                                                             │
│  where v_G(q) = 4π/|q+G|²                                   │
│                                                             │
│  Implementation: X_dielectric_matrix.F                      │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│              STEP 3: Inverse Dielectric Function            │
│                                                             │
│  ε⁻¹(q,G,G',ω) = [ε(q,G,G',ω)]⁻¹                            │
│                                                             │
│  Matrix inversion (typically small matrices ~100×100)       │
│                                                             │
│  Stored in: X_par(iq)%blc(ig1,ig2,iw)                       │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│              STEP 4: Screened Interaction                   │
│                                                             │
│  W(q,G,G',ω) = Σ_{G''} ε⁻¹(q,G,G'',ω) v_{G''}(q) δ_{G''G'}  │
│              = ε⁻¹(q,G,G',ω) v_{G'}(q)                      │
│                                                             │
│  Plasmon-Pole Approximation:                                │
│  W(q,G,G',ω) = δ_{GG'} v_G(q) + Ω²/(ω² - ω₀² + iη)          │
│                                                             │
│  Implementation: QP_ppa_cohsex.F (lines 349-404)            │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│              STEP 5: Self-Energy                            │
│                                                             │
│  Σ_{n,k}(ω) = Σ_{m,q,G,G'} ρ*_{nm}(k,q,G)                   │
│                             × W(q,G,G',ω-ε_m)               │
│                             × ρ_{nm}(k,q,G')                │
│                             × f_m                           │
│                                                             │
│  Implementation: QP_ppa_cohsex.F (lines 650-750)            │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│              STEP 6: Quasiparticle Energies                 │
│                                                             │
│  E^{QP}_{n,k} = ε^{DFT}_{n,k}                               │
│               + ⟨n,k|Σ(E^{QP}_{n,k})|n,k⟩                   │
│               - ⟨n,k|V^{xc}|n,k⟩                            │
│                                                             │
│  Solve self-consistently (Newton/secant method)             │
│                                                             │
│  Implementation: QP_newton.F, QP_secant.F                   │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                    OUTPUT: QP Corrections                   │
│  • Quasiparticle energies E^{QP}_{n,k}                      │
│  • Band gaps                                                │
│  • Lifetimes (if real-axis)                                 │
│  • Stored in: ndb.QP database                               │
└─────────────────────────────────────────────────────────────┘
```

### Plasmon-Pole Approximation Detail

```
Full Frequency Dependence          Plasmon-Pole Model
                                   
W(ω)                               W(ω)
 │                                  │
 │  ╱╲                              │     ╱╲
 │ ╱  ╲                             │    ╱  ╲
 │╱    ╲___                         │   ╱    ╲
 │          ───___                  │  ╱      ╲
─┼──────────────────── ω           ─┼─╱────────╲─── ω
 │                                  │╱          ╲
 │                                  │            ╲
 │                                  │             ╲
 │                                  │              ╲
                                    │               ╲
                                   -ω₀      0      ω₀

Exact (expensive)                  Approximate (fast)
Requires full ω grid               Only 2 parameters: Ω², ω₀

Formula:
W(ω) = δ_{GG'} v_G + Ω²_{GG'}/(ω² - ω²_{GG'} + iη)

Determination:
From ε⁻¹(ω=0): ω_{GG'} = √[Ω²/(ε⁻¹(0) - 1)]
```

### Self-Energy Frequency Dependence

```
Σ(ω)
 │
 │     ╱
 │    ╱
 │   ╱
 │  ╱
 │ ╱
─┼╱────────────── ω
 │
 │
 
Slope at E^{DFT}: Z = [1 - ∂Σ/∂ω]⁻¹

Quasiparticle energy:
E^{QP} = E^{DFT} + Z[Σ(E^{QP}) - V^{xc}]

Linearized:
E^{QP} ≈ E^{DFT} + Σ(E^{DFT}) - V^{xc}
```

---

## 4. BSE Calculation Flow

### Overall BSE Scheme

```
┌─────────────────────────────────────────────────────────────┐
│                    INPUT: QP or DFT Results                 │
│  • Wavefunctions ψ_{n,k}                                    │
│  • Energies E_{n,k} (QP or DFT)                             │
│  • Screened interaction W (from GW or static)               │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│              STEP 1: Define Transition Space                │
│                                                             │
│  Transitions: |vck⟩ = |v,k⟩_e ⊗ |c,k⟩_h                     │
│                                                             │
│  v ∈ [v_min, v_max]: Valence bands                          │
│  c ∈ [c_min, c_max]: Conduction bands                       │
│  k ∈ IBZ: k-points                                          │
│                                                             │
│  Dimension: N_trans = N_v × N_c × N_k                       │
│                                                             │
│  Implementation: K_Transitions_setup.F                      │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│              STEP 2: Compute Oscillators                    │
│                                                             │
│  ρ_{vc}(k,q,G) = ⟨v,k|e^{-i(q+G)·r}|c,k+q⟩                  │
│                                                             │
│  For each transition (v,c,k):                               │
│    • Load wavefunctions ψ_v(k), ψ_c(k)                      │
│    • Transform to real space (FFT)                          │
│    • Multiply and apply phase                               │
│    • Transform back (FFT)                                   │
│                                                             │
│  Stored in: BS_blk(iblk)%O_c(ig,iT)                         │
│                                                             │
│  Implementation: scatter_Bamp.F                             │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│              STEP 3: Construct BSE Kernel                   │
│                                                             │
│  K_{vck,v'c'k'} = K^{exch} + K^{dir}                        │
│                                                             │
│  Exchange (attractive):                                     │
│  K^{exch} = -δ_{kk'} Σ_G v_G ρ_{vc}(G) ρ*_{v'c'}(G)         │
│                                                             │
│  Direct (screened):                                         │
│  K^{dir} = Σ_{GG'} ρ_{vc}(G) W_{GG'}(q) ρ*_{v'c'}(G')       │
│                                                             │
│  Implementation: K_kernel.F                                 │
│    • K_exchange_kernel.F                                    │
│    • K_correlation_kernel_std.F                             │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│              STEP 4: Add Diagonal (Resonant)                │
│                                                             │
│  R_{vck,v'c'k'} = (E_c - E_v) δ_{vv'} δ_{cc'} δ_{kk'}       │
│                 + K_{vck,v'c'k'}                            │
│                                                             │
│  Diagonal elements: E_c - E_v (transition energies)         │
│  Off-diagonal: Kernel K                                     │
│                                                             │
│  Implementation: K_diagonal.F                               │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│              STEP 5: Solve BSE Eigenvalue Problem           │
│                                                             │
│  Method 1: Direct Diagonalization                           │
│    R A = Ω A                                                │
│    Use LAPACK/ScaLAPACK                                     │
│    Implementation: K_diago_driver.F                         │
│                                                             │
│  Method 2: Haydock Recursion                                │
│    Iterative: |ψ_{n+1}⟩ = H|ψ_n⟩ - a_n|ψ_n⟩ - b_n|ψ_{n-1}⟩  │
│    No full matrix storage                                   │
│    Implementation: K_Haydock.F                              │
│                                                             │
│  Method 3: Inversion                                        │
│    ε(ω) = 1 - v χ = 1 - v(1-R)⁻¹χ₀                          │
│    Implementation: K_inversion_driver.F                     │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│              STEP 6: Compute Optical Spectrum               │
│                                                             |
│  ε_M(ω) = 1 - Σ_S |⟨S|ρ|0⟩|²/(ω - Ω^S + iη)                 │
│                                                             │
│  Oscillator strength:                                       │
│  |⟨S|ρ|0⟩|² = |Σ_{vck} A^S_{vck} ρ_{vc}(k,q→0)|²            │
│                                                             │
│  Implementation: K_observables.F                            │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                    OUTPUT: Optical Properties               │
│  • Excitation energies Ω^S                                  │
│  • Exciton wavefunctions A^S_{vck}                          │
│  • Absorption spectrum ε_M(ω)                               │
│  • Stored in: ndb.BS_diago, o.eps_q1_*                      │
└─────────────────────────────────────────────────────────────┘
```

### BSE Kernel Structure

```
Resonant Block (R)                Coupling Block (C)
                                 
    c'→                              c'→
v ┌─────────────┐              v ┌─────────────┐
│ │ ╲           │              │ │             │
↓ │   ╲         │              ↓ │             │
  │     ╲       │                │             │
  │       ╲     │                │             │
  │         ╲   │                │             │
  │           ╲ │                │             │
  └─────────────┘                └─────────────┘
  
  Diagonal: E_c - E_v            Electron-hole to
  Off-diagonal: K                hole-electron coupling

Full Matrix (with coupling):

┌                    ┐
│   R        C       │
│                    │
│   C*      -R*      │
└                    ┘

Dimension: 2 × N_trans

Tamm-Dancoff Approximation (TDA):
Set C = 0, solve only R block
Dimension: N_trans
```

### Kernel Matrix Elements

```
Exchange Term (K^{exch}):

  k ──v──●──c──                k' ──v'──●──c'──
         │                              │
         │ v_G(0)                       │
         │                              │
         ●──────────────────────────────●
         
  K^{exch}_{vck,v'c'k'} = -δ_{kk'} Σ_G v_G(0) ρ_{vc}(G) ρ*_{v'c'}(G)
  
  • Attractive (negative sign)
  • Local in k (δ_{kk'})
  • Bare Coulomb v_G = 4π/|G|²

Direct Term (K^{dir}):

  k ──v──●──c──                k' ──v'──●──c'──
         │                              │
         │ W(q,G,G')                    │
         │                              │
         ●──────────────────────────────●
         
  K^{dir}_{vck,v'c'k'} = Σ_{GG'} ρ_{vc}(k,q,G) W_{GG'}(q) ρ*_{v'c'}(k',q,G')
  
  • Repulsive (positive, reduces binding)
  • Non-local in k (q = k - k')
  • Screened interaction W
```

### Haydock Recursion Visualization

```
Iteration n=0:
|ψ₀⟩ = |initial state⟩ (e.g., dipole)

Iteration n=1:
|ψ₁⟩ = H|ψ₀⟩ - a₀|ψ₀⟩
a₀ = ⟨ψ₀|H|ψ₀⟩
b₁ = ||ψ₁||

Iteration n=2:
|ψ₂⟩ = H|ψ₁⟩ - a₁|ψ₁⟩ - b₁|ψ₀⟩
a₁ = ⟨ψ₁|H|ψ₁⟩
b₂ = ||ψ₂||

...

Continued Fraction:
ε(ω) = 1 - |d|²/[ω - a₀ - b²₁/(ω - a₁ - b²₂/(ω - a₂ - ...))]

Convergence:
  n=10      n=50      n=100     n=500
   │         │          │         │
   ▼         ▼          ▼         ▼
  ╱╲        ╱╲         ╱╲        ╱╲
 ╱  ╲      ╱  ╲       ╱  ╲      ╱  ╲
╱    ╲    ╱    ╲     ╱    ╲    ╱    ╲
      ╲  ╱      ╲   ╱      ╲  ╱      ╲
       ╲╱        ╲ ╱        ╲╱        ╲
Rough   Better   Good      Converged
```

---

## 5. Symmetry Operations

### Brillouin Zone and IBZ

```
Full Brillouin Zone (BZ)          Irreducible BZ (IBZ)
                                 
    ●─────●─────●─────●              ●─────●
    │     │     │     │              │    ╱
    ●─────●─────●─────●              │   ╱
    │     │     │     │              │  ╱
    ●─────●─────●─────●              │ ╱
    │     │     │     │              │╱
    ●─────●─────●─────●              ●
    
    N_k = 16 k-points                N_k = 3 k-points
    
    All k-points in BZ               Minimal set
                                     Others by symmetry
                                     
Reduction factor: N_BZ / N_IBZ = nsym (typically 8-48)
```

### Star of k-point

```
Given k-point k₀:

Star(k₀) = {S₁k₀, S₂k₀, ..., S_n k₀}

Example: k₀ = (0.25, 0, 0) in cubic system

         k_y
          │
    S₃k₀  │  S₂k₀
      ●   │   ●
          │
    ──────●──────── k_x  (k₀)
          │
      ●   │   ●
    S₄k₀  │  S₁k₀
          │
          
Star has 4 members (4-fold rotation)

Implementation:
• k%nstar(ik) = 4
• k%star(ik,1:4) = symmetry indices
```

### Symmetry Operation on Wavefunction

```
Original k-point:              Rotated k-point:
                              
ψ_{n,k}(r)                     ψ_{n,Sk}(r)
    │                              │
    │ Apply symmetry S             │
    │ with translation τ           │
    ▼                              ▼
                              
c_{n,k}(G)                     c_{n,Sk}(G)
    │                              │
    │                              │
    └──────────────────────────────┘
              │
              ▼
    c_{n,Sk}(G) = e^{iSk·τ} e^{iG·τ} c_{n,k}(S⁻¹G)
                  └────┬────┘ └──┬──┘ └────┬─────┘
                       │         │         │
                  k-phase   G-phase   Rotated coeff
                  
Implementation:
• g_rot(ig,is): Rotated G-vector index
• g_phs(ig,is): Phase factor e^{iG·τ}
• WF_phases: Additional k-dependent phases
```

### Time-Reversal Symmetry

```
Time-Reversal Operation:

k → -k
ψ_{n,k}(r) → ψ*_{n,-k}(r)

In reciprocal space:
c_{n,k}(G) → c*_{n,-k}(-G)

Symmetry doubling:
Without TR: nsym = sp_nsym
With TR:    nsym = 2 × sp_nsym

Example:
Symmetries 1-24: Spatial operations
Symmetries 25-48: Spatial + TR

Implementation:
• i_time_rev = 1 (if present)
• Symmetries with is > nsym/(i_time_rev+1) include TR
```

### Symmetry Table

```
Symmetry Multiplication Table:

S_i × S_j = S_k

Example for C₄ᵥ (square):

    │ E  C₄ C₂ C₃  σᵥ σᵥ' σ_d σ_d'
────┼────────────────────────────────
 E  │ E  C₄ C₂ C₃  σᵥ σᵥ' σ_d σ_d'
 C₄ │ C₄ C₂ C₃ E   σ_d σ_d' σᵥ σᵥ'
 C₂ │ C₂ C₃ E  C₄  σᵥ' σᵥ σ_d' σ_d
 C₃ │ C₃ E  C₄ C₂  σ_d' σ_d σᵥ' σᵥ
 σᵥ │ σᵥ σ_d' σᵥ' σ_d E  C₂ C₄ C₃
 ...

Implementation:
• sop_tab(is1,is2) = is3
• sop_inv(is) = inverse symmetry
```

### Small Group of k

```
Full Symmetry Group              Small Group of k
                                
{S₁, S₂, ..., S_nsym}           {S_i | S_i k = k + G}
                                
All symmetries                   Subset leaving k invariant
                                
Example: k = (0, 0, 0) (Γ point)
Small group = Full group
                                
Example: k = (0.5, 0, 0) (X point)
Small group ⊂ Full group
(only symmetries preserving x-axis)

Implementation:
• grp_nsym(ik): Size of small group
• grp_table(ik,is_grp): Mapping to full list
```

---

## 6. Data Structures

### Wavefunction Storage

```
WF%c(ig, ib, ik)
     │   │   │
     │   │   └─ k-point index (1:nk)
     │   └───── Band index (1:nb)
     └───────── G-vector index (1:wf_ng)

Memory layout:
┌────────────────────────────────────────┐
│ k=1, b=1: [c(G₁), c(G₂), ..., c(G_ng)] │
│ k=1, b=2: [c(G₁), c(G₂), ..., c(G_ng)] │
│ ...                                    │
│ k=1, b=nb: [...]                       │
│ k=2, b=1: [...]                        │
│ ...                                    │
└────────────────────────────────────────┘

Size: wf_ng × nb × nk × sizeof(complex(SP))
Typical: 1000 × 100 × 100 × 8 bytes = 800 MB
```

### Response Function Storage

```
X_par(iq)%blc(ig1, ig2, iw)
              │    │    │
              │    │    └─ Frequency index
              │    └────── G' index
              └─────────── G index

For each q-point:
┌──────────────────────────────────────┐
│ ω=1: [ε⁻¹(G₁,G'₁), ε⁻¹(G₁,G'₂), ...] │
│ ω=2: [ε⁻¹(G₁,G'₁), ε⁻¹(G₁,G'₂), ...] │
│ ...                                  │
└──────────────────────────────────────┘

Size per q: ng × ng × nw × sizeof(complex(SP))
Typical: 100 × 100 × 2 × 8 bytes = 160 KB (PPA)
         100 × 100 × 100 × 8 bytes = 8 MB (full ω)
```

### BSE Kernel Storage

```
BS_blk(iblk)%mat(iT1, iT2)
                  │    │
                  │    └─ Transition 2 index
                  └────── Transition 1 index

Transition index:
iT = (v-v_min) + (c-c_min)×N_v + (k-1)×N_v×N_c

Full matrix:
┌────────────────────────────────────┐
│ R₁₁  R₁₂  R₁₃  ...  R₁ₙ            │
│ R₂₁  R₂₂  R₂₃  ...  R₂ₙ            │
│ R₃₁  R₃₂  R₃₃  ...  R₃ₙ            │
│ ...                                │
│ Rₙ₁  Rₙ₂  Rₙ₃  ...  Rₙₙ              │
└────────────────────────────────────┘

Size: N_trans × N_trans × sizeof(complex(SP))
Typical: 10000 × 10000 × 8 bytes = 800 MB
Large systems: Can be TB!

Storage modes:
• Full matrix (small systems)
• Block-diagonal (medium)
• On-the-fly (large, Haydock)
```

### Oscillator Storage

```
BS_blk(iblk)%O_c(ig, iT)
                 │   │
                 │   └─ Transition index
                 └───── G-vector index

For each transition:
ρ_{vc}(k,q,G) for all G

┌────────────────────────────────────┐
│ T=1: [ρ(G₁), ρ(G₂), ..., ρ(G_ng)]  │
│ T=2: [ρ(G₁), ρ(G₂), ..., ρ(G_ng)]  │
│ ...                                │
│ T=N_trans: [...]                   │
└────────────────────────────────────┘

Size: ng × N_trans × sizeof(complex(SP))
Typical: 1000 × 10000 × 8 bytes = 80 MB
```

### k-Point Sampling Structure

```
type bz_samp
  integer :: nibz, nbz
  real(SP), allocatable :: pt(:,:)      ! IBZ k-points
  real(SP), allocatable :: ptbz(:,:)    ! BZ k-points
  integer, allocatable :: nstar(:)      ! Star size
  integer, allocatable :: star(:,:)     ! Star members
  integer, allocatable :: sstar(:,:)    ! BZ→IBZ map
  real(SP), allocatable :: weights(:)   ! k-weights
end type

Memory layout:
┌────────────────────────────────────┐
│ IBZ k-points:                      │
│ k₁ = (k₁ₓ, k₁ᵧ, k₁ᵤ)               │
│ k₂ = (k₂ₓ, k₂ᵧ, k₂ᵤ)               │
│ ...                                │
│                                    │
│ BZ k-points:                       │
│ k₁ᴮᶻ = (k₁ₓ, k₁ᵧ, k₁ᵤ)             │
│ k₂ᴮᶻ = (k₂ₓ, k₂ᵧ, k₂ᵤ)             │
│ ...                                │
│                                    │
│ Mapping:                           │
│ sstar(ikbz,1) = ik_ibz             │
│ sstar(ikbz,2) = is_symm            │
└────────────────────────────────────┘
```

### Symmetry Data Structure

```
Symmetry operations:

dl_sop(3, 3, is)  - Real space
rl_sop(3, 3, is)  - Reciprocal space
dl_tra(3, is)     - Translations

Example: C₄ rotation around z-axis

dl_sop(:,:,is) = │ 0 -1  0 │
                 │ 1  0  0 │
                 │ 0  0  1 │

rl_sop(:,:,is) = │ 0  1  0 │
                 │-1  0  0 │
                 │ 0  0  1 │

dl_tra(:,is) = (0, 0, 0)  - No translation

For non-symmorphic:
dl_tra(:,is) = (τₓ, τᵧ, τᵤ)  - Fractional translation
```

---

## Summary Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    YAMBO Theory Stack                       │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌────────────────────────────────────────────────────┐     │
│  │              Optical Properties                    │     │
│  │  • Absorption spectra                              │     │
│  │  • Excitons                                        │     │
│  │  • EELS                                            │     │
│  └──────────────────┬─────────────────────────────────┘     │
│                     │                                       │
│  ┌──────────────────┴─────────────────────────────────┐     │
│  │         Bethe-Salpeter Equation (BSE)              │     │
│  │  • Two-particle excitations                        │     │
│  │  • Electron-hole interaction                       │     │
│  │  • K = K^{exch} + K^{dir}                          │     │
│  └──────────────────┬─────────────────────────────────┘     │
│                     │                                       │
│  ┌──────────────────┴─────────────────────────────────┐     │
│  │         Quasiparticle Energies (GW)                │     │
│  │  • Band structure corrections                      │     │
│  │  • Band gaps                                       │     │
│  │  • E^{QP} = E^{DFT} + Σ - V^{xc}                   │     │
│  └──────────────────┬─────────────────────────────────┘     │
│                     │                                       │
│  ┌──────────────────┴─────────────────────────────────┐     │
│  │         Screened Interaction (W)                   │     │
│  │  • W = ε⁻¹ v                                       │     │
│  │  • Plasmon-pole approximation                      │     │
│  │  • Static screening (COHSEX)                       │     │
│  └──────────────────┬─────────────────────────────────┘     │
│                     │                                       │
│  ┌──────────────────┴─────────────────────────────────┐     │
│  │         Polarization Function (χ₀)                 │     │
│  │  • Independent-particle response                   │     │
│  │  • Oscillator strengths                            │     │
│  │  • Sum over transitions                            │     │
│  └──────────────────┬─────────────────────────────────┘     │
│                     │                                       │
│  ┌──────────────────┴─────────────────────────────────┐     │
│  │         DFT Wavefunctions & Eigenvalues            │     │
│  │  • Plane-wave basis                                │     │
│  │  • Bloch states ψ_{n,k}                            │     │
│  │  • Kohn-Sham energies ε_{n,k}                      │     │
│  └────────────────────────────────────────────────────┘     │
│                                                             │
│  ┌────────────────────────────────────────────────────┐     │
│  │         Symmetries & k-point Sampling              │     │
│  │  • Crystal symmetries                              │     │
│  │  • IBZ reduction                                   |     │
│  │  • Time-reversal                                   |     │
│  └────────────────────────────────────────────────────┘     │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

**End of Visual Guide**