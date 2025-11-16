---
title: YAMBO ALLOC README
---

# YAMBO Memory Allocation System - Complete Documentation {#alloc_main}

## Overview

This documentation package provides comprehensive information about YAMBO's memory allocation system (`YAMBO_ALLOC`), a sophisticated memory management framework that wraps Fortran's native allocation with automatic tracking, error handling, GPU support, and MPI awareness.

---

## Documentation Files

This suite contains the following documentation pages:

- @subpage alloc_doc "Complete Technical Reference"
- @subpage alloc_quick_ref "Quick Reference Guide"
- @subpage alloc_architecture "System Architecture"
- @subpage alloc_examples "Practical Examples"

### 1. **YAMBO_ALLOC_DOCUMENTATION.md** (Main Reference)
**Purpose:** Complete technical reference  
**Contents:**
- System overview and architecture
- Core macros (`YAMBO_ALLOC`, `YAMBO_FREE`, etc.)
- Memory tracking system internals
- GPU/device memory management
- MPI-aware parallel allocation
- Best practices and troubleshooting
- Advanced topics

**When to use:** 
- Understanding how the system works
- Looking up macro syntax
- Debugging memory issues
- Learning about GPU/MPI features

---

### 2. **YAMBO_ALLOC_QUICK_REFERENCE.md** (Cheat Sheet)
**Purpose:** Fast lookup for common tasks  
**Contents:**
- Quick start guide
- Common patterns (basic, GPU, MPI)
- Macro reference table
- Memory size calculations
- Error messages and fixes
- Common mistakes checklist

**When to use:**
- Quick syntax lookup
- Copy-paste code snippets
- Checking memory calculations
- Troubleshooting errors

---

### 3. **YAMBO_ALLOC_ARCHITECTURE.md** (Visual Guide)
**Purpose:** Visual understanding of system architecture  
**Contents:**
- System overview diagram
- Allocation/deallocation flow charts
- Memory database structure
- GPU memory architecture
- MPI parallel memory flow
- Type-specific memory counting
- Compilation flags impact

**When to use:**
- Understanding system flow
- Visualizing memory tracking
- Learning GPU/MPI internals
- Teaching others

---

### 4. **YAMBO_ALLOC_EXAMPLES.md** (Practical Guide)
**Purpose:** Real-world code examples  
**Contents:**
- Basic allocation examples
- Real-time simulation patterns
- GPU computing examples
- MPI parallel examples
- Advanced patterns (pooling, resizing)
- Common mistakes and fixes
- Performance optimization

**When to use:**
- Writing new code
- Implementing specific features
- Optimizing memory usage
- Learning from examples

---

## Quick Start

### Minimal Example

```fortran
! 1. Include header
#include<y_memory.h>

! 2. Use module
use y_memory_alloc

! 3. Allocate
complex(SP), allocatable :: array(:,:)
YAMBO_ALLOC(array, (100, 200))

! 4. Use
array = (0.0_SP, 0.0_SP)

! 5. Free
YAMBO_FREE(array)
```

---

## Key Features

### ✅ Automatic Memory Tracking
Every allocation is logged with:
- Array name and size
- Memory location (host/device)
- Section/subroutine context
- Total memory usage

**Output:**
```
[MEMORY] Alloc array(156.25 Kb) TOTAL: 234.5 Mb (traced)
```

---

### ✅ Error Handling
Allocation failures are caught and reported:
```
[ERROR] Allocation of array failed with code 1
Out of memory
```

---

### ✅ GPU Support
Unified interface for host and device memory:
```fortran
YAMBO_ALLOC_GPU(array, (n, m))  ! Allocate and map to GPU
! ... GPU computation ...
YAMBO_FREE_GPU(array)            ! Unmap and free
```

---

### ✅ MPI Awareness
Parallel allocation with global statistics:
```fortran
YAMBO_PAR_ALLOC3(array, LOCAL_SIZE)
! Each rank allocates locally
! Master reports total across all ranks
```

**Output:**
```
[MEMORY] Global allocation: array (7.63 Mb across 4 ranks)
[MEMORY] Alloc array(1.91 Mb) TOTAL: 1.91 Mb (traced)
```

---

### ✅ Memory Limits
User-configurable limits prevent overallocation:
```bash
yambo -M 16Gb  # Set 16 GB limit
```

If exceeded:
```
[ERROR] Allocation leads total memory above USER limit [16Gb]
```

---

## Common Use Cases

### Real-Time Simulations

