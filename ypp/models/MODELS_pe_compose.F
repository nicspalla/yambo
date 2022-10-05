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
subroutine MODELS_pe_compose(X,DUM,V,obs,mode,W)
 !
 use pars,                ONLY:SP
 use YPP_models,          ONLY:MODEL_PH,OMS_Q,SF_Q
 use MODELS,              ONLY:MODEL_E_ph,MODEL_ep_dV,MODEL_gkkp_kind
 use QP_m,                ONLY:QP_Sc_steps
 use stderr,              ONLY:STRING_same
 !
#include<memory.h>
 !
 type(MODEL_PH)    :: X,DUM,V
 character(*)      :: obs,mode
 complex(SP)       :: W(QP_Sc_steps)
 !
 ! Work Space
 !
 integer           :: i_oms,i_sf,i_l,iw
 complex(SP)       :: Q_sq_Gb_sq,OMS_weight,delta_X_oms,SF_weight(QP_Sc_steps)
 !
 ! Filling: V_st, V_oms, Eph,PI, D
 !=================================
 !... OMS
 do i_oms=1,OMS_Q%N
   !
   if (STRING_same(MODEL_gkkp_kind,"Debye"    )) Q_sq_Gb_sq=2.*MODEL_ep_dV**2*OMS_Q%val(i_oms)**2
   if (STRING_same(MODEL_gkkp_kind,"Frohlich" )) Q_sq_Gb_sq=2.*MODEL_ep_dV**2
   if (STRING_same(obs,"V")) Q_sq_Gb_sq=OMS_Q%val(i_oms)**2
   !
   i_sf=-1
   do i_l=1,SF_Q%N
     if (SF_Q%indx(i_l)==OMS_Q%indx(i_oms)) i_sf=i_l
   enddo
   !
   ! Q^2 dV^2
   select case (mode)
     case('bb')
       OMS_weight=Q_sq_Gb_sq/OMS_Q%val(i_oms)**2
       if (i_sf>0) SF_weight=OMS_weight
     case('bs')
       OMS_weight=Q_sq_Gb_sq*V%STATIC(i_oms)
       if (i_sf>0) SF_weight=OMS_weight
     case('ss')
       OMS_weight=Q_sq_Gb_sq*(V%STATIC(i_oms)*OMS_Q%val(i_oms))**2.
       if (i_sf>0) SF_weight=OMS_weight
     case('bd')
       OMS_weight=Q_sq_Gb_sq*V%OMS(i_oms)
       if (i_sf>0) SF_weight(:)=Q_sq_Gb_sq*V%SF(i_sf,:)
   end select
   !
   delta_X_oms=X%OMS(i_oms)-X%STATIC(i_oms)
   !
   select case (obs)
     case('V')
       DUM%OMS(i_oms)=OMS_weight
       if (i_sf>0) DUM%SF(i_sf,:)=SF_weight(:)
     case('PI')
       DUM%OMS(i_oms)=delta_X_oms*OMS_weight
       if (i_sf>0) DUM%SF(i_sf,:)=(X%SF(i_sf,:)-X%STATIC(i_oms))*SF_weight(:)
     case('Eph')
       DUM%OMS(i_oms)=sqrt(MODEL_E_ph*(MODEL_E_ph+delta_X_oms*OMS_weight))
     case('D')
       if (i_sf>0) then
         do iw=1,QP_Sc_steps
           DUM%SF(i_sf,iw)=MODEL_E_ph/(W(iw)**2-MODEL_E_ph**2-&
&                          MODEL_E_ph*(X%SF(i_sf,iw)-X%STATIC(i_oms))*SF_weight(iw))
         enddo
       endif
   end select
 enddo
 !
end subroutine MODELS_pe_compose
