# Yambo I/O System Flowchart {#io_flowchart}

@page io_flowchart I/O System Flowchart

@tableofcontents

## High-Level I/O Workflow

```
┌─────────────────────────────────────────────────────────────────┐
│                    USER CODE (e.g., RT_apply.F)                 │
│                                                                 │
│  Needs to read/write database (e.g., ndb.RT_carriers)           │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                    STEP 1: io_control()                         │
│                                                                 │
│  • Set ACTION (read/write/open/close)                           │
│  • Set MODE (DUMP/VERIFY)                                       │
│  • Set COM (where to report: REP/LOG/NONE)                      │
│  • Set SEC (which sections: /1/, /1,2/, /1,2,3/)                │
│  • Set parallel permissions:                                    │
│    - COMM: MPI communicator for parallel I/O                    │
│    - DO_IT: logical flag for selective CPU I/O                  │
│                                                                 │
│  Returns: ID (database unit identifier)                         │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                    STEP 2: io_connect()                         │
│                                                                 │
│  • Build filename from descriptor (e.g., "ndb.RT_carriers")     │
│  • Search for file in multiple locations:                       │
│    1. Current job directory                                     │
│    2. SAVE directory                                            │
│    3. Alternative paths                                         │
│  • Create directories if writing                                │
│  • Open file using NetCDF/HDF5:                                 │
│    - Serial: nf90_open() / nf90_create()                        │
│    - Parallel: nf90_open_par() / nf90_create_par()              │
│                                                                 │
│  Returns: error_code (0=success, -1=not found, -6=not allowed)  │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
                    ┌────────┴────────┐
                    │                 │
                    ▼                 ▼
    ┌───────────────────────┐   ┌──────────────────────┐
    │  STEP 3a: Fragment?   │   │  STEP 3b: No Fragment│
    │                       │   │                      │
    │  io_fragment()        │   │  Direct I/O          │
    │                       │   │                      │
    │  • Opens fragment     │   │  Skip to Step 4      │
    │    file with index    │   │                      │
    │  • Returns ID_frag    │   │                      │
    └───────────┬───────────┘   └──────────┬───────────┘
                │                          │
                └──────────┬───────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│                    STEP 4: Data I/O                             │
│                                                                 │
│  Choose based on data type and size:                            │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  io_elemental() - For scalars and small arrays          │    │
│  │                                                         │    │
│  │  • Integers, reals, complex, strings, logicals          │    │
│  │  • Automatic verification (CHECK, WARN)                 │    │
│  │  • Unit conversion for display                          │    │
│  │  • Error reporting (*ERR*, *WRN*)                       │    │
│  │                                                         │    │
│  │  Example:                                               │    │
│  │    call io_elemental(ID, VAR='nkpts', I0=nk)            │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  io_bulk() - For large multi-dimensional arrays          │   │
│  │                                                          │   │
│  │  • Up to 5D arrays (I0-I5, R0-R5, C0-C5, Z0-Z5)          │   │
│  │  • HDF5 compression support                              │   │
│  │  • Partial I/O with IPOS parameter                       │   │
│  │  • Complex → real conversion for NetCDF                  │   │
│  │                                                          │   │
│  │  Example:                                                │   │
│  │    call io_bulk(ID, VAR='wavefunction', VAR_SZ=(/ng,nb/))│   │
│  │    call io_bulk(ID, C2=wf_array)                         │   │
│  └──────────────────────────────────────────────────────────┘    │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                    STEP 5: io_disconnect()                      │
│                                                                 │
│  • Close NetCDF/HDF5 file                                       │
│  • Free database unit ID                                        │
│  • Reset internal state                                         │
└─────────────────────────────────────────────────────────────────┘
```

---

## Parallel I/O Decision Tree

