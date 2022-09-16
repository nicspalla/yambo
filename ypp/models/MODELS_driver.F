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
subroutine MODELS_driver( )
 !
 use MODELS,              ONLY:MODEL_H_kind
 use electrons,           ONLY:levels,E_reset
 use R_lattice,           ONLY:bz_samp,bz_samp_reset
 use parallel_m,          ONLY:PP_indexes,PP_indexes_reset
 use parallel_int,        ONLY:PP_wait,PARALLEL_index 
 !
#include<memory.h>
 !
 ! Work Space
 !
 type(levels )    :: E
 type(bz_samp)    :: k
 type(PP_indexes) :: px
 !
 call section("*",trim(MODEL_H_kind)//" model driver")
 !
 call E_reset(E)
 call bz_samp_reset(k)
 !
 ! Hamiltonian
 call MODELS_Hamiltonian(E,k)
 !
 ! E-P 
 !=====
 !
 ! Parallel indexes...
 call PP_indexes_reset(px)
 call PARALLEL_index(px,(/E%nb,k%nibz/))
 call PP_wait
 !
 !... el
 call MODELS_ep_Fan(k,E,px)
 !
 !... ph
 call MODELS_pe_driver(k,E,px)
 !
end subroutine
