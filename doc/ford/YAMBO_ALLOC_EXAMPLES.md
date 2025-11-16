---
title: YAMBO ALLOC EXAMPLES
---

# YAMBO_ALLOC Practical Examples {#alloc_examples}

## Table of Contents
1. [Basic Examples](#basic-examples)
2. [Real-Time Simulation Examples](#real-time-simulation-examples)
3. [GPU Computing Examples](#gpu-computing-examples)
4. [MPI Parallel Examples](#mpi-parallel-examples)
5. [Advanced Patterns](#advanced-patterns)
6. [Common Mistakes and Fixes](#common-mistakes-and-fixes)
7. [Performance Optimization](#performance-optimization)

---

## Basic Examples

### Example 1: Simple 2D Array

```fortran
subroutine example_simple_2d()
  !
  ! Allocate and use a simple 2D complex array
  !
#include<y_memory.h>
  use pars,          ONLY: SP, cZERO
  use y_memory_alloc
  implicit none
  
  complex(SP), allocatable :: matrix(:,:)
  integer :: n, m, i, j
  
  n = 100
  m = 200
  
  ! Allocate
  YAMBO_ALLOC(matrix, (n, m))
  
  ! Initialize
  matrix = cZERO
  
  ! Use
  do j = 1, m
    do i = 1, n
      matrix(i,j) = cmplx(real(i,SP), real(j,SP), SP)
    enddo
  enddo
  
  ! Free
  YAMBO_FREE(matrix)
  
end subroutine example_simple_2d
```

**Output:**
```
[MEMORY] Alloc matrix(156.25 Kb) TOTAL: 156.25 Kb (traced)
[MEMORY]  Free matrix(156.25 Kb) TOTAL: 0.00 Kb (traced)
```

---

### Example 2: Multiple Arrays with Different Types

```fortran
subroutine example_multiple_types()
  !
  ! Allocate arrays of different types
  !
#include<y_memory.h>
  use pars,          ONLY: SP, DP
  use y_memory_alloc
  implicit none
  
  integer,     allocatable :: indices(:)
  real(SP),    allocatable :: energies(:,:)
  real(DP),    allocatable :: high_precision(:)
  complex(SP), allocatable :: wavefunctions(:,:,:)
  logical,     allocatable :: flags(:,:)
  
  integer :: n, nb, nk
  
  n = 1000
  nb = 50
  nk = 10
  
  ! Allocate different types
  YAMBO_ALLOC(indices, (n))                    ! 4 bytes × 1000 = 3.91 Kb
  YAMBO_ALLOC(energies, (nb, nk))              ! 4 bytes × 500 = 1.95 Kb
  YAMBO_ALLOC(high_precision, (n))             ! 8 bytes × 1000 = 7.81 Kb
  YAMBO_ALLOC(wavefunctions, (nb, nk, 1000))   ! 8 bytes × 500,000 = 3.81 Mb
  YAMBO_ALLOC(flags, (nb, nk))                 ! 4 bytes × 500 = 1.95 Kb
  
  ! Initialize
  indices = 0
  energies = 0.0_SP
  high_precision = 0.0_DP
  wavefunctions = (0.0_SP, 0.0_SP)
  flags = .false.
  
  ! Use arrays...
  
  ! Free all
  YAMBO_FREE(indices)
  YAMBO_FREE(energies)
  YAMBO_FREE(high_precision)
  YAMBO_FREE(wavefunctions)
  YAMBO_FREE(flags)
  
end subroutine example_multiple_types
```

---

### Example 3: Custom Index Ranges

```fortran
subroutine example_custom_ranges()
  !
  ! Use custom lower and upper bounds
  !
#include<y_memory.h>
  use pars,          ONLY: SP
  use y_memory_alloc
  implicit none
  
  real(SP), allocatable :: energies(:,:)
  integer :: valence(2), conduction(2), nk
  
  ! Band ranges
  valence    = [-10, 0]    ! Valence bands: -10 to 0
  conduction = [1, 20]     ! Conduction bands: 1 to 20
  nk = 100
  
  ! Allocate with custom ranges
  YAMBO_ALLOC(energies, (valence(1):conduction(2), nk))
  
  ! Now energies is indexed as energies(-10:20, 1:100)
  
  ! Access valence bands
  energies(valence(1):valence(2), :) = -1.0_SP
  
  ! Access conduction bands
  energies(conduction(1):conduction(2), :) = 1.0_SP
  
  ! Free
  YAMBO_FREE(energies)
  
end subroutine example_custom_ranges
```

---

### Example 4: Conditional Allocation

```fortran
subroutine example_conditional(l_use_scattering, l_use_hartree)
  !
  ! Allocate arrays only when needed
  !
#include<y_memory.h>
  use pars,          ONLY: SP, cZERO
  use y_memory_alloc
  implicit none
  
  logical, intent(in) :: l_use_scattering, l_use_hartree
  
  complex(SP), allocatable :: scattering_matrix(:,:,:)
  complex(SP), allocatable :: hartree_potential(:,:)
  integer :: nb, nk, nq
  
  nb = 100
  nk = 50
  nq = 20
  
  ! Allocate scattering matrix only if needed
  if (l_use_scattering) then
    YAMBO_ALLOC(scattering_matrix, (nb, nb, nq))
    scattering_matrix = cZERO
    ! ... compute scattering ...
  endif
  
  ! Allocate Hartree potential only if needed
  if (l_use_hartree) then
    YAMBO_ALLOC(hartree_potential, (nb, nk))
    hartree_potential = cZERO
    ! ... compute Hartree ...
  endif
  
  ! Free only what was allocated
  if (l_use_scattering) YAMBO_FREE(scattering_matrix)
  if (l_use_hartree)    YAMBO_FREE(hartree_potential)
  
end subroutine example_conditional
```

---

## Real-Time Simulation Examples

### Example 5: Green's Functions Allocation

```fortran
subroutine RT_allocate_Greens_functions()
  !
  ! Allocate Green's functions for real-time simulations
  ! Based on src/real_time_control/RT_alloc.F
  !
#include<y_memory.h>
  use pars,          ONLY: SP, cZERO
  use electrons,     ONLY: n_sp_pol
  use parallel_m,    ONLY: PAR_G_k_range
  use real_time,     ONLY: G_lesser, dG_lesser, G_lesser_reference, &
                           RT_bands, RT_nk, G_MEM_steps
  use y_memory_alloc
  implicit none
  
  integer :: nk(2)
  
  ! Get local k-point range for this MPI rank
  nk = PAR_G_k_range  ! e.g., [1, 5] for rank 0
  
  ! Reference Green's function (equilibrium)
  ! Replicated on all ranks (uses RT_nk, not nk)
  YAMBO_ALLOC(G_lesser_reference, (RT_bands(1):RT_bands(2), &
                                   RT_bands(1):RT_bands(2), &
                                   RT_nk, n_sp_pol))
  G_lesser_reference = cZERO
  
  ! Time-dependent Green's function
  ! Distributed over k-points (uses nk(1):nk(2))
  ! Last dimension: G_MEM_steps (2 or 3 time steps)
  YAMBO_ALLOC(G_lesser, (RT_bands(1):RT_bands(2), &
                         RT_bands(1):RT_bands(2), &
                         nk(1):nk(2), n_sp_pol, G_MEM_steps))
  G_lesser = cZERO
  
  ! Time derivative of Green's function
  YAMBO_ALLOC(dG_lesser, (RT_bands(1):RT_bands(2), &
                          RT_bands(1):RT_bands(2), &
                          nk(1):nk(2), n_sp_pol, G_MEM_steps))
  dG_lesser = cZERO
  
  ! Memory usage example (RT_bands=[1,100], nk=[1,5], n_sp_pol=2, G_MEM_steps=3):
  ! G_lesser_reference: 100×100×10×2 × 8 bytes = 1.53 Mb (replicated)
  ! G_lesser:           100×100×5×2×3 × 8 bytes = 2.29 Mb (distributed)
  ! dG_lesser:          100×100×5×2×3 × 8 bytes = 2.29 Mb (distributed)
  ! Total per rank: ~6.1 Mb
  
end subroutine RT_allocate_Greens_functions
```

---

### Example 6: Hamiltonian Matrices

```fortran
subroutine RT_allocate_Hamiltonians(l_velocity_gauge)
  !
  ! Allocate Hamiltonian matrices for RT simulations
  !
#include<y_memory.h>
  use pars,          ONLY: SP, cZERO
  use electrons,     ONLY: n_sp_pol
  use parallel_m,    ONLY: PAR_G_k_range
  use real_time,     ONLY: Ho_plus_Sigma, H_EQ, H_field, H_pseudo_eq, &
                           RT_bands, RT_nk
  use y_memory_alloc
  implicit none
  
  logical, intent(in) :: l_velocity_gauge
  integer :: nk(2)
  
  nk = PAR_G_k_range
  
  ! Hamiltonian with self-energy
  YAMBO_ALLOC(Ho_plus_Sigma, (RT_bands(1):RT_bands(2), &
                              RT_bands(1):RT_bands(2), &
                              nk(1):nk(2), n_sp_pol))
  Ho_plus_Sigma = cZERO
  
  ! Equilibrium Hamiltonian
  YAMBO_ALLOC(H_EQ, (RT_bands(1):RT_bands(2), &
                     RT_bands(1):RT_bands(2), &
                     nk(1):nk(2), n_sp_pol))
  H_EQ = cZERO
  
  ! Field Hamiltonian (light-matter interaction)
  YAMBO_ALLOC(H_field, (RT_bands(1):RT_bands(2), &
                        RT_bands(1):RT_bands(2), &
                        nk(1):nk(2), n_sp_pol))
  H_field = cZERO
  
  ! Pseudo-equilibrium Hamiltonian (velocity gauge correction)
  if (l_velocity_gauge) then
    YAMBO_ALLOC(H_pseudo_eq, (RT_bands(1):RT_bands(2), &
                              RT_bands(1):RT_bands(2), &
                              RT_nk, n_sp_pol))
    H_pseudo_eq = cZERO
  endif
  
end subroutine RT_allocate_Hamiltonians
```

---

### Example 7: Scattering Matrices

```fortran
subroutine RT_allocate_scattering(l_elph, l_elel)
  !
  ! Allocate scattering matrices (very memory intensive!)
  !
#include<y_memory.h>
  use pars,          ONLY: SP, cZERO
  use electrons,     ONLY: n_sp_pol
  use R_lattice,     ONLY: nqibz
  use real_time,     ONLY: RT_bands, RT_nk
  use y_memory_alloc
  implicit none
  
  logical, intent(in) :: l_elph, l_elel
  
  complex(SP), allocatable :: GKKP(:,:,:,:,:)      ! Electron-phonon
  complex(SP), allocatable :: W_eel(:,:,:,:,:)     ! Electron-electron
  
  integer :: nb, nk, nq, n_ph_modes
  
  nb = RT_bands(2) - RT_bands(1) + 1
  nk = RT_nk
  nq = nqibz
  n_ph_modes = 3 * 2  ! 3 directions × 2 atoms (example)
  
  ! Electron-phonon matrix elements
  if (l_elph) then
    YAMBO_ALLOC(GKKP, (nb, nb, nk, nq, n_ph_modes))
    GKKP = cZERO
    
    ! Memory: 100×100×10×20×6 × 8 bytes = 915.5 Mb (HUGE!)
    call warning("Electron-phonon scattering requires large memory!")
  endif
  
  ! Electron-electron screening
  if (l_elel) then
    YAMBO_ALLOC(W_eel, (nb, nb, nk, nq, n_sp_pol))
    W_eel = cZERO
    
    ! Memory: 100×100×10×20×2 × 8 bytes = 305.2 Mb
  endif
  
  ! ... use matrices ...
  
  ! Free
  if (l_elph) YAMBO_FREE(GKKP)
  if (l_elel) YAMBO_FREE(W_eel)
  
end subroutine RT_allocate_scattering
```

---

## GPU Computing Examples

### Example 8: Basic GPU Allocation

```fortran
#if defined _OPENACC
subroutine example_gpu_basic()
  !
  ! Basic GPU memory allocation and computation
  !
#include<y_memory.h>
  use pars,          ONLY: SP
  use y_memory_alloc
  implicit none
  
  real(SP), allocatable :: A(:,:), B(:,:), C(:,:)
  integer :: n, i, j
  
  n = 1000
  
  ! Allocate on host and map to device
  YAMBO_ALLOC_GPU(A, (n, n))
  YAMBO_ALLOC_GPU(B, (n, n))
  YAMBO_ALLOC_GPU(C, (n, n))
  
  ! Initialize on host
  A = 1.0_SP
  B = 2.0_SP
  C = 0.0_SP
  
  ! Update device with host data
  !$acc update device(A, B)
  
  ! Compute on GPU
  !$acc parallel loop collapse(2) present(A, B, C)
  do j = 1, n
    do i = 1, n
      C(i,j) = A(i,j) + B(i,j)
    enddo
  enddo
  !$acc end parallel loop
  
  ! Copy result back to host
  !$acc update host(C)
  
  ! Free GPU memory
  YAMBO_FREE_GPU(A)
  YAMBO_FREE_GPU(B)
  YAMBO_FREE_GPU(C)
  
end subroutine example_gpu_basic
#endif
```

**Output:**
```
[MEMORY] Alloc A(3.81 Mb) (DEV) TOTAL: 3.81 Mb (traced)
[MEMORY] Alloc B(3.81 Mb) (DEV) TOTAL: 7.63 Mb (traced)
[MEMORY] Alloc C(3.81 Mb) (DEV) TOTAL: 11.44 Mb (traced)
[MEMORY]  Free A(3.81 Mb) (DEV) TOTAL: 7.63 Mb (traced)
[MEMORY]  Free B(3.81 Mb) (DEV) TOTAL: 3.81 Mb (traced)
[MEMORY]  Free C(3.81 Mb) (DEV) TOTAL: 0.00 Mb (traced)
```

---

### Example 9: GPU Matrix Multiplication

```fortran
#if defined _OPENACC
subroutine example_gpu_matmul()
  !
  ! Matrix multiplication on GPU
  !
#include<y_memory.h>
  use pars,          ONLY: SP
  use y_memory_alloc
  implicit none
  
  complex(SP), allocatable :: A(:,:), B(:,:), C(:,:)
  integer :: n, i, j, k
  complex(SP) :: sum_val
  
  n = 500
  
  ! Allocate GPU arrays
  YAMBO_ALLOC_GPU(A, (n, n))
  YAMBO_ALLOC_GPU(B, (n, n))
  YAMBO_ALLOC_GPU(C, (n, n))
  
  ! Initialize
  A = (1.0_SP, 0.0_SP)
  B = (0.0_SP, 1.0_SP)
  C = (0.0_SP, 0.0_SP)
  
  !$acc update device(A, B, C)
  
  ! Matrix multiplication: C = A × B
  !$acc parallel loop collapse(2) present(A, B, C) private(sum_val)
  do j = 1, n
    do i = 1, n
      sum_val = (0.0_SP, 0.0_SP)
      do k = 1, n
        sum_val = sum_val + A(i,k) * B(k,j)
      enddo
      C(i,j) = sum_val
    enddo
  enddo
  !$acc end parallel loop
  
  !$acc update host(C)
  
  ! Free
  YAMBO_FREE_GPU(A)
  YAMBO_FREE_GPU(B)
  YAMBO_FREE_GPU(C)
  
end subroutine example_gpu_matmul
#endif
```

---

### Example 10: Mixed Host-Device Memory

```fortran
#if defined _OPENACC
subroutine example_mixed_memory()
  !
  ! Some arrays on host, some on device
  !
#include<y_memory.h>
  use pars,          ONLY: SP
  use y_memory_alloc
  implicit none
  
  real(SP), allocatable :: host_data(:,:)      ! Host only
  real(SP), allocatable :: device_data(:,:)    ! Device
  real(SP), allocatable :: result(:)           ! Host only
  integer :: n, i, j
  
  n = 1000
  
  ! Host-only array (large, rarely accessed)
  YAMBO_ALLOC(host_data, (n, n))
  host_data = 1.0_SP
  
  ! Device array (frequently accessed in computation)
  YAMBO_ALLOC_GPU(device_data, (n, n))
  device_data = 0.0_SP
  
  ! Result array (host only)
  YAMBO_ALLOC(result, (n))
  result = 0.0_SP
  
  ! Copy subset to device
  device_data(1:100, :) = host_data(1:100, :)
  !$acc update device(device_data)
  
  ! Compute on GPU
  !$acc parallel loop present(device_data)
  do i = 1, n
    device_data(i,:) = device_data(i,:) * 2.0_SP
  enddo
  !$acc end parallel loop
  
  ! Copy result back
  !$acc update host(device_data)
  
  ! Reduce on host
  do i = 1, n
    result(i) = sum(device_data(i,:))
  enddo
  
  ! Free
  YAMBO_FREE(host_data)
  YAMBO_FREE_GPU(device_data)
  YAMBO_FREE(result)
  
end subroutine example_mixed_memory
#endif
```

---

## MPI Parallel Examples

### Example 11: K-point Distribution

```fortran
subroutine example_kpoint_distribution()
  !
  ! Distribute k-points across MPI ranks
  !
#include<y_memory.h>
  use pars,          ONLY: SP, cZERO
  use parallel_m,    ONLY: PAR_G_k_range, PAR_COM_HOST
  use y_memory_alloc
  implicit none
  
  complex(SP), allocatable :: G_k(:,:,:)
  integer :: nb, nk_local, nk_total
  integer :: LOCAL_SIZE(3), HOST_SIZE(3)
  
  nb = 100
  nk_total = 100
  
  ! Each rank gets a subset of k-points
  nk_local = PAR_G_k_range(2) - PAR_G_k_range(1) + 1
  
  ! Example distribution for 4 ranks:
  ! Rank 0: k-points 1-25   (nk_local=25)
  ! Rank 1: k-points 26-50  (nk_local=25)
  ! Rank 2: k-points 51-75  (nk_local=25)
  ! Rank 3: k-points 76-100 (nk_local=25)
  
  LOCAL_SIZE = [nb, nb, nk_local]
  
  ! Parallel allocation with global reporting
  YAMBO_PAR_ALLOC3(G_k, LOCAL_SIZE)
  
  ! Each rank has G_k(100, 100, 25) = 1.91 Mb
  ! Total across 4 ranks: 7.63 Mb
  
  G_k = cZERO
  
  ! Each rank works on its local k-points
  ! ... computation ...
  
  YAMBO_FREE(G_k)
  
end subroutine example_kpoint_distribution
```

**Output (from master rank):**
```
[MEMORY] Global allocation: G_k (7.63 Mb across 4 ranks)
[MEMORY] Alloc G_k(1.91 Mb) TOTAL: 1.91 Mb (traced)
```

---

### Example 12: Band Parallelization

```fortran
subroutine example_band_parallelization()
  !
  ! Distribute bands across MPI ranks
  !
#include<y_memory.h>
  use pars,          ONLY: SP
  use parallel_m,    ONLY: PAR_COM_BAND, myid
  use y_memory_alloc
  implicit none
  
  real(SP), allocatable :: energies(:,:)
  integer :: nb_total, nb_local, nk
  integer :: ib_start, ib_end
  
  nb_total = 200
  nk = 50
  
  ! Distribute bands across ranks
  nb_local = nb_total / PAR_COM_BAND%n_CPU
  ib_start = myid * nb_local + 1
  ib_end   = (myid + 1) * nb_local
  
  ! Example for 4 ranks:
  ! Rank 0: bands 1-50
  ! Rank 1: bands 51-100
  ! Rank 2: bands 101-150
  ! Rank 3: bands 151-200
  
  YAMBO_ALLOC(energies, (ib_start:ib_end, nk))
  
  ! Each rank: energies(50, 50) = 9.77 Kb
  
  energies = 0.0_SP
  
  ! ... computation ...
  
  YAMBO_FREE(energies)
  
end subroutine example_band_parallelization
```

---

## Advanced Patterns

### Example 13: Memory Pooling

```fortran
module memory_pool
  !
  ! Reusable memory pool to avoid repeated allocation/deallocation
  !
#include<y_memory.h>
  use pars,          ONLY: SP
  use y_memory_alloc
  implicit none
  
  complex(SP), allocatable :: work_array(:,:)
  logical :: pool_initialized = .false.
  
contains
  
  subroutine pool_init(n, m)
    integer, intent(in) :: n, m
    if (.not. pool_initialized) then
      YAMBO_ALLOC(work_array, (n, m))
      pool_initialized = .true.
    endif
  end subroutine
  
  subroutine pool_cleanup()
    if (pool_initialized) then
      YAMBO_FREE(work_array)
      pool_initialized = .false.
    endif
  end subroutine
  
  subroutine use_pool()
    ! Use work_array without allocating
    if (.not. pool_initialized) call error("Pool not initialized!")
    work_array = (0.0_SP, 0.0_SP)
    ! ... computation ...
  end subroutine
  
end module memory_pool

subroutine example_memory_pool()
  use memory_pool
  implicit none
  
  ! Initialize pool once
  call pool_init(1000, 1000)
  
  ! Use multiple times without reallocation
  call use_pool()
  call use_pool()
  call use_pool()
  
  ! Cleanup at end
  call pool_cleanup()
  
end subroutine example_memory_pool
```

---

### Example 14: Dynamic Resizing

```fortran
subroutine example_dynamic_resize()
  !
  ! Resize array when needed
  !
#include<y_memory.h>
  use pars,          ONLY: SP
  use y_memory_alloc
  implicit none
  
  real(SP), allocatable :: data(:)
  real(SP), allocatable :: temp(:)
  integer :: current_size, new_size, i
  
  ! Initial allocation
  current_size = 100
  YAMBO_ALLOC(data, (current_size))
  data = 0.0_SP
  
  ! Fill data
  do i = 1, current_size
    data(i) = real(i, SP)
  enddo
  
  ! Need more space
  new_size = 200
  
  ! Allocate temporary array
  YAMBO_ALLOC(temp, (new_size))
  temp = 0.0_SP
  
  ! Copy old data
  temp(1:current_size) = data(1:current_size)
  
  ! Free old array
  YAMBO_FREE(data)
  
  ! Reallocate with new size
  YAMBO_ALLOC(data, (new_size))
  data = temp
  
  ! Free temporary
  YAMBO_FREE(temp)
  
  ! Now data has size 200
  current_size = new_size
  
  ! Cleanup
  YAMBO_FREE(data)
  
end subroutine example_dynamic_resize
```

---

### Example 15: Hierarchical Allocation

```fortran
subroutine example_hierarchical()
  !
  ! Allocate arrays in hierarchical structure
  !
#include<y_memory.h>
  use pars,          ONLY: SP, cZERO
  use y_memory_alloc
  implicit none
  
  ! Level 1: System properties
  complex(SP), allocatable :: wavefunctions(:,:,:)
  real(SP),    allocatable :: energies(:,:)
  
  ! Level 2: Derived quantities
  complex(SP), allocatable :: density_matrix(:,:,:)
  complex(SP), allocatable :: current(:,:)
  
  ! Level 3: Observables
  real(SP),    allocatable :: polarization(:)
  real(SP),    allocatable :: absorption(:)
  
  integer :: nb, nk, nt
  
  nb = 100
  nk = 50
  nt = 1000
  
  ! Allocate level 1 (fundamental)
  YAMBO_ALLOC(wavefunctions, (nb, nk, 1000))
  YAMBO_ALLOC(energies, (nb, nk))
  
  ! Allocate level 2 (derived from level 1)
  YAMBO_ALLOC(density_matrix, (nb, nb, nk))
  YAMBO_ALLOC(current, (3, nt))
  
  ! Allocate level 3 (observables)
  YAMBO_ALLOC(polarization, (nt))
  YAMBO_ALLOC(absorption, (nt))
  
  ! Initialize
  wavefunctions = cZERO
  energies = 0.0_SP
  density_matrix = cZERO
  current = cZERO
  polarization = 0.0_SP
  absorption = 0.0_SP
  
  ! ... computation ...
  
  ! Free in reverse order (level 3 → 2 → 1)
  YAMBO_FREE(absorption)
  YAMBO_FREE(polarization)
  
  YAMBO_FREE(current)
  YAMBO_FREE(density_matrix)
  
  YAMBO_FREE(energies)
  YAMBO_FREE(wavefunctions)
  
end subroutine example_hierarchical
```

---

## Common Mistakes and Fixes

### Mistake 1: Allocating in Loop

**❌ Wrong:**
```fortran
do iter = 1, 1000
  YAMBO_ALLOC(temp, (n, n))
  ! ... use temp ...
  YAMBO_FREE(temp)
enddo
```

**✅ Correct:**
```fortran
YAMBO_ALLOC(temp, (n, n))
do iter = 1, 1000
  ! ... use temp ...
enddo
YAMBO_FREE(temp)
```

---

### Mistake 2: Forgetting to Free

**❌ Wrong:**
```fortran
subroutine compute()
  YAMBO_ALLOC(work, (n, n))
  ! ... use work ...
  ! Missing: YAMBO_FREE(work)
end subroutine
```

**✅ Correct:**
```fortran
subroutine compute()
  YAMBO_ALLOC(work, (n, n))
  ! ... use work ...
  YAMBO_FREE(work)
end subroutine
```

---

### Mistake 3: Double Allocation

**❌ Wrong:**
```fortran
YAMBO_ALLOC(array, (n, m))
! ... some code ...
YAMBO_ALLOC(array, (n, m))  ! ERROR: Already allocated!
```

**✅ Correct:**
```fortran
if (allocated(array)) YAMBO_FREE(array)
YAMBO_ALLOC(array, (n, m))
```

---

### Mistake 4: Wrong GPU Free

**❌ Wrong:**
```fortran
YAMBO_ALLOC_GPU(array, (n, m))
! ...
YAMBO_FREE(array)  ! ERROR: Still mapped on device!
```

**✅ Correct:**
```fortran
YAMBO_ALLOC_GPU(array, (n, m))
! ...
YAMBO_FREE_GPU(array)
```

---

## Performance Optimization

### Optimization 1: Minimize Allocations

**Slow:**
```fortran
do i = 1, n_iterations
  YAMBO_ALLOC(temp, (n, n))
  call compute(temp)
  YAMBO_FREE(temp)
enddo
```

**Fast:**
```fortran
YAMBO_ALLOC(temp, (n, n))
do i = 1, n_iterations
  call compute(temp)
enddo
YAMBO_FREE(temp)
```

---

### Optimization 2: Free Early

**Memory-hungry:**
```fortran
YAMBO_ALLOC(A, (n, n))
YAMBO_ALLOC(B, (n, n))
YAMBO_ALLOC(C, (n, n))

call step1(A, B)
call step2(B, C)

YAMBO_FREE(A)
YAMBO_FREE(B)
YAMBO_FREE(C)
```

**Memory-efficient:**
```fortran
YAMBO_ALLOC(A, (n, n))
YAMBO_ALLOC(B, (n, n))

call step1(A, B)
YAMBO_FREE(A)  ! Free as soon as done

YAMBO_ALLOC(C, (n, n))
call step2(B, C)
YAMBO_FREE(B)
YAMBO_FREE(C)
```

---

### Optimization 3: Use Appropriate Precision

**Memory-hungry:**
```fortran
complex(DP) :: array(n, n)  ! 16 bytes per element
YAMBO_ALLOC(array, (n, n))
```

**Memory-efficient (if precision allows):**
```fortran
complex(SP) :: array(n, n)  ! 8 bytes per element (50% less!)
YAMBO_ALLOC(array, (n, n))
```

---

## Summary

| Pattern | Use Case | Example |
|---------|----------|---------|
| Basic allocation | Simple arrays | `YAMBO_ALLOC(A, (n, m))` |
| Custom ranges | Band/k-point ranges | `YAMBO_ALLOC(E, (nb(1):nb(2), nk))` |
| Conditional | Optional features | `if (l_use) YAMBO_ALLOC(...)` |
| GPU | GPU computing | `YAMBO_ALLOC_GPU(A, (n, m))` |
| MPI | Parallel distribution | `YAMBO_PAR_ALLOC3(A, SIZE)` |
| Memory pool | Repeated use | Allocate once, reuse many times |
| Dynamic resize | Growing arrays | Allocate temp, copy, reallocate |

**Key Takeaways:**
- Always use `YAMBO_ALLOC`/`YAMBO_FREE`
- Allocate outside loops when possible
- Free memory as soon as it's no longer needed
- Use appropriate precision (SP vs DP)
- Check `allocated()` before freeing
- Use GPU-specific macros for device memory
- Use parallel macros for MPI-distributed arrays

---