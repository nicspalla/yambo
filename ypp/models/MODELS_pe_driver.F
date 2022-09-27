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
subroutine MODELS_pe_driver(k,q,E,px)
 !
 use electrons,           ONLY:levels
 use R_lattice,           ONLY:bz_samp
 use units,               ONLY:HA2EV
 use YPP_models,          ONLY:MODEL_ph,MODEL_N_E_steps,MODEL_N_masses,OMS_Q,SF_Q
 use MODELS,              ONLY:MODEL_E_ph 
 use ELPH,                ONLY:elph_branches,PH_freqs_sq,l_GKKP_DB_is_expanded
 use PHEL,                ONLY:PH_Q,PHEL_alloc,QPH,PH_of
 use QP_m,                ONLY:QP_Sc_steps,l_QP_eval_GF,QP_G_damp,QP_G_er
 use parallel_m,          ONLY:PP_indexes
 !
#include<memory.h>
 !
 type(bz_samp), intent(inout)   :: k,q
 type(levels ), intent(inout)   :: E
 type(PP_indexes), intent(in)   :: px
 !
 ! Work Space
 !
 type(MODEL_ph)              ::NUM
 type(MODEL_ph), allocatable ::EXACT(:)
 integer                     ::i_mass,i_sf
 logical       , allocatable ::Q_mask(:)
 !
 call section("=","E-P Pi (phonons)")
 !===================================
 ! ...  OMS Q TODO's list
 !------------------------
 call MODELS_pe_todos("Q_oms_and_Masses",k,q)
 YAMBO_ALLOC(Q_mask,(q%nbz ))
 Q_mask=.FALSE.
 !
 ! ...  SF Q & M TODO's list
 !---------------------------
 call MODELS_pe_todos("SF",k,q)
 !
 ! ... Kinds and frequencies
 ! ... SF and REPORT only at the @BOX corner
 !-------------------------------------------
 PH_Q=(/minval(SF_Q%indx),maxval(SF_Q%indx)/)
 QP_Sc_steps=MODEL_N_E_steps
 elph_branches=1
 QP_G_damp=0.001/HA2EV
 QP_G_er=(/-10.,10./)*MODEL_E_ph
 YAMBO_ALLOC(PH_freqs_sq,(q%nibz,1))
 PH_freqs_sq=MODEL_E_ph**2.
 l_QP_eval_GF=.TRUE.
 l_GKKP_DB_is_expanded=.FALSE.
 call PHEL_energy_and_KINDS_setup(k)
 call PHEL_alloc( ) 
 !
 ! ... MODEL PH alloc 
 !-------------------- 
 call PH_alloc(NUM)
 allocate(EXACT(MODEL_N_masses))
 do i_mass=1,MODEL_N_masses
   call PH_alloc(EXACT(i_mass))
 enddo
 !
 ! Pi numerical
 !--------------
 call MODELS_pe_Pi_numerical(NUM,k,q,E,px)
 !
 ! Pi exact
 !----------
 call MODELS_pe_Pi_exact(EXACT,q,QPH%W)
 !
 ! Report
 !--------
 call MODELS_pe_report(NUM,EXACT,q,QPH%W)
 !          
 do i_sf=1,SF_Q%N
   Q_mask(SF_Q%indx(i_sf))=.TRUE.
 enddo
 call PH_of(k,Q_mask=Q_mask)
 !
 contains
   !
   subroutine PH_alloc(PH)
     use pars, ONLY:cZERO
     type(MODEL_PH) :: PH
     YAMBO_ALLOC(PH%PI_OMS,(OMS_Q%N))
     YAMBO_ALLOC(PH%PI_ST,(OMS_Q%N))
     YAMBO_ALLOC(PH%PI_w,(SF_Q%N,QP_Sc_steps))
     PH%PI_OMS=cZERO
     PH%PI_ST=cZERO
     PH%PI_w=cZERO
   end subroutine
   !
end subroutine MODELS_pe_driver
