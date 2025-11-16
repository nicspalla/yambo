# YAMBO YPP Real-Time Flowcharts and Visual Guide {#ypp_rt_flowcharts}

@page ypp_rt_flowcharts YPP Real-Time Flowcharts

@tableofcontents

## Table of Contents

1. [Overall YPP RT Workflow](#overall-ypp-rt-workflow)
2. [Analysis Type Decision Tree](#analysis-type-decision-tree)
3. [Linear Response Workflow](#linear-response-workflow)
4. [Nonlinear Optics Workflow](#nonlinear-optics-workflow)
5. [Transient Absorption Workflow](#transient-absorption-workflow)
6. [Carrier Dynamics Workflow](#carrier-dynamics-workflow)
7. [Database Manipulation Workflow](#database-manipulation-workflow)
8. [Data Flow Diagrams](#data-flow-diagrams)

---

## Overall YPP RT Workflow

```
┌─────────────────────────────────────────────────────────────────┐
│                    YAMBO RT Simulation                          │
│                                                                 │
│  yambo_rt -F input.in                                          │
│                                                                 │
│  Outputs:                                                       │
│  ├── ndb.RT_carriers        (carrier occupations)             │
│  ├── ndb.RT_G_lesser_*      (Green's functions)               │
│  ├── ndb.Nonlinear          (polarization/current)            │
│  └── o.observables          (time-dependent observables)      │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    YPP Post-Processing                          │
│                                                                 │
│  Choose analysis type:                                          │
│  ├── ypp -y  (General RT)                                      │
│  ├── ypp -n  (Nonlinear)                                       │
│  ├── ypp -t  (Transient Abs)                                   │
│  └── ypp -r  (DB Manipulation)                                 │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Analysis Outputs                             │
│                                                                 │
│  ├── YPP-eps_*, YPP-alpha_*     (Optical properties)          │
│  ├── YPP-occ_*, YPP-carriers_*  (Carrier dynamics)            │
│  ├── YPP-X_*_order_*            (Nonlinear susceptibilities)  │
│  ├── YPP-Kerr_*                 (Magneto-optical)             │
│  └── ndb.RT_carriers            (Modified databases)          │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Visualization                                │
│                                                                 │
│  ├── gnuplot / xmgrace                                         │
│  ├── Python (matplotlib, numpy)                                │
│  └── Custom analysis scripts                                   │
└─────────────────────────────────────────────────────────────────┘
```

---

## Analysis Type Decision Tree

```
                    What do you want to analyze?
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
        ▼                     ▼                     ▼
   Optical              Carrier              Database
   Properties           Dynamics             Manipulation
        │                     │                     │
        │                     │                     │
        ▼                     ▼                     ▼
┌───────────────┐    ┌───────────────┐    ┌───────────────┐
│ Linear?       │    │ Time series?  │    │ Create        │
│               │    │               │    │ excitation?   │
│ YES → ypp -y  │    │ YES → RTtime  │    │               │
│   RTX         │    │               │    │ YES → ypp -r  │
│   Xorder=1    │    │ NO ↓          │    │               │
│               │    │               │    │ Energy-based  │
│ NO ↓          │    │ Energy-res?   │    │ → ypp -r e    │
│               │    │               │    │               │
│ Nonlinear?    │    │ YES → RTenergy│    │ Fermi func   │
│               │    │               │    │ → ypp -r f    │
│ YES → ypp -n  │    │ NO ↓          │    │               │
│   Xorder=N    │    │               │    └───────────────┘
│               │    │ DOS(E,t)?     │
│ NO ↓          │    │               │
│               │    │ YES → RTdos   │
│ Time-resolved?│    │               │
│               │    │ NO ↓          │
│ YES → ypp -t  │    │               │
│   TransAbs    │    │ Band struct?  │
│               │    │               │
└───────────────┘    │ YES → RTbands │
                     │               │
                     └───────────────┘
```

---

## Linear Response Workflow

```
┌─────────────────────────────────────────────────────────────────┐
│                RT Simulation with Delta Pulse                   │
│                                                                 │
│  Field(1)= "DELTA"                                             │
│  Field_Freq(1)= 0.0 | eV                                       │
│  Field_Int(1)= 1.E-4 | kWLm2                                   │
│  NETime= 100 | fs                                              │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    YPP Reads Databases                          │
│                                                                 │
│  ├── ndb.Nonlinear  → P(t), J(t)                              │
│  └── o.observables  → Time grid                                │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Time Window Selection                        │
│                                                                 │
│  TimeRange= t_start | t_end | fs                               │
│                                                                 │
│  ├── Skip initial transient (t_start > 0)                      │
│  └── Use clean signal region                                   │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Apply Damping                                │
│                                                                 │
│  DampMode= "LORENTZIAN" or "GAUSSIAN"                          │
│  DampFactor= Γ | eV                                            │
│                                                                 │
│  P_damped(t) = P(t) × exp(-Γt)  [Lorentzian]                  │
│  P_damped(t) = P(t) × exp(-Γ²t²) [Gaussian]                   │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Fourier Transform                            │
│                                                                 │
│  P(ω) = ∫ P(t) e^(iωt) dt                                     │
│  J(ω) = ∫ J(t) e^(iωt) dt                                     │
│                                                                 │
│  Energy range: EnRngeRt                                         │
│  Energy steps: ETStpsRt                                         │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Compute Susceptibility                       │
│                                                                 │
│  χ(ω) = P(ω) / E(ω)                                           │
│                                                                 │
│  where E(ω) = FT of external field                             │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Compute Optical Properties                   │
│                                                                 │
│  ε(ω) = 1 + 4π χ(ω)        [Dielectric function]              │
│  α(ω) = (ω/c) Im[ε(ω)]     [Absorption]                       │
│  n(ω) = Re[√ε(ω)]          [Refractive index]                 │
│  R(ω) = |(√ε-1)/(√ε+1)|²   [Reflectivity]                     │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Write Output Files                           │
│                                                                 │
│  ├── YPP-eps_along_E        [ε(ω)]                            │
│  ├── YPP-alpha_along_E      [α(ω)]                            │
│  ├── YPP-n_along_E          [n(ω)]                            │
│  └── YPP-R_along_E          [R(ω)]                            │
└─────────────────────────────────────────────────────────────────┘
```

---

## Nonlinear Optics Workflow

```
┌─────────────────────────────────────────────────────────────────┐
│            RT Simulations at Multiple Frequencies               │
│                                                                 │
│  For ω = ω₁, ω₂, ..., ωₙ:                                     │
│    Field(1)= "SIN"                                             │
│    Field_Freq(1)= ω | eV                                       │
│    Field_Int(1)= I | kWLm2                                     │
│    NETime= T | fs  (long enough for steady state)             │
│                                                                 │
│  Each run creates: ndb.Nonlinear in separate directory         │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    YPP Reads All Databases                      │
│                                                                 │
│  For each frequency ω_i:                                        │
│    ├── Read P(t) from ndb.Nonlinear                           │
│    ├── Check field consistency                                 │
│    └── Store in RT_P_probe(:,i_f,:)                           │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Select Steady-State Region                   │
│                                                                 │
│  TimeRange= t_ss | t_end | fs                                  │
│                                                                 │
│  where t_ss > several periods (T = 2π/ω)                       │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Fourier Coefficient Inversion                │
│                                                                 │
│  For each frequency ω_i:                                        │
│                                                                 │
│    P(t) = Σ_{n=0}^{N} P_n cos(nωt + φ_n)                      │
│                                                                 │
│    Fit to extract {P_n, φ_n} for n = 0, 1, 2, ..., Xorder     │
│                                                                 │
│    Method: RT_coefficients_Inversion                            │
│      ├── Construct design matrix                               │
│      ├── Least-squares fit                                     │
│      └── Extract harmonic amplitudes                           │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Compute Susceptibilities                     │
│                                                                 │
│  For each order n:                                              │
│                                                                 │
│    χ^(n)(nω) = P_n / E₀^n                                      │
│                                                                 │
│  where E₀ is field amplitude                                    │
│                                                                 │
│  Harmonic frequencies:                                          │
│    ω₀ = 0      (DC)                                            │
│    ω₁ = ω      (Linear)                                        │
│    ω₂ = 2ω     (SHG)                                           │
│    ω₃ = 3ω     (THG)                                           │
│    ...                                                          │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Write Output Files                           │
│                                                                 │
│  For each order n = 0, 1, 2, ..., Xorder:                     │
│                                                                 │
│    YPP-X_probe_order_n                                         │
│      ├── Column 1: Frequency (eV)                              │
│      ├── Column 2-3: Im/Re χ^(n)_x                            │
│      ├── Column 4-5: Im/Re χ^(n)_y                            │
│      └── Column 6-7: Im/Re χ^(n)_z                            │
│                                                                 │
│  Units:                                                         │
│    χ^(1): Dimensionless                                        │
│    χ^(n) (n≥2): [cm/statV]^(n-1)                              │
└─────────────────────────────────────────────────────────────────┘
```

### Pump-Probe Extension

```
┌─────────────────────────────────────────────────────────────────┐
│                    Two RT Simulations                           │
│                                                                 │
│  Run 1: Pump + Probe                                           │
│    ├── Field(1)= Pump                                          │
│    ├── Field(2)= Probe                                         │
│    └── Output: ndb.Nonlinear (full)                           │
│                                                                 │
│  Run 2: Pump only (reference)                                  │
│    ├── Field(1)= Pump                                          │
│    └── Output: ndb.Nonlinear (pump)                           │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    YPP Subtraction                              │
│                                                                 │
│  P_probe(t) = P_full(t) - P_pump(t)                           │
│                                                                 │
│  Input:                                                         │
│    Pump_path= "pump_only"                                      │
│    Probe_path= "pump_probe"                                    │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Analyze Isolated Probe                       │
│                                                                 │
│  χ_probe(ω) = P_probe(ω) / E_probe(ω)                         │
│                                                                 │
│  Shows pump-induced changes in probe response                   │
└─────────────────────────────────────────────────────────────────┘
```

---

## Transient Absorption Workflow

```
┌─────────────────────────────────────────────────────────────────┐
│                RT Simulation with Pump Pulse                    │
│                                                                 │
│  Field(1)= "PULSE"                                             │
│  Field_Freq(1)= ω_pump | eV                                    │
│  Field_Int(1)= I_pump | kWLm2                                  │
│  Field_FWHM(1)= τ_pump | fs                                    │
│  NETime= T_max | fs                                            │
│                                                                 │
│  Include scattering:                                            │
│    LifeInterpKIND= "FLAT"                                      │
│    LifeInterpSteps= Δt | fs                                    │
│                                                                 │
│  Outputs:                                                       │
│    ├── ndb.RT_carriers  (f_n(k,t))                            │
│    └── ndb.dipoles      (transition dipoles)                   │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    YPP Setup                                    │
│                                                                 │
│  ├── Read carrier occupations f_n(k,t)                         │
│  ├── Read dipole matrix elements d_nm(k)                       │
│  ├── Setup time grid (RT_time_configuration_setup)             │
│  └── Setup frequency grid (W_bss)                              │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Loop Over Time Steps                         │
│                                                                 │
│  For each time t:                                               │
│    ├── Load f_n(k,t) from database                             │
│    └── Proceed to transition analysis ↓                        │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Identify Transitions                         │
│                                                                 │
│  Three types based on TRabsMODE:                               │
│                                                                 │
│  1. cv transitions (equilibrium):                              │
│     ├── Valence → Conduction                                   │
│     ├── Weight: f_v(k) [1 - f_c(k)]                           │
│     └── Energy: E_c(k) - E_v(k)                                │
│                                                                 │
│  2. cc transitions (excited electrons):                         │
│     ├── Conduction → Conduction                                │
│     ├── Weight: Δf_c(k) = f_c(k,t) - f_c(k,0)                 │
│     └── Energy: E_c'(k) - E_c(k)                               │
│                                                                 │
│  3. vv transitions (holes):                                     │
│     ├── Valence → Valence                                      │
│     ├── Weight: Δf_v(k) = f_v(k,0) - f_v(k,t)                 │
│     └── Energy: E_v'(k) - E_v(k)                               │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Compute Residuals                            │
│                                                                 │
│  For each transition (n→m, k):                                  │
│                                                                 │
│    R_left(trans) = √[weight(trans)] × d_nm(k)                  │
│    R_right(trans) = √[weight(trans)] × d*_nm(k)                │
│                                                                 │
│  where d_nm(k) are dipole matrix elements                       │
│                                                                 │
│  Routine: RT_TRabs_residuals                                    │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Build Dielectric Tensor                      │
│                                                                 │
│  For each component ε_ij(ω,t):                                 │
│                                                                 │
│    ε_ij(ω,t) = δ_ij + 4π Σ_trans [                            │
│                  R_i(trans,t) R*_j(trans,t)                    │
│                  ────────────────────────────                   │
│                  ω - E_trans(t) + iΓ                           │
│                ]                                                │
│                                                                 │
│  Sum over all transitions (cv + cc + vv)                        │
│                                                                 │
│  Routine: build_up_eps_ij                                       │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Compute Observables                          │
│                                                                 │
│  Absorption:                                                    │
│    α_i(ω,t) = (ω/c) Im[ε_ii(ω,t)]                             │
│                                                                 │
│  Kerr angle (if off-diagonal):                                 │
│    θ_K + iη_K = -ε_xy / [ε_xx √ε_xx]                          │
│                                                                 │
│  Reflectivity:                                                  │
│    R(ω,t) = |(√ε - 1)/(√ε + 1)|²                              │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Write Output Files                           │
│                                                                 │
│  For each time step t:                                          │
│                                                                 │
│    ├── YPP-eps_along_E_T{t}.dat     [ε(ω) at time t]          │
│    ├── YPP-alpha_along_E_T{t}.dat   [α(ω) at time t]          │
│    ├── YPP-Kerr_T{t}.dat            [θ_K(ω) at time t]        │
│    └── YPP-R_T{t}.dat               [R(ω) at time t]          │
│                                                                 │
│  Creates 2D map: Observable(ω, t)                              │
└─────────────────────────────────────────────────────────────────┘
```

### BSE Extension

```
┌─────────────────────────────────────────────────────────────────┐
│                    BSE Transient Absorption                     │
│                                                                 │
│  Use BSE eigenstates instead of single-particle transitions     │
│                                                                 │
│  Exciton basis:                                                 │
│    |λ⟩ = Σ_{cvk} A^λ_{cvk} |cvk⟩                              │
│                                                                 │
│  Transitions:                                                   │
│    ├── Exciton → Exciton (inter-exc)                          │
│    └── Ground → Exciton (cv with BSE)                         │
│                                                                 │
│  Input:                                                         │
│    TRabsMODE= "inter-exc"                                      │
│    % TRabsExc                                                  │
│     1 | N_exc |                                                │
│    %                                                            │
└─────────────────────────────────────────────────────────────────┘
```

---

## Carrier Dynamics Workflow

```
┌─────────────────────────────────────────────────────────────────┐
│                RT Simulation with Excitation                    │
│                                                                 │
│  Creates non-equilibrium carrier distribution                   │
│                                                                 │
│  Outputs:                                                       │
│    └── ndb.RT_carriers                                         │
│         ├── f_n(k,t) for all times                             │
│         ├── Lifetimes (if scattering)                          │
│         └── Time grid                                           │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    YPP Reads Carrier Data                       │
│                                                                 │
│  RT_apply(RT_bands, en, k, TIME=t)                             │
│    ├── Loads f_n(k,t) at time t                                │
│    ├── Loads lifetimes τ_n(k,t)                                │
│    └── Interpolates if needed                                  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
                    Choose Analysis Type
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
        ▼                     ▼                     ▼
   Time Series          Energy-Resolved         DOS Evolution
        │                     │                     │
        │                     │                     │
        ▼                     ▼                     ▼
```

### Time Series Branch

```
┌─────────────────────────────────────────────────────────────────┐
│                    Time Series Analysis                         │
│                    (RT_occ_time_plot.F)                         │
│                                                                 │
│  For each selected state (n, k, spin):                          │
│                                                                 │
│    Loop over time steps:                                        │
│      ├── Load f_n(k,t)                                         │
│      ├── Compute Δf = f_n(k,t) - f_n(k,0)                     │
│      ├── Extract lifetimes τ_n(k,t)                            │
│      └── Store data                                             │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    State Selection                              │
│                                                                 │
│  Methods:                                                       │
│    1. QPkrange: Explicit band/k-point range                    │
│    2. BANDS_path: High-symmetry path                           │
│    3. Energy window: CarrEnRnge                                │
│                                                                 │
│  Options:                                                       │
│    ├── SeparateEH: Separate electrons/holes                    │
│    ├── IncludeEQocc: Add equilibrium f                         │
│    └── OCCgroup: Group similar states                          │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Write Output                                 │
│                                                                 │
│  For each state:                                                │
│    YPP-occ_K{ik}_B{ib}_S{is}.dat                               │
│      ├── Column 1: Time (fs)                                   │
│      ├── Column 2: Δf_n(k,t)                                   │
│      ├── Column 3-4: e-e lifetime (hole/electron)              │
│      ├── Column 5-6: e-ph lifetime (hole/electron)             │
│      └── Column 7-8: Total lifetime                            │
│                                                                 │
│  If OCCgroup:                                                   │
│    YPP-carriers_path.dat (grouped states)                      │
└─────────────────────────────────────────────────────────────────┘
```

### Energy-Resolved Branch

```
┌─────────────────────────────────────────────────────────────────┐
│                    Energy-Resolved Analysis                     │
│                    (RT_components_energy_plot.F)                │
│                                                                 │
│  For each time step t:                                          │
│                                                                 │
│    1. Sort states by energy: E_n(k)                            │
│    2. Bin occupations: f(E,t)                                  │
│    3. Fit to Fermi function                                    │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Fermi Function Fitting                       │
│                                                                 │
│  Model:                                                         │
│    f_fit(E) = 1 / [1 + exp((E - μ)/k_B T)]                    │
│                                                                 │
│  Fit parameters:                                                │
│    ├── μ: Chemical potential (eV)                              │
│    └── T: Temperature (K)                                      │
│                                                                 │
│  Separate fits for:                                             │
│    ├── Electrons (E > E_F)                                     │
│    └── Holes (E < E_F)                                         │
│                                                                 │
│  Skip with: SkipFermiFIT                                        │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Write Output                                 │
│                                                                 │
│  YPP-carriers_E.dat:                                           │
│    ├── Rows: Energy bins                                       │
│    ├── Columns: Time steps                                     │
│    └── Values: f(E,t)                                          │
│                                                                 │
│  YPP-Ef_and_T.dat:                                             │
│    ├── Column 1: Time (fs)                                     │
│    ├── Column 2: T_electron (K)                                │
│    ├── Column 3: T_hole (K)                                    │
│    ├── Column 4: μ_electron (eV)                               │
│    └── Column 5: μ_hole (eV)                                   │
│                                                                 │
│  Separate files for e-e, e-ph contributions                     │
└─────────────────────────────────────────────────────────────────┘
```

### DOS Evolution Branch

```
┌─────────────────────────────────────────────────────────────────┐
│                    DOS Evolution Analysis                       │
│                    (RT_dos_time_plot.F)                         │
│                                                                 │
│  For each time step t:                                          │
│                                                                 │
│    1. Load f_n(k,t)                                            │
│    2. Compute DOS(E,t) with broadening                         │
│    3. Optional: Interpolate in k-space                         │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    DOS Computation                              │
│                                                                 │
│  DOS(E,t) = Σ_{nk} f_n(k,t) δ[E - E_n(k)]                     │
│                                                                 │
│  Broadening:                                                    │
│    δ(E) → Gaussian or Lorentzian                               │
│    Width: DOSEBroad                                            │
│                                                                 │
│  Energy grid:                                                   │
│    Range: DOSERange                                            │
│    Steps: DOSESteps                                            │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Optional: k-space Interpolation              │
│                                                                 │
│  If INTERP_Grid set:                                           │
│    ├── Interpolate f_n(k,t) to finer grid                      │
│    ├── Compute DOS on interpolated grid                        │
│    └── Smoother DOS, better resolution                         │
│                                                                 │
│  INTERPOLATION_driver_do                                        │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Write Output                                 │
│                                                                 │
│  YPP-TD_dos.dat:                                               │
│    ├── Rows: Energy bins                                       │
│    ├── Columns: Time steps                                     │
│    └── Values: DOS(E,t)                                        │
│                                                                 │
│  If interpolated:                                               │
│    YPP-TD_INTERPOLATED_dos.dat                                 │
│                                                                 │
│  Options:                                                       │
│    ├── l_separate_eh: Separate e/h DOS                         │
│    ├── l_PROJECT_atom: Projected DOS                           │
│    └── Spin-resolved (if spinor)                               │
└─────────────────────────────────────────────────────────────────┘
```

---

## Database Manipulation Workflow

```
┌─────────────────────────────────────────────────────────────────┐
│                    Choose Excitation Method                     │
│                                                                 │
│  ypp -r e  →  Energy-based excitation                          │
│  ypp -r f  →  Fermi function excitation                        │
└─────────────────────────────────────────────────────────────────┘
                              │
        ┌─────────────────────┴─────────────────────┐
        │                                           │
        ▼                                           ▼
   Energy-Based                              Fermi Function
        │                                           │
```

### Energy-Based Branch

```
┌─────────────────────────────────────────────────────────────────┐
│                    Energy-Based Excitation                      │
│                    (RT_manual_excitation)                       │
│                                                                 │
│  Input parameters:                                              │
│    ├── RTpumpNel: Total electrons to excite                    │
│    ├── RTpumpEhEn: Energy window (E_h | E_e)                   │
│    ├── RTpumpEhWd: Energy width (Gaussian)                     │
│    └── RTpumpDE: e-h energy separation                         │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    K-Space Selection                            │
│                                                                 │
│  Optional: Restrict to k-regions                                │
│    ├── BANDS_path: High-symmetry points                        │
│    ├── RTpumpBZWd: k-space width                               │
│    └── RTpumpBZReg: Explicit k-points                          │
│                                                                 │
│  RT_select_k_space → do_kpt(:)                                 │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Select Hole States                           │
│                                                                 │
│  For each k-point (if do_kpt(k)):                              │
│    For each valence band v:                                     │
│      If |E_v(k) - E_VBM - E_h| < E_width:                      │
│        ├── Weight: w_v(k) = exp[-(E_v - E_target)²/σ²]        │
│        └── Mark as hole state                                  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Select Electron States                       │
│                                                                 │
│  For each k-point (if do_kpt(k)):                              │
│    For each conduction band c:                                  │
│      If |E_c(k) - E_CBM - E_e| < E_width:                      │
│        If |E_c(k) - E_v(k) - ΔE| < tolerance:                  │
│          ├── Weight: w_c(k) = exp[-(E_c - E_target)²/σ²]      │
│          └── Mark as electron state                            │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Normalize Weights                            │
│                                                                 │
│  Σ_states w(state) = RTpumpNel                                 │
│                                                                 │
│  Scale weights to match target Nel                              │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Set Occupations                              │
│                                                                 │
│  For holes:                                                     │
│    f_v(k) = f_eq(k) - w_v(k)                                   │
│                                                                 │
│  For electrons:                                                 │
│    f_c(k) = f_eq(k) + w_c(k)                                   │
└─────────────────────────────────────────────────────────────────┘
```

### Fermi Function Branch

```
┌─────────────────────────────────────────────────────────────────┐
│                    Fermi Function Excitation                    │
│                    (RT_Fermi_excitation)                        │
│                                                                 │
│  Input parameters:                                              │
│    ├── RTpumpNel: Total electrons to excite                    │
│    ├── Eh_mu: Chemical potential (μ_h | μ_e)                   │
│    ├── Eh_temp: Temperature (T_h | T_e)                        │
│    └── h_mu_autotune_thr: Tolerance for Nel matching           │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    K-Space Selection                            │
│                                                                 │
│  Same as energy-based:                                          │
│    RT_select_k_space → do_kpt(:)                               │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Initial Fermi Distributions                  │
│                                                                 │
│  Holes:                                                         │
│    f_h(E) = 1 - 1/[1 + exp((E - μ_h)/k_B T_h)]                │
│                                                                 │
│  Electrons:                                                     │
│    f_e(E) = 1/[1 + exp((E - μ_e)/k_B T_e)]                    │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Auto-tune Chemical Potentials                │
│                                                                 │
│  Iteratively adjust μ_h and μ_e to match:                      │
│                                                                 │
│    N_holes = Σ_v,k [f_eq(v,k) - f_h(v,k)] = RTpumpNel         │
│    N_electrons = Σ_c,k [f_e(c,k) - f_eq(c,k)] = RTpumpNel     │
│                                                                 │
│  Tolerance: h_mu_autotune_thr                                   │
│                                                                 │
│  Method: Bisection or Newton-Raphson                            │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Set Occupations                              │
│                                                                 │
│  For each state (n, k):                                         │
│    f_n(k) = f_h(E_n) + f_e(E_n)                                │
│                                                                 │
│  Results in thermal-like distribution                           │
└─────────────────────────────────────────────────────────────────┘
```

### Common Final Steps

```
┌─────────────────────────────────────────────────────────────────┐
│                    Initialize RT Structures                     │
│                                                                 │
│  RT_alloc("carriers")                                          │
│  RT_carriers_object(..., "allocate")                           │
│    ├── Allocate carrier arrays                                 │
│    ├── Set f_n(k,t=0) from above                               │
│    └── Initialize scattering components to zero                │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Write Database                               │
│                                                                 │
│  io_RT_components("carriers", ID)                              │
│    ├── Section 1: Header                                       │
│    ├── Section 2: Carrier data                                 │
│    └── Section 3: Time grid (t=0 only)                         │
│                                                                 │
│  Output: ndb.RT_carriers                                        │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Use in RT Simulation                         │
│                                                                 │
│  yambo_rt will:                                                 │
│    ├── Read ndb.RT_carriers                                    │
│    ├── Use as initial condition: f_n(k,t=0)                    │
│    └── Propagate from this state                               │
└─────────────────────────────────────────────────────────────────┘
```

---

## Data Flow Diagrams

### RT Simulation → YPP → Analysis

```
┌──────────────────────────────────────────────────────────────────┐
│                    YAMBO RT Simulation                           │
└──────────────────────────────────────────────────────────────────┘
                              │
                              │ Writes databases
                              ▼
        ┌─────────────────────────────────────────┐
        │                                         │
        ▼                                         ▼
┌──────────────────┐                    ┌──────────────────┐
│ ndb.RT_carriers  │                    │ ndb.Nonlinear    │
│                  │                    │                  │
│ • f_n(k,t)       │                    │ • P(t)           │
│ • τ_n(k,t)       │                    │ • J(t)           │
│ • Time grid      │                    │ • Field info     │
└──────────────────┘                    └──────────────────┘
        │                                         │
        │                                         │
        └─────────────────┬───────────────────────┘
                          │
                          │ YPP reads
                          ▼
        ┌─────────────────────────────────────────┐
        │                                         │
        ▼                                         ▼
┌──────────────────┐                    ┌──────────────────┐
│ Carrier Analysis │                    │ Optical Analysis │
│                  │                    │                  │
│ • f(t)           │                    │ • χ(ω)           │
│ • f(E)           │                    │ • ε(ω)           │
│ • DOS(E,t)       │                    │ • α(ω)           │
│ • T(t), μ(t)     │                    │ • χ^(n)(ω)       │
└──────────────────┘                    └──────────────────┘
        │                                         │
        │                                         │
        └─────────────────┬───────────────────────┘
                          │
                          │ Writes output
                          ▼
        ┌─────────────────────────────────────────┐
        │                                         │
        ▼                                         ▼
┌──────────────────┐                    ┌──────────────────┐
│ YPP-occ_*.dat    │                    │ YPP-eps_*.dat    │
│ YPP-carriers_*.dat│                   │ YPP-alpha_*.dat  │
│ YPP-Ef_and_T.dat │                    │ YPP-X_*.dat      │
│ YPP-TD_dos.dat   │                    │                  │
└──────────────────┘                    └──────────────────┘
```

### Database Structure

```
ndb.RT_carriers
├── Section 1: Header
│   ├── RT_bands
│   ├── RT_nk
│   ├── n_sp_pol
│   └── Time info
│
├── Section 2: Carrier data
│   ├── f_n(k,t) [all times]
│   ├── RT_carriers%table
│   └── RT_carriers%kpt
│
└── Section 3: Scattering (if present)
    ├── τ_ee(n,k,t)
    ├── τ_ep(n,k,t)
    └── τ_eph(n,k,t)

ndb.Nonlinear
├── Section 1: Header
│   ├── Field parameters
│   ├── Time grid
│   └── Simulation info
│
└── Section 2+: Frequency data
    ├── P(t) [3 components]
    ├── J(t) [3 components]
    └── Field(t)
```

---

## Summary: YPP RT Processing Pipeline

```
                    ┌─────────────────────┐
                    │   RT Simulation     │
                    │   (yambo_rt)        │
                    └──────────┬──────────┘
                               │
                               │ Creates databases
                               │
                    ┌──────────▼──────────┐
                    │   YPP Analysis      │
                    │   (ypp -y/n/t/r)    │
                    └──────────┬──────────┘
                               │
                ┌──────────────┼──────────────┐
                │              │              │
                ▼              ▼              ▼
        ┌───────────┐  ┌───────────┐  ┌───────────┐
        │ Carriers  │  │  Optical  │  │ Database  │
        │ Dynamics  │  │ Response  │  │   Manip   │
        └───────────┘  └───────────┘  └───────────┘
                │              │              │
                └──────────────┼──────────────┘
                               │
                    ┌──────────▼──────────┐
                    │   Output Files      │
                    │   (YPP-*.dat)       │
                    └──────────┬──────────┘
                               │
                    ┌──────────▼──────────┐
                    │   Visualization     │
                    │   (gnuplot/python)  │
                    └─────────────────────┘
```

---

**Flowcharts Version**: 1.0  
**For YAMBO**: 5.x  
**Last Updated**: 2025

These flowcharts provide visual guidance for understanding YPP's RT post-processing workflows. For detailed explanations, see `YAMBO_YPP_RT_DOCUMENTATION.md`.