# Kadanoff-Baym Equations Implementation in Yambo/YAMBO {#kb_implementation}

@page kb_implementation Kadanoff-Baym Implementation Analysis

@tableofcontents

## Executive Summary

**YES**, Yambo/YAMBO **does support the general Kadanoff-Baym equations** and implements time propagation of Green's functions. However, there are important implementation details to understand:

### Key Findings

1. ✅ **Kadanoff-Baym Equations**: Fully implemented in the real-time module
2. ⚠️ **Two-Time Propagation**: Uses **time-diagonal approximation** during propagation
3. ✅ **Two-Time Green's Functions**: Can be reconstructed post-simulation for analysis
4. ✅ **Full G^<(t,t')**: Available through YPP post-processing tools

---

## 1. Theoretical Framework

### 1.1 General Kadanoff-Baym Equations

The code implements the Kadanoff-Baym equations for the lesser Green's function:

```
i∂G^<(t)/∂t - [H^RT(t), G^<(t)] = Σ^scatt(t)
```

**Components:**
- `G^<_{nm}(k,t,t')`: Lesser Green's function (two-time object)
- `H^RT(t)`: Time-dependent Hamiltonian
- `Σ^scatt(t)`: Collision self-energy (scattering terms)

**Full two-time form:**
```
G^<_{nm}(k,t,t') = i⟨c†_m(k,t') c_n(k,t)⟩
```

where:
- `n,m` are band indices
- `k` is crystal momentum
- `t,t'` are two independent time arguments
- `c†, c` are creation/annihation operators

**Source**: `src/real_time_drivers/RT_driver.F:53-62`

---

## 2. Time-Diagonal Approximation

### 2.1 What is Actually Propagated

During the real-time simulation, YAMBO uses the **time-diagonal approximation**:

```
G^<_{nm}(k,t) ≡ G^<_{nm}(k,t,t)
```

This reduces the two-time Green's function to a **density matrix**:

```
ρ_{nm}(k,t) = -iG^<_{nm}(k,t,t)
```

**Physical interpretation:**
- **Diagonal elements**: `ρ_{nn}(k,t) = f_n(k,t)` (occupation factors)
- **Off-diagonal elements**: `ρ_{nm}(k,t)` (coherences between states n and m)

**Source**: `doc/doxygen/YAMBO_RT_THEORY_DOCUMENTATION.md:64-80`

### 2.2 Equation of Motion

The propagated equation becomes:

```
i∂ρ(t)/∂t = [H^RT(t), ρ(t)] - iΣ^scatt(t)
```

This is a **single-time** equation that evolves the density matrix forward in time.

---

## 3. Implementation Details

### 3.1 Core Data Structures

**Module**: `src/modules/mod_real_time.F`

**Key variables:**
```fortran
complex(SP), allocatable :: G_lesser(:,:,:,:,:)
  ! Dimensions: (bands, bands, k-points, spin, time_steps)
  ! G_lesser(:,:,:,:,i_MEM_now) = ρ(t) at current time

complex(SP), allocatable :: dG_lesser(:,:,:,:,:)
  ! Variation: δG = G - G_reference
  ! Used in low-pumping regime for efficiency
```

**Memory management:**
```fortran
integer :: G_MEM_steps  ! Number of time steps stored in memory
integer :: i_MEM_now    ! Current time index
integer :: i_MEM_prev   ! Previous time index
integer :: i_MEM_old    ! Old time index
```

The code uses **circular buffers** to minimize memory usage, storing only a few time steps at once.

### 3.2 Time Propagation Algorithms

**Available integrators** (`src/real_time_propagation/`):

1. **EULER**: Simple forward Euler (1st order)
   ```
   G(t+Δt) = G(t) - iΔt[H(t), G(t)]
   ```

2. **RK2/RK4/HEUN**: Runge-Kutta methods (2nd/4th order)

3. **EXP**: Exponential integrator (Magnus expansion)
   ```
   G(t+Δt) = U(Δt) G(t) U†(Δt)
   U(t) = exp(-iHt) ≈ Σ_{k=0}^N (-iHt)^k/k!
   ```
   - **Source**: `src/real_time_propagation/RT_EXP_step_std.F`
   - **Order**: Typically N=2-6 (controlled by `integrator_exp_order`)
   - **Advantages**: Better unitarity, larger time steps
   - **Most accurate** for slowly-varying Hamiltonians

4. **INV**: Inverse integrator (implicit, unconditionally stable)

5. **DIAG**: Diagonalization-based propagation

**Default**: EXP (exponential) with order 4

### 3.3 Propagation Workflow

**Main driver**: `src/real_time_drivers/RT_driver.F`

**Time loop structure:**
```fortran
do i_t = 1, NE_steps
  ! 1. Build time-dependent Hamiltonian
  call RT_Hamiltonian(dG_lesser(:,:,:,:,i_MEM_now), A_tot, E, k)
  
  ! 2. Propagate density matrix: G(t) → G(t+Δt)
  call RT_Integrator(dG_lesser, E, k, q)
  
  ! 3. Compute observables
  call RT_Observables(E, k, OBSERVABLES)
  
  ! 4. Evaluate scattering terms
  call RT_relaxation(...)
  
  ! 5. Output and save to database
  call RT_output_and_IO_driver(E, k, OBSERVABLES)
  
  ! 6. Update memory indices
  call RT_MEMORY_index(...)
enddo
```

**Key point**: Only the **time-diagonal** `G^<(t,t)` is propagated during the simulation.

---

## 4. Two-Time Green's Functions: Post-Processing

### 4.1 Reconstruction from History

Although only `G^<(t,t)` is propagated, the **full two-time** `G^<(t,t')` can be reconstructed **after** the simulation using the stored history.

**Requirement**: Must enable history saving during RT simulation:
```bash
SaveGhistory = .true.
```

This stores the density matrix at **all time steps** (not just the circular buffer).

### 4.2 YPP Post-Processing Tools

**Module**: `ypp/real_time/RT_G_two_times_*.F`

**Driver**: `RT_G_two_times_driver.F`

**Capabilities:**

#### 1. Build G^<(t,t')

**Routine**: `RT_G_two_times_build.F`

Reads the stored `G^<(t,t)` history and constructs the two-time object:

```fortran
G^<_{nm}(k,t,t') = i f_{nm}(k,t,t')
```

**Input file** (`ypp -y`):
```bash
RealTime
RTGtwotimes
%QPkrange
  1 | 10 | 5 | 8 |  # k-point and band range
%
```

#### 2. Analyze Time-Off-Diagonal Elements

**Physical meaning of** `G^<(t,t')` **for** `t ≠ t'`:
- **Memory effects**: How long the system remembers its past
- **Dephasing**: Decay of off-diagonal elements
- **Correlations**: Time-time correlations in the density matrix

**Applications:**
- Dephasing time analysis
- Memory kernel extraction
- Non-Markovian dynamics

#### 3. Compute Spectral Functions

From `G^<(t,t')`, compute time-resolved spectral function:

```
A(k,ω,t) = -2 Im ∫ G^<(k,t,t') e^(iω(t-t')) dt'
```

**Physical meaning:**
- Time-resolved band structure
- Shows how bands evolve during dynamics
- Includes broadening from scattering

**Input**:
```bash
ypp -y
RealTime
RTGtwotimes
BuildSpec
Rho_deph= 0.1 | eV     # Additional dephasing
% GrEnRange
 -5.0 | 10.0 | eV
%
GrEnSteps= 1000
```

**Output**: `YPP-G_lesser_K*_B*_t_tp.dat`

**Source**: `doc/doxygen/YPP_RT_DOCUMENTATION.md:620-703`

#### 4. Retarded/Advanced Green's Functions

Can also build:
- **Retarded**: `G^R(t,t')`
- **Advanced**: `G^A(t,t')`
- **Greater**: `G^>(t,t')`

**Options**:
```fortran
BuildGret  ! Build G^R
BuildGadv  ! Build G^A
BuildGles  ! Build G^<
BuildGgrt  ! Build G^>
BuildSpec  ! Build spectral function A(ω,t)
```

---

## 5. Limitations and Approximations

### 5.1 Time-Diagonal Propagation

**What this means:**
- The code does **NOT** propagate the full `G^<(t,t')` with two independent time arguments
- Only the **equal-time** slice `G^<(t,t)` is evolved
- This is the **standard approach** in real-time TDDFT

**Why this approximation:**
1. **Computational cost**: Full two-time propagation scales as `O(N_t^2)` vs `O(N_t)`
2. **Memory**: Would require storing `N_t × N_t` matrices instead of `N_t` vectors
3. **Physical justification**: For many observables, equal-time quantities are sufficient

### 5.2 When Time-Diagonal is Valid

The time-diagonal approximation is **valid** when:
- System is in the **Markovian regime** (short memory)
- Scattering is **instantaneous** (no retardation effects)
- Interested in **observables** that depend only on `G^<(t,t)`

Examples:
- Current: `J(t) = Tr[v G^<(t,t)]`
- Occupation: `f_n(k,t) = G^<_{nn}(k,t,t)`
- Energy: `E(t) = Tr[H(t) G^<(t,t)]`

### 5.3 When You Need Full Two-Time

The **full** `G^<(t,t')` is needed for:
- **Non-Markovian dynamics** (long memory effects)
- **Spectral functions** `A(ω,t)` (requires Fourier transform over `t-t'`)
- **Correlation functions** (explicitly depend on two times)
- **Memory kernels** in generalized master equations

**Solution**: Use YPP post-processing to reconstruct from history.

---

## 6. Scattering and Memory Effects

### 6.1 Collision Integrals

The scattering term `Σ^scatt(t)` includes:

**Supported mechanisms:**
- **el-el**: Electron-electron (Coulomb) scattering
- **el-ph**: Electron-phonon scattering
- **el-photon**: Radiative recombination
- **ph-el**: Phonon-electron (for phonon dynamics)

**Activation** (input file):
```bash
ElPhScatt        # Electron-phonon
ElElScatt        # Electron-electron
ElPhotonScatt    # Radiative
```

### 6.2 Memory Effects in Scattering

**Current implementation**: Scattering is treated as **instantaneous** (Markovian):
```
Σ^scatt(t) = Σ[G^<(t,t)]
```

**Memory effects** (retardation) would require:
```
Σ^scatt(t) = ∫ dt' Σ(t,t') G^<(t')
```

This is **not currently implemented** during propagation, but can be analyzed post-hoc using the two-time Green's functions from YPP.

---

## 7. Practical Usage

### 7.1 Standard RT Simulation (Time-Diagonal)

**Input file** (`yambo_rt`):
```bash
negf                     # Real-time dynamics
% RTBands
  1 | 10 |               # Band range
%
RTstep= 0.01 | fs        # Time step
NETime= 100  | fs        # Total time
Integrator= "EXP4"       # Exponential, order 4

# Scattering
ElPhScatt                # Enable el-ph scattering
LifeExtrapolation        # Extrapolate lifetimes

# External field
% Field1_Freq
 2.5 | eV                # Photon energy
%
Field1_Int= 1.E7 | kWLm2 # Intensity
```

**Output**: Time-diagonal quantities
- `o.YPP-RT_current`: Current `J(t)`
- `o.YPP-RT_energy`: Energy `E(t)`
- `o.YPP-RT_occupations`: Occupations `f_n(k,t)`

### 7.2 Two-Time Analysis (Post-Processing)

**Step 1**: Run RT with history saving
```bash
# In yambo_rt input
SaveGhistory = .true.
```

**Step 2**: Post-process with YPP
```bash
ypp -y
```

**Input file** (`ypp`):
```bash
RealTime
RTGtwotimes              # Two-time Green's function
BuildSpec                # Build spectral function

%QPkrange
  1 | 10 | 5 | 8 |       # k-point and band range
%

% GrEnRange
 -5.0 | 10.0 | eV        # Energy range
%
GrEnSteps= 1000          # Energy resolution

Rho_deph= 0.1 | eV       # Additional dephasing (optional)
```

**Output**:
- `YPP-G_lesser_K*_B*_t_tp.dat`: Full `G^<(t,t')` matrices
- `YPP-Spectral_K*_B*.dat`: Spectral functions `A(k,ω,t)`

---

## 8. Comparison with Full Two-Time Propagation

### 8.1 What Yambo/YAMBO Does

**Propagation**: Time-diagonal `G^<(t,t)` only
- **Equation**: `i∂ρ(t)/∂t = [H(t), ρ(t)] - iΣ(t)`
- **Scaling**: `O(N_t × N_b^2 × N_k)`
- **Memory**: `O(N_b^2 × N_k × G_MEM_steps)` (typically 2-3 steps)

**Post-processing**: Reconstruct `G^<(t,t')` from history
- **Requires**: Saving all time steps (`SaveGhistory`)
- **Scaling**: `O(N_t^2)` for analysis
- **Memory**: `O(N_t × N_b^2 × N_k)` for storage

### 8.2 Full Two-Time Propagation (Not Implemented)

**Would require**:
- Propagating `G^<(t,t')` with **both** `t` and `t'` as independent variables
- **Equation**: `i∂G^<(t,t')/∂t = [H(t), G^<(t,t')] + ...`
- **Scaling**: `O(N_t^2 × N_b^2 × N_k)` (prohibitive!)
- **Memory**: `O(N_t^2 × N_b^2 × N_k)` (huge!)

**Why not implemented**:
- Computational cost is **quadratic** in number of time steps
- Memory requirements are **enormous**
- Most physical observables don't need it
- Can be reconstructed when needed

### 8.3 When Each Approach is Appropriate

| Feature | Time-Diagonal | Full Two-Time |
|---------|---------------|---------------|
| **Observables** (J, E, f) | ✅ Sufficient | ⚠️ Overkill |
| **Spectral functions** | ✅ Via post-processing | ✅ Direct |
| **Memory effects** | ⚠️ Markovian only | ✅ Full non-Markovian |
| **Computational cost** | ✅ `O(N_t)` | ❌ `O(N_t^2)` |
| **Memory usage** | ✅ Small | ❌ Huge |
| **Implementation** | ✅ Available | ❌ Not implemented |

---

## 9. Summary and Recommendations

### 9.1 Direct Answer to Your Question

**Q: Does the code support the general Kadanoff-Baym equations?**
- **A: YES** - The KBE are fully implemented in `src/real_time_drivers/RT_driver.F`

**Q: Can it solve with two-time propagation of Green's functions?**
- **A: PARTIALLY** - It uses time-diagonal propagation during simulation, but can reconstruct full two-time Green's functions in post-processing

### 9.2 What You Can Do

✅ **Available:**
1. Solve Kadanoff-Baym equations for `G^<(t,t)` (time-diagonal)
2. Include scattering (el-ph, el-el, el-photon)
3. Apply external fields (laser pulses, DC fields)
4. Compute all standard observables (current, energy, occupations)
5. Reconstruct `G^<(t,t')` from saved history (YPP)
6. Compute spectral functions `A(k,ω,t)` (YPP)
7. Analyze dephasing and memory effects (YPP)

❌ **Not available:**
1. Direct propagation of full `G^<(t,t')` with two independent times
2. Non-Markovian scattering during propagation (only in post-analysis)

### 9.3 Recommended Workflow

**For most applications:**
1. Run RT simulation with time-diagonal propagation (fast, efficient)
2. Enable `SaveGhistory` if you need two-time analysis
3. Use YPP to compute spectral functions or analyze memory effects

**For non-Markovian dynamics:**
1. Run RT simulation with `SaveGhistory = .true.`
2. Use YPP to reconstruct `G^<(t,t')`
3. Analyze memory kernels and correlation functions
4. Consider implementing custom post-processing if needed

### 9.4 Theoretical Justification

The time-diagonal approximation is **standard** in real-time TDDFT and is justified by:
1. **Adiabatic approximation**: XC functional depends only on instantaneous density
2. **Markovian scattering**: Collision integrals are local in time
3. **Computational efficiency**: Allows simulations of realistic systems

For systems where these approximations break down, the two-time reconstruction in YPP provides a path forward.

---

## 10. References

### Code Files
- **Main driver**: `src/real_time_drivers/RT_driver.F`
- **Module**: `src/modules/mod_real_time.F`
- **Integrators**: `src/real_time_propagation/RT_*_step*.F`
- **Two-time tools**: `ypp/real_time/RT_G_two_times_*.F`

### Documentation
- @ref yambo_rt_theory_main "Real-Time Theory Documentation"
- @ref ypp_rt_main "YPP Real-Time Post-Processing"
- @ref yambo_rt_theory_doc "Kadanoff-Baym Equations Details"

### Key Papers
- Marques et al., "Time-dependent density functional theory", Annu. Rev. Phys. Chem. (2004)
- Stefanucci & van Leeuwen, "Nonequilibrium Many-Body Theory of Quantum Systems" (2013)
- Attaccalite et al., "Real-time approach to the optical properties of solids", PRB (2011)

---

## Appendix: Code Examples

### A.1 Checking if Two-Time Propagation is Active

```fortran
! In src/modules/mod_real_time.F
logical :: SAVE_G_history  ! If .true., saves full history

! In src/real_time_drivers/RT_driver.F
if (SAVE_G_history) then
  ! Store G_lesser at all time steps
  ! Enables two-time reconstruction in YPP
endif
```

### A.2 Memory Management

```fortran
! Circular buffer for time-dependent quantities
integer :: G_MEM_steps = 2  ! Default: only 2 steps in memory

! Memory indices
integer :: i_MEM_now   ! Current time: t
integer :: i_MEM_prev  ! Previous time: t-Δt
integer :: i_MEM_old   ! Old time: t-2Δt

! Access density matrix at current time
G_lesser(:,:,:,:,i_MEM_now)
```

### A.3 Time Propagation (Exponential Integrator)

```fortran
! From src/real_time_propagation/RT_EXP_step_std.F

! Build evolution operators
U1 = exp(-iH*Δt) ≈ Σ_{k=0}^N (-iHΔt)^k/k!
U2 = exp(+iH*Δt) ≈ Σ_{k=0}^N (+iHΔt)^k/k!

! Propagate density matrix
G(t+Δt) = U1 * G(t) * U2
```

---

**Last updated**: 2025-01-15
**Author**: Analysis based on Yambo/YAMBO source code and documentation