```fortran
! Green's functions (time-dependent)
YAMBO_ALLOC(G_lesser, (nb, nb, nk_local, nsp, G_MEM_steps))

! Hamiltonians
YAMBO_ALLOC(Ho_plus_Sigma, (nb, nb, nk_local, nsp))
YAMBO_ALLOC(H_field, (nb, nb, nk_local, nsp))

! Scattering matrices (very large!)
if (l_elph) then
  YAMBO_ALLOC(GKKP, (nb, nb, nk, nq, n_ph_modes))
endif
```

---

### GPU Computing

```fortran
#if defined _OPENACC
  YAMBO_ALLOC_GPU(A, (n, n))
  YAMBO_ALLOC_GPU(B, (n, n))
  
  !$acc parallel loop present(A, B)
  do i = 1, n
    B(i,:) = A(i,:) * 2.0_SP
  enddo
  !$acc end parallel loop
  
  YAMBO_FREE_GPU(A)
  YAMBO_FREE_GPU(B)
#endif
```

---

### MPI Parallelization

```fortran
! K-point distribution
nk_local = PAR_G_k_range(2) - PAR_G_k_range(1) + 1
LOCAL_SIZE = [nb, nb, nk_local]

YAMBO_PAR_ALLOC3(G_k, LOCAL_SIZE)
! Each rank: G_k(nb, nb, nk_local)
! Total: sum across all ranks
```

---

## Memory Calculation

### Formula
```
Memory (bytes) = num_elements × bytes_per_element
```

### Bytes per Element

| Type | Bytes | Example |
|------|-------|---------|
| `integer` | 4 | `integer :: i` |
| `real(SP)` | 4 | `real(SP) :: x` |
| `real(DP)` | 8 | `real(DP) :: y` |
| `complex(SP)` | 8 | `complex(SP) :: z` |
| `complex(DP)` | 16 | `complex(DP) :: w` |

### Example
```fortran
complex(SP) :: G_lesser(100, 100, 10, 2)
! Memory = 100 × 100 × 10 × 2 × 8 bytes
!        = 1,600,000 bytes
!        = 1,562.5 Kb
!        ≈ 1.53 Mb
```

---

## Best Practices

### ✅ DO

1. **Always use YAMBO_ALLOC/YAMBO_FREE**
   ```fortran
   YAMBO_ALLOC(array, (n, m))
   YAMBO_FREE(array)
   ```

2. **Allocate outside loops**
   ```fortran
   YAMBO_ALLOC(temp, (n, n))
   do i = 1, 1000
     call compute(temp)
   enddo
   YAMBO_FREE(temp)
   ```

3. **Free as soon as possible**
   ```fortran
   YAMBO_ALLOC(temp, (n, n))
   call compute(temp)
   YAMBO_FREE(temp)  ! Free immediately
   ```

4. **Check before freeing**
   ```fortran
   if (allocated(array)) YAMBO_FREE(array)
   ```

5. **Use appropriate precision**
   ```fortran
   complex(SP) :: array  ! 8 bytes
   ! Instead of:
   complex(DP) :: array  ! 16 bytes (2× memory!)
   ```

---

### ❌ DON'T

1. **Don't use raw allocate/deallocate**
   ```fortran
   allocate(array(n, m))    ! ❌ No tracking
   deallocate(array)        ! ❌ No tracking
   ```

2. **Don't allocate in loops**
   ```fortran
   do i = 1, 1000
     YAMBO_ALLOC(temp, (n, n))  ! ❌ Slow!
     YAMBO_FREE(temp)
   enddo
   ```

3. **Don't forget to free**
   ```fortran
   YAMBO_ALLOC(array, (n, m))
   ! ... use array ...
   ! Missing: YAMBO_FREE(array)  ❌ Memory leak!
   ```

4. **Don't mix GPU and regular free**
   ```fortran
   YAMBO_ALLOC_GPU(array, (n, m))
   YAMBO_FREE(array)  ! ❌ Still mapped on device!
   ```

---

## Troubleshooting

### Problem: Allocation Failed

**Error:**
```
[ERROR] Allocation of array failed with code 1
Out of memory
```

**Solutions:**
1. Check available memory: `free -h` (Linux) or `vm_stat` (macOS)
2. Reduce array sizes
3. Free unused arrays
4. Use MPI to distribute memory
5. Increase system memory

---

### Problem: Already Allocated

**Error:**
```
[WARNING] Object was already allocated in [array]
```

