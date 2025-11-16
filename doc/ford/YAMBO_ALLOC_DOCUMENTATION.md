---
title: YAMBO ALLOC DOCUMENTATION
---

# YAMBO Memory Allocation System Documentation {#alloc_doc}

## Table of Contents
1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Core Macros](#core-macros)
4. [Memory Tracking System](#memory-tracking-system)
5. [Usage Examples](#usage-examples)
6. [GPU/Device Memory](#gpu-device-memory)
7. [Parallel Memory Allocation](#parallel-memory-allocation)
8. [Best Practices](#best-practices)
9. [Troubleshooting](#troubleshooting)

---

## Overview

YAMBO implements a sophisticated memory management system that provides:

- **Automatic memory tracking**: All allocations are logged and monitored
- **Memory usage reporting**: Real-time memory consumption statistics
- **Error handling**: Comprehensive allocation failure detection
- **GPU support**: Unified interface for host and device memory
- **MPI awareness**: Parallel memory allocation with global statistics
- **Memory limits**: User-configurable memory caps to prevent overallocation

The system is built around preprocessor macros (`YAMBO_ALLOC`, `YAMBO_FREE`) that wrap Fortran's native `allocate`/`deallocate` with tracking and error handling.

---

## Architecture

### File Structure

```
include/headers/common/
├── y_memory.h              # Core allocation/deallocation macros
└── parallel_memory.h       # MPI-aware allocation macros

src/modules/
└── mod_memory.F            # Memory module with tracking infrastructure

src/memory/
├── MEM_manager_alloc.F     # Allocation tracking logic
├── MEM_free.F              # Deallocation tracking logic
├── MEM_error.F             # Error reporting
├── MEM_manager_init.F      # Memory system initialization
├── MEM_manager_messages.F  # Memory usage messages
├── MEM_library.F           # Memory library/shelf system
└── MEM_report.F            # Memory usage reports
```

### Key Components

1. **Macros** (`y_memory.h`): Preprocessor macros that expand to allocation code + tracking
2. **Memory Module** (`mod_memory.F`): Data structures for tracking allocations
3. **Manager Functions**: Backend functions that maintain allocation database
4. **Reporting System**: Real-time and summary memory usage reports

---

## Core Macros

### Basic Allocation: `YAMBO_ALLOC`

**Syntax:**
```fortran
YAMBO_ALLOC(array_name, (dimensions))
```

**What it does:**
1. Allocates the array using Fortran's `allocate`
2. Checks allocation status (`stat=MEM_err`)
3. Captures error messages (`errmsg=MEM_msg`)
4. Calls `MEM_count()` to register the allocation
5. Calls `MEM_error()` if allocation fails

**Macro Definition:**
```c
#define YAMBO_ALLOC(x,SIZE) \
  allocate(x SIZE,  &NEWLINE& stat=MEM_err,errmsg=MEM_msg)NEWLINE \
  YAMBO_ALLOC_CHECK(x)

#define YAMBO_ALLOC_CHECK(x) \
  if (     allocated(x)) &NEWLINE& call MEM_count(QUOTES x QUOTES,x)NEWLINE \
  if (.not.allocated(x)) &NEWLINE& call MEM_error(QUOTES x QUOTES)
```

**Example:**
```fortran
use y_memory_alloc
complex(SP), allocatable :: G_lesser(:,:,:,:)

! Allocate G_lesser(nb, nb, nk, nsp)
YAMBO_ALLOC(G_lesser, (RT_bands(1):RT_bands(2), RT_bands(1):RT_bands(2), nk(1):nk(2), n_sp_pol))
```

**Expanded code (approximately):**
```fortran
allocate(G_lesser(RT_bands(1):RT_bands(2), RT_bands(1):RT_bands(2), nk(1):nk(2), n_sp_pol), &
         stat=MEM_err, errmsg=MEM_msg)
if (allocated(G_lesser)) call MEM_count("G_lesser", G_lesser)
if (.not.allocated(G_lesser)) call MEM_error("G_lesser")
```

---

### Pointer Allocation: `YAMBO_ALLOC_P`

For pointer arrays (less common in modern Fortran):

```fortran
YAMBO_ALLOC_P(pointer_name, (dimensions))
```

**Difference from `YAMBO_ALLOC`:**
- Uses `associated()` instead of `allocated()`
- Designed for pointer variables

---

### Source/Mold Allocation

**`YAMBO_ALLOC_SOURCE`**: Allocate and copy from source
```fortran
YAMBO_ALLOC_SOURCE(new_array, source_array)
```

**`YAMBO_ALLOC_MOLD`**: Allocate with same type/shape as mold
```fortran
YAMBO_ALLOC_MOLD(new_array, template_array)
```

---

### Deallocation: `YAMBO_FREE`

**Syntax:**
```fortran
YAMBO_FREE(array_name)
```

**What it does:**
1. Checks if array is allocated
2. Calls `MEM_free()` to unregister the allocation
3. Deallocates the array
4. (GPU version) Checks that device memory is unmapped first

**Macro Definition:**
```c
#define YAMBO_FREE(x) \
  if (.not.allocated(x)) &NEWLINE& call MEM_free(QUOTES x QUOTES,int(-1,KIND=IPL))NEWLINE \
  if (     allocated(x)) &NEWLINE& call MEM_free(QUOTES x QUOTES,size(x,KIND=IPL))NEWLINE \
  if (     allocated(x)) &NEWLINE& deallocate(x)
```

**Example:**
```fortran
YAMBO_FREE(G_lesser)
```

**Expanded code:**
```fortran
if (.not.allocated(G_lesser)) call MEM_free("G_lesser", int(-1,KIND=IPL))
if (allocated(G_lesser)) call MEM_free("G_lesser", size(G_lesser,KIND=IPL))
if (allocated(G_lesser)) deallocate(G_lesser)
```

---

## Memory Tracking System

### How Tracking Works

When you call `YAMBO_ALLOC`, the system:

1. **Calculates memory size:**
   ```fortran
   MEM_now_Kb = (array_size * element_kind) / Kilobyte
   ```
   - `array_size`: Total number of elements
   - `element_kind`: Bytes per element (4 for SP, 8 for DP, 8 for complex SP)

2. **Updates global counters:**
   ```fortran
   TOT_MEM_Kb(where) = TOT_MEM_Kb(where) + MEM_now_Kb
   ```
   - `where`: `HOST_` (1) or `DEV_` (2) for GPU

3. **Registers in database:**
   - **SHELF**: Logical grouping (e.g., "G_lesser", "Hamiltonian")
   - **COMPONENT**: Individual array within a shelf
   - **Metadata**: Name, size, kind, location (host/device), section

4. **Generates messages:**
   ```
   [MEMORY] Alloc G_lesser(234.5 Mb) TOTAL: 1.23 Gb (traced)
   ```

### Data Structures

**`MEM_element` type** (from `mod_memory.F`):
```fortran
type MEM_element
  character(schlen) :: shelf                                    ! Logical group name
  integer           :: use                                      ! Total memory used (Kb)
  integer           :: N                                        ! Number of components
  character(schlen) :: name(N_MEM_max_element_components)      ! Component names
  character(schlen) :: desc(N_MEM_max_element_components)      ! Section/description
  integer           :: kind(N_MEM_max_element_components)      ! Bytes per element
  integer(IPL)      :: size(N_MEM_max_element_components)      ! Number of elements
  integer(IPL)      :: where(N_MEM_max_element_components)     ! HOST_ or DEV_
  logical           :: composed(N_MEM_max_element_components)  ! Multi-part allocation?
end type MEM_element
```

**Global arrays:**
```fortran
type(MEM_element) :: MEMs(N_MEM_max)              ! All allocations
type(MEM_element) :: LARGE_MEMs(N_MEM_SAVE_max)   ! Large allocations (>10 Mb)
integer           :: N_MEM_elements                ! Current number of allocations
integer(IP)       :: TOT_MEM_Kb(2)                 ! Total memory: (1)=HOST, (2)=DEV
integer(IP)       :: MAX_MEM_Kb(2)                 ! Peak memory usage
```

### Memory Shelves and Libraries

YAMBO organizes memory into **shelves** (logical groups):

- Arrays with similar names or related functionality are grouped
- Example: `G_lesser`, `dG_lesser`, `G_lesser_reference` → shelf `"[G_lesser]"`
- Shelves are defined in `MEM_library.F`

**Benefits:**
- Cleaner memory reports
- Easier to track related allocations
- Hierarchical memory organization

---

## Usage Examples

### Example 1: Simple Array Allocation

```fortran
subroutine allocate_wavefunction(nb, nk, ng)
  use pars,          ONLY: SP
  use y_memory_alloc
  implicit none
  
  integer, intent(in) :: nb, nk, ng
  complex(SP), allocatable :: WF(:,:,:)
  
  ! Allocate wavefunction array
  YAMBO_ALLOC(WF, (nb, nk, ng))
  
  ! Use the array...
  WF = (0.0_SP, 0.0_SP)
  
  ! Free when done
  YAMBO_FREE(WF)
end subroutine
```

**Output:**
```
[MEMORY] Alloc WF(45.6 Mb) TOTAL: 123.4 Mb (traced)
[MEMORY]  Free WF(45.6 Mb) TOTAL: 77.8 Mb (traced)
```

---

### Example 2: Real-Time Green's Functions (from `RT_alloc.F`)

```fortran
subroutine RT_alloc(en, what)
  use real_time,      ONLY: G_lesser, dG_lesser, G_lesser_reference, &
                            RT_bands, RT_nk, G_MEM_steps
  use electrons,      ONLY: n_sp_pol
  use parallel_m,     ONLY: PAR_G_k_range
  use y_memory_alloc
  implicit none
  
  integer :: nk(2)
  
  nk = PAR_G_k_range  ! Local k-point range for this MPI rank
  
  ! Reference Green's function (equilibrium)
  YAMBO_ALLOC(G_lesser_reference, (RT_bands(1):RT_bands(2), &
                                   RT_bands(1):RT_bands(2), &
                                   RT_nk, n_sp_pol))
  
  ! Time-dependent Green's function
  YAMBO_ALLOC(G_lesser, (RT_bands(1):RT_bands(2), &
                         RT_bands(1):RT_bands(2), &
                         nk(1):nk(2), n_sp_pol, G_MEM_steps))
  
  ! Time derivative of Green's function
  YAMBO_ALLOC(dG_lesser, (RT_bands(1):RT_bands(2), &
                          RT_bands(1):RT_bands(2), &
                          nk(1):nk(2), n_sp_pol, G_MEM_steps))
  
  ! Initialize
  G_lesser_reference = cZERO
  G_lesser = cZERO
  dG_lesser = cZERO
  
end subroutine
```

**Key points:**
- Uses band ranges: `RT_bands(1):RT_bands(2)` (e.g., 1:100)
- Uses local k-point range: `nk(1):nk(2)` (MPI-distributed)
- `G_MEM_steps`: Number of time steps to keep in memory (2 or 3)

---

### Example 3: Conditional Allocation

```fortran
subroutine allocate_scattering_matrices(l_elph, l_elel)
  use y_memory_alloc
  implicit none
  
  logical, intent(in) :: l_elph, l_elel
  complex(SP), allocatable :: GKKP(:,:,:,:)
  complex(SP), allocatable :: W_eel(:,:,:,:)
  
  ! Allocate electron-phonon matrix only if needed
  if (l_elph) then
    YAMBO_ALLOC(GKKP, (nb, nb, nq, n_ph_modes))
    GKKP = cZERO
  endif
  
  ! Allocate electron-electron screening only if needed
  if (l_elel) then
    YAMBO_ALLOC(W_eel, (nb, nb, nq, n_freqs))
    W_eel = cZERO
  endif
  
  ! ... computation ...
  
  ! Clean up
  if (l_elph) YAMBO_FREE(GKKP)
  if (l_elel) YAMBO_FREE(W_eel)
  
end subroutine
```

---

### Example 4: Multi-dimensional Arrays with Custom Ranges

```fortran
subroutine allocate_hamiltonian()
  use y_memory_alloc
  use real_time, ONLY: RT_bands, RT_nk
  use electrons, ONLY: n_sp_pol
  implicit none
  
  complex(SP), allocatable :: H(:,:,:,:)
  integer :: nb(2), nk
  
  nb = RT_bands  ! e.g., [1, 100]
  nk = RT_nk     ! e.g., 10
  
  ! Allocate with custom lower bounds
  YAMBO_ALLOC(H, (nb(1):nb(2), nb(1):nb(2), nk, n_sp_pol))
  
  ! Now H is indexed as H(1:100, 1:100, 1:10, 1:2)
  ! Not H(1:100, 1:100, 1:10, 1:2) with default bounds
  
  YAMBO_FREE(H)
end subroutine
```

---

## GPU/Device Memory

### GPU Allocation Macros

When compiled with GPU support (`_OPENACC` or `_OPENMP_GPU`):

**`YAMBO_ALLOC_GPU`**: Allocate on host and map to device
```fortran
YAMBO_ALLOC_GPU(array, (dimensions))
```

**What it does:**
1. Allocates on host (if not already allocated)
2. Maps to device memory using `devxlib_map()`
3. Tracks device memory separately

**`YAMBO_FREE_GPU`**: Unmap from device and deallocate
```fortran
YAMBO_FREE_GPU(array)
```

**What it does:**
1. Unmaps from device using `devxlib_unmap()`
2. Deallocates host memory

### Example: GPU Memory Management

```fortran
#if defined _OPENACC
subroutine compute_on_gpu()
  use y_memory_alloc
  implicit none
  
  complex(SP), allocatable :: A(:,:), B(:,:), C(:,:)
  integer :: n
  
  n = 1000
  
  ! Allocate and map to GPU
  YAMBO_ALLOC_GPU(A, (n, n))
  YAMBO_ALLOC_GPU(B, (n, n))
  YAMBO_ALLOC_GPU(C, (n, n))
  
  ! Initialize on host
  A = 1.0_SP
  B = 2.0_SP
  
  ! Compute on GPU
  !$acc parallel loop collapse(2) present(A, B, C)
  do j = 1, n
    do i = 1, n
      C(i,j) = A(i,j) * B(i,j)
    enddo
  enddo
  !$acc end parallel loop
  
  ! Free GPU memory
  YAMBO_FREE_GPU(A)
  YAMBO_FREE_GPU(B)
  YAMBO_FREE_GPU(C)
  
end subroutine
#endif
```

### Memory Tracking: Host vs Device

The system tracks host and device memory separately:

```fortran
integer(IP) :: TOT_MEM_Kb(2)
! TOT_MEM_Kb(HOST_) = Host memory (CPU)
! TOT_MEM_Kb(DEV_)  = Device memory (GPU)
```

**Output example:**
```
[MEMORY] Alloc A(7.63 Mb) (DEV) TOTAL: 234.5 Mb (traced)
```

---

## Parallel Memory Allocation

### MPI-Aware Allocation

For MPI-parallel runs, YAMBO provides macros that:
1. Allocate local memory on each rank
2. Collect global memory statistics
3. Report total memory across all ranks

**Macros:**
```fortran
YAMBO_PAR_ALLOC1(array, SIZE)  ! 1D array
YAMBO_PAR_ALLOC2(array, SIZE)  ! 2D array
YAMBO_PAR_ALLOC3(array, SIZE)  ! 3D array
... up to YAMBO_PAR_ALLOC6
```

**How it works:**
```c
#define YAMBO_PAR_ALLOC3(x,SIZE) \
  YAMBO_PAR_ALLOC_CHECK3(x,SIZE) NEWLINE \
  YAMBO_ALLOC3(x,LOCAL_SIZE)
```

Where `YAMBO_PAR_ALLOC_CHECK3`:
1. Computes `LOCAL_SIZE` (local to this rank)
2. Reduces to get `HOST_SIZE` (sum across all ranks)
3. Master rank allocates temporary array with `HOST_SIZE`
4. Calls `MEM_global_mesg()` to report global memory
5. Deallocates temporary array
6. All ranks wait at barrier

### Example: Parallel K-point Distribution

```fortran
subroutine allocate_distributed_array()
  use parallel_m,     ONLY: PAR_G_k_range, PAR_COM_HOST
  use y_memory_alloc
  implicit none
  
  complex(SP), allocatable :: G(:,:,:)
  integer :: LOCAL_SIZE(3), HOST_SIZE(3)
  integer :: nb, nk_local
  
  nb = 100
  nk_local = PAR_G_k_range(2) - PAR_G_k_range(1) + 1  ! Local k-points
  
  LOCAL_SIZE = [nb, nb, nk_local]
  
  ! This will:
  ! 1. Allocate G(nb, nb, nk_local) on each rank
  ! 2. Report total memory = sum over all ranks
  YAMBO_PAR_ALLOC3(G, LOCAL_SIZE)
  
  ! Each rank works on its local k-points
  ! ...
  
  YAMBO_FREE(G)
end subroutine
```

**Output (from master rank):**
```
[MEMORY] Global allocation: G (1.23 Gb across 32 ranks)
[MEMORY] Alloc G(39.4 Mb) TOTAL: 234.5 Mb (traced)
```

---

## Best Practices

### 1. Always Use YAMBO_ALLOC/YAMBO_FREE

**❌ Don't:**
```fortran
allocate(array(100, 100))
deallocate(array)
```

**✅ Do:**
```fortran
YAMBO_ALLOC(array, (100, 100))
YAMBO_FREE(array)
```

**Why:** Memory tracking, error handling, GPU support, MPI awareness

---

### 2. Check Allocation Status

The macros automatically check, but you can add extra logic:

```fortran
YAMBO_ALLOC(large_array, (n, n, n))

if (.not. allocated(large_array)) then
  call warning("Could not allocate large_array, using smaller version")
  YAMBO_ALLOC(small_array, (n/2, n/2, n/2))
endif
```

---

### 3. Free Memory as Soon as Possible

```fortran
subroutine compute_something()
  ! Allocate temporary arrays
  YAMBO_ALLOC(temp1, (n, n))
  YAMBO_ALLOC(temp2, (n, n))
  
  ! Use them
  call do_computation(temp1, temp2)
  
  ! Free immediately after use
  YAMBO_FREE(temp1)
  YAMBO_FREE(temp2)
  
  ! Continue with other work...
end subroutine
```

---

### 4. Use Descriptive Variable Names

The memory tracker uses variable names in reports:

**❌ Bad:**
```fortran
YAMBO_ALLOC(a, (n, n))
YAMBO_ALLOC(b, (n, n))
```
Output: `[MEMORY] Alloc a(7.63 Mb)`

**✅ Good:**
```fortran
YAMBO_ALLOC(G_lesser, (n, n))
YAMBO_ALLOC(G_greater, (n, n))
```
Output: `[MEMORY] Alloc G_lesser(7.63 Mb)`

---

### 5. Set Memory Limits

Users can set memory limits to prevent overallocation:

```bash
yambo -F input.in -J job_name -M 16Gb
```

In the code:
```fortran
USER_MEM_limit = 16000000  ! 16 Gb in Kb
```

If allocation exceeds limit:
```
[ERROR] Allocation of G_lesser leads total memory above USER limit [16Gb]
```

---

### 6. Monitor Memory Usage

Enable verbose memory reporting:

```fortran
MEM_treshold = 1000  ! Report allocations > 1 Mb
```

Check memory reports:
```fortran
call MEM_report()  ! Prints detailed memory usage
```

---

### 7. GPU Memory Management

**Always unmap before freeing:**
```fortran
YAMBO_ALLOC_GPU(array, (n, n))
! ... GPU computation ...
YAMBO_FREE_GPU(array)  ! Automatically unmaps
```

**Don't mix GPU and regular free:**
```fortran
YAMBO_ALLOC_GPU(array, (n, n))
YAMBO_FREE(array)  ! ❌ ERROR: Still mapped on device!
```

---

## Troubleshooting

### Error: "Allocation failed with code X"

**Cause:** Fortran `allocate` returned error code X

**Solutions:**
1. Check available memory: `free -h` (Linux) or `vm_stat` (macOS)
2. Reduce array sizes
3. Increase system memory or swap
4. Use MPI to distribute memory across nodes

**Common error codes:**
- `stat=1`: Out of memory
- `stat=2`: Invalid dimensions (negative size)

---

### Error: "Object was already allocated"

**Cause:** Trying to allocate an already-allocated array

**Solution:**
```fortran
if (allocated(array)) YAMBO_FREE(array)
YAMBO_ALLOC(array, (n, n))
```

Or use conditional allocation:
```fortran
if (.not. allocated(array)) then
  YAMBO_ALLOC(array, (n, n))
endif
```

---

### Error: "Trying to deallocate var X still on device memory"

**Cause:** GPU array not unmapped before deallocation

**Solution:**
```fortran
YAMBO_FREE_GPU(array)  ! Use GPU-specific free
```

Or manually unmap:
```fortran
call devxlib_unmap(array, MEM_err)
YAMBO_FREE(array)
```

---

### Warning: "De-allocation attempt of X which was not allocated"

**Cause:** Calling `YAMBO_FREE` on unallocated array

**Solution:** Add check:
```fortran
if (allocated(array)) YAMBO_FREE(array)
```

---

### Memory Leak Detection

If memory keeps growing:

1. **Check for missing YAMBO_FREE:**
   ```fortran
   YAMBO_ALLOC(temp, (n, n))
   ! ... use temp ...
   ! YAMBO_FREE(temp)  ← Missing!
   ```

2. **Check for allocations in loops:**
   ```fortran
   do i = 1, 1000
     YAMBO_ALLOC(temp, (n, n))  ! ❌ Allocates 1000 times!
     ! ...
     YAMBO_FREE(temp)
   enddo
   ```

3. **Use memory reports:**
   ```fortran
   call MEM_report()  ! Shows all current allocations
   ```

---

### Compilation Issues

**Error: "YAMBO_ALLOC not defined"**

**Solution:** Include the header:
```fortran
#include<y_memory.h>
```

And use the module:
```fortran
use y_memory_alloc
```

---

**Error: "MEM_count not found"**

**Solution:** Enable memory checking:
```bash
./configure --enable-memory-profile
```

Or compile with:
```bash
-D_MEM_CHECK
```

---

## Advanced Topics

### Memory Shelves and Libraries

Define custom memory shelves in `MEM_library.F`:

```fortran
call MEM_library_add("G_lesser", "Green's Functions")
call MEM_library_add("H_field", "Hamiltonians")
```

Arrays with these names will be grouped in reports.

---

### Custom Memory Thresholds

Adjust reporting thresholds:

```fortran
MEM_treshold = 10000       ! Report allocations > 10 Mb
MEM_SAVE_treshold = 100000 ! Save large allocations > 100 Mb
MEM_jump_treshold = 500000 ! Report memory jumps > 500 Mb
```

---

### Memory Statistics

Access memory statistics:

```fortran
use y_memory, ONLY: TOT_MEM_Kb, MAX_MEM_Kb, N_MEM_elements

print *, "Current memory:", TOT_MEM_Kb(HOST_), "Kb"
print *, "Peak memory:", MAX_MEM_Kb(HOST_), "Kb"
print *, "Number of allocations:", N_MEM_elements
```

---

## Summary

| **Task** | **Macro** | **Example** |
|----------|-----------|-------------|
| Allocate array | `YAMBO_ALLOC` | `YAMBO_ALLOC(A, (n, m))` |
| Free array | `YAMBO_FREE` | `YAMBO_FREE(A)` |
| Allocate pointer | `YAMBO_ALLOC_P` | `YAMBO_ALLOC_P(ptr, (n))` |
| Allocate from source | `YAMBO_ALLOC_SOURCE` | `YAMBO_ALLOC_SOURCE(A, B)` |
| Allocate on GPU | `YAMBO_ALLOC_GPU` | `YAMBO_ALLOC_GPU(A, (n, m))` |
| Free GPU array | `YAMBO_FREE_GPU` | `YAMBO_FREE_GPU(A)` |
| Parallel allocation | `YAMBO_PAR_ALLOC3` | `YAMBO_PAR_ALLOC3(A, SIZE)` |

**Key Points:**
- ✅ Always use `YAMBO_ALLOC`/`YAMBO_FREE` instead of raw `allocate`/`deallocate`
- ✅ Memory is automatically tracked and reported
- ✅ Errors are caught and reported with context
- ✅ GPU and MPI support built-in
- ✅ User-configurable memory limits prevent overallocation

---

## References

- **Source files:**
  - `include/headers/common/y_memory.h`
  - `include/headers/common/parallel_memory.h`
  - `src/modules/mod_memory.F`
  - `src/memory/MEM_*.F`

- **Example usage:**
  - `src/real_time_control/RT_alloc.F`
  - `src/pol_function/X_irredux.F`
  - `src/el-ph/ELPH_Hamiltonian.F`

---