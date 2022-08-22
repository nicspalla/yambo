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
subroutine MODELS_ep_Fan(k,E,px)
 !
 use units,               ONLY:HA2EV
 use pars,                ONLY:SP
 use electrons,           ONLY:levels
 use R_lattice,           ONLY:bz_samp
 use units,               ONLY:HA2EV
 use MODELS,              ONLY:MODEL_gkkp_kind,MODEL_elph_alpha,MODEL_E_ph,MODEL_ep_dV,MODEL_effective_mass
 use ELPH,                ONLY:GKKP
 use com,                 ONLY:msg,com_compose_msg
 use LIVE_t,              ONLY:live_timing
 use parallel_m,          ONLY:myid,PP_indexes
 use parallel_int,        ONLY:PP_redux_wait
 !
#include<memory.h>
 !
 type(bz_samp),    intent(inout):: k
 type(levels ),    intent(inout):: E
 type(PP_indexes), intent(in)   :: px
 !
 ! Work Space
 !
 integer     :: ik,ib
 real(SP)    :: OMS_el(1),k_mod
 !
 call section("+","E-P Fan (electrons)")
 !
 MODEL_gkkp_kind="Frohlich"
 call ELPH_model_gkkp(GKKP)
 !
 ! Electrons
 !
 OMS_el=0._SP
 call live_timing("E-P OMS (electrons)",px%n_of_elements(myid+1))
 do ib=1,E%nb
   do ik=1,k%nibz
     if (.not.px%element_2D(ib,ik)) cycle
     k_mod=sqrt( (E%E(ib,ik,1)-E%E(1,1,1))*2.*MODEL_effective_mass )
     if (k_mod<1.E-5) cycle
     OMS_el=OMS_el+MODEL_ep_dV**2/k%nibz/k_mod**2/(MODEL_E_ph+E%E(ib,ik,1)-E%E(1,1,1))
     call live_timing(steps=1)
   enddo
 enddo
 call live_timing()
 call PP_redux_wait(OMS_el)
 !
 call msg('sr',com_compose_msg(body="[MODEL] OMS (el)",post="(calc exact)"),&
&                             (/OMS_el(1),MODEL_elph_alpha*MODEL_E_ph/)*HA2EV*1000.,after_msg="[meV]")
 !
end subroutine MODELS_ep_Fan
