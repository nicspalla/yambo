---
title: mainpage
---

# Yambo Documentation {#mainpage}

[TOC]

## Welcome to Yambo

**Yambo** is a GPL-licensed scientific code derived from Yambo 5.3, designed for advanced Many-Body computational physics calculations. The code specializes in quantum physics simulations for solid-state physics applications, including electronic excitations, optical properties, and time-dependent phenomena.

---

## Overview

Yambo provides a comprehensive framework for:

- **Electronic Structure Calculations**: Compute electronic band structures, density of states, and wavefunctions
- **Optical Properties**: Calculate absorption spectra, dielectric functions, and optical responses
- **Time-Dependent Simulations**: Real-time propagation of electronic systems under external fields
- **Many-Body Effects**: Include electron-electron and electron-phonon interactions
- **Post-Processing**: Extensive tools for data analysis and visualization

### Key Features

| Feature | Description |
|---------|-------------|
| 🌊 **Many-Body Physics** | Advanced treatment of electron correlations using GW approximation and Bethe-Salpeter equation |
| ⚡ **Real-Time Dynamics** | Time-dependent simulations of electronic systems under external perturbations |
| 🔬 **Spectroscopy** | Calculation of optical absorption, photoemission, and other spectroscopic properties |
| 🎯 **High Performance** | Parallel computing support with MPI and optimized linear algebra |
| 📊 **Visualization** | Built-in tools for plotting and data analysis |

---

## Mathematical Framework

### Many-Body Green's Function

The central quantity in many-body theory is the one-particle Green's function:

\f[
G(\mathbf{r}, \mathbf{r}', t-t') = -i\langle \Psi_0 | T[\hat{\psi}(\mathbf{r},t)\hat{\psi}^\dagger(\mathbf{r}',t')] | \Psi_0 \rangle
\f]

where \f$\hat{\psi}\f$ and \f$\hat{\psi}^\dagger\f$ are field operators, and \f$T\f$ is the time-ordering operator.

### GW Approximation

The self-energy in the GW approximation is given by:

\f[
\Sigma(\mathbf{r}, \mathbf{r}', \omega) = i \int \frac{d\omega'}{2\pi} G(\mathbf{r}, \mathbf{r}', \omega + \omega') W(\mathbf{r}, \mathbf{r}', \omega')
\f]

where \f$W\f$ is the screened Coulomb interaction:

\f[
W(\mathbf{r}, \mathbf{r}', \omega) = \int d\mathbf{r}'' \epsilon^{-1}(\mathbf{r}, \mathbf{r}'', \omega) v(\mathbf{r}'' - \mathbf{r}')
\f]

### Bethe-Salpeter Equation

For optical excitations, the Bethe-Salpeter equation reads:

