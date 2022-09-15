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
 use pars,                ONLY:SP,pi,cI,cZERO,schlen
 use parser_m,            ONLY:parser
 use units,               ONLY:HA2EV
 use YPP_models,          ONLY:E_jell,PI_ph,MODEL_N_masses,MODEL_masses_range
 use MODELS,              ONLY:MODEL_E_ph,MODEL_ep_dV,MODEL_effective_mass,MODEL_K_fermi 
 use R_lattice,           ONLY:bz_samp,RL_vol
 use stderr,              ONLY:intc
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
 integer            :: iq,is,i_sign,ik,ib,iw,i_mass
 real(SP)           :: q_mod,alpha,beta,Ko,Mass(MODEL_N_masses),W_iWo
 complex(SP)        :: PI_A(QP_Sc_steps),PI_oms(1),W_oms
 type(PP_indexes)   :: px
 !
 ! SF's to plot
 character(schlen)  :: fname
 logical            :: l_print_SF
 integer, parameter :: n_SF=6
 integer            :: SF_ind(n_SF,2),i_p
 complex(SP)        :: PIoms(n_SF,NQ),PIiW(n_SF,NQ),D(QP_Sc_steps),D_w(QP_Sc_steps),Integral,PIst(n_SF,NQ)
 complex(SP),external :: CIntegrate
 !                                           M...          Q..
 real(SP),parameter :: REF_M(n_SF)=(/1. ,1. ,1. ,2. ,2. ,2. /)
 real(SP),parameter :: REF_Q(n_SF)=(/0.2,0.5,1.2,0.2,0.5,1.2/)
 !
 call PP_indexes_reset(px)
 call PARALLEL_index(px,(/NQ/))
 call PP_redux_wait
 !
 call parser('Print_SF',l_print_SF)
 !
 call live_timing("Phonon PI (exact)",px%n_of_elements(myid+1)*MODEL_N_masses)
 !
 do i_mass=1,MODEL_N_masses-1
   Mass(i_mass)=MODEL_masses_range(1)+(i_mass-1)*(MODEL_masses_range(2)-MODEL_masses_range(1))/float(MODEL_N_masses-1)
 enddo
 Mass(MODEL_N_masses)=MODEL_masses_range(2)
 !
 fname="PI_vs_mass_and_q_mod_EXACT"
 call OUTPUT_driver(fname,action="open")
 !
 SF_ind=0
 if (MODEL_N_masses>1) then
   do i_p=1,n_SF
     do i_mass=2,MODEL_N_masses
       if (Mass(i_mass)>=REF_M(i_p).and.Mass(i_mass-1)<REF_M(i_p)) SF_ind(i_p,1)=i_mass 
     enddo
     do is=2,NQ
       if (iku_v_norm(q%pt(Q_todo(is),:))/MODEL_K_fermi>REF_Q(i_p).and.&
&          iku_v_norm(q%pt(Q_todo(is-1),:))/MODEL_K_fermi<REF_Q(i_p) ) SF_ind(i_p,2)=is
     enddo
   enddo
 else
   SF_ind(1,:)=(/1,NQ/)
 endif
 !
 PI_exact%SF_w =cZERO
 PI_exact%SF_iw=cZERO
 PIst =cZERO
 PIoms=cZERO
 PIiW =cZERO
 !
 do i_mass=1,MODEL_N_masses
   !
   PI_exact%OMS=cZERO
   PI_exact%ST=cZERO
   PI_exact%IW=cZERO
   !
   do is=1,NQ
     !
     if (.not.px%element_1D(is)) cycle
     !
     iq=Q_todo(is)
     q_mod=iku_v_norm(q%pt(iq,:))
     beta=Mass(i_mass)/q_mod
     !
     ! Spectral function
     do iw=1,QP_Sc_steps
       PI_A(iw)=-1./pi*PI_im(real(W(iw)),Mass(i_mass))
     enddo
     !
     ! OMS
     PI_oms=cZERO
     call Kramers_Kronig(PI_A,real(W),QP_Sc_steps,PI_oms,(/MODEL_E_ph+cI*QP_G_damp/),1,cZERO) 
     PI_exact%OMS(is)=real(PI_oms(1))+cI*PI_im(MODEL_E_ph,Mass(i_mass))
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
     ! Full GF
     do i_p=1,n_SF
       if (all(SF_ind(i_p,:)==(/i_mass,is/))) then
         call Kramers_Kronig(PI_A,real(W),QP_Sc_steps,PI_exact%SF_w(i_p,:), W,QP_Sc_steps,cZERO) 
         call Kramers_Kronig(PI_A,real(W),QP_Sc_steps,PI_exact%SF_iw(i_p,:),cI*real(W),QP_Sc_steps,cZERO) 
       endif
       if (SF_ind(i_p,1)==i_mass) then
         PIoms(i_p,is)=PI_exact%OMS(is)
         PIiW(i_p,is) =PI_exact%iW(is)
         PIst(i_p,is) =PI_exact%ST(is)
       endif
     enddo
     !
     call live_timing(steps=1)
     !
   enddo
   !
   call PP_redux_wait(PI_exact%ST)
   call PP_redux_wait(PI_exact%OMS)
   call PP_redux_wait(PI_exact%IW)
   !
   do is=1,NQ
     iq=Q_todo(is)
     q_mod=iku_v_norm(q%pt(iq,:))
     W_iWo=sqrt(MODEL_E_ph*(MODEL_E_ph+PI_exact%IW(is)-PI_exact%ST(is)))/MODEL_E_ph
     W_oms=sqrt(MODEL_E_ph*(MODEL_E_ph+PI_exact%OMS(is)-PI_exact%ST(is)))/MODEL_E_ph
     call OUTPUT_driver(fname,TITLES=(/"Mass"/),R_VALUES=(/Mass(i_mass)/))
     call OUTPUT_driver(fname,TITLES=(/"|q|/Kf"/),R_VALUES=(/q_mod/MODEL_K_fermi/))
     call OUTPUT_driver(fname,TITLES=(/"Re[E_iWo-E_Wo]/Wo"/),R_VALUES=real((/W_iWo-W_oms/)))
     call OUTPUT_driver(fname,TITLES=(/"|Im[E_Wo]/Wo|"/),R_VALUES=(/abs(aimag(W_oms))/))
     call OUTPUT_driver(fname,TITLES=(/"Re[E_iWo]/Wo"/),R_VALUES=real((/W_iWo/)))
     call OUTPUT_driver(fname,action="write")
   enddo
   !
 enddo
 !
 call OUTPUT_driver(fname,action="close")
 !
 call live_timing( )
 !
 call PP_redux_wait(PIst)
 call PP_redux_wait(PIoms)
 call PP_redux_wait(PIiW)
 call PP_redux_wait(PI_exact%SF_w)
 call PP_redux_wait(PI_exact%SF_iw)
 !
 if (     l_print_SF) call live_timing("Phonon PI (Output)",n_SF*(1+NQ))
 if (.not.l_print_SF) call live_timing("Phonon PI (Output)",n_SF)
 ! 
 do i_p=1,n_SF
   !
   ! SF's
   if (any((/SF_ind(i_p,:)==0/))) cycle
   i_mass=SF_ind(i_p,1)
   is=SF_ind(i_p,2)
   iq=Q_todo(is)
   q_mod=iku_v_norm(q%pt(iq,:))
   fname="PI_vs_W_EXACT_"//trim(intc(i_p))
   call OUTPUT_driver(fname,action="reset")
   call OUTPUT_driver(fname,action="open")
   call msg('o '//fname,'# M*                ',Mass(i_mass),INDENT=0)
   call msg('o '//fname,'# |Q|/K_fermi       ',q_mod/MODEL_K_fermi,INDENT=0)
   call msg('o '//fname,'# Re[\D\PI(Wo)]  [meV]',real(PIoms(i_p,is)-PIst(i_p,is))*HA2EV*1000.,INDENT=0)
   call msg('o '//fname,'# Re[\D\PI(iWo)] [meV]',real(PIiW(i_p,is)-PIst(i_p,is))*HA2EV*1000.,INDENT=0)
   call msg('o '//fname,'# Im[\PI(Wo)]    [meV]',aimag(PIoms(i_p,is))*HA2EV*1000.,INDENT=0)
   do iw=1,QP_Sc_steps
     call OUTPUT_driver(fname,TITLES=(/"E [meV]"/),R_VALUES=(/real(W(iw))/),UNIT="meV")
     call OUTPUT_driver(fname,TITLES=(/"Im[\Pi(w)] [meV]"/),R_VALUES=(/aimag(PI_exact%SF_w(i_p,iw))/),UNIT="meV")
     call OUTPUT_driver(fname,TITLES=(/"Re[\Pi(w)] [meV]"/),R_VALUES=(/real(PI_exact%SF_w(i_p,iw))/),UNIT="meV")
     call OUTPUT_driver(fname,TITLES=(/"Re[\Pi(iw)] [meV]"/),R_VALUES=(/real(PI_exact%SF_iw(i_p,iw))/),UNIT="meV")
     call OUTPUT_driver(fname,action="write")
   enddo
   call OUTPUT_driver(fname,action="close")
   !
   ! iW's
   fname="W_vs_q_mod_EXACT_"//trim(intc(i_p))
   call OUTPUT_driver(fname,action="open")
   do is=1,NQ
     iq=Q_todo(is)
     q_mod=iku_v_norm(q%pt(iq,:))
     call OUTPUT_driver(fname,TITLES=(/"|Q|/K_fermi"/),R_VALUES=(/q_mod/MODEL_K_fermi/))
     W_iWo=sqrt(MODEL_E_ph*(MODEL_E_ph+PIiW(i_p,is)-PIst(i_p,is)))/MODEL_E_ph
     W_oms=sqrt(MODEL_E_ph*(MODEL_E_ph+PIoms(i_p,is)-PIst(i_p,is)))/MODEL_E_ph
     call OUTPUT_driver(fname,TITLES=(/"E_iw/Wo"/),R_VALUES=(/W_iWo/))
     call OUTPUT_driver(fname,TITLES=(/"Re[E_oms]/Wo"/),R_VALUES=(/real(W_oms)/))
     call OUTPUT_driver(fname,TITLES=(/"Im[E_oms]/Wo"/),R_VALUES=(/abs(aimag(W_oms))/))
     call OUTPUT_driver(fname,action="write")
   enddo
   call OUTPUT_driver(fname,action="close")
   !
   call live_timing(steps=1)
   !
   ! D's
   if (l_print_SF) then
     fname="D_vs_W_and_q_mod_EXACT_"//trim(intc(i_p))
     call OUTPUT_driver(fname,action="open")
     do is=1,NQ
       iq=Q_todo(is)
       q_mod=iku_v_norm(q%pt(iq,:))
       W_oms=sqrt(MODEL_E_ph*(MODEL_E_ph+PIoms(i_p,is)-PIst(i_p,is)))
       W_iWo=sqrt(MODEL_E_ph*(MODEL_E_ph+ PIiW(i_p,is)-PIst(i_p,is)))
       do iw=1,QP_Sc_steps
         D_w(iw)=MODEL_E_ph*(2./real(QP_Sc_steps)*iw)+cI*0.001/HA2EV
         D(iw)=MODEL_E_ph/(D_w(iw)**2-MODEL_E_ph**2-MODEL_E_ph*(PIoms(i_p,is)-PIst(i_p,is)))
       enddo
       Integral=CIntegrate(-D,real(D_w),QP_Sc_steps)
       do iw=1,QP_Sc_steps
         call OUTPUT_driver(fname,TITLES=(/"|Q|/K_fermi"/),R_VALUES=(/q_mod/MODEL_K_fermi/))
         call OUTPUT_driver(fname,TITLES=(/"E/Wo"/),R_VALUES=(/real(D_w(iw)/MODEL_E_ph)/))
         call OUTPUT_driver(fname,TITLES=(/"Im[D(E)]"/),R_VALUES=(/-aimag(D(iw))/aimag(Integral)/))
         call OUTPUT_driver(fname,action="write")
       enddo
       call live_timing(steps=1)
     enddo
     call OUTPUT_driver(fname,action="close")
   endif
   !
 enddo
 !
 call live_timing()
 !
 call OUTPUT_driver("PI_vs_q_mod_EXACT",action="open")
 do is=1,NQ
   iq=Q_todo(is)
   q_mod=iku_v_norm(q%pt(iq,:))
   call OUTPUT_driver("q_mod_EXACT",TITLES=(/"|q|"/),R_VALUES=(/q_mod/))
   call OUTPUT_driver("q_mod_EXACT",TITLES=(/"-Im[PI(Wo)]"/),R_VALUES=(/-aimag(PI_exact%OMS(is))/),UNIT="meV")
   call OUTPUT_driver("q_mod_EXACT",TITLES=(/"Re[\D\PI(Wo)]"/),R_VALUES=(/real(PI_exact%OMS(is)-PI_exact%ST(is))/),UNIT="meV")
   call OUTPUT_driver("q_mod_EXACT",TITLES=(/"Re[\D\PI(iWo)]"/),R_VALUES=(/real(PI_exact%iW(is)-PI_exact%ST(is))/),UNIT="meV")
   call OUTPUT_driver("q_mod_EXACT",TITLES=(/"Re[PI(0)]"/),R_VALUES=(/real(PI_exact%ST(is))/),UNIT="meV")
   call OUTPUT_driver("q_mod_EXACT",action="write")
 enddo
 call OUTPUT_driver("q_mod_EXACT",action="close")
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
end subroutine MODELS_ep_Pi_exact
