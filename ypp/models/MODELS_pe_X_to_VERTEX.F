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
subroutine MODELS_pe_X_to_VERTEX(X,V)
 !
 use YPP_models,          ONLY:MODEL_PH,SF_Q,OMS_Q
 use MODELS,              ONLY:MODEL_V
 use QP_m,                ONLY:QP_Sc_steps
 !
 implicit none
 !
 type(MODEL_PH)              :: X,V
 !
 ! Work Space
 !
 integer :: i_sf,i_oms,iw
 !
 do i_oms=1,OMS_Q%N
   V%OMS(i_oms)=1./(OMS_Q%val(i_oms)**2.-MODEL_V*X%OMS(i_oms))
   V%STATIC(i_oms)=1./(OMS_Q%val(i_oms)**2.-MODEL_V*X%STATIC(i_oms))
   do i_sf=1,SF_Q%N
     if (OMS_Q%indx(i_oms)==OMS_Q%indx(i_sf)) then
       do iw=1,QP_Sc_steps
         V%SF(i_sf,iw)=1./(SF_Q%val(i_sf)**2.-MODEL_V*X%SF(i_sf,iw))
       enddo
     endif
   enddo
 enddo
 !
end subroutine MODELS_pe_X_to_VERTEX