\f[
(E_c - E_v)A_{vck} + \sum_{v'c'k'} \langle vck | K | v'c'k' \rangle A_{v'c'k'} = \Omega A_{vck}
\f]

where \f$K\f$ is the electron-hole interaction kernel.

### Time-Dependent Schrödinger Equation

Real-time dynamics are governed by:

\f[
i\hbar \frac{\partial}{\partial t} |\Psi(t)\rangle = \hat{H}(t) |\Psi(t)\rangle
\f]

with the time-dependent Hamiltonian:

\f[
\hat{H}(t) = \hat{H}_0 + \hat{H}_{\text{ext}}(t) + \hat{H}_{\text{ee}}(t)
\f]

---

## Code Architecture

### Directory Structure

```
Yambo/
├── src/              # Main source code
│   ├── modules/      # Fortran modules and data structures
│   ├── wf_and_fft/   # Wavefunction and FFT operations
│   ├── io/           # Input/output routines
│   ├── real_time_*/  # Real-time simulation modules
│   ├── bse/          # Bethe-Salpeter equation solver
│   ├── qp/           # Quasiparticle calculations
│   ├── dipoles/      # Dipole matrix elements
│   ├── collisions/   # Collision integrals
│   └── ...           # Other physics modules
├── driver/           # Main program entry points
├── ypp/              # Post-processing utilities
├── include/          # Header files and common definitions
├── interfaces/       # External library interfaces
├── lib/              # External libraries
├── config/           # Build system configuration
└── doc/              # Documentation
```

### Module Organization

The code is organized into functional modules:

- **@ref modules "Core Modules"**: Basic data structures and common utilities
- **@ref wf_and_fft "Wavefunctions & FFT"**: Wavefunction manipulation and Fourier transforms
- **@ref io "Input/Output"**: File I/O and database management
- **@ref real_time "Real-Time Dynamics"**: Time propagation algorithms
- **@ref bse "BSE Solver"**: Bethe-Salpeter equation implementation
- **@ref qp "Quasiparticles"**: GW calculations and quasiparticle corrections
- **@ref linear_algebra "Linear Algebra"**: Matrix operations and solvers

---

## Documentation Structure

This documentation is organized into the following main sections:

### 📚 **[Theory & Methods](@ref theory_section)**
Comprehensive theoretical background and mathematical formulations:
- @subpage yambo_theory_main "YAMBO Theory Documentation Suite"
- @subpage yambo_rt_theory_main "Real-Time TDDFT Theory"
- @subpage yambo_formulas "Quick Formula Reference"

### 🔧 **[User Guides & References](@ref user_guides_section)**
Practical guides for using YAMBO and YPP:
- @subpage input_flags "Input Parameters Reference"
- @subpage doxygen_quick_ref "Doxygen Quick Reference"

### 🔬 **[Real-Time Simulations](@ref realtime_section)**
Real-time TDDFT simulations and post-processing:
- @subpage yambo_rt_theory_main "RT Theory Documentation"
- @subpage ypp_rt_main "YPP Real-Time Post-Processing"
- @subpage kb_implementation "Kadanoff-Baym Implementation Analysis"
- @subpage two_time_reconstruction "Two-Time Green's Function Reconstruction"
- @subpage rt_dyson_summary "RT-DE for TR-ARPES: Executive Summary" ⭐ NEW
- @subpage rt_dyson_comparison "RT-DE vs Current Method: Visual Comparison" ⭐ NEW
- @subpage rt_dyson_expansion "Real-Time Dyson Expansion: Detailed Analysis" ⭐ NEW

### 💾 **[I/O System](@ref io_section)**
Input/Output system architecture and usage:
- @subpage io_architecture "I/O System Architecture"
- @subpage io_flowchart "I/O System Flowchart"
- @subpage io_quick_ref "I/O Quick Reference"

### 🧮 **[Memory Management](@ref memory_section)**
Memory allocation and management system:
- @subpage alloc_main "Memory Allocation Documentation Suite"

---

## Getting Started

### Input Parameters Reference

For a comprehensive guide to all input flags and parameters, see the **@ref input_flags "Input Flags Documentation"**.

This reference covers:
- All ~177 input parameters organized by functionality
- Parameter types, descriptions, and default values
- Usage examples for GW, BSE, TDDFT, and real-time calculations
- Units reference and input file format guide

### Prerequisites

Before building Yambo, ensure you have:

- **Fortran Compiler**: gfortran 9.0+ or ifort 19.0+
- **C Compiler**: gcc or icc
- **MPI**: OpenMPI or Intel MPI (for parallel execution)
- **Libraries**:
  - libxc (v5.2.3+) - Exchange-correlation functionals
  - HDF5 - Hierarchical data format
  - FFTW3 - Fast Fourier transforms
  - BLAS/LAPACK - Linear algebra
  - ScaLAPACK - Parallel linear algebra (optional)
  - NetCDF - Network Common Data Form (optional)

### Building Yambo

1. **Configure the build**:
   ```bash
   ./configure --enable-hdf5-p2y-support \
               --with-libxc-path=/path/to/libxc \
               --with-hdf5-path=/path/to/hdf5 \
               --with-fft-path=/path/to/fftw
   ```

2. **Compile**:
   ```bash
   make all
   ```

3. **Install** (optional):
   ```bash
   make install
   ```

The compiled binaries will be in the `bin/` directory.

### Configuration Options

| Option | Description |
|--------|-------------|
| `--enable-hdf5-p2y-support` | Enable HDF5 support for p2y interface |
| `--enable-par-linalg` | Enable parallel linear algebra |
| `--with-libxc-path=PATH` | Path to libxc installation |
| `--with-hdf5-path=PATH` | Path to HDF5 installation |
| `--with-fft-path=PATH` | Path to FFTW installation |
| `--with-blas-libs=LIBS` | BLAS library flags |
| `--with-lapack-libs=LIBS` | LAPACK library flags |
| `--with-scalapack-libs=LIBS` | ScaLAPACK library flags |

---

## Usage Examples

### Basic Workflow

1. **Prepare input data**: Convert DFT output to Yambo format
   ```bash
   p2y -F input.xml
   ```

2. **Run Yambo calculation**:
   ```bash
   yambo -i input_file -o output_file
   ```

3. **Post-process results**:
   ```bash
   ypp -e c -V qp
   ```

### Real-Time Simulation

For time-dependent calculations:

```fortran
! Initialize real-time simulation
call RT_initialize(en, k, q)

! Time propagation loop
do i_time = 1, n_time_steps
  ! Apply external field
  call RT_apply_field(E_field, i_time)
  
  ! Propagate density matrix
  call RT_propagate(rho, dt)
  
  ! Calculate observables
  call RT_observables(rho, current, polarization)
end do
```

---

## Physics Modules

### @ref xc_functionals "Exchange-Correlation Functionals"

Implementation of various XC functionals using libxc:
- LDA (Local Density Approximation)
- GGA (Generalized Gradient Approximation)
- Hybrid functionals
- Meta-GGA functionals

### @ref coulomb "Coulomb Interaction"

Treatment of the Coulomb interaction:
- Bare Coulomb potential: \f$v(\mathbf{q}) = \frac{4\pi e^2}{q^2}\f$
- Screened interaction: \f$W = \epsilon^{-1} v\f$
- Cutoff techniques for 2D and 1D systems

### @ref dipoles "Dipole Matrix Elements"

Calculation of dipole transitions:

\f[
\langle n\mathbf{k} | \mathbf{r} | m\mathbf{k} \rangle = \frac{i}{\omega_{nm}} \langle n\mathbf{k} | \nabla | m\mathbf{k} \rangle
\f]

### @ref collisions "Collision Integrals"

Electron-electron and electron-phonon scattering:

\f[
\Gamma_{nm}(\mathbf{k}) = 2\pi \sum_{\mathbf{k}'} |M_{nm}(\mathbf{k}, \mathbf{k}')|^2 \delta(E_n(\mathbf{k}) - E_m(\mathbf{k}'))
\f]

---

## Performance Optimization

### Parallelization Strategy

Yambo uses a multi-level parallelization approach:

1. **K-point parallelization**: Distribute k-points across MPI processes
2. **Band parallelization**: Distribute bands within each k-point
3. **G-vector parallelization**: Distribute plane waves for FFT operations
4. **Frequency parallelization**: Distribute frequency points in response functions

### Memory Management

Efficient memory usage through:
- Dynamic allocation of arrays
- Memory pools for frequently used objects
- Out-of-core algorithms for large matrices
- Compressed storage formats

### Computational Complexity

| Operation | Complexity | Scaling |
|-----------|-----------|---------|
| FFT | \f$O(N \log N)\f$ | Excellent |
| Matrix multiplication | \f$O(N^3)\f$ | Good with ScaLAPACK |
| Diagonalization | \f$O(N^3)\f$ | Moderate |
| BSE solver | \f$O(N^4)\f$ | Challenging |

---

## Contributing

We welcome contributions to Yambo! Please see the [AUTHORS](AUTHORS) file for the list of contributors.

### Coding Standards

- **Language**: Fortran 90/95
- **Style**: Follow the existing code style
- **Documentation**: Use Doxygen comments for all subroutines and modules
- **Testing**: Add tests for new features

### Doxygen Documentation Guidelines

All subroutines and functions should include:

```fortran
!> @brief Brief one-line description
!> @author Your Name
!> @date YYYY-MM-DD
!>
!> @details
!! Detailed description of the algorithm and implementation.
!! Can include multiple paragraphs and LaTeX formulas:
!! \f$ E = mc^2 \f$
!!
!> @param[in] input_param Description of input parameter
!> @param[out] output_param Description of output parameter
!> @param[in,out] inout_param Description of input/output parameter
!>
!> @note Important notes for users
!> @warning Potential pitfalls or limitations
!> @see Related functions or modules
!>
!> @callgraph
!> @callergraph
subroutine example_routine(input_param, output_param, inout_param)
```

---

## References

### Key Publications

1. **Yambo Code**: [www.yambo-code.eu](https://www.yambo-code.eu)
2. **GW Approximation**: Hedin, L. (1965). "New Method for Calculating the One-Particle Green's Function with Application to the Electron-Gas Problem"
3. **Bethe-Salpeter Equation**: Salpeter, E. E., & Bethe, H. A. (1951). "A Relativistic Equation for Bound-State Problems"
4. **Time-Dependent DFT**: Runge, E., & Gross, E. K. (1984). "Density-Functional Theory for Time-Dependent Systems"

### External Resources

- [Yambo Wiki](https://www.yambo-code.eu/wiki/)
- [Yambo Forum](https://www.yambo-code.eu/forum)
- [MaX Centre](https://www.max-centre.eu)

---

## License

Yambo is distributed under the **GNU General Public License v2.0** (GPL-2.0).

All material included in this distribution is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.

These programs are distributed in the hope that they will be useful, but **WITHOUT ANY WARRANTY**; without even the implied warranty of **MERCHANTABILITY** or **FITNESS FOR A PARTICULAR PURPOSE**. See the GNU General Public License for more details.

See the [COPYING](COPYING) file for the full license text.

---

## Contact and Support

For questions, bug reports, or feature requests:

- **Issue Tracker**: See the ISSUES file
- **Authors**: See the AUTHORS file
- **Changelog**: See the ChangeLog file

---

## Acknowledgments

Yambo is derived from Yambo 5.3, developed by the Yambo team. We acknowledge:

- The Yambo development team
- The MaX Centre of Excellence
- All contributors to the project
- The scientific community using and improving the code

---

*Generated with Doxygen*