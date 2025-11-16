---
title: YAMBO RT THEORY README
---

# YAMBO Real-Time Theory Documentation Suite {#yambo_rt_theory_main}

**Complete theoretical and practical guide to YAMBO's real-time dynamics module**

---

## 📚 Documentation Overview

This suite provides comprehensive documentation for YAMBO's **real-time (RT) module**, which implements non-equilibrium many-body dynamics by solving the **Kadanoff-Baym equations** for the time-dependent density matrix.

### What's Included

This suite includes the following documents:

- @subpage yambo_rt_theory_doc "Main RT Theory Documentation"
- @subpage yambo_rt_quick_ref "RT Quick Reference"
- @subpage yambo_rt_visual "RT Visual Guide"

| Document | Lines | Purpose |
|----------|-------|---------|
| @ref yambo_rt_theory_doc "YAMBO_RT_THEORY_DOCUMENTATION.md" | ~2,000 | Complete theoretical reference |
| @ref yambo_rt_quick_ref "YAMBO_RT_QUICK_REFERENCE.md" | ~800 | Fast formula lookup |
| @ref yambo_rt_visual "YAMBO_RT_VISUAL_GUIDE.md" | ~1,000 | Diagrams and flowcharts |
| **This README** | ~400 | Navigation and quick start |

**Total:** ~4,200 lines of comprehensive RT documentation

---

## 🎯 Quick Start

### For Beginners

