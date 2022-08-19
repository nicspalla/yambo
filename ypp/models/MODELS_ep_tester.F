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
subroutine MODELS_ep_tester(k,E)
 !
 use units,               ONLY:HA2EV,HA2KEL
 use pars,                ONLY:SP,cI
 use electrons,           ONLY:levels,nel
 use R_lattice,           ONLY:bz_samp
 use D_lattice,           ONLY:Tel
 use units,               ONLY:HA2EV
 use MODELS,              ONLY:MODEL_gkkp_kind,MODEL_elph_alpha,MODEL_E_ph,MODEL_ep_dV,MODEL_effective_mass,MODEL_Nel_at_Ef
 use ELPH,                ONLY:GKKP
 use vec_operate,         ONLY:iku_v_norm,sort
 use com,                 ONLY:msg,com_compose_msg
 use interfaces,          ONLY:OCCUPATIONS_Fermi
 use stderr,              ONLY:STRING_same
 use functions,           ONLY:Fermi_fnc
 use LIVE_t,              ONLY:live_timing
 use parallel_m,          ONLY:PP_indexes,PP_indexes_reset,myid
 use parallel_int,        ONLY:PP_redux_wait,PARALLEL_index 
 !
#include<memory.h>
 !
 type(bz_samp), intent(inout)   :: k
 type(levels ), intent(inout)   :: E
 !
 ! Work Space
 !
 integer, parameter :: NW=1000
 integer     :: ik,ib,Q_index(k%nibz),iq,Nq,is,iw,Q_is_todo(k%nibz)
 real(SP)    :: OMS_el(1),q_mod,k_m_q(k%nibz),q(3),k_mod,f_kmq,f_k,E_k,E_kmq,OMS_ph_RE_min_max(2),&
