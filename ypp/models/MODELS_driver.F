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
 use pars,                ONLY:SP,pi
 use units,               ONLY:HA2EV
 use MODELS,              ONLY:MODEL_H_kind,MODEL_gkkp_kind,MODEL_Nel_at_Ef,MODEL_K_fermi,&
&                              MODEL_effective_mass,MODEL_ep_dV,MODEL_E_ph
 use YPP_models,          ONLY:MODEL_B_shift
 use vec_operate,         ONLY:iku_v_norm
 use electrons,           ONLY:levels,E_reset
 use stderr,              ONLY:STRING_same
 use R_lattice,           ONLY:bz_samp,bz_samp_reset
 use interfaces,          ONLY:OCCUPATIONS_Fermi
 use parallel_m,          ONLY:PP_indexes,PP_indexes_reset
 use parallel_int,        ONLY:PP_wait,PARALLEL_index 
 use ELPH,                ONLY:GKKP
 use com,                 ONLY:msg,com_compose_msg
 !
#include<memory.h>
 !
 ! Work Space
 !
 type(levels )    :: E
 type(bz_samp)    :: k,q
 type(PP_indexes) :: px
 !
 integer       :: ik,ib
 real(SP)      :: Ef_dist
 !
 call section("*",trim(MODEL_H_kind)//" model driver with "//trim(MODEL_gkkp_kind)//" E-P interaction")
 !
 call E_reset(E)
 call bz_samp_reset(k)
 call bz_samp_reset(q)
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
 call section("=","Folding & Occupations")
 !
 ! ... k tables
 call MODELS_k_tables(E,k,q,px)
 !
 !... occupations and K_fermi
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
 !... gkkp
 call ELPH_model_gkkp(GKKP)
 !
 call msg('sr',com_compose_msg(body="[MODEL] Nel@E_fermi (ph)"),MODEL_Nel_at_Ef)
 call msg('sr',com_compose_msg(body="[MODEL] dV (ph)"),MODEL_ep_dV*(HA2EV*1000.)**2,after_msg="[meV]")
 call msg('sr',com_compose_msg(body="[MODEL] K_fermi"),MODEL_K_fermi,after_msg="[a.u.]")
 call msg('sr',com_compose_msg(body="[MODEL] Qc/K_fermi"),MODEL_E_ph/MODEL_effective_mass)
 !
 !... el
 if (STRING_same(MODEL_gkkp_kind,"frohlich")) call MODELS_ep_Fan(k,E,px)
 !
 !... ph
 call MODELS_pe_driver(k,q,E,px)
 !
end subroutine
