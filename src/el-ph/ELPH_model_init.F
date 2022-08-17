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
subroutine ELPH_model_init( )
 !
 use ELPH,          ONLY:GKKP,elph_nQ,elph_nk_bz,elph_nQ_used,elph_use_q_grid,&
&                        PH_W_debye
 use R_lattice,     ONLY:nqbz,nkbz
 use interfaces,    ONLY:ELPH_alloc
 use MODELS,        ONLY:MODEL_gkkp_kind,l_MODEL_force_jellium,MODEL_E_ph
 use parser_m,      ONLY:parser
 !
 implicit none
 !
 call parser('ForceJell',l_MODEL_force_jellium)
 if (l_MODEL_force_jellium) call warning("Jellium e-p Self-Energy mode")
 PH_W_debye=MODEL_E_ph
 elph_nQ=nqbz
 elph_nk_bz=nkbz
 elph_nQ_used=nqbz
 elph_use_q_grid=.TRUE.
 call ELPH_alloc('dV PHONONS '//trim(MODEL_gkkp_kind),GKKP,Nk_mem=1)
 !
end subroutine
