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
subroutine ELPH_model_jellium(q)
 !
 use units,         ONLY:HA2EV
 use com,           ONLY:msg
 use pars,          ONLY:SP,DP,rZERO
 use vec_operate,   ONLY:iku_v_norm
 use RIM,           ONLY:RIM_n_rand_pts
 use R_lattice,     ONLY:bz_samp
 use MODELS,        ONLY:MODEL_E_ph,MODEL_effective_mass,MODEL_elph_alpha,MODEL_E_ph,MODEL_ep_dV
 use LIVE_t,        ONLY:live_timing
 use parallel_int,  ONLY:PP_redux_wait
 use QP_m,          ONLY:QP_Sc
 use parallel_m,    ONLY:PAR_IND_Q_bz_ID,PAR_IND_Q_bz,PAR_COM_Q_INDEX
 !
 implicit none
 !
 type(bz_samp)      :: q
 !
 ! Work Space
 !
 integer  :: iq,N_out,ip
 real(DP) :: OMS_dp
 real(SP) :: OMS(1),q_norm_square,q_grid_norm_square,pts(3,RIM_n_rand_pts),OMS_exact,integral
 !
 call section('=','Jellium Fan Self-Energy')
 !
 OMS(1)=rZERO
 !
 call rim_random_points_generator('Unit-Cell',q%nbz,pts,N_out)
 !
 call live_timing('Fan SE',PAR_IND_Q_bz%n_of_elements(PAR_IND_Q_bz_ID+1))
 !
 do iq=1,q%nbz
   !
   if (.not.PAR_IND_Q_bz%element_1D(iq)) cycle
   !
   OMS_dp=0._DP
   !
   q_grid_norm_square=iku_v_norm(q%pt(iq,:))**2
   integral=1./(MODEL_E_ph+q_grid_norm_square/2./MODEL_effective_mass)
   if (RIM_n_rand_pts>0) then
     do ip=1,RIM_n_rand_pts
       q_norm_square=iku_v_norm(q%pt(iq,:)+pts(:,ip))**2
       OMS_dp=OMS_dp-MODEL_ep_dV**2./q_norm_square*integral
     enddo
   else
     if (iq>1) OMS_dp=-MODEL_ep_dV**2./iku_v_norm(q%pt(iq,:))**2*integral
   endif
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
 if (RIM_n_rand_pts>0) OMS(1)=OMS(1)/float(RIM_n_rand_pts)
 OMS(1)=OMS(1)/float(q%nbz)
 OMS_exact=-MODEL_elph_alpha*MODEL_E_ph
 !
 QP_Sc=OMS(1)
 !
 call msg('nr','[El-Ph] Jellium Integral (calc/exact)',(/OMS(1)*HA2EV,OMS_exact*HA2EV/),"[ev]")
 !
end subroutine
