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
module MODELS
 !
 use pars,  ONLY:schlen,SP
 use units, ONLY:HA2EV
 !
 logical           :: l_models
 logical           :: l_MODEL_no_intraband
 logical           :: l_MODEL_force_jellium=.FALSE.
 character(schlen) :: MODEL_H_kind="none"
 character(schlen) :: MODEL_GKKP_kind="none"
 real(SP)          :: MODEL_U
 real(SP)          :: MODEL_alat
 real(SP)          :: MODEL_effective_mass
 real(SP)          :: MODEL_overlap
 real(SP)          :: MODEL_nel=2.
 real(SP)          :: MODEL_Eg
 real(SP)          :: MODEL_ep_dV
 real(SP)          :: MODEL_E_ph=.1/HA2EV
 real(SP)          :: MODEL_elph_alpha=0.
 real(SP)          :: MODEL_Nel_at_Ef=0.
 integer           :: MODEL_k(3)
 integer           :: MODEL_E_shells=0
 !
end module MODELS
