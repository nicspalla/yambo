---
title: YAMBO THEORY README
---

# YAMBO Theory Documentation Suite {#yambo_theory_main}

**Comprehensive documentation of GW, BSE, basis sets, and symmetries in YAMBO**

---

## Overview

This documentation suite provides a complete theoretical and practical guide to YAMBO's implementation of many-body perturbation theory methods. It covers the mathematical formulas, their physical interpretation, code implementation details, and practical examples.

### What's Included

This suite consists of **4 comprehensive documents** totaling over **3,500 lines** of documentation:

1. **Main Theory Documentation** - Complete theoretical framework
2. **Quick Reference Guide** - Fast formula lookup
3. **Visual Guide** - Diagrams and flowcharts
4. **Code Examples** - Practical implementation details

---

## Documentation Files

This suite includes the following documents:

- @subpage yambo_theory_doc "Main Theory Documentation"
- @subpage yambo_formulas "Quick Formula Reference"
- @subpage yambo_theory_visual "Visual Guide"
- @subpage yambo_theory_examples "Code Examples"

---

### 1. @ref yambo_theory_doc "YAMBO_THEORY_DOCUMENTATION.md" (Main Reference)

**Size:** ~1,200 lines  
**Purpose:** Complete theoretical reference

**Contents:**
- **Basis Sets in YAMBO**
  - Plane-wave expansion
  - G-vector cutoffs
  - Oscillator strengths
  - Real-space representation
  
- **GW Approximation**
  - Self-energy operator
  - Screened interaction
  - Plasmon-pole approximation
  - COHSEX approximation
  - Quasiparticle energies
  - Real-axis integration
  
- **Bethe-Salpeter Equation**
  - Two-particle Hamiltonian
  - BSE kernel (exchange + direct)
  - Resonant-antiresonant coupling
  - Tamm-Dancoff approximation
  - Optical absorption
  - Haydock recursion
  
- **Symmetry Operations**
  - Crystal symmetries
  - k-point mapping
  - Time-reversal symmetry
  - Spatial inversion
  - Wavefunction transformation
  
- **Implementation Details**
  - Code structure
  - Parallelization
  - GPU acceleration
  - I/O and databases

**When to use:** Deep dive into theory, understanding formulas, learning the physics

---

### 2. YAMBO_FORMULAS_QUICK_REFERENCE.md (Cheat Sheet)

**Size:** ~600 lines  
**Purpose:** Quick formula lookup

**Contents:**
- **Basis Sets** - Plane-wave formulas
- **GW Formulas** - All self-energy expressions
- **BSE Formulas** - Kernel and optical absorption
- **Symmetry Operations** - Transformation rules
- **Code Variables** - Variable names and locations
- **Quick Lookup Tables** - Fast reference

**When to use:** Quick formula check, finding variable names, during coding

---

### 3. YAMBO_THEORY_VISUAL_GUIDE.md (Diagrams)

**Size:** ~900 lines  
**Purpose:** Visual understanding

**Contents:**
- **System Overview** - YAMBO workflow diagrams
- **Basis Set Visualization** - Plane-wave representation
- **GW Calculation Flow** - Step-by-step flowcharts
- **BSE Calculation Flow** - Kernel construction flow
- **Symmetry Operations** - BZ and IBZ diagrams
- **Data Structures** - Memory layout visualization

**When to use:** Understanding workflow, visualizing concepts, presentations

---

### 4. YAMBO_THEORY_CODE_EXAMPLES.md (Practical Guide)

**Size:** ~800 lines  
**Purpose:** Implementation examples

**Contents:**
- **Oscillator Strength Calculation** - Complete scatter_Bamp example
- **GW Self-Energy Implementation** - QP_ppa_cohsex walkthrough
- **BSE Kernel Construction** - K_kernel detailed example
- **Symmetry Operations** - WF_apply_symm implementation
- **Memory Layout Examples** - Data access patterns

**When to use:** Writing code, debugging, understanding implementation

---

## Quick Start Guide

### For Beginners

