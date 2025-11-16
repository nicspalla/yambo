# YAMBO YPP Real-Time Quick Reference Guide {#ypp_rt_quick}

@page ypp_rt_quick YPP Real-Time Quick Reference

@tableofcontents

## What is YPP?

**YPP** (Yambo Post-Processor) analyzes output from `yambo_rt` real-time simulations. It extracts physical observables without re-running expensive calculations.

---

## Quick Start: Common Tasks

### 1. Linear Absorption Spectrum

**After RT simulation with delta pulse:**

```bash
# ypp_abs.in
RealTime
RTX
Xorder= 1
TimeRange= 5 | 100 | fs
DampMode= "LORENTZIAN"
DampFactor= 0.05 | eV
% EnRngeRt
 0.0 | 10.0 | eV
%
ETStpsRt= 1000
```

```bash
ypp -y -F ypp_abs.in
```

**Output**: `YPP-eps_along_E`, `YPP-alpha_along_E`

---

### 2. Carrier Dynamics

**Track occupation evolution:**

```bash
# ypp_occ.in
RealTime
RToccupations
RTtime
RTenergy
%QPkrange
  1 | 50 | 1 | 50 |
%
```

```bash
ypp -y -F ypp_occ.in
```

**Outputs**: 
- `YPP-occ_*.dat`: Occupation vs time
- `YPP-carriers_E.dat`: Occupation vs energy
- `YPP-Ef_and_T.dat`: Fitted temperature and chemical potential

---

### 3. Second Harmonic Generation (SHG)

**After RT simulations at multiple frequencies:**

```bash
# ypp_shg.in
NonLinear
Xorder= 2
% Probe_Freq
 1.0 | 3.0 | 0.2 | eV
%
TimeRange= 100 | 200 | fs
```

```bash
ypp -n -F ypp_shg.in
```

**Outputs**: 
- `YPP-X_probe_order_1`: χ^(1)(ω)
- `YPP-X_probe_order_2`: χ^(2)(2ω)

---

### 4. Pump-Probe Transient Absorption

**After RT simulation with pump:**

```bash
# ypp_trabs.in
TransAbs
TRabsWHAT= "abs"
TRabsMODE= "cv+cc+vv"
% TRabsEnRange
 0.0 | 8.0 | eV
%
TRabsEnSteps= 800
TRabsDamp= 0.1 | eV
```

```bash
ypp -t -F ypp_trabs.in
```

**Outputs**: `YPP-eps_along_E_T*.dat` (ε(ω) at each time)

---

### 5. Manual Carrier Injection

**Create initial carrier distribution:**

```bash
# ypp_pump.in
RTDBs
RTpumpNel= 0.05
% RTpumpEhEn
 -0.3 | 0.3 | eV
%
RTpumpEhWd= 0.15 | eV
RTpumpDE= 2.5 | eV
```

```bash
ypp -r e -F ypp_pump.in
```

**Output**: `ndb.RT_carriers` (use in subsequent RT simulation)

---

## YPP Modes Summary

| Mode | Command | Purpose | Key Outputs |
|------|---------|---------|-------------|
| **RT Post-Processing** | `ypp -y` | General RT analysis | Various |
| **Nonlinear Optics** | `ypp -n` | χ^(n) extraction | `YPP-X_*_order_*` |
| **Transient Abs** | `ypp -t` | Time-resolved spectra | `YPP-eps_*_T*` |
| **DB Manipulation** | `ypp -r e/f` | Manual excitation | `ndb.RT_carriers` |

---

## Key Input Variables

### Time Configuration

```fortran
TimeRange= t_start | t_end | fs    ! Time window
DampMode= "LORENTZIAN"              ! Damping type
DampFactor= Γ | eV                  ! Damping strength
```

### Energy Configuration

```fortran
% EnRngeRt
 E_min | E_max | eV
%
ETStpsRt= N                         ! Energy steps
```

### State Selection

```fortran
%QPkrange
 ib_min | ib_max | ik_min | ik_max |
%
BANDS_path= "G K M G"               ! High-symmetry path
```

---

## Analysis Types

### Occupations (`RToccupations`)

**Time evolution** (`RTtime`):
- Tracks f_n(k,t) for selected states
- Includes lifetimes if scattering present
- Output: `YPP-occ_K*_B*_S*.dat`

**Energy-resolved** (`RTenergy`):
- Plots f(E,t) with Fermi fitting
- Extracts effective T and μ
- Output: `YPP-carriers_E.dat`, `YPP-Ef_and_T.dat`

**DOS** (`RTdos`):
- Time-dependent DOS(E,t)
- Optional k-space interpolation
- Output: `YPP-TD_dos.dat`

