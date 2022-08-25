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
subroutine ELPH_model_gkkp(GKKP)
 !
 use pars,             ONLY:SP,pi
 use MODELS,           ONLY:MODEL_E_ph,MODEL_elph_alpha,MODEL_gkkp_kind,MODEL_effective_mass,MODEL_ep_dV,MODEL_Nel_at_Ef
 use stderr,           ONLY:STRING_same
 use ELPH,             ONLY:PH_freqs_sq,MAX_gkkp,GKKP_me
 use D_lattice,        ONLY:DL_vol
 !
 implicit none
 !
 type(GKKP_me) :: GKKP
 !
 ! Work Space
 !
 real(SP)           :: EM_sq
 !
 if (STRING_same(MODEL_gkkp_kind,"debye" )) then
   EM_sq=MODEL_E_ph**2*MODEL_elph_alpha/MODEL_Nel_at_Ef/DL_vol
 else if (STRING_same(MODEL_gkkp_kind,"Frohlich")) then 
   EM_sq=2.*pi*MODEL_E_ph*sqrt(2*pi*MODEL_E_ph/MODEL_effective_mass)*MODEL_elph_alpha/DL_vol
 else
   call error("Model kind is not specified")
 endif
 MODEL_ep_dV=sqrt(EM_sq)
 !
 if (allocated(PH_freqs_sq)) then
   PH_freqs_sq(:,1)=MODEL_E_ph**2.
 endif
 if (allocated(GKKP%dVc)) then
   GKKP%dVc(1,:,:,:,1)=sqrt(2.*EM_sq*MODEL_E_ph)
 endif
 if (allocated(GKKP%dVr)) then
   GKKP%dVr(:,:,:,1,1)=2.*EM_sq*MODEL_E_ph
   MAX_gkkp=GKKP%dVr(1,1,1,1,1)
 endif
 !
end subroutine
