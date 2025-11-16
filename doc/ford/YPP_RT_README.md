---
title: YPP RT README
---

# YAMBO YPP Real-Time Documentation Suite {#ypp_rt_main}

## Overview

This documentation suite provides comprehensive coverage of **YPP** (Yambo Post-Processor) capabilities for analyzing real-time TDDFT simulations performed with `yambo_rt`.

YPP is the essential tool for extracting physical observables from RT simulations, including:
- **Optical response**: Linear and nonlinear susceptibilities, absorption spectra
- **Carrier dynamics**: Occupations, lifetimes, thermalization
- **Transient spectroscopy**: Time-resolved absorption, Kerr effect
- **Green's functions**: Two-time correlations, spectral functions
- **Database manipulation**: Manual carrier excitation for initial conditions

---

## Documentation Files

This suite includes the following documents:

- @subpage ypp_rt_doc "Main YPP RT Documentation"
- @subpage ypp_rt_quick "YPP RT Quick Reference"
- @subpage ypp_rt_flowcharts "YPP RT Flowcharts"

---

### 1. @ref ypp_rt_doc "YPP_RT_DOCUMENTATION.md" (~15,000 lines)

**Complete reference manual** covering all YPP RT capabilities.

**Contents**:
- Overview and capabilities summary
- Detailed analysis types:
  - Occupations and carrier dynamics
  - Response functions and optical properties
  - Nonlinear optics (SHG, THG, HHG)
  - Transient absorption spectroscopy
  - Green's functions analysis
  - Database manipulation
  - Field analysis
- Practical examples with complete workflows
- Input variables reference
- Code structure reference
- Tips and troubleshooting

**Use this for**: In-depth understanding, complete variable reference, advanced usage

---

### 2. **YAMBO_YPP_RT_QUICK_GUIDE.md** (~3,000 lines)

**Quick reference guide** for common tasks.

**Contents**:
- Quick start for common analyses
- YPP modes summary table
- Key input variables
- Analysis types overview
- Complete workflow examples
- Input file templates
- Command quick reference
- Troubleshooting tips

**Use this for**: Quick lookup, common tasks, getting started

---

### 3. **YAMBO_YPP_RT_FLOWCHARTS.md** (~4,000 lines)

**Visual guide** with flowcharts and diagrams.

**Contents**:
- Overall YPP RT workflow
- Analysis type decision tree
- Detailed flowcharts for:
  - Linear response
  - Nonlinear optics
  - Transient absorption
  - Carrier dynamics
  - Database manipulation
- Data flow diagrams
- Database structure

**Use this for**: Understanding workflows, visual learning, planning analyses

---

## Quick Navigation

### By Task

| **I want to...** | **Document** | **Section** |
|------------------|--------------|-------------|
| Compute absorption spectrum | Quick Guide | Linear Absorption |
| Extract carrier temperature | Documentation | Occupations → Energy-Resolved |
| Analyze SHG/THG | Documentation | Nonlinear Optics |
| Do pump-probe spectroscopy | Documentation | Transient Absorption |
| Track carrier relaxation | Quick Guide | Carrier Dynamics |
| Create initial excitation | Documentation | Database Manipulation |
| Understand the workflow | Flowcharts | Overall Workflow |
| Find input variables | Documentation | Input Variables Reference |
| Troubleshoot issues | Quick Guide | Troubleshooting |

### By Analysis Type

| **Analysis** | **Command** | **Quick Start** | **Full Details** |
|--------------|-------------|-----------------|------------------|
| Linear response | `ypp -y` | Quick Guide p.1 | Documentation §4 |
| Carrier dynamics | `ypp -y` | Quick Guide p.2 | Documentation §3 |
| Nonlinear optics | `ypp -n` | Quick Guide p.3 | Documentation §5 |
| Transient absorption | `ypp -t` | Quick Guide p.4 | Documentation §6 |
| Manual excitation | `ypp -r e/f` | Quick Guide p.5 | Documentation §8 |

---

## Getting Started

### 1. **First Time Users**

**Recommended path**:
1. Read **Quick Guide** → "Quick Start" section
2. Try a simple example (linear absorption)
3. Consult **Flowcharts** → "Overall Workflow"
4. Refer to **Documentation** for details as needed

**Example workflow**:
```bash
# 1. Run RT simulation
yambo_rt -F rt_delta.in

# 2. Post-process with YPP
ypp -y -F ypp_abs.in

# 3. Plot results
gnuplot -e "plot 'YPP-alpha_along_E' u 1:2 w l"
```

### 2. **Specific Task**

