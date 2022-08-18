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
subroutine MODELS_energy_levels(k,E)
 !
 use units,            ONLY:HA2EV
 use pars,             ONLY:SP
 use MODELS,           ONLY:MODEL_H_kind,MODEL_overlap,MODEL_effective_mass,MODEL_Eg,MODEL_E_shells
 use stderr,           ONLY:STRING_same
 use R_lattice,        ONLY:bz_samp
 use electrons,        ONLY:levels,n_sp_pol
 use com,              ONLY:msg,com_compose_msg
 use vec_operate,      ONLY:iku_v_norm,sort
 !
#include<memory.h>
 !
 type(bz_samp), intent(in)      :: k
 type(levels ), intent(inout)   :: E
 !
 ! Work Space
 !
 integer  :: i1,i2,i3,ik,ib
 real(SP) :: E_max,k_mod
 !
 if (STRING_same(MODEL_H_kind,"2bands" )) then
   E%nb=2  
   YAMBO_ALLOC(E%E,(E%nb,k%nibz,n_sp_pol))
   do ik=1,k%nibz
     E%E(1,ik,:)=-( 2.*MODEL_overlap*(1-cos(iku_v_norm(k%pt(ik,:))))+MODEL_Eg/2. )
     E%E(2,ik,:)= ( 2.*MODEL_overlap*(1-cos(iku_v_norm(k%pt(ik,:))))+MODEL_Eg/2. )
   enddo
 endif
 !
 if (STRING_same(MODEL_H_kind,"jellium")) then
   E%nb=(2*MODEL_E_shells+1)**3
   YAMBO_ALLOC(E%E,(E%nb,k%nibz,n_sp_pol))
   E%nb=0
   do i1=-MODEL_E_shells,MODEL_E_shells
     do i2=-MODEL_E_shells,MODEL_E_shells
       do i3=-MODEL_E_shells,MODEL_E_shells
         E%nb=E%nb+1
         do ik=1,k%nibz
           k_mod=iku_v_norm(k%pt(ik,:))
           if (k_mod>=0._SP) E%E(E%nb,ik,1)=iku_v_norm(k%pt(ik,:)+(/i1,i2,i3/))**2./2./MODEL_effective_mass/HA2EV
           if (k_mod< 0._SP) E%E(E%nb,ik,1)=iku_v_norm(k%pt(ik,:)-(/i1,i2,i3/))**2./2./MODEL_effective_mass/HA2EV
         enddo
       enddo
     enddo
   enddo
   E_max=maxval(E%E)
   do ik=1,k%nibz
     call sort( E%E(:,ik,1) )
   enddo
 endif
 !
 call msg('s',com_compose_msg(body="[MODEL] Bands"),E%nb)
 call msg('s',com_compose_msg(body="[MODEL] Max energy"),E_max*HA2EV,after_msg="[eV]")
 !
end subroutine MODELS_energy_levels
