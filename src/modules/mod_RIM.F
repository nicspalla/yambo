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
module RIM
 !
 use pars,        ONLY:SP,DP
 !
#include<dev_defs.h>
#include<memory.h>
 !
 ! Random generator
 !
 integer :: RIM_n_rand_pts
 integer :: RIM_IC_n_pts           ! Points generated in the IC
 real(SP):: RIM_IC_vol             ! Integration cell volume (larger than UC)
 real(SP):: RIM_UC_integrated_vol
 real(SP),   allocatable          :: RIM_pt(:,:)
 !
 ! Bare interaction (V)
 !
 integer :: RIM_ng
 integer :: RIM_id_epsm1_reference
 logical :: RIM_is_diagonal
 real(SP):: RIM_epsm1(3)
 real(SP):: RIM_anisotropy
 real(SP),   allocatable          :: RIM_qpg(:,:,:)
 real(SP),   allocatable DEV_ATTR :: RIM_qpg_d(:,:,:)
 !
 ! Screened interaction (W)
 !
 integer :: RIM_W_ng
 integer :: RIM_W_n_rand_pts
 logical :: RIM_W_is_diagonal
 logical :: RIM_W_for_graph
 real(SP),   allocatable          :: RIM_W_E(:,:)
 real(SP),   allocatable          :: RIM_W(:,:,:)
 real(SP),   allocatable DEV_ATTR :: RIM_W_d(:,:,:)
 real(DP),   allocatable          :: RIM_coeff(:,:,:,:,:)
 !
end module RIM
