---
title: YAMBO FORMULAS QUICK REFERENCE
---

# YAMBO Formulas Quick Reference {#yambo_formulas}

**Quick lookup guide for main theoretical formulas in YAMBO**

---

## Table of Contents

1. [Basis Sets](#basis-sets)
2. [GW Formulas](#gw-formulas)
3. [BSE Formulas](#bse-formulas)
4. [Symmetry Operations](#symmetry-operations)
5. [Code Variables](#code-variables)

---

## 1. Basis Sets

### Plane-Wave Expansion

```
ψ_{n,k}(r) = (1/√Ω) Σ_G c_{n,k}(G) e^{i(k+G)·r}
```

**Code:** `WF%c(ig,ib,ik)` in `mod_wave_func.F`

### G-Vector Cutoff

```
|k + G|² / 2 ≤ E_cut
```

**Code:** `wf_ng`, `wf_ncx`, `wf_igk(ig,ik)`

### Oscillator Strength

```
ρ_{nm}(k,q,G) = ⟨n,k|e^{-i(q+G)·r}|m,k+q⟩
              = Σ_G' c*_{n,k}(G') c_{m,k+q}(G'+G)
```

**Code:** `scatter_Bamp` → `isc%rhotw(ig)`

---

## 2. GW Formulas

### Self-Energy Operator

```
Σ(r,r',ω) = i/(2π) ∫ G(r,r',ω+ω') W(r,r',ω') e^{iω'η} dω'
```

**Components:**
- `G(r,r',ω)` = Green's function
- `W(r,r',ω)` = Screened Coulomb interaction

### Screened Interaction

```
W(r,r',ω) = ∫ ε^{-1}(r,r'',ω) v(r'',r') dr''
```

**Code:** `X_par(iq)%blc(ig1,ig2,iw)` stores `ε^{-1} - 1`

### Matrix Element Form

```
⟨n,k|Σ(ω)|n,k⟩ = Σ_{m,q,G,G'} ρ*_{nm}(k,q,G) W_{GG'}(q,ω-ε_m) ρ_{nm}(k,q,G')
```

**Code:** `QP_ppa_cohsex.F`, lines 650-750

### Plasmon-Pole Approximation

```
W_{GG'}(q,ω) = δ_{GG'} v_G(q) + Ω²_{GG'}(q) / [ω² - ω²_{GG'}(q) + iη]
```

**Pole Determination:**
```
ω_{GG'}(q) = √[Ω²_{GG'}(q) / ε^{-1}_{GG'}(q,0) - 1]
```

**Code:**
- `X_par(iq)%blc(ig1,ig2,1)` = `Ω²` (residue)
- `X_par(iq)%blc(ig1,ig2,2)` = `ω` (pole energy)

### Correlation Self-Energy (PPA)

```
Σ^c_{n,k}(ω) = Σ_{m,q,G,G'} ρ*_{nm}(k,q,G) Ω²_{GG'}(q) / [ω - ε_m - ω_{GG'}(q) + iη] ρ_{nm}(k,q,G') f_m
```

**Code:**
```fortran
W_i = X_blc_p(ig1,ig2,1) / (Sc_W(i_qp)%p(iw) - E_kmq - X_blc_p(ig1,ig2,2) + cI*QP_G_damp)
```

### Exchange Self-Energy

```
Σ^x_{n,k} = -Σ_{m,q,G} ρ*_{nm}(k,q,G) v_G(q) ρ_{nm}(k,q,G) f_m
```

**Code:** `XCo_Hartree_Fock.F`

### COHSEX Approximation

**SEX (Screened Exchange):**
```
Σ^{SEX}_{n,k} = -Σ_{m,q,G,G'} ρ*_{nm}(k,q,G) W_{GG'}(q,0) ρ_{nm}(k,q,G') f_m
```

**COH (Coulomb Hole):**
```
Σ^{COH}_{n,k} = (1/2) Σ_{m,q,G,G'} ρ*_{nn}(k,0,G) [W_{GG'}(q,0) - v_G(q)δ_{GG'}] ρ_{nn}(k,0,G')
```

**Code:** `QP_ppa_cohsex.F`, lines 507-620

### Quasiparticle Energy

**First-Order:**
```
E^{QP}_{n,k} = ε^{DFT}_{n,k} + Z_{n,k} [⟨n,k|Σ(E^{QP}_{n,k})|n,k⟩ - V^{xc}_{n,k}]
```

**Linearized:**
```
E^{QP}_{n,k} ≈ ε^{DFT}_{n,k} + ⟨n,k|Σ(ε^{DFT}_{n,k})|n,k⟩ - V^{xc}_{n,k}
```

**Renormalization Factor:**
```
Z_{n,k} = [1 - ∂Σ/∂ω|_{ω=E^{QP}}]^{-1}
```

**Code:** `QP_Sc(i_qp,i_w)` stores self-energy

---

## 3. BSE Formulas

### BSE Eigenvalue Problem

```
(E_c - E_v) A^S_{vck} + Σ_{v'c'k'} K_{vck,v'c'k'} A^S_{v'c'k'} = Ω^S A^S_{vck}
```

**Indices:**
- `v, v'` = Valence bands
- `c, c'` = Conduction bands
- `k, k'` = k-points
- `S` = Exciton state index

**Code:** `BS_K_dim` = dimension, `BS_bands(1:4)` = band ranges

### BSE Kernel

```
K_{vck,v'c'k'} = K^{exch}_{vck,v'c'k'} + K^{dir}_{vck,v'c'k'}
```

### Exchange Term (Attractive)

```
K^{exch}_{vck,v'c'k'} = -δ_{kk'} Σ_G v_G(0) ρ_{vc}(k,0,G) ρ*_{v'c'}(k',0,G)
```

**Physical Meaning:** Direct Coulomb attraction between electron and hole

**Code:** `K_exchange_kernel.F`
```fortran
H_x = Σ_ig conjg(O_x(ig,i_Tp)) * O_x(ig,i_Tk) / bare_qpg(iq,ig)**2
```

### Direct Term (Screened)

```
K^{dir}_{vck,v'c'k'} = Σ_{G,G'} ρ_{vc}(k,q,G) W_{GG'}(q,0) ρ*_{v'c'}(k',q,G')
```

**Physical Meaning:** Screened Coulomb repulsion (reduces binding)

**Code:** `K_correlation_kernel_std.F`
```fortran
K_corr = Vstar_dot_V_gpu(BS_n_g_W, O2, O_times_W) * 4._SP * pi
```

### Resonant-Antiresonant Form

```
┌           ┐ ┌   ┐     ┌   ┐
│  R    C   │ │ A │     │ A │
│           │ │   │ = Ω │   │
│  C*  -R*  │ │ B │     │ B │
└           ┘ └   ┘     └   ┘
```

**Resonant Block:**
```
R_{vck,v'c'k'} = (E_c - E_v) δ_{vv'} δ_{cc'} δ_{kk'} + K_{vck,v'c'k'}
```

**Coupling Block:**
```
C_{vck,v'c'k'} = K^{coupling}_{vck,v'c'k'}
```

**Code:** `BS_K_coupling` enables coupling

### Tamm-Dancoff Approximation (TDA)

Neglect coupling (`C = 0`):
```
R A = Ω A
```

**Code:** Default unless `BSEmod="coupling"`

### Optical Absorption

```
ε_M(ω) = 1 - lim_{q→0} v(q) Σ_S |⟨S|ρ(q)|0⟩|² / (ω - Ω^S + iη)
```

**Oscillator Strength:**
```
|⟨S|ρ(q)|0⟩|² = |Σ_{vck} A^S_{vck} ρ_{vc}(k,q)|²
```

**Code:** `K_observables.F`

### Haydock Recursion

```
ε_M(ω) = 1 - |d|² / [ω - a_0 - b²_1/(ω - a_1 - b²_2/(ω - a_2 - ...))]
```

**Recursion:**
```
|ψ_{n+1}⟩ = H|ψ_n⟩ - a_n|ψ_n⟩ - b_n|ψ_{n-1}⟩
```

**Code:** `K_Haydock.F`

---

## 4. Symmetry Operations

### Symmetry Group

```
{S_i | τ_i},  i = 1, ..., nsym
```

- `S_i` = Rotation matrix (3×3)
- `τ_i` = Fractional translation

**Code:**
- `nsym` = Total symmetries
- `dl_sop(3,3,is)` = Real-space operations
- `rl_sop(3,3,is)` = Reciprocal-space operations
- `dl_tra(3,is)` = Translations

### k-Point Mapping

```
S_i k = k' + G
```

**Star of k:**
```
Star(k) = {S_i k | i = 1, ..., nsym}
```

**Code:**
- `nstar(ik)` = Size of star
- `star(ik,is)` = Symmetry mapping
- `sstar(ikbz,1:2)` = (IBZ index, symmetry)

### Wavefunction Transformation

```
ψ_{n,Sk}(r) = e^{iSk·τ} ψ_{n,k}(S^{-1}r)
```

**Reciprocal Space:**
```
c_{n,Sk}(G) = e^{iSk·τ} e^{iG·τ} c_{n,k}(S^{-1}G)
```

**Code:**
- `g_rot(ig,is)` = Rotated G-vector index
- `g_phs(ig,is)` = Phase factor `e^{iG·τ}`
- `WF_phases(ig,is,ib,ik,isp)` = Wavefunction phases

### Time-Reversal Symmetry

```
ψ_{n,-k}(r) = ψ*_{n,k}(r)
```

**Reciprocal Space:**
```
c_{n,-k}(G) = c*_{n,k}(-G)
```

**Code:**
- `i_time_rev = 1` if present
- Symmetries with `is > nsym/(i_time_rev+1)` include TR

### Spatial Inversion

```
I: r → -r,  k → -k,  G → -G
```

**Code:**
- `i_space_inv = 1` if present
- `inv_index` = Symmetry index of `-I`

### Small Group of k

```
Small_Group(k) = {S_i | S_i k = k + G}
```

**Code:**
- `grp_nsym(ik)` = Number in small group
- `grp_table(ik,is_grp)` = Mapping to full list

---

## 5. Code Variables

### Wavefunctions

| Variable | Description | Module |
|----------|-------------|--------|
| `WF%c(ig,ib,ik)` | Wavefunction coefficients | `mod_wave_func.F` |
| `wf_ng` | Number of G-vectors | `mod_wave_func.F` |
| `wf_igk(ig,ik)` | G-vector table | `mod_wave_func.F` |
| `wf_nc_k(ik)` | Components at k | `mod_wave_func.F` |

### Reciprocal Lattice

| Variable | Description | Module |
|----------|-------------|--------|
| `b(3,3)` | Reciprocal lattice vectors | `mod_R_lattice.F` |
| `g_vec(ig,3)` | G-vector coordinates | `mod_R_lattice.F` |
| `ng_vec` | Total G-vectors | `mod_R_lattice.F` |
| `g_rot(ig,is)` | Rotated G-vector | `mod_R_lattice.F` |
| `g_phs(ig,is)` | Phase factor | `mod_R_lattice.F` |
| `G_m_G(ig1,ig2)` | G-G' table | `mod_R_lattice.F` |

### k-Points

| Variable | Description | Module |
|----------|-------------|--------|
| `k%nibz` | IBZ k-points | `mod_R_lattice.F` |
| `k%nbz` | Full BZ k-points | `mod_R_lattice.F` |
| `k%pt(ik,3)` | IBZ k-coordinates | `mod_R_lattice.F` |
| `k%ptbz(ikbz,3)` | BZ k-coordinates | `mod_R_lattice.F` |
| `k%nstar(ik)` | Star size | `mod_R_lattice.F` |
| `k%sstar(ikbz,1:2)` | BZ→IBZ mapping | `mod_R_lattice.F` |

### Symmetries

| Variable | Description | Module |
|----------|-------------|--------|
| `nsym` | Total symmetries | `mod_D_lattice.F` |
| `dl_sop(3,3,is)` | Real-space operations | `mod_D_lattice.F` |
| `rl_sop(3,3,is)` | Reciprocal operations | `mod_D_lattice.F` |
| `dl_tra(3,is)` | Translations | `mod_D_lattice.F` |
| `i_time_rev` | Time-reversal flag | `mod_D_lattice.F` |
| `i_space_inv` | Inversion flag | `mod_D_lattice.F` |
| `sop_tab(is1,is2)` | Symmetry table | `mod_D_lattice.F` |
| `sop_inv(is)` | Inverse symmetry | `mod_D_lattice.F` |

### GW Variables

| Variable | Description | File |
|----------|-------------|------|
| `QP_Sc(i_qp,i_w)` | Self-energy | `mod_QP_m.F` |
| `QP_table(i_qp,1:3)` | (v,c,k) indices | `mod_QP_m.F` |
| `QP_n_G_bands(1:2)` | Band range | `mod_QP_m.F` |
| `X_par(iq)%blc(ig1,ig2,iw)` | Response function | `mod_X_m.F` |
| `X%ppaE` | Plasmon-pole energy | `mod_X_m.F` |
| `isc%rhotw(ig)` | Oscillator | `mod_collision_el.F` |

### BSE Variables

| Variable | Description | File |
|----------|-------------|------|
| `BS_K_dim` | Kernel dimension | `mod_BS.F` |
| `BS_bands(1:4)` | (v_min,v_max,c_min,c_max) | `mod_BS.F` |
| `BS_blk(iblk)%mat(iT1,iT2)` | Kernel matrix | `mod_BS.F` |
| `BS_blk(iblk)%O_c(ig,iT)` | Oscillators | `mod_BS.F` |
| `BS_res_K_exchange` | Exchange flag | `mod_BS.F` |
| `BS_res_K_corr` | Correlation flag | `mod_BS.F` |
| `BS_K_coupling` | Coupling flag | `mod_BS.F` |
| `BS_W(ig1,ig2,iq)` | Screened interaction | `mod_BS.F` |

### Coulomb Interaction

| Variable | Description | File |
|----------|-------------|------|
| `bare_qpg(iq,ig)` | \|q+G\| | `mod_R_lattice.F` |
| `cut_geometry` | Cutoff type | `mod_R_lattice.F` |
| `RIM_qpg(ig,iq,irand)` | RIM q-points | `mod_R_lattice.F` |

---

## Quick Formula Lookup

### Need to compute...

**Quasiparticle energy?**
→ `E^{QP} = ε^{DFT} + ⟨Σ(E^{QP})⟩ - V^{xc}`

**Optical absorption?**
→ `ε_M(ω) = 1 - Σ_S |⟨S|ρ|0⟩|²/(ω - Ω^S)`

**Oscillator strength?**
→ `ρ_{nm}(k,q,G) = ⟨n,k|e^{-i(q+G)·r}|m,k+q⟩`

**Screened interaction?**
→ `W = ε^{-1} v`

**BSE kernel?**
→ `K = K^{exch} + K^{dir}`

**Exchange term?**
→ `K^{exch} = -Σ_G v_G ρ ρ*`

**Direct term?**
→ `K^{dir} = Σ_{GG'} ρ W ρ*`

---

## Normalization Factors

| Quantity | Factor | Origin |
|----------|--------|--------|
| Wavefunction | `1/√Ω` | Volume normalization |
| Coulomb | `4π/\|q+G\|²` | Poisson equation |
| Self-energy | `1/(2π)` | Frequency integral |
| BSE correlation | `4π` | Coulomb normalization |
| Spin factor | `2` or `1` | `spin_occ` |
| BZ integration | `1/N_k` | k-point sampling |

---

## Common Approximations

| Approximation | Formula | When to Use |
|---------------|---------|-------------|
| **PPA** | `W(ω) = Ω²/(ω² - ω₀²)` | Standard GW |
| **COHSEX** | `W(ω=0)` | Static screening |
| **TDA** | `C = 0` in BSE | Most optical spectra |
| **Linearized QP** | `E^{QP} ≈ ε + ⟨Σ(ε)⟩ - V^{xc}` | First iteration |
| **Haydock** | Continued fraction | Large BSE matrices |

---

## Units and Constants

| Quantity | YAMBO Unit | Conversion |
|----------|------------|------------|
| Energy | Hartree (Ha) | 1 Ha = 27.2114 eV |
| Length | Bohr (a₀) | 1 a₀ = 0.529177 Å |
| k-points | 2π/a | Reciprocal lattice units |
| Time | ℏ/Ha | 1 ℏ/Ha = 24.2 as |

**Constants:**
- `HA2EV = 27.21138602` (Ha to eV)
- `pi = 3.14159265358979323846`
- `cI = (0, 1)` (imaginary unit)

---

## File Locations

| Topic | Main Files |
|-------|------------|
| **GW** | `src/qp/QP_ppa_cohsex.F`, `QP_real_axis.F` |
| **BSE** | `src/bse/K_kernel.F`, `K_exchange_kernel.F`, `K_correlation_kernel_std.F` |
| **Wavefunctions** | `src/modules/mod_wave_func.F`, `src/wf_and_fft/` |
| **Symmetries** | `src/modules/mod_D_lattice.F`, `src/bz_ops/` |
| **Oscillators** | `src/wf_and_fft/scatter_Bamp.F` |
| **Response** | `src/pol_function/X_irredux_residuals.F` |

---

**End of Quick Reference**