**Recommended path**:
1. Check **Quick Guide** → "Common Tasks"
2. Copy relevant input template
3. Consult **Documentation** for variable details
4. Check **Flowcharts** if workflow unclear

### 3. **Advanced Users**

**Recommended path**:
1. **Documentation** → Specific analysis section
2. **Flowcharts** → Detailed workflow
3. **Documentation** → Code structure reference

---

## Key Concepts

### YPP Modes

YPP has different runlevels for different analyses:

```bash
ypp -y    # General RT post-processing
ypp -n    # Nonlinear optics
ypp -t    # Transient absorption
ypp -r e  # Database manipulation (energy-based)
ypp -r f  # Database manipulation (Fermi function)
```

### Input Structure

All YPP RT inputs follow this pattern:

```
[Mode keyword]          # RealTime, NonLinear, TransAbs, RTDBs
[Analysis type]         # RTX, RToccupations, etc.
[Time configuration]    # TimeRange, DampMode, etc.
[Energy configuration]  # EnRngeRt, ETStpsRt
[State selection]       # QPkrange, BANDS_path
[Specific options]      # Analysis-dependent
```

### Output Files

YPP creates files with prefix `YPP-`:

```
YPP-eps_*           # Dielectric function
YPP-alpha_*         # Absorption
YPP-occ_*           # Occupations
YPP-carriers_*      # Carrier data
YPP-X_*_order_*     # Nonlinear susceptibilities
YPP-Kerr_*          # Kerr effect
```

---

## Common Workflows

### Workflow 1: Linear Absorption

```
RT Simulation (delta pulse)
    ↓
YPP Linear Response (ypp -y, RTX)
    ↓
Output: ε(ω), α(ω)
```

**See**: Quick Guide p.1, Documentation §4.1

### Workflow 2: Carrier Thermalization

```
RT Simulation (pump + scattering)
    ↓
YPP Carrier Analysis (ypp -y, RToccupations, RTenergy)
    ↓
Output: f(E,t), T(t), μ(t)
```

**See**: Quick Guide p.2, Documentation §3.2

### Workflow 3: Second Harmonic Generation

```
RT Simulations (multiple frequencies)
    ↓
YPP Nonlinear Analysis (ypp -n, Xorder=2)
    ↓
Output: χ^(1)(ω), χ^(2)(2ω)
```

**See**: Quick Guide p.3, Documentation §5

### Workflow 4: Pump-Probe Spectroscopy

```
RT Simulation (pump pulse)
    ↓
YPP Transient Absorption (ypp -t, TransAbs)
    ↓
Output: ε(ω,t), α(ω,t)
```

**See**: Quick Guide p.4, Documentation §6

### Workflow 5: Custom Initial State

```
YPP Database Creation (ypp -r e/f)
    ↓
RT Simulation (starts from custom state)
    ↓
YPP Analysis
```

**See**: Quick Guide p.5, Documentation §8

---

## Input Variable Quick Reference

### Essential Variables

```fortran
! Time configuration
TimeRange= t_start | t_end | fs
DampMode= "LORENTZIAN"
DampFactor= Γ | eV

! Energy configuration
% EnRngeRt
 E_min | E_max | eV
%
ETStpsRt= N

! State selection
%QPkrange
 ib_min | ib_max | ik_min | ik_max |
%
```

### Analysis-Specific

**Linear response**:
```fortran
RealTime
RTX
Xorder= 1
```

**Carrier dynamics**:
```fortran
RealTime
RToccupations
RTtime          # Time series
RTenergy        # Energy-resolved
RTdos           # DOS evolution
RTbands         # Band structure
```

**Nonlinear optics**:
```fortran
NonLinear
Xorder= N
% Probe_Freq
 ω_min | ω_max | dω | eV
%
```

**Transient absorption**:
```fortran
TransAbs
TRabsWHAT= "abs"
TRabsMODE= "cv+cc+vv"
% TRabsEnRange
 E_min | E_max | eV
%
```

**Database manipulation**:
```fortran
RTDBs
RTpumpNel= Nel
% RTpumpEhEn
 E_h | E_e | eV
%
```

---

## Troubleshooting

### Common Issues

| **Problem** | **Solution** | **Reference** |
|-------------|--------------|---------------|
| Noisy spectra | Increase DampFactor, longer TimeRange | Quick Guide §Tips |
| Missing features | Check EnRngeRt, increase ETStpsRt | Documentation §11 |
| Slow processing | Reduce ETStpsRt, use UseFFT | Quick Guide §Tips |
| Wrong results | Verify RT convergence, check gauge | Documentation §11 |

### Getting Help

