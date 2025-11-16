# Yambo I/O System Architecture {#io_architecture}

@page io_architecture I/O System Architecture

@tableofcontents

## Overview

The Yambo I/O system (`src/Yio`) provides a sophisticated, parallel-aware database management layer built on top of NetCDF/HDF5. It handles reading and writing of all physical quantities (wavefunctions, response functions, Green's functions, etc.) with support for both serial and parallel I/O operations across MPI and OpenMP environments.

**Key Design Principles:**
- **Abstraction**: High-level interface hides NetCDF/HDF5 complexity
- **Parallel-aware**: Automatic handling of MPI communicators and CPU permissions
- **Type-safe**: Separate routines for elemental (scalars/small arrays) and bulk (large arrays) data
- **Fragmentation**: Large datasets split into fragments for parallel access
- **Verification**: Built-in database compatibility checking

---

## Core Components

### 1. I/O Control Layer (`io_control.F`)

**Purpose**: Manages I/O permissions and parallel communicators

**Key Function**: `io_control(ACTION, MODE, COM, SEC, ID, COMM, DO_IT)`

**Parameters:**
- `ACTION`: What to do (open/read/write/close)
- `MODE`: How to handle data (DUMP=write/read, VERIFY=check compatibility)
- `COM`: Where to report (REP=report file, LOG=log file, NONE=silent)
- `SEC`: Which database sections to access
- `ID`: Database unit identifier (assigned automatically)
- `COMM`: MPI communicator for parallel I/O (optional)
- `DO_IT`: Logical flag to enable/disable I/O for specific CPUs (optional)

**Actions (defined in `mod_IO.F`):**
```fortran
OP_RD_CL    = 2   ! Open for reading, then close
OP_WR_CL    = 3   ! Open for writing, then close
OP_APP_CL   = 4   ! Open for appending, then close
OP_RD       = 5   ! Open for reading (keep open)
OP_APP      = 6   ! Open for appending (keep open)
OP_WR       = 7   ! Open for writing (keep open)
RD          = 8   ! Read (already open)
WR          = 9   ! Write (already open)
RD_CL       = 1   ! Read and close
WR_CL       = 11  ! Write and close
```

**Parallel I/O Control:**

The system uses two key variables per database ID:
- `io_PAR_comm(ID)`: MPI communicator for collective I/O operations
- `io_PAR_cpu(ID)`: Permission flag (1=allowed, 0=not allowed)

**Three I/O Permission Modes:**

1. **Single CPU I/O** (default):
   ```fortran
   call io_control(ACTION=OP_WR_CL, ID=ID)
   ! Only master CPU writes, others skip
   ```

2. **Explicit CPU Selection**:
   ```fortran
   call io_control(ACTION=OP_WR_CL, ID=ID, DO_IT=my_condition)
   ! Only CPUs where my_condition=.TRUE. participate
   ! Uses MPI_COMM_WORLD for synchronization
   ```

3. **Communicator-based Parallel I/O**:
   ```fortran
   call io_control(ACTION=OP_WR_CL, ID=ID, COMM=PAR_IND_Xk%COMM)
   ! All CPUs in COMM participate in parallel I/O
   ! Requires _PAR_IO and _HDF5_IO compilation flags
   ```

---

### 2. Connection Layer (`io_connect.F`)

**Purpose**: Opens/creates database files and manages file paths

**Key Function**: `io_connect(desc, subfolder, type, ID) -> error_code`

**Parameters:**
- `desc`: Database descriptor (e.g., "ndb.RT_carriers", "ndb.dipoles")
- `subfolder`: Optional subdirectory (e.g., "SAVE")
- `type`: File type (1=NetCDF, 2=HDF5, -2=binary)
- `ID`: Database unit identifier

**Return Values:**
- `0`: Success
- `IO_NO_DATABASE=-1`: File not found
- `IO_NOT_ALLOWED=-6`: CPU not permitted to access

**File Location Search Order:**
1. Current job directory: `{more_io_path}/{jobdir}/{jobstr}/`
2. SAVE directory: `{more_io_path}/SAVE/`
3. Alternative job strings (if configured)
4. Core I/O path

**Parallel I/O Modes:**

When `io_PAR_comm(ID) ≠ mpi_comm_null` and `ncpu > 1`:
```fortran
#if defined _PAR_IO && defined _HDF5_IO
  ! Parallel HDF5 mode
  call nf90_create_par(filename, PAR_IO_CREATE_MODE, &
                       io_PAR_comm(ID), MPI_INFO_NULL, io_unit(ID))
#else
  ! Serial fallback (error if COMM was specified)
  call error('Parallel COMM present but yambo compiled with serial IO')
#endif
```

---

### 3. Data I/O Layer

#### 3a. Elemental I/O (`io_elemental.F`)

**Purpose**: Read/write scalars and small arrays with verification and reporting

**Key Function**: `io_elemental(ID, VAR, VAR_SZ, I0, R0, C0, CH0, L0, ...)`

**Supported Types:**
- `I0, I1(:)`: Integers (scalar, 1D array)
- `R0, R1(:)`: Real (SP) (scalar, 1D array)
- `D0`: Double precision (scalar)
- `C0`: Complex (SP) (scalar)
- `CH0, CH1(:)`: Character strings
- `L0`: Logical (stored as integer)

**Features:**
- **Automatic verification**: Compares read values with expected values
- **Unit conversion**: Applies `UNIT` factor for display
- **Error reporting**: Marks incompatible variables with `*ERR*` or `*WRN*`
- **Descriptors**: Builds metadata for database documentation

**Example Usage:**
```fortran
! Define variable in database
call io_elemental(ID, VAR='Temperature', VAR_SZ=1)

! Write value
call io_elemental(ID, VAR='Temperature', R0=300.0, UNIT=1.0)

! Read and verify
call io_elemental(ID, VAR='Temperature', R0=T_read, DB_R0=T_expected, &
                  CHECK=.TRUE., OP=(/'=='/))
```

#### 3b. Bulk I/O (`io_bulk.F`)

**Purpose**: Read/write large multi-dimensional arrays efficiently

**Key Function**: `io_bulk(ID, VAR, VAR_SZ, I1, R2, C3, ...)`

**Supported Types:**
- Integers: `I0` to `I5` (scalar to 5D array)
- Real (SP): `R0` to `R5`
- Real (DP): `D0` to `D5`
- Complex (SP): `C0` to `C5`
- Complex (DP): `Z0` to `Z5`
- Logical (LP): `L0` to `L4`

**Features:**
- **HDF5 compression**: Automatic deflate compression (level 2) when `_HDF5_COMPRESSION` enabled
- **Partial I/O**: `IPOS` parameter for reading/writing array slices
- **Complex handling**: Converts complex arrays to real arrays (2×N) for NetCDF storage

**Example Usage:**
```fortran
! Define 3D array variable
call io_bulk(ID, VAR='Density', VAR_SZ=(/nx, ny, nz/))

! Write entire array
call io_bulk(ID, R3=rho)

! Write slice starting at position (1, 1, iz)
call io_bulk(ID, R2=rho_slice, IPOS=(/1, 1, iz/))
```

---

### 4. Fragment I/O (`io_fragment.F`)

**Purpose**: Split large databases into fragments for parallel access

**Why Fragments?**
- **Parallel efficiency**: Different CPUs read/write different fragments simultaneously
- **Memory management**: Load only needed portions of large datasets
- **k-point parallelization**: Each CPU handles its k-point subset

**Key Function**: `io_fragment(ID, ID_frag, i_fragment, j_fragment, extension)`

**Fragmented Databases:**
- Wavefunctions (`wf`, `Vnl`, `kb_pp`)
- Dipoles (`dip_iR_and_P`, `Overlaps`)
- Response functions (`em1s`, `em1d`, `pp`, `Xx`)
- Hartree-Fock (`HF_and_locXC`, `xxvxc`)
- Real-time carriers (`carriers`, `THETA`, `OBSERVABLES`)
- Self-energy (`scE`, `scWFs`, `scV`)
- BSE kernel (`BS_Q*`)
- Electron-phonon (`elph_gkkp`)

**Fragment Naming Convention:**
```
{database}_fragment_{i}           ! Single index
{database}_fragments_{i}_{j}      ! Double index (e.g., k-point pairs)
```

**Control Flags** (set via input or `DBs_FRAG_control_string`):
```fortran
frag_WF        ! Fragment wavefunctions
frag_DIP       ! Fragment dipoles
frag_RESPONSE  ! Fragment response functions
frag_HF        ! Fragment Hartree-Fock
frag_RT        ! Fragment real-time data
frag_BS_K      ! Fragment BSE kernel
```

**Example Usage:**
```fortran
! Open main database
call io_control(ACTION=OP_RD_CL, ID=ID)
ierr = io_connect('ndb.dipoles', ID=ID)

! Open fragment for k-point ik
call io_fragment(ID, ID_frag, i_fragment=ik)

! Read data from fragment
call io_bulk(ID_frag, C2=dipole_matrix)

! Close fragment
call io_disconnect(ID_frag)
```

---

## Parallel I/O Strategies

### Strategy 1: Master-Only I/O (Default)

**When to use**: Small databases, infrequent I/O

**Behavior**:
- Only `master_cpu` (rank 0) performs I/O
- Other CPUs skip I/O operations
- Data broadcast via MPI after reading

**Code Pattern**:
```fortran
call io_control(ACTION=OP_RD_CL, ID=ID)
ierr = io_connect('ndb.kindx', ID=ID)
call io_elemental(ID, I0=nkpts)  ! Only master reads
call PP_bcast(nkpts)              ! Broadcast to all
```

**Advantages**: Simple, no parallel I/O library needed
**Disadvantages**: Slow for large data, memory bottleneck on master

---

### Strategy 2: Selective CPU I/O

**When to use**: Distributed data where each CPU owns a subset

**Behavior**:
- CPUs with `DO_IT=.TRUE.` perform I/O
- Uses `MPI_COMM_WORLD` for synchronization
- Each CPU writes its own data independently

**Code Pattern**:
```fortran
! Each CPU writes its k-point subset
do ik = 1, PAR_IND_Xk%n(myid+1)
  ik_global = PAR_IND_Xk%element_1D(ik)
  
  call io_control(ACTION=OP_APP_CL, ID=ID, DO_IT=.TRUE.)
  call io_fragment(ID, ID_frag, i_fragment=ik_global)
  call io_bulk(ID_frag, C2=my_data(:,:,ik))
  call io_disconnect(ID_frag)
enddo
```

**Advantages**: Parallel writes, no data movement
**Disadvantages**: Many small files (fragments), filesystem stress

---

### Strategy 3: Communicator-Based Parallel I/O

**When to use**: Large arrays, HDF5 available, collective operations

**Behavior**:
- All CPUs in `COMM` participate in collective I/O
- Uses parallel HDF5 (requires `_PAR_IO` and `_HDF5_IO`)
- Single file, parallel access via MPI-IO

**Code Pattern**:
```fortran
! All CPUs in PAR_IND_Xk%COMM write collectively
call io_control(ACTION=OP_WR_CL, ID=ID, COMM=PAR_IND_Xk%COMM)
ierr = io_connect('ndb.response', ID=ID)

! Define array dimensions
call io_bulk(ID, VAR='Chi', VAR_SZ=(/ng, ng, nw/))

! Each CPU writes its frequency slice
do iw = 1, PAR_IND_w%n(myid+1)
  iw_global = PAR_IND_w%element_1D(iw)
  call io_bulk(ID, C2=chi_local(:,:,iw), IPOS=(/1, 1, iw_global/))
enddo

call io_disconnect(ID)
```

**Advantages**: Single file, efficient for large data, true parallel I/O
**Disadvantages**: Requires parallel HDF5, more complex setup

---

## MPI + OpenMP Considerations

### Thread Safety

**NetCDF/HDF5 Thread Safety:**
- NetCDF-4 with HDF5 backend is **NOT thread-safe** by default
- Yambo uses **OpenMP critical sections** around I/O calls
- Only one thread per MPI process performs I/O

**Implementation Pattern**:
```fortran
!$omp critical (io_lock)
call io_elemental(ID, R0=value)
!$omp end critical (io_lock)
```

### Hybrid MPI+OpenMP I/O

**Typical Configuration:**
- MPI parallelization over k-points, q-points, frequencies
- OpenMP parallelization over bands, G-vectors (inner loops)
- I/O performed by **master thread** of each MPI process

**Example: Response Function Calculation**
```
MPI Process 0 (4 threads)          MPI Process 1 (4 threads)
├─ Thread 0 (master)               ├─ Thread 0 (master)
│  └─ Handles I/O for q1           │  └─ Handles I/O for q2
├─ Thread 1                        ├─ Thread 1
├─ Thread 2                        ├─ Thread 2
└─ Thread 3                        └─ Thread 3
   (compute only)                     (compute only)
```

**Code Pattern**:
```fortran
!$omp parallel default(shared)
!$omp do
do ib = 1, nbands
  ! Compute contribution (all threads)
  call compute_matrix_element(ib, contrib)
  
  !$omp critical
  chi_local = chi_local + contrib
  !$omp end critical
enddo
!$omp end do

!$omp master
! Only master thread does I/O
call io_bulk(ID, C2=chi_local)
!$omp end master
!$omp end parallel
```

---

## Database Structure

### Database Sections

Yambo databases are organized into **sections** (like chapters in a book):

**Section 1**: Header
- Code version, revision, serial number
- Database type and format version
- Creation date and parameters

**Section 2**: Dimensions
- Number of k-points, bands, G-vectors, frequencies
- Grid specifications
- Index ranges

**Section 3+**: Data
- Physical quantities (wavefunctions, energies, matrices)
- Often split into fragments

**Accessing Sections**:
```fortran
! Read only header
call io_control(ACTION=OP_RD_CL, SEC=(/1/), ID=ID)

! Read header and dimensions
call io_control(ACTION=OP_RD_CL, SEC=(/1,2/), ID=ID)

! Read everything
call io_control(ACTION=OP_RD_CL, SEC=(/1,2,3/), ID=ID)
```

---

## Common I/O Patterns

### Pattern 1: Read Database Header

```fortran
use IO_int,  ONLY: io_control, io_connect
use IO_m,    ONLY: OP_RD_CL, VERIFY, REP

integer :: ID, ierr

! Open database, read header only
call io_control(ACTION=OP_RD_CL, COM=REP, SEC=(/1/), MODE=VERIFY, ID=ID)
ierr = io_connect('ndb.dipoles', ID=ID)

if (ierr /= 0) then
  call warning('Dipole database not found')
  return
endif

! Header is automatically read by io_connect
! Version, serial number, etc. stored in io_code_version(ID,:), etc.
```

### Pattern 2: Write New Database

```fortran
use IO_int,  ONLY: io_control, io_connect, io_disconnect
use IO_m,    ONLY: OP_WR_CL, DUMP, NONE

integer :: ID, ierr

! Create new database
call io_control(ACTION=OP_WR_CL, COM=NONE, SEC=(/1,2,3/), MODE=DUMP, ID=ID)
ierr = io_connect('ndb.my_data', subfolder='SAVE', type=2, ID=ID)

! Write header (section 1)
call io_elemental(ID, VAR='PARS', VAR_SZ=0)  ! Start section
call io_elemental(ID, VAR='nkpts', I0=nk)
call io_elemental(ID, VAR='nbands', I0=nb)

! Write data (section 2)
call io_elemental(ID, VAR='DATA', VAR_SZ=0)
call io_bulk(ID, VAR='energies', VAR_SZ=(/nb, nk/))
call io_bulk(ID, R2=energies)

call io_disconnect(ID)
```

### Pattern 3: Parallel Fragment Write

```fortran
use parallel_m, ONLY: PAR_IND_Xk, myid

integer :: ID, ID_frag, ik, ik_global

! Open main database (master only)
if (myid == 0) then
  call io_control(ACTION=OP_WR_CL, ID=ID)
  ierr = io_connect('ndb.wf', ID=ID)
  ! Write header...
  call io_disconnect(ID)
endif

! Each CPU writes its k-point fragments
do ik = 1, PAR_IND_Xk%n(myid+1)
  ik_global = PAR_IND_Xk%element_1D(ik)
  
  call io_control(ACTION=OP_WR_CL, ID=ID, DO_IT=.TRUE.)
  ierr = io_connect('ndb.wf', ID=ID)
  call io_fragment(ID, ID_frag, i_fragment=ik_global)
  
  call io_bulk(ID_frag, VAR='wf', VAR_SZ=(/npw, nb/))
  call io_bulk(ID_frag, C2=wavefunction(:,:,ik))
  
  call io_disconnect(ID_frag)
  call io_disconnect(ID)
enddo
```

### Pattern 4: Read with Verification

```fortran
use IO_m, ONLY: VERIFY, io_status, IO_NO_ERROR

integer :: nk_expected, nk_read

nk_expected = 100

call io_control(ACTION=OP_RD_CL, MODE=VERIFY, ID=ID)
ierr = io_connect('ndb.kindx', ID=ID)

! Read and verify
call io_elemental(ID, VAR='nkpts', I0=nk_read, DB_I0=nk_expected, &
                  CHECK=.TRUE., OP=(/'=='/))

if (io_status(ID) /= IO_NO_ERROR) then
  call error('Incompatible k-point grid')
endif
```

---

## Performance Considerations

### When to Use Each Strategy

| Data Size | Access Pattern | MPI Ranks | Recommended Strategy |
|-----------|----------------|-----------|----------------------| 
| < 1 MB | Broadcast to all | Any | Master-only I/O             |
| 1-100 MB | Distributed | < 100 | Selective CPU + Fragments    |
| > 100 MB | Distributed | > 100 | Parallel HDF5 (if available) |
| > 1 GB | Collective | Any | Parallel HDF5 (required)          |

### Optimization Tips

1. **Minimize I/O Calls**: Batch small writes into larger arrays
2. **Use Fragments**: For k-point parallel calculations
3. **Enable Compression**: For large databases (HDF5 only)
4. **Avoid Synchronization**: Use `DO_IT` instead of barriers
5. **Lustre Filesystems**: Use striping for large files
   ```bash
   lfs setstripe -c 8 -S 4M output_directory/
   ```

### Memory vs. I/O Trade-offs

**Memory-Intensive Approach** (no fragments):
- Load entire database into memory
- Fast access, no I/O during computation
- Requires `memory_size > database_size × n_mpi_ranks`

**I/O-Intensive Approach** (fragments):
- Load fragments on-demand
- Slower access, frequent I/O
- Requires `memory_size > fragment_size`

**Yambo Default**: Hybrid approach with configurable fragmentation

---

## Debugging I/O Issues

### Enable Verbose I/O Logging

```bash
yambo -V io  # Verbose I/O messages
```

### Check Database Integrity

```fortran
use IO_int, ONLY: io_control, io_connect
use IO_m,   ONLY: OP_RD_CL, VERIFY, LOG

call io_control(ACTION=OP_RD_CL, COM=LOG, MODE=VERIFY, ID=ID)
ierr = io_connect('ndb.dipoles', ID=ID)

! Check return code
select case (ierr)
  case (IO_NO_DATABASE)
    print *, "Database not found"
  case (IO_INCOMPATIBLE_VAR)
    print *, "Incompatible database version"
  case (IO_OUTDATED_DB)
    print *, "Database format outdated"
  case (0)
    print *, "Database OK"
end select
```

### Common Error Messages

**"Parallel COMM present but yambo compiled with serial IO"**
- Solution: Recompile with `--enable-hdf5-par-io` configure flag

**"Recompile Yambo with a larger: max_io_units"**
- Solution: Increase `max_io_units` in `src/modules/mod_pars.F`

**"Trying to overwrite variable with wrong dimensions"**
- Solution: Delete old database or use different filename

**"std::length_error: basic_string"** (Doxygen-related, but similar in I/O)
- Solution: Check array bounds, ensure dimensions match

---

## Summary

The Yambo I/O system provides:

✅ **Unified interface** for all database operations  
✅ **Automatic parallel I/O** handling (MPI + OpenMP)  
✅ **Fragment-based** access for large datasets  
✅ **Type-safe** operations with verification  
✅ **Flexible** permission control (master/selective/collective)  
✅ **Portable** across HDF5/NetCDF backends  

**Key Takeaway for Users:**
> You rarely need to worry about MPI ranks or file formats. Just call `io_control` with the appropriate `COMM` or `DO_IT` parameter, and the system handles the rest.

**Key Takeaway for Developers:**
> Always use `io_control` to set permissions before `io_connect`. Never directly call NetCDF/HDF5 functions—use `io_elemental` or `io_bulk` wrappers.

---

## Related Files

- **Core I/O**: `src/Yio/io_control.F`, `io_connect.F`, `io_elemental.F`, `io_bulk.F`
- **Fragments**: `src/Yio/io_fragment.F`, `io_fragment_disconnect.F`
- **Module**: `src/modules/mod_IO.F`
- **Utilities**: `src/Yio/io_utilities.F`, `IO_make_directories.F`
- **Examples**: `src/io/*.F` (database-specific I/O routines)

---
