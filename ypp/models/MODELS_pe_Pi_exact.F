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
subroutine MODELS_pe_Pi_exact(EXACT,q,W)
 !
 use pars,                ONLY:SP,pi,cI,cZERO
 use YPP_models,          ONLY:E_jell,MODEL_PH,MODEL_N_masses,OMS_Q,SF_Q,SF_mass,MODEL_masses
 use MODELS,              ONLY:MODEL_E_ph,MODEL_ep_dV,MODEL_effective_mass,MODEL_K_fermi
 use R_lattice,           ONLY:bz_samp,RL_vol
 use vec_operate,         ONLY:iku_v_norm
 use QP_m,                ONLY:QP_Sc_steps,QP_G_damp
 use LIVE_t,              ONLY:live_timing
 use parallel_m,          ONLY:PP_indexes,PP_indexes_reset,myid
 use parallel_int,        ONLY:PP_redux_wait,PARALLEL_index,PP_wait
 !
 implicit none
 !
 type(MODEL_PH)              :: EXACT(MODEL_N_masses)
 type(bz_samp), intent(in)   :: q
 complex(SP)                 :: W(QP_Sc_steps)
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
 call live_timing("Phonon PI (exact)",px%n_of_elements(myid+1)*MODEL_N_masses)
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
       PI_A(iw)=-1./pi*PI_im(real(W(iw)),MODEL_masses(i_mass))
     enddo
     !
     ! OMS
     PI_oms=cZERO
     call Kramers_Kronig(PI_A,real(W),QP_Sc_steps,PI_oms,(/MODEL_E_ph+cI*QP_G_damp/),1,cZERO) 
     EXACT(i_mass)%PI_OMS_w(is)=real(PI_oms(1))+cI*PI_im(MODEL_E_ph,MODEL_masses(i_mass))
     !
     ! ST
     PI_oms=cZERO
     call Kramers_Kronig(PI_A,real(W),QP_Sc_steps,PI_oms,(/cI*QP_G_damp/),1,cZERO) 
     EXACT(i_mass)%PI_ST(is)=real(PI_oms(1))
     !
     ! iW
     PI_oms=cZERO
     call Kramers_Kronig(PI_A,real(W),QP_Sc_steps,PI_oms,(/cI*MODEL_E_ph/),1,cZERO) 
     EXACT(i_mass)%PI_OMS_iw(is)=PI_oms(1)
     !
     ! Full GF
     do i_p=1,SF_Q%N
       if (SF_Q%indx(i_p)==iq.and.SF_mass%indx(i_p)==i_mass) then
         call Kramers_Kronig(PI_A,real(W),QP_Sc_steps,EXACT(i_mass)%PI_w(i_p,:), W,QP_Sc_steps,cZERO) 
         call Kramers_Kronig(PI_A,real(W),QP_Sc_steps,EXACT(i_mass)%PI_iw(i_p,:),cI*real(W),QP_Sc_steps,cZERO) 
       endif
     enddo
     !
     call live_timing(steps=1)
     !
   enddo
   !
!   do is=1,NQ
!     iq=Q_todo(is)
!     q_mod=iku_v_norm(q%pt(iq,:))
!     W_iWo=sqrt(MODEL_E_ph*(MODEL_E_ph+PI_exact%IW(is)-PI_exact%ST(is)))/MODEL_E_ph
!     W_oms=sqrt(MODEL_E_ph*(MODEL_E_ph+PI_exact%OMS(is)-PI_exact%ST(is)))/MODEL_E_ph
!     call OUTPUT_driver(fname,TITLES=(/"Mass"/),R_VALUES=(/Mass(i_mass)/))
!     call OUTPUT_driver(fname,TITLES=(/"|q|/Kf"/),R_VALUES=(/q_mod/MODEL_K_fermi/))
!     call OUTPUT_driver(fname,TITLES=(/"Re[E_iWo-E_Wo]/Wo"/),R_VALUES=real((/W_iWo-W_oms/)))
!     call OUTPUT_driver(fname,TITLES=(/"|Im[E_Wo]/Wo|"/),R_VALUES=(/abs(aimag(W_oms))/))
!     call OUTPUT_driver(fname,TITLES=(/"Re[E_iWo]/Wo"/),R_VALUES=real((/W_iWo/)))
!     call OUTPUT_driver(fname,action="write")
!   enddo
   !
 enddo
 !
