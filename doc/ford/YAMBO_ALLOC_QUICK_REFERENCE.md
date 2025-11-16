---
title: YAMBO ALLOC QUICK REFERENCE
---

# YAMBO_ALLOC Quick Reference Guide {#alloc_quick_ref}

## Quick Start

```fortran
! 1. Include header
#include<y_memory.h>

! 2. Use module
use y_memory_alloc

! 3. Allocate
YAMBO_ALLOC(array_name, (dim1, dim2, ...))

! 4. Use array
array_name = some_value

! 5. Free
YAMBO_FREE(array_name)
```

---

## Common Patterns

### Basic Allocation
```fortran
complex(SP), allocatable :: A(:,:)
YAMBO_ALLOC(A, (100, 200))
YAMBO_FREE(A)
```

### Custom Index Ranges
```fortran
real(SP), allocatable :: E(:,:)
integer :: nb(2) = [1, 100]
YAMBO_ALLOC(E, (nb(1):nb(2), nk))  ! E(1:100, 1:nk)
YAMBO_FREE(E)
```

### Conditional Allocation
```fortran
if (.not. allocated(array)) then
  YAMBO_ALLOC(array, (n, m))
endif
```

### Safe Deallocation
```fortran
if (allocated(array)) YAMBO_FREE(array)
```

---

## Macro Reference

| Macro | Purpose | Example |
|-------|---------|---------|
| `YAMBO_ALLOC(x, SIZE)` | Allocate array | `YAMBO_ALLOC(A, (n, m))` |
| `YAMBO_FREE(x)` | Deallocate array | `YAMBO_FREE(A)` |
| `YAMBO_ALLOC_P(x, SIZE)` | Allocate pointer | `YAMBO_ALLOC_P(ptr, (n))` |
| `YAMBO_FREE_P(x)` | Deallocate pointer | `YAMBO_FREE_P(ptr)` |
| `YAMBO_ALLOC_SOURCE(x, y)` | Allocate from source | `YAMBO_ALLOC_SOURCE(A, B)` |
| `YAMBO_ALLOC_MOLD(x, y)` | Allocate with mold | `YAMBO_ALLOC_MOLD(A, B)` |
| `YAMBO_ALLOC_GPU(x, SIZE)` | GPU allocation | `YAMBO_ALLOC_GPU(A, (n, m))` |
| `YAMBO_FREE_GPU(x)` | GPU deallocation | `YAMBO_FREE_GPU(A)` |
| `YAMBO_PAR_ALLOC[1-6](x, SIZE)` | MPI-aware allocation | `YAMBO_PAR_ALLOC3(A, SIZE)` |

---

## GPU Memory

```fortran
#if defined _OPENACC
  ! Allocate on host and map to device
  YAMBO_ALLOC_GPU(A, (n, m))
  
  ! Use on GPU
  !$acc parallel loop present(A)
  do i = 1, n
    A(i,:) = compute_something()
  enddo
  !$acc end parallel loop
  
  ! Free (automatically unmaps)
  YAMBO_FREE_GPU(A)
#endif
```

---

## MPI Parallel Allocation

```fortran
use parallel_m, ONLY: PAR_G_k_range

integer :: nk_local, LOCAL_SIZE(3)

! Local k-points for this rank
nk_local = PAR_G_k_range(2) - PAR_G_k_range(1) + 1

LOCAL_SIZE = [nb, nb, nk_local]

! Allocate locally, report globally
YAMBO_PAR_ALLOC3(G_lesser, LOCAL_SIZE)

! Each rank has G_lesser(nb, nb, nk_local)
! Master reports total memory across all ranks

YAMBO_FREE(G_lesser)
```

---

## Real-Time Simulation Example

```fortran
subroutine RT_allocate_Greens_functions()
  use real_time,      ONLY: G_lesser, dG_lesser, G_lesser_reference, &
                            RT_bands, RT_nk, G_MEM_steps
  use electrons,      ONLY: n_sp_pol
  use parallel_m,     ONLY: PAR_G_k_range
  use y_memory_alloc
  implicit none
  
  integer :: nk(2)
  
  nk = PAR_G_k_range  ! Local k-point range
  
  ! Reference (equilibrium) - replicated on all ranks
  YAMBO_ALLOC(G_lesser_reference, (RT_bands(1):RT_bands(2), &
                                   RT_bands(1):RT_bands(2), &
                                   RT_nk, n_sp_pol))
  
  ! Time-dependent - distributed over k-points
  YAMBO_ALLOC(G_lesser, (RT_bands(1):RT_bands(2), &
                         RT_bands(1):RT_bands(2), &
                         nk(1):nk(2), n_sp_pol, G_MEM_steps))
  
  ! Time derivative - distributed over k-points
  YAMBO_ALLOC(dG_lesser, (RT_bands(1):RT_bands(2), &
                          RT_bands(1):RT_bands(2), &
                          nk(1):nk(2), n_sp_pol, G_MEM_steps))
  
  ! Initialize
  G_lesser_reference = cZERO
  G_lesser = cZERO
  dG_lesser = cZERO
  
end subroutine

subroutine RT_free_Greens_functions()
  use real_time,      ONLY: G_lesser, dG_lesser, G_lesser_reference
  use y_memory_alloc
  implicit none
  
  YAMBO_FREE(G_lesser_reference)
  YAMBO_FREE(G_lesser)
  YAMBO_FREE(dG_lesser)
  
end subroutine
```

