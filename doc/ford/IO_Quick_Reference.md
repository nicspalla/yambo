---
title: IO Quick Reference
---

# Yambo I/O Quick Reference Card {#io_quick_ref}

## Essential Includes

```fortran
use IO_int,  ONLY: io_control, io_connect, io_disconnect
use IO_m,    ONLY: OP_RD_CL, OP_WR_CL, OP_APP_CL, &
                   DUMP, VERIFY, REP, LOG, NONE, &
                   io_status, IO_NO_ERROR
```

---

## Common I/O Patterns

### 1. Read Database (Master CPU Only)

```fortran
integer :: ID, ierr

call io_control(ACTION=OP_RD_CL, COM=REP, SEC=(/1,2,3/), MODE=VERIFY, ID=ID)
ierr = io_connect('ndb.dipoles', ID=ID)

if (ierr == 0) then
  ierr = io_DIPOLES(ID)  ! Database-specific read routine
  call io_disconnect(ID)
endif
```

### 2. Write Database (Master CPU Only)

```fortran
integer :: ID, ierr

call io_control(ACTION=OP_WR_CL, COM=NONE, SEC=(/1,2,3/), MODE=DUMP, ID=ID)
ierr = io_connect('ndb.my_data', subfolder='SAVE', type=2, ID=ID)

! Write header
call io_elemental(ID, VAR='PARS', VAR_SZ=0)
call io_elemental(ID, VAR='nkpts', I0=nk)

! Write data
call io_bulk(ID, VAR='energies', VAR_SZ=(/nb, nk/))
call io_bulk(ID, R2=E_array)

call io_disconnect(ID)
```

### 3. Parallel Write (Selective CPUs)

```fortran
integer :: ID, ierr, ik, ik_global
logical :: do_io

do ik = 1, PAR_IND_Xk%n(myid+1)
  ik_global = PAR_IND_Xk%element_1D(ik)
  do_io = .TRUE.  ! This CPU participates
  
  call io_control(ACTION=OP_WR_CL, ID=ID, DO_IT=do_io)
  ierr = io_connect('ndb.wf', ID=ID)
  
  ! Write fragment for this k-point
  call io_fragment(ID, ID_frag, i_fragment=ik_global)
  call io_bulk(ID_frag, C2=wf(:,:,ik))
  call io_disconnect(ID_frag)
  call io_disconnect(ID)
enddo
```

### 4. Parallel Write (Communicator-Based)

```fortran
use parallel_m, ONLY: PAR_IND_Xk

integer :: ID, ierr

! All CPUs in PAR_IND_Xk%COMM participate
call io_control(ACTION=OP_WR_CL, ID=ID, COMM=PAR_IND_Xk%COMM)
ierr = io_connect('ndb.response', ID=ID)

call io_bulk(ID, VAR='Chi', VAR_SZ=(/ng, ng, nw/))

! Each CPU writes its frequency slice
do iw = 1, my_nw
  iw_global = my_w_index(iw)
  call io_bulk(ID, C2=chi_local(:,:,iw), IPOS=(/1, 1, iw_global/))
enddo

call io_disconnect(ID)
```

### 5. Read with Verification

```fortran
integer :: nk_expected, nk_read

nk_expected = 100

call io_control(ACTION=OP_RD_CL, MODE=VERIFY, ID=ID)
ierr = io_connect('ndb.kindx', ID=ID)

call io_elemental(ID, VAR='nkpts', I0=nk_read, DB_I0=nk_expected, &
                  CHECK=.TRUE., OP=(/'=='/))

if (io_status(ID) /= IO_NO_ERROR) then
  call error('Incompatible k-point grid')
endif

call io_disconnect(ID)
```

### 6. Fragment Read (Parallel)

```fortran
integer :: ID, ID_frag, ik, ik_global

call io_control(ACTION=OP_RD_CL, ID=ID)
ierr = io_connect('ndb.dipoles', ID=ID)

! Read header/dimensions
ierr = io_DIPOLES(ID, HEADER_ONLY=.TRUE.)

! Each CPU reads its k-point fragments
do ik = 1, PAR_IND_Xk%n(myid+1)
  ik_global = PAR_IND_Xk%element_1D(ik)
  
  call io_fragment(ID, ID_frag, i_fragment=ik_global)
  call io_bulk(ID_frag, C2=dipole_matrix(:,:,ik))
  call io_disconnect(ID_frag)
enddo

call io_disconnect(ID)
```

