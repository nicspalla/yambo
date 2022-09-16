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
subroutine MODELS_pe_report(NUM,EXACT)
 !
 use pars,                ONLY:SP
 use YPP_models,          ONLY:MODEL_PH,MODEL_N_masses,SF_Q
 use com,                 ONLY:msg,com_compose_msg
 use units,               ONLY:HA2EV
 !
 implicit none
 !
 type(MODEL_PH) :: NUM,EXACT(MODEL_N_masses)
 !
 ! Work Space
 !
 integer     :: is,i_p
 real(SP)    :: OMS_single_q(2)
 !
 do i_p=1,SF_Q%N
   is=SF_Q%indx(i_p)
   OMS_single_q=(/real(NUM%PI_OMS_w(is)),aimag(NUM%PI_OMS_w(is))/)*HA2EV*1000.
   call msg('sr',com_compose_msg(body="[MODEL] Pi_OMS",post="(numerical)"),OMS_single_q,after_msg="[meV]")
   OMS_single_q=(/real(EXACT(MODEL_N_masses)%PI_OMS_w(is)),aimag(EXACT(MODEL_N_masses)%PI_OMS_w(is))/)*HA2EV*1000.
   call msg('sr',com_compose_msg(body="[MODEL]",post="(exact)"),OMS_single_q,after_msg="[meV]")
 enddo
 !
end subroutine MODELS_pe_report

 ! SF's to plot
! character(schlen)  :: fname
! integer, parameter :: n_SF=6
! integer            :: SF_ind(n_SF,2),i_p
! complex(SP)        :: PIoms(n_SF,NQ),PIiW(n_SF,NQ),D(QP_Sc_steps),D_w(QP_Sc_steps),Integral,PIst(n_SF,NQ)
! complex(SP),external :: CIntegrate
 !
! fname="PI_vs_mass_and_q_mod_EXACT"
! call OUTPUT_driver(fname,action="open")
! !
! ! Report
! !-------
! ! ... all q
! ! 
! call OUTPUT_driver("q_mod_NUM",action="reset")
! call OUTPUT_driver("q_mod_NUM",action="open")
! do is=1,NQ
!   iq=Q_todo(is)
!   q_mod=iku_v_norm(q%pt(iq,:))
!   call OUTPUT_driver("q_mod_NUM",TITLES=(/"|q|"/),R_VALUES=(/q_mod/))
!   call OUTPUT_driver("q_mod_NUM",TITLES=(/"-Im[PI(Wo)]"/),R_VALUES=(/-aimag(PI_num%OMS(is))/),UNIT="meV")
!   call OUTPUT_driver("q_mod_NUM",TITLES=(/"Re[PI(Wo)]"/),R_VALUES=(/real(PI_num%OMS(is))/),UNIT="meV")
!   call OUTPUT_driver("q_mod_NUM",TITLES=(/"Re[PI(iWo)]"/),R_VALUES=(/real(PI_num%IW(is))/),UNIT="meV")
!   call OUTPUT_driver("q_mod_NUM",TITLES=(/"Re[PI(0)]"/),R_VALUES=(/real(PI_num%ST(is))/),UNIT="meV")
!   call OUTPUT_driver("q_mod_NUM",action="write")
! enddo
! call OUTPUT_driver("q_mod_NUM",action="close")
! !
! call PH_of(k)
! ! 
! is=NQ
! OMS_single_q=(/real(PI_num%OMS(is)-Pi_num%ST(is)),aimag(PI_num%OMS(is))/)*HA2EV*1000.
! call msg('sr',com_compose_msg(body="[MODEL] \Delta Pi_OMS",post="(numerical)"),OMS_single_q,after_msg="[meV]")
! OMS_single_q=(/real(PI_exact%OMS(is)-Pi_exact%ST(is)),aimag(PI_exact%OMS(is))/)*HA2EV*1000.
! call msg('sr',com_compose_msg(body="[MODEL] \Delta Pi_OMS",post="(exact)"),OMS_single_q,after_msg="[meV]")
! !
! OMS_single_q=(/real(PI_num%ST(is)),aimag(PI_num%ST(is))/)*HA2EV*1000.
! call msg('sr',com_compose_msg(body="[MODEL] PI_static",post="(numerical)"),OMS_single_q,after_msg="[meV]")
! OMS_single_q=(/real(PI_exact%ST(is)),aimag(PI_exact%ST(is))/)*HA2EV*1000.
! call msg('sr',com_compose_msg(body="[MODEL] PI_static",post="(exact)"),OMS_single_q,after_msg="[meV]")
! !
! OMS_single_q=(/real(PI_num%IW(is)-Pi_num%ST(is)),aimag(PI_num%IW(is))/)*HA2EV*1000.
! call msg('sr',com_compose_msg(body="[MODEL] \Delta PI_iW",post="(numerical)"),OMS_single_q,after_msg="[meV]")
! OMS_single_q=(/real(PI_exact%IW(is)-Pi_exact%ST(is)),aimag(PI_exact%IW(is))/)*HA2EV*1000.
! call msg('sr',com_compose_msg(body="[MODEL] \Delta_Pi_iW",post="(exact)"),OMS_single_q,after_msg="[meV]")

