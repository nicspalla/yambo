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
subroutine ELPH_model_gkkp(iq)
 !
 use pars,             ONLY:SP,pi
 use MODELS,           ONLY:MODEL_E_ph,MODEL_elph_alpha,MODEL_gkkp_kind,MODEL_effective_mass
 use stderr,           ONLY:STRING_same
 use ELPH,             ONLY:GKKP,PH_freqs_sq,PH_W_debye
 use D_lattice,        ONLY:DL_vol
 use electrons,        ONLY:default_nel
 !
 implicit none
 !
 integer            :: iq
 !
 ! Work Space
 !
 real(SP)           :: EM_sq
 !
 PH_W_debye=MODEL_E_ph
 PH_freqs_sq(iq,1)=MODEL_E_ph**2.
 !
 if (STRING_same(MODEL_gkkp_kind,"debye" )) then
   EM_sq=2*pi**2*MODEL_E_ph*(4*pi)**(1./3.)/(3*default_nel)**1./3.*MODEL_elph_alpha
 else if (STRING_same(MODEL_gkkp_kind,"Frholich")) then 
   EM_sq=2.*pi*MODEL_E_ph*sqrt(2*pi*MODEL_E_ph/MODEL_effective_mass)*MODEL_elph_alpha
 endif
 GKKP%dVc(1,:,:,:,1)=sqrt(EM_sq*MODEL_E_ph)
 !
end subroutine
