# YAMBO Memory System Architecture {#alloc_architecture}

@page alloc_architecture Memory Allocation Architecture

@tableofcontents

## System Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                     YAMBO Memory System                         │
│                                                                 │
│  User Code                                                      │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  YAMBO_ALLOC(array, (n, m))                              │   │
│  │  YAMBO_FREE(array)                                       │   │
│  └──────────────────┬───────────────────────────────────────┘   │
│                     │                                           │
│                     ▼                                           │
│  Preprocessor Macros (y_memory.h)                               │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  #define YAMBO_ALLOC(x,SIZE)                             │   │
│  │    allocate(x SIZE, stat=MEM_err, errmsg=MEM_msg)        │   │
│  │    if (allocated(x)) call MEM_count("x", x)              │   │
│  │    if (.not.allocated(x)) call MEM_error("x")            │   │
│  └──────────────────┬───────────────────────────────────────┘   │
│                     │                                           │
│                     ▼                                           │
│  Memory Module (mod_memory.F)                                   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  interface MEM_count                                     │   │
│  │    MEM_i1, MEM_i2, ..., MEM_c1, MEM_c2, ...              │   │
│  │  end interface                                           │   │
│  │                                                          │   │
│  │  type(MEM_element) :: MEMs(N_MEM_max)                    │   │
│  │  integer(IP)       :: TOT_MEM_Kb(2)  ! HOST, DEV         │   │
│  └──────────────────┬───────────────────────────────────────┘   │
│                     │                                           │
│                     ▼                                           │
│  Memory Manager (MEM_manager_alloc.F)                           │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  1. Calculate memory size                                │   │
│  │  2. Update global counters (TOT_MEM_Kb)                  │   │
│  │  3. Register in database (MEMs array)                    │   │
│  │  4. Generate messages                                    │   │
│  │  5. Check memory limits                                  │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Allocation Flow Diagram

```
User calls YAMBO_ALLOC(G_lesser, (100, 100, 10, 2))
                    │
                    ▼
┌───────────────────────────────────────────────────────────┐
│ MACRO EXPANSION                                           │
│                                                           │
│ allocate(G_lesser(100, 100, 10, 2),                       │
│          stat=MEM_err, errmsg=MEM_msg)                    │
│                                                           │
│ if (allocated(G_lesser))                                  │
│   call MEM_count("G_lesser", G_lesser)  ────────-┐        │
│                                                  │        │
│ if (.not.allocated(G_lesser))                    │        │
│   call MEM_error("G_lesser")  ──────────┐        │        │
└─────────────────────────────────────────┼───── ──┼────────┘
                                          │        │
                    ┌─────────────────────┘        │
                    │                              │
                    ▼                              │
         ┌──────────────────────┐                  │
         │ MEM_error()          │                  │
         │                      │                  │
         │ if (MEM_err /= 0)    │                  │
         │   print error        │                  │
         │   call error()       │                  │
         │   STOP               │                  │
         └──────────────────────┘                  │
                                                   │
                    ┌──────────────────────────────┘
                    │
                    ▼
         ┌──────────────────────────────────────────────┐
         │ MEM_count("G_lesser", G_lesser)              │
         │                                              │
         │ Determines array type and rank:              │
         │   - integer, real, complex                   │
         │   - 1D, 2D, 3D, 4D, 5D, 6D                   │
         │                                              │
         │ Calls: MEM_manager_alloc(name, size, kind,   │
         │                          where)              │
         └───────────────────┬──────────────────────────┘
                             │
                             ▼
         ┌──────────────────────────────────────────────┐
         │ MEM_manager_alloc()                          │
         │                                              │
         │ 1. Initialize                                │
         │    ├─ Parse name (shelf/component)           │
         │    ├─ Search existing allocations            │
         │    └─ Check for errors                       │
         │                                              │
         │ 2. Calculate memory                          │
         │    MEM_now_Kb = (size × kind) / 1024         │
         │    Example: (100×100×10×2 × 8) / 1024        │
         │           = 1,562.5 Kb ≈ 1.53 Mb             │
         │                                              │
         │ 3. Update global counters                    │
         │    TOT_MEM_Kb(HOST_) += MEM_now_Kb           │
         │    MAX_MEM_Kb(HOST_) = max(...)              │
         │                                              │
         │ 4. Register in database                      │
         │    ├─ Find or create shelf                   │
         │    ├─ Add component                          │
         │    └─ Store metadata                         │
         │                                              │
         │ 5. Generate message                          │
         │    "[MEMORY] Alloc G_lesser(1.53 Mb)         │
         │     TOTAL: 234.5 Mb (traced)"                │
         │                                              │
         │ 6. Check limits                              │
         │    if (TOT_MEM_Kb > USER_MEM_limit)          │
         │      call error()                            │
         └──────────────────────────────────────────────┘
```

