# YAMBO Theory Documentation: GW, BSE, Basis Sets, and Symmetries {#yambo_theory_doc}

@page yambo_theory_doc YAMBO Theory Documentation

**Version:** 1.0  
**Date:** 2025  
**Author:** Generated from YAMBO source code analysis

@tableofcontents

---

## Table of Contents

1. [Introduction](#introduction)
2. [Basis Sets in YAMBO](#basis-sets-in-yambo)
3. [GW Approximation](#gw-approximation)
4. [Bethe-Salpeter Equation (BSE)](#bethe-salpeter-equation-bse)
5. [Symmetry Operations](#symmetry-operations)
6. [Implementation Details](#implementation-details)
7. [References](#references)

---

## 1. Introduction

YAMBO implements many-body perturbation theory (MBPT) methods for calculating electronic and optical properties of materials from first principles. This document provides a comprehensive overview of the theoretical formulas and their implementation in the code.

### Key Approximations

- **GW Approximation**: Quasiparticle energies and lifetimes
- **Bethe-Salpeter Equation**: Optical absorption including excitonic effects
- **Plane-Wave Basis**: Expansion of wavefunctions and response functions
- **Symmetry Exploitation**: Reduction of computational cost using crystal symmetries

---

## 2. Basis Sets in YAMBO

### 2.1 Plane-Wave Basis

YAMBO uses a **plane-wave basis set** for representing electronic wavefunctions and response functions. This is inherited from the underlying DFT calculation (typically from Quantum ESPRESSO, ABINIT, or other codes).

#### Wavefunction Expansion

The single-particle wavefunctions are expanded in plane waves:

```
ψ_{n,k}(r) = (1/√Ω) Σ_G c_{n,k}(G) e^{i(k+G)·r}
```

Where:
- `ψ_{n,k}(r)` = Bloch wavefunction for band `n` at k-point `k`
- `Ω` = Unit cell volume
- `G` = Reciprocal lattice vectors
- `c_{n,k}(G)` = Plane-wave coefficients
- `k` = Crystal momentum (k-point)

**Implementation:**
- Module: `mod_wave_func.F`
- Type: `WAVEs`
- Storage: `WF%c(ig,ib,ik)` where `ig` is G-vector index, `ib` is band, `ik` is k-point

```fortran
type WAVEs 
  integer              :: b(2)      ! band range 
  integer              :: k(2)      ! k range
  integer              :: sp_pol(2) ! spin polarization range
  integer              :: N         ! number of states 
  character(1)         :: space     ! 'G' (reciprocal) or 'R' (real)
  complex(SP), allocatable :: c(:,:,:)  ! wavefunction coefficients
  integer    , allocatable :: index(:,:,:)
  logical    , allocatable :: state(:,:,:)
end type WAVEs
```

### 2.2 G-Vector Cutoff

The plane-wave expansion is truncated at a kinetic energy cutoff:

```
|k + G|² / 2 ≤ E_cut
```

**Key Parameters:**
- `wf_ng`: Number of G-vectors for wavefunctions in IBZ
- `wf_ng_1st_BZ`: Number of G-vectors in first BZ
- `wf_ncx`: Maximum number of components
- `wf_igk(ig,ik)`: Table mapping G-vector index to component index at k-point

**Implementation:**
```fortran
! From mod_wave_func.F
integer :: wf_ng          ! For WFs in the IBZ
integer :: wf_ng_1st_BZ   ! For WFs in the 1st BZ
integer :: wf_ncx         ! Max Num. of COMPONENTS
integer, allocatable :: wf_igk(:,:)  ! G-vec <-> Components table
integer, allocatable :: wf_nc_k(:)   ! Num. of components at each k
```

### 2.3 Reciprocal Lattice

The reciprocal lattice vectors are defined by:

```
b_i · a_j = 2π δ_{ij}
```

Where `a_i` are the real-space lattice vectors.

**Implementation:**
- Module: `mod_R_lattice.F`
- Variables:
  - `b(3,3)`: Reciprocal lattice vectors
  - `g_vec(ig,3)`: G-vector coordinates
  - `ng_vec`: Total number of G-vectors
  - `ng_closed`: Number of G-vectors in closed shell
  - `n_g_shells`: Number of G-shells

```fortran
! From mod_R_lattice.F
real(SP) :: b(3,3)                    ! Reciprocal lattice vectors
real(SP), allocatable :: g_vec(:,:)   ! G-vector coordinates
integer :: ng_vec                     ! Number of G-vectors
integer :: n_g_shells                 ! Number of G-shells
integer, allocatable :: ng_in_shell(:) ! Number of G in each shell
real(SP), allocatable :: E_of_shell(:) ! Energy of each shell
```

### 2.4 Real-Space Representation

Wavefunctions can be transformed to real space via FFT:

```
ψ_{n,k}(r) = FFT[c_{n,k}(G)]
```

**Implementation:**
- Subroutine: `scatter_Bamp` in `scatter_Bamp.F`
- FFT routines in `src/wf_and_fft/`
- Space indicator: `WF%space = 'R'` (real) or `'G'` (reciprocal)

### 2.5 Oscillator Strengths

Transition matrix elements (oscillators) between states are computed as:

```
ρ_{nm}(k,q,G) = ⟨n,k|e^{-i(q+G)·r}|m,k+q⟩
             = Σ_G' c*_{n,k}(G') c_{m,k+q}(G'+G)
```

These are fundamental building blocks for:
- Polarization function (GW)
- BSE kernel matrix elements
- Optical matrix elements

**Implementation:**
- Subroutine: `scatter_Bamp` computes oscillators via FFT
- Storage: `elemental_collision%rhotw(ig)` for density oscillators
- Module: `mod_collision_el.F`

---

## 3. GW Approximation

### 3.1 Theoretical Background

The GW approximation provides quasiparticle (QP) energies by including electron-electron interactions beyond mean-field DFT.

#### Quasiparticle Equation

```
[T + V_ext + V_H] ψ_{n,k} + ∫ Σ(r,r',E_{n,k}) ψ_{n,k}(r') dr' = E_{n,k} ψ_{n,k}(r)
```

Where:
- `T` = Kinetic energy operator
- `V_ext` = External potential (nuclei)
- `V_H` = Hartree potential
- `Σ(r,r',ω)` = Self-energy operator (non-local, energy-dependent)
- `E_{n,k}` = Quasiparticle energy

### 3.2 Self-Energy in GW

The self-energy in the GW approximation is:

```
Σ(r,r',ω) = i/(2π) ∫ G(r,r',ω+ω') W(r,r',ω') e^{iω'η} dω'
```

Where:
- `G(r,r',ω)` = Green's function
- `W(r,r',ω)` = Screened Coulomb interaction
- `η` = Infinitesimal positive number

#### Screened Interaction

```
W(r,r',ω) = ∫ ε^{-1}(r,r'',ω) v(r'',r') dr''
```

Where:
- `ε^{-1}(r,r',ω)` = Inverse dielectric function
- `v(r,r')` = Bare Coulomb interaction = `1/|r-r'|`

### 3.3 Matrix Elements

In plane-wave basis, the self-energy matrix element is:

```
⟨n,k|Σ(ω)|n,k⟩ = Σ_{m,q} Σ_{G,G'} M_{nm}^{GG'}(k,q,ω)
```

Where:

```
M_{nm}^{GG'}(k,q,ω) = ρ*_{nm}(k,q,G) W_{GG'}(q,ω) ρ_{nm}(k,q,G')
```

With:
- `ρ_{nm}(k,q,G)` = Oscillator strength (see Section 2.5)
- `W_{GG'}(q,ω)` = Screened interaction in reciprocal space

### 3.4 Plasmon-Pole Approximation (PPA)

To avoid expensive frequency integration, YAMBO uses the plasmon-pole approximation:

```
W_{GG'}(q,ω) = δ_{GG'} v_G(q) + [Ω_{GG'}(q)]² / [ω² - [ω_{GG'}(q)]² + iη]
```

Where:
- `Ω_{GG'}(q)` = Plasmon-pole strength (residue)
- `ω_{GG'}(q)` = Plasmon-pole energy
- `v_G(q) = 4π/|q+G|²` = Bare Coulomb interaction

**Determination of Poles:**

From static screening `ε^{-1}_{GG'}(q,ω=0)`:

```
ω_{GG'}(q) = √[Ω_{GG'}(q) / ε^{-1}_{GG'}(q,0) - 1]
```

**Implementation:**
- File: `QP_ppa_cohsex.F`
- Lines 349-383: Pole calculation
- Variables:
  - `X_ppaE`: Plasmon-pole energy
  - `X_par(iq)%blc(ig1,ig2,1)`: Residue `Ω²`
  - `X_par(iq)%blc(ig1,ig2,2)`: Pole energy `ω`

```fortran
! From QP_ppa_cohsex.F, lines 365-377
if (real(X_par(iq_mem)%blc(ig1,ig2,X_range1)/X_par(iq_mem)%blc(ig1,ig2,X_range2))<=1._SP) then
  ! PP condition fails: use fixed pole
  X_par(iq_mem)%blc(ig1,ig2,X_range2)=X_ppaE
else
  ! Calculate pole from residue and static screening
  X_par(iq_mem)%blc(ig1,ig2,X_range2)=sqrt(X_par(iq_mem)%blc(ig1,ig2,X_range1)/&
                                           X_par(iq_mem)%blc(ig1,ig2,X_range2)-1)
endif
```

### 3.5 Correlation Self-Energy

The correlation part of the self-energy:

```
Σ^c_{n,k}(ω) = Σ_{m,q} Σ_{G,G'} ρ*_{nm}(k,q,G) [W_{GG'}(q,ω-ε_m) - v_G(q)δ_{GG'}] ρ_{nm}(k,q,G') f_m
```

Where:
- `f_m` = Occupation factor (Fermi-Dirac)
- `ε_m` = DFT eigenvalue of state `m`

**Plasmon-Pole Form:**

```
Σ^c_{n,k}(ω) = Σ_{m,q} Σ_{G,G'} ρ*_{nm}(k,q,G) Ω²_{GG'}(q) / [ω - ε_m - ω_{GG'}(q) + iη] ρ_{nm}(k,q,G') f_m
```

**Implementation:**
- File: `QP_ppa_cohsex.F`
- Lines 650-750: Main correlation loop
- Key formula at line ~700:

```fortran
! Correlation contribution
W_i = X_blc_p(ig1,ig2,X_range1) / (Sc_W(i_qp)%p(iw) - E_kmq - X_blc_p(ig1,ig2,X_range2) + cI*QP_G_damp)
```

### 3.6 Exchange Self-Energy

The exchange part (Fock term):

```
Σ^x_{n,k} = -Σ_{m,q} Σ_G ρ*_{nm}(k,q,G) v_G(q) ρ_{nm}(k,q,G) f_m
```

**Implementation:**
- File: `XCo_Hartree_Fock.F`
- Computed as part of exact exchange

### 3.7 COHSEX Approximation

Static approximation (ω=0):

**SEX (Screened Exchange):**
```
Σ^{SEX}_{n,k} = -Σ_{m,q} Σ_{G,G'} ρ*_{nm}(k,q,G) W_{GG'}(q,0) ρ_{nm}(k,q,G') f_m
```

**COH (Coulomb Hole):**
```
Σ^{COH}_{n,k} = (1/2) Σ_{m,q} Σ_{G,G'} ρ*_{nn}(k,0,G) [W_{GG'}(q,0) - v_G(q)δ_{GG'}] ρ_{nn}(k,0,G')
```

**Implementation:**
- File: `QP_ppa_cohsex.F`
- Lines 507-620: COHSEX calculation using completeness relation
- COH uses `q=0` and same band indices

### 3.8 Quasiparticle Energy Correction

First-order perturbation theory:

```
E^{QP}_{n,k} = ε^{DFT}_{n,k} + Z_{n,k} [⟨n,k|Σ(E^{QP}_{n,k})|n,k⟩ - V^{xc}_{n,k}]
```

Where:
- `Z_{n,k} = [1 - ∂Σ/∂ω|_{ω=E^{QP}}]^{-1}` = Renormalization factor
- `V^{xc}_{n,k} = ⟨n,k|V^{xc}|n,k⟩` = DFT exchange-correlation potential

**Linearized Form:**

```
E^{QP}_{n,k} ≈ ε^{DFT}_{n,k} + ⟨n,k|Σ(ε^{DFT}_{n,k})|n,k⟩ - V^{xc}_{n,k}
```

**Implementation:**
- File: `QP_newton.F`, `QP_secant.F`
- Solvers: Newton, secant, or Green's function methods
- Variable: `QP_Sc(i_qp,i_w)` stores self-energy on frequency grid

### 3.9 Real-Axis Integration

For full frequency-dependent calculations (no PPA):

```
Σ^c_{n,k}(ω) = (i/2π) ∫_{-∞}^{∞} Σ_{m,q,G,G'} ρ*_{nm}(k,q,G) W_{GG'}(q,ω') ρ_{nm}(k,q,G') / (ω - ε_m - ω' + iη) dω'
```

**Implementation:**
- File: `QP_real_axis.F`
- Requires full frequency-dependent `W(ω)` from response function calculation
- More accurate but computationally expensive

---

## 4. Bethe-Salpeter Equation (BSE)

### 4.1 Theoretical Background

The BSE describes optical excitations including electron-hole interactions (excitonic effects).

#### Two-Particle Hamiltonian

```
(E_c - E_v) A^S_{vck} + Σ_{v'c'k'} K_{vck,v'c'k'} A^S_{v'c'k'} = Ω^S A^S_{vck}
```

Where:
- `A^S_{vck}` = Exciton amplitude (S-th excited state)
- `E_c, E_v` = Quasiparticle energies (conduction, valence)
- `K_{vck,v'c'k'}` = BSE kernel (electron-hole interaction)
- `Ω^S` = Excitation energy

### 4.2 Transition Space

The BSE is solved in the space of electron-hole transitions:

```
|vck⟩ = |v,k⟩_electron ⊗ |c,k⟩_hole
```

**Indices:**
- `v, v'` = Valence band indices
- `c, c'` = Conduction band indices
- `k, k'` = k-points in the Brillouin zone

**Dimension:**
```
N_transitions = N_v × N_c × N_k
```

Where `N_v`, `N_c`, `N_k` are numbers of valence bands, conduction bands, and k-points.

**Implementation:**
- Module: `mod_BS.F`
- Type: `BS_T_group` for transition groups
- Variables:
  - `BS_K_dim`: Kernel dimension (number of transitions)
  - `BS_bands(1:2)`: Valence band range
  - `BS_bands(3:4)`: Conduction band range

### 4.3 BSE Kernel

The kernel has two main contributions:

```
K_{vck,v'c'k'} = K^{exch}_{vck,v'c'k'} + K^{dir}_{vck,v'c'k'}
```

#### Exchange (Attractive) Term

```
K^{exch}_{vck,v'c'k'} = -δ_{kk'} Σ_G v_G(0) ρ_{vc}(k,0,G) ρ*_{v'c'}(k',0,G)
```

Where:
- `v_G(0) = 4π/|G|²` = Bare Coulomb interaction at q=0
- `ρ_{vc}(k,0,G) = ⟨v,k|e^{-iG·r}|c,k⟩` = Oscillator strength

**Physical Interpretation:** Direct Coulomb attraction between electron and hole.

**Implementation:**
- File: `K_exchange_kernel.F`
- Function: `K_exchange_kernel`
- Formula (line 54):

```fortran
H_x = Σ_ig conjg(BS_T_grp_ip%O_x(ig,i_Tp)) * BS_T_grp_ik%O_x(ig,i_Tk) / bare_qpg(iq,ig)**2
```

Where:
- `O_x(ig,iT)` = Oscillator `ρ_{vc}(k,q,G)`
- `bare_qpg(iq,ig)` = `|q+G|` (Coulomb interaction)

#### Direct (Screened) Term

```
K^{dir}_{vck,v'c'k'} = Σ_{G,G'} ρ_{vc}(k,q,G) W_{GG'}(q,0) ρ*_{v'c'}(k',q,G')
```

Where:
- `q = k - k'` = Momentum transfer
- `W_{GG'}(q,0)` = Static screened Coulomb interaction

**Physical Interpretation:** Screened Coulomb repulsion between electron and hole (reduces binding).

**Implementation:**
- File: `K_correlation_kernel_std.F`
- Function: `K_correlation_kernel_std`
- Formula (line 100):

```fortran
K_correlation_kernel_std = Vstar_dot_V_gpu(BS_n_g_W, O2, O_times_W) * 4._SP * pi
```

Where:
- `O1, O2` = Oscillators with symmetry operations applied
- `O_times_W = W * O1` = Screened oscillator
- `4π` = Normalization factor

### 4.4 Resonant-Antiresonant Coupling

Full BSE includes coupling between resonant and antiresonant parts:

```
┌                    ┐ ┌   ┐     ┌   ┐
│  R      C          │ │ A │     │ A │
│                    │ │   │ = Ω │   │
│  C*    -R*         │ │ B │     │ B │
└                    ┘ └   ┘     └   ┘
```

Where:
- `R` = Resonant block (electron-hole excitations)
- `C` = Coupling block (electron-hole to hole-electron)

**Resonant Block:**
```
R_{vck,v'c'k'} = (E_c - E_v) δ_{vv'} δ_{cc'} δ_{kk'} + K_{vck,v'c'k'}
```

**Coupling Block:**
```
C_{vck,v'c'k'} = K^{coupling}_{vck,v'c'k'}
```

**Implementation:**
- Variable: `BS_K_coupling` (logical) enables coupling
- Blocks: `BS_res_K_exchange`, `BS_res_K_corr` (resonant)
- Blocks: `BS_cpl_K_exchange`, `BS_cpl_K_corr` (coupling)

### 4.5 Tamm-Dancoff Approximation (TDA)

Neglecting coupling (`C = 0`), the BSE reduces to:

```
R A = Ω A
```

This is the **Tamm-Dancoff Approximation**, which is often sufficient for optical spectra.

**Implementation:**
- Default in YAMBO unless `BSEmod= "coupling"` is specified
- Reduces matrix size by factor of 2

### 4.6 Optical Absorption

The macroscopic dielectric function is:

```
ε_M(ω) = 1 - lim_{q→0} v(q) Σ_S |⟨S|ρ(q)|0⟩|² / (ω - Ω^S + iη)
```

Where:
- `|S⟩` = Exciton state (eigenstate of BSE)
- `|0⟩` = Ground state
- `ρ(q) = Σ_{vck} ρ_{vc}(k,q) c†_{ck} c_{vk}` = Density operator

**Oscillator Strength:**
```
|⟨S|ρ(q)|0⟩|² = |Σ_{vck} A^S_{vck} ρ_{vc}(k,q)|²
```

**Implementation:**
- File: `K_observables.F`
- Computes absorption spectrum from BSE eigenvectors
- Uses dipole matrix elements for `q→0` limit

### 4.7 Haydock Recursion Method

For large systems, YAMBO uses the Haydock recursion method to compute spectra without full diagonalization:

```
ε_M(ω) = 1 - |d|² / [ω - a_0 - b²_1/(ω - a_1 - b²_2/(ω - a_2 - ...))]
```

Where `a_n`, `b_n` are Haydock coefficients obtained by iterative application of the BSE Hamiltonian.

**Implementation:**
- File: `K_Haydock.F`
- Iterative algorithm: `|ψ_{n+1}⟩ = H|ψ_n⟩ - a_n|ψ_n⟩ - b_n|ψ_{n-1}⟩`
- Avoids storing full kernel matrix

### 4.8 Kernel Construction

The kernel is constructed by looping over transitions:

```fortran
! Pseudo-code from K_kernel.F
do i_Tk = 1, N_transitions_k
  do i_Tp = 1, N_transitions_p
    
    ! Exchange term
    if (BS_res_K_exchange) then
      H_x = K_exchange_kernel(iq, BS_n_g_exch, BS_T_grp_p, i_Tp, BS_T_grp_k, i_Tk)
    endif
    
    ! Correlation term
    if (BS_res_K_corr) then
      H_c = K_correlation_kernel_std(i_block, ...)
    endif
    
    ! Store kernel element
    BS_mat(i_Tk, i_Tp) = H_x + H_c
    
  enddo
enddo
```

**Implementation:**
- File: `K_kernel.F`
- Lines 80-200: Main kernel loop structure
- Parallelized over k-points and transitions

### 4.9 TDDFT Kernel

YAMBO can also use TDDFT kernels (e.g., ALDA) instead of BSE:

```
K^{TDDFT}_{vck,v'c'k'} = δ_{kk'} ∫∫ ψ*_v(r) ψ_c(r) f_{xc}(r,r') ψ_{v'}(r') ψ*_{c'}(r') dr dr'
```

Where `f_{xc}(r,r')` is the exchange-correlation kernel.

**ALDA (Adiabatic LDA):**
```
f^{ALDA}_{xc}(r,r') = δ(r-r') ∂²E_{xc}[n]/∂n² |_{n=n_0(r)}
```

**Implementation:**
- File: `TDDFT_ALDA_eh_space_G_kernel.F`
- Module: `mod_TDDFT.F`
- Variable: `BS_K_is_ALDA` enables TDDFT mode

---

## 5. Symmetry Operations

### 5.1 Crystal Symmetries

YAMBO exploits crystal symmetries to reduce computational cost.

#### Symmetry Group

A crystal has `nsym` symmetry operations:

```
{S_i | τ_i},  i = 1, ..., nsym
```

Where:
- `S_i` = Rotation matrix (3×3)
- `τ_i` = Fractional translation vector

**Implementation:**
- Module: `mod_D_lattice.F`
- Variables:
  - `nsym`: Total number of symmetries
  - `dl_sop(3,3,nsym)`: Symmetry operations in real space
  - `dl_tra(3,nsym)`: Fractional translations
  - `rl_sop(3,3,nsym)`: Symmetry operations in reciprocal space

```fortran
! From mod_D_lattice.F
integer :: nsym                      ! Total symmetries
integer :: sp_nsym                   ! Spatial symmetries
integer :: nrot                      ! Pure rotations
integer :: i_time_rev                ! =1 if time-reversal, =0 otherwise
integer :: i_space_inv               ! =1 if inversion, =0 otherwise
real(SP), allocatable :: dl_sop(:,:,:)  ! Symmetry operations (real space)
real(SP), allocatable :: dl_tra(:,:)    ! Translations
real(SP), allocatable :: rl_sop(:,:,:)  ! Symmetry operations (reciprocal space)
```

### 5.2 Symmetry Operations on k-points

A symmetry operation maps k-points:

```
S_i k = k' + G
```

Where `G` is a reciprocal lattice vector bringing `k'` back to the first BZ.

**Star of k:**

The set of k-points related by symmetry:

```
Star(k) = {S_i k | i = 1, ..., nsym}
```

**Irreducible Brillouin Zone (IBZ):**

The minimal set of k-points from which all others can be generated by symmetry.

**Implementation:**
- Module: `mod_R_lattice.F`
- Type: `bz_samp`
- Variables:
  - `nibz`: Number of k-points in IBZ
  - `nbz`: Number of k-points in full BZ
  - `nstar(ik)`: Number of k-points in star of `ik`
  - `star(ik,is)`: Symmetry operation mapping `ik` to star member
  - `sstar(ikbz,1:2)`: Maps BZ k-point to (IBZ index, symmetry)

```fortran
! From mod_R_lattice.F
type bz_samp
  integer           :: nibz                ! IBZ k-points
  integer           :: nbz                 ! Full BZ k-points
  integer, allocatable :: nstar(:)         ! n° of points in star
  integer, allocatable :: star(:,:)        ! ik,ikstar --> symmetry
  integer, allocatable :: sstar(:,:)       ! ikbz --> (ik_ibz, symmetry)
  integer, allocatable :: s_table(:,:)     ! ik,is --> symmetry index
  integer, allocatable :: k_table(:,:)     ! ik,is --> ikbz
  real(SP), allocatable :: pt(:,:)         ! k-points in IBZ
  real(SP), allocatable :: ptbz(:,:)       ! k-points in full BZ
  real(SP), allocatable :: weights(:)      ! k-point weights
end type bz_samp
```

### 5.3 Small Group of k

For a given k-point, only a subset of symmetries leave it invariant (up to G):

```
Small_Group(k) = {S_i | S_i k = k + G}
```

**Implementation:**
- Subroutine: `k_small_group` in `k_small_group.F`
- Variables:
  - `grp_nsym(ik)`: Number of symmetries in small group
  - `grp_table(ik,is_grp)`: Maps small group index to full symmetry list

### 5.4 Time-Reversal Symmetry

Time-reversal symmetry relates:

```
ψ_{n,-k}(r) = ψ*_{n,k}(r)
```

In reciprocal space:

```
c_{n,-k}(G) = c*_{n,k}(-G)
```

**Implementation:**
- Variable: `i_time_rev = 1` if present, `0` otherwise
- Doubles the number of symmetries: `nsym = 2 × sp_nsym` (if TR present)
- Symmetries with index `> nsym/(i_time_rev+1)` include time-reversal

### 5.5 Spatial Inversion

Inversion symmetry:

```
I: r → -r
```

In reciprocal space:

```
I: k → -k,  G → -G
```

**Implementation:**
- Variable: `i_space_inv = 1` if present, `0` otherwise
- Index: `inv_index` gives the symmetry corresponding to `-I`
- Subroutine: `atoms_spatial_inversion` checks if atoms respect inversion

### 5.6 Symmetrization of Wavefunctions

Wavefunctions at symmetry-related k-points are related by:

```
ψ_{n,Sk}(r) = e^{iSk·τ} ψ_{n,k}(S^{-1}r)
```

In reciprocal space:

```
c_{n,Sk}(G) = e^{iSk·τ} e^{iG·τ} c_{n,k}(S^{-1}G)
```

**Implementation:**
- File: `WF_apply_symm.F`
- Applies symmetry operations to wavefunctions
- Phase factors: `WF_phases(ig,is,ib,ik,isp)` store `e^{iG·τ}`

### 5.7 G-Vector Rotations

Symmetry operations rotate G-vectors:

```
S G = G'
```

**Implementation:**
- Variable: `g_rot(ig,is)` gives index of rotated G-vector
- Variable: `g_phs(ig,is)` gives phase factor `e^{iG·τ}`
- Computed in setup phase

```fortran
! From mod_R_lattice.F
integer, allocatable :: g_rot(:,:)   ! Rotated G-vector index
real(SP), allocatable :: g_phs(:,:)  ! Phase factors
```

### 5.8 Symmetrization in GW

Self-energy matrix elements at symmetry-related k-points:

```
Σ_{n,Sk}(ω) = Σ_{n,k}(ω)
```

This allows computing self-energy only in IBZ and symmetrizing to full BZ.

**Implementation:**
- File: `QP_states_simmetrize.F`
- Symmetrizes QP corrections after GW calculation

### 5.9 Symmetrization in BSE

BSE kernel respects symmetries:

```
K_{vck,v'c'k'} = K_{v(Sk),c(Sk),v'(Sk'),c'(Sk')}
```

This allows constructing kernel only for IBZ k-points.

**Implementation:**
- File: `K_kernel.F`
- Lines 80-100: Symmetry operations applied to oscillators
- Oscillators rotated: `O(S^{-1}G)` with phase `e^{iG·τ}`

### 5.10 Non-Symmorphic Symmetries

For non-symmorphic space groups (with non-zero `τ`), additional phase factors appear:

```
ψ_{n,Sk}(r) = e^{iSk·τ} ψ_{n,k}(S^{-1}r)
```

**Implementation:**
- Variable: `non_symmorphic_syms` (logical) indicates presence
- Phase factors included in `g_phs` and `WF_phases`

---

## 6. Implementation Details

### 6.1 Code Structure

**Main Directories:**
- `src/qp/`: GW self-energy calculations
- `src/bse/`: BSE kernel and solvers
- `src/wf_and_fft/`: Wavefunction operations and FFTs
- `src/bz_ops/`: Brillouin zone operations and symmetries
- `src/modules/`: Data structures and modules

**Key Modules:**
- `mod_wave_func.F`: Wavefunction storage
- `mod_R_lattice.F`: Reciprocal lattice and k-points
- `mod_D_lattice.F`: Real-space lattice and symmetries
- `mod_QP_m.F`: Quasiparticle data structures
- `mod_BS.F`: BSE data structures

### 6.2 Workflow

**GW Calculation:**
1. Read DFT wavefunctions and eigenvalues
2. Compute polarization function `χ_0(q,G,G',ω)`
3. Compute screened interaction `W = ε^{-1} v`
4. Compute self-energy `Σ = iGW`
5. Solve quasiparticle equation for `E^{QP}`

**BSE Calculation:**
1. Read QP energies (or use DFT)
2. Compute oscillator strengths `ρ_{vc}(k,q,G)`
3. Construct BSE kernel `K = K^{exch} + K^{dir}`
4. Solve BSE eigenvalue problem
5. Compute optical absorption spectrum

### 6.3 Parallelization

YAMBO uses MPI parallelization over:
- k-points (`PAR_IND_Xk_ibz`)
- q-points (`PAR_IND_Q_ibz`)
- Bands (`PAR_IND_G_b`)
- G-vectors (`PAR_IND_G`)
- QP states (`PAR_IND_QP`)
- BSE transitions

**Implementation:**
- Module: `parallel_m.F`
- Parallel indices: `PAR_IND_*` types
- Communication: `PP_redux_wait`, `PP_wait`

### 6.4 Memory Management

YAMBO uses the `YAMBO_ALLOC`/`YAMBO_FREE` system (see separate memory documentation).

**Key Arrays:**
- `WF%c(ig,ib,ik)`: Wavefunctions (~GB)
- `X_par(iq)%blc(ig1,ig2,iw)`: Response function (~GB)
- `BS_blk(iblk)%mat(iT1,iT2)`: BSE kernel (can be TB)

### 6.5 GPU Acceleration

YAMBO supports GPU acceleration via:
- OpenACC directives
- CUDA Fortran
- OpenMP target offload

**Implementation:**
- Preprocessor: `_GPU`, `_CUDA`, `_OPENACC`, `_OPENMP_GPU`
- Device arrays: `DEV_ATTR` attribute
- Device variables: `DEV_VAR(x)` macro
- Memory copy: `devxlib_memcpy_h2d`, `devxlib_memcpy_d2h`

**Key GPU Kernels:**
- `scatter_Bamp_gpu`: Oscillator computation
- `K_exchange_kernel`: BSE exchange term
- `K_correlation_kernel_std`: BSE correlation term
- Matrix operations: `devxlib_xgemv_gpu`, `V_dot_V_gpu`

### 6.6 I/O and Databases

YAMBO uses NetCDF/HDF5 for I/O:

**Database Files:**
- `ndb.QP`: Quasiparticle energies
- `ndb.em1s`: Inverse dielectric function
- `ndb.pp`: Plasmon-pole parameters
- `ndb.BS_K`: BSE kernel
- `ndb.BS_diago`: BSE eigenvalues/eigenvectors

**Implementation:**
- Module: `io_m.F`
- Functions: `io_X`, `io_QP_and_GF`, `io_BS`

### 6.7 Cutoff Techniques

For 2D materials and surfaces, Coulomb cutoff is applied:

```
v_cut(q,G) = v(q,G) × cutoff_function(q,G)
```

**Cutoff Geometries:**
- `box`: 3D box cutoff
- `cylinder`: Cylindrical cutoff (2D)
- `slab`: Slab cutoff (2D with periodicity in plane)
- `ws`: Wigner-Seitz cell cutoff

**Implementation:**
- Module: `mod_coulomb.F`
- Subroutine: `CUTOFF_set` in `src/coulomb/`
- Variable: `cut_geometry`

### 6.8 Random Integration Method (RIM)

For q→0 singularity in 2D/1D systems, YAMBO uses RIM:

```
lim_{q→0} ∫_{BZ} f(q) dq ≈ Σ_i w_i f(q_i)
```

Where `q_i` are random points near q=0.

**Implementation:**
- Variables: `RIM_ng`, `RIM_n_rand_pts`
- Arrays: `RIM_qpg(ig,iq,irand)`: Random q-points
- Applied in: `QP_ppa_cohsex.F` (lines 356-363)

---

## 7. References

### Theoretical Background

1. **GW Approximation:**
   - Hedin, L. (1965). "New Method for Calculating the One-Particle Green's Function with Application to the Electron-Gas Problem." *Physical Review*, 139(3A), A796.
   - Hybertsen, M. S., & Louie, S. G. (1986). "Electron correlation in semiconductors and insulators: Band gaps and quasiparticle energies." *Physical Review B*, 34(8), 5390.
   - Onida, G., Reining, L., & Rubio, A. (2002). "Electronic excitations: density-functional versus many-body Green's-function approaches." *Reviews of Modern Physics*, 74(2), 601.

2. **Bethe-Salpeter Equation:**
   - Salpeter, E. E., & Bethe, H. A. (1951). "A Relativistic Equation for Bound-State Problems." *Physical Review*, 84(6), 1232.
   - Rohlfing, M., & Louie, S. G. (2000). "Electron-hole excitations and optical spectra from first principles." *Physical Review B*, 62(8), 4927.
   - Strinati, G. (1988). "Application of the Green's functions method to the study of the optical properties of semiconductors." *Rivista del Nuovo Cimento*, 11(12), 1-86.

3. **Plasmon-Pole Approximation:**
   - Hybertsen, M. S., & Louie, S. G. (1987). "First-Principles Theory of Quasiparticles: Calculation of Band Gaps in Semiconductors and Insulators." *Physical Review Letters*, 55(13), 1418.
   - Godby, R. W., & Needs, R. J. (1989). "Metal-insulator transition in Kohn-Sham theory and quasiparticle theory." *Physical Review Letters*, 62(10), 1169.

4. **Symmetries in Solid State:**
   - Dresselhaus, M. S., Dresselhaus, G., & Jorio, A. (2007). *Group Theory: Application to the Physics of Condensed Matter*. Springer Science & Business Media.
   - Bradley, C. J., & Cracknell, A. P. (2010). *The Mathematical Theory of Symmetry in Solids*. Oxford University Press.

### YAMBO-Specific

5. **YAMBO Code:**
   - Marini, A., Hogan, C., Grüning, M., & Varsano, D. (2009). "yambo: An ab initio tool for excited state calculations." *Computer Physics Communications*, 180(8), 1392-1403.
   - Sangalli, D., et al. (2019). "Many-body perturbation theory calculations using the yambo code." *Journal of Physics: Condensed Matter*, 31(32), 325902.

6. **YAMBO Documentation:**
   - Official website: http://www.yambo-code.org/
   - Wiki: http://www.yambo-code.org/wiki/
   - Tutorials: http://www.yambo-code.org/tutorials/

### Computational Methods

7. **Haydock Recursion:**
   - Haydock, R., Heine, V., & Kelly, M. J. (1972). "Electronic structure based on the local atomic environment for tight-binding bands." *Journal of Physics C: Solid State Physics*, 5(20), 2845.
   - Grüning, M., Marini, A., & Gonze, X. (2011). "Exciton-Plasmon States in Nanoscale Materials: Breakdown of the Tamm-Dancoff Approximation." *Nano Letters*, 9(8), 2820-2824.

8. **Plane-Wave Methods:**
   - Payne, M. C., et al. (1992). "Iterative minimization techniques for ab initio total-energy calculations: molecular dynamics and conjugate gradients." *Reviews of Modern Physics*, 64(4), 1045.
   - Martin, R. M. (2004). *Electronic Structure: Basic Theory and Practical Methods*. Cambridge University Press.

---

## Appendix: Formula Summary

### GW Self-Energy

```
Σ(r,r',ω) = i/(2π) ∫ G(r,r',ω+ω') W(r,r',ω') e^{iω'η} dω'

W(r,r',ω) = ∫ ε^{-1}(r,r'',ω) v(r'',r') dr''

⟨n,k|Σ(ω)|n,k⟩ = Σ_{m,q,G,G'} ρ*_{nm}(k,q,G) W_{GG'}(q,ω-ε_m) ρ_{nm}(k,q,G')

E^{QP}_{n,k} = ε^{DFT}_{n,k} + ⟨n,k|Σ(E^{QP}_{n,k})|n,k⟩ - V^{xc}_{n,k}
```

### BSE Kernel

```
(E_c - E_v) A^S_{vck} + Σ_{v'c'k'} K_{vck,v'c'k'} A^S_{v'c'k'} = Ω^S A^S_{vck}

K_{vck,v'c'k'} = K^{exch}_{vck,v'c'k'} + K^{dir}_{vck,v'c'k'}

K^{exch}_{vck,v'c'k'} = -δ_{kk'} Σ_G v_G(0) ρ_{vc}(k,0,G) ρ*_{v'c'}(k',0,G)

K^{dir}_{vck,v'c'k'} = Σ_{G,G'} ρ_{vc}(k,q,G) W_{GG'}(q,0) ρ*_{v'c'}(k',q,G')
```

### Oscillator Strengths

```
ρ_{nm}(k,q,G) = ⟨n,k|e^{-i(q+G)·r}|m,k+q⟩ = Σ_G' c*_{n,k}(G') c_{m,k+q}(G'+G)
```

### Optical Absorption

```
ε_M(ω) = 1 - lim_{q→0} v(q) Σ_S |Σ_{vck} A^S_{vck} ρ_{vc}(k,q)|² / (ω - Ω^S + iη)
```

---

**End of Documentation**