**Band structure** (`RTbands`):
- Occupation along high-symmetry paths
- Animated band evolution
- Output: `YPP-occ_BANDS_*.dat`

### Response Functions (`RTX`)

**Linear response** (`Xorder=1`):
- From delta pulse: full χ(ω)
- From monochromatic: χ at specific ω
- Output: `YPP-eps_*`, `YPP-alpha_*`

**Polarization** (`RTpol`):
- Decompose P(t) by transitions
- Shows resonance structure
- Output: `YPP-TD_P_decomposition`

### Nonlinear Optics (`NonLinear`)

**Harmonic generation**:
- χ^(1): Linear (ω)
- χ^(2): SHG (2ω)
- χ^(3): THG (3ω)
- Output: `YPP-X_*_order_N`

**Frequency scan**:
```fortran
% Probe_Freq
 ω_min | ω_max | dω | eV
%
```

**Angular scan**:
```fortran
% Probe_Angles
 θ_min | θ_max | dθ |
%
```

### Transient Absorption (`TransAbs`)

**Observables**:
- `TRabsWHAT= "abs"`: Absorption α(ω,t)
- `TRabsWHAT= "kerr"`: Kerr angle θ_K(ω,t)

**Transitions**:
- `TRabsMODE= "cv"`: Equilibrium only
- `TRabsMODE= "cc+vv"`: Excited carriers
- `TRabsMODE= "cv+cc+vv"`: Full spectrum

**Dipole components**:
- `TRabsDIP_plane= "none"`: ε_xx only
- `TRabsDIP_plane= "xy"`: ε_xx, ε_xy, ε_yx, ε_yy
- `TRabsDIP_plane= "all"`: All 9 components

### Database Manipulation (`RTDBs`)

**Energy-based** (`ypp -r e`):
```fortran
RTpumpNel= Nel              ! Electrons per cell
% RTpumpEhEn
 E_h | E_e | eV             ! Energy window
%
RTpumpEhWd= σ | eV          ! Width
RTpumpDE= ΔE | eV           ! e-h separation
```

**Fermi function** (`ypp -r f`):
```fortran
RTpumpNel= Nel
% Eh_mu
 μ_h | μ_e | eV             ! Chemical potential
%
% Eh_temp
 T_h | T_e | K              ! Temperature
%
```

---

## Workflow Examples

### Complete Linear Response

```bash
# 1. RT simulation
cat > rt_delta.in << EOF
negf
RTBands= 1 | 50 |
RTstep= 0.01 | fs
NETime= 100 | fs
Field(1)= "DELTA"
Field_Freq(1)= 0.0 | eV
Field_Int(1)= 1.E-4 | kWLm2
EOF

yambo_rt -F rt_delta.in

# 2. YPP post-processing
cat > ypp_abs.in << EOF
RealTime
RTX
Xorder= 1
TimeRange= 5 | 100 | fs
DampMode= "LORENTZIAN"
DampFactor= 0.05 | eV
% EnRngeRt
 0.0 | 10.0 | eV
%
ETStpsRt= 1000
EOF

ypp -y -F ypp_abs.in

# 3. Plot
gnuplot -e "plot 'YPP-alpha_along_E' u 1:2 w l"
```

### Complete SHG Analysis

```bash
# 1. RT simulations at different frequencies
for omega in 1.0 1.5 2.0 2.5 3.0; do
  mkdir run_w${omega}
  cd run_w${omega}
  
  cat > rt_shg.in << EOF
negf
RTBands= 1 | 50 |
RTstep= 0.05 | fs
NETime= 200 | fs
Field(1)= "SIN"
Field_Freq(1)= ${omega} | eV
Field_Int(1)= 1.E6 | kWLm2
EOF
  
  yambo_rt -F rt_shg.in
  cd ..
done

# 2. YPP analysis
cat > ypp_shg.in << EOF
NonLinear
Xorder= 2
% Probe_Freq
 1.0 | 3.0 | 0.5 | eV
%
TimeRange= 100 | 200 | fs
EOF

ypp -n -F ypp_shg.in

# 3. Plot χ^(2)
gnuplot -e "plot 'YPP-X_probe_order_2' u 1:2 w l"
```

### Complete Pump-Probe