---

## Deallocation Flow Diagram

```
User calls YAMBO_FREE(G_lesser)
                    │
                    ▼
┌───────────────────────────────────────────────────────────┐
│ MACRO EXPANSION                                           │
│                                                           │
│ if (.not.allocated(G_lesser))                             │
│   call MEM_free("G_lesser", -1)                           │
│                                                           │
│ if (allocated(G_lesser))                                  │
│   call MEM_free("G_lesser", size(G_lesser))  ────────--┐  │
│                                                        │  │
│ if (allocated(G_lesser))                               │  │
│   deallocate(G_lesser)                                 │  │
└────────────────────────────────────────────────────────┼──┘
                                                         │
                    ┌────────────────────────────────────┘
                    │
                    ▼
         ┌──────────────────────────────────────────────┐
         │ MEM_free("G_lesser", size)                   │
         │                                              │
         │ 1. Find allocation in database               │
         │    ├─ Search MEMs array                      │
         │    ├─ Find shelf: "[G_lesser]"               │
         │    └─ Find component: "G_lesser"             │
         │                                              │
         │ 2. Calculate memory                          │
         │    MEM_now_Kb = (size × kind) / 1024         │
         │                                              │
         │ 3. Update global counters                    │
         │    TOT_MEM_Kb(HOST_) -= MEM_now_Kb           │
         │                                              │
         │ 4. Update database                           │
         │    ├─ Decrease shelf usage                   │
         │    ├─ Decrease component size                │
         │    └─ Remove if size = 0                     │
         │                                              │
         │ 5. Generate message                          │
         │    "[MEMORY] Free G_lesser(1.53 Mb)          │
         │     TOTAL: 233.0 Mb (traced)"                │
         └──────────────────────────────────────────────┘
                             │
                             ▼
                    ┌────────────────┐
                    │ deallocate()   │
                    │ (Fortran)      │
                    └────────────────┘
```

---

## Memory Database Structure

```
┌─────────────────────────────────────────────────────────────┐
│ MEMs Array (Global Memory Database)                         │
│                                                             │
│ MEMs(1):                                                    │
│   shelf = "[G_lesser]"                                      │
│   use   = 4,687 Kb                                          │
│   N     = 3                                                 │
│   ┌──────────────────────────────────────────────────────┐  │
│   │ Component 1:                                         │  │
│   │   name = "G_lesser_reference"                        │  │
│   │   desc = "RT_initialize"                             │  │
│   │   kind = 8 (complex SP)                              │  │
│   │   size = 200,000 elements                            │  │
│   │   where = HOST_                                      │  │
│   ├──────────────────────────────────────────────────────┤  │
│   │ Component 2:                                         │  │
│   │   name = "G_lesser"                                  │  │
│   │   desc = "RT_alloc"                                  │  │
│   │   kind = 8                                           │  │
│   │   size = 300,000 elements                            │  │
│   │   where = HOST_                                      │  │
│   ├──────────────────────────────────────────────────────┤  │
│   │ Component 3:                                         │  │
│   │   name = "dG_lesser"                                 │  │
│   │   desc = "RT_alloc"                                  │  │
│   │   kind = 8                                           │  │
│   │   size = 300,000 elements                            │  │
│   │   where = HOST_                                      │  │
│   └──────────────────────────────────────────────────────┘  │
│                                                             │
│ MEMs(2):                                                    │
│   shelf = "[Hamiltonian]"                                   │
│   use   = 3,125 Kb                                          │
│   N     = 3                                                 │
│   ┌──────────────────────────────────────────────────────┐  │
│   │ Component 1: "Ho_plus_Sigma"                         │  │
│   │ Component 2: "H_EQ"                                  │  │
│   │ Component 3: "H_field"                               │  │
│   └──────────────────────────────────────────────────────┘  │
│                                                             │
│ MEMs(3):                                                    │
│   shelf = "[Dipoles]"                                       │
│   use   = 1,562 Kb                                          │
│   ...                                                       │
│                                                             │
│ Total: N_MEM_elements = 3                                   │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ Global Counters                                             │
│                                                             │
│ TOT_MEM_Kb(HOST_) = 9,374 Kb  (current host memory)         │
│ TOT_MEM_Kb(DEV_)  = 2,345 Kb  (current device memory)       │
│                                                             │
│ MAX_MEM_Kb(HOST_) = 12,456 Kb (peak host memory)            │
│ MAX_MEM_Kb(DEV_)  = 3,456 Kb  (peak device memory)          │
│                                                             │
│ USER_MEM_limit    = 16,000,000 Kb (16 Gb limit)             │
└─────────────────────────────────────────────────────────────┘
```

