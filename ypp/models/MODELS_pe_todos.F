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
 use R_lattice,      ONLY:bz_samp
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
 integer     :: iq,is,ic,Q_index(k%nibz),i_mass,i_p,N_USER_q_and_M,i_found
 real(SP)    :: q_mod(k%nibz)
 !
 if (what=="Q_oms_and_Masses") then
   !
   ! q type
   !-------
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
           OMS_Q%val(OMS_Q%N)=q_mod(is)
         endif
       endif
     enddo
     if (ic==1) then
       YAMBO_ALLOC(OMS_Q%indx,(OMS_Q%N))
       YAMBO_ALLOC(OMS_Q%val,(OMS_Q%N))
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
   YAMBO_FREE(SF_Q_and_M)
   call PARSER_array(mode="REAL dimensions",VAR="SF_Q_and_M",N=N_USER_q_and_M,M=2)
   if (N_USER_q_and_M>0) then
     YAMBO_ALLOC(SF_Q_and_M,(N_USER_q_and_M,2))
     call PARSER_array(mode="read",VAR="SF_Q_and_M",N=N_USER_q_and_M,M=2,R_v=SF_Q_and_M)
   endif
   ! 
   do ic=1,2
     SF_Q%N=0
     do i_p=1,N_USER_q_and_M
       i_found=0
       do i_mass=2,MODEL_N_masses
         if (MODEL_masses(i_mass)>=SF_Q_and_M(i_p,2).and.MODEL_masses(i_mass-1)<SF_Q_and_M(i_p,2)) then
           SF_Q%N=SF_Q%N+1
           i_found=1
           if (ic==2) then
             SF_mass%indx(SF_Q%N)=i_mass 
             SF_mass%val(SF_Q%N)=MODEL_masses(i_mass) 
           endif
         endif
       enddo
       if (i_found==1) then
         do is=2,OMS_Q%N
           if (OMS_Q%val(is)/MODEL_K_fermi>SF_Q_and_M(i_p,1).and.&
&              OMS_Q%val(is-1)/MODEL_K_fermi<SF_Q_and_M(i_p,1) ) then
             i_found=2
             if (ic==2) then
               SF_Q%val(SF_Q%N)=iku_v_norm(q%pt(OMS_Q%indx(is),:))
               SF_Q%indx(SF_Q%N)=OMS_Q%indx(is)
             endif
           endif
         enddo
       endif
       if (i_found==1) SF_Q%N=SF_Q%N-1
     enddo
     !
     SF_Q%N=SF_Q%N+1
     !
     if (ic==2) cycle
     !
     YAMBO_ALLOC(SF_Q%indx,(SF_Q%N))
     YAMBO_ALLOC(SF_Q%val,(SF_Q%N))
     YAMBO_ALLOC(SF_mass%indx,(SF_Q%N))
     YAMBO_ALLOC(SF_mass%val,(SF_Q%N))
     !
   enddo
   SF_mass%N=SF_Q%N
   !
   SF_Q%indx(SF_Q%N)=OMS_Q%indx(OMS_Q%N)
   SF_Q%val(SF_Q%N)=iku_v_norm(q%pt(OMS_Q%indx(OMS_Q%N),:))
   SF_mass%indx(SF_mass%N)=MODEL_N_masses
   SF_mass%val(SF_mass%N)=MODEL_masses(MODEL_N_masses)
   !
   call msg('sr',com_compose_msg(body="[MODEL] NQ & Masses (SF)"),SF_Q%N)
   !
 endif
 !
end subroutine MODELS_pe_todos
