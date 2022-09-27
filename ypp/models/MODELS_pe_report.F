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
subroutine MODELS_pe_report(NUM,EXACT,q,W)
 !
 use pars,                ONLY:SP,schlen
 use YPP_models,          ONLY:MODEL_PH,MODEL_N_masses,SF_Q,SF_mass,OMS_Q,MODEL_masses
 use MODELS,              ONLY:MODEL_K_fermi,MODEL_E_ph
 use QP_m,                ONLY:QP_Sc_steps
 use com,                 ONLY:msg,com_compose_msg
 use OUTPUT,              ONLY:OUTPUT_driver
 use units,               ONLY:HA2EV
 use R_lattice,           ONLY:bz_samp
 use stderr,              ONLY:intc
 !
 implicit none
 !
 type(MODEL_PH)              :: NUM,EXACT(MODEL_N_masses)
 type(bz_samp), intent(in)   :: q
 complex(SP)                 :: W(QP_Sc_steps)
 !
 ! Work Space
 !
 integer           :: i_oms,i_mass,i_sf,iw,ic,IND_oms(SF_Q%N)
 real(SP)          :: val(2),mass
 complex(SP)       :: W_oms(3),D
 character(schlen) :: string
 !
 !... report
 do i_oms=1,OMS_Q%N
   do i_sf=1,SF_Q%N
     if (SF_Q%indx(i_sf)==OMS_Q%indx(i_oms)) then
       i_mass=SF_mass%indx(i_sf)
       val=(/OMS_Q%val(i_oms)/MODEL_K_fermi,SF_mass%val(i_sf)/)
       call msg('sr',com_compose_msg(body="[MODEL] Pi_OMS@IQ "//trim(intc(OMS_Q%indx(i_oms))),post="@(Q/Kf Mass)"),val)
       val=(/real(EXACT(i_mass)%PI_OMS(i_oms)),aimag(EXACT(i_mass)%PI_OMS(i_oms))/)*HA2EV*1000.
       call msg('sr',com_compose_msg(body="[MODEL] Exact",post="(Re Im)"),val,after_msg="[meV]")
       IND_oms(i_sf)=i_oms
       if (i_sf<SF_Q%N) cycle
       val=(/real(NUM%PI_OMS(i_oms)),aimag(NUM%PI_OMS(i_oms))/)*HA2EV*1000.
       call msg('sr',com_compose_msg(body="[MODEL] Numerical",post="(Re Im)"),val,after_msg="[meV]")
     endif
   enddo
 enddo
 !
 !..ph_OMS_EXACT
 string="ph_OMS_EXACT"
 call OUTPUT_driver(string,action="open")
 do i_mass=1,MODEL_N_masses
   do i_oms=1,OMS_Q%N
     W_oms(1)=sqrt(MODEL_E_ph*(MODEL_E_ph+EXACT(i_mass)%PI_OMS(i_oms)-EXACT(i_mass)%PI_ST(i_oms)))/MODEL_E_ph
     call OUTPUT_driver(string,TITLES=(/"Mass"/),R_VALUES=(/MODEL_masses(i_mass)/))
     call OUTPUT_driver(string,TITLES=(/"|q|/Kf"/),R_VALUES=(/OMS_Q%val(i_oms)/MODEL_K_fermi/))
     call OUTPUT_driver(string,TITLES=(/"Re[W_oms]/Wo"/),R_VALUES=real((/W_oms(1)/)))
     call OUTPUT_driver(string,TITLES=(/"|Im[W_oms]/Wo|"/),R_VALUES=(/abs(aimag(W_oms(1)))/))
     call OUTPUT_driver(string,action="write")
   enddo
 enddo
 call OUTPUT_driver(string,action="close")
 !
 !..ph_OMS/ST_EXACT_vs_NUM
 do ic=1,2
   if (ic==1) string="PI_OMS_EXACT_vs_NUM"
   if (ic==2) string="PI_ST_EXACT_vs_NUM"
   call OUTPUT_driver(string,action="open")
   do i_oms=1,OMS_Q%N
     call OUTPUT_driver(string,TITLES=(/"|q|/Kf"/),R_VALUES=(/OMS_Q%val(i_oms)/MODEL_K_fermi/))
     if (ic==1) then
       W_oms(1)=EXACT(MODEL_N_masses)%PI_OMS(i_oms)
       W_oms(2)=NUM%PI_OMS(i_oms)
     else
       W_oms(1)=EXACT(MODEL_N_masses)%PI_ST(i_oms)
       W_oms(2)=NUM%PI_ST(i_oms)
     endif
     call OUTPUT_driver(string,TITLES=(/"Re[PI_e]"/),R_VALUES=real((/W_oms(1)/)),UNIT="meV")
     call OUTPUT_driver(string,TITLES=(/"Re[PI_n]"/),R_VALUES=real((/W_oms(2)/)),UNIT="meV")
     call OUTPUT_driver(string,TITLES=(/"|Im[PI_e]|"/),R_VALUES=(/abs(aimag(W_oms(1)))/),UNIT="meV")
     call OUTPUT_driver(string,TITLES=(/"|Im[PI_n]|"/),R_VALUES=(/abs(aimag(W_oms(2)))/),UNIT="meV")
     call OUTPUT_driver(string,action="write")
   enddo
   call OUTPUT_driver(string,action="close")
 enddo
 !
 !... .D/PI_ph_Q###_Branch_1_EXACT
 do i_sf=1,SF_Q%N
   do ic=1,2
     If (ic==1) string="PI_ph_Q"//trim(intc(SF_Q%indx(i_sf)))//"_Branch_1_EXACT"
     If (ic==2) string="D_ph_Q"//trim(intc(SF_Q%indx(i_sf)))//"_Branch_1_EXACT"
     call OUTPUT_driver(string,action="open")
     i_mass=SF_mass%indx(i_sf)
     call msg('o '//string,'# M*                ',MODEL_masses(i_mass),INDENT=0)
     call msg('o '//string,'# |Q|/K_fermi       ',SF_Q%val(i_sf)/MODEL_K_fermi,INDENT=0)
     val(1)=real(EXACT(i_mass)%PI_oms(IND_oms(i_sf))-EXACT(i_mass)%PI_ST(IND_oms(i_sf)))
     val(2)=aimag(EXACT(i_mass)%PI_oms(IND_oms(i_sf)))
     call msg('o '//string,'# Re[\D\PI(Wo)]  [meV]',val(1)*HA2EV*1000.,INDENT=0)
     call msg('o '//string,'# Im[\PI(Wo)]    [meV]',val(2)*HA2EV*1000.,INDENT=0)
     do iw=1,QP_Sc_steps
       call OUTPUT_driver(string,TITLES=(/"E [meV]"/),R_VALUES=(/real(W(iw))/),UNIT="meV")
       if (ic==1) then
         val(1)=aimag(EXACT(i_mass)%PI_w(i_sf,iw))
         val(2)=real(EXACT(i_mass)%PI_w(i_sf,iw)-EXACT(i_mass)%PI_ST(IND_oms(i_sf)))
         call OUTPUT_driver(string,TITLES=(/"Im[\Pi(w)] [meV]"/),R_VALUES=val(1:1),UNIT="meV")
         call OUTPUT_driver(string,TITLES=(/"Re[\Pi(w)] [meV]"/),R_VALUES=val(2:2),UNIT="meV")
       else
         D=MODEL_E_ph/(W(iw)**2-MODEL_E_ph**2-MODEL_E_ph*(EXACT(i_mass)%PI_w(i_sf,iw)-EXACT(i_mass)%PI_ST(IND_oms(i_sf))))
         call OUTPUT_driver(string,TITLES=(/"-Im[D(w)]"/),R_VALUES=(/-aimag(D)/))
         call OUTPUT_driver(string,TITLES=(/"Re[D(w)]"/),R_VALUES=(/real(D)/))
       endif
       call OUTPUT_driver(string,action="write")
     enddo
     call OUTPUT_driver(string,action="close")
  enddo
 enddo
 !
end subroutine MODELS_pe_report