---

## GPU Memory Architecture

```
┌─────────────────────────────────────────────────────────────-┐
│                    GPU Memory System                         │
│                                                              │
│  User Code                                                   │
│  ┌────────────────────────────────────────────────────────┐  │
│  │  YAMBO_ALLOC_GPU(array, (n, m))                        │  │
│  │  YAMBO_FREE_GPU(array)                                 │  │
│  └──────────────────┬─────────────────────────────────────┘  │
│                     │                                        │
│                     ▼                                        │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │ YAMBO_ALLOC_GPU Macro                                   │ │
│  │                                                         │ │
│  │ 1. if (.not.allocated(array))                           │ │
│  │      YAMBO_ALLOC(array, SIZE)  ← Host allocation        │ │
│  │                                                         │ │
│  │ 2. call devxlib_map(array)     ← Map to device          │ │
│  │                                                         │ │
│  │ 3. call MEM_count_d("array", array) ← Track device      │ │
│  └──────────────────┬──────────────────────────────────────┘ │
│                     │                                        │
│                     ▼                                        │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │ Memory State                                            │ │
│  │                                                         │ │
│  │ HOST:  array(n, m) allocated                            │ │
│  │        TOT_MEM_Kb(HOST_) += size                        │ │
│  │                                                         │ │
│  │ DEVICE: array(n, m) mapped                              │ │
│  │         TOT_MEM_Kb(DEV_) += size                        │ │
│  │                                                         │ │
│  │ devxlib_mapped(array) = .TRUE.                          │ │
│  └─────────────────────────────────────────────────────────┘ │
│                                                              │
│  GPU Computation                                             │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │ !$acc parallel loop present(array)                      │ │
│  │ do i = 1, n                                             │ │
│  │   array(i,:) = compute_on_gpu()                         │ │
│  │ enddo                                                   │ │
│  │ !$acc end parallel loop                                 │ │
│  └─────────────────────────────────────────────────────────┘ │
│                                                              │
│  Deallocation                                                │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │ YAMBO_FREE_GPU(array)                                   │ │
│  │                                                         │ │
│  │ 1. call MEM_free("array", size) ← Untrack device        │ │
│  │    TOT_MEM_Kb(DEV_) -= size                             │ │
│  │                                                         │ │
│  │ 2. call devxlib_unmap(array)    ← Unmap from device     │ │
│  │                                                         │ │
│  │ 3. call MEM_free("array", size) ← Untrack host          │ │
│  │    TOT_MEM_Kb(HOST_) -= size                            │ │
│  │                                                         │ │
│  │ 4. deallocate(array)             ← Free host memory     │ │
│  └─────────────────────────────────────────────────────────┘ │
└────────────────────────────────────────────────────────────-─┘
```

---

## MPI Parallel Memory Architecture

