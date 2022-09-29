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
subroutine MODELS_pe_Pi_exact(EXACT,q)
 !
 use pars,                ONLY:SP,pi,cI,cZERO
 use YPP_models,          ONLY:E_jell,MODEL_PH,MODEL_N_masses,OMS_Q,SF_Q,SF_mass,MODEL_masses
 use MODELS,              ONLY:MODEL_E_ph,MODEL_effective_mass,MODEL_K_fermi
 use R_lattice,           ONLY:bz_samp,RL_vol
 use vec_operate,         ONLY:iku_v_norm
 use PHEL,                ONLY:QPH
 use QP_m,                ONLY:QP_Sc_steps,QP_G_damp
 use LIVE_t,              ONLY:live_timing
 use parallel_m,          ONLY:PP_indexes,PP_indexes_reset,myid
 use parallel_int,        ONLY:PP_redux_wait,PARALLEL_index,PP_wait
 !
 implicit none
 !
 type(MODEL_PH)              :: EXACT(MODEL_N_masses)
 type(bz_samp), intent(in)   :: q
 !
 ! Work Space
 !
 integer            :: iq,is,i_sign,ik,iw,i_mass,i_p
 real(SP)           :: q_mod,alpha,beta,Ko
 complex(SP)        :: PI_A(QP_Sc_steps),PI_oms(1)
 type(PP_indexes)   :: px
 !
 call PP_indexes_reset(px)
 call PARALLEL_index(px,(/OMS_Q%N/))
 call PP_wait
 !
 call section("=","Exact Xo(w)")
 !==============================
 !
 call live_timing("Xo (exact)",px%n_of_elements(myid+1)*MODEL_N_masses)
 !
 do i_mass=1,MODEL_N_masses
   !
   do is=1,OMS_Q%N
     !
     if (.not.px%element_1D(is)) cycle
     !
     iq=OMS_Q%indx(is)
     q_mod=iku_v_norm(q%pt(iq,:))
     beta=MODEL_masses(i_mass)/q_mod
     !
     ! Spectral function
     do iw=1,QP_Sc_steps
       PI_A(iw)=-1./pi*PI_im(real(QPH%W(iw)),MODEL_masses(i_mass))
     enddo
     !
     ! OMS
     PI_oms=cZERO
     call Kramers_Kronig(PI_A,real(QPH%W),QP_Sc_steps,PI_oms,(/MODEL_E_ph+cI*QP_G_damp/),1,cZERO) 
     EXACT(i_mass)%OMS(is)=real(PI_oms(1))+cI*PI_im(MODEL_E_ph,MODEL_masses(i_mass))
     !
     ! ST
     PI_oms=cZERO
     call Kramers_Kronig(PI_A,real(QPH%W),QP_Sc_steps,PI_oms,(/cI*QP_G_damp/),1,cZERO) 
     EXACT(i_mass)%STATIC(is)=real(PI_oms(1))
     !
     ! Full GF
     do i_p=1,SF_Q%N
       if (SF_Q%indx(i_p)==iq.and.SF_mass%indx(i_p)==i_mass) then
         call Kramers_Kronig(PI_A,real(QPH%W),QP_Sc_steps,EXACT(i_mass)%SF(i_p,:), QPH%W,QP_Sc_steps,cZERO) 
       endif
     enddo
     !
     call live_timing(steps=1)
     !
   enddo

   !
 enddo
 !
 call live_timing( )
 !
 do i_mass=1,MODEL_N_masses
   call PP_redux_wait(EXACT(i_mass)%STATIC)
   call PP_redux_wait(EXACT(i_mass)%OMS)
   call PP_redux_wait(EXACT(i_mass)%SF)
 enddo
 !
 contains
   !
   function PI_im(E,Mass_)
     real(SP) :: PI_im,E,Mass_
     PI_im=0._SP
     do i_sign=-1,1,2
       alpha=i_sign*E-E_jell(q%pt(iq,:))
       Ko=abs(alpha*beta)
       if (abs(Ko)>MODEL_K_fermi) cycle
       PI_im=PI_im-i_sign*pi**2*beta*(MODEL_K_fermi**2-Ko**2)
     enddo
     PI_im=PI_im*2./RL_vol*MODEL_effective_mass/Mass_
     !
   end function
   !
   function PI_re(E)
     real(SP) :: PI_re,E,gamma
     PI_re=0._SP
     do i_sign=-1,1,2
       alpha=i_sign*E-E_jell(q%pt(iq,:))
       Ko=abs(alpha*beta) 
       gamma=MODEL_K_fermi/Ko
        PI_re=PI_re+2.*pi*beta*( (gamma*2-1.)*log(abs((gamma+1.)/(gamma-1.)))+2.*gamma )*Ko/2.
     enddo
     PI_re=PI_re*2./RL_vol
     !
   end function
   !
end subroutine MODELS_pe_Pi_exact