**Start here:**
1. Read **Section 1-2** of `YAMBO_THEORY_DOCUMENTATION.md` (Basis sets)
2. Look at **System Overview** in `YAMBO_THEORY_VISUAL_GUIDE.md`
3. Check **Oscillator Calculation** in `YAMBO_THEORY_CODE_EXAMPLES.md`

**Goal:** Understand plane-wave basis and basic operations

### For GW Calculations

**Start here:**
1. Read **Section 3** of `YAMBO_THEORY_DOCUMENTATION.md` (GW theory)
2. Look at **GW Calculation Flow** in `YAMBO_THEORY_VISUAL_GUIDE.md`
3. Check **GW Self-Energy Implementation** in `YAMBO_THEORY_CODE_EXAMPLES.md`
4. Use `YAMBO_FORMULAS_QUICK_REFERENCE.md` for formula lookup

**Goal:** Understand and implement GW calculations

### For BSE Calculations

**Start here:**
1. Read **Section 4** of `YAMBO_THEORY_DOCUMENTATION.md` (BSE theory)
2. Look at **BSE Calculation Flow** in `YAMBO_THEORY_VISUAL_GUIDE.md`
3. Check **BSE Kernel Construction** in `YAMBO_THEORY_CODE_EXAMPLES.md`
4. Use `YAMBO_FORMULAS_QUICK_REFERENCE.md` for kernel formulas

**Goal:** Understand and implement BSE calculations

### For Symmetry Operations

**Start here:**
1. Read **Section 5** of `YAMBO_THEORY_DOCUMENTATION.md` (Symmetries)
2. Look at **Symmetry Operations** in `YAMBO_THEORY_VISUAL_GUIDE.md`
3. Check **Symmetry Operations** in `YAMBO_THEORY_CODE_EXAMPLES.md`

**Goal:** Understand symmetry exploitation in YAMBO

---

## Documentation Roadmap

### By Task

| Task | Documents to Read | Order |
|------|-------------------|-------|
| **Learn YAMBO theory** | Main Doc → Visual Guide | 1 → 3 |
| **Implement GW** | Main Doc (Sec 3) → Code Examples (Sec 2) → Quick Ref | 1 → 4 → 2 |
| **Implement BSE** | Main Doc (Sec 4) → Code Examples (Sec 3) → Quick Ref | 1 → 4 → 2 |
| **Debug code** | Code Examples → Quick Ref → Main Doc | 4 → 2 → 1 |
| **Quick formula** | Quick Ref | 2 |
| **Understand workflow** | Visual Guide | 3 |
| **Write paper** | Main Doc → Visual Guide | 1 → 3 |

### By Experience Level

**Beginner (New to YAMBO):**
```
Week 1: Visual Guide (System Overview, Basis Sets)
Week 2: Main Doc (Sections 1-2)
Week 3: Code Examples (Oscillators)
Week 4: Quick Ref (as needed)
```

**Intermediate (Know basics):**
```
Day 1: Main Doc (GW or BSE section)
Day 2: Visual Guide (corresponding flow)
Day 3: Code Examples (implementation)
Day 4: Quick Ref (during coding)
```

**Advanced (Implementing features):**
```
Use Quick Ref for formulas
Use Code Examples for patterns
Use Main Doc for deep theory
Use Visual Guide for presentations
```

---

## Key Concepts Summary

### Basis Sets

**Core Idea:** Wavefunctions expanded in plane waves
```
ψ_{n,k}(r) = Σ_G c_{n,k}(G) e^{i(k+G)·r}
```

**Key Files:**
- Theory: `YAMBO_THEORY_DOCUMENTATION.md` Section 2
- Code: `mod_wave_func.F`
- Example: `YAMBO_THEORY_CODE_EXAMPLES.md` Section 1

### GW Approximation

**Core Idea:** Quasiparticle energies from self-energy
```
E^{QP} = E^{DFT} + Σ(E^{QP}) - V^{xc}
Σ = iGW
W = ε^{-1}v
```

**Key Files:**
- Theory: `YAMBO_THEORY_DOCUMENTATION.md` Section 3
- Formulas: `YAMBO_FORMULAS_QUICK_REFERENCE.md` Section 2
- Flow: `YAMBO_THEORY_VISUAL_GUIDE.md` Section 3
- Code: `QP_ppa_cohsex.F`
- Example: `YAMBO_THEORY_CODE_EXAMPLES.md` Section 2

