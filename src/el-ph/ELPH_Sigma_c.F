!
!        Copyright (C) 2000-2022 the YAMBO team
!              http://www.yambo-code.org
!
! Authors (see AUTHORS file for details): AM
! 
! This file is distributed under the terms of the GNU 
! General Public License. You can redistribute it and/or 
! modify it under the terms of the GNU General Public 
! License as published by the Free Software Foundation; 
! either version 2, or (at your option) any later version.
!
! This program is distributed in the hope that it will 
! be useful, but WITHOUT ANY WARRANTY; without even the 
! implied warranty of MERCHANTABILITY or FITNESS FOR A 
! PARTICULAR PURPOSE.  See the GNU General Public License 
! for more details.
!
! You should have received a copy of the GNU General Public 
! License along with this program; if not, write to the Free 
! Software Foundation, Inc., 59 Temple Place - Suite 330,Boston, 
! MA 02111-1307, USA or visit http://www.gnu.org/copyleft/gpl.txt.
!
subroutine ELPH_Sigma_c(en,k,q,qp)
 !
 ! This routine calculates the QP shifts due to el-ph intercation
 ! following the Allen-Cardona formulation (see for example 
 ! PRB 23, 1495 (1981) )
 !
 use pars,           ONLY:SP,schlen,pi,rZERO,cZERO
 use units,          ONLY:HA2EV,HA2THZ
 use parser_m,       ONLY:parser
 use frequency,      ONLY:w_samp,W_reset
 use electrons,      ONLY:levels
 use LIVE_t,         ONLY:live_timing
 use com,            ONLY:msg,com_compose_msg
 use functions,      ONLY:BZ_index
 use collision_el,   ONLY:elemental_collision
 use COLL_interfaces,ONLY:SCATTERING_GW_kinematics
 use drivers,        ONLY:l_elel_corr
 use parallel_int,   ONLY:PP_wait,PARALLEL_global_indexes
 use parallel_m,     ONLY:PAR_IND_Q_bz,PAR_Q_bz_index,PAR_IND_QP,&
&                         PAR_IND_Q_bz_ID,PAR_IND_G_b,PAR_IND_G_b_ID,PAR_IND_QP_ID,master_cpu,&
                          PAR_COM_Q_A2A,PAR_COM_Q_INDEX,myid
 use IO_int,         ONLY:io_control,IO_and_Messaging_switch
 use IO_m,           ONLY:manage_action,OP_RD,REP,RD_CL_IF_END,OP_WR,WR,WR_CL,&
&                         OP_WR_CL,OP_APP_CL,DUMP
 use QP_ctl_m,       ONLY:QP_apply
 use QP_m,           ONLY:QP_t,QP_G_damp,QP_Sc,QP_n_states,QP_table,&
&                         QP_dSc_steps,QP_dSc_delta,QP_solver,QP_Sc_steps,&
&                         On_Mass_Shell_approx,QP_time_order_sign
 use D_lattice,      ONLY:sop_inv,nsym,i_time_rev,sop_tab
 use R_lattice,      ONLY:bz_samp
 use ELPH,           ONLY:elph_nb,PH_freqs_sq,GKKP,ph_modes,PH_freqs,FineGd_E_kpq_components_reset,&
&                         QP_PH_n_G_bands,PH_W_debye,use_PH_DbGd,EkplusQ_mode, &
&                         elph_nQ,elph_use_q_grid,setup_k_plus_q_levels,elph_nQ_used,&
&                         E_kpq_sh_fact,gsqF_energy_steps,eval_G_using_KK,PH_qpt,ID_E_kpq,ID_E_kpq_obj, &
&                         elph_branches,QP_DW,QP_OMS_Fan,FAN_deltaE_treshold,l_GKKP_DB_is_expanded,l_GKKP_DB_exists
 use interfaces,     ONLY:QP_state_print,ELPH_alloc
 use interpolate,    ONLY:INTERPOLATE_is_serial,INTERPOLATION_coefficients,INTERP_obj,INTERP_shell_factor,&
&                         INTERPOLATE_is_quiet    
 use stderr,         ONLY:STRING_same
 use timing_m,       ONLY:timing
#if defined _MODELS
 use MODELS,        ONLY:l_MODEL_force_jellium
#endif
 !
#include<memory.h>
 !
 type(levels)  ::en
 type(bz_samp) ::k,q
 type(QP_t)    ::qp
 !
 ! WorkSpace  
 !
 integer          ::iq_db,iq_bz,iq_loop,iq_db_ref,ik,ib,ob,is,il,i_qp,i2,&
