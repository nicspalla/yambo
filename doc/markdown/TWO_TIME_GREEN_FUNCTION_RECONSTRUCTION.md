@page two_time_reconstruction Two-Time Green's Function Reconstruction

# Two-Time Green's Function Reconstruction in Yambo/YAMBO

## Table of Contents
@tableofcontents

---

## Executive Summary

This document provides a detailed analysis of how Yambo/YAMBO reconstructs the **full two-time Green's function** G^<(t,t') from the time-diagonal density matrix ρ(t) saved during real-time propagation.

**Key Points:**
- **What is reconstructed**: Full lesser Green's function G^<(k,t,t') for all time pairs (t,t')
- **From what**: Time-diagonal density matrix ρ(k,t) = -iG^<(k,t,t) saved at each time step
- **Method**: Iterative propagation of retarded Green's function G^R(t,t') combined with density matrix
- **Theoretical basis**: Keldysh formalism, reference PRA 92, 033419 (2015)
- **Computational cost**: O(N_t²) in post-processing vs O(N_t³) for direct propagation
- **Storage cost**: O(N_t × N_k × N_b²) for history vs O(N_t² × N_k × N_b²) for full G^<

---

## 1. Theoretical Framework

### 1.1 Definitions

**Lesser Green's function** (two-time):
```
G^<_{nm}(k,t,t') = i⟨c†_m(k,t')c_n(k,t)⟩
```