**Solution:**
```fortran
if (allocated(array)) YAMBO_FREE(array)
YAMBO_ALLOC(array, (n, m))
```

---

### Problem: GPU Memory Error

**Error:**
```
[ERROR] Trying to deallocate var array still on device memory
```

**Solution:**
```fortran
YAMBO_FREE_GPU(array)  ! Use GPU-specific free
```

---

### Problem: Memory Leak

**Symptom:** Memory keeps growing

**Debug:**
```fortran
call MEM_report()  ! Shows all current allocations
```

**Common causes:**
- Missing `YAMBO_FREE`
- Allocating in loops
- Not freeing in error paths

---

## Compilation

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

### MPI Support
```bash
./configure --enable-mpi
```

---

## Source Code Reference

### Header Files
- `include/headers/common/y_memory.h` - Core macros
- `include/headers/common/parallel_memory.h` - MPI macros

### Modules
- `src/modules/mod_memory.F` - Memory tracking module

### Implementation
- `src/memory/MEM_manager_alloc.F` - Allocation tracking
- `src/memory/MEM_free.F` - Deallocation tracking
- `src/memory/MEM_error.F` - Error handling
- `src/memory/MEM_manager_init.F` - Initialization
- `src/memory/MEM_manager_messages.F` - Reporting

### Examples
- `src/real_time_control/RT_alloc.F` - Real-time allocations
- `src/pol_function/X_irredux.F` - Polarization function
- `src/el-ph/ELPH_Hamiltonian.F` - Electron-phonon

---

## Documentation Roadmap

```
Start Here
    │
    ├─ Need quick syntax?
    │  └─→ YAMBO_ALLOC_QUICK_REFERENCE.md
    │
    ├─ Want to understand how it works?
    │  └─→ YAMBO_ALLOC_DOCUMENTATION.md
    │
    ├─ Need visual diagrams?
    │  └─→ YAMBO_ALLOC_ARCHITECTURE.md
    │
    └─ Looking for code examples?
       └─→ YAMBO_ALLOC_EXAMPLES.md
```

---

## Summary Table

| Feature | Macro | Example |
|---------|-------|---------|
| Basic allocation | `YAMBO_ALLOC` | `YAMBO_ALLOC(A, (n, m))` |
| Deallocation | `YAMBO_FREE` | `YAMBO_FREE(A)` |
| GPU allocation | `YAMBO_ALLOC_GPU` | `YAMBO_ALLOC_GPU(A, (n, m))` |
| GPU deallocation | `YAMBO_FREE_GPU` | `YAMBO_FREE_GPU(A)` |
| MPI allocation | `YAMBO_PAR_ALLOC3` | `YAMBO_PAR_ALLOC3(A, SIZE)` |
| Pointer allocation | `YAMBO_ALLOC_P` | `YAMBO_ALLOC_P(ptr, (n))` |
| Source allocation | `YAMBO_ALLOC_SOURCE` | `YAMBO_ALLOC_SOURCE(A, B)` |

---

## Getting Help

1. **Check documentation:**
   - Quick reference for syntax
   - Main documentation for details
   - Examples for patterns

2. **Check memory reports:**
   ```fortran
   call MEM_report()
   ```

3. **Enable verbose output:**
   ```fortran
   MEM_treshold = 1  ! Report all allocations > 1 Kb
   ```

4. **Check source code:**
   - Look at similar code in YAMBO
   - Check `RT_alloc.F` for real-time examples
   - Check `X_irredux.F` for response function examples

---

## Contributing

When adding new allocations to YAMBO:

1. ✅ Use `YAMBO_ALLOC`/`YAMBO_FREE`
2. ✅ Include `#include<y_memory.h>`
3. ✅ Use `use y_memory_alloc`
4. ✅ Use descriptive variable names
5. ✅ Free memory in reverse allocation order
6. ✅ Add comments for large allocations
7. ✅ Test with memory profiling enabled

---

## Version Information

- **Documentation Version:** 1.0
- **Last Updated:** 2024
- **Based on:** YAMBO source code analysis
- **Compatibility:** YAMBO 5.x and later

---

## License

This documentation follows the same license as YAMBO (GPL).

---

## Authors

Documentation created through comprehensive analysis of YAMBO source code, including:
- Memory management system (`mod_memory.F`, `MEM_*.F`)
- Macro definitions (`y_memory.h`, `parallel_memory.h`)
- Real-world usage examples throughout YAMBO codebase

---

**For questions or issues, refer to the YAMBO documentation or source code.**