&                   ik_bz_gkkp,ib_gkkp,ob_gkkp,nq_to_sum,iq_mem,live_timing_steps
 type(w_samp)     ::Sc_W(qp%n_states)
 integer          ::io_err,ID,IO_ACT,ID_DG
 integer, external::io_ELPH,io_Double_Grid,io_gFsq
 character(schlen)::ch
 real(SP)         ::ph_E,elph_gkkp_sq,E_random_shift
 logical          ::l_WRgFsq,l_GF_from_CA,MULTIPLY_by_Qsquare
 real(SP), allocatable :: q_weight(:)
 type(elemental_collision) :: I
 ! 
 call timing('GW(e-p)',OPR='start')
 !
 ! Zeroing
 !
 do i_qp=1,qp%n_states
   call W_reset(Sc_W(i_qp))
 enddo
 QP_DW=rZERO
 QP_OMS_Fan=rZERO
 !
 if (     l_elel_corr) call section('+','Correlation: Phonon-mediated Self-energy')
 if (.not.l_elel_corr) call section('=','Correlation: Phonon-mediated Self-energy')
 !
 ! gFsq coefficients 2 DB ?
 !
 call parser('WRgFsq',l_WRgFsq)
 !
 ! Eval Green's function directly from Allen-Cardona expression ?
 !
 call parser('GF_from_CA',l_GF_from_CA)
 !
 ! Eval Green's functions using KK
 !
 eval_G_using_KK=trim(QP_solver)=='g'.and..not.l_GF_from_CA
 if (eval_G_using_KK) l_WRgFsq=.FALSE.
 !
 call k_build_up_BZ_tables(q)
 call k_build_up_BZ_tables(k)
 call k_expand(k)
 call k_ibz2bz(q,'i',.TRUE.)
 call k_ibz2bz(k,'i',.TRUE.)
 !
 if (QP_PH_n_G_bands(2)<=0.or.QP_PH_n_G_bands(2)>elph_nb) QP_PH_n_G_bands=(/1,elph_nb/)
 if (QP_PH_n_G_bands(1)<=0.or.QP_PH_n_G_bands(1)>elph_nb) QP_PH_n_G_bands=(/1,elph_nb/)
 !
 call msg('r', '[GW/El-Ph] Bands range       ',(/QP_PH_n_G_bands(1),QP_PH_n_G_bands(2)/))
 if (trim(QP_solver)=='n') &
&  call msg('r', '[GW/El-Ph] G damping         ',QP_G_damp*HA2EV,"[eV]")
 !
 ! QP_table -> report
 !
 call QP_state_print( )
 !
#if defined _MODELS
 ! Model e-p (init)
 ! ================
 call ELPH_model_init( )
#endif
 !
 ! ELPH DB
 ! ========
 if (STRING_same(GKKP%H,"dfpt")) call ELPH_databases_check(-1)
 !
 call msg('nr',com_compose_msg(body="El-Ph Hamiltonian"),GKKP%H)
 call msg('rn',com_compose_msg(body="BZ expanded"),l_GKKP_DB_is_expanded)
 !
 if (.not.l_GKKP_DB_exists.and.STRING_same(GKKP%H,"dfpt")) call error("GKKP database not found")
 !
 !Sc Energy points
 !
 if (trim(QP_solver)=='g') then
   !
   do i_qp=1,qp%n_states
     !
     Sc_W(i_qp)%n_freqs =QP_Sc_steps
     !
     call FREQUENCIES_Green_Function(i_qp,Sc_W(i_qp),en%E,.not.l_GF_from_CA)
     !
   enddo
   QP_Sc_steps      =Sc_W(1)%n_freqs
   gsqF_energy_steps=Sc_W(1)%n_freqs
   !
   if (.not.l_elel_corr) QP_Sc=cZERO
   !
   call msg('nr', '[GW/El-Ph] gsqF E range      ',Sc_W(1)%er*HA2EV,"[eV]")
   !
 else if (trim(QP_solver)=='n') then
   !
#if defined _MODELS
   if (l_MODEL_force_jellium) On_Mass_Shell_approx=.TRUE.