```
                        START: Need to do I/O
                                 │
                                 ▼
                    ┌────────────────────────┐
                    │  How many CPUs need    │
                    │  to access the data?   │
                    └────────┬───────────────┘
                             │
              ┌──────────────┼──────────────┐
              │              │              │
              ▼              ▼              ▼
    ┌─────────────┐  ┌─────────────┐  ┌─────────────┐
    │  Only one   │  │  Subset of  │  │  All CPUs   │
    │ CPU (master)│  │  CPUs       │  │ collectively│
    └──────┬──────┘  └──────┬──────┘  └──────┬──────┘
           │                │                │
           ▼                ▼                ▼
    ┌─────────────┐  ┌─────────────┐  ┌─────────────┐
    │ STRATEGY 1  │  │ STRATEGY 2  │  │ STRATEGY 3  │
    │ Master-Only │  │ Selective   │  │ Parallel    │
    │             │  │ CPU I/O     │  │ HDF5        │
    └──────┬──────┘  └──────┬──────┘  └──────┬──────┘
           │                │                │
           ▼                ▼                ▼
    ┌─────────────┐  ┌─────────────┐  ┌─────────────┐
    │ io_control( │  │ io_control( │  │ io_control( │
    │   ACTION,   │  │   ACTION,   │  │   ACTION,   │
    │   ID=ID     │  │   DO_IT=    │  │   COMM=     │
    │ )           │  │   condition,│  │   my_comm,  │
    │             │  │   ID=ID     │  │   ID=ID     │
    │ Only master │  │ )           │  │ )           │
    │ CPU does I/O│  │             │  │             │
    │             │  │ Each CPU    │  │ Requires    │
    │ Others skip │  │ with DO_IT= │  │ _PAR_IO &   │
    │             │  │ .TRUE. does │  │ _HDF5_IO    │
    │ Broadcast   │  │ I/O         │  │             │
    │ after read  │  │             │  │ Collective  │
    │             │  │ Often uses  │  │ operations  │
    │ Simple      │  │ fragments   │  │             │
    │             │  │             │  │ Single file │
    └─────────────┘  └─────────────┘  └─────────────┘
```

---

## Fragment I/O Pattern

```
┌─────────────────────────────────────────────────────────────────┐
│                    MAIN DATABASE                                │
│                    (e.g., ndb.dipoles)                          │
│                                                                 │
│  Section 1: Header (version, serial number, parameters)         │
│  Section 2: Dimensions (nk, nb, ng, etc.)                       │
│  Section 3: → Points to fragments                               │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             │ io_fragment(ID, ID_frag, i_fragment=ik)
                             │
              ┌──────────────┼──────────────┐
              │              │              │
              ▼              ▼              ▼
    ┌─────────────┐  ┌─────────────┐  ┌─────────────┐
    │  Fragment 1 │  │  Fragment 2 │  │  Fragment N │
    │             │  │             │  │             │
    │ ndb.dipoles │  │ ndb.dipoles │  │ ndb.dipoles │
    │ _fragment_1 │  │ _fragment_2 │  │ _fragment_N │
    │             │  │             │  │             │
    │ Data for    │  │ Data for    │  │ Data for    │
    │ k-point 1   │  │ k-point 2   │  │ k-point N   │
    └─────────────┘  └─────────────┘  └─────────────┘
          │                │                │
          │                │                │
          ▼                ▼                ▼
    ┌─────────────┐  ┌─────────────┐  ┌─────────────┐
    │   CPU 0     │  │   CPU 1     │  │   CPU N-1   │
    │             │  │             │  │             │
    │ Reads/writes│  │ Reads/writes│  │ Reads/writes│
    │ fragment 1  │  │ fragment 2  │  │ fragment N  │
    │             │  │             │  │             │
    │ Parallel    │  │ Parallel    │  │ Parallel    │
    │ access!     │  │ access!     │  │ access!     │
    └─────────────┘  └─────────────┘  └─────────────┘
```

**Advantages:**
- ✅ Multiple CPUs can read/write simultaneously
- ✅ No file locking conflicts
- ✅ Scales well with number of k-points
- ✅ Memory efficient (load only needed fragments)

