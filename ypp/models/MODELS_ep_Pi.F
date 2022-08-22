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
 use electrons,           ONLY:levels,nel
 use R_lattice,           ONLY:bz_samp
 use D_lattice,           ONLY:Tel
 use units,               ONLY:HA2EV,HA2KEL
 use MODELS,              ONLY:MODEL_gkkp_kind,MODEL_E_ph,MODEL_ep_dV,MODEL_effective_mass,MODEL_Nel_at_Ef
 use ELPH,                ONLY:GKKP,elph_branches,PH_freqs_sq
 use PHEL,                ONLY:PH_Q,PHEL_alloc,PHEL_qp,QPH
 use QP_m,                ONLY:QP_Sc_steps,l_QP_eval_GF,QP_G_damp,QP_G_er
 use vec_operate,         ONLY:iku_v_norm,sort
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
 integer     :: ik,ib,Q_index(k%nibz),iq,Nq,is,Q_is_todo(k%nibz),iw
 real(SP)    :: q_mod,k_m_q(k%nibz),q(3),k_mod,f_kmq,f_k,E_k,E_kmq,OMS_single_q(2)
 complex(SP) :: OMS_ph(k%nibz),OMS_im_W(k%nibz),OMS_static(k%nibz)
 !
 call section("=","E-P Pi (phonons)")
 !===================================
 !
 ! ... occupations
 !----------------
 Tel=273./HA2KEL
 E%nk=k%nibz
 YAMBO_ALLOC(k%weights,(k%nibz))
 k%weights=1./float(k%nibz)
 call OCCUPATIONS_Fermi(E,k,"OCCUPATIONS")
 MODEL_Nel_at_Ef=0._SP
 do ib=1,E%nb
   do ik=1,k%nibz
     if (abs(E%E(ib,ik,1))<Tel) MODEL_Nel_at_Ef = MODEL_Nel_at_Ef+E%f(ib,ik,1)/float(k%nibz)
   enddo
 enddo
 MODEL_Nel_at_Ef=nel
 !
 ! ... 	q's and TODO list
 !-----------------------
 do ik=1,k%nibz
   k_m_q(ik)=iku_v_norm(k%pt(ik,:)-k%pt(1,:))
 enddo
 call sort(k_m_q,indx=Q_index)
 Q_is_todo=0
 do is=2,k%nibz
   if (k_m_q(is)-k_m_q(is-1) > 1.E-6) Q_is_todo(is)=1
 enddo
 !
 ! ... Kinds and frequencies
 ! ... BOX corner
 !--------------------------
 PH_Q=Q_index(k%nibz)
 OMS_ph=0._SP
 OMS_im_W=0._SP
 OMS_static=0._SP
 QP_Sc_steps=1000
 elph_branches=1
 QP_G_damp=0.005/HA2EV
 QP_G_er=(/0.,MODEL_E_ph*10./)
 YAMBO_ALLOC(PH_freqs_sq,(k%nibz,1))
 l_QP_eval_GF=.TRUE.
 call PHEL_energy_and_KINDS_setup(k)
 call PHEL_alloc( ) 
 !
 MODEL_gkkp_kind="Debye"
 call ELPH_model_gkkp(GKKP)
 !
 ! ... Loop
 !---------
 Nq=count(Q_is_todo==1)
 call live_timing("E-P OMS (phonons)",px%n_of_elements(myid+1)*Nq)
 !
 do is=1,k%nibz
   !
   if (Q_is_todo(is)==0) cycle
   !
   iq=Q_index(is)
   q=k%pt(iq,:)-k%pt(1,:)
   !
   do ib=1,E%nb
     do ik=1,k%nibz
       !
       if (.not.px%element_2D(ib,ik)) cycle
       !
       k_mod=iku_v_norm(k%pt(ik,:))
       !
       E_k=E%E(ib,ik,1)
       E_kmq=iku_v_norm(k%pt(ik,:)-q)**2./2./MODEL_effective_mass-E%E_fermi
       f_k=Fermi_fnc(E_k,Tel)
       f_kmq=Fermi_fnc(E_kmq,Tel)
       !
       OMS_ph(iq)=OMS_ph(iq)+MODEL_ep_dV**2/k%nibz*( (f_kmq-f_k)/(MODEL_E_ph+E_kmq-E_k+cI*QP_G_damp)+&
&                                                      (f_k-f_kmq)/(MODEL_E_ph+E_k-E_kmq+cI*QP_G_damp))
       !
       OMS_im_W(iq)=OMS_im_W(iq)+MODEL_ep_dV**2/k%nibz*( (f_kmq-f_k)/(cI*MODEL_E_ph+E_kmq-E_k)+&
&                                                        (f_k-f_kmq)/(cI*MODEL_E_ph+E_k-E_kmq) )
       !
       OMS_static(iq)=OMS_static(iq)+MODEL_ep_dV**2/k%nibz*( (f_kmq-f_k)/(E_kmq-E_k+cI*QP_G_damp)+&
&                                                            (f_k-f_kmq)/(E_k-E_kmq+cI*QP_G_damp) )
       !
       if (.not.is==k%nibz) cycle
       !
       do iw=1,QP_Sc_steps
         PHEL_qp%PI(1,iq,iw)=PHEL_qp%PI(1,iq,iw)+MODEL_ep_dV**2/k%nibz*( (f_kmq-f_k)/(QPH%W(iw)+E_kmq-E_k)+&
&                                                                        (f_k-f_kmq)/(QPH%W(iw)+E_k-E_kmq))
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
 do is=1,k%nibz
   if (Q_is_todo(is)==0) cycle
   iq=Q_index(is)
   q=k%pt(iq,:)-k%pt(1,:)
   q_mod=iku_v_norm(q)
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
 iq=Q_index(k%nibz)
 OMS_single_q=(/real(OMS_ph(iq)-OMS_static(iq)),-aimag(OMS_ph(iq))/)*HA2EV*1000.
 call msg('sr',com_compose_msg(body="[MODEL] OMS@Wo (ph)",post="(Re -Im)"),OMS_single_q,after_msg="[meV]")
 OMS_single_q=(/real(OMS_im_W(iq)-OMS_static(iq)),aimag(OMS_im_W(iq))/)*HA2EV*1000.
 call msg('sr',com_compose_msg(body="[MODEL] OMS@iWo (ph)",post="(Re Im)"),OMS_single_q,after_msg="[meV]")
 !
end subroutine MODELS_ep_Pi
