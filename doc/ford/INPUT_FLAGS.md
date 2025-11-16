---
title: INPUT FLAGS
---

# Yambo Input Flags Reference {#input_flags}

This document provides a comprehensive reference for all input flags and command-line options available in Yambo/Yambo. The flags are organized by category for easy navigation.

---

## Table of Contents

1. [Command-Line Options](#command-line-options)
   - [Self-Energy Calculations](#self-energy-calculations)
   - [Initializations](#initializations)
   - [Response Functions](#response-functions)
   - [Bethe-Salpeter Equation](#bethe-salpeter-equation)
   - [Total Energy](#total-energy)
   - [Real-Time Dynamics](#real-time-dynamics)
   - [Hamiltonians & Potentials](#hamiltonians--potentials)
   - [Control Options](#control-options)
2. [Run Levels](#run-levels)
3. [Basic Parameters](#basic-parameters)
4. [K-Points and Grids](#k-points-and-grids)
5. [Temperature and Occupation](#temperature-and-occupation)
6. [Parallel Execution](#parallel-execution)
7. [Input/Output Control](#inputoutput-control)
8. [Self-Energy and GW Calculations](#self-energy-and-gw-calculations)
9. [Response Functions (X)](#response-functions-x)
10. [Bethe-Salpeter Equation (BSE)](#bethe-salpeter-equation-bse)
11. [BSE Solvers](#bse-solvers)
12. [TDDFT and Exchange-Correlation](#tddft-and-exchange-correlation)
13. [Dipoles](#dipoles)
14. [Coulomb Interaction and RIM](#coulomb-interaction-and-rim)
15. [Cutoff Techniques](#cutoff-techniques)
16. [ACFDT](#acfdt)
17. [Advanced Options](#advanced-options)

---

## Command-Line Options

Yambo/Yambo calculations are initiated using command-line options that specify the calculation type and parameters. These options can be combined to perform complex calculations.

### Self-Energy Calculations

| Short | Long Option | Description | Options |
|-------|-------------|-------------|---------|
| `-x` | `--hf` | Hartree-Fock self-energy | - |
| `-p` | `--gw0` | GW approximation | `p` = pPA, `m` = mPA, `c` = COHSEX, `r` = real-axis, `fan` = Fan (with _ELPH), `X` = (with _ELPH) |
| `-g` | `--dyson` | Dyson equation solver | `g` = Green's function (any scattering), `n` = Newton [order 1], `s` = Secant (e-e scattering), `n` = Newton [order 2] (p-e scattering with _PHEL) |
| `-l` | `--lifetimes` | GoWo quasiparticle lifetimes | - |
| `-c` | `--correlation` | Correlation kind (yambo_ph, yambo_qed) | `ee` = electron-electron, `eh` = electron-photon (with _QED), `ep` = electron-phonon (with _ELPH), `pe` = phonon-electron (with _ELPH) |

**Example:**
```bash
yambo -p c -g n -x    # COHSEX calculation with Newton solver and HF
yambo -p p -g g       # GW with plasmon-pole and Green's function solver
```

### Initializations

| Short | Long Option | Description |
|-------|-------------|-------------|
| `-i` | `--setup` | Initialize calculation and generate input file |
| `-r` | `--coulomb` | Coulomb potential (RIM/cutoff) |
| `-w` | `--rw` | Screened Coulomb potential |

**Example:**
```bash
yambo -i              # Generate input file
yambo -r              # Setup Coulomb potential with RIM
```

### Response Functions

| Short | Long Option | Description | Options |
|-------|-------------|-------------|---------|
| `-o` | `--optics` | Linear response optical properties | `c` = Reciprocal-space (chi), `b` = Transition-space (BSE) |
| `-d` | `--X` | Inverse dielectric/response matrix | `s` = static, `p` = pPA, `m` = mPA, `d` = dynamical dielectric matrix, `X` = dynamical response matrix |
| `-q` | `--dipoles` | Calculate oscillator strengths (dipoles) | - |
| `-k` | `--kernel` | Exchange-correlation kernel | `hartree`, `alda`, `lrc`, `hf`, `sex`, `bsfxc` (Note: hf/sex only in eh-space; lrc only in G-space) |

**Example:**
```bash
yambo -o c -k hartree    # Chi calculation with Hartree kernel
yambo -o b -k sex        # BSE calculation with screened exchange kernel
yambo -d -k alda         # Response function with ALDA kernel
```

### Bethe-Salpeter Equation

| Short | Long Option | Description | Options |
|-------|-------------|-------------|---------|
| `-y` | `--Ksolver` | BSE solver method | `h` = Haydock, `d` = diagonalization, `pi` = perturbative inversion, `fi` = full inversion, `s` = SLEPc partial diagonalization (with _SLEPC) |

**Example:**
```bash
yambo -o b -y h       # BSE with Haydock solver
yambo -o b -y d       # BSE with full diagonalization
```

### Total Energy

| Short | Long Option | Description |
|-------|-------------|-------------|
| - | `--acfdt` | ACFDT total energy calculation |

**Example:**
```bash
yambo --acfdt         # ACFDT calculation
```

### Real-Time Dynamics

| Short | Long Option | Description | Options | Binary |
|-------|-------------|-------------|---------|--------|
| `-n` | `--rt` | NEQ real-time dynamics | `p` = pump or probe, `pp` = pump & probe, `pn` = n external fields | yambo_rt |
| `-u` | `--nl` | Non-linear spectroscopy | `p` = pump or probe, `n` = non-linear optics | yambo_nl |
| `-s` | `--scattering` | NEQ scattering kind | `ee` = electron-electron, `eh` = electron-photon (with _QED), `ep` = electron-phonon (with _ELPH), `pe` = phonon-electron (with _ELPH). Can combine: `ee+ep` | yambo_rt |
| `-e` | `--collisions` | Collisions | - | yambo_rt, yambo_sc, yambo_nl |
| `-u` | `--pl` | Photo-luminescence | - | yambo_pl |

**Example:**
```bash
yambo_rt -n p -s ee      # Real-time with pump field and e-e scattering
yambo_rt -n pp -s ee+ep  # Pump-probe with e-e and e-ph scattering
yambo_nl -u n            # Non-linear optics
```

### Hamiltonians & Potentials

| Short | Long Option | Description | Options | Binary |
|-------|-------------|-------------|---------|--------|
| `-s` | `--sc` | Self-consistent single-particle calculations | - | yambo_sc |
| `-v` | `--potential` | Self-consistent potential | `h` = Hartree, `f` = Fock, `coh` = COH, `sex` = SEX, `exx` = EXX, `exxc` = EXXC, `srpa` = SRPA, `d` = default, `ip` = IP, `ldax` = LDA_X, `pz` = PZ, `gs` = GS, `cvonly` = compute only cv collisions, `kbse` = compute collisions from BSE. Can combine, e.g., `hf` for Hartree-Fock | yambo_sc, yambo_rt, yambo_nl |
| - | `--magnetic` | Self-consistent magnetic calculations | `p` = Pauli, `l` = Landau | yambo_sc |
| - | `--electric` | Self-consistent static electric field | - | yambo_sc |
| - | `--epham` | Electron-phonon Hamiltonian | - | yambo_ph |
| `-m` | `--excph` | Exciton-phonon | `o` = optical spectra, `l` = lifetimes | yambo_ph |

**Example:**
```bash
yambo_sc -s -v hf        # Self-consistent Hartree-Fock
yambo_sc -s -v sex       # Self-consistent screened exchange
yambo_rt -v ip -e        # Real-time with IP potential and collisions
```

### Control Options

| Short | Long Option | Description | Options |
|-------|-------------|-------------|---------|
| `-F` | `--Input` | Input file (or KSS/WFK file for a2y/e2y) | filename |
| `-V` | `--Verbosity` | Input file variables verbosity | `RL`, `kpt`, `sc`, `qp`, `io`, `gen`, `resp`/`X`, `ph`, `rt`, `par`, `nl`, `all` |
| `-Q` | `--Quiet` | Quiet input file creation | - |
| - | `--fatlog` | Verbose (fatter) log files | - |
| - | `--expuser` | Assume experienced user | - |
| `-D` | `--DBlist` | Database properties | - |
| - | `--walltime` | Walltime limit | Format: DdHhMm (D=days, H=hours, M=minutes) |
| - | `--memory` | Memory limit per processor | Value in Mb/Gb, e.g., `1Gb` |
| `-J` | `--Job` | Job string identifier | string |
| `-I` | `--Idir` | Input directory | path |
| `-O` | `--Odir` | Output/I-O directory | path |
| `-C` | `--Cdir` | Communication directory | path |
| `-E` | `--parenv` | Environment parallel variables file | filename |
| - | `--nompi` | Switch off MPI support | - |
| - | `--noopenmp` | Switch off OpenMP support | - |
| - | `--slktest` | ScaLAPACK test (with _SCALAPACK) | - |
| - | `--gputest` | GPU test | - |

**Example:**
```bash
yambo -F input.in -V qp      # Use input.in with QP verbosity
yambo -i -V all              # Generate input with all variables
yambo -J "GW_calc" -O outdir # Set job name and output directory
```

---

## Run Levels

Run levels determine which calculation type to perform. These are typically set via command-line options (see above) and appear in the input file.

| Flag | Type | Description | Command-Line |
|------|------|-------------|--------------|
| `HF_and_locXC` | Runlevel | Hartree-Fock and local XC | `-x` or `--hf` |
| `gw0` | Runlevel | GW approximation | `-p` or `--gw0` |
| `life` | Runlevel | Quasiparticle lifetimes | `-l` or `--lifetimes` |
| `setup` | Runlevel | Initialization | `-i` or `--setup` |
| `rim_cut` | Runlevel | Coulomb potential | `-r` or `--coulomb` |
| `rim_w` | Runlevel | Screened Coulomb potential | `-w` or `--rw` |
| `optics` | Runlevel | Optical properties | `-o` or `--optics` |
| `screen` | Runlevel | Inverse dielectric matrix | `-d` or `--X` |
| `dipoles` | Runlevel | Dipole matrix elements | `-q` or `--dipoles` |
| `bss` | Runlevel | BSE solver | `-y` or `--Ksolver` |
| `acfdt` | Runlevel | ACFDT total energy | `--acfdt` |
| `negf` | Runlevel | Real-time NEQ dynamics | `-n` or `--rt` (yambo_rt) |
| `nloptics` | Runlevel | Non-linear optics | `-u` or `--nl` (yambo_nl) |
| `scrun` | Runlevel | Self-consistent run | `-s` or `--sc` (yambo_sc) |
| `collisions` | Runlevel | Collision integrals | `-e` or `--collisions` |
| `photolum` | Runlevel | Photo-luminescence | `--pl` (yambo_pl) |
| `ElPhHam` | Runlevel | Electron-phonon Hamiltonian | `--epham` (yambo_ph) |
| `chi` | Runlevel | Dyson equation for Chi | (internal) |
| `bse` | Runlevel | Bethe Salpeter Equation | (internal) |
| `tddft` | Runlevel | Use TDDFT kernel | (internal) |
| `cohsex` | Runlevel | Coulomb Hole Screened Exchange | `-p c` |
| `Xx` | Runlevel | Dynamical Response Function | (internal) |
| `em1s` | Runlevel | Statically Screened Interaction | (internal) |
| `em1d` | Runlevel | Dynamically Screened Interaction | (internal) |
| `ppa` | Runlevel | Plasmon Pole Approximation | `-p p` |
| `mpa` | Runlevel | Multi Pole Approximation | `-p m` |
| `el_el_corr` | Runlevel | Electron-Electron Correlation | (internal) |

---

## Basic Parameters

Fundamental parameters that control the basic setup of the calculation.

| Flag | Type | Description | Default/Units |
|------|------|-------------|---------------|
| `StdoHash` | Integer | Live-timing Hashes | - |
| `MaxGvecs` | Integer | Max number of G-vectors planned to use | G-vectors |
| `Gthresh` | Real | Accuracy for energy shell separation (-1 = automatic) | - |
| `FFTGvecs` | Integer | Plane-waves for FFT | G-vectors |
| `NonPDirs` | String | Non-periodic Cartesian directions (X,Y,Z,XY...) | - |
| `MolPos` | Real(3) | Molecule coordinates in supercell (0.5 = middle) | - |
| `Nelectro` | Real | Number of electrons | - |

---

## K-Points and Grids

Parameters controlling k-point sampling and grid selection.

| Flag | Type | Description | Default/Units |
|------|------|-------------|---------------|
| `K_grids` | String | Select the grids (X=response, S=sigma, C=collisions, B=bse) | "X S C B" |
| `IkSigLim` | Integer(2) | QP K-points indices range | - |
| `IkXLim` | Integer | X grid last k-point index | - |

---

## Temperature and Occupation

Parameters related to electronic and bosonic temperatures and occupation.

| Flag | Type | Description | Default/Units |
|------|------|-------------|---------------|
| `ElecTemp` | Real | Electronic Temperature | Temperature units |
| `OccTresh` | Real | Occupation threshold (metallic bands) | - |
| `BoseTemp` | Real | Bosonic Temperature | Temperature units |
| `EXCTemp` | Real | Excitonic Temperature (for luminescence spectra) | Temperature units |
| `BoseCut` | Real | Finite T Bose function cutoff | - |

---

## Parallel Execution

Parameters controlling parallel execution and threading.

| Flag | Type | Description | Default/Units |
|------|------|-------------|---------------|
| `NLogCPUs` | Integer | Live-timing CPUs (0 for all) | 0 |
| `PAR_def_mode` | String | Default distribution mode (balanced/memory/workload/KQmemory) | "balanced" |

**OpenMP Threading (if compiled with OpenMP):**

| Flag | Type | Description |
|------|------|-------------|
| `K_Threads` | Integer | Number of threads for BSE kernel |
| `X_Threads` | Integer | Number of threads for response functions |
| `DIP_Threads` | Integer | Number of threads for dipoles |
| `OSCLL_Threads` | Integer | Number of threads for oscillators |
| `SE_Threads` | Integer | Number of threads for self-energy |
| `RT_Threads` | Integer | Number of threads for real-time |
| `NL_Threads` | Integer | Number of threads for nl-optics |

---

## Input/Output Control

Flags controlling file I/O and database management.

| Flag | Type | Description | Options |
|------|------|-------------|---------|
| `DBsIOoff` | String | Space-separated list of DB with NO I/O | DIP, X, HF, COLLs, J, GF, CARRIERs, OBS, W, SC, BS, ALL |
| `DBsFRAGpm` | String | Space-separated list of +DB to FRAG and -DB to NOT FRAG | DIP, X, W, HF, COLLS, K, BS, QINDX, RT, ELPH, SC, ALL |
| `WF_load_mode` | String | Default distribution mode for wavefunctions | "all" / "on-the-fly" |
| `WFbuffIO` | Flag | Wave-functions buffered I/O | - |

---

## Self-Energy and GW Calculations

Parameters for GW and self-energy calculations.

### Band and Component Selection

| Flag | Type | Description | Default/Units |
|------|------|-------------|---------------|
| `GbndRnge` | Integer(2) | G[W] bands range | - |
| `HARRLvcs` | Integer | Hartree RL components | G-vectors |
| `EXXRLvcs` | Integer | Exchange RL components | G-vectors |
| `VXCRLvcs` | Integer | XC potential RL components | G-vectors |
| `CORRLvcs` | Integer | Correlation RL components | G-vectors |
| `UseNLCC` | Flag | Add NLCC contributions to charge density | - |
| `UseEbands` | Flag | Force COHSEX to use empty bands | - |

### Damping and Energy Parameters

| Flag | Type | Description | Default/Units |
|------|------|-------------|---------------|
| `GDamping` | Real | G[W] damping | Energy units |
| `GDmRnge` | Real(2) | G_gw damping range | Energy units |
| `dScStep` | Real | Energy step to evaluate Z factors | Energy units |
| `LifeTrCG` | Real | Lifetime transition reduction | % |

### Solvers and Sampling

| Flag | Type | Description | Options |
|------|------|-------------|---------|
| `DysSolver` | String | Dyson Equation solver | "n" (newton), "s" (secant), "g" (green), "q" |
| `GsampType` | String | Type of sampling | "ra" (FF-RA), "1l" (MPA-1l), "2l" (MPA-2l) |

### Green's Function Parameters

| Flag | Type | Description | Default/Units |
|------|------|-------------|---------------|
| `GEnSteps` | Integer | Green's Function energy steps | - |
| `GEnRnge` | Real(2) | GF energy range | Energy units |
| `GImRnge` | Real(2) | GF imaginary range | Energy units |
| `GEnMode` | String | GF energy mode | "centered" / "absolute" |
| `GreenFTresh` | Real | Threshold to define new zoomed energy range | % |

### Terminator

| Flag | Type | Description | Options |
|------|------|-------------|---------|
| `GTermKind` | String | GW terminator | "none", "BG" (Bruneval-Gonze), "BRS" (Berger-Reining-Sottile) |
| `GTermEn` | Real | GW terminator energy (for kind="BG") | Energy units |

### Flags

| Flag | Description |
|------|-------------|
| `NewtDchk` | Test dSc/dw convergence |
| `ExtendOut` | Print all variables in the output file |
| `QPsymmtrz` | Force symmetrization of states with the same energy |
| `QPExpand` | The QP corrections are expanded all over the BZ |
| `GreenF2QP` | Use real axis Green's function to define the QPs |
| `OnMassShell` | On mass shell approximation |

### Self-Consistent Calculations

| Flag | Type | Description | Default/Units |
|------|------|-------------|---------------|
| `SCEtresh` | Real | Energy convergence threshold for SC-GW | Energy units |

---

## Response Functions (X)

Parameters for calculating the response function (polarizability).

### Mode and Algorithm

| Flag | Type | Description | Options |
|------|------|-------------|---------|
| `Chimod` | String | Chi mode | IP, Hartree, ALDA, LRC, PF, BSfxc |
| `ChiLinAlgMod` | String | Linear algebra mode | inversion/lin_sys, cpu/gpu |

### Terminator

| Flag | Type | Description | Options |
|------|------|-------------|---------|
| `XTermKind` | String | X terminator | "none", "BG" (Bruneval-Gonze) |
| `XTermEn` | Real | X terminator energy (for kind="BG") | Energy units |

### Q-vector Parameters

| Flag | Type | Description | Default/Units |
|------|------|-------------|---------------|
| `Qdirection` | Real(3) | Transferred momentum direction | iku |
| `QShiftOrder` | Integer | Pick-up the (QShiftOrder)th q+G vector | - |

### Database and Output

| Flag | Type | Description | Default/Units |
|------|------|-------------|---------------|
| `DbGdQsize` | Real | Percentual of total DbGd transitions to use | % |

### Flags

| Flag | Description |
|------|-------------|
| `DrClassic` | Use a classical model for the drude term |
| `mpERdb` | Write to disk MPA poles and residues |
| `WriteXo` | Write on-the-fly the IP response function |
| `OptDipAverage` | Average Xd along the non-zero Electric Field directions |

---

## Bethe-Salpeter Equation (BSE)

Parameters for BSE kernel construction and electron-hole interaction.

### Mode and Kernel

| Flag | Type | Description | Options |
|------|------|-------------|---------|
| `BSEmod` | String | BSE mode | resonant, retarded, coupling |
| `BSKmod` | String | BSE kernel mode | IP, Hartree, HF, ALDA, SEX, BSfxc |
| `Lkind` | String | Screening type | bar (default), full, tilde |

### Bands and Energy Windows

| Flag | Type | Description | Default/Units |
|------|------|-------------|---------------|
| `BSEBands` | Integer(2) | Bands range for BSE | - |
| `BSEFrozenBands` | String | Bands excluded from BSE construction | - |
| `BSEEhEny` | Real(2) | Electron-hole energy range | Energy units |
| `BSehWind` | Real | E/h coupling pairs energy window | % |

### G-vectors Components

| Flag | Type | Description | Default/Units |
|------|------|-------------|---------------|
| `BSENGBlk` | Integer | Screened interaction block size (-1 = all G-vectors) | G-vectors |
| `BSENGexx` | Integer | Exchange components | G-vectors |
| `BSENGfxc` | Integer | Fxc components | G-vectors |

### Q-points

| Flag | Type | Description | Default/Units |
|------|------|-------------|---------------|
| `BSEQptR` | Integer(2) | Transferred momenta range | - |

### Kernel Cutoff and I/O

| Flag | Type | Description | Default/Units |
|------|------|-------------|---------------|
| `BSKCut` | Real | Cutoff on the BSE Kernel (0=full, 1=none) | - |
| `BSKIOmode` | String | I/O mode | "1D_linear"/"2D_standard" + "norestart" + "write_all_steps" |

### Gauge and Properties

| Flag | Type | Description | Options |
|------|------|-------------|---------|
| `Gauge` | String | Gauge for dipoles | length, velocity |
| `BSEprop` | String | Property to calculate | abs, jdos, kerr, asymm, anHall, magn, dich, photolum, esrt |
| `BSEdips` | String | Dipole geometry | trace, none, xy, xz, yz |

### Flags

| Flag | Description |
|------|-------------|
| `NoCondSumRule` | Do not impose the conductivity sum rule in velocity gauge |
| `MetDamp` | Define ω+=sqrt(ω*(ω+iη)) |
| `FxcLibxc` | Force computing Fxc via libxc |
| `WehDiag` | Diagonal (G-space) the e-h interaction |
| `WehCpl` | e-h interaction included also in coupling |
| `ALLGexx` | Force the use of all RL vectors for the exchange part |

---

## BSE Solvers

Parameters for solving the BSE and computing optical spectra.

### Solver Selection

| Flag | Type | Description | Options |
|------|------|-------------|---------|
| `BSSmod` | String | BSE solver | (h)aydock, (d)iagonalization, (s)lepc, (i)nversion, (t)ddft |

### Energy Grid and Damping

| Flag | Type | Description | Default/Units |
|------|------|-------------|---------------|
| `BEnRange` | Real(2) | Energy range | Energy units |
| `BDmRange` | Real(2) | Damping range | Energy units |
| `BEnSteps` | Integer | Energy steps | - |
| `BDmERef` | Real | Damping energy reference | Energy units |

### Field Directions

| Flag | Type | Description | Default/Units |
|------|------|-------------|---------------|
| `BLongDir` | Real(3) | Electric Field versor | Cartesian |
| `QPropDir` | Real(3) | Propagation versor Field | Cartesian |

### Haydock Solver

| Flag | Type | Description | Default/Units |
|------|------|-------------|---------------|
| `BSHayTrs` | Real | Relative Haydock threshold (Strict>0 / Average<0) | % |
| `BSHayItrMAX` | Integer | Max number of Haydock iterations | - |
| `BSHayItrIO` | Integer | Iterations between I/O for Haydock restart | - |

### Diagonalization Solver

| Flag | Type | Description | Default/Units |
|------|------|-------------|---------------|
| `BSSNEig` | Integer | Number of eigenvalues to compute | - |
| `BSSFirstEig` | Integer | Index of the first eigenvalue to compute | - |
| `BSSEnRange` | Real(2) | Target energy to find eigenvalues | Energy units |
| `BSSldiaLib` | String | Library used with ldiago solver | (s)calapack, (e)lpa |

### Inversion Solver

| Flag | Type | Description | Options |
|------|------|-------------|---------|
| `BSSInvMode` | String | Inversion solver modality | (f)ull, (p)erturbative |
| `BSSInvPFratio` | Real | Ratio between frequencies solved pert/full | - |
| `BSEPSInvTrs` | Real | EPS Inversion threshold (Relative>0 / Absolute<0) | % |
| `BSPLInvTrs` | Real | PL Inversion threshold | - |

### Additional Parameters

| Flag | Type | Description | Default/Units |
|------|------|-------------|---------------|
| `DrudeWBS` | Real | Drude plasmon | Energy units |

### Flags

| Flag | Description |
|------|-------------|
| `WRbsWF` | Write to disk excitonic wavefunctions |
| `BSHayTer` | Terminate Haydock continuous fraction |
| `Reflectivity` | Compute reflectivity at normal incidence |
| `BSSPertWidth` | Include QPs lifetime in a perturbative way |
| `BSSInvKdiag` | In the inversion solver keep the diagonal kernel in place |

---

## TDDFT and Exchange-Correlation

Parameters for TDDFT kernels and exchange-correlation functionals.

### Kernel Parameters

| Flag | Type | Description | Options |
|------|------|-------------|---------|
| `FxcMode` | String | Fxc mode | "G-XXX" or "R-XXX" with XXX=def/full/cut_Gmax/cut_GmGp |
| `FxcGRLc` | Integer | XC-kernel RL size | G-vectors |

### LRC (Long-Range Corrected) Parameters

| Flag | Type | Description | Default/Units |
|------|------|-------------|---------------|
| `LRC_alpha` | Real | LRC alpha factor | - |
| `LRC_beta` | Real | LRC beta factor | - |

### PF (Parameter-Free) Parameters

| Flag | Type | Description | Options |
|------|------|-------------|---------|
| `PF_alpha` | String | PF alpha factor approximation | CUR, EMP, RBO, JGM |

### Memory and Precision

| Flag | Type | Description | Default/Units |
|------|------|-------------|---------------|
| `FxcMEStps` | Real | Memory energy steps | % |
| `FxcSVdig` | Integer | Keep SV within FxcSVdig digits | - |

### Flags

| Flag | Description |
|------|-------------|
| `FxcRetarded` | Retarded TDDFT kernel |

---

## Dipoles

Parameters for dipole matrix element calculations.

| Flag | Type | Description | Default/Units |
|------|------|-------------|---------------|
| `DipBands` | Integer(2) | Bands range for dipoles | - |
| `DipQpts` | Integer(2) | Q-points range for dipoles | - |
| `DipoleEtresh` | Real | Threshold in the definition of R=P/deltaE | Energy units |
| `DipApproach` | String | Approach | G-space v, R-space x, Covariant, Shifted grids, derk |
| `DipComputed` | String | Components to compute | default: R P V; extra: P2 Spin Orb |
| `ShiftedPaths` | String | Shifted grids paths (space-separated) | - |

### Flags

| Flag | Description |
|------|-------------|
| `DipPDirect` | Directly compute &lt;v&gt; also when using other approaches |
| `DipBandsALL` | Compute all bands range, not only valence and conduction |

---

## Coulomb Interaction and RIM

Parameters for the Coulomb interaction and Random Integration Method.

### RIM (Random Integration Method)

| Flag | Type | Description | Default/Units |
|------|------|-------------|---------------|
| `Em1Anys` | Real(3) | X Y Z Static Inverse dielectric matrix Anisotropy | - |
| `IDEm1Ref` | Integer | Dielectric matrix reference component (1=x, 2=y, 3=z) | - |
| `RandQpts` | Integer | Number of random q-points in the BZ | - |
| `RandQptsSphe` | Integer | Number of random q-points in the BZ (spherical) | - |
| `RandGvec` | Integer | Coulomb interaction RS components | G-vectors |
| `RandGvecW` | Integer | Screened interaction RS components | G-vectors |
| `rimw_type` | String | Screened interaction limit | metal, semiconductor, graphene |

### Environment

| Flag | Type | Description | Default/Units |
|------|------|-------------|---------------|
| `EpsEnv` | Real | Static Inverse dielectric matrix of environment | - |

### Flags

| Flag | Description |
|------|-------------|
| `QpgFull` | Coulomb interaction: Full matrix |

---

## Cutoff Techniques

Parameters for Coulomb cutoff in reduced dimensionality systems.

| Flag | Type | Description | Options/Units |
|------|------|-------------|---------------|
| `CUTGeo` | String | Coulomb Cutoff geometry | box, cylinder, sphere, ws, slab X/Y/Z/XY... |
| `CUTBox` | Real(3) | Box sides | a.u. |
| `CUTRadius` | Real | Sphere/Cylinder radius | a.u. |
| `CUTCylLen` | Real | Cylinder length | a.u. |
| `CUTwsGvec` | Integer | WS cutoff: number of G to be modified | - |

### Flags

| Flag | Description |
|------|-------------|
| `CUTCol_test` | Perform a cutoff test in R-space |

---

## ACFDT

Parameters for ACFDT (Adiabatic Connection Fluctuation-Dissipation Theorem) calculations.

| Flag | Type | Description | Default/Units |
|------|------|-------------|---------------|
| `AC_n_LAM` | Integer | Coupling Constant GL-grid points | - |
| `AC_n_FR` | Integer | Integration frequency points | - |
| `AC_E_Rng` | Real(2) | Imaginary axis 2nd & 3rd energy points | Energy units |

---

## Advanced Options

### Photoluminescence

| Flag | Type | Description | Default/Units |
|------|------|-------------|---------------|
| `PL_weights` | Real(3) | Weights of the Cartesian components of emitted radiation | - |

### Testing and Debugging

| Flag | Type | Description | Default/Units |
|------|------|-------------|---------------|
| `SLKdim` | Integer | ScaLAPACK Matrix Dimension for testing | - |
| `GPUdim` | Integer | GPU Matrix Dimension for testing | - |

### System Setup

| Flag | Description |
|------|-------------|
| `NoDiagSC` | New setup for non-diagonal supercells |
| `DegFix` | Force the code to impose energy levels to respect their degeneracy |

---

## Units

Yambo/Yambo uses the following unit conventions:

- **Energy**: Hartree (Ha), Rydberg (Ry), or eV depending on input
- **Temperature**: Kelvin (K)
- **Length**: Bohr radius (a.u.)
- **Time**: Atomic units (ℏ/Ha)
- **G-vectors**: Reciprocal lattice units

Units can be specified in the input file. Common unit specifications:
- Energy: `eV`, `Ha`, `Ry`, `meV`
- Temperature: `K`
- Time: `fs`, `as`

---

## Input File Format

Input files in Yambo/Yambo follow this general format:

```
# Comments start with #

ParameterName = value [unit]

# For ranges
ParameterRange = value1 | value2 [unit]

# For vectors
VectorParameter = value1 | value2 | value3

# For flags (boolean)
%FlagName
```

### Example Input File

```
# GW calculation example

# Run level
gw0                              # GW approximation

# Bands and k-points
GbndRnge = 1 | 100               # Bands range
IkSigLim = 1 | 10                # K-points range

# G-vectors
EXXRLvcs = 2 Ry                  # Exchange RL components
CORRLvcs = 2 Ry                  # Correlation RL components

# Energy grid
GEnSteps = 2                     # Energy steps
GEnRnge = -10.0 | 10.0 eV        # Energy range

# Solver
DysSolver = "n"                  # Newton solver

# Parallel
X_Threads = 4                    # OpenMP threads
```

---

## See Also

- [Yambo Official Documentation](http://www.yambo-code.org/wiki/)
- [Yambo Tutorials](http://www.yambo-code.org/wiki/index.php/Tutorials)
- [Yambo Forum](http://www.yambo-code.org/forum/)

---

## Notes

1. **Flag vs Parameter**: Flags (marked with `%` in input files) are boolean switches that don't take values. Parameters require values.

2. **Conditional Compilation**: Some flags are only available if Yambo/Yambo was compiled with specific options (e.g., `_ELPH`, `_RT`, `_NL`, `_SC`, `_QED`).

3. **Default Values**: Many parameters have sensible defaults. Only specify parameters you need to change.

4. **Case Sensitivity**: Parameter names are case-sensitive. Flag names in string parameters (like solver names) may have specific case requirements.

5. **Verbosity Levels**: Many parameters have associated verbosity levels that control how much information is printed during execution.

---

*This documentation was automatically generated from the INIT_load.F source file.*
*Last updated: 2025*