#endif
   !
   if (On_Mass_Shell_approx) QP_dSc_steps=1
   !
   do i_qp=1,qp%n_states
     Sc_W(i_qp)%n_freqs=QP_dSc_steps
     YAMBO_ALLOC(Sc_W(i_qp)%p,(Sc_W(i_qp)%n_freqs))
     forall (i2=1:QP_dSc_steps) Sc_W(i_qp)%p(i2)=&
&           en%E(QP_table(i_qp,1),QP_table(i_qp,3),1)+(i2-1)*QP_dSc_delta+&
&           cmplx(0.,QP_G_damp,SP)
   enddo
   !
   gsqF_energy_steps=QP_dSc_steps
   if (On_Mass_Shell_approx) gsqF_energy_steps=1
   !
 endif
 !
 ! Parallelization
 !-----------------
 call PARALLEL_global_indexes(en,k,q,"Self_Energy")
 !
 ! Note that only by using causal ordering it is correct to use 
 ! the KK to calculate the Green's function
 !
 if (trim(QP_solver)=='g')  QP_time_order_sign=1
 !
 ! Q ranges and Spherical RIM
 !============================
 !
 !             / set by ypp_ph     elph_use_q_grid=F
 ! elph_nQ = | 
 !             \ nqibz             elph_use_q_grid=T
 !
 !                  / <user defined>    elph_use_q_grid=F
 ! elph_nQ_used = | 
 !                  \ nqibz             elph_use_q_grid=T
 !
 !              / elph_nQ_used     elph_use_q_grid=F
 ! nq_to_sum = | 
 !              \ nqbz             elph_use_q_grid=T
 !
 if (     elph_use_q_grid) nq_to_sum=q%nbz
 if (.not.elph_use_q_grid) nq_to_sum=elph_nQ_used
 !
 YAMBO_ALLOC(q_weight,(nq_to_sum))
 !
 MULTIPLY_by_Qsquare=.TRUE.
#if defined _MODELS
 MULTIPLY_by_Qsquare=.FALSE.
#endif
 if (     elph_use_q_grid) call rim_integrate_elph("unit-cell",nq_to_sum,q%ptbz,              q_weight,2,MULTIPLY_by_Qsquare)
 if (.not.elph_use_q_grid) call rim_integrate_elph("sphere",   nq_to_sum,PH_qpt(:nq_to_sum,:),q_weight,2,MULTIPLY_by_Qsquare)
 !
 if(elph_nQ_used/=elph_nQ) call warning(" Number of q-used different from total number of q-points")
 !
 ! Check double-grid
 !-------------------
 !
 ! Fill the PH_E array
 !
 PH_freqs%nk=nq_to_sum
 PH_freqs%nb=ph_modes
 YAMBO_ALLOC(PH_freqs%E,(nq_to_sum,ph_modes,1))
 ! 
 call io_control(ACTION=OP_RD,COM=REP,MODE=DUMP,SEC=(/1,2/),ID=ID_DG)
 io_err=io_Double_Grid(PH_freqs,q,ID_DG,'phonons')
 !
 if(io_err==0) then
   if(elph_use_q_grid) then
     use_PH_DbGd=.TRUE.
     call ELPH_alloc("DGRID",GKKP)
   else
     call warning('PH-double-grid not yet compatible with Random q-grids and Eliashberg functions!')
     use_PH_DbGd=.FALSE.
   endif
 endif
 !
 ! Interpolate the E(k+q) energies for the double-grid
 !
 if(use_PH_DbGd.and.STRING_same(EkplusQ_mode,'interp')) then
   INTERPOLATE_is_serial=.TRUE.
   INTERPOLATE_is_quiet =.TRUE.
   INTERP_shell_factor  =E_kpq_sh_fact
   call INTERPOLATION_BZ_setup(k)
   INTERP_obj(ID_E_kpq_obj)%what="E(k+q)"
   call INTERPOLATION_coefficients(E=en,k=k,ID=ID_E_kpq,ID_obj=ID_E_kpq_obj)
   call ELPH_interpolate_E_at_k_plus_q(k,q,en,1)  ! I need them for the DW term
 endif
 !
#if defined _MODELS
 !
 ! Jellium Model
 !---------------
 !
 call ELPH_model_gkkp(GKKP)
 !
 ! Ad-Hoc integration of the Jellium Fan SE
 call ELPH_model_jellium(q,k,en,q_weight)
 !
#endif
 !
 ! Timing steps
 !--------------
 live_timing_steps=PAR_IND_QP%n_of_elements(PAR_IND_QP_ID+1)*&