1. **Check documentation**: Search for error message or issue
2. **YAMBO forum**: https://www.yambo-code.eu/forum/
3. **YAMBO wiki**: https://www.yambo-code.eu/wiki/
4. **Mailing list**: yambo-users@yambo-code.eu

---

## Examples Directory Structure

The documentation includes complete examples:

```
Examples/
├── linear_absorption/
│   ├── rt_delta.in
│   ├── ypp_abs.in
│   └── plot.gp
│
├── shg/
│   ├── run_multiple_freq.sh
│   ├── ypp_shg.in
│   └── plot_chi2.py
│
├── pump_probe/
│   ├── rt_pump.in
│   ├── ypp_trabs.in
│   └── plot_2d.py
│
├── carrier_dynamics/
│   ├── rt_therm.in
│   ├── ypp_carriers.in
│   └── plot_temp.py
│
└── manual_pump/
    ├── ypp_inject.in
    ├── rt_from_db.in
    └── README
```

**See**: Documentation §10 for complete examples

---

## Code Structure

### Main YPP RT Files

```
ypp/
├── real_time/
│   ├── RT_ypp_driver.F              # Main RT driver
│   ├── NL_ypp_driver.F              # Nonlinear driver
│   ├── RT_occupations_driver.F      # Occupations driver
│   ├── RT_TRabs_driver.F            # Transient abs driver
│   ├── RT_G_two_times_driver.F      # Green's function driver
│   │
│   ├── RT_occ_time_plot.F           # f(t) analysis
│   ├── RT_components_energy_plot.F  # f(E) and Fermi fitting
│   ├── RT_dos_time_plot.F           # DOS(E,t)
│   ├── RT_occ_bands_interpolation.F # Band structure
│   │
│   ├── RT_X_response.F              # Linear response
│   ├── RT_Polarization.F            # Polarization analysis
│   ├── RT_X_effective.F             # Effective susceptibility
│   │
│   ├── RT_transient_absorption.F    # Transient spectra
│   ├── RT_G_two_times_build.F       # G^<(t,t')
│   │
│   ├── RT_DBs_carriers_setup.F      # DB manipulation
│   ├── RT_manual_excitation.F       # Energy-based pump
│   ├── RT_Fermi_excitation.F        # Fermi function pump
│   │
│   └── RT_fields.F                  # Field analysis
│
└── YPPmodules/
    └── mod_YPP_real_time.F          # RT variables and types
```

**See**: Documentation §11 for complete code reference

---

## Version Information

- **Documentation Version**: 1.0
- **YAMBO Version**: 5.x
- **Last Updated**: 2025
- **Authors**: Generated from YAMBO source code analysis

---

## Related Documentation

### YAMBO Main Documentation
- **Main manual**: https://www.yambo-code.eu/wiki/
- **RT tutorial**: https://www.yambo-code.eu/wiki/index.php/Real_time_approach_to_linear_response
- **NL tutorial**: https://www.yambo-code.eu/wiki/index.php/Nonlinear_optics

### Theory Documentation
For theoretical background on RT-TDDFT in YAMBO, see:
- `YAMBO_RT_THEORY_DOCUMENTATION.md` (if available)
- Sangalli et al., J. Chem. Phys. 134, 034115 (2011)
- Attaccalite et al., Phys. Rev. B 88, 235113 (2013)

### Other YPP Capabilities
YPP can also post-process:
- Band structures and DOS
- Exciton analysis
- QP corrections
- Wannier functions
- Electron-phonon coupling

See main YAMBO documentation for these features.

---

## Document Statistics

| **Document** | **Lines** | **Size** | **Focus** |
|--------------|-----------|----------|-----------|
| DOCUMENTATION | ~15,000 | ~500 KB | Complete reference |
| QUICK_GUIDE | ~3,000 | ~100 KB | Quick lookup |
| FLOWCHARTS | ~4,000 | ~150 KB | Visual workflows |
| **TOTAL** | **~22,000** | **~750 KB** | **Full coverage** |

---

## Feedback and Contributions

This documentation is generated from YAMBO source code analysis. For:
- **Corrections**: Report to YAMBO developers
- **Additions**: Suggest on YAMBO forum
- **Questions**: Ask on yambo-users mailing list

---

## Quick Start Checklist

- [ ] Read Quick Guide introduction
- [ ] Understand YPP modes (`ypp -y/n/t/r`)
- [ ] Try linear absorption example
- [ ] Explore flowcharts for your analysis type
- [ ] Consult full documentation for details
- [ ] Check troubleshooting if issues arise
- [ ] Visit YAMBO forum for community support

---

**Happy post-processing!**

For the latest YAMBO updates and news, visit: https://www.yambo-code.eu