**Start here:**
1. Read [Section 1-2 of Main Documentation](YAMBO_RT_THEORY_DOCUMENTATION.md#1-introduction) - Introduction and theoretical framework
2. Browse [Visual Guide Section 1](YAMBO_RT_VISUAL_GUIDE.md#1-rt-workflow-overview) - RT workflow overview
3. Check [Quick Reference - Common Tasks](YAMBO_RT_QUICK_REFERENCE.md#common-tasks) - Practical examples

**Key concepts to understand:**
- Lesser Green's function G^< = density matrix
- Kadanoff-Baym equation: i∂G^</∂t = [H^RT, G^<] + Σ^scatt
- Time integrators (Euler, Exponential, Inverse)
- Gauge choices (velocity vs length)

### For RT Calculations

**Linear response (absorption spectrum):**
1. [Main Doc Section 6.5](YAMBO_RT_THEORY_DOCUMENTATION.md#65-field-shapes) - Field setup
2. [Quick Ref - Linear Response](YAMBO_RT_QUICK_REFERENCE.md#1-linear-response-weak-field) - Parameters
3. [Visual Guide Section 1](YAMBO_RT_VISUAL_GUIDE.md#1-rt-workflow-overview) - Workflow

**Pump-probe spectroscopy:**
1. [Main Doc Section 8](YAMBO_RT_THEORY_DOCUMENTATION.md#8-physical-observables) - Observables
2. [Quick Ref - Pump-Probe](YAMBO_RT_QUICK_REFERENCE.md#2-pump-probe-spectroscopy) - Setup
3. [Visual Guide Section 6](YAMBO_RT_VISUAL_GUIDE.md#6-observable-computation) - Observable computation

**High-harmonic generation:**
1. [Main Doc Section 6](YAMBO_RT_THEORY_DOCUMENTATION.md#6-external-fields-and-gauge-choices) - Strong fields
2. [Quick Ref - HHG](YAMBO_RT_QUICK_REFERENCE.md#3-high-harmonic-generation) - Parameters
3. [Visual Guide Section 5](YAMBO_RT_VISUAL_GUIDE.md#5-gauge-choices-comparison) - Gauge choices

### For Developers

**Understanding the code:**
1. [Main Doc Section 10](YAMBO_RT_THEORY_DOCUMENTATION.md#10-implementation-details) - Code structure
2. [Visual Guide Section 8](YAMBO_RT_VISUAL_GUIDE.md#8-data-flow-diagrams) - Data flow
3. [Quick Ref - Variable Reference](YAMBO_RT_QUICK_REFERENCE.md#variable-reference) - Variable names

**Implementing new features:**
1. [Main Doc Section 5](YAMBO_RT_THEORY_DOCUMENTATION.md#5-time-integration-methods) - Integration methods
2. [Main Doc Section 7](YAMBO_RT_THEORY_DOCUMENTATION.md#7-scattering-mechanisms) - Scattering terms
3. [Visual Guide Section 4](YAMBO_RT_VISUAL_GUIDE.md#4-hamiltonian-construction) - Hamiltonian construction

---

## 📖 Documentation Roadmap

### By Topic

#### Theoretical Framework
- **Kadanoff-Baym Equations:** [Main Doc §3](YAMBO_RT_THEORY_DOCUMENTATION.md#3-kadanoff-baym-equations), [Visual Guide §2](YAMBO_RT_VISUAL_GUIDE.md#2-kadanoff-baym-equation-structure)
- **Density Matrix:** [Main Doc §2.2](YAMBO_RT_THEORY_DOCUMENTATION.md#22-time-diagonal-approximation), [Quick Ref - Density Matrix](YAMBO_RT_QUICK_REFERENCE.md#density-matrix)
- **Time Evolution:** [Main Doc §2.3](YAMBO_RT_THEORY_DOCUMENTATION.md#23-equation-of-motion), [Quick Ref - Time Evolution](YAMBO_RT_QUICK_REFERENCE.md#time-evolution)

#### Hamiltonian
- **Decomposition:** [Main Doc §4.1](YAMBO_RT_THEORY_DOCUMENTATION.md#41-hamiltonian-decomposition), [Visual Guide §4](YAMBO_RT_VISUAL_GUIDE.md#4-hamiltonian-construction)
- **Mean-Field:** [Main Doc §4.2](YAMBO_RT_THEORY_DOCUMENTATION.md#42-mean-field-self-energy), [Quick Ref - Approximations](YAMBO_RT_QUICK_REFERENCE.md#approximations)
- **External Fields:** [Main Doc §6](YAMBO_RT_THEORY_DOCUMENTATION.md#6-external-fields-and-gauge-choices), [Visual Guide §5](YAMBO_RT_VISUAL_GUIDE.md#5-gauge-choices-comparison)

#### Time Integration
- **Methods Overview:** [Main Doc §5](YAMBO_RT_THEORY_DOCUMENTATION.md#5-time-integration-methods), [Visual Guide §3](YAMBO_RT_VISUAL_GUIDE.md#3-time-integration-schemes)
- **Euler:** [Main Doc §5.2](YAMBO_RT_THEORY_DOCUMENTATION.md#52-euler-method-euler), [Quick Ref - Euler](YAMBO_RT_QUICK_REFERENCE.md#euler-1st-order)
- **Exponential:** [Main Doc §5.3](YAMBO_RT_THEORY_DOCUMENTATION.md#53-exponential-integrator-exp), [Quick Ref - Exponential](YAMBO_RT_QUICK_REFERENCE.md#exponential-magnus)
- **Inverse:** [Main Doc §5.4](YAMBO_RT_THEORY_DOCUMENTATION.md#54-inverse-integrator-inv), [Quick Ref - Inverse](YAMBO_RT_QUICK_REFERENCE.md#inverse-crank-nicolson)
- **Multi-Step:** [Main Doc §5.6](YAMBO_RT_THEORY_DOCUMENTATION.md#56-multi-step-methods), [Quick Ref - Multi-Step](YAMBO_RT_QUICK_REFERENCE.md#multi-step-methods)

#### Physical Observables
- **Current:** [Main Doc §8.1](YAMBO_RT_THEORY_DOCUMENTATION.md#81-current-density), [Quick Ref - Current](YAMBO_RT_QUICK_REFERENCE.md#current), [Visual Guide §6](YAMBO_RT_VISUAL_GUIDE.md#6-observable-computation)
- **Polarization:** [Main Doc §8.2](YAMBO_RT_THEORY_DOCUMENTATION.md#82-polarization), [Quick Ref - Polarization](YAMBO_RT_QUICK_REFERENCE.md#polarization)
- **Energy:** [Main Doc §8.3](YAMBO_RT_THEORY_DOCUMENTATION.md#83-energy-components), [Quick Ref - Energy](YAMBO_RT_QUICK_REFERENCE.md#energy)
- **Carriers:** [Main Doc §8.4](YAMBO_RT_THEORY_DOCUMENTATION.md#84-carrier-populations), [Quick Ref - Carriers](YAMBO_RT_QUICK_REFERENCE.md#carrier-populations)

#### Approximations
- **IP:** [Main Doc §9.1](YAMBO_RT_THEORY_DOCUMENTATION.md#91-independent-particle-ip), [Quick Ref - IP](YAMBO_RT_QUICK_REFERENCE.md#independent-particle-ip)
- **TD-Hartree:** [Main Doc §9.2](YAMBO_RT_THEORY_DOCUMENTATION.md#92-time-dependent-hartree-td-hartree), [Quick Ref - TD-Hartree](YAMBO_RT_QUICK_REFERENCE.md#time-dependent-hartree)
- **TDDFT:** [Main Doc §9.3](YAMBO_RT_THEORY_DOCUMENTATION.md#93-time-dependent-ldagga-tddft), [Quick Ref - TDDFT](YAMBO_RT_QUICK_REFERENCE.md#tddft-ldagga)
- **TDSEX:** [Main Doc §9.4](YAMBO_RT_THEORY_DOCUMENTATION.md#94-time-dependent-sex-tdsex), [Quick Ref - TDSEX](YAMBO_RT_QUICK_REFERENCE.md#tdsex)

#### Implementation
- **Code Structure:** [Main Doc §10.1](YAMBO_RT_THEORY_DOCUMENTATION.md#101-code-structure), [Visual Guide §8](YAMBO_RT_VISUAL_GUIDE.md#8-data-flow-diagrams)
- **Data Structures:** [Main Doc §10.2](YAMBO_RT_THEORY_DOCUMENTATION.md#102-key-data-structures), [Quick Ref - Variables](YAMBO_RT_QUICK_REFERENCE.md#variable-reference)
- **Memory Management:** [Main Doc §10.3](YAMBO_RT_THEORY_DOCUMENTATION.md#103-memory-management), [Visual Guide §7](YAMBO_RT_VISUAL_GUIDE.md#7-memory-management)
- **Parallelization:** [Main Doc §10.4](YAMBO_RT_THEORY_DOCUMENTATION.md#104-parallelization), [Visual Guide §8](YAMBO_RT_VISUAL_GUIDE.md#parallel-distribution)

---

## 🔑 Key Concepts Summary

### Core Equation

```
i∂G^<(t)/∂t = [H^RT(t), G^<(t)] + Σ^scatt(t)
```

**Components:**
- `G^<(t)`: Lesser Green's function (density matrix)
- `H^RT(t) = H^EQ + ΔΣ^Hxc[G(t)] + H^ext(t)`: Time-dependent Hamiltonian
- `Σ^scatt(t)`: Collision self-energy (scattering)

### Hamiltonian Decomposition

```
H^RT(t) = H^EQ + ΔΣ^Hxc[G(t)] + H^ext(t)
          │       │              │
          │       │              └─ External field (laser)
          │       └──────────────── Mean-field correction
          └──────────────────────── Equilibrium (DFT/GW)
```

### Time Integration

| Method | Order | Stability | Cost | Best For |
|--------|-------|-----------|------|----------|
| EULER | 1st | Conditional | Low | Quick tests |
| EXP | 2nd-6th | Good | Medium | General use |
| INV | 2nd | Unconditional | High | Stiff problems |
| RK4 | 4th | Good | High | High accuracy |

### Gauge Choices

| Gauge | Hamiltonian | Best For |
|-------|-------------|----------|
| Velocity | H = A·p - A²/2 | Periodic systems, strong fields |
| Length | H = E·r | Molecules, weak fields |

---

## 📊 Formula Quick Lookup

### Most Important Formulas

**Density matrix evolution:**
```
G^<(t+Δt) = G^<(t) - iΔt[H^RT(t), G^<(t)] + Δt Σ^scatt(t)
```

**Current density:**
```
J(t) = -e Σ_{n,k} f_n(k,t) v_n(k)
```

**Polarization:**
```
P(t) = ∫_0^t J(t') dt'
```

**Hartree potential:**
```
V^H(r,t) = ∫ ρ(r',t)/|r-r'| dr'
```

**Occupation extraction:**
```
f_n(k,t) = Im[G^<_{nn}(k,t)]
```

---

## 🗂️ Code Location Quick Reference

### Main Routines

| Routine | File | Line | Purpose |
|---------|------|------|---------|
| `RT_driver` | `src/real_time_drivers/RT_driver.F` | 1 | Main RT driver |
| `RT_Hamiltonian` | `src/real_time_hamiltonian/RT_Hamiltonian.F` | 115 | Build H^RT(t) |
| `RT_Integrator` | `src/real_time_propagation/RT_Integrator.F` | 1 | Time integration dispatcher |
| `RT_EULER_step` | `src/real_time_propagation/RT_EULER_step.F` | 1 | Euler integrator |
| `RT_EXP_step_std` | `src/real_time_propagation/RT_EXP_step_std.F` | 1 | Exponential integrator |
| `RT_INV_step_std` | `src/real_time_propagation/RT_INV_step_std.F` | 1 | Inverse integrator |
| `RT_apply_field` | `src/real_time_hamiltonian/RT_apply_field.F` | 8 | Add external field |
| `RT_G_lesser_init` | `src/real_time_initialize/RT_G_lesser_init.F` | 1 | Initialize G^< |

### Key Modules

| Module | File | Contents |
|--------|------|----------|
| `real_time` | `src/modules/mod_real_time.F` | RT variables and types |
| `RT_lifetimes` | `src/modules/mod_RT_lifetimes.F` | Lifetime data structures |
| `RT_occupations` | `src/modules/mod_RT_occupations.F` | Occupation data structures |
| `fields` | `src/modules/mod_fields.F` | External field definitions |

---

## 🎓 Common Use Cases

### 1. Linear Optical Response

**Goal:** Compute absorption spectrum α(ω)

**Steps:**
1. Apply weak Gaussian pulse (E_0 ~ 10^-4 a.u.)
2. Compute current J(t) during and after pulse
3. Fourier transform: χ(ω) = FT[J(t)]/E(ω)
4. Extract absorption: α(ω) = Im[χ(ω)]

**Documentation:**
- Theory: [Main Doc §6.5](YAMBO_RT_THEORY_DOCUMENTATION.md#65-field-shapes)
- Practice: [Quick Ref - Linear Response](YAMBO_RT_QUICK_REFERENCE.md#1-linear-response-weak-field)
- Workflow: [Visual Guide §1](YAMBO_RT_VISUAL_GUIDE.md#1-rt-workflow-overview)

### 2. Pump-Probe Spectroscopy

**Goal:** Study transient absorption ΔA(ω,τ)

**Steps:**
1. Apply strong pump pulse (excite carriers)
2. Wait delay time τ
3. Apply weak probe pulse
4. Compute differential absorption vs delay

**Documentation:**
- Theory: [Main Doc §8.4](YAMBO_RT_THEORY_DOCUMENTATION.md#84-carrier-populations)
- Practice: [Quick Ref - Pump-Probe](YAMBO_RT_QUICK_REFERENCE.md#2-pump-probe-spectroscopy)
- Observables: [Visual Guide §6](YAMBO_RT_VISUAL_GUIDE.md#6-observable-computation)

### 3. High-Harmonic Generation

**Goal:** Compute HHG spectrum

**Steps:**
1. Apply very strong few-cycle pulse (E_0 ~ 10^-2 a.u.)
2. Use velocity gauge (better for strong fields)
3. Compute current J(t)
4. Fourier transform: HHG(ω) = |FT[J(t)]|²

**Documentation:**
- Theory: [Main Doc §6.2](YAMBO_RT_THEORY_DOCUMENTATION.md#62-velocity-gauge-coulomb-gauge)
- Practice: [Quick Ref - HHG](YAMBO_RT_QUICK_REFERENCE.md#3-high-harmonic-generation)
- Gauges: [Visual Guide §5](YAMBO_RT_VISUAL_GUIDE.md#5-gauge-choices-comparison)

### 4. Carrier Dynamics

**Goal:** Study thermalization and relaxation

**Steps:**
1. Excite carriers (optical pulse or manual excitation)
2. Include scattering (el-el, el-ph)
3. Track carrier populations n_e(t), n_h(t)
4. Extract relaxation times and temperatures

**Documentation:**
- Theory: [Main Doc §7](YAMBO_RT_THEORY_DOCUMENTATION.md#7-scattering-mechanisms)
- Practice: [Quick Ref - Carrier Dynamics](YAMBO_RT_QUICK_REFERENCE.md#4-carrier-dynamics)
- Observables: [Main Doc §8.4](YAMBO_RT_THEORY_DOCUMENTATION.md#84-carrier-populations)

---

## 🛠️ Troubleshooting Guide

### Problem: Simulation crashes or diverges

**Possible causes:**
1. Time step too large
2. Field too strong
3. Numerical instability

**Solutions:**
- Reduce time step: `RTstep = 0.01 fs` (or smaller)
- Use more stable integrator: `Integrator = "INV"`
- Reduce field strength
- Check [Main Doc §5](YAMBO_RT_THEORY_DOCUMENTATION.md#5-time-integration-methods) for stability conditions

### Problem: Unphysical results

**Check:**
1. **Unitarity:** Tr[G^<] should be conserved
2. **Energy conservation:** (for IP approximation)
3. **Gauge consistency:** Results should be gauge-independent
4. **Convergence:** k-points, bands, time step

**Documentation:**
- [Main Doc §10.6](YAMBO_RT_THEORY_DOCUMENTATION.md#106-rotating-wave-approximation-rwa)
- [Quick Ref - Troubleshooting](YAMBO_RT_QUICK_REFERENCE.md#troubleshooting)

### Problem: Slow performance

**Optimizations:**
1. Use adaptive time-stepping
2. Enable RWA for near-resonant excitation
3. Reduce band range if possible
4. Use GPU acceleration
5. Optimize MPI distribution

**Documentation:**
- [Main Doc §10.4](YAMBO_RT_THEORY_DOCUMENTATION.md#104-parallelization)
- [Visual Guide §8](YAMBO_RT_VISUAL_GUIDE.md#parallel-distribution)

---

## 📚 References

### Foundational Theory

1. **Kadanoff-Baym Equations:**
   - L.P. Kadanoff and G. Baym, *Quantum Statistical Mechanics* (Benjamin, 1962)
   - L.V. Keldysh, *Sov. Phys. JETP* **20**, 1018 (1965)

2. **Real-Time TDDFT:**
   - E. Runge and E.K.U. Gross, *Phys. Rev. Lett.* **52**, 997 (1984)

3. **Non-Equilibrium Green's Functions:**
   - H. Haug and A.-P. Jauho, *Quantum Kinetics in Transport and Optics of Semiconductors* (Springer, 2008)

### YAMBO Implementation

4. **YAMBO Real-Time:**
   - D. Sangalli et al., *J. Chem. Phys.* **134**, 034115 (2011)
   - C. Attaccalite et al., *Phys. Rev. B* **84**, 245110 (2011)

5. **Applications:**
   - C. Attaccalite et al., *Phys. Rev. Lett.* **98**, 097402 (2007) - Ultrafast dynamics
   - M. Grüning and C. Attaccalite, *Phys. Rev. B* **89**, 081102(R) (2014) - Transient absorption

**Complete reference list:** [Main Doc §11](YAMBO_RT_THEORY_DOCUMENTATION.md#11-references)

---

## 🔗 External Resources

### YAMBO Official

- **Website:** http://www.yambo-code.org
- **Wiki:** http://www.yambo-code.org/wiki
- **Forum:** http://www.yambo-code.org/forum
- **GitHub:** https://github.com/yambo-code/yambo

### Tutorials

- **YAMBO School Materials:** http://www.yambo-code.org/schools
- **RT Tutorial:** http://www.yambo-code.org/wiki/index.php/Real_time_approach_to_linear_response
- **Examples:** `$YAMBO/test-suite/TESTS_RT/`

---

## 📊 Documentation Statistics

| Metric | Value |
|--------|-------|
| Total lines | ~4,200 |
| Number of documents | 4 |
| Sections covered | 35+ |
| Formulas documented | 100+ |
| Code examples | 20+ |
| Diagrams | 15+ |
| References | 25+ |

### Coverage

- ✅ **Theory:** Complete (KBE, Hamiltonian, integration, observables)
- ✅ **Implementation:** Comprehensive (code structure, data flow, parallelization)
- ✅ **Practical:** Extensive (use cases, parameters, troubleshooting)
- ✅ **Visual:** Rich (flowcharts, diagrams, data structures)

---

## 🤝 Contributing

Found an error or want to improve the documentation?

1. Check existing documentation for coverage
2. Identify the appropriate document to modify
3. Follow the existing style and formatting
4. Add references where appropriate
5. Update this README if adding new sections

## 📄 License

This documentation is released under the **GPL license**, consistent with YAMBO's licensing.

---

## ✨ Acknowledgments

This documentation suite was created to provide comprehensive theoretical and practical guidance for YAMBO's real-time dynamics module. It builds upon:

- YAMBO's extensive Doxygen documentation
- Published papers on RT-TDDFT and non-equilibrium Green's functions
- Community feedback and common questions
- Years of development by the YAMBO team

**YAMBO Development Team**  
**Website:** http://www.yambo-code.org