&               OMS_ph_IM_min_max(2),E_range(2)
 complex(SP) :: OMS_ph(k%nibz),W(NW),PI_ph(NW)
 type(PP_indexes) :: px
 !
 call section("+","E-P tester")
 !
 ! Parallel setup
 !
 call PP_indexes_reset(px)
 call PARALLEL_index(px,(/E%nb,k%nibz/))
 call PP_redux_wait
 !
 MODEL_gkkp_kind="Frohlich"
 call ELPH_model_gkkp(GKKP)
 !
 ! Electrons
 !
 OMS_el=0._SP
 call live_timing("E-P OMS (electrons)",px%n_of_elements(myid+1))
 do ib=1,E%nb
   do ik=1,k%nibz
     if (.not.px%element_2D(ib,ik)) cycle
     k_mod=iku_v_norm(k%pt(ik,:))
     if (k_mod<1.E-5) cycle
     OMS_el=OMS_el+MODEL_ep_dV**2/k%nibz/k_mod**2/(MODEL_E_ph+E%E(ib,ik,1)+E%E_Fermi)
     call live_timing(steps=1)
   enddo
 enddo
 call live_timing()
 call PP_redux_wait(OMS_el)
 !
 call msg('sr',com_compose_msg(body="[MODEL] OMS (el)",post="(calc exact)"),&
&                             (/OMS_el(1),MODEL_elph_alpha*MODEL_E_ph/)*HA2EV*1000.,after_msg="[meV]")
 !
 ! Phonons
 !
 ! ... occupations
 Tel=273./HA2KEL
 E%nk=k%nibz
 YAMBO_ALLOC(k%weights,(k%nibz))
 k%weights=1./float(k%nibz)
 call OCCUPATIONS_Fermi(E,k,"OCCUPATIONS")
 !
 MODEL_Nel_at_Ef=0._SP
 do ib=1,E%nb
   do ik=1,k%nibz
     if (abs(E%E(ib,ik,1))<Tel) MODEL_Nel_at_Ef = MODEL_Nel_at_Ef+E%f(ib,ik,1)/float(k%nibz)
   enddo
 enddo
 MODEL_Nel_at_Ef=nel
 !
 MODEL_gkkp_kind="Debye"
 call ELPH_model_gkkp(GKKP)
 !
 ! ... 	q's
 do ik=1,k%nibz
   k_m_q(ik)=iku_v_norm(k%pt(ik,:)-k%pt(1,:))
 enddo
 call sort(k_m_q,indx=Q_index)
 !
 OMS_ph=0._SP
 !
 Q_is_todo=0
 do is=2,k%nibz
   if (k_m_q(is)-k_m_q(is-1) > 1.E-3) Q_is_todo(is)=1
 enddo
 !
 Q_is_todo=0
 Q_is_todo(k%nibz)=1
 !
 Nq=count(Q_is_todo==1)
 !
 E_range=(/-MODEL_E_ph*10.,MODEL_E_ph*10./)
 do iw=1,NW
   W(iw)=E_range(1)+(E_range(2)-E_range(1))/NW*iw+cI*0.005/HA2EV
 enddo
 PI_ph=0.
 !
 call live_timing("E-P OMS (phonons)",px%n_of_elements(myid+1)*Nq)
 !
 do is=2,k%nibz
   !
   if (Q_is_todo(is)==0) cycle
   !
   iq=Q_index(is)
   q=k%pt(iq,:)-k%pt(1,:)
   q_mod=iku_v_norm(q)
   !
   do ib=1,E%nb
     do ik=1,k%nibz
       !
       if (.not.px%element_2D(ib,ik)) cycle
       !
       k_mod=iku_v_norm(k%pt(ik,:))
       !
       E_k=E%E(ib,ik,1)
       E_kmq=iku_v_norm(k%pt(ik,:)-q)**2./2./MODEL_effective_mass-E%E_fermi
       f_k=Fermi_fnc(E_k,Tel)
       f_kmq=Fermi_fnc(E_kmq,Tel)
       !
       OMS_ph(iq)=OMS_ph(iq)+2*MODEL_ep_dV**2/k%nibz*(f_kmq-f_k)/(MODEL_E_ph+E_kmq-E_k+cI*0.5/HA2EV)
       !
       do iw=1,NW
         PI_ph(iw)=PI_ph(iw)+2*MODEL_ep_dV**2/k%nibz*(f_kmq-f_k)/(W(iw)+E_kmq-E_k)
       enddo
       !
       call live_timing(steps=1)
       !
     enddo
   enddo
   !
   if (STRING_same(MODEL_gkkp_kind,"Frohlich")) OMS_ph(iq)=OMS_ph(iq)/q_mod**2
   !
 enddo
 !
 call live_timing()
 !
 call PP_redux_wait(OMS_ph)
 call PP_redux_wait(PI_ph)
 !
 OMS_ph_RE_min_max=(/100.,-100./)
 OMS_ph_IM_min_max=(/100.,-100./)
 do is=2,k%nibz
   if (Q_is_todo(is)==0) cycle
   iq=Q_index(is)
   q=k%pt(iq,:)-k%pt(1,:)
   q_mod=iku_v_norm(q)
   if (abs(real(OMS_ph(iq)))<OMS_ph_RE_min_max(1)) OMS_ph_RE_min_max(1)=real(OMS_ph(iq))
   if (abs(real(OMS_ph(iq)))>OMS_ph_RE_min_max(2)) OMS_ph_RE_min_max(2)=real(OMS_ph(iq))
   if (abs(aimag(OMS_ph(iq)))<OMS_ph_IM_min_max(1)) OMS_ph_IM_min_max(1)=aimag(OMS_ph(iq))
   if (abs(aimag(OMS_ph(iq)))>OMS_ph_IM_min_max(2)) OMS_ph_IM_min_max(2)=aimag(OMS_ph(iq))
   if (myid==0) write (100,*) q_mod,real(OMS_ph(iq))*HA2EV*1000.,aimag(OMS_ph(iq))*HA2EV*1000.,iq,q
 enddo
 !
 do iw=1,NW
   if (myid==0) write (200,*) real(W(iw))*HA2EV*1000.,real(PI_ph(iw))*HA2EV*1000.,aimag(PI_ph(iw))*HA2EV*1000.
 enddo
 !
 call msg('sr',com_compose_msg(body="[MODEL] Re[OMS] (ph)",post="(min MAX)"),OMS_ph_RE_min_max*HA2EV*1000.,after_msg="[meV]")
 call msg('sr',com_compose_msg(body="[MODEL] Im[OMS] (ph)",post="(min MAX)"),OMS_ph_IM_min_max*HA2EV*1000.,after_msg="[meV]")
 !
end subroutine MODELS_ep_tester