**Physical interpretation:**
- **Diagonal (n=m)**: Occupation of state n at times t and t'
- **Off-diagonal (n≠m)**: Coherence between states n and m
- **Time-diagonal (t=t')**: Instantaneous density matrix ρ(t)
- **Time-off-diagonal (t≠t')**: Memory effects, correlations, dephasing

**Density matrix** (time-diagonal):
```
ρ_{nm}(k,t) = -iG^<_{nm}(k,t,t)
```

**Retarded Green's function**:
```
G^R_{nm}(k,t,t') = -iθ(t-t')⟨[c_n(k,t), c†_m(k,t')]⟩
```

### 1.2 Reconstruction Equations

The reconstruction is based on the **Keldysh equation** relating G^<, G^R, and ρ:

**For t > t' (causal region):**

```
G^<(t,t') = -G^R(t,t') ρ(t')                    [Eq. 1a]
```

**For t < t' (anti-causal region):**

```
G^<(t,t') = ρ(t) [G^R(t',t)]†                   [Eq. 1b]
```

**At t = t' (time-diagonal):**

```
G^<(t,t) = -iρ(t)                               [Eq. 1c]
```

**Symmetry relations:**
```
G^<(t',t) = -[G^<(t,t')]†                      [Eq. 2]
G^R(t',t) = [G^A(t,t')]†                       [Eq. 3]
```

where G^A is the advanced Green's function.

### 1.3 Retarded Green's Function Evolution

The key to reconstruction is evolving G^R(t,t') in the two-time plane. The equation of motion is:

```
i∂G^R(t,t')/∂t = [H(t), G^R(t,t')]             [Eq. 4a]
-i∂G^R(t,t')/∂t' = [G^R(t,t'), H(t')]          [Eq. 4b]
```

**Initial condition:**
```
G^R(t,t) = -i𝟙                                  [Eq. 5]
```

**Discretized evolution** (used in the code):
```
G^R(t+δt, t'-δt) = U(t+δt) G^R(t,t') U†(t'-δt) [Eq. 6]
```

where the time-evolution operator is:
```
U(t) = exp(-iH(t)δt) ≈ 𝟙 - iH(t)δt + ... + (-iH(t)δt)^n/n! [Eq. 7]
```

---

## 2. Implementation in Yambo/YAMBO

### 2.1 Algorithm Overview

**File**: `ypp/real_time/RT_G_two_times_build.F`

**Main steps:**

1. **Load saved history**: Read ρ(k,t) and H[ρ(t)] from RT database
2. **Initialize G^R**: Set G^R(T_c,T_c) = -i𝟙 at central time T_c
3. **Iterate over time pairs**: For each (t,t') pair, evolve G^R and compute G^<
4. **Fourier transform**: Transform G^<(t,t') → G^<(ω) via FFT
5. **Output**: Write spectral functions, k-resolved data

### 2.2 Detailed Algorithm

**Initialization** (lines 136-181):
```fortran
! Central time
T_c = (T_range(1) + T_range(2))/2
i_Tc = (T_n_steps + 1)/2

! Load ρ(T_c) and H[ρ(T_c)]
call io_RT_components('G_lesser_K_section', ID)

! Initialize retarded Green's function
G_ret(:,:,ik,i_sp) = -cI * I1_matrix(:,:)

! Compute ρ and (1-ρ) including equilibrium occupation
rho_T(:,:,ik,i_sp) = -cI*G_lesser_reference + (-cI)*dG_lesser
b_rho_T(:,:,ik,i_sp) = I1_matrix + cI*G_lesser_reference - (-cI)*dG_lesser
```

**Time-diagonal value** (lines 188-215):
```fortran
! At t=t', compute G^<(T_c,T_c)
if (build_G_les) then
  G_tmp = -G_ret * rho_T + rho_T * G_ret†
endif

! Store F(k,T_c-T_c) = Tr[G^<(k,T_c,T_c)]
F_k_tmtp(ik,i_sp,i_Tc) = Σ_{n,m} G_tmp(n,m)
```

**Iterative reconstruction** (lines 221-371):
```fortran
do i_T1 = i_Tc+1, T_n_steps
  
  i_T2 = i_Tc + (i_Tc - i_T1)  ! Symmetric time
  
  ! Load ρ(t) and ρ(t') from database
  do i_kind = 1, 2
    call io_RT_components('G_lesser_K_section', ID)
    H_rho_T(:,:,:,:,i_kind) = H_EQ + Ho_plus_sigma
  enddo
  
  ! Evolve G^R(t,t') → G^R(t+δt, t'-δt)
  ! Using: G^R(t+δt,t'-δt) = exp(-iH(t+δt)δt) G^R(t,t') exp(+iH(t'-δt)δt)
  H_avg_t = (H_rho_T(:,:,ik,i_sp,1) + H_rho_T_prev(:,:,ik,i_sp,1))/2
  H_avg_tp = (H_rho_T(:,:,ik,i_sp,2) + H_rho_T_prev(:,:,ik,i_sp,2))/2
  
  call RT_apply_Texp(H_avg_t, G_ret(:,:,ik,i_sp), H_avg_tp, δt, η, 5)
  
  ! Compute G^<(t,t') for t>t'
  if (build_G_les) then
    G_tmp = -G_ret(:,:,ik,i_sp) * rho_T(:,:,ik,i_sp)  ! Eq. 1a
  endif
  
  ! Store for t>t' and t<t' using symmetry
  F_k_tmtp(ik,i_sp,i_T1) = F_k_tmtp(ik,i_sp,i_T1) + Σ G_tmp(n,m)
  F_k_tmtp(ik,i_sp,i_T2) = F_k_tmtp(ik,i_sp,i_T2) - Σ conjg(G_tmp(m,n))
  
enddo
```

### 2.3 Time Evolution Operator

**File**: `ypp/real_time/RT_apply_Texp.F`

**Purpose**: Apply U(t) = exp(-iHt) to G^R using Taylor expansion

**Implementation** (lines 41-84):
```fortran
subroutine RT_apply_Texp(H1, Gret, H2, deltaT, eta, n_order)
  !
  ! Computes: Gret(t+dt,t'-dt) = U1(t+dt) Gret(t,t') U2†(t'-dt)
  ! where: U1 = exp(-iH1*dt) * exp(-η*dt)
  !        U2 = exp(-iH2*dt) * exp(-η*dt)
  !
  ! Taylor expansion up to order n_order:
  ! U = 1 + (-iHt) + (-iHt)²/2! + ... + (-iHt)^n/n!
  
  U1 = -cI*deltaT*H1
  U2 = -cI*deltaT*H2
  
  M1a_tmp = U1
  M1b_tmp = U1
  M2a_tmp = U2
  M2b_tmp = U2
  
  do i_order = 2, n_order
    M1c_tmp = M1a_tmp * M1b_tmp / i_order
    M2c_tmp = M2a_tmp * M2b_tmp / i_order
    U1 = U1 + M1c_tmp
    U2 = U2 + M2c_tmp
    M1b_tmp = M1c_tmp
    M2b_tmp = M2c_tmp
  enddo
  
  ! Add identity and damping
  U1 = (U1 + I1_matrix) * exp(-deltaT*eta)
  U2 = (U2 + I1_matrix) * exp(-deltaT*eta)
  
  ! Apply: Gret = U1 * Gret * U2
  G_tmp = U1 * Gret
  Gret = G_tmp * U2
  
end subroutine
```

**Accuracy**: 5th order Taylor expansion (n_order=5) provides excellent accuracy for typical time steps.

---

## 3. Equations Used in the Code

### 3.1 Core Reconstruction Equations

**Line 323** (Lesser Green's function for t>t'):
```fortran
! PRA 92, 033419 (2015), Eq.(19a)
G^<(t,t') = -G^R(t,t') ρ(t')
```

**Line 332** (Greater Green's function for t>t'):
```fortran
! PRA 92, 033419 (2015), Eq.(19b)
G^>(t,t') = +G^R(t,t') (1-ρ(t'))
```

**Line 342** (Symmetry relations):
```fortran
! PRA 92, 033419 (2015), Below Eq.(19)
G^A(t',t) = [G^R(t,t')]†
G^<(t',t) = -[G^<(t,t')]†
G^>(t',t) = -[G^>(t,t')]†
```

### 3.2 Hamiltonian Construction

**Line 177-178** (Effective Hamiltonian):
```fortran
H_rho_T(:,:,ik,i_sp,i_kind) = H_EQ(:,:,ik,i_sp) + Ho_plus_sigma(:,:,ik,i_sp)
```

where:
- `H_EQ`: Equilibrium Hamiltonian (DFT eigenvalues + off-diagonal elements)
- `Ho_plus_sigma`: Self-energy corrections (Hartree, exchange, correlation, el-ph, etc.)

**With dephasing** (lines 251-262):
```fortran
if (l_dephase_rho) then
  do ib1, ib2
    deph_factor = 1.0
    if ((ib1>nbf .and. ib2<=nbf) .or. (ib1<=nbf .and. ib2>nbf)) then
      deph_factor = exp(-Rho_deph * RT_time(i_T))
    endif
    H_rho_T(ib1,ib2,:,:,i_kind) = H_EQ(ib1,ib2,:,:) + Ho_plus_sigma(ib1,ib2,:,:) * deph_factor
  enddo
endif
```

This adds phenomenological dephasing to coherences (valence-conduction transitions).

### 3.3 Density Matrix Construction

**Line 164-171** (Including equilibrium occupation):
```fortran
if (include_eq_occ) then
  rho_T(:,:,ik,i_sp) = -cI*G_lesser_reference(:,:,ik,i_sp) + (-cI)*dG_lesser(:,:,ik,i_sp,1)
  b_rho_T(:,:,ik,i_sp) = I1_matrix + cI*G_lesser_reference(:,:,ik,i_sp) - (-cI)*dG_lesser(:,:,ik,i_sp,1)
else
  rho_T(:,:,ik,i_sp) = (-cI)*dG_lesser(:,:,ik,i_sp,1)
  b_rho_T(:,:,ik,i_sp) = I1_matrix - (-cI)*dG_lesser(:,:,ik,i_sp,1)
endif
```

where:
- `G_lesser_reference`: Equilibrium G^< (ground state)
- `dG_lesser`: Change in G^< due to perturbation
- `b_rho_T`: Complementary density matrix (1-ρ) for holes

### 3.4 Time Evolution

**Line 302-310** (Retarded Green's function propagation):
```fortran
! G^R(t+dt,t'-dt) = exp(-iH[ρ(t+dt)]dt) G^R(t,t') exp(+iH[ρ(t'-dt)]dt)
TMP_M(:,:,1) = (H_rho_T(:,:,ik,i_sp,1) + H_rho_T_prev(:,:,ik,i_sp,1))/2
TMP_M(:,:,2) = (H_rho_T(:,:,ik,i_sp,2) + H_rho_T_prev(:,:,ik,i_sp,2))/2
call RT_apply_Texp(TMP_M(:,:,1), G_ret(:,:,ik,i_sp), TMP_M(:,:,2), δt, η, 5)
```

**Averaging**: Uses midpoint rule (average of H at t and t+dt) for better accuracy.

---

## 4. Approximations Used

### 4.1 Time-Diagonal Propagation

**During RT simulation:**
- Only ρ(t) = -iG^<(t,t) is propagated
- Full G^<(t,t') is NOT computed during dynamics
- **Justification**: Most observables only need ρ(t)

**Equation of motion** (solved during RT):
```
i∂ρ(t)/∂t = [H^RT(t), ρ(t)] - iΣ^scatt(t)
```

### 4.2 Reconstruction Approximations

**1. Gradient expansion** (implicit):
The reconstruction assumes that G^R(t,t') can be evolved using local Hamiltonians H(t) and H(t'). This is valid when:
```
|t-t'| << τ_correlation
```
where τ_correlation is the correlation time of the system.

**2. Markovian approximation** (optional):
If `SaveGhistory = .false.`, only recent history is kept (G_MEM_steps ≈ 2-3), limiting reconstruction to short time differences.

**3. Self-energy approximation**:
The Hamiltonian H[ρ(t)] includes self-energy corrections computed at the mean-field level:
```
H[ρ(t)] = H_0 + Σ^Hartree[ρ(t)] + Σ^xc[ρ(t)] + Σ^el-ph(t) + ...
```

**4. Taylor expansion truncation**:
The time-evolution operator is expanded to 5th order (n_order=5):
```
U(t) ≈ Σ_{n=0}^5 (-iHt)^n/n!
```
Error: O((Ht)^6) ≈ O(δt^6) for typical δt ~ 0.01 fs

### 4.3 Validity Conditions

The reconstruction is accurate when:

1. **Small time step**: δt << ℏ/ΔE where ΔE is typical energy scale
2. **Smooth Hamiltonian**: H(t) varies slowly compared to δt
3. **Short memory**: |t-t'| not too large (depends on SaveGhistory)
4. **Weak correlations**: Mean-field self-energy is adequate

---

## 5. Storage and Computational Cost

### 5.1 Storage Requirements

**During RT simulation:**
```
Memory = N_k × N_b² × G_MEM_steps × 16 bytes
```

**Example** (typical calculation):
- N_k = 100 k-points
- N_b = 20 bands
- G_MEM_steps = 3 (if SaveGhistory=.false.) or N_t (if SaveGhistory=.true.)
- Memory ≈ 100 × 400 × 3 × 16 bytes = 1.9 MB (without history)
- Memory ≈ 100 × 400 × 1000 × 16 bytes = 640 MB (with full history)

**For full G^<(t,t')** (if stored directly):
```
Memory = N_k × N_b² × N_t² × 16 bytes
```

**Example**:
- N_t = 1000 time steps
- Memory ≈ 100 × 400 × 1000000 × 16 bytes = 640 GB (prohibitive!)

**Savings**: Storing only ρ(t) reduces memory by factor of N_t (1000×).

### 5.2 Computational Cost

**RT propagation** (time-diagonal):
```
Cost_RT = N_t × N_k × N_b³ × C_integrator
```
where C_integrator depends on method (EULER: 1, RK4: 4, EXP: ~10).

**Two-time reconstruction** (post-processing):
```
Cost_recon = N_t² × N_k × N_b³ × C_Texp
```
where C_Texp ≈ 5 (5th order Taylor expansion).

**Ratio**:
```
Cost_recon / Cost_RT ≈ N_t × (C_Texp / C_integrator) ≈ 1000 × (5/10) = 500
```

**Practical implications:**
- RT simulation: Minutes to hours
- Reconstruction: Hours to days (but only done once in post-processing)
- **Alternative** (direct two-time propagation): Would be N_t times more expensive than reconstruction!

### 5.3 Fourier Transform Cost

**1D FFT** (lines 390-406):
```fortran
! Transform G^<(t,t') → G^<(ω) for fixed T_c = (t+t')/2
RT_time = (RT_time - T_c) * 2  ! Shift to relative time τ = t-t'
call RT_1D_Fourier_Transform('T2W', GreenF_T_and_W, RT_conf, 1)
```

**Cost**:
```
Cost_FFT = N_k × N_b² × N_t × log(N_t)
```

**Example**:
- N_t = 1000, log(N_t) ≈ 10
- Cost_FFT ≈ 100 × 400 × 1000 × 10 = 400M operations (negligible)

---

## 6. Comparison with Direct Two-Time Propagation

### 6.1 Direct Propagation

**Hypothetical approach**: Solve full Kadanoff-Baym equations:
```
i∂G^<(t,t')/∂t = [H(t), G^<(t,t')] + ∫ dt'' [Σ^R(t,t'')G^<(t'',t') - Σ^<(t,t'')G^A(t'',t')]
```

**Challenges:**
1. **Memory**: Store G^<(t,t') for all (t,t') → O(N_t²) arrays
2. **Computation**: Evolve N_t² coupled equations → O(N_t³) operations
3. **Complexity**: Need Σ^R(t,t') and Σ^<(t,t') (not just Σ^scatt(t))

### 6.2 Reconstruction Approach (Used in Yambo)

**Advantages:**
1. **Memory**: Store only ρ(t) → O(N_t) arrays
2. **Computation**: RT propagation O(N_t), reconstruction O(N_t²) in post-processing
3. **Simplicity**: Only need time-diagonal self-energy Σ^scatt(t)

**Limitations:**
1. **Approximation**: Assumes G^<(t,t') can be reconstructed from ρ(t) and G^R(t,t')
2. **Memory effects**: Limited by saved history (G_MEM_steps or full N_t)
3. **Accuracy**: Depends on smoothness of H(t) and validity of gradient expansion

### 6.3 When is Reconstruction Accurate?

**Good accuracy:**
- Weak to moderate perturbations (linear/weakly nonlinear regime)
- Smooth external fields (no sudden jumps)
- Short correlation times (Markovian dynamics)
- Well-separated energy scales (no strong resonances)

**Potential issues:**
- Strong correlations (beyond mean-field)
- Non-Markovian dynamics (long memory effects)
- Rapid field variations (δt too large)
- Strong resonances (need very fine time grid)

---

## 7. Practical Usage

### 7.1 Input Parameters

**RT simulation** (to save history):
```bash
negf                           # Real-time simulation
% RTBands
  1 | 20 |                     # Band range
%
RTstep= 0.01 | fs              # Time step
RTtime= 100 | fs               # Total time
Integrator= "RK4"              # or "EXP" (recommended)
SaveGhistory= .true.           # CRITICAL: Save full history
```

**YPP reconstruction**:
```bash
ypp -y                         # YPP real-time post-processing
RealTime
RTGtwotimes                    # Two-time Green's function
BuildGles                      # Build G^< (or BuildGret, BuildSpec)
IncludeEQocc                   # Include equilibrium occupation
% QPkrange
  1 | 10 | 5 | 8 |             # k-points and bands
%
% GrEnRange
 -5.0 | 10.0 | eV              # Energy range for spectral function
%
GrEnSteps= 1000                # Energy resolution
Rho_deph= 0.0 | eV             # Additional dephasing (optional)
```

### 7.2 Output Files

**Integrated spectral function**:
- `G_w_integrated.dat`: G^<(ω) integrated over k-space
- Columns: Energy [eV], Im[G(ω)], Re[G(ω)]

**k-resolved spectral function**:
- `G_k1_w.dat`: G^<(k,ω) for specific k-point (k1 = Γ point)
- Columns: Energy [eV], Im[G(ω)], Re[G(ω)]

**Interpolated data** (if k-path specified):
- `YPP-G_lesser_K*_B*_t_tp.dat`: G^<(t,t') for each (k,band)
- 2D plots showing time-time correlations

### 7.3 Analysis Workflow

**1. Dephasing analysis:**
```fortran
! Plot |G^<(t,t')| vs (t-t') for fixed T_c = (t+t')/2
! Exponential decay → dephasing time τ_deph
```

**2. Spectral function:**
```fortran
! A(k,ω,T_c) = -2 Im ∫ G^<(k,T_c+τ/2, T_c-τ/2) e^(iωτ) dτ
! Shows time-resolved band structure
```

**3. Memory effects:**
```fortran
! Compare G^<(t,t') for different |t-t'|
! Non-exponential decay → non-Markovian dynamics
```

---

## 8. Code Structure

### 8.1 Main Routines

**Driver**:
- `RT_G_two_times_driver.F`: Main entry point, calls build and plot routines

**Core reconstruction**:
- `RT_G_two_times_build.F`: Reconstruct G^<(t,t') from ρ(t)
  - Lines 59-181: Initialization
  - Lines 183-215: Time-diagonal value
  - Lines 221-371: Iterative reconstruction
  - Lines 390-457: Fourier transform and output

**Time evolution**:
- `RT_apply_Texp.F`: Apply exp(-iHt) using Taylor expansion
  - Lines 41-73: Taylor series computation
  - Lines 75-82: Apply to G^R

**Interpolation and plotting**:
- `RT_G_two_times_interp_and_plot.F`: Interpolate G^<(k,ω) on k-path

### 8.2 Key Data Structures

**From `mod_real_time.F`**:
```fortran
complex(SP), allocatable :: dG_lesser(:,:,:,:,:)        ! ρ(t) - ρ_eq
complex(SP), allocatable :: G_lesser_reference(:,:,:,:) ! ρ_eq
complex(SP), allocatable :: Ho_plus_Sigma(:,:,:,:)      ! H + Σ
complex(SP), allocatable :: H_EQ(:,:,:,:)               ! H_0
```

**Local to reconstruction**:
```fortran
complex(SP), allocatable :: rho_T(:,:,:,:)              ! ρ(t)
complex(SP), allocatable :: b_rho_T(:,:,:,:)            ! 1-ρ(t)
complex(SP), allocatable :: H_rho_T(:,:,:,:,:)          ! H[ρ(t)]
complex(SP), allocatable :: G_ret(:,:,:,:)              ! G^R(t,t')
complex(SP), allocatable :: F_k_tmtp(:,:,:)             ! Tr[G^<(k,t,t')]
```

### 8.3 I/O Operations

**Read from RT database**:
```fortran
call io_control(ACTION=OP_RD_CL, COM=NONE, MODE=DUMP, SEC=(/1,2/), ID=ID)
io_err = io_RT_components('G_lesser', ID)               ! Read metadata
io_err = io_RT_components('G_lesser_K_section', ID)    ! Read ρ(k,t)
io_err = io_RT_components('REF', ID)                   ! Read ρ_eq
```

**Write output**:
```fortran
call of_open_close('G_w_integrated', 'ot')
call msg('o G_w_integrated', "#", headings, INDENT=0, USE_TABS=.true.)
call msg('o G_w_integrated', '', odata, INDENT=-2, USE_TABS=.true.)
call of_open_close('G_w_integrated')
```

---

## 9. Advanced Features

### 9.1 Phenomenological Dephasing

**Purpose**: Add artificial dephasing to coherences (useful for comparison with experiments)

**Implementation** (lines 251-262):
```fortran
if (l_dephase_rho) then
  do ib1, ib2
    if ((ib1>nbf .and. ib2<=nbf) .or. (ib1<=nbf .and. ib2>nbf)) then
      deph_factor = exp(-Rho_deph * RT_time(i_T))
      H_rho_T(ib1,ib2,:,:,i_kind) = H_EQ(ib1,ib2,:,:) + Ho_plus_sigma(ib1,ib2,:,:) * deph_factor
      rho_T(ib1,ib2,:,:) = -cI*dG_lesser(ib1,ib2,:,:,1) * deph_factor
    endif
  enddo
endif
```

**Effect**: Exponentially suppresses valence-conduction coherences with rate Rho_deph.

### 9.2 Band Filtering

**Purpose**: Compute G^< only for specific band combinations (reduce computational cost)

**Options**:
- `KeepCC`: Conduction-conduction transitions
- `KeepVV`: Valence-valence transitions
- `KeepCV`: Conduction-valence transitions (optical coherences)
- `KeepVC`: Valence-conduction transitions (optical coherences)

**Implementation** (lines 202-212):
```fortran
do ib1, ib2
  if ((ib1<=nbf .and. ib2<=nbf) .and. (.not.keep_vv)) cycle
  if ((ib1>nbf .and. ib2>nbf) .and. (.not.keep_cc)) cycle
  if ((ib1>nbf .and. ib2<=nbf) .and. (.not.keep_cv)) cycle
  if ((ib1<=nbf .and. ib2>nbf) .and. (.not.keep_vc)) cycle
  F_k_tmtp(ik,i_sp,i_Tc) = F_k_tmtp(ik,i_sp,i_Tc) + G_tmp(ib1,ib2)
enddo
```

### 9.3 Multiple Green's Functions

**Options**:
- `BuildGles`: Lesser G^< (particles)
- `BuildGgrt`: Greater G^> (holes)
- `BuildGret`: Retarded G^R (causal propagator)
- `BuildGadv`: Advanced G^A (anti-causal propagator)
- `BuildSpec`: Spectral function A = i(G^R - G^A)

**Relations**:
```fortran
if (build_G_les) G_tmp = -G_ret * rho_T + rho_T * G_ret†
if (build_G_grt) G_tmp = +G_ret * b_rho_T - b_rho_T * G_ret†
if (build_G_ret) G_tmp = G_ret
if (build_G_adv) G_tmp = hermitian(G_ret)
if (build_Spect) G_tmp = G_ret - hermitian(G_ret)
```

---

## 10. Summary and Recommendations

### 10.1 Key Takeaways

1. **Reconstruction is efficient**: O(N_t²) post-processing vs O(N_t³) direct propagation
2. **Storage is manageable**: O(N_t) during RT vs O(N_t²) for full G^<
3. **Accuracy is good**: For typical RT-TDDFT applications (weak-to-moderate perturbations)
4. **Flexibility**: Can compute G^<, G^>, G^R, G^A, and spectral functions

### 10.2 Best Practices

**For accurate reconstruction:**
1. Use small time step (δt ≤ 0.01 fs)
2. Enable `SaveGhistory = .true.` in RT simulation
3. Use high-order integrator (EXP or RK4)
4. Check convergence with respect to δt and n_order

**For efficient computation:**
1. Use band filtering (KeepCV, KeepVC) if only optical properties needed
2. Limit k-point range (QPkrange) to region of interest
3. Use coarse energy grid for initial tests, refine later

**For physical insight:**
1. Plot G^<(t,t') in 2D to visualize dephasing
2. Compute spectral function A(k,ω,t) to see time-resolved bands
3. Compare with/without dephasing to understand coherence effects

### 10.3 Limitations and Future Directions

**Current limitations:**
- Mean-field self-energy (no vertex corrections)
- Gradient expansion (assumes smooth H(t))
- Limited to saved history (memory constraints)

**Possible improvements:**
- Include vertex corrections (GW+DMFT)
- Use higher-order propagators (Magnus expansion)
- Implement adaptive time stepping
- Parallelize reconstruction over (t,t') pairs

---

## References

1. **PRA 92, 033419 (2015)**: "Real-time Green's functions in many-body theories"
   - Equations (19a), (19b): G^< and G^> reconstruction
   - Symmetry relations for time-reversal

2. **Keldysh formalism**: Non-equilibrium Green's functions
   - G. Stefanucci and R. van Leeuwen, "Nonequilibrium Many-Body Theory of Quantum Systems" (Cambridge, 2013)

3. **RT-TDDFT in YAMBO**:
   - D. Sangalli et al., J. Chem. Phys. 144, 074103 (2016)
   - A. Marini et al., Comp. Phys. Comm. 180, 1392 (2009)

---

**Document version**: 1.0  
**Last updated**: 2025  
**Author**: Yambo/YAMBO Development Team  
**Contact**: See AUTHORS file for details