---

## Memory Tracking Output

### Allocation Message
```
[MEMORY] Alloc G_lesser(234.5 Mb) TOTAL: 1.23 Gb (traced)
```

### Deallocation Message
```
[MEMORY]  Free G_lesser(234.5 Mb) TOTAL: 1.00 Gb (traced)
```

### Memory Jump Message
```
[MEMORY] In use: TOTAL: 2.45 Gb (traced) 2.51 Gb (memstat)
```

### GPU Memory
```
[MEMORY] Alloc A(7.63 Mb) (DEV) TOTAL: 234.5 Mb (traced)
```

---

## Error Messages

### Allocation Failure
```
[ERROR] Allocation of G_lesser failed with code 1
Out of memory
```

**Fix:** Reduce array size or increase system memory

---

### Already Allocated
```
[WARNING] Allocation of G_lesser failed with code 0
[WARNING] Object was already allocated in [G_lesser]
```

**Fix:** Free before reallocating
```fortran
if (allocated(G_lesser)) YAMBO_FREE(G_lesser)
YAMBO_ALLOC(G_lesser, (n, m))
```

---

### GPU Memory Error
```
[ERROR] Trying to deallocate var A still on device memory
```

**Fix:** Use GPU-specific free
```fortran
YAMBO_FREE_GPU(A)  ! Not YAMBO_FREE(A)
```

---

### Memory Limit Exceeded
```
[ERROR] Allocation of G_lesser leads total memory above USER limit [16Gb]
```

**Fix:** Increase limit or reduce array sizes
```bash
yambo -M 32Gb  # Increase to 32 Gb
```

---

## Memory Size Calculation

### Formula
```
Memory (bytes) = num_elements × bytes_per_element
```

### Bytes per Element

| Type | Bytes | Example |
|------|-------|---------|
| `integer` | 4 | `integer :: i` |
| `integer(LP)` | 8 | `integer(LP) :: big_i` |
| `real(SP)` | 4 | `real(SP) :: x` |
| `real(DP)` | 8 | `real(DP) :: y` |
| `complex(SP)` | 8 | `complex(SP) :: z` |
| `complex(DP)` | 16 | `complex(DP) :: w` |
| `logical` | 4 | `logical :: flag` |

### Examples

**1D array:**
```fortran
real(SP) :: A(1000)
! Memory = 1000 × 4 = 4,000 bytes = 3.91 Kb
```

**2D array:**
```fortran
complex(SP) :: G(100, 100)
! Memory = 100 × 100 × 8 = 80,000 bytes = 78.1 Kb
```

**4D array:**
```fortran
complex(SP) :: G_lesser(100, 100, 10, 2)
! Memory = 100 × 100 × 10 × 2 × 8 = 1,600,000 bytes = 1.53 Mb
```

**5D array (time-dependent):**
```fortran
complex(SP) :: G_lesser(100, 100, 10, 2, 3)
! Memory = 100 × 100 × 10 × 2 × 3 × 8 = 4,800,000 bytes = 4.58 Mb
```

---

## Compilation Flags

### Enable Memory Tracking
```bash
./configure --enable-memory-profile
```

Or manually:
```bash
-D_MEM_CHECK
```

### GPU Support
```bash
./configure --enable-open-acc
# or
./configure --enable-openmp-gpu
```

Defines: `-D_OPENACC` or `-D_OPENMP_GPU`

### MPI Support
```bash
./configure --enable-mpi
```

Defines: `-D_MPI`

---

## Debugging Tips

### 1. Check if Array is Allocated
```fortran
if (allocated(array)) then
  print *, "Array is allocated, size:", size(array)
else
  print *, "Array is NOT allocated"
endif
```

### 2. Print Memory Usage
```fortran
use y_memory, ONLY: TOT_MEM_Kb, MAX_MEM_Kb

print *, "Current memory (Kb):", TOT_MEM_Kb(HOST_)
print *, "Peak memory (Kb):", MAX_MEM_Kb(HOST_)
```

### 3. Generate Memory Report
```fortran
call MEM_report()  ! Prints detailed allocation table
```