```
┌─────────────────────────────────────────────────────────────-┐
│              MPI Parallel Memory Allocation                  │
│                                                              │
│  Rank 0          Rank 1          Rank 2          Rank 3      │
│  ┌────────┐     ┌────────┐     ┌────────┐     ┌────────┐     │
│  │ nk=3   │     │ nk=3   │     │ nk=2   │     │ nk=2   │     │
│  │ k=1-3  │     │ k=4-6  │     │ k=7-8  │     │ k=9-10 │     │
│  └────┬───┘     └────┬───┘     └────┬───┘     └────┬───┘     │
│       │              │              │              │         │
│       └──────────────┴──────────────┴──────────────┘         │
│                             │                                │
│                             ▼                                │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │ YAMBO_PAR_ALLOC3(G_lesser, LOCAL_SIZE)                  │ │
│  │                                                         │ │
│  │ LOCAL_SIZE = [nb, nb, nk_local]                         │ │
│  └──────────────────┬──────────────────────────────────────┘ │
│                     │                                        │
│                     ▼                                        │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │ Step 1: Compute LOCAL_SIZE on each rank                 │ │
│  │                                                         │ │
│  │ Rank 0: LOCAL_SIZE = [100, 100, 3]                      │ │
│  │ Rank 1: LOCAL_SIZE = [100, 100, 3]                      │ │
│  │ Rank 2: LOCAL_SIZE = [100, 100, 2]                      │ │
│  │ Rank 3: LOCAL_SIZE = [100, 100, 2]                      │ │
│  └──────────────────┬──────────────────────────────────────┘ │
│                     │                                        │
│                     ▼                                        │
│  ┌────────────────────────────────────────────────────────┐  │
│  │ Step 2: MPI Reduction (sum across ranks)               │  │
│  │                                                        │  │
│  │ call PP_redux_wait(HOST_SIZE, COMM=PAR_COM_HOST%COMM)  │  │
│  │                                                        │  │
│  │ HOST_SIZE = [100, 100, 10]  (total k-points)           │  │
│  └──────────────────┬─────────────────────────────────────┘  │
│                     │                                        │
│                     ▼                                        │
│  ┌────────────────────────────────────────────────────────┐  │
│  │ Step 3: Master rank reports global memory              │  │
│  │                                                        │  │
│  │ if (PAR_COM_HOST%CPU_id == 0) then                     │  │
│  │   allocate(temp(HOST_SIZE))                            │  │
│  │   call MEM_global_mesg("G_lesser", kind, HOST_SIZE)    │  │
│  │   deallocate(temp)                                     │  │
│  │ endif                                                  │  │
│  │                                                        │  │
│  │ Output: "[MEMORY] Global: G_lesser (7.63 Mb total)"    │  │
│  └──────────────────┬─────────────────────────────────────┘  │
│                     │                                        │
│                     ▼                                        │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │ Step 4: Each rank allocates local memory                │ │
│  │                                                         │ │
│  │ YAMBO_ALLOC3(G_lesser, LOCAL_SIZE)                      │ │
│  │                                                         │ │
│  │ Rank 0: G_lesser(100, 100, 3) = 2.29 Mb                 │ │
│  │ Rank 1: G_lesser(100, 100, 3) = 2.29 Mb                 │ │
│  │ Rank 2: G_lesser(100, 100, 2) = 1.53 Mb                 │ │
│  │ Rank 3: G_lesser(100, 100, 2) = 1.53 Mb                 │ │
│  │                                                         │ │
│  │ Total: 7.63 Mb (distributed)                            │ │
│  └─────────────────────────────────────────────────────────┘ │
│                                                              │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │ Step 5: Barrier synchronization                         │ │
│  │                                                         │ │
│  │ call PP_wait(COMM=PAR_COM_HOST%COMM)                    │ │
│  └─────────────────────────────────────────────────────────┘ │
└────────────────────────────────────────────────────────=─────┘
```

---

## Memory Reporting System