! call OUTPUT_driver(fname,action="close")
 !
 call live_timing( )
 !
 do i_mass=1,MODEL_N_masses
   call PP_redux_wait(EXACT(i_mass)%PI_ST)
   call PP_redux_wait(EXACT(i_mass)%PI_OMS_w)
   call PP_redux_wait(EXACT(i_mass)%PI_OMS_iw)
   call PP_redux_wait(EXACT(i_mass)%PI_w)
   call PP_redux_wait(EXACT(i_mass)%PI_iw)
 enddo
 !
! if (     l_print_SF) call live_timing("Phonon PI (Output)",n_SF*(1+NQ))
! if (.not.l_print_SF) call live_timing("Phonon PI (Output)",n_SF)
! ! 
! do i_p=1,n_SF
!   !
!   ! SF's
!   if (any((/SF_ind(i_p,:)==0/))) cycle
!   i_mass=SF_ind(i_p,1)
!   is=SF_ind(i_p,2)
!   iq=Q_todo(is)
!   q_mod=iku_v_norm(q%pt(iq,:))
!   fname="PI_vs_W_EXACT_"//trim(intc(i_p))
!   call OUTPUT_driver(fname,action="reset")
!   call OUTPUT_driver(fname,action="open")
!   call msg('o '//fname,'# M*                ',Mass(i_mass),INDENT=0)
!   call msg('o '//fname,'# |Q|/K_fermi       ',q_mod/MODEL_K_fermi,INDENT=0)
!   call msg('o '//fname,'# Re[\D\PI(Wo)]  [meV]',real(PIoms(i_p,is)-PIst(i_p,is))*HA2EV*1000.,INDENT=0)
!   call msg('o '//fname,'# Re[\D\PI(iWo)] [meV]',real(PIiW(i_p,is)-PIst(i_p,is))*HA2EV*1000.,INDENT=0)
!   call msg('o '//fname,'# Im[\PI(Wo)]    [meV]',aimag(PIoms(i_p,is))*HA2EV*1000.,INDENT=0)
!   do iw=1,QP_Sc_steps
!     call OUTPUT_driver(fname,TITLES=(/"E [meV]"/),R_VALUES=(/real(W(iw))/),UNIT="meV")
!     call OUTPUT_driver(fname,TITLES=(/"Im[\Pi(w)] [meV]"/),R_VALUES=(/aimag(PI_exact%SF_w(i_p,iw))/),UNIT="meV")
!     call OUTPUT_driver(fname,TITLES=(/"Re[\Pi(w)] [meV]"/),R_VALUES=(/real(PI_exact%SF_w(i_p,iw))/),UNIT="meV")
!     call OUTPUT_driver(fname,TITLES=(/"Re[\Pi(iw)] [meV]"/),R_VALUES=(/real(PI_exact%SF_iw(i_p,iw))/),UNIT="meV")
!     call OUTPUT_driver(fname,action="write")
!   enddo
!   call OUTPUT_driver(fname,action="close")
!   !
!   ! iW's
!   fname="W_vs_q_mod_EXACT_"//trim(intc(i_p))
!   call OUTPUT_driver(fname,action="open")
!   do is=1,NQ
!     iq=Q_todo(is)
!     q_mod=iku_v_norm(q%pt(iq,:))
!     call OUTPUT_driver(fname,TITLES=(/"|Q|/K_fermi"/),R_VALUES=(/q_mod/MODEL_K_fermi/))
!     W_iWo=sqrt(MODEL_E_ph*(MODEL_E_ph+PIiW(i_p,is)-PIst(i_p,is)))/MODEL_E_ph
!     W_oms=sqrt(MODEL_E_ph*(MODEL_E_ph+PIoms(i_p,is)-PIst(i_p,is)))/MODEL_E_ph
!     call OUTPUT_driver(fname,TITLES=(/"E_iw/Wo"/),R_VALUES=(/W_iWo/))
!     call OUTPUT_driver(fname,TITLES=(/"Re[E_oms]/Wo"/),R_VALUES=(/real(W_oms)/))
!     call OUTPUT_driver(fname,TITLES=(/"Im[E_oms]/Wo"/),R_VALUES=(/abs(aimag(W_oms))/))
!     call OUTPUT_driver(fname,action="write")
!   enddo
!   call OUTPUT_driver(fname,action="close")
!   !
!   call live_timing(steps=1)
!   !
!   ! D's
!   if (l_print_SF) then
!     fname="D_vs_W_and_q_mod_EXACT_"//trim(intc(i_p))
!     call OUTPUT_driver(fname,action="open")
!     do is=1,NQ
!       iq=Q_todo(is)
!       q_mod=iku_v_norm(q%pt(iq,:))
!       W_oms=sqrt(MODEL_E_ph*(MODEL_E_ph+PIoms(i_p,is)-PIst(i_p,is)))
!       W_iWo=sqrt(MODEL_E_ph*(MODEL_E_ph+ PIiW(i_p,is)-PIst(i_p,is)))
!       do iw=1,QP_Sc_steps
!         D_w(iw)=MODEL_E_ph*(2./real(QP_Sc_steps)*iw)+cI*0.001/HA2EV
!         D(iw)=MODEL_E_ph/(D_w(iw)**2-MODEL_E_ph**2-MODEL_E_ph*(PIoms(i_p,is)-PIst(i_p,is)))
!       enddo
!       Integral=CIntegrate(-D,real(D_w),QP_Sc_steps)
!       do iw=1,QP_Sc_steps
!         call OUTPUT_driver(fname,TITLES=(/"|Q|/K_fermi"/),R_VALUES=(/q_mod/MODEL_K_fermi/))
!         call OUTPUT_driver(fname,TITLES=(/"E/Wo"/),R_VALUES=(/real(D_w(iw)/MODEL_E_ph)/))
!         call OUTPUT_driver(fname,TITLES=(/"Im[D(E)]"/),R_VALUES=(/-aimag(D(iw))/aimag(Integral)/))
!         call OUTPUT_driver(fname,action="write")
!       enddo
!       call live_timing(steps=1)
!     enddo
!     call OUTPUT_driver(fname,action="close")
!   endif
!   !
! enddo
! !
! call live_timing()
! !
! call OUTPUT_driver("PI_vs_q_mod_EXACT",action="open")
! do is=1,NQ
!   iq=Q_todo(is)
!   q_mod=iku_v_norm(q%pt(iq,:))
!   call OUTPUT_driver("q_mod_EXACT",TITLES=(/"|q|"/),R_VALUES=(/q_mod/))
!   call OUTPUT_driver("q_mod_EXACT",TITLES=(/"-Im[PI(Wo)]"/),R_VALUES=(/-aimag(PI_exact%OMS(is))/),UNIT="meV")
!   call OUTPUT_driver("q_mod_EXACT",TITLES=(/"Re[\D\PI(Wo)]"/),R_VALUES=(/real(PI_exact%OMS(is)-PI_exact%ST(is))/),UNIT="meV")
!   call OUTPUT_driver("q_mod_EXACT",TITLES=(/"Re[\D\PI(iWo)]"/),R_VALUES=(/real(PI_exact%iW(is)-PI_exact%ST(is))/),UNIT="meV")
!   call OUTPUT_driver("q_mod_EXACT",TITLES=(/"Re[PI(0)]"/),R_VALUES=(/real(PI_exact%ST(is))/),UNIT="meV")
!   call OUTPUT_driver("q_mod_EXACT",action="write")
! enddo
! call OUTPUT_driver("q_mod_EXACT",action="close")
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
     PI_im=PI_im*2.*MODEL_ep_dV**2/RL_vol*MODEL_effective_mass/Mass_
     !
     !if (STRING_same(MODEL_gkkp_kind,"Frohlich" )) PI_im=PI_im/q_mod**2.
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
     PI_re=PI_re*2.*MODEL_ep_dV**2/RL_vol
     !
     !if (STRING_same(MODEL_gkkp_kind,"Frohlich" )) PI_im=PI_im/q_mod**2.
     !
   end function
   !
end subroutine MODELS_pe_Pi_exact
