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
subroutine ELPH_model_init(k,q)
 !
 use ELPH,          ONLY:GKKP,gkkp_db,elph_nQ,elph_nk_bz,elph_nQ_used,elph_use_q_grid
 use R_lattice,     ONLY:bz_samp
 use interfaces,    ONLY:ELPH_alloc
 !
 implicit none
 !
 type(bz_samp)      :: k,q
 !
 gkkp_db="genFroh"
 elph_nQ=q%nbz
 elph_nk_bz=k%nbz
 elph_nQ_used=q%nbz
 elph_use_q_grid=.TRUE.
 call ELPH_alloc('dV PHONONS',GKKP,Nk_mem=1)
 !
end subroutine
