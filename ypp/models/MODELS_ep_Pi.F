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
subroutine MODELS_ep_Pi(k,E,px)
 !
 use pars,                ONLY:SP,cI
 use electrons,           ONLY:levels
 use stderr,              ONLY:STRING_same
 use R_lattice,           ONLY:bz_samp
 use D_lattice,           ONLY:Tel
 use units,               ONLY:HA2EV
 use YPP_models,          ONLY:MODEL_kmq_table,MODEL_K_fermi,MODEL_B_shift,E_jell
 use MODELS,              ONLY:MODEL_gkkp_kind,MODEL_E_ph,MODEL_ep_dV,MODEL_Nel_at_Ef
 use ELPH,                ONLY:GKKP,elph_branches,PH_freqs_sq
 use PHEL,                ONLY:PH_Q,PHEL_alloc,PHEL_qp,QPH
 use QP_m,                ONLY:QP_Sc_steps,l_QP_eval_GF,QP_G_damp,QP_G_er
 use vec_operate,         ONLY:iku_v_norm
 use com,                 ONLY:msg,com_compose_msg
 use interfaces,          ONLY:OCCUPATIONS_Fermi
 use functions,           ONLY:Fermi_fnc
 use LIVE_t,              ONLY:live_timing
 use parallel_m,          ONLY:myid,PP_indexes
 use parallel_int,        ONLY:PP_redux_wait
 use OUTPUT,              ONLY:OUTPUT_driver
 !