---

## ACTION Codes

| Code | Name | Description |
|------|------|-------------|
| `OP_RD_CL` | Open-Read-Close | Open for reading, then close |
| `OP_WR_CL` | Open-Write-Close | Open for writing, then close |
| `OP_APP_CL` | Open-Append-Close | Open for appending, then close |
| `OP_RD` | Open-Read | Open for reading (keep open) |
| `OP_WR` | Open-Write | Open for writing (keep open) |
| `OP_APP` | Open-Append | Open for appending (keep open) |
| `RD` | Read | Read (already open) |
| `WR` | Write | Write (already open) |
| `RD_CL` | Read-Close | Read and close |
| `WR_CL` | Write-Close | Write and close |

---

## MODE Codes

| Code | Description |
|------|-------------|
| `DUMP` | Write/read data without verification |
| `VERIFY` | Read and verify compatibility with expected values |

---

## COM Codes (Communication/Reporting)

| Code | Description |
|------|-------------|
| `REP` | Report to report file (r-*) |
| `LOG` | Report to log file (l-*) |
| `NONE` | Silent (no reporting) |

---

## Error Codes

| Code | Value | Description |
|------|-------|-------------|
| `IO_NO_ERROR` | 0 | Success |
| `IO_NO_DATABASE` | -1 | Database file not found |
| `IO_INCOMPATIBLE_VAR` | -2 | Incompatible variable |
| `IO_GENERIC_ERROR` | -3 | Generic error |
| `IO_NO_BINDING_ERROR` | -4 | No binding error |
| `IO_OUTDATED_DB` | -5 | Database format outdated |
| `IO_NOT_ALLOWED` | -6 | CPU not allowed to access |

---

## io_elemental() Quick Reference

### Scalars

```fortran
! Integer
call io_elemental(ID, VAR='nkpts', I0=nk)

! Real
call io_elemental(ID, VAR='temperature', R0=T, UNIT=1.0)

! Double precision
call io_elemental(ID, VAR='energy', D0=E_total)

! Complex
call io_elemental(ID, VAR='phase', C0=phase_factor)

! Logical
call io_elemental(ID, VAR='converged', L0=is_converged)

! String
call io_elemental(ID, VAR='xc_functional', CH0='PBE')
```

### 1D Arrays

```fortran
! Integer array
call io_elemental(ID, VAR='k_indices', I1=k_idx)

! Real array
call io_elemental(ID, VAR='weights', R1=wk)

! String array
call io_elemental(ID, VAR='labels', CH1=atom_labels)
```

### With Verification

```fortran
! Read and verify
call io_elemental(ID, VAR='nkpts', I0=nk_read, DB_I0=nk_expected, &
                  CHECK=.TRUE., OP=(/'=='/))

! Read with warning (not error)
call io_elemental(ID, VAR='temperature', R0=T_read, DB_R0=T_expected, &
                  WARN=.TRUE., OP=(/'<='/))
```

### Verification Operators

- `'=='` : Equal
- `'/='` : Not equal
- `'<'`  : Less than
- `'<='` : Less than or equal
- `'>'`  : Greater than
- `'>='` : Greater than or equal

---

## io_bulk() Quick Reference

### Define Variable

```fortran
! 2D real array
call io_bulk(ID, VAR='density', VAR_SZ=(/nx, ny/))

! 3D complex array
call io_bulk(ID, VAR='wavefunction', VAR_SZ=(/ng, nb, nk/))

! 4D integer array
call io_bulk(ID, VAR='indices', VAR_SZ=(/n1, n2, n3, n4/))
```

### Write/Read Data

```fortran
! Write entire array
call io_bulk(ID, R2=density_array)

! Read entire array
call io_bulk(ID, C3=wf_array)

! Write slice (starting at IPOS)
call io_bulk(ID, R2=slice_array, IPOS=(/1, iz/))
```

### Supported Types

| Prefix | Type | Dimensions |
|--------|------|------------|
| `I0-I5` | Integer | Scalar to 5D |
| `R0-R5` | Real (SP) | Scalar to 5D |
| `D0-D5` | Double (DP) | Scalar to 5D |
| `C0-C5` | Complex (SP) | Scalar to 5D |
| `Z0-Z5` | Complex (DP) | Scalar to 5D |
| `L0-L4` | Logical | Scalar to 4D |

