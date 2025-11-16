# YAMBO Theory: Code Examples and Implementation Details {#yambo_theory_examples}

@page yambo_theory_examples YAMBO Theory Code Examples

**Practical code examples showing how theoretical formulas are implemented in YAMBO**

@tableofcontents

---

## Table of Contents

1. [Oscillator Strength Calculation](#oscillator-strength-calculation)
2. [GW Self-Energy Implementation](#gw-self-energy-implementation)
3. [BSE Kernel Construction](#bse-kernel-construction)
4. [Symmetry Operations](#symmetry-operations)
5. [Memory Layout Examples](#memory-layout-examples)

---

## 1. Oscillator Strength Calculation

### Theory

```
ρ_{nm}(k,q,G) = ⟨n,k|e^{-i(q+G)·r}|m,k+q⟩
              = Σ_G' c*_{n,k}(G') c_{m,k+q}(G'+G)
```

### Implementation: scatter_Bamp.F

```fortran
!==============================================================================
! Compute oscillator strength ρ_{nm}(k,q,G)
!==============================================================================
subroutine scatter_Bamp(isc)
  use pars,          ONLY:SP,cZERO
  use electrons,     ONLY:n_spinor
  use collision_el,  ONLY:elemental_collision
  use wave_func,     ONLY:WF
  use FFT_m,         ONLY:fft_size,fft_3d
  implicit none
  
  type(elemental_collision) :: isc
  
  ! Local variables
  integer     :: ib_n, ib_m, ik, ikpq, ig, ir, i_spinor
  complex(SP) :: wf_n(fft_size,n_spinor)
  complex(SP) :: wf_m(fft_size,n_spinor)
  complex(SP) :: rho_r(fft_size)
  
  ! Extract indices from collision structure
  ib_n  = isc%is(1)  ! Band n
  ik    = isc%is(2)  ! k-point
  ib_m  = isc%os(1)  ! Band m
  ikpq  = isc%os(2)  ! k+q point
  
  ! Initialize
  isc%rhotw = cZERO
  
  ! Loop over spinor components
  do i_spinor = 1, n_spinor
    
    ! STEP 1: Load wavefunctions in G-space
    ! ψ_n(k,G) stored in WF%c(ig,ib,ik)
    do ig = 1, isc%ngrho
      wf_n(ig,i_spinor) = WF%c(ig,ib_n,ik)
      wf_m(ig,i_spinor) = WF%c(ig,ib_m,ikpq)
    enddo
    
    ! STEP 2: Transform to real space via FFT
    ! ψ_n(k,r) = FFT[ψ_n(k,G)]
    call fft_3d(wf_n(:,i_spinor), fft_size, +1)  ! G→R
    call fft_3d(wf_m(:,i_spinor), fft_size, +1)  ! G→R
    
    ! STEP 3: Multiply in real space
    ! ρ(r) = ψ*_n(k,r) × ψ_m(k+q,r)
    do ir = 1, fft_size
      rho_r(ir) = conjg(wf_n(ir,i_spinor)) * wf_m(ir,i_spinor)
    enddo
    
    ! STEP 4: Transform back to G-space
    ! ρ(G) = FFT[ρ(r)]
    call fft_3d(rho_r, fft_size, -1)  ! R→G
    
    ! STEP 5: Store result
    ! Phase factor e^{-i(q+G)·r} is implicit in FFT
    do ig = 1, isc%ngrho
      isc%rhotw(ig) = isc%rhotw(ig) + rho_r(ig)
    enddo
    
  enddo
  
  ! Normalization
  isc%rhotw = isc%rhotw / real(fft_size, SP)
  
end subroutine scatter_Bamp
```

### Usage Example

```fortran
! Setup collision structure
type(elemental_collision) :: isc

! Define transition: band n=5 at k=10 → band m=8 at k+q=15
isc%is = (/5, 10, 1, 1/)  ! (band_n, k, symmetry, spin)
isc%os = (/8, 15, 1, 1/)  ! (band_m, k+q, symmetry, spin)
isc%qs = (/iq, iqibz, iqs/)  ! q-point info
isc%ngrho = wf_ng  ! Number of G-vectors

! Allocate
call elemental_collision_alloc(isc, NG=isc%ngrho, TITLE="Oscillator")

! Compute oscillator
call scatter_Bamp(isc)

! Result: isc%rhotw(ig) contains ρ_{nm}(k,q,G) for all G
```

---

## 2. GW Self-Energy Implementation

### Theory

**Plasmon-Pole Form:**
```
Σ^c_{n,k}(ω) = Σ_{m,q,G,G'} ρ*_{nm}(k,q,G) × Ω²_{GG'}(q)/(ω - ε_m - ω_{GG'}(q) + iη) × ρ_{nm}(k,q,G')
```

### Implementation: QP_ppa_cohsex.F

```fortran
!==============================================================================
! GW Self-Energy Calculation (Plasmon-Pole Approximation)
!==============================================================================
subroutine QP_ppa_cohsex(X,Xk,E,k,q,qp,Xw,GW_iter)
  use pars,          ONLY:SP,cZERO,cI,pi
  use QP_m,          ONLY:QP_t,QP_Sc,QP_table,QP_n_G_bands,QP_G_damp
  use X_m,           ONLY:X_t,X_par
  use collision_el,  ONLY:elemental_collision
  use R_lattice,     ONLY:qindx_S,bz_samp,G_m_G
  implicit none
  
  type(X_t)      :: X
  type(bz_samp)  :: Xk,k,q
  type(QP_t)     :: qp
  integer        :: GW_iter
  
  ! Local variables
  integer     :: i_qp, i_v, i_c, i_k, i_sp_pol
  integer     :: iqbz, iqibz, i_kmq, i_kmq_bz, ib
  integer     :: ig1, ig2, iw
  real(SP)    :: E_kmq, f_kmq
  complex(SP) :: W_i, Sigma_c
  type(elemental_collision) :: isc, iscp
  
  ! Initialize self-energy
  QP_Sc = cZERO
  
  !============================================================================
  ! MAIN LOOP: Over quasiparticle states
  !============================================================================
  do i_qp = 1, qp%n_states
    
    ! Extract QP state indices
    i_v = QP_table(i_qp,1)  ! Valence band
    i_c = QP_table(i_qp,2)  ! Conduction band
    i_k = QP_table(i_qp,3)  ! k-point
    i_sp_pol = spin(QP_table(i_qp,:))
    
    !--------------------------------------------------------------------------
    ! LOOP: Over q-points
    !--------------------------------------------------------------------------
    do iqbz = 1, q%nbz
      
      iqibz = q%sstar(iqbz,1)
      
      ! Determine k-q point
      i_kmq_bz = qindx_S(i_k,iqbz,1)
      i_kmq = k%sstar(i_kmq_bz,1)
      
      !------------------------------------------------------------------------
      ! LOOP: Over intermediate bands m
      !------------------------------------------------------------------------
      do ib = QP_n_G_bands(1), QP_n_G_bands(2)
        
        ! Energy and occupation of intermediate state
        E_kmq = E%E(ib,i_kmq,i_sp_pol)
        f_kmq = E%f(ib,i_kmq,i_sp_pol)
        
        !----------------------------------------------------------------------
        ! STEP 1: Compute oscillators ρ_{nm}(k,q,G)
        !----------------------------------------------------------------------
        
        ! Oscillator for valence band: ρ_{v,ib}(k,q,G)
        isc%is = (/i_v, i_k, 1, i_sp_pol/)
        isc%os = (/ib, i_kmq, 1, i_sp_pol/)
        isc%qs = (/iqbz, iqibz, 1/)
        call scatter_Bamp(isc)
        
        ! Oscillator for conduction band: ρ_{c,ib}(k,q,G)
        iscp%is = (/i_c, i_k, 1, i_sp_pol/)
        iscp%os = (/ib, i_kmq, 1, i_sp_pol/)
        iscp%qs = (/iqbz, iqibz, 1/)
        call scatter_Bamp(iscp)
        
        !----------------------------------------------------------------------
        ! STEP 2: Contract with screened interaction W
        !----------------------------------------------------------------------
        
        ! Loop over frequency points
        do iw = 1, QP_dSc_steps
          
          Sigma_c = cZERO
          
          ! Double loop over G-vectors
          do ig2 = X_par(iqibz)%cols(1), X_par(iqibz)%cols(2)
          do ig1 = X_par(iqibz)%rows(1), X_par(iqibz)%rows(2)
            
            !------------------------------------------------------------------
            ! FORMULA: W(ω) = Ω²/(ω² - ω₀² + iη)
            !------------------------------------------------------------------
            ! X_par(iq)%blc(ig1,ig2,1) = Ω² (residue)
            ! X_par(iq)%blc(ig1,ig2,2) = ω₀ (pole energy)
            
            W_i = X_par(iqibz)%blc(ig1,ig2,1) / &
                  (Sc_W(i_qp)%p(iw) - E_kmq - X_par(iqibz)%blc(ig1,ig2,2) + cI*QP_G_damp)
            
            !------------------------------------------------------------------
            ! FORMULA: Σ^c = Σ_{GG'} ρ*(G) W(GG') ρ(G')
            !------------------------------------------------------------------
            Sigma_c = Sigma_c + &
                      conjg(isc%rhotw(ig1)) * W_i * isc%rhotw(ig2) * &
                      isc%gamp(ig1,ig2)  ! Coulomb factor 4π/|q+G||q+G'|
            
          enddo
          enddo
          
          ! Multiply by occupation factor
          Sigma_c = Sigma_c * f_kmq
          
          ! Accumulate self-energy
          QP_Sc(i_qp,iw) = QP_Sc(i_qp,iw) + Sigma_c
          
        enddo  ! iw (frequency)
        
      enddo  ! ib (intermediate bands)
      
    enddo  ! iqbz (q-points)
    
  enddo  ! i_qp (QP states)
  
  ! Normalization factors
  QP_Sc = QP_Sc * 4._SP * pi / real(q%nbz, SP)
  
end subroutine QP_ppa_cohsex
```

### Quasiparticle Energy Correction

```fortran
!==============================================================================
! Solve for quasiparticle energy: E^{QP} = E^{DFT} + Σ(E^{QP}) - V^{xc}
!==============================================================================
subroutine QP_newton(qp, E, Xw)
  use pars,     ONLY:SP
  use QP_m,     ONLY:QP_t,QP_Sc,QP_table
  implicit none
  
  type(QP_t) :: qp
  
  integer     :: i_qp, iter, max_iter
  real(SP)    :: E_DFT, E_QP, E_QP_old, V_xc
  real(SP)    :: Sigma_E, dSigma_dE, Z_factor
  real(SP)    :: tol, error
  
  max_iter = 100
  tol = 1.E-5_SP
  
  do i_qp = 1, qp%n_states
    
    ! DFT eigenvalue
    E_DFT = qp%E_bare(i_qp)
    
    ! Exchange-correlation potential
    V_xc = qp%Vxc(i_qp)
    
    ! Initial guess
    E_QP = E_DFT
    
    ! Newton-Raphson iteration
    do iter = 1, max_iter
      
      E_QP_old = E_QP
      
      ! Interpolate self-energy at E_QP
      call interpolate_Sigma(i_qp, E_QP, Sigma_E, dSigma_dE)
      
      ! Renormalization factor: Z = [1 - ∂Σ/∂ω]^{-1}
      Z_factor = 1._SP / (1._SP - dSigma_dE)
      
      ! Newton step: E^{QP} = E^{DFT} + Z[Σ(E^{QP}) - V^{xc}]
      E_QP = E_DFT + Z_factor * (Sigma_E - V_xc)
      
      ! Check convergence
      error = abs(E_QP - E_QP_old)
      if (error < tol) exit
      
    enddo
    
    ! Store result
    qp%E(i_qp) = E_QP
    qp%Z(i_qp) = Z_factor
    
  enddo
  
end subroutine QP_newton
```

---

## 3. BSE Kernel Construction

### Theory

**Exchange Term:**
```
K^{exch}_{vck,v'c'k'} = -δ_{kk'} Σ_G v_G(0) ρ_{vc}(k,0,G) ρ*_{v'c'}(k',0,G)
```

**Direct Term:**
```
K^{dir}_{vck,v'c'k'} = Σ_{GG'} ρ_{vc}(k,q,G) W_{GG'}(q,0) ρ*_{v'c'}(k',q,G')
```

### Implementation: K_exchange_kernel.F

```fortran
!==============================================================================
! BSE Exchange Kernel (Resonant)
!==============================================================================
function K_exchange_kernel(iq, BS_n_g_exch, BS_T_grp_ip, i_Tp, &
                           BS_T_grp_ik, i_Tk) result(H_x)
  use pars,      ONLY:SP,cZERO
  use BS,        ONLY:BS_T_group
  use R_lattice, ONLY:bare_qpg
  use wrapper_omp, ONLY:Vstar_dot_V_omp
  implicit none
  
  integer,          intent(in) :: iq, BS_n_g_exch, i_Tp, i_Tk
  type(BS_T_group), intent(in) :: BS_T_grp_ip, BS_T_grp_ik
  complex(SP) :: H_x
  
  integer :: ig
  
  !============================================================================
  ! FORMULA: H_x = -Σ_G ρ*_{v'c'}(G) × [1/|G|²] × ρ_{vc}(G)
  !============================================================================
  
  H_x = cZERO
  
  ! Loop over G-vectors
  do ig = 1, BS_n_g_exch
    
    ! Oscillator for transition p: ρ_{v'c'}(k',0,G)
    ! Stored in: BS_T_grp_ip%O_x(ig,i_Tp)
    
    ! Oscillator for transition k: ρ_{vc}(k,0,G)
    ! Stored in: BS_T_grp_ik%O_x(ig,i_Tk)
    
    ! Coulomb interaction: v_G = 4π/|G|²
    ! Stored in: bare_qpg(iq,ig) = |q+G|
    
    H_x = H_x + conjg(BS_T_grp_ip%O_x(ig,i_Tp)) * &
                BS_T_grp_ik%O_x(ig,i_Tk) / &
                bare_qpg(iq,ig)**2
    
  enddo
  
  ! Negative sign for attractive interaction
  H_x = -H_x
  
  ! Alternative: Use optimized dot product
  ! H_x = -Vstar_dot_V_omp(BS_n_g_exch, &
  !                        BS_T_grp_ip%O_x(:,i_Tp), &
  !                        BS_T_grp_ik%O_x(:,i_Tk) / bare_qpg(iq,:)**2)
  
end function K_exchange_kernel
```

### Implementation: K_correlation_kernel_std.F

```fortran
!==============================================================================
! BSE Correlation Kernel (Resonant)
!==============================================================================
function K_correlation_kernel_std(i_block, i_p, i_pmq, &
                                  i_k_s, i_kp_s, i_n_k, i_n_p, &
                                  i_kmq_s, i_kp_mq_s, i_m_k, i_m_p, &
                                  i_kmq_t, i_pmq_t, &
                                  i_k_sp_pol_n, i_p_sp_pol_n, &
                                  i_k_sp_pol_m, i_p_sp_pol_m, &
                                  iq_W, iq_W_s, ig_W, i_k_s_m1, &
                                  iq_W_s_mq, ig_W_mq, i_kmq_s_m1, &
                                  BS_n_g_W, O1, O2, O_times_W) result(H_c)
  use pars,      ONLY:SP,cZERO,pi
  use BS,        ONLY:BS_blk,BS_W,BS_W_is_diagonal,WF_phase
  use R_lattice, ONLY:G_m_G,g_rot,g_phs
  use wrapper,   ONLY:Vstar_dot_V_gpu
  use devxlib,   ONLY:devxlib_xgemv_gpu
  implicit none
  
  integer,     intent(in) :: i_block, i_p, i_pmq
  integer,     intent(in) :: i_k_s, i_kp_s, i_n_k, i_n_p
  integer,     intent(in) :: i_kmq_s, i_kp_mq_s, i_m_k, i_m_p
  integer,     intent(in) :: i_kmq_t, i_pmq_t
  integer,     intent(in) :: i_k_sp_pol_n, i_p_sp_pol_n
  integer,     intent(in) :: i_k_sp_pol_m, i_p_sp_pol_m
  integer,     intent(in) :: iq_W, iq_W_s, ig_W, i_k_s_m1
  integer,     intent(in) :: iq_W_s_mq, ig_W_mq, i_kmq_s_m1
  integer,     intent(in) :: BS_n_g_W
  complex(SP), intent(inout) :: O1(BS_n_g_W), O2(BS_n_g_W), O_times_W(BS_n_g_W)
  complex(SP) :: H_c
  
  integer     :: iO1, i_block_1, iO2, i_block_2
  integer     :: i_g1, i_g2, i_g3, i_g2p, i_g3p
  complex(SP) :: PHASE_1, PHASE_2, gphase1, gphase2
  
  !============================================================================
  ! STEP 1: Apply symmetry operations to oscillators
  !============================================================================
  
  ! Get oscillator indices from table
  iO1 = BS_blk(i_block)%O_table(1,i_kp_s,1,1,i_n_k,i_n_p,i_k_sp_pol_n)
  i_block_1 = BS_blk(i_block)%O_table(2,i_kp_s,1,1,i_n_k,i_n_p,i_k_sp_pol_n)
  
  iO2 = BS_blk(i_block)%O_table(1,i_kp_mq_s,i_kmq_t,i_pmq_t,i_m_k,i_m_p,i_k_sp_pol_m)
  i_block_2 = BS_blk(i_block)%O_table(2,i_kp_mq_s,i_kmq_t,i_pmq_t,i_m_k,i_m_p,i_k_sp_pol_m)
  
  ! Phase factors for non-symmorphic symmetries
  PHASE_1 = WF_phase(i_p,i_kp_s,i_n_p,i_p_sp_pol_n)
  PHASE_2 = WF_phase(i_pmq,i_kp_mq_s,i_m_p,i_p_sp_pol_m)
  if (PHASE_1 == cZERO .or. PHASE_1 == -99._SP) PHASE_1 = 1._SP
  if (PHASE_2 == cZERO .or. PHASE_2 == -99._SP) PHASE_2 = 1._SP
  
  ! Apply symmetry operations to oscillators
  do i_g1 = 1, BS_n_g_W
    
    ! Rotate G-vectors and apply phases
    i_g2 = G_m_G(g_rot(i_g1,iq_W_s), ig_W)
    i_g3 = G_m_G(g_rot(i_g1,iq_W_s_mq), ig_W_mq)
    
    gphase1 = cmplx(cos(g_phs(i_g2,iq_W_s)), sin(g_phs(i_g2,iq_W_s)))
    gphase2 = cmplx(cos(g_phs(i_g3,iq_W_s_mq)), sin(g_phs(i_g3,iq_W_s_mq)))
    
    i_g2p = g_rot(i_g2, i_k_s_m1)
    i_g3p = g_rot(i_g3, i_kmq_s_m1)
    
    gphase1 = cmplx(cos(g_phs(i_g2p,i_k_s_m1)), sin(g_phs(i_g2p,i_k_s_m1))) * gphase1
    gphase2 = cmplx(cos(g_phs(i_g3p,i_kmq_s_m1)), sin(g_phs(i_g3p,i_kmq_s_m1))) * gphase2
    
    ! Symmetrized oscillators
    O1(i_g1) = BS_blk(i_block_1)%O_c(i_g2p,iO1) * PHASE_1 * gphase1
    O2(i_g1) = BS_blk(i_block_2)%O_c(i_g3p,iO2) * PHASE_2 * gphase2
    
  enddo
  
  !============================================================================
  ! STEP 2: Contract with screened interaction W
  !============================================================================
  
  if (BS_W_is_diagonal) then
    
    ! Diagonal W: O_times_W = W(G) × O1(G)
    do i_g1 = 1, BS_n_g_W
      O_times_W(i_g1) = BS_W(i_g1,1,iq_W) * O1(i_g1)
    enddo
    
  else
    
    ! Full W matrix: O_times_W = Σ_G' W(G,G') × O1(G')
    call devxlib_xgemv_gpu('T', BS_n_g_W, BS_n_g_W, &
                           (1._SP,0._SP), &
                           BS_W(:,:,iq_W), BS_n_g_W, &
                           O1, 1, &
                           (0._SP,0._SP), &
                           O_times_W, 1)
    
  endif
  
  !============================================================================
  ! STEP 3: Final contraction: H_c = Σ_G O2*(G) × O_times_W(G)
  !============================================================================
  
  H_c = Vstar_dot_V_gpu(BS_n_g_W, O2, O_times_W) * 4._SP * pi
  
end function K_correlation_kernel_std
```

### Main Kernel Loop: K_kernel.F

```fortran
!==============================================================================
! Construct BSE Kernel Matrix
!==============================================================================
subroutine K_kernel(iq, Ken, Xk, q, X, Xw, W_bss)
  use pars,     ONLY:SP,pi,cZERO
  use BS,       ONLY:BS_K_dim,BS_blk,BS_res_K_exchange,BS_res_K_corr
  implicit none
  
  integer :: iq
  
  ! Local variables
  integer     :: i_Tk, i_Tp, i_block
  integer     :: i_v_k, i_c_k, i_k
  integer     :: i_v_p, i_c_p, i_p
  complex(SP) :: H_x, H_c, BS_mat_element
  
  ! Normalization factor
  real(SP) :: Co
  Co = 4._SP * pi / DL_vol / real(q%nbz, SP)
  
  !============================================================================
  ! MAIN LOOP: Construct kernel matrix
  !============================================================================
  
  i_block = 1
  
  ! Loop over transitions (rows)
  do i_Tk = 1, BS_K_dim
    
    ! Extract transition indices
    i_v_k = BS_blk(i_block)%table(i_Tk,1)  ! Valence band
    i_c_k = BS_blk(i_block)%table(i_Tk,2)  ! Conduction band
    i_k   = BS_blk(i_block)%table(i_Tk,3)  ! k-point
    
    ! Loop over transitions (columns)
    do i_Tp = 1, BS_K_dim
      
      i_v_p = BS_blk(i_block)%table(i_Tp,1)
      i_c_p = BS_blk(i_block)%table(i_Tp,2)
      i_p   = BS_blk(i_block)%table(i_Tp,3)
      
      BS_mat_element = cZERO
      
      !------------------------------------------------------------------------
      ! Exchange term (attractive)
      !------------------------------------------------------------------------
      if (BS_res_K_exchange) then
        
        H_x = K_exchange_kernel(iq, BS_n_g_exch, &
                                BS_T_grp(i_p), i_Tp, &
                                BS_T_grp(i_k), i_Tk)
        
        BS_mat_element = BS_mat_element + H_x * Co
        
      endif
      
      !------------------------------------------------------------------------
      ! Correlation term (screened)
      !------------------------------------------------------------------------
      if (BS_res_K_corr) then
        
        H_c = K_correlation_kernel_std(i_block, i_p, i_pmq, &
                                       i_k_s, i_kp_s, i_v_k, i_v_p, &
                                       i_kmq_s, i_kp_mq_s, i_c_k, i_c_p, &
                                       i_kmq_t, i_pmq_t, &
                                       i_k_sp_pol_v, i_p_sp_pol_v, &
                                       i_k_sp_pol_c, i_p_sp_pol_c, &
                                       iq_W, iq_W_s, ig_W, i_k_s_m1, &
                                       iq_W_s_mq, ig_W_mq, i_kmq_s_m1, &
                                       BS_n_g_W, O1, O2, O_times_W)
        
        BS_mat_element = BS_mat_element + H_c * Co
        
      endif
      
      !------------------------------------------------------------------------
      ! Store kernel element
      !------------------------------------------------------------------------
      BS_blk(i_block)%mat(i_Tk,i_Tp) = BS_mat_element
      
    enddo  ! i_Tp
    
  enddo  ! i_Tk
  
  !============================================================================
  ! Add diagonal (transition energies)
  !============================================================================
  call K_diagonal(Ken, BS_blk(i_block))
  
end subroutine K_kernel
```

---

## 4. Symmetry Operations

### Theory

```
ψ_{n,Sk}(r) = e^{iSk·τ} ψ_{n,k}(S^{-1}r)

In reciprocal space:
c_{n,Sk}(G) = e^{iSk·τ} e^{iG·τ} c_{n,k}(S^{-1}G)
```

### Implementation: WF_apply_symm.F

```fortran
!==============================================================================
! Apply symmetry operation to wavefunction
!==============================================================================
subroutine WF_apply_symm(WF_in, WF_out, ik_in, ik_out, is_symm)
  use pars,      ONLY:SP,cZERO
  use wave_func, ONLY:WAVEs,wf_igk,wf_nc_k
  use R_lattice, ONLY:g_rot,g_phs
  use D_lattice, ONLY:dl_tra
  implicit none
  
  type(WAVEs), intent(in)  :: WF_in
  type(WAVEs), intent(out) :: WF_out
  integer,     intent(in)  :: ik_in, ik_out, is_symm
  
  ! Local variables
  integer     :: ib, ig, ig_rot, ig_out
  real(SP)    :: k_in(3), k_out(3), tau(3)
  complex(SP) :: phase_k, phase_G, total_phase
  
  ! Get k-points
  k_in  = k%pt(ik_in,:)
  k_out = k%pt(ik_out,:)
  
  ! Get translation vector
  tau = dl_tra(:,is_symm)
  
  ! k-dependent phase: e^{iSk·τ}
  phase_k = exp(cI * dot_product(k_out, tau))
  
  ! Loop over bands
  do ib = WF_in%b(1), WF_in%b(2)
    
    WF_out%c(:,ib,ik_out) = cZERO
    
    ! Loop over G-vectors
    do ig = 1, wf_nc_k(ik_in)
      
      ! Rotate G-vector: S^{-1}G
      ig_rot = g_rot(ig,is_symm)
      
      ! G-dependent phase: e^{iG·τ}
      phase_G = cmplx(cos(g_phs(ig_rot,is_symm)), &
                      sin(g_phs(ig_rot,is_symm)))
      
      ! Total phase
      total_phase = phase_k * phase_G
      
      ! Find output G-vector index
      ig_out = wf_igk(ig_rot,ik_out)
      
      ! Apply symmetry: c_{n,Sk}(G) = e^{iSk·τ} e^{iG·τ} c_{n,k}(S^{-1}G)
      WF_out%c(ig_out,ib,ik_out) = total_phase * WF_in%c(ig,ib,ik_in)
      
    enddo
    
  enddo
  
end subroutine WF_apply_symm
```

### k-Point Mapping

```fortran
!==============================================================================
! Map k-point from BZ to IBZ using symmetries
!==============================================================================
subroutine k_ibz_to_bz(k_ibz, ik_ibz, ik_bz, is_symm)
  use R_lattice, ONLY:bz_samp,rl_sop
  implicit none
  
  type(bz_samp), intent(in)  :: k_ibz
  integer,       intent(in)  :: ik_ibz
  integer,       intent(out) :: ik_bz, is_symm
  
  real(SP) :: k_in(3), k_out(3), k_rot(3)
  integer  :: is, ikbz
  real(SP) :: tol
  
  tol = 1.E-5_SP
  
  ! Get IBZ k-point
  k_in = k_ibz%pt(ik_ibz,:)
  
  ! Loop over symmetries
  do is = 1, nsym
    
    ! Rotate k-point: k_rot = S × k_in
    k_rot = matmul(rl_sop(:,:,is), k_in)
    
    ! Bring back to first BZ (modulo G)
    k_rot = k_rot - nint(k_rot)
    
    ! Search in BZ
    do ikbz = 1, k_ibz%nbz
      
      k_out = k_ibz%ptbz(ikbz,:)
      
      ! Check if k_rot = k_out (modulo G)
      if (all(abs(k_rot - k_out) < tol)) then
        ik_bz = ikbz
        is_symm = is
        return
      endif
      
    enddo
    
  enddo
  
  ! Should never reach here
  call error('k-point not found in BZ')
  
end subroutine k_ibz_to_bz
```

### Star of k-point

```fortran
!==============================================================================
! Generate star of k-point
!==============================================================================
subroutine k_build_star(k, ik_ibz)
  use R_lattice, ONLY:bz_samp,rl_sop,nsym
  implicit none
  
  type(bz_samp), intent(inout) :: k
  integer,       intent(in)    :: ik_ibz
  
  real(SP) :: k_in(3), k_rot(3), k_star(3,nsym)
  integer  :: is, n_star, i_star
  logical  :: is_new
  real(SP) :: tol
  
  tol = 1.E-5_SP
  
  ! Get IBZ k-point
  k_in = k%pt(ik_ibz,:)
  
  n_star = 0
  
  ! Loop over symmetries
  do is = 1, nsym
    
    ! Rotate k-point
    k_rot = matmul(rl_sop(:,:,is), k_in)
    k_rot = k_rot - nint(k_rot)  ! Bring to first BZ
    
    ! Check if already in star
    is_new = .true.
    do i_star = 1, n_star
      if (all(abs(k_rot - k_star(:,i_star)) < tol)) then
        is_new = .false.
        exit
      endif
    enddo
    
    ! Add to star if new
    if (is_new) then
      n_star = n_star + 1
      k_star(:,n_star) = k_rot
      k%star(ik_ibz,n_star) = is
    endif
    
  enddo
  
  ! Store star size
  k%nstar(ik_ibz) = n_star
  
end subroutine k_build_star
```

---

## 5. Memory Layout Examples

### Wavefunction Access Pattern

```fortran
!==============================================================================
! Example: Access wavefunction coefficients
!==============================================================================
program wavefunction_access
  use wave_func, ONLY:WF,wf_igk,wf_nc_k
  implicit none
  
  integer     :: ib, ik, ig, ig_vec
  complex(SP) :: coeff
  real(SP)    :: norm
  
  ! Example: Get coefficient for band 5, k-point 10, G-vector 50
  ib = 5
  ik = 10
  ig = 50
  
  ! Direct access
  coeff = WF%c(ig,ib,ik)
  
  ! Get actual G-vector index
  ig_vec = wf_igk(ig,ik)
  
  ! Compute norm of wavefunction
  norm = 0._SP
  do ig = 1, wf_nc_k(ik)
    norm = norm + abs(WF%c(ig,ib,ik))**2
  enddo
  
  print *, 'Wavefunction norm:', norm
  print *, 'Should be close to 1.0'
  
end program wavefunction_access
```

### Response Function Access

```fortran
!==============================================================================
! Example: Access inverse dielectric function
!==============================================================================
program response_access
  use X_m, ONLY:X_par
  implicit none
  
  integer     :: iq, ig1, ig2, iw
  complex(SP) :: eps_inv
  
  ! Example: Get ε^{-1}(q=1, G=10, G'=20, ω=1)
  iq = 1
  ig1 = 10
  ig2 = 20
  iw = 1
  
  ! Check if in local range
  if (ig1 >= X_par(iq)%rows(1) .and. ig1 <= X_par(iq)%rows(2) .and. &
      ig2 >= X_par(iq)%cols(1) .and. ig2 <= X_par(iq)%cols(2)) then
    
    ! Access element
    eps_inv = X_par(iq)%blc(ig1,ig2,iw)
    
    print *, 'ε^{-1}(q,G,G'',ω) =', eps_inv
    
  else
    
    print *, 'Element not in local range'
    
  endif
  
end program response_access
```

### BSE Kernel Access

```fortran
!==============================================================================
! Example: Access BSE kernel matrix element
!==============================================================================
program bse_kernel_access
  use BS, ONLY:BS_blk,BS_K_dim
  implicit none
  
  integer     :: i_block, i_Tk, i_Tp
  integer     :: i_v_k, i_c_k, i_k
  integer     :: i_v_p, i_c_p, i_p
  complex(SP) :: K_element
  
  i_block = 1
  
  ! Example: Get kernel element for transitions
  ! Transition k: v=4, c=5, k=10
  ! Transition p: v=4, c=5, k=15
  
  ! Find transition indices
  do i_Tk = 1, BS_K_dim
    i_v_k = BS_blk(i_block)%table(i_Tk,1)
    i_c_k = BS_blk(i_block)%table(i_Tk,2)
    i_k   = BS_blk(i_block)%table(i_Tk,3)
    if (i_v_k == 4 .and. i_c_k == 5 .and. i_k == 10) exit
  enddo
  
  do i_Tp = 1, BS_K_dim
    i_v_p = BS_blk(i_block)%table(i_Tp,1)
    i_c_p = BS_blk(i_block)%table(i_Tp,2)
    i_p   = BS_blk(i_block)%table(i_Tp,3)
    if (i_v_p == 4 .and. i_c_p == 5 .and. i_p == 15) exit
  enddo
  
  ! Access kernel element
  K_element = BS_blk(i_block)%mat(i_Tk,i_Tp)
  
  print *, 'K(vck,v''c''k'') =', K_element
  
end program bse_kernel_access
```

---

## Summary: Key Code Patterns

### 1. Oscillator Calculation Pattern

```fortran
! Setup collision
isc%is = (/band_n, k_in, 1, spin/)
isc%os = (/band_m, k_out, 1, spin/)
isc%qs = (/iq, iqibz, iqs/)

! Compute
call scatter_Bamp(isc)

! Result in: isc%rhotw(ig)
```

### 2. GW Self-Energy Pattern

```fortran
! Loop structure
do i_qp = 1, n_QP_states
  do iq = 1, n_q_points
    do ib = 1, n_bands
      
      ! Compute oscillators
      call scatter_Bamp(isc)
      
      ! Contract with W
      do ig1 = 1, ng
      do ig2 = 1, ng
        W_i = X_par(iq)%blc(ig1,ig2,1) / (omega - E_ib - X_par(iq)%blc(ig1,ig2,2))
        Sigma = Sigma + conjg(isc%rhotw(ig1)) * W_i * isc%rhotw(ig2)
      enddo
      enddo
      
    enddo
  enddo
enddo
```

### 3. BSE Kernel Pattern

```fortran
! Loop structure
do i_Tk = 1, N_transitions
  do i_Tp = 1, N_transitions
    
    ! Exchange
    H_x = -Σ_G conjg(O_p(G)) * O_k(G) / |G|²
    
    ! Correlation
    H_c = Σ_{GG'} conjg(O_p(G)) * W(G,G') * O_k(G')
    
    ! Store
    K(i_Tk,i_Tp) = H_x + H_c
    
  enddo
enddo
```

### 4. Symmetry Application Pattern

```fortran
! Apply symmetry to wavefunction
do ig = 1, ng
  ig_rot = g_rot(ig,is)
  phase = exp(cI * (k_phase + g_phs(ig_rot,is)))
  WF_out(ig_rot) = phase * WF_in(ig)
enddo
```

---

**End of Code Examples**