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
module YPP_models
 !
 use pars,                ONLY:SP,schlen,DP
 !
 integer, allocatable :: MODEL_B_shift(:,:,:)
 integer, allocatable :: MODEL_kmq_table(:,:,:,:)
 !
 ! Masses...
 integer  :: MODEL_N_masses=1
 integer  :: MODEL_N_E_steps=100
 real(SP) :: MODEL_masses_range(2)=1.
 real(SP),  allocatable :: MODEL_masses(:)
 !
 type TODO
   integer  :: N
   integer,  allocatable :: indx(:)
   real(SP), allocatable :: val(:)
 end type
 type(TODO) :: OMS_Q,SF_Q,SF_mass
 !
 real(SP),      allocatable :: SF_Q_and_M(:,:)
 !
 type MODEL_ph
   complex(SP), allocatable :: PI_OMS(:)
   complex(SP), allocatable :: PI_ST(:)
   complex(SP), allocatable :: PI_w(:,:)
 end type
 !
 contains
   !
   function E_jell(k,shift)  
     use MODELS,        ONLY:MODEL_effective_mass
     use vec_operate,   ONLY:iku_v_norm
     implicit none
     real(SP)           :: k(3),E_jell
     integer,  optional :: shift(3)
     if (present(shift)) then
       E_jell=iku_v_norm(k+shift)**2./2./MODEL_effective_mass
     else
       E_jell=iku_v_norm(k)**2./2./MODEL_effective_mass
      endif
   end function
   !
end module YPP_models