**Disadvantages:**
- ❌ Many small files (filesystem stress)
- ❌ More complex bookkeeping
- ❌ Requires fragment-aware code

---

## MPI + OpenMP Thread Model

```
┌─────────────────────────────────────────────────────────────────┐
│                    MPI PROCESS 0                                │
│                                                                 │
│  ┌────────────────────────────────────────────────────────┐     │
│  │  OpenMP Thread 0 (MASTER)                              │     │
│  │                                                        │     │
│  │  • Handles all I/O operations                          │     │
│  │  • Calls io_control(), io_connect(), io_bulk()         │     │
│  │  • Protected by !$omp master / !$omp critical          │     │
│  └────────────────────────────────────────────────────────┘     │
│                                                                 │
│  ┌────────────────────────────────────────────────────────┐     │
│  │  OpenMP Thread 1                                       │     │
│  │  • Computation only (bands, G-vectors)                 │     │
│  │  • Waits at barriers                                   │     │
│  └────────────────────────────────────────────────────────┘     │
│                                                                 │
│  ┌────────────────────────────────────────────────────────┐     │
│  │  OpenMP Thread 2                                       │     │
│  │  • Computation only                                    │     │
│  └────────────────────────────────────────────────────────┘     │
│                                                                 │
│  ┌────────────────────────────────────────────────────────┐     │
│  │  OpenMP Thread 3                                       │     │
│  │  • Computation only                                    │     │
│  └────────────────────────────────────────────────────────┘     │
└─────────────────────────────────────────────────────────────────┘
                             │
                             │ MPI Communication
                             │
┌─────────────────────────────────────────────────────────────────┐
│                    MPI PROCESS 1                                │
│                                                                 │
│  ┌────────────────────────────────────────────────────────┐     │
│  │  OpenMP Thread 0 (MASTER)                              │     │
│  │  • Handles I/O for this process                        │     │
│  └────────────────────────────────────────────────────────┘     │
│                                                                 │
│  ┌────────────────────────────────────────────────────────┐     │
│  │  OpenMP Threads 1-3                                    │     │
│  │  • Computation only                                    │     │
│  └────────────────────────────────────────────────────────┘     │
└─────────────────────────────────────────────────────────────────┘
```

**Key Points:**
- NetCDF/HDF5 libraries are **NOT thread-safe**
- Only **master thread** of each MPI process does I/O
- Use `!$omp master` or `!$omp critical` around I/O calls
- OpenMP parallelizes computation (inner loops)
- MPI parallelizes data distribution (k-points, q-points)

---

## Database Section Structure

```
┌─────────────────────────────────────────────────────────────────┐
│                    DATABASE FILE (e.g., ndb.dipoles)            │
├─────────────────────────────────────────────────────────────────┤
│  SECTION 1: HEADER                                              │
│  ┌───────────────────────────────────────────────────────┐      │
│  │  • Code version (major.minor.patch)                   │      │
│  │  • Code revision (devel, GPL)                         │      │
│  │  • Serial number (unique DB identifier)               │      │
│  │  • Creation date                                      │      │
│  │  • Database type and format version                   │      │
│  └───────────────────────────────────────────────────────┘      │
├─────────────────────────────────────────────────────────────────┤
│  SECTION 2: DIMENSIONS                                          │
│  ┌───────────────────────────────────────────────────────┐      │
│  │  • Number of k-points (nk)                            │      │
│  │  • Number of bands (nb)                               │      │
│  │  • Number of G-vectors (ng)                           │      │
│  │  • Number of frequencies (nw)                         │      │
│  │  • Grid specifications                                │      │
│  │  • Index ranges                                       │      │
│  └───────────────────────────────────────────────────────┘      │
├─────────────────────────────────────────────────────────────────┤
│  SECTION 3: DATA                                                │
│  ┌───────────────────────────────────────────────────────┐      │
│  │  • Physical quantities (arrays, matrices)             │      │
│  │  • May be split into fragments                        │      │
│  │  • Can be very large (GB-TB)                          │      │
│  └───────────────────────────────────────────────────────┘      │
└─────────────────────────────────────────────────────────────────┘

Access patterns:
• SEC=(/1/)      → Read only header (fast, for compatibility check)
• SEC=(/1,2/)    → Read header + dimensions (setup arrays)
• SEC=(/1,2,3/)  → Read everything (full data load)
```