### BSE

**Core Idea:** Optical excitations with electron-hole interaction
```
(E_c - E_v) A + Σ K A = Ω A
K = K^{exch} + K^{dir}
```

**Key Files:**
- Theory: `YAMBO_THEORY_DOCUMENTATION.md` Section 4
- Formulas: `YAMBO_FORMULAS_QUICK_REFERENCE.md` Section 3
- Flow: `YAMBO_THEORY_VISUAL_GUIDE.md` Section 4
- Code: `K_kernel.F`, `K_exchange_kernel.F`, `K_correlation_kernel_std.F`
- Example: `YAMBO_THEORY_CODE_EXAMPLES.md` Section 3

### Symmetries

**Core Idea:** Exploit crystal symmetries to reduce cost
```
ψ_{n,Sk}(r) = e^{iSk·τ} ψ_{n,k}(S^{-1}r)
IBZ: Minimal k-point set
```

**Key Files:**
- Theory: `YAMBO_THEORY_DOCUMENTATION.md` Section 5
- Formulas: `YAMBO_FORMULAS_QUICK_REFERENCE.md` Section 4
- Visual: `YAMBO_THEORY_VISUAL_GUIDE.md` Section 5
- Code: `mod_D_lattice.F`, `mod_R_lattice.F`
- Example: `YAMBO_THEORY_CODE_EXAMPLES.md` Section 4

---

## Formula Quick Lookup

### Most Important Formulas

**Oscillator Strength:**
```
ρ_{nm}(k,q,G) = ⟨n,k|e^{-i(q+G)·r}|m,k+q⟩
```
→ `YAMBO_FORMULAS_QUICK_REFERENCE.md` Section 1

**GW Self-Energy:**
```
Σ_{n,k}(ω) = Σ_{m,q,G,G'} ρ*_{nm} W_{GG'}(ω-ε_m) ρ_{nm}
```
→ `YAMBO_FORMULAS_QUICK_REFERENCE.md` Section 2

**Quasiparticle Energy:**
```
E^{QP} = E^{DFT} + ⟨Σ(E^{QP})⟩ - V^{xc}
```
→ `YAMBO_FORMULAS_QUICK_REFERENCE.md` Section 2

**BSE Exchange Kernel:**
```
K^{exch} = -δ_{kk'} Σ_G v_G ρ_{vc} ρ*_{v'c'}
```
→ `YAMBO_FORMULAS_QUICK_REFERENCE.md` Section 3

**BSE Direct Kernel:**
```
K^{dir} = Σ_{GG'} ρ_{vc} W_{GG'} ρ*_{v'c'}
```
→ `YAMBO_FORMULAS_QUICK_REFERENCE.md` Section 3

**Optical Absorption:**
```
ε_M(ω) = 1 - Σ_S |⟨S|ρ|0⟩|²/(ω - Ω^S)
```
→ `YAMBO_FORMULAS_QUICK_REFERENCE.md` Section 3

---

## Code Location Quick Reference

### Main Source Directories

| Component | Directory | Key Files |
|-----------|-----------|-----------|
| **GW** | `src/qp/` | `QP_ppa_cohsex.F`, `QP_real_axis.F` |
| **BSE** | `src/bse/` | `K_kernel.F`, `K_exchange_kernel.F` |
| **Wavefunctions** | `src/wf_and_fft/` | `scatter_Bamp.F`, `WF_apply_symm.F` |
| **Symmetries** | `src/bz_ops/` | `k_expand.F`, `k_ibz2bz.F` |
| **Modules** | `src/modules/` | `mod_wave_func.F`, `mod_R_lattice.F` |

### Key Modules

| Module | File | Purpose |
|--------|------|---------|
| `wave_func` | `mod_wave_func.F` | Wavefunction storage |
| `R_lattice` | `mod_R_lattice.F` | Reciprocal lattice, k-points |
| `D_lattice` | `mod_D_lattice.F` | Real lattice, symmetries |
| `QP_m` | `mod_QP_m.F` | Quasiparticle data |
| `BS` | `mod_BS.F` | BSE data structures |
| `X_m` | `mod_X_m.F` | Response function |

