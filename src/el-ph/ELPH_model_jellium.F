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
subroutine ELPH_model_jellium(q,k,E,q_weight)
 !
 use units,          ONLY:HA2EV
 use com,            ONLY:msg
 use pars,           ONLY:SP,DP,rZERO
 use electrons,      ONLY:levels
 use R_lattice,      ONLY:bz_samp
 use MODELS,         ONLY:MODEL_E_ph,MODEL_effective_mass,MODEL_elph_alpha,MODEL_ep_dV
 use LIVE_t,         ONLY:live_timing
 use parallel_int,   ONLY:PP_redux_wait
 use parallel_m,     ONLY:PAR_IND_Q_bz_ID,PAR_IND_Q_bz,PAR_COM_Q_INDEX
 !
#include<memory.h>
 !
 type(bz_samp)      :: q,k
 type(levels)       :: E
 real(SP)           :: q_weight(q%nbz)
 !
 ! Work Space
 !
 integer  :: iq,ib
 real(DP) :: OMS_dp
 real(SP) :: OMS(1),OMS_exact,integral,E_q
 !
 call section('=','Jellium Fan Self-Energy')
 !
 OMS(1)=rZERO
 !
 call live_timing('Fan Jellium SE',PAR_IND_Q_bz%n_of_elements(PAR_IND_Q_bz_ID+1)*E%nb)
 !
 do ib=1,E%nb
   !
   OMS_dp=0._DP
   !
   do iq=1,q%nbz
     !
     if (.not.PAR_IND_Q_bz%element_1D(iq)) cycle
     !
     E_q=(E%E(ib,iq,1)-E%E(1,1,1))
     if (ib==1) then
       integral=q_weight(iq)/(MODEL_E_ph+E_q)
     else
       integral=1./((MODEL_E_ph+E_q)*E_q*2.*MODEL_effective_mass)/float(q%nbz)
     endif
     OMS_dp=OMS_dp-MODEL_ep_dV**2.*integral
     !
   enddo
   !
   OMS=OMS+OMS_dp
   !
   call live_timing(steps=1)
   !
 enddo
 !
 call live_timing( )
 !
 call PP_redux_wait(OMS,COMM=PAR_COM_Q_INDEX%COMM)
 !
 OMS_exact=-MODEL_elph_alpha*MODEL_E_ph
 !
 call msg('nrs','[El-Ph] Jellium Integral (calc/exact)',(/OMS(1)*HA2EV,OMS_exact*HA2EV/),"[ev]")
 !
end subroutine