```bash
# 1. RT simulation
cat > rt_pump.in << EOF
negf
RTBands= 1 | 50 |
RTstep= 0.05 | fs
NETime= 500 | fs
Field(1)= "PULSE"
Field_Freq(1)= 3.0 | eV
Field_Int(1)= 1.E8 | kWLm2
Field_FWHM(1)= 10 | fs
LifeInterpKIND= "FLAT"
LifeInterpSteps= 10 | fs
EOF

yambo_rt -F rt_pump.in

# 2. YPP transient absorption
cat > ypp_trabs.in << EOF
TransAbs
TRabsWHAT= "abs"
TRabsMODE= "cv+cc+vv"
% TRabsEnRange
 0.0 | 8.0 | eV
%
TRabsEnSteps= 800
TRabsDamp= 0.1 | eV
EOF

ypp -t -F ypp_trabs.in

# 3. Plot 2D map (Python)
python << EOF
import numpy as np
import matplotlib.pyplot as plt

times = []
alphas = []
for t in range(0, 500, 10):
    data = np.loadtxt(f'YPP-alpha_along_E_T{t}.dat')
    times.append(t)
    alphas.append(data[:,1])

plt.contourf(data[:,0], times, alphas)
plt.xlabel('Energy (eV)')
plt.ylabel('Time (fs)')
plt.savefig('transient_abs.png')
EOF
```

---

## Tips and Troubleshooting

### Time Range Selection

**For Fourier transforms**:
- Skip initial transient: `TimeRange= 10 | 100 | fs`
- Use steady-state for monochromatic fields
- Longer time → better frequency resolution

**For occupations**:
- Include full dynamics: `TimeRange= 0 | T_max | fs`

### Damping

**LORENTZIAN** (recommended):
- Physical broadening
- Use `DampFactor ~ Γ_scatt`

**GAUSSIAN**:
- Smoother spectra
- Better for noisy data

### Common Issues

**Noisy spectra**:
- Increase `DampFactor`
- Use longer `TimeRange`
- Check RT simulation convergence

**Missing features**:
- Check `EnRngeRt` covers relevant energies
- Increase `ETStpsRt`
- Verify RT simulation included all bands

**Slow post-processing**:
- Reduce `ETStpsRt`
- Use `UseFFT`
- Select fewer states with `QPkrange`

---

## Output Files Quick Reference

| File Pattern | Content | Analysis |
|--------------|---------|----------|
| `YPP-occ_K*_B*_S*.dat` | f_n(k,t) | Occupation vs time |
| `YPP-carriers_E.dat` | f(E,t) | Occupation vs energy |
| `YPP-Ef_and_T.dat` | T(t), μ(t) | Fitted parameters |
| `YPP-TD_dos.dat` | DOS(E,t) | Time-dependent DOS |
| `YPP-eps_along_E` | ε(ω) | Dielectric function |
| `YPP-alpha_along_E` | α(ω) | Absorption |
| `YPP-X_probe_order_N` | χ^(N)(ω) | N-th order susceptibility |
| `YPP-eps_*_T*.dat` | ε(ω,t) | Transient dielectric |
| `YPP-Kerr_*` | θ_K(ω,t) | Kerr angle |
| `YPP-TD_P_decomposition` | P(ω) by transition | Polarization analysis |
| `ndb.RT_carriers` | f_n(k,t=0) | Initial carrier distribution |

---

## Command Quick Reference

```bash
# Linear absorption
ypp -y -F ypp_abs.in

# Carrier dynamics
ypp -y -F ypp_occ.in

# Nonlinear optics
ypp -n -F ypp_nl.in

# Transient absorption
ypp -t -F ypp_trabs.in

# Manual excitation (energy-based)
ypp -r e -F ypp_pump.in

# Manual excitation (Fermi function)
ypp -r f -F ypp_pump.in

# Generate input template
ypp -y -H

# Check version
ypp -v
```

---

## Input File Templates

### Minimal Linear Response

```
RealTime
RTX
Xorder= 1
TimeRange= 5 | 100 | fs
% EnRngeRt
 0.0 | 10.0 | eV
%
```

### Minimal Carrier Dynamics

```
RealTime
RToccupations
RTtime
RTenergy
%QPkrange
  1 | 50 | 1 | 50 |
%
```

### Minimal SHG

```
NonLinear
Xorder= 2
% Probe_Freq
 1.0 | 3.0 | 0.2 | eV
%
TimeRange= 100 | 200 | fs
```

### Minimal Transient Absorption

```
TransAbs
TRabsWHAT= "abs"
% TRabsEnRange
 0.0 | 8.0 | eV
%
TRabsEnSteps= 800
```

### Minimal Manual Pump

```
RTDBs
RTpumpNel= 0.05
% RTpumpEhEn
 -0.3 | 0.3 | eV
%
```

---

## Further Reading

- **Full Documentation**: `YAMBO_YPP_RT_DOCUMENTATION.md`
- **YAMBO Manual**: https://www.yambo-code.eu/wiki/
- **RT Tutorial**: https://www.yambo-code.eu/wiki/index.php/Real_time_approach_to_linear_response
- **Forum**: https://www.yambo-code.eu/forum/

---

**Quick Guide Version**: 1.0  
**For YAMBO**: 5.x  
**Last Updated**: 2025