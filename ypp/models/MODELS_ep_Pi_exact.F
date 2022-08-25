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
subroutine MODELS_ep_Pi_exact(q,NQ,Q_todo,PI_exact,W)
 !
 use pars,                ONLY:SP,pi,cI,cZERO
 use units,               ONLY:HA2EV
 use YPP_models,          ONLY:E_jell,MODEL_K_fermi,PI_ph
 use MODELS,              ONLY:MODEL_E_ph,MODEL_ep_dV,MODEL_effective_mass,MODEL_gkkp_kind
 use stderr,              ONLY:STRING_same,intc
 use R_lattice,           ONLY:bz_samp,RL_vol
 use vec_operate,         ONLY:iku_v_norm
 use QP_m,                ONLY:QP_Sc_steps,QP_G_damp
 use com,                 ONLY:msg
 use OUTPUT,              ONLY:OUTPUT_driver
 use LIVE_t,              ONLY:live_timing
 use parallel_m,          ONLY:PP_indexes,PP_indexes_reset,myid
 use parallel_int,        ONLY:PP_redux_wait,PARALLEL_index 
 !
#include<memory.h>
 !
 type(bz_samp), intent(in)   :: q
 integer                     :: NQ,Q_todo(q%nibz)
 type(PI_ph)                 :: PI_exact 
 complex(SP)                 :: W(QP_Sc_steps)
 !
 ! Work Space
 !
 integer       :: iq,is,i_sign,ik,ib,is_SF(10)
 real(SP)      :: q_mod,alpha,beta,Ko,iw
 complex(SP)   :: PI_A(QP_Sc_steps),PI_oms(1)
 type(PP_indexes) :: px
 !
 call PP_indexes_reset(px)
 call PARALLEL_index(px,(/NQ/))
 call PP_redux_wait
 !
 call live_timing("Phonon PI (exact)",px%n_of_elements(myid+1))
 !
 is_SF(1)=NQ/3
 is_SF(2)=2*NQ/3
 is_SF(3)=NQ
 is_SF(4)=1
 !
 do is=1,NQ
   !
   if (.not.px%element_1D(is)) cycle
   !
   iq=Q_todo(is)
   q_mod=iku_v_norm(q%pt(iq,:))
   beta=MODEL_effective_mass/q_mod
   !
   ! Full GF
   !
   do iw=1,QP_Sc_steps
     PI_A(iw)=-1./pi*PI_im(real(W(iw)))
   enddo
   call Kramers_Kronig(PI_A,real(W),QP_Sc_steps,PI_exact%SF(is,:),W,QP_Sc_steps,cZERO) 
   !
   ! OMS
   PI_oms=cZERO
   call Kramers_Kronig(PI_A,real(W),QP_Sc_steps,PI_oms,(/MODEL_E_ph+cI*QP_G_damp/),1,cZERO) 
   PI_exact%OMS(is)=real(PI_oms(1))+cI*PI_im(MODEL_E_ph)
   !
   ! ST
   PI_oms=cZERO
   call Kramers_Kronig(PI_A,real(W),QP_Sc_steps,PI_oms,(/cI*QP_G_damp/),1,cZERO) 
   PI_exact%ST(is)=real(PI_oms(1))
   !
   ! iW
   PI_oms=cZERO
   call Kramers_Kronig(PI_A,real(W),QP_Sc_steps,PI_oms,(/cI*MODEL_E_ph/),1,cZERO) 
   PI_exact%IW(is)=PI_oms(1)
   !
   call live_timing(steps=1)
   !
   !alpha=MODEL_E_ph-E_jell(q%pt(iq,:))
   !Ko=abs(alpha*beta)
   !write (100,*) q_mod,aimag(PI_exact%OMS(is))*HA2EV*1000.,real(PI_exact%OMS(is)-PI_exact%IW(is))*HA2EV*1000.
   !
 enddo
 !
 call PP_redux_wait(PI_exact%ST)
 call PP_redux_wait(PI_exact%OMS)
 call PP_redux_wait(PI_exact%IW)
 call PP_redux_wait(PI_exact%SF)
 !
 call live_timing( )
 !
 call OUTPUT_driver("q_mod_EXACT",action="reset")
 call OUTPUT_driver("q_mod_EXACT",action="open")
 !
 do is=1,NQ
   !
   iq=Q_todo(is)
   q_mod=iku_v_norm(q%pt(iq,:))
   !
   if (any((/is_SF==is/))) then
     call OUTPUT_driver("PI_exact_S_"//trim(intc(is)),action="reset")
     call OUTPUT_driver("PI_exact_S_"//trim(intc(is)),action="open")
     call msg('o '//"PI_exact_S_"//trim(intc(is)),'# |Q|        ',q_mod,INDENT=0)
     call msg('o '//"PI_exact_S_"//trim(intc(is)),'# PI_st      ',real(PI_exact%ST(is))*HA2EV*1000.,INDENT=0)
     call msg('o '//"PI_exact_S_"//trim(intc(is)),'# Re[PI_oms] ',real(PI_exact%OMS(is))*HA2EV*1000.,INDENT=0)
     call msg('o '//"PI_exact_S_"//trim(intc(is)),'# Im[PI_oms] ',aimag(PI_exact%OMS(is))*HA2EV*1000.,INDENT=0)
     do iw=1,QP_Sc_steps
       call OUTPUT_driver("PI_exact_S_"//trim(intc(is)),TITLES=(/"E [meV]"/),R_VALUES=(/real(W(iw))/),UNIT="meV")
       call OUTPUT_driver("PI_exact_S_"//trim(intc(is)),TITLES=(/"SF [meV]"/),R_VALUES=(/aimag(PI_exact%SF(is,iw))/),UNIT="meV")
       call OUTPUT_driver("PI_exact_S_"//trim(intc(is)),TITLES=(/"KK [meV]"/),R_VALUES=(/real(PI_exact%SF(is,iw))/),UNIT="meV")
       call OUTPUT_driver("PI_exact_S_"//trim(intc(is)),action="write")
     enddo
     call OUTPUT_driver("PI_exact_S_"//trim(intc(is)),action="close")
   endif
   !
   call OUTPUT_driver("q_mod_EXACT",TITLES=(/"|q|"/),R_VALUES=(/q_mod/))
   call OUTPUT_driver("q_mod_EXACT",TITLES=(/"-Im[PI(Wo)]"/),R_VALUES=(/-aimag(PI_exact%OMS(is))/),UNIT="meV")
   call OUTPUT_driver("q_mod_EXACT",TITLES=(/"Re[\Delta PI(Wo)]"/),R_VALUES=(/real(PI_exact%OMS(is)-PI_exact%ST(is))/),UNIT="meV")
   call OUTPUT_driver("q_mod_EXACT",TITLES=(/"Re[\Delta PI(iWo)]"/),R_VALUES=(/real(PI_exact%iW(is)-PI_exact%ST(is))/),UNIT="meV")
   call OUTPUT_driver("q_mod_EXACT",TITLES=(/"Re[PI(0)]"/),R_VALUES=(/real(PI_exact%ST(is))/),UNIT="meV")
   call OUTPUT_driver("q_mod_EXACT",action="write")
   !
 enddo
 !
 call OUTPUT_driver("q_mod_EXACT",action="close")
 !
 contains
   !
   function PI_im(E)
     real(SP) :: PI_im,E
     PI_im=0._SP
     do i_sign=-1,1,2
       alpha=i_sign*E-E_jell(q%pt(iq,:))
       Ko=abs(alpha*beta)
       if (abs(Ko)>MODEL_K_fermi) cycle
       PI_im=PI_im-i_sign*pi**2*beta*(MODEL_K_fermi**2-Ko**2)
     enddo
     PI_im=PI_im*2.*MODEL_ep_dV**2/RL_vol
     if (STRING_same(MODEL_gkkp_kind,"Frohlich" )) PI_im=PI_im/q_mod**2.
   end function
   !
end subroutine MODELS_ep_Pi_exact