```
┌─────────────────────────────────────────────────────────────-┐
│                   Memory Reporting Flow                      │
│                                                              │
│  Allocation Event                                            │
│  ┌────────────────────────────────────────────────────────┐  │
│  │ YAMBO_ALLOC(G_lesser, (100, 100, 10, 2))               │  │
│  └──────────────────┬─────────────────────────────────────   │
│                     │                                        │
│                     ▼                                        │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │ MEM_manager_alloc()                                     │ │
│  │   ├─ Calculate: MEM_now_Kb = 1,562 Kb                   │ │
│  │   ├─ Update: TOT_MEM_Kb += 1,562                        │ │
│  │   └─ Call: MEM_manager_messages()                       │ │
│  └──────────────────┬──────────────────────────────────────┘ │
│                     │                                        │
│                     ▼                                        │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │ MEM_manager_messages()                                  │ │
│  │                                                         │ │
│  │ Check thresholds:                                       │ │
│  │                                                         │ │
│  │ 1. Individual allocation threshold                      │ │
│  │    if (MEM_now_Kb > MEM_treshold) then                  │ │
│  │      print allocation message                           │ │
│  │    endif                                                │ │
│  │                                                         │ │
│  │    MEM_treshold = 1,000 Kb (1 Mb)                       │ │
│  │                                                         │ │
│  │    ✓ 1,562 Kb > 1,000 Kb → Print message                │ │
│  │                                                         │ │
│  │ 2. Memory jump threshold                                │ │
│  │    if ((TOT_MEM_Kb - TOT_MEM_Kb_SAVE) > jump) then      │ │
│  │      print total memory message                         │ │
│  │      TOT_MEM_Kb_SAVE = TOT_MEM_Kb                       │ │
│  │    endif                                                │ │
│  │                                                         │ │
│  │    MEM_jump_treshold = 100,000 Kb (100 Mb)              │ │
│  └──────────────────┬──────────────────────────────────────┘ │
│                     │                                        │
│                     ▼                                        │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │ Output Messages                                         │ │
│  │                                                         │ │
│  │ [MEMORY] Alloc G_lesser(1.53 Mb) TOTAL: 234.5 Mb        │ │
│  │          (traced) 241.2 Mb (memstat)                    │ │
│  │                                                         │ │
│  │ Components:                                             │ │
│  │   - Array name: "G_lesser"                              │ │
│  │   - Size: 1.53 Mb                                       │ │
│  │   - Total traced: 234.5 Mb (YAMBO tracking)             │ │
│  │   - Total memstat: 241.2 Mb (system query)              │ │
│  └─────────────────────────────────────────────────────────┘ │
└────────────────────────────────────────────────────────────-─┘

┌─────────────────────────────────────────────────────────-────┐
│                  Memory Report Structure                     │
│                                                              │
│  call MEM_report()                                           │
│                                                              │
│  Output:                                                     │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │ <---> Memory Usage Report                               │ │
│  │ <---> =====================                             │ │
│  │ <--->                                                   │ │
│  │ <---> Total Memory (HOST): 234.5 Mb                     │ │
│  │ <---> Peak Memory  (HOST): 456.7 Mb                     │ │
│  │ <---> Total Memory (DEV):  123.4 Mb                     │ │
│  │ <---> Peak Memory  (DEV):  234.5 Mb                     │ │
│  │ <--->                                                   │ │
│  │ <---> Allocations by Shelf:                             │ │
│  │ <--->                                                   │ │
│  │ <---> [G_lesser]                    4.58 Mb             │ │
│  │ <--->   ├─ G_lesser_reference       1.53 Mb             │ │
│  │ <--->   ├─ G_lesser                 1.53 Mb             │ │
│  │ <--->   └─ dG_lesser                1.53 Mb             │ │
│  │ <--->                                                   │ │
│  │ <---> [Hamiltonian]                 3.05 Mb             │ │
│  │ <--->   ├─ Ho_plus_Sigma            1.02 Mb             │ │
│  │ <--->   ├─ H_EQ                     1.02 Mb             │ │
│  │ <--->   └─ H_field                  1.02 Mb             │ │
│  │ <--->                                                   │ │
│  │ <---> [Dipoles]                     1.56 Mb             │ │
│  │ <--->   └─ DIP_v                    1.56 Mb             │ │
│  │ <--->                                                   │ │
│  │ <---> ... (more shelves) ...                            │ │
│  └─────────────────────────────────────────────────────────┘ │
└────────────────────────────────────────────────────-─────────┘
```

---

## Type-Specific Memory Counting