---

## OpenMP Thread Safety

### Always Protect I/O Calls

```fortran
!$omp parallel default(shared)

! Computation (all threads)
!$omp do
do ib = 1, nbands
  call compute_something(ib, result)
  
  !$omp critical
  accumulator = accumulator + result
  !$omp end critical
enddo
!$omp end do

! I/O (master thread only)
!$omp master
call io_bulk(ID, R1=accumulator)
!$omp end master

!$omp end parallel
```

### Alternative: Use Single

```fortran
!$omp parallel

! ... computation ...

!$omp single
call io_elemental(ID, VAR='result', R0=final_result)
!$omp end single

!$omp end parallel
```

---

## Debugging Tips

### Enable Verbose I/O

```bash
yambo -V io
```

### Check Database Status

```fortran
if (io_status(ID) /= IO_NO_ERROR) then
  write(*,*) 'I/O error code:', io_status(ID)
endif
```

### Print I/O Variables

```fortran
use IO_m, ONLY: io_file, io_PAR_cpu, io_PAR_comm

write(*,*) 'File:', trim(io_file(ID))
write(*,*) 'CPU allowed:', io_PAR_cpu(ID)
write(*,*) 'MPI comm:', io_PAR_comm(ID)
```

### Common Mistakes

❌ **Don't do this:**
```fortran
! Forgot to call io_control before io_connect
ierr = io_connect('ndb.dipoles', ID=ID)  ! ID is undefined!
```

✅ **Do this:**
```fortran
call io_control(ACTION=OP_RD_CL, ID=ID)  ! ID is assigned here
ierr = io_connect('ndb.dipoles', ID=ID)
```

---

❌ **Don't do this:**
```fortran
! All CPUs try to write without coordination
call io_control(ACTION=OP_WR_CL, ID=ID)
ierr = io_connect('ndb.data', ID=ID)
call io_bulk(ID, R1=my_data)  ! Race condition!
```

✅ **Do this:**
```fortran
! Use DO_IT or COMM to coordinate
call io_control(ACTION=OP_WR_CL, ID=ID, DO_IT=(myid==0))
ierr = io_connect('ndb.data', ID=ID)
if (myid == 0) call io_bulk(ID, R1=my_data)
```

---

❌ **Don't do this:**
```fortran
!$omp parallel
  ! All threads try to do I/O
  call io_bulk(ID, R1=thread_data)  ! Not thread-safe!
!$omp end parallel
```

✅ **Do this:**
```fortran
!$omp parallel
  !$omp master
    call io_bulk(ID, R1=shared_data)
  !$omp end master
!$omp end parallel
```

---

## Performance Tips

### 1. Minimize I/O Calls

❌ Slow:
```fortran
do ik = 1, nk
  call io_elemental(ID, VAR='energy', R0=E(ik))  ! nk calls
enddo
```

✅ Fast:
```fortran
call io_elemental(ID, VAR='energies', R1=E)  ! 1 call
```

### 2. Use Fragments for Large Data

✅ Good for parallel access:
```fortran
! Each CPU reads its own fragment
call io_fragment(ID, ID_frag, i_fragment=my_ik)
call io_bulk(ID_frag, C2=wf_local)
```

### 3. Enable HDF5 Compression

Compile with:
```bash
./configure --enable-hdf5-compression
```

Reduces file size by ~2-5× with minimal performance impact.

### 4. Use Parallel HDF5 for Large Arrays

Compile with:
```bash
./configure --enable-hdf5-par-io
```

Then use:
```fortran
call io_control(ACTION=OP_WR_CL, COMM=my_comm, ID=ID)
```

---

## File Type Codes

| Type | Description |
|------|-------------|
| `1` | NetCDF (default) |
| `2` | HDF5 (NetCDF-4) |
| `-2` | Binary (unformatted) |
| `-4` | Binary (formatted) |

---

## Related Documentation

- **Full Guide**: `doc/IO_System_Architecture.md`
- **Flowcharts**: `doc/IO_System_Flowchart.md`
- **Source Code**: `src/Yio/`
- **Module**: `src/modules/mod_IO.F`

---

**Quick Help**: Search for `io_control` in existing code to see usage examples!