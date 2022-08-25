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
subroutine MODELS_ep_Pi_exact(q,NQ,Q_todo,iq_c)
 !
 use pars,                ONLY:SP,pi,cI
 use YPP_models,          ONLY:E_jell,MODEL_K_fermi
 use MODELS,              ONLY:MODEL_E_ph,MODEL_ep_dV,MODEL_effective_mass,MODEL_gkkp_kind
 use stderr,              ONLY:STRING_same
 use R_lattice,           ONLY:bz_samp,RL_vol
 use vec_operate,         ONLY:iku_v_norm
 use OUTPUT,              ONLY:OUTPUT_driver
 !
#include<memory.h>
 !
 type(bz_samp), intent(in)   :: q
 integer                     :: NQ,Q_todo(q%nibz),iq_c(-1:1)
 !
 ! Work Space
 !
 integer       :: iq,is,i_sign,ik,ib
 real(SP)      :: q_mod,alpha,beta,dist(-1:1)
 complex(SP)   :: OMS_exact(-1:1)
 ! 
 dist=10.
 iq_c=0
 do is=1,NQ
   iq=Q_todo(is)
   q_mod=iku_v_norm(q%pt(iq,:))
   do i_sign=-1,1,2
     if ( abs(E_jell(q%pt(iq,:))-MODEL_E_ph)<dist(i_sign)) then
       iq_c(i_sign)=iq
       dist(i_sign)=abs(E_jell(q%pt(iq,:))-MODEL_E_ph)
     endif
   enddo
 enddo
 !
 call OUTPUT_driver("q_mod_EXACT",action="reset")
 call OUTPUT_driver("q_mod_EXACT",action="open")
 do is=1,NQ
   iq=Q_todo(is)
   q_mod=iku_v_norm(q%pt(iq,:))
 enddo
 !
 do is=1,NQ
   !
   iq=Q_todo(is)
   q_mod=iku_v_norm(q%pt(iq,:))
   !
   call OUTPUT_driver("q_mod_EXACT",TITLES=(/"|q|"/),R_VALUES=(/q_mod/))
   !
   OMS_exact=0._SP
   !
   ! Im
   do i_sign=-1,1,2
     q_mod=iku_v_norm(q%pt(iq,:))
     alpha=i_sign*MODEL_E_ph-E_jell(q%pt(iq,:))
     beta=abs(alpha*MODEL_effective_mass/q_mod)
     if (abs(beta)>MODEL_K_fermi) cycle
     OMS_exact(i_sign)=OMS_exact(i_sign)-pi**2*MODEL_effective_mass/q_mod*(MODEL_K_fermi**2-beta**2)
   enddo
   !
   OMS_exact=OMS_exact*cI*2.*MODEL_ep_dV**2/RL_vol
   !
   if (STRING_same(MODEL_gkkp_kind,"Frohlich" )) OMS_exact=OMS_exact/q_mod**2.
   !
   call OUTPUT_driver("q_mod_EXACT",TITLES=(/"-Im[PI(Wo)]"/),R_VALUES=(/-aimag(OMS_exact(+1)-OMS_exact(-1))/),UNIT="meV")
   call OUTPUT_driver("q_mod_EXACT",action="write")
   !
 enddo
 !
 call OUTPUT_driver("q_mod_EXACT",action="close")
 !
end subroutine MODELS_ep_Pi_exact