#include<memory.h>
 !
 type(bz_samp), intent(inout)   :: k
 type(levels ), intent(inout)   :: E
 type(PP_indexes), intent(in)   :: px
 !
 ! Work Space
 !
 integer       :: ik,ib,i_kmq,ib_kmq,is,iw,iq,iq_c(-1:1)
 complex(SP), allocatable :: OMS_ph(:),OMS_im_W(:),OMS_static(:)
 real(SP)      :: q_mod,E_k,E_kmq,f_k,f_kmq,OMS_single_q(2),Ef_dist,GKKP_me
 !
 ! Q and TODO
 integer       :: NQ,Q_todo(k%nibz)
 type(bz_samp) :: q
 !
 call section("=","E-P Pi (phonons)")
 !===================================
 ! ... 	q's and TODO list
 !-----------------------
 call MODELS_k_tables(E,k,q,NQ,Q_todo,px)
 !
 ! ... occupations
 !----------------
 Tel=0.!273./HA2KEL
 E%nk=k%nibz
 YAMBO_ALLOC(k%weights,(k%nibz))
 k%weights=1./float(k%nibz)
 call OCCUPATIONS_Fermi(E,k,"OCCUPATIONS")
 MODEL_Nel_at_Ef=0._SP
 Ef_dist=10.
 do ib=1,E%nb
   do ik=1,k%nibz
     if (abs(E%E(ib,ik,1)-E%E_fermi)<Ef_dist.and.E%f(ib,ik,1)>0.) then
       MODEL_K_fermi=iku_v_norm(k%pt(ik,:)+MODEL_B_shift(ib,ik,:))
       MODEL_Nel_at_Ef=E%f(ib,ik,1)
       Ef_dist=abs(E%E(ib,ik,1)-E%E_fermi)
     endif
   enddo
 enddo
 !
 ! ... Kinds and frequencies
 ! ... BOX corner
 !--------------------------
 PH_Q=Q_todo(NQ)
 YAMBO_ALLOC(OMS_ph,(1:q%nibz))
 YAMBO_ALLOC(OMS_im_W,(1:q%nibz))
 YAMBO_ALLOC(OMS_static,(1:q%nibz))
 OMS_ph=0._SP
 OMS_im_W=0._SP
 OMS_static=0._SP
 QP_Sc_steps=1000
 elph_branches=1
 QP_G_damp=0.001/HA2EV
 QP_G_er=(/0.,MODEL_E_ph*10./)
 YAMBO_ALLOC(PH_freqs_sq,(q%nibz,1))
 l_QP_eval_GF=.TRUE.
 call PHEL_energy_and_KINDS_setup(k)
 call PHEL_alloc( ) 
 !
 MODEL_gkkp_kind="Debye"
 !MODEL_gkkp_kind="Frohlich"
 call ELPH_model_gkkp(GKKP)
 call msg('sr',com_compose_msg(body="[MODEL] Nel@E_fermi (ph)"),MODEL_Nel_at_Ef)
 call msg('sr',com_compose_msg(body="[MODEL] dV (ph)"),MODEL_ep_dV*(HA2EV*1000.)**2,after_msg="[meV]")
 !
 ! The exact solution (zero temperature)
 !--------------------------------------
 call MODELS_ep_Pi_exact(q,NQ,Q_todo,iq_c)
 !
 ! ... Loop
 !---------
 call live_timing("E-P OMS (phonons)",px%n_of_elements(myid+1)*NQ)
 !
 do is=1,NQ
   iq=Q_todo(is)
   q_mod=iku_v_norm(q%pt(iq,:))
   !
   if (STRING_same(MODEL_gkkp_kind,"debye"    )) GKKP_me=2.*MODEL_ep_dV**2
   if (STRING_same(MODEL_gkkp_kind,"Frohlich" )) GKKP_me=2.*MODEL_ep_dV**2/q_mod**2.
   !
   do ib=1,E%nb
     do ik=1,k%nibz
       !
       if (.not.px%element_2D(ib,ik)) cycle
       !
       if (allocated(MODEL_kmq_table)) then
         ib_kmq=MODEL_kmq_table(ik,ib,is,1)
         i_kmq =MODEL_kmq_table(ik,ib,is,2)
         if (ib_kmq==0.or.i_kmq==0) then
           call live_timing(steps=1)
           cycle
         endif
         E_k=E%E(ib,ik,1)
         E_kmq=E%E(ib_kmq,i_kmq,1)
       else
         E_k  =E_jell(k%pt(ik,:))-E%E_fermi
         E_kmq=E_jell(k%pt(ik,:)-q%pt(iq,:))-E%E_fermi
       endif
       !
       f_k=Fermi_fnc(E_k,Tel)
       f_kmq=Fermi_fnc(E_kmq,Tel)
       !
       OMS_ph(iq)=OMS_ph(iq)        +GKKP_me*f_k/k%nibz*fraction(MODEL_E_ph+cI*QP_G_damp)
       !
       OMS_im_W(iq)=OMS_im_W(iq)    +GKKP_me*f_k/k%nibz*fraction(cI*MODEL_E_ph)
       !
       OMS_static(iq)=OMS_static(iq)+GKKP_me*f_k/k%nibz*fraction(cI*QP_G_damp)
       !
       if (is<NQ) cycle
       !
       do iw=1,QP_Sc_steps
         PHEL_qp%PI(1,iq,iw)=PHEL_qp%PI(1,iq,iw)+GKKP_me*f_k/k%nibz*fraction(QPH%W(iw))
       enddo
       !
       call live_timing(steps=1)
       !
     enddo
   enddo
   !
 enddo
 !
 call live_timing()
 call PP_redux_wait(OMS_static)
 call PP_redux_wait(OMS_ph)
 call PP_redux_wait(OMS_im_W)
 call PP_redux_wait(PHEL_qp%PI)
 !
 ! Report
 !-------
 ! ... all q
 ! 
 call OUTPUT_driver("q_mod_OMS",action="reset")
 call OUTPUT_driver("q_mod_OMS",action="open")
 do is=1,NQ
   iq=Q_todo(is)
   q_mod=iku_v_norm(q%pt(iq,:))
   call OUTPUT_driver("q_mod_OMS",TITLES=(/"|q|"/),R_VALUES=(/q_mod/))
   call OUTPUT_driver("q_mod_OMS",TITLES=(/"-Im[PI(Wo)]"/),R_VALUES=(/-aimag(OMS_ph(iq))/),UNIT="meV")
   call OUTPUT_driver("q_mod_OMS",TITLES=(/"Re[PI(Wo)]"/),R_VALUES=(/real(OMS_ph(iq)-OMS_static(iq))/),UNIT="meV")
   call OUTPUT_driver("q_mod_OMS",TITLES=(/"Re[PI(iWo)]"/),R_VALUES=(/real(OMS_im_W(iq)-OMS_static(iq))/),UNIT="meV")
   call OUTPUT_driver("q_mod_OMS",action="write")
 enddo
 call OUTPUT_driver("q_mod_OMS",action="close")
 !
 call PH_of(k)
 ! 
 iq=iq_c(1)
 OMS_single_q=(/real(OMS_static(iq)),aimag(OMS_static(iq))/)*HA2EV*1000.
 call msg('sr',com_compose_msg(body="[MODEL] OMS_static (ph)",post="(Re Im)"),OMS_single_q,after_msg="[meV]")
 OMS_single_q=(/real(OMS_ph(iq)),-aimag(OMS_ph(iq))/)*HA2EV*1000.
 call msg('sr',com_compose_msg(body="[MODEL] OMS@Wo (ph)",post="(Re -Im)"),OMS_single_q,after_msg="[meV]")
 OMS_single_q=(/real(OMS_ph(iq)-OMS_static(iq)),-aimag(OMS_ph(iq))/)*HA2EV*1000.
 call msg('sr',com_compose_msg(body="[MODEL] OMS@Wo-OMS_static (ph)",post="(Re -Im)"),OMS_single_q,after_msg="[meV]")
 OMS_single_q=(/real(OMS_im_W(iq)-OMS_static(iq)),aimag(OMS_im_W(iq))/)*HA2EV*1000.
 call msg('sr',com_compose_msg(body="[MODEL] OMS@iWo-OMS_static (ph)",post="(Re Im)"),OMS_single_q,after_msg="[meV]")
 !
 contains
   !
   function fraction(E)
     complex(SP) :: E
     complex(SP) :: fraction
     fraction=1./(E+E_k-E_kmq)-1./(E-E_k+E_kmq+cI*QP_G_damp)
   end function
   !
end subroutine MODELS_ep_Pi
