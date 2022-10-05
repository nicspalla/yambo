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
 use stderr,              ONLY:STRING_same
 use MODELS,              ONLY:MODEL_E_ph,MODEL_ep_dV,MODEL_gkkp_kind
 use ELPH,                ONLY:elph_branches,PH_freqs_sq,l_GKKP_DB_is_expanded
 use PHEL,                ONLY:PH_Q,PHEL_alloc,PH_of,PHONON,QPH
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
 type(MODEL_ph)              ::NUM,N_vertex
 type(MODEL_ph), allocatable ::EXACT(:),E_vertex(:)
 integer                     ::i_mass,i_sf,iw,i_m
 logical       , allocatable ::Q_mask(:)
 character(2)                ::modes(4)
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
 QP_G_er=(/-1.,1./)*20.*MODEL_E_ph
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
 call PH_alloc(N_vertex)
 allocate(EXACT(MODEL_N_masses))
 allocate(E_vertex(MODEL_N_masses))
 do i_mass=1,MODEL_N_masses
   call PH_alloc(EXACT(i_mass))
   call PH_alloc(E_vertex(i_mass))
 enddo
 !
 ! Pi numerical
 !--------------
 call MODELS_pe_Pi_numerical(NUM,k,q,E,px)
 call MODELS_pe_X_to_VERTEX("num",-1,NUM,N_vertex,QPH%W)
 !
 ! Pi exact
 !----------
 call MODELS_pe_Pi_exact(EXACT,q)
 do i_mass=1,MODEL_N_masses
   call MODELS_pe_X_to_VERTEX("exact",i_mass,EXACT(i_mass),E_vertex(i_mass),QPH%W)
 enddo
 !
 ! Output
 !--------
 !
 modes=(/"bb","ss","bs","bd"/)
 do i_m=1,4
   call MODELS_pe_report("V",modes(i_m),EXACT,NUM,N_vertex,E_vertex,QPH%W)
   call MODELS_pe_report("Eph",modes(i_m),EXACT,NUM,N_vertex,E_vertex,QPH%W)
   call MODELS_pe_report("PI",modes(i_m),EXACT,NUM,N_vertex,E_vertex,QPH%W)
   call MODELS_pe_report("D",modes(i_m),EXACT,NUM,N_vertex,E_vertex,QPH%W)
 enddo
 !          
 do i_sf=1,SF_Q%N
   Q_mask(SF_Q%indx(i_sf))=.TRUE.
   do iw=1,QP_Sc_steps
     PHONON%PI(1,SF_Q%indx(i_sf),iw)=NUM%SF(i_sf,iw)*2.*MODEL_ep_dV**2*N_vertex%SF(i_sf,iw)
     if (STRING_same(MODEL_gkkp_kind,"Debye")) then
       PHONON%PI(1,SF_Q%indx(i_sf),iw)=PHONON%PI(1,SF_Q%indx(i_sf),iw)*SF_Q%val(i_sf)**2
     endif
   enddo
 enddo
 call PH_of(k,Q_mask=Q_mask)
 !
 contains
   !
   subroutine PH_alloc(PH)
     use pars, ONLY:cZERO,rZERO
     type(MODEL_PH) :: PH
     YAMBO_ALLOC(PH%OMS,(OMS_Q%N))
     YAMBO_ALLOC(PH%STATIC,(OMS_Q%N))
     YAMBO_ALLOC(PH%SF,(SF_Q%N,QP_Sc_steps))
     PH%OMS=cZERO
     PH%STATIC=cZERO
     PH%SF=cZERO
   end subroutine
   !
end subroutine MODELS_pe_driver