### 4. Check for Memory Leaks
```fortran
! At start of routine
call MEM_report()
integer :: mem_start = TOT_MEM_Kb(HOST_)

! ... allocations and deallocations ...

! At end of routine
call MEM_report()
integer :: mem_end = TOT_MEM_Kb(HOST_)

if (mem_end /= mem_start) then
  print *, "WARNING: Memory leak detected!"
  print *, "Leaked:", mem_end - mem_start, "Kb"
endif
```

---

## Best Practices Checklist

- ✅ Always use `YAMBO_ALLOC` instead of `allocate`
- ✅ Always use `YAMBO_FREE` instead of `deallocate`
- ✅ Include `#include<y_memory.h>` at top of file
- ✅ Use `use y_memory_alloc` in subroutines
- ✅ Free memory as soon as it's no longer needed
- ✅ Check `allocated()` before freeing
- ✅ Use descriptive variable names (helps in reports)
- ✅ Use `YAMBO_FREE_GPU` for GPU arrays
- ✅ Use `YAMBO_PAR_ALLOC` for MPI-distributed arrays
- ✅ Set memory limits for production runs (`-M` flag)

---

## Common Mistakes

### ❌ Mistake 1: Using raw allocate
```fortran
allocate(A(n, m))  ! ❌ No tracking
```
**Fix:**
```fortran
YAMBO_ALLOC(A, (n, m))  ! ✅ Tracked
```

---

### ❌ Mistake 2: Forgetting to free
```fortran
subroutine compute()
  YAMBO_ALLOC(temp, (n, n))
  ! ... use temp ...
  ! Missing: YAMBO_FREE(temp)
end subroutine
```
**Fix:**
```fortran
subroutine compute()
  YAMBO_ALLOC(temp, (n, n))
  ! ... use temp ...
  YAMBO_FREE(temp)  ! ✅ Always free
end subroutine
```

---

### ❌ Mistake 3: Allocating in loop
```fortran
do i = 1, 1000
  YAMBO_ALLOC(temp, (n, n))  ! ❌ Allocates 1000 times!
  ! ...
  YAMBO_FREE(temp)
enddo
```
**Fix:**
```fortran
YAMBO_ALLOC(temp, (n, n))  ! ✅ Allocate once
do i = 1, 1000
  ! ... use temp ...
enddo
YAMBO_FREE(temp)
```

---

### ❌ Mistake 4: Wrong GPU free
```fortran
YAMBO_ALLOC_GPU(A, (n, m))
! ...
YAMBO_FREE(A)  ! ❌ Still mapped on device!
```
**Fix:**
```fortran
YAMBO_ALLOC_GPU(A, (n, m))
! ...
YAMBO_FREE_GPU(A)  ! ✅ Unmaps and frees
```

---

### ❌ Mistake 5: Not checking allocation
```fortran
YAMBO_ALLOC(huge_array, (10000, 10000, 10000))
! Might fail silently if _MEM_CHECK not defined
```
**Fix:**
```fortran
YAMBO_ALLOC(huge_array, (10000, 10000, 10000))
if (.not. allocated(huge_array)) then
  call error("Failed to allocate huge_array")
endif
```

---

## Performance Tips

### 1. Allocate Large Arrays Once
```fortran
! ✅ Good: Allocate once, reuse
YAMBO_ALLOC(work, (n, n))
do iter = 1, n_iterations
  call compute(work)
enddo
YAMBO_FREE(work)

! ❌ Bad: Allocate/free in loop
do iter = 1, n_iterations
  YAMBO_ALLOC(work, (n, n))
  call compute(work)
  YAMBO_FREE(work)
enddo
```

### 2. Free Temporary Arrays Immediately
```fortran
YAMBO_ALLOC(temp1, (n, n))
YAMBO_ALLOC(temp2, (n, n))

call step1(temp1, temp2)
YAMBO_FREE(temp1)  ! ✅ Free as soon as done

call step2(temp2)
YAMBO_FREE(temp2)  ! ✅ Free as soon as done
```

### 3. Use Appropriate Data Types
```fortran
! If single precision is enough:
complex(SP) :: A(n, n)  ! 8 bytes per element

! Instead of:
complex(DP) :: A(n, n)  ! 16 bytes per element (2× memory!)
```

---

## Resources

- **Full Documentation:** `YAMBO_ALLOC_DOCUMENTATION.md`
- **Source Code:**
  - Macros: `include/headers/common/y_memory.h`
  - Module: `src/modules/mod_memory.F`
  - Manager: `src/memory/MEM_*.F`
- **Examples:**
  - Real-time: `src/real_time_control/RT_alloc.F`
  - Polarization: `src/pol_function/X_irredux.F`

---

**Quick Reference Version:** 1.0  
**Last Updated:** 2024