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
subroutine MODELS_pe_driver(k,E,px)
 !
 use pars,                ONLY:SP,pi
 use electrons,           ONLY:levels
 use R_lattice,           ONLY:bz_samp
 use D_lattice,           ONLY:Tel
 use units,               ONLY:HA2EV
 use YPP_models,          ONLY:MODEL_B_shift,MODEL_ph,MODEL_N_E_steps,MODEL_N_masses,OMS_Q,SF_Q
 use MODELS,              ONLY:MODEL_gkkp_kind,MODEL_E_ph,MODEL_ep_dV,MODEL_Nel_at_Ef,MODEL_effective_mass,MODEL_K_fermi 
 use ELPH,                ONLY:GKKP,elph_branches,PH_freqs_sq
 use PHEL,                ONLY:PH_Q,PHEL_alloc,QPH
 use QP_m,                ONLY:QP_Sc_steps,l_QP_eval_GF,QP_G_damp,QP_G_er
 use vec_operate,         ONLY:iku_v_norm
 use com,                 ONLY:msg,com_compose_msg
 use interfaces,          ONLY:OCCUPATIONS_Fermi
 use parallel_m,          ONLY:PP_indexes
 !
#include<memory.h>
 !
 type(bz_samp), intent(inout)   :: k
 type(levels ), intent(inout)   :: E
 type(PP_indexes), intent(in)   :: px
 !
 ! Work Space
 !
 type(bz_samp) :: q
 integer       :: ik,ib,i_mass
 real(SP)      :: Ef_dist
 type(MODEL_ph)              ::NUM
 type(MODEL_ph), allocatable ::EXACT(:)
 !
 call section("=","E-P Pi (phonons)")
 !===================================
 ! ...  OMS Q TODO's list
 !------------------------
 call MODELS_pe_todos("Q_oms_and_Masses",k,q)
 !
 ! ... 	k tables
 !-----------------------
 call MODELS_k_tables(E,k,q,px)
 !
 ! ... occupations
 !----------------
 Tel=0.!273./HA2KEL
 E%nk=k%nibz
 YAMBO_ALLOC(k%weights,(k%nibz))
 k%weights=1./float(k%nibz)
 call OCCUPATIONS_Fermi(E,k,"OCCUPATIONS")
 MODEL_Nel_at_Ef=0._SP
 Ef_dist=10.
 do ib=1,E%nb
   do ik=1,k%nibz
     if (abs(E%E(ib,ik,1)-E%E_fermi)<Ef_dist.and.E%f(ib,ik,1)>0.) then
       MODEL_K_fermi=iku_v_norm(k%pt(ik,:)+MODEL_B_shift(ib,ik,:))
       Ef_dist=abs(E%E(ib,ik,1)-E%E_fermi)
     endif
   enddo
 enddo
 MODEL_Nel_at_Ef=2.*pi*MODEL_effective_mass*MODEL_K_fermi
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
 l_QP_eval_GF=.TRUE.
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
 ! ... GKKP
 !---------
 MODEL_gkkp_kind="Debye"
 !MODEL_gkkp_kind="Frohlich"
 call ELPH_model_gkkp(GKKP)
 call msg('sr',com_compose_msg(body="[MODEL] Nel@E_fermi (ph)"),MODEL_Nel_at_Ef)
 call msg('sr',com_compose_msg(body="[MODEL] dV (ph)"),MODEL_ep_dV*(HA2EV*1000.)**2,after_msg="[meV]")
 call msg('sr',com_compose_msg(body="[MODEL] K_fermi"),MODEL_K_fermi,after_msg="[a.u.]")
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
 call MODELS_pe_report(NUM,EXACT)
 !
 contains
   !
   subroutine PH_alloc(PH)
     use pars, ONLY:cZERO
     type(MODEL_PH) :: PH
     YAMBO_ALLOC(PH%PI_OMS_w,(OMS_Q%N))
     YAMBO_ALLOC(PH%PI_ST,(OMS_Q%N))
     YAMBO_ALLOC(PH%PI_OMS_iw,(OMS_Q%N))
     YAMBO_ALLOC(PH%PI_w,(SF_Q%N,QP_Sc_steps))
     YAMBO_ALLOC(PH%PI_iw,(SF_Q%N,QP_Sc_steps))
     PH%PI_OMS_w=cZERO
     PH%PI_ST=cZERO
     PH%PI_OMS_iw=cZERO
     PH%PI_w=cZERO
     PH%PI_iw=cZERO
   end subroutine
   !
end subroutine MODELS_pe_driver
