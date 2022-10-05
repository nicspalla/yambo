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
subroutine MODELS_pe_report(obs,mode,EXACT,NUM,N_vertex,E_vertex,W)
 !
 use pars,                ONLY:SP,schlen,cZERO
 use YPP_models,          ONLY:MODEL_PH,MODEL_N_masses,SF_Q,OMS_Q,MODEL_masses,SF_mass
 use MODELS,              ONLY:MODEL_K_fermi,MODEL_E_ph
 use com,                 ONLY:msg
 use QP_m,                ONLY:QP_Sc_steps
 use OUTPUT,              ONLY:OUTPUT_driver
 use stderr,              ONLY:STRING_same,intc,real2ch,STRING_remove
 use units,               ONLY:HA2EV
 !
#include<memory.h>
 !
 type(MODEL_PH)              :: EXACT(MODEL_N_masses),NUM,N_vertex,E_vertex(MODEL_N_masses)
 character(*)                :: obs,mode
 complex(SP)                 :: W(QP_Sc_steps)
 !
 ! Work Space
 !
 type(MODEL_PH)    :: DUM(MODEL_N_masses+1)
 integer           :: i_oms,i_mass,i_mass_,ic,i_sf,iw
 complex(SP)       :: PI_oms
 character(schlen) :: string(4)
 !
 do ic=1,MODEL_N_masses+1
   YAMBO_ALLOC(DUM(ic)%OMS,(OMS_Q%N))
   YAMBO_ALLOC(DUM(ic)%STATIC,(OMS_Q%N))
   YAMBO_ALLOC(DUM(ic)%SF,(SF_Q%N,QP_Sc_steps))
   DUM(ic)%OMS=cZERO
   DUM(ic)%STATIC=cZERO
   DUM(ic)%SF=cZERO
 enddo
 !
 ! Filling: V,Eph,PI,D
 !
 do i_mass=1,MODEL_N_masses
   call MODELS_pe_compose(EXACT(i_mass),DUM(i_mass),E_vertex(i_mass),obs,mode,W)
 enddo
 call MODELS_pe_compose(NUM,DUM(MODEL_N_masses+1),N_vertex,obs,mode,W)
 !
 if (.not.obs=="D") then
   !
   string(1)=obs//"_"//mode//"_JellMass_EXACT"
   string(2)=obs//"_"//mode//"_JellMass_NUM"
   string(3)=obs//"_"//mode//"_ALLMasses_EXACT"
   if (mode=="none") then
     string(1)=obs//"_JellMass_EXACT"
     string(2)=obs//"_JellMass_NUM"
     string(3)=obs//"_ALLMasses_EXACT"
   endif
   !
   do ic=1,3
     call OUTPUT_driver(string(ic),action="open")
   enddo
   !
   do i_mass=1,MODEL_N_masses+2
     i_mass_=i_mass
     string(4)=string(3)
     if (i_mass==MODEL_N_masses+1) then
       string(4)=string(1)
       i_mass_=MODEL_N_masses
     else if (i_mass==MODEL_N_masses+2) then
       string(4)=string(2)
       i_mass_=MODEL_N_masses+1
     endif
     do i_oms=1,OMS_Q%N
       if (i_mass<=MODEL_N_masses) call OUTPUT_driver(string(4),TITLES=(/"Mass"/),R_VALUES=(/MODEL_masses(i_mass)/))
       call OUTPUT_driver(string(4),TITLES=(/"|q|/Kf"/),R_VALUES=(/OMS_Q%val(i_oms)/MODEL_K_fermi/))
       if (STRING_same(obs,"V")) then
         call OUTPUT_driver(string(4),TITLES=(/"Re["//obs//"]"/),R_VALUES=(/real(DUM(i_mass_)%OMS(i_oms))/))
         call OUTPUT_driver(string(4),TITLES=(/"Im["//obs//"]"/),R_VALUES=(/aimag(DUM(i_mass_)%OMS(i_oms))/))
       else
         call OUTPUT_driver(string(4),TITLES=(/" Re["//obs//"]"/),R_VALUES=(/real(DUM(i_mass_)%OMS(i_oms))/),UNIT="meV")
         call OUTPUT_driver(string(4),TITLES=(/"-Im["//obs//"]"/),R_VALUES=(/-aimag(DUM(i_mass_)%OMS(i_oms))/),UNIT="meV")
        endif
       call OUTPUT_driver(string(4),action="write")
     enddo
   enddo
   !
   do ic=1,3
     call OUTPUT_driver(string(ic),action="close")
   enddo
   !
 endif
 !
 if (.not.obs=="PI".and..not.obs=="D") return
 !
 do i_sf=1,SF_Q%N
   i_mass=SF_mass%indx(i_sf)
   string(1)=obs//"_"//mode//"_ph_Q"//trim(intc(SF_Q%indx(i_sf)))//"_M"//&
&            trim(real2ch(MODEL_masses(i_mass)))//"_Branch_1_EXACT"
   string(1)=STRING_remove(string(1)," ",replace="")
   call OUTPUT_driver(string(1),action="open")
   !
   do i_oms=1,OMS_Q%N
     if (SF_Q%indx(i_sf)==OMS_Q%indx(i_oms)) PI_oms=DUM(i_mass)%OMS(i_oms)
   enddo
   call msg('o '//string(1),'# M*                ',MODEL_masses(i_mass),INDENT=0)
   call msg('o '//string(1),'# |Q|/K_fermi       ',SF_Q%val(i_sf)/MODEL_K_fermi,INDENT=0)
   call msg('o '//string(1),'# Re[E_oms]    [meV]',real(sqrt(MODEL_E_ph*(MODEL_E_ph+PI_oms)))*HA2EV*1000.,INDENT=0)
   call msg('o '//string(1),'# |Im[E_oms]|  [meV]',-aimag(sqrt(MODEL_E_ph*(MODEL_E_ph+PI_oms)))*HA2EV*1000.,INDENT=0)
   !
   do iw=1,QP_Sc_steps
     call OUTPUT_driver(string(1),TITLES=(/"E [meV]"/),R_VALUES=(/real(W(iw))/),UNIT="meV")
     call OUTPUT_driver(string(1),TITLES=(/" Re["//obs//"] [meV]"/),&
&         R_VALUES=(/real(DUM(i_mass)%SF(i_sf,iw))/),UNIT="meV")
     call OUTPUT_driver(string(1),TITLES=(/"-Im["//obs//"] [meV]"/),&
&         R_VALUES=(/-aimag(DUM(i_mass)%SF(i_sf,iw))/),UNIT="meV")
     call OUTPUT_driver(string(1),action="write")
   enddo
   !
   call OUTPUT_driver(string(1),action="close")
   !
 enddo
 !
end subroutine MODELS_pe_report