---

## Complete Example: Reading RT Carriers Database

```fortran
! ============================================================
! Example: Read carrier occupations from RT database
! ============================================================

use IO_int,      ONLY: io_control, io_connect, io_disconnect
use IO_m,        ONLY: OP_RD_CL, VERIFY, REP, io_status, IO_NO_ERROR
use electrons,   ONLY: E  ! Electronic structure
use real_time,   ONLY: RT_carriers

integer :: ID, ierr

! ──────────────────────────────────────────────────────────
! STEP 1: Setup I/O control
! ──────────────────────────────────────────────────────────
call io_control(ACTION=OP_RD_CL,     &  ! Open, read, close
                COM=REP,              &  ! Report to report file
                SEC=(/1,2,3/),        &  ! Read all sections
                MODE=VERIFY,          &  ! Verify compatibility
                ID=ID)                   ! Returns database ID

! ──────────────────────────────────────────────────────────
! STEP 2: Connect to database file
! ──────────────────────────────────────────────────────────
ierr = io_connect(desc='ndb.RT_carriers',  &  ! Database name
                  subfolder='',             &  ! In current dir
                  ID=ID)                       ! Use this ID

if (ierr /= 0) then
  call warning('RT carriers database not found')
  return
endif

! ──────────────────────────────────────────────────────────
! STEP 3: Read data using database-specific routine
! ──────────────────────────────────────────────────────────
ierr = io_RT_components('carriers', ID)

! This routine internally calls:
!   - io_elemental() for scalars (nk, nb, time, etc.)
!   - io_bulk() for arrays (occupations, energies, etc.)

! ──────────────────────────────────────────────────────────
! STEP 4: Check status and disconnect
! ──────────────────────────────────────────────────────────
if (io_status(ID) /= IO_NO_ERROR) then
  call error('Incompatible RT carriers database')
endif

call io_disconnect(ID)

! ──────────────────────────────────────────────────────────
! STEP 5: Use the data
! ──────────────────────────────────────────────────────────
! Data is now loaded into E%f (occupations), E%E (energies), etc.
! Can proceed with calculations...
```

---

## Summary Diagram: I/O System Components

```
┌─────────────────────────────────────────────────────────────────┐
│                    YAMBO I/O SYSTEM                             │
└─────────────────────────────────────────────────────────────────┘
                             │
        ┌────────────────────┼────────────────────┐
        │                    │                    │
        ▼                    ▼                    ▼
┌───────────────┐    ┌───────────────┐    ┌───────────────┐
│  CONTROL      │    │  CONNECTION   │    │  DATA I/O     │
│  LAYER        │    │  LAYER        │    │  LAYER        │
├───────────────┤    ├───────────────┤    ├───────────────┤
│ io_control.F  │───▶│ io_connect.F  │───▶│io_elemental.F │
│               │    │               │    │io_bulk.F      │
│ • Permissions │    │ • File search │    │io_fragment.F  │
│ • Actions     │    │ • Open/create │    │               │
│ • MPI comms   │    │ • Directories │    │ • Read/write  │
│ • CPU flags   │    │ • NetCDF/HDF5 │    │ • Verify      │
└───────────────┘    └───────────────┘    └───────────────┘
        │                    │                    │
        └────────────────────┼────────────────────┘
                             │
                             ▼
                    ┌────────────────┐
                    │  DISCONNECT    │
                    ├────────────────┤
                    │io_disconnect.F │
                    │                │
                    │ • Close files  │
                    │ • Free IDs     │
                    │ • Reset state  │
                    └────────────────┘
```

---

**For more details, see**: `doc/doxygen/IO_System_Architecture.md`