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
subroutine MODELS_pe_Pi_numerical(NUM,k,q,E,px)
 !
 use pars,                ONLY:SP,cI
 use electrons,           ONLY:levels
 use stderr,              ONLY:STRING_same
 use R_lattice,           ONLY:bz_samp
 use D_lattice,           ONLY:Tel
 use YPP_models,          ONLY:MODEL_kmq_table,E_jell,MODEL_PH,OMS_Q,SF_Q
 use MODELS,              ONLY:MODEL_gkkp_kind,MODEL_E_ph,MODEL_ep_dV 
 use ELPH,                ONLY:GKKP
 use PHEL,                ONLY:PHONON,QPH
 use QP_m,                ONLY:QP_Sc_steps,QP_G_damp
 use functions,           ONLY:Fermi_fnc
 use LIVE_t,              ONLY:live_timing
 use parallel_m,          ONLY:myid,PP_indexes
 use parallel_int,        ONLY:PP_redux_wait
 !
 implicit none
 !
 type(bz_samp), intent(inout)   :: k,q
 type(levels ), intent(inout)   :: E
 type(PP_indexes), intent(in)   :: px
 type(MODEL_PH),intent(inout)   :: NUM
 !
 ! Work Space
 !
 integer      :: ik,ib,i_kmq,ib_kmq,is,iw,iq
 real(SP)     :: q_mod,E_k,E_kmq,f_k,f_kmq,GKKP_me
 !
 call section("+","Numerical Pi(w)")
 !===================================
 ! ... Loop
 !---------
 call live_timing("Phonon PI (numerical)",px%n_of_elements(myid+1)*OMS_Q%N)
 !
 do is=1,OMS_Q%N
   !
   iq   =OMS_Q%indx(is)
   q_mod=OMS_Q%val(is)
   !
   if (STRING_same(MODEL_gkkp_kind,"debye"    )) GKKP_me=2.*MODEL_ep_dV**2
   if (STRING_same(MODEL_gkkp_kind,"frohlich" )) GKKP_me=2.*MODEL_ep_dV**2/q_mod**2.
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
       NUM%PI_OMS(is) =NUM%PI_OMS(is) +GKKP_me*f_k/k%nibz*fraction(MODEL_E_ph)
       !
       NUM%PI_ST(is)  =NUM%PI_ST(is)  +GKKP_me*f_k/k%nibz*fraction( 0._SP )
       !
       if (any(iq==SF_Q%indx)) then
         do iw=1,QP_Sc_steps
           PHONON%PI(1,iq,iw)=PHONON%PI(1,iq,iw)+GKKP_me*f_k/k%nibz*fraction(real(QPH%W(iw)))
         enddo
       endif
       !
       call live_timing(steps=1)
       !
     enddo
   enddo
   !
 enddo
 !
 call live_timing()
 call PP_redux_wait(NUM%PI_OMS)
 call PP_redux_wait(NUM%PI_ST)
 call PP_redux_wait(PHONON%PI)
 !
 do is=1,SF_Q%N
   NUM%PI_w(is,:)=PHONON%PI(1,SF_Q%indx(is),:)
 enddo
 !
 contains
   !
   function fraction(E)
     real(SP)    :: E
     complex(SP) :: fraction
     fraction=1./(E+E_k-E_kmq+cI*QP_G_damp)-1./(E-E_k+E_kmq+cI*QP_G_damp)
   end function
   !
end subroutine MODELS_pe_Pi_numerical