&                  PAR_IND_Q_bz%n_of_elements(PAR_IND_Q_bz_ID+1)*&
&                  PAR_IND_G_b%n_of_elements(PAR_IND_G_b_ID+1)
 !
 call PP_wait
 !
 ! g^2F(w) residuals Allocation
 !
 call ELPH_alloc('gFsq')
 !
 iq_db_ref=0
 !
 do iq_loop=1,nq_to_sum
   !
   iq_db = iq_loop
   iq_bz = iq_loop
   if (elph_use_q_grid) then
     if (     l_GKKP_DB_is_expanded) iq_db=iq_bz
     if (.not.l_GKKP_DB_is_expanded) iq_db=q%sstar(iq_bz,1)
   endif
   !
   ! DB I/O can be skipped except at the gamma point which is used to define E_k_plus_q_at_gamma array
   !
   if (.not.PAR_IND_Q_bz%element_1D(iq_loop).and.iq_db>1) cycle
   iq_mem=PAR_Q_bz_index(iq_loop)
   !
   if (iq_db/=iabs(iq_db_ref)) then
     !
     if (STRING_same(GKKP%H,"DFPT")) then
       IO_ACT=manage_action(RD_CL_IF_END,iq_db,1,elph_nQ_used)
       if (iq_db==1) IO_ACT=OP_RD
       call io_control(ACTION=IO_ACT,SEC=(/iq_db+1/),ID=ID)
       if (     l_GKKP_DB_is_expanded) io_err=io_ELPH(ID,"gkkp_expanded")
       if (.not.l_GKKP_DB_is_expanded) io_err=io_ELPH(ID,"gkkp")
       if (io_err<0) call error('Missing Q-database')
     endif
     !
     if (.not.elph_use_q_grid.or.l_GKKP_DB_is_expanded) then
       !
       if (iq_loop==1) E_random_shift=GKKP%E_kpq(iq_db)%E(en%nbf(1),1,1)-en%E(en%nbf(1),1,1)
       !
       call setup_k_plus_q_levels(iq_db,E_random_shift)
       !
       call QP_apply((/1,elph_nb/),GKKP%E_kpq(iq_db),k,"G",msg_fmt=' ')
       !
     endif
     !
     ! I call live_timing here as in ioELPH the global_alloc() can 
     ! send a screen message about the allocated memory that can interferee
     ! with the live_timing hashes
     !
     if (iq_db_ref==0) call live_timing('El-Ph Sc [coeff]',live_timing_steps)
     !
     iq_db_ref=iq_db
     !
   endif
   !
   if (.not.PAR_IND_Q_bz%element_1D(iq_loop)) cycle
   !
   if (use_PH_DbGd.and.STRING_same(EkplusQ_mode,'interp').and.iq_bz/=1) call ELPH_interpolate_E_at_k_plus_q(k,q,en,iq_bz)
   !
   do i_qp=1,QP_n_states
     !
     if (.not.PAR_IND_QP%element_1D(i_qp)) cycle
     !
     do ob=QP_PH_n_G_bands(1),QP_PH_n_G_bands(2)
       !
       if (.not.PAR_IND_G_b%element_1D(ob)) cycle
       !
       if (elph_use_q_grid) then
         call SCATTERING_GW_kinematics(iq_bz,ob,I,k,q,QP_table(i_qp,:))
         if (l_GKKP_DB_is_expanded) I%qs=(/1,iq_bz,1/)
       else
         I%is=(/QP_table(i_qp,1),QP_table(i_qp,3),1,1/)
         I%os=(/ob,1,1,1/)
         I%qs=(/1,iq_loop,1/)
       endif
       !
       ik_bz_gkkp=BZ_index(I%is(2),k)
       ib_gkkp   =I%is(1)
       ob_gkkp   =I%os(1)
       !
       if (     elph_use_q_grid.and..not.l_GKKP_DB_is_expanded) then
         !
         ! When using a uniform Q grid I cycle on the q symmetries 
         ! as well. To rotate the gkkp m.e. I use:
         ! 
         ! gkkp_{I_need}= <k+Rq n'|dV_{SCF}/du^{Rq nu}|k n>=
         !                <(R^-1 k)+q n'|dV_{SCF}/du^{q nu}|(R^-1 k) n>= 
         !                gkkp(ik_bz,nu,n',n)
         !
         ! ik_bz=BZ_index(I%is(2),k)
         !
         ik_bz_gkkp=k%k_table(I%is(2),sop_inv(I%qs(3)))  
         !
         ! COMMENT: I do not have sop_tab(:,is) because is=1 (identity)
         ! 
         ! gkkp_{I_need}= <k+IRq n'|dV_{SCF}/du^{IRq nu}|k n>=
         !                [<(R^-1 S p)+q n|dV_{SCF}/du^{q nu}|(R^-1 S p) n'>]^*= 
         !                [gkkp(ik_bz,nu,n,n')]^*
         ! 
         ! with k + IRq = Sp 
         !
         if (I%qs(3)>nsym/(i_time_rev+1)) then
           ib_gkkp   =I%os(1)
           ob_gkkp   =I%is(1)
           !                                 R^-1                 S
           !                                 -------------------- --
           ik_bz_gkkp=k%k_table(I%os(2),sop_tab(sop_inv(I%qs(3)-nsym/2),I%os(3)))
         endif
         !
         ! k is in the IBZ and q is the PW_q (=-YAMBO_q)
         !
       endif
       !
#if defined _MODELS
       ik_bz_gkkp=1
#endif
       !
       do il=elph_branches(1),elph_branches(2)
         !
         ph_E=sqrt(abs(PH_freqs_sq(I%qs(2),il)))
         !
         ! Skip modes @ Gamma (1st point is always gamma, either with random
         ! or uniform grids, as it is needed to evaluate the DW factor) 
         !
         if (abs(ph_E)<FAN_deltaE_treshold) cycle
         !
         ! In the SE expression I have the m.e. 
         !
         !  <ib ik|g(q_YAMBO l r)|ob ik-q_YAMBO> = [<ob ik+q_PW|g(q_PW l r)|ib ik>]^* = 
         !                              elph_gkkp(il,ob_gkkp,ib_gkkp,ik_bz_gkkp)^*
         !
         ! with q_YAMBO = - q_PW
         !
         elph_gkkp_sq=real(conjg(GKKP%dVc(il,ob_gkkp,ib_gkkp,ik_bz_gkkp,1))*&
&                           GKKP%dVc(il,ob_gkkp,ib_gkkp,ik_bz_gkkp,1)/2._SP/ph_E,SP)
         !
         ! ELPH_GreenF evaluate real and imaginary part of the electron-phonon self-energy
         !
         call ELPH_GreenF(I,i_qp,iq_mem,il,elph_gkkp_sq,en,k,q,Sc_W(i_qp),q_weight(iq_bz))
         !
       enddo
       !
       call live_timing(steps=1)
       !
     enddo
     !
   enddo  ! i_qp loop
   !
   if(use_PH_DbGd.and.iq_loop/=1) call FineGd_E_kpq_components_reset(GKKP%E_dg_kpq(iq_loop))
   !
 enddo ! Q loop
 !
 call live_timing()
 !
 ! Debye energy
 !
 call msg('nr','[Ph] Debye energy         ',(/PH_W_debye*HA2EV,PH_W_debye*HA2THZ/),"[ev/ThZ]")
 !
 ! Here I use the Cardona-Allen g^2 F functions to evaluate their integrated value.
 ! I also calculate the full frequency dependent self-energy
 !
 call ELPH_gsqF_to_Sigma(en,q,l_GF_from_CA,Sc_W)
 !
 ! Dump on file gFsq coefficients 
 !
 if (l_WRgFsq) then
   !
   if (master_cpu) then
     call io_control(ACTION=OP_WR_CL,COM=REP,SEC=(/1/),ID=ID)
     io_err=io_gFsq(ID)
   endif
   call PP_wait()
   call IO_and_Messaging_switch("+io_out",CONDITION=PAR_COM_Q_A2A%CPU_id==0)
   do iq_loop=1,nq_to_sum
     if (.not.PAR_IND_Q_bz%element_1D(iq_loop)) cycle
     call io_control(ACTION=OP_APP_CL,COM=REP,SEC=(/iq_loop+1/),ID=ID)
     io_err=io_gFsq(ID)
   enddo
   call IO_and_Messaging_switch("+io_out",CONDITION=master_cpu)
   !
 endif
 !
 ! CLEAN
 !
 call ELPH_alloc('FREE')
 call k_ibz2bz(k,'d',.TRUE.)
 call k_ibz2bz(q,'d',.TRUE.)
 YAMBO_FREE(q_weight)
 do i_qp=1,qp%n_states
   call W_reset(Sc_W(i_qp))
 enddo
 call timing('GW(e-p)',OPR='stop')
 !
end subroutine
