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
subroutine MODELS_pe_todos(what,k,q)
 !
 use pars,           ONLY:SP
 use R_lattice,      ONLY:bz_samp,bz_samp_reset
 use MODELS,         ONLY:MODEL_K_fermi
 use YPP_models,     ONLY:OMS_Q,SF_Q,SF_mass,MODEL_N_masses,SF_Q_and_M,MODEL_masses,&
&                         MODEL_N_masses,MODEL_masses_range
 use com,            ONLY:msg,com_compose_msg
 use vec_operate,    ONLY:iku_v_norm,sort
 use parser_m,       ONLY:PARSER_array
 !
#include<memory.h>
 !
 character(*)                   :: what
 type(bz_samp), intent(inout)   :: k,q
 !
 ! Work Space
 !
 integer     :: iq,is,ic,Q_index(k%nibz),i_mass,i_p
 real(SP)    :: q_mod(k%nibz)
 !
 if (what=="Q_oms_and_Masses") then
   !
   ! q type
   !-------
   call bz_samp_reset(q)
   q%nibz=k%nibz
   q%nbz =k%nbz
   YAMBO_ALLOC(q%pt,(q%nbz,3))
   do iq=1,q%nibz
     q%pt(iq,:)=k%pt(iq,:)-k%pt(1,:)
     q_mod(iq)=iku_v_norm(q%pt(iq,:))
   enddo
   !
   ! q todo (OMS)
   !--------------
   call sort(q_mod,indx=Q_index)
   do ic=1,2
     OMS_Q%N=0
     do is=2,q%nibz
       if (q_mod(is)-q_mod(is-1) > 1.E-6) then
         OMS_Q%N=OMS_Q%N+1
         if (ic==2) then
           OMS_Q%indx(OMS_Q%N)=Q_index(is)
         endif
       endif
     enddo
     if (ic==1) then
       YAMBO_ALLOC(OMS_Q%indx,(OMS_Q%N))
       OMS_Q%indx=0
     endif
   enddo
   call msg('sr',com_compose_msg(body="[MODEL] NQ (OMS)"),OMS_Q%N)
   !
   YAMBO_ALLOC(MODEL_masses,(MODEL_N_masses))
   do i_mass=1,MODEL_N_masses-1
     MODEL_masses(i_mass)=MODEL_masses_range(1)+(i_mass-1)*(MODEL_masses_range(2)-MODEL_masses_range(1))/float(MODEL_N_masses-1)
   enddo
   MODEl_masses(MODEL_N_masses)=MODEL_masses_range(2)
   !
   call msg('sr',com_compose_msg(body="[MODEL] Masses (OMS)"),MODEL_N_masses)
   !
 endif
 !
 if (what=="SF") then
   ! 
   ! Q/M todo (SF)
   !---------------
   call PARSER_array(mode="REAL dimensions",VAR="SF_Q_and_M",N=SF_Q%N,M=2)
   if (SF_Q%N>0) then
     YAMBO_ALLOC(SF_Q_and_M,(SF_Q%N,2))
     call PARSER_array(mode="read",VAR="BANDS_kpts",N=SF_Q%N,M=2,R_v=SF_Q_and_M)
     SF_mass%N=SF_Q%N
   else
     SF_Q%N=1
     SF_mass%N=1
   endif
   YAMBO_ALLOC(SF_Q%indx,(SF_Q%N))
   YAMBO_ALLOC(SF_mass%indx,(SF_mass%N))
   !
   SF_Q%indx=0
   SF_mass%indx=0
   !
   if (allocated(SF_Q_and_M)) then
     do i_p=1,SF_Q%N
       do i_mass=2,MODEL_N_masses
         if (MODEL_masses(i_mass)>=SF_Q_and_M(i_p,2).and.MODEL_masses(i_mass-1)<SF_Q_and_M(i_p,2)) SF_mass%indx(i_p)=i_mass 
       enddo
       do is=2,OMS_Q%N
         if (iku_v_norm(q%pt(OMS_Q%indx(is),:))/MODEL_K_fermi>SF_Q_and_M(i_p,1).and.&
&            iku_v_norm(q%pt(OMS_Q%indx(is-1),:))/MODEL_K_fermi<SF_Q_and_M(i_p,1) ) SF_Q%indx(i_p)=is
       enddo
       if (SF_mass%indx(i_p)==0) SF_Q%indx(i_p)=0
       if (SF_Q%indx(i_p)==0   ) SF_mass%indx(i_p)=0
     enddo
   else
     SF_Q%indx(1)=OMS_Q%indx(OMS_Q%N)
     SF_mass%indx(1)=MODEL_N_masses
   endif
   !
   SF_Q%N=count(SF_Q%indx>0)
   SF_mass%N=count(SF_mass%indx>0)
   !
   call msg('sr',com_compose_msg(body="[MODEL] NQ (SF)"),SF_Q%N)
   call msg('sr',com_compose_msg(body="[MODEL] Masses (SF)"),SF_mass%N)
   !
 endif
 !
end subroutine MODELS_pe_todos
