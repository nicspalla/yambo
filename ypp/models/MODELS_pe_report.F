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
subroutine MODELS_pe_report(EXACT,NUM,N_vertex,E_vertex,obs,mode,W)
 !
 use pars,                ONLY:SP,schlen
 use YPP_models,          ONLY:MODEL_PH,MODEL_N_masses,SF_Q,OMS_Q,MODEL_masses,SF_mass
 use MODELS,              ONLY:MODEL_K_fermi,MODEL_E_ph,MODEL_ep_dV,MODEL_gkkp_kind
 use QP_m,                ONLY:QP_Sc_steps
 use OUTPUT,              ONLY:OUTPUT_driver
 use stderr,              ONLY:STRING_same,intc
 use units,               ONLY:HA2EV
 use com,                 ONLY:msg
 !
 implicit none
 !
 type(MODEL_PH)              :: EXACT(MODEL_N_masses)
 type(MODEL_PH),optional     :: N_vertex,E_vertex(MODEL_N_masses),NUM
 character(*)  ,optional     :: obs,mode
 complex(SP)   ,optional     :: W(QP_Sc_steps)
 !
 ! Work Space
 !
 integer           :: i_oms,i_mass,i_sf,ic,IND_oms(SF_Q%N),i_G,iw
 complex(SP)       :: PI_N,PI_E_oms,PI_E_st,E_oms,PI_E,D
 real(SP)          :: val(2)
 !
 ! Gsq
 real(SP)          :: Qsq
 complex(SP)       :: Gsq_E(OMS_Q%N,MODEL_N_masses,4) ! bb,ss,bs,bd
 complex(SP)       :: Gsq_N(OMS_Q%N,4) ! bb,ss,bs,bd
 !
 character(schlen) :: string(3)
 !
 i_G=1
 if (mode=="ss") i_G=2
 if (mode=="bs") i_G=3
 if (mode=="bd") i_G=4
 !
 ! Setup...
 do i_oms=1,OMS_Q%N
   Qsq=1.
   if (STRING_same(MODEL_gkkp_kind,"Debye" )) Qsq=OMS_Q%val(i_oms)**2
   do i_sf=1,SF_Q%N
     if (SF_Q%indx(i_sf)==OMS_Q%indx(i_oms)) IND_oms(i_sf)=i_oms
   enddo
   do i_mass=1,MODEL_N_masses
     Gsq_E(i_oms,i_mass,1)=2.*MODEL_ep_dV**2
     if (STRING_same(MODEL_gkkp_kind,"Frohlich" )) Gsq_E(i_oms,i_mass,1)=Gsq_E(i_oms,i_mass,1)/OMS_Q%val(i_oms)**2
     if (present(E_vertex)) then
       Gsq_E(i_oms,i_mass,2)=2.*MODEL_ep_dV**2.*(E_vertex(i_mass)%STATIC(i_oms)*Qsq)**2.
       Gsq_E(i_oms,i_mass,3)=2.*MODEL_ep_dV**2.*E_vertex(i_mass)%STATIC(i_oms)*Qsq
       Gsq_E(i_oms,i_mass,4)=2.*MODEL_ep_dV**2.*E_vertex(i_mass)%OMS(i_oms)*Qsq
     endif
   enddo
   Gsq_N(i_oms,1)=Gsq_E(i_oms,MODEL_N_masses,1)
   if (present(N_vertex)) then
     Gsq_N(i_oms,2)=2.*MODEL_ep_dV**2.*(N_vertex%STATIC(i_oms)*Qsq)**2.
     Gsq_N(i_oms,3)=2.*MODEL_ep_dV**2.*N_vertex%STATIC(i_oms)*Qsq
     Gsq_N(i_oms,4)=2.*MODEL_ep_dV**2.*N_vertex%OMS(i_oms)*Qsq
   endif
 enddo
 !
 string(1)=obs//"_"//mode//"_OMS_EXACT"
 string(2)=obs//"_"//mode//"_OMS_exact_vs_num"
 string(3)=obs//"_"//mode//"_ST_exact_vs_num"
 !
 if (.not.present(NUM).and.obs=="Eph") call OUTPUT_driver(string(1),action="open")
 if (     present(NUM)) then
   call OUTPUT_driver(string(2),action="open")
   call OUTPUT_driver(string(3),action="open")
 endif
 !
 do i_mass=1,MODEL_N_masses
   do i_oms=1,OMS_Q%N
     !
     PI_E_oms=EXACT(i_mass)%OMS(i_oms)*Gsq_E(i_oms,i_mass,i_G)
     PI_E_st =EXACT(i_mass)%STATIC(i_oms)*Gsq_E(i_oms,i_mass,i_G)
     E_oms   =sqrt(MODEL_E_ph*(MODEL_E_ph+PI_E_oms-PI_E_st))/MODEL_E_ph
     call OUTPUT_driver(string(1),TITLES=(/"Mass"/),R_VALUES=(/MODEL_masses(i_mass)/))
     call OUTPUT_driver(string(1),TITLES=(/"|q|/Kf"/),R_VALUES=(/OMS_Q%val(i_oms)/MODEL_K_fermi/))
     call OUTPUT_driver(string(1),TITLES=(/"Re["//obs//"]/Eo"/),R_VALUES=real((/E_oms/)))
     call OUTPUT_driver(string(1),TITLES=(/"|Im["//obs//"]/Eo|"/),R_VALUES=(/abs(aimag(E_oms))/))
     call OUTPUT_driver(string(1),action="write")
     !
     if (i_mass==MODEL_N_masses.and.present(NUM)) then
       do ic=1,2
         if (ic==1) PI_N=NUM%OMS(i_oms)*Gsq_N(i_oms,i_G)
         if (ic==1) PI_E=PI_E_oms
         if (ic==2) PI_N=NUM%STATIC(i_oms)*Gsq_N(i_oms,i_G)
         if (ic==2) PI_E=PI_E_st
         call OUTPUT_driver(string(1+ic),TITLES=(/"|q|/Kf"/),R_VALUES=(/OMS_Q%val(i_oms)/MODEL_K_fermi/))
         call OUTPUT_driver(string(1+ic),TITLES=(/"Re["//obs//"_e]"/),R_VALUES=real((/PI_E/)),UNIT="meV")
         call OUTPUT_driver(string(1+ic),TITLES=(/"Re["//obs//"_n]"/),R_VALUES=real((/PI_N/)),UNIT="meV")
         call OUTPUT_driver(string(1+ic),TITLES=(/"|Im["//obs//"_e]|"/),R_VALUES=(/abs(aimag(PI_E))/),UNIT="meV")
         call OUTPUT_driver(string(1+ic),TITLES=(/"|Im["//obs//"_n]|"/),R_VALUES=(/abs(aimag(PI_N))/),UNIT="meV")
         call OUTPUT_driver(string(1+ic),action="write")
       enddo
     endif
     !
   enddo
   !
 enddo
 !
 if (.not.present(NUM)) call OUTPUT_driver(string(1),action="close")
 if (     present(NUM)) then
   call OUTPUT_driver(string(2),action="close")
   call OUTPUT_driver(string(3),action="close")
 endif
 !
 if (present(NUM).or.obs=="Eph") return
 !
 !... SF EXACT
 do i_sf=1,SF_Q%N
   i_mass=SF_mass%indx(i_sf)
   i_oms=IND_oms(i_sf)
   Qsq=1.
   if (STRING_same(MODEL_gkkp_kind,"Debye" )) Qsq=OMS_Q%val(i_oms)**2
   PI_E_oms=EXACT(i_mass)%OMS(i_oms)*Gsq_E(i_oms,i_mass,i_G)
   PI_E_st =EXACT(i_mass)%STATIC(i_oms)*Gsq_E(i_oms,i_mass,i_G)
   E_oms   =sqrt(MODEL_E_ph*(MODEL_E_ph+PI_E_oms-PI_E_st))
   string(1)=obs//"_"//mode//"_ph_Q"//trim(intc(SF_Q%indx(i_sf)))//"_Branch_1_EXACT"
   call OUTPUT_driver(string(1),action="open")
   call msg('o '//string(1),'# M*                ',MODEL_masses(i_mass),INDENT=0)
   call msg('o '//string(1),'# |Q|/K_fermi       ',SF_Q%val(i_sf)/MODEL_K_fermi,INDENT=0)
   call msg('o '//string(1),'# Re[E_oms]    [meV]',real(E_oms)*HA2EV*1000.,INDENT=0)
   call msg('o '//string(1),'# Im[E_oms]    [meV]',aimag(E_oms)*HA2EV*1000.,INDENT=0)
   do iw=1,QP_Sc_steps
     call OUTPUT_driver(string(1),TITLES=(/"E [meV]"/),R_VALUES=(/real(W(iw))/),UNIT="meV")
     ! 
     PI_E=EXACT(i_mass)%SF(i_sf,iw)-EXACT(i_mass)%STATIC(IND_oms(i_sf))
     if (i_G<=3) then
       PI_E=PI_E*Gsq_E(i_oms,i_mass,i_G)
     else
       PI_E=PI_E*2.*MODEL_ep_dV**2*E_vertex(i_mass)%SF(i_sf,iw)*Qsq
     endif
     !
     If (STRING_same(obs,"PI"))  then
       call OUTPUT_driver(string(1),TITLES=(/"Im[\Pi(w)] [meV]"/),R_VALUES=(/real(PI_E)/),UNIT="meV")
       call OUTPUT_driver(string(1),TITLES=(/"Re[\Pi(w)] [meV]"/),R_VALUES=(/aimag(PI_E)/),UNIT="meV")
     endif
     If (STRING_same(obs,"D"))  then
       D=MODEL_E_ph/(W(iw)**2-MODEL_E_ph**2-MODEL_E_ph*PI_E)
       call OUTPUT_driver(string(1),TITLES=(/"-Im[D(w)]"/),R_VALUES=(/-aimag(D)/))
       call OUTPUT_driver(string(1),TITLES=(/"Re[D(w)]"/),R_VALUES=(/real(D)/))
     endif
     call OUTPUT_driver(string(1),action="write")
   enddo
   call OUTPUT_driver(string(1),action="close")
 enddo
 !
end subroutine MODELS_pe_report
