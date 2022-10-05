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
subroutine MODELS_pe_X_to_VERTEX(what,i_mass,X,V,W)
 !
 use pars,                ONLY:pi,schlen,SP
 use YPP_models,          ONLY:MODEL_PH,SF_Q,OMS_Q,SF_mass,MODEL_masses
 use MODELS,              ONLY:MODEL_V
 use D_lattice,           ONLY:DL_vol
 use QP_m,                ONLY:QP_Sc_steps
 use OUTPUT,              ONLY:OUTPUT_driver
 use stderr,              ONLY:real2ch,STRING_remove,intc
 !
 implicit none
 !
 character(*)                :: what
 integer                     :: i_mass
 type(MODEL_PH)              :: X,V
 complex(SP)                 :: W(QP_Sc_steps)
 !
 ! Work Space
 !
 integer           :: i_sf,i_oms,iw
 character(schlen) :: file_name
 complex(SP)       :: eels,eps
 !
 do i_oms=1,OMS_Q%N
   V%OMS(i_oms)=1./(OMS_Q%val(i_oms)**2.-4.*pi*MODEL_V*X%OMS(i_oms)/DL_vol)
   V%STATIC(i_oms)=1./(OMS_Q%val(i_oms)**2.-4.*pi*MODEL_V*X%STATIC(i_oms)/DL_vol)
   do i_sf=1,SF_Q%N
     if (OMS_Q%indx(i_oms)==OMS_Q%indx(i_sf).and.i_mass==SF_mass%indx(i_sf)) then
       !
       if (what=="exact") then
         file_name="eels_q"//trim(intc(SF_Q%indx(i_sf)))//"_M"//trim(real2ch(MODEL_masses(SF_mass%indx(i_sf))))
         file_name=STRING_remove(file_name," ",replace="")
         call OUTPUT_driver(file_name,action="open")
       endif
       !
       do iw=1,QP_Sc_steps
         V%SF(i_sf,iw)=1./(SF_Q%val(i_sf)**2.-4.*pi*MODEL_V*X%SF(i_sf,iw)/DL_vol)
         eels=SF_Q%val(i_sf)**2.*V%SF(i_sf,iw)
         eps=1.-4*pi/SF_Q%val(i_sf)**2.*MODEL_V*X%SF(i_sf,iw)/DL_vol
         if (what=="exact") then
           call OUTPUT_driver(file_name,TITLES=(/"E"/),R_VALUES=(/real(W(iw))/),UNIT="meV")
           call OUTPUT_driver(file_name,TITLES=(/" Im[eels]"," Re[eels]"/),R_VALUES=(/abs(aimag(eels)),real(eels)/))
           call OUTPUT_driver(file_name,TITLES=(/" Im[eps]"," Re[eps]"/),R_VALUES=(/abs(aimag(eps)),real(eps)/))
           call OUTPUT_driver(file_name,action="write")
         endif
       enddo
       if (what=="exact") call OUTPUT_driver(file_name,action="close")
     endif
   enddo
 enddo
 !
end subroutine MODELS_pe_X_to_VERTEX