```
┌─────────────────────────────────────────────────────────────-┐
│           MEM_count Interface Resolution                     │
│                                                              │
│  User calls: call MEM_count("array", array)                  │
│                                                              │
│  Fortran resolves based on array type and rank:              │
│                                                              │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │ Integer Arrays                                          │ │
│  │   MEM_i1(name, i(:))                                    │ │
│  │   MEM_i2(name, i(:,:))                                  │ │
│  │   MEM_i3(name, i(:,:,:))                                │ │
│  │   ...                                                   │ │
│  │   MEM_i7(name, i(:,:,:,:,:,:,:))                        │ │
│  └─────────────────────────────────────────────────────────┘ │
│                                                              │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │ Real Arrays (SP)                                        │ │
│  │   MEM_r1(name, r(:))                                    │ │
│  │   MEM_r2(name, r(:,:))                                  │ │
│  │   ...                                                   │ │
│  │   MEM_r5(name, r(:,:,:,:,:))                            │ │
│  └─────────────────────────────────────────────────────────┘ │
│                                                              │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │ Complex Arrays (SP)                                     │ │
│  │   MEM_c1(name, c(:))                                    │ │
│  │   MEM_c2(name, c(:,:))                                  │ │
│  │   ...                                                   │ │
│  │   MEM_c6(name, c(:,:,:,:,:,:))                          │ │
│  │                                                         │ │
│  │   Note: kind = 2 × kind(c) for complex                  │ │
│  └─────────────────────────────────────────────────────────┘ │
│                                                              │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │ Example: complex(SP) :: G_lesser(100, 100, 10, 2)       │ │
│  │                                                         │ │
│  │ Resolves to: MEM_c4(name, c)                            │ │
│  │                                                         │ │
│  │ Calls: MEM_manager_alloc(                               │ │
│  │          name  = "G_lesser",                            │ │
│  │          Sz    = 100×100×10×2 = 200,000,                │ │
│  │          Kn    = 2×kind(c) = 2×4 = 8,                   │ │
│  │          where = HOST_                                  │ │
│  │        )                                                │ │
│  │                                                         │ │
│  │ Memory = 200,000 × 8 / 1024 = 1,562.5 Kb ≈ 1.53 Mb      │ │
│  └─────────────────────────────────────────────────────────┘ │
└────────────────────────────────────────────────────────────-─┘
```

---

## Compilation Flags Impact

```
┌───────────────────────────────────────────────────────────-──┐
│              Compilation Configuration                       │
│                                                              │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │ _MEM_CHECK Defined                                      │ │
│  │                                                         │ │
│  │ YAMBO_ALLOC → Full tracking enabled                     │ │
│  │   ├─ Memory database updated                            │ │
│  │   ├─ Messages printed                                   │ │
│  │   ├─ Limits checked                                     │ │
│  │   └─ Reports available                                  │ │
│  └─────────────────────────────────────────────────────────┘ │
│                                                              │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │ _MEM_CHECK NOT Defined                                  │ │
│  │                                                         │ │
│  │ YAMBO_ALLOC → Minimal tracking                          │ │
│  │   ├─ Only error checking                                │ │
│  │   ├─ No database updates                                │ │
│  │   ├─ No messages                                        │ │
│  │   └─ No reports                                         │ │
│  └─────────────────────────────────────────────────────────┘ │
│                                                              │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │ _OPENACC or _OPENMP_GPU Defined                         │ │
│  │                                                         │ │
│  │ YAMBO_ALLOC_GPU → GPU support enabled                   │ │
│  │   ├─ devxlib_map() available                            │ │
│  │   ├─ devxlib_unmap() available                          │ │
│  │   ├─ Separate device tracking                           │ │
│  │   └─ Device memory checks                               │ │
│  │                                                         │ │
│  │ YAMBO_FREE → Checks device mapping                      │ │
│  │   └─ Error if still mapped                              │ │
│  └─────────────────────────────────────────────────────────┘ │
│                                                              │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │ _MPI Defined                                            │ │
│  │                                                         │ │
│  │ YAMBO_PAR_ALLOC → MPI support enabled                   │ │
│  │   ├─ PP_redux_wait() available                          │ │
│  │   ├─ Global memory reporting                            │ │
│  │   └─ Barrier synchronization                            │ │
│  └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────-────────┘
```

---

## Summary Diagram

```
                    YAMBO Memory System
                           │
        ┌──────────────────┼──────────────────┐
        │                  │                  │
    User API         Tracking System    Reporting System
        │                  │                  │
  ┌─────┴─────┐      ┌─────┴─────┐      ┌────┴────┐
  │ ALLOC     │      │ Database  │      │ Messages│
  │ FREE      │──────│ Counters  │──────│ Reports │
  │ ALLOC_GPU │      │ Shelves   │      │ Limits  │
  │ PAR_ALLOC │      │ Components│      │         │
  └───────────┘      └───────────┘      └─────────┘
        │                  │                  │
        └──────────────────┴──────────────────┘
                           │
                    Fortran allocate()
```

---

**Architecture Documentation Version:** 1.0  
**Last Updated:** 2024