---

## Common Use Cases

### 1. Understanding a Formula

**Problem:** "What is the GW self-energy formula?"

**Solution:**
1. Check `YAMBO_FORMULAS_QUICK_REFERENCE.md` Section 2 for quick answer
2. Read `YAMBO_THEORY_DOCUMENTATION.md` Section 3.3 for details
3. Look at `YAMBO_THEORY_VISUAL_GUIDE.md` Section 3 for visualization

### 2. Finding Code Implementation

**Problem:** "Where is the BSE kernel computed?"

**Solution:**
1. Check `YAMBO_FORMULAS_QUICK_REFERENCE.md` Section 5 for file location
2. Read `YAMBO_THEORY_CODE_EXAMPLES.md` Section 3 for implementation
3. Look at actual code: `src/bse/K_kernel.F`

### 3. Debugging a Calculation

**Problem:** "My GW calculation gives wrong results"

**Solution:**
1. Check `YAMBO_THEORY_VISUAL_GUIDE.md` Section 3 for workflow
2. Verify each step using `YAMBO_THEORY_CODE_EXAMPLES.md` Section 2
3. Compare formulas with `YAMBO_FORMULAS_QUICK_REFERENCE.md` Section 2
4. Check theory in `YAMBO_THEORY_DOCUMENTATION.md` Section 3

### 4. Writing a Paper

**Problem:** "Need to explain YAMBO's BSE implementation"

**Solution:**
1. Use formulas from `YAMBO_THEORY_DOCUMENTATION.md` Section 4
2. Include diagrams from `YAMBO_THEORY_VISUAL_GUIDE.md` Section 4
3. Cite references from `YAMBO_THEORY_DOCUMENTATION.md` Section 7

### 5. Implementing a New Feature

**Problem:** "Want to add a new kernel term"

**Solution:**
1. Understand theory: `YAMBO_THEORY_DOCUMENTATION.md` Section 4
2. Study existing code: `YAMBO_THEORY_CODE_EXAMPLES.md` Section 3
3. Follow patterns: `K_exchange_kernel.F` as template
4. Use `YAMBO_FORMULAS_QUICK_REFERENCE.md` for variable names

---

## Best Practices

### Reading the Documentation

**DO:**
- ✅ Start with Visual Guide for overview
- ✅ Use Quick Reference during coding
- ✅ Read Main Doc for deep understanding
- ✅ Study Code Examples before implementing
- ✅ Cross-reference between documents

**DON'T:**
- ❌ Try to read everything at once
- ❌ Skip the Visual Guide
- ❌ Ignore the Quick Reference
- ❌ Code without understanding theory

### Using the Formulas

**DO:**
- ✅ Check units and normalization
- ✅ Verify indices and ranges
- ✅ Understand physical meaning
- ✅ Compare with code implementation

**DON'T:**
- ❌ Copy formulas without understanding
- ❌ Ignore symmetry factors
- ❌ Forget normalization constants
- ❌ Mix different conventions

### Implementing Code

**DO:**
- ✅ Follow existing patterns
- ✅ Use YAMBO's memory system
- ✅ Exploit symmetries
- ✅ Add comments with formulas
- ✅ Test with simple systems

**DON'T:**
- ❌ Reinvent the wheel
- ❌ Ignore memory management
- ❌ Break symmetry exploitation
- ❌ Write uncommented code
- ❌ Skip validation

---

## Troubleshooting

### "I don't understand the theory"

**Solution:**
1. Start with `YAMBO_THEORY_VISUAL_GUIDE.md` for intuition
2. Read `YAMBO_THEORY_DOCUMENTATION.md` slowly, section by section
3. Work through `YAMBO_THEORY_CODE_EXAMPLES.md` examples
4. Consult references in Section 7 of Main Doc

### "I can't find a formula"

**Solution:**
1. Check `YAMBO_FORMULAS_QUICK_REFERENCE.md` first
2. Use Ctrl+F to search in Main Doc
3. Check the Table of Contents
4. Look in the relevant section (GW=3, BSE=4, etc.)

### "The code doesn't match the formula"

**Solution:**
1. Check normalization factors
2. Verify index conventions
3. Look for symmetry operations
4. Read comments in code
5. Compare with `YAMBO_THEORY_CODE_EXAMPLES.md`

### "I need more details"

**Solution:**
1. Read the full section in Main Doc
2. Check the references (Section 7)
3. Look at the actual source code
4. Consult YAMBO wiki: http://www.yambo-code.org/wiki/

---

## Additional Resources

### YAMBO Official

- **Website:** http://www.yambo-code.org/
- **Wiki:** http://www.yambo-code.org/wiki/
- **Tutorials:** http://www.yambo-code.org/tutorials/
- **Forum:** http://www.yambo-code.org/forum/

### Related Documentation

- **Memory System:** `YAMBO_ALLOC_DOCUMENTATION.md` (if available)
- **RT Initialization:** Doxygen documentation in `src/real_time_initialize/`
- **Resource Estimator:** `yambo_rt_resource_estimator.py`

### Key Papers

1. **YAMBO Code:**
   - Marini et al., Comp. Phys. Comm. 180, 1392 (2009)
   - Sangalli et al., J. Phys.: Condens. Matter 31, 325902 (2019)

2. **GW Theory:**
   - Hedin, Phys. Rev. 139, A796 (1965)
   - Hybertsen & Louie, Phys. Rev. B 34, 5390 (1986)
   - Onida et al., Rev. Mod. Phys. 74, 601 (2002)

3. **BSE Theory:**
   - Salpeter & Bethe, Phys. Rev. 84, 1232 (1951)
   - Rohlfing & Louie, Phys. Rev. B 62, 4927 (2000)
   - Strinati, Riv. Nuovo Cimento 11, 1 (1988)

---

## Document Statistics

| Document | Lines | Size | Topics |
|----------|-------|------|--------|
| Main Documentation | ~1,200 | ~85 KB | 7 sections |
| Quick Reference | ~600 | ~45 KB | 5 sections |
| Visual Guide | ~900 | ~65 KB | 6 sections |
| Code Examples | ~800 | ~60 KB | 5 sections |
| **Total** | **~3,500** | **~255 KB** | **23 sections** |

### Coverage

- ✅ Plane-wave basis sets
- ✅ GW approximation (all variants)
- ✅ BSE (full theory)
- ✅ Symmetry operations
- ✅ Code implementation
- ✅ Practical examples
- ✅ Visual diagrams
- ✅ Quick reference
- ✅ Memory layouts
- ✅ Workflow diagrams

---

## Feedback and Contributions

This documentation was generated from analysis of the YAMBO source code. If you find errors or have suggestions:

1. Check the source code for the latest implementation
2. Consult the YAMBO wiki for updates
3. Post on the YAMBO forum for clarifications

---

## Version Information

- **Documentation Version:** 1.0
- **Date:** 2025
- **Based on:** YAMBO source code analysis
- **Covers:** GW, BSE, basis sets, symmetries

---

## Quick Navigation

**By Topic:**
- [Basis Sets](#key-concepts-summary) → Main Doc Sec 2
- [GW](#key-concepts-summary) → Main Doc Sec 3, Quick Ref Sec 2
- [BSE](#key-concepts-summary) → Main Doc Sec 4, Quick Ref Sec 3
- [Symmetries](#key-concepts-summary) → Main Doc Sec 5, Quick Ref Sec 4
- [Code](#code-location-quick-reference) → Code Examples

**By Task:**
- [Learn Theory](#for-beginners) → Main Doc + Visual Guide
- [Implement GW](#for-gw-calculations) → All documents
- [Implement BSE](#for-bse-calculations) → All documents
- [Debug Code](#by-task) → Code Examples + Quick Ref
- [Write Paper](#4-writing-a-paper) → Main Doc + Visual Guide

**By Experience:**
- [Beginner](#by-experience-level) → Visual Guide first
- [Intermediate](#by-experience-level) → Main Doc + Code Examples
- [Advanced](#by-experience-level) → Quick Ref + Code Examples

---

**Happy coding with YAMBO!**

*"Understanding the theory makes the code transparent."*