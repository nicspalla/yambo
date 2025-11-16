# Two-Time Green's Function Reconstruction - Executive Summary

## How does the reconstruction of the full G^< with two-time dependence work?**

**A:** The code reconstructs the full two-time lesser Green's function **G^<(k,t,t')** from the time-diagonal density matrix **ρ(k,t) = -iG^<(k,t,t)** saved during real-time propagation. The method uses:

1. **Saved data**: ρ(k,t) and H[ρ(t)] at each time step
2. **Retarded Green's function**: G^R(t,t') evolved iteratively in the (t,t') plane
3. **Keldysh relation**: G^<(t,t') = -G^R(t,t') ρ(t') for t>t'

---

## Core Equations

### 1. Reconstruction Formula

For **t > t'** (causal region):
```
G^<(t,t') = -G^R(t,t') ρ(t')
```

For **t < t'** (anti-causal region):
```
G^<(t,t') = ρ(t) [G^R(t',t)]†
```

**Reference**: PRA 92, 033419 (2015), Eq. (19a)

### 2. Retarded Green's Function Evolution

**Equation of motion**:
```
i∂G^R(t,t')/∂t = [H(t), G^R(t,t')]
-i∂G^R(t,t')/∂t' = [G^R(t,t'), H(t')]
```

**Initial condition**:
```
G^R(t,t) = -i𝟙
```

**Discretized evolution** (implemented in code):
```
G^R(t+δt, t'-δt) = U(t+δt) G^R(t,t') U†(t'-δt)
```

where:
```
U(t) = exp(-iH(t)δt) ≈ Σ_{n=0}^5 (-iH(t)δt)^n / n!
```

### 3. Hamiltonian

**Effective Hamiltonian**:
```
H[ρ(t)] = H_EQ + Σ^Hartree[ρ(t)] + Σ^xc[ρ(t)] + Σ^el-ph(t) + ...
```

**With phenomenological dephasing** (optional):
```
H_{nm}[ρ(t)] = H_EQ,nm + Σ_{nm}[ρ(t)] × exp(-Γ_deph × t)  [for n≠m, v-c transitions]
```

---

## Approximations Used

### 1. **Gradient Expansion**
The reconstruction assumes G^R(t,t') can be evolved using local Hamiltonians H(t) and H(t'). Valid when:
```
|t-t'| << τ_correlation
```

### 2. **Mean-Field Self-Energy**
The Hamiltonian includes self-energy at the mean-field level (Hartree, exchange-correlation, el-ph). No vertex corrections.

### 3. **Taylor Expansion**
Time-evolution operator truncated at 5th order:
```
U(t) ≈ Σ_{n=0}^5 (-iH(t)δt)^n / n!
```
Error: O(δt^6)

### 4. **Time-Diagonal Propagation**
During RT simulation, only ρ(t) = -iG^<(t,t) is propagated, not the full G^<(t,t').

---

## Storage and Computational Cost

### Storage Requirements

**During RT simulation** (with SaveGhistory=.true.):
```
Memory = N_k × N_b² × N_t × 16 bytes
```

**Example** (N_k=100, N_b=20, N_t=1000):
```
Memory ≈ 100 × 400 × 1000 × 16 bytes = 640 MB
```

**If full G^<(t,t') were stored directly**:
```
Memory = N_k × N_b² × N_t² × 16 bytes ≈ 640 GB  (1000× larger!)
```

**Savings**: Factor of **N_t** (typically 1000×)

### Computational Cost

**RT propagation** (time-diagonal):
```
Cost_RT = N_t × N_k × N_b³ × C_integrator
```

**Two-time reconstruction** (post-processing):
```
Cost_recon = N_t² × N_k × N_b³ × C_Texp
```

**Ratio**:
```
Cost_recon / Cost_RT ≈ N_t × (C_Texp / C_integrator) ≈ 1000 × (5/10) = 500
```

**Direct two-time propagation** (hypothetical):
```
Cost_direct = N_t³ × N_k × N_b³  (N_t times more expensive than reconstruction!)
```

---

## Algorithm Overview

### Step-by-Step Process

**1. Initialization** (at central time T_c):
```fortran
! Load ρ(T_c) and H[ρ(T_c)] from RT database
call io_RT_components('G_lesser_K_section', ID)

! Initialize retarded Green's function
G_ret(:,:,ik,i_sp) = -cI * I1_matrix

! Compute G^<(T_c,T_c) = -iρ(T_c)
G_tmp = -G_ret * rho_T + rho_T * G_ret†
```

**2. Iterative reconstruction** (for each time pair):
```fortran
do i_T1 = i_Tc+1, T_n_steps
  
  i_T2 = i_Tc + (i_Tc - i_T1)  ! Symmetric time
  
  ! Load ρ(t) and ρ(t') from database
  call io_RT_components('G_lesser_K_section', ID)
  
  ! Evolve G^R(t,t') → G^R(t+δt, t'-δt)
  H_avg_t = (H[ρ(t)] + H[ρ(t-δt)]) / 2
  H_avg_tp = (H[ρ(t')] + H[ρ(t'+δt)]) / 2
  call RT_apply_Texp(H_avg_t, G_ret, H_avg_tp, δt, η, 5)
  
  ! Compute G^<(t,t') = -G^R(t,t') ρ(t')
  G_tmp = -G_ret * rho_T
  
  ! Store for t>t' and t<t' using symmetry
  F_k_tmtp(ik,i_sp,i_T1) = Tr[G_tmp]
  F_k_tmtp(ik,i_sp,i_T2) = -Tr[G_tmp†]
  
enddo
```

**3. Fourier transform**:
```fortran
! Transform G^<(t,t') → G^<(ω) for fixed T_c = (t+t')/2
RT_time = (RT_time - T_c) * 2  ! Shift to relative time τ = t-t'
call RT_1D_Fourier_Transform('T2W', GreenF_T_and_W, RT_conf, 1)
```

**4. Output**:
```fortran
! Write spectral functions
call of_open_close('G_w_integrated', 'ot')
call msg('o G_w_integrated', odata)
```

---

## Code Implementation

### Main Files

1. **`ypp/real_time/RT_G_two_times_build.F`** (480 lines)
   - Core reconstruction algorithm
   - Lines 59-181: Initialization
   - Lines 183-215: Time-diagonal value
   - Lines 221-371: Iterative reconstruction
   - Lines 390-457: Fourier transform and output

2. **`ypp/real_time/RT_apply_Texp.F`** (84 lines)
   - Apply exp(-iHt) using 5th order Taylor expansion
   - Lines 41-73: Taylor series computation
   - Lines 75-82: Apply to G^R

3. **`ypp/real_time/RT_G_two_times_interp_and_plot.F`** (75 lines)
   - Interpolate G^<(k,ω) on k-path
   - Generate plots

### Key Data Structures

```fortran
! Density matrix and Hamiltonian
complex(SP), allocatable :: rho_T(:,:,:,:)              ! ρ(t)
complex(SP), allocatable :: b_rho_T(:,:,:,:)            ! 1-ρ(t)
complex(SP), allocatable :: H_rho_T(:,:,:,:,:)          ! H[ρ(t)]

! Green's functions
complex(SP), allocatable :: G_ret(:,:,:,:)              ! G^R(t,t')
complex(SP), allocatable :: G_tmp(:,:)                  ! Temporary G^<

! Output
complex(SP), allocatable :: F_k_tmtp(:,:,:)             ! Tr[G^<(k,t,t')]
```

---

## Practical Usage

### Input Parameters

**RT simulation** (save history):
```bash
negf
% RTBands
  1 | 20 |
%
RTstep= 0.01 | fs
RTtime= 100 | fs
Integrator= "EXP"              # Recommended
SaveGhistory= .true.           # CRITICAL!
```

**YPP reconstruction**:
```bash
ypp -y
RealTime
RTGtwotimes
BuildGles                      # Build G^<
IncludeEQocc                   # Include equilibrium
% QPkrange
  1 | 10 | 5 | 8 |
%
% GrEnRange
 -5.0 | 10.0 | eV
%
GrEnSteps= 1000
Rho_deph= 0.0 | eV             # Optional dephasing
```

### Output Files

- **`G_w_integrated.dat`**: G^<(ω) integrated over k
- **`G_k1_w.dat`**: G^<(k,ω) for specific k-point
- **`YPP-G_lesser_K*_B*_t_tp.dat`**: G^<(t,t') for each (k,band)

---

## Comparison: Reconstruction vs Direct Propagation

| Aspect | Reconstruction (Yambo) | Direct Propagation |
|--------|------------------------|-------------------|
| **Memory during RT** | O(N_t) | O(N_t²) |
| **Computation during RT** | O(N_t) | O(N_t³) |
| **Post-processing** | O(N_t²) | None |
| **Total cost** | O(N_t²) | O(N_t³) |
| **Approximations** | Gradient expansion, mean-field | Exact (if Σ known) |
| **Flexibility** | Can change analysis later | Fixed during RT |
| **Practical** | ✅ Feasible | ❌ Prohibitive |

**Conclusion**: Reconstruction is **N_t times faster** (typically 1000×) and uses **N_t times less memory**.

---

## When is Reconstruction Accurate?

### Good Accuracy

✅ Weak to moderate perturbations (linear/weakly nonlinear regime)  
✅ Smooth external fields (no sudden jumps)  
✅ Short correlation times (Markovian dynamics)  
✅ Well-separated energy scales  
✅ Small time step (δt ≤ 0.01 fs)  

### Potential Issues

⚠️ Strong correlations (beyond mean-field)  
⚠️ Non-Markovian dynamics (long memory effects)  
⚠️ Rapid field variations (δt too large)  
⚠️ Strong resonances (need very fine time grid)  

---

## Advanced Features

### 1. Phenomenological Dephasing

Add artificial dephasing to coherences:
```fortran
Rho_deph= 0.1 | eV             # Dephasing rate
```

Effect: Exponentially suppresses valence-conduction coherences.

### 2. Band Filtering

Compute G^< only for specific band combinations:
```fortran
KeepCC                         # Conduction-conduction
KeepVV                         # Valence-valence
KeepCV                         # Conduction-valence (optical)
KeepVC                         # Valence-conduction (optical)
```

### 3. Multiple Green's Functions

```fortran
BuildGles                      # Lesser G^<
BuildGgrt                      # Greater G^>
BuildGret                      # Retarded G^R
BuildGadv                      # Advanced G^A
BuildSpec                      # Spectral function A = i(G^R - G^A)
```

---

## Key Takeaways

1. **Efficient**: O(N_t²) post-processing vs O(N_t³) direct propagation
2. **Practical**: O(N_t) memory during RT vs O(N_t²) for full G^<
3. **Accurate**: For typical RT-TDDFT applications (weak-to-moderate perturbations)
4. **Flexible**: Can compute G^<, G^>, G^R, G^A, and spectral functions
5. **Well-tested**: Based on established Keldysh formalism (PRA 92, 033419, 2015)

---

## References

1. **PRA 92, 033419 (2015)**: "Real-time Green's functions in many-body theories"
2. **Keldysh formalism**: G. Stefanucci and R. van Leeuwen, "Nonequilibrium Many-Body Theory of Quantum Systems" (Cambridge, 2013)
3. **RT-TDDFT in YAMBO**: D. Sangalli et al., J. Chem. Phys. 144, 074103 (2016)

---

**For full details, see**: @ref two_time_reconstruction "Two-Time Green's Function Reconstruction (Full Documentation)"
