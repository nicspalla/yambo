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
subroutine PHEL_energy_and_KINDS_setup(q)
 !
 use pars,           ONLY:cI,SP
 use R_lattice,      ONLY:bz_samp
 use drivers,        ONLY:l_life
 use ELPH,           ONLY:elph_branches
 use PHEL,           ONLY:PH_Q,PH_SF_W,PH_energy,PHEL_fit_Energies,&
&                         QPH_OMS,QPH_OMS_bare_Pole,QPH_full,QPH,QPHt_alloc,QPH_DDFPT
 use QP_m,           ONLY:QP_Sc_steps,QP_G_er,QP_G_damp,l_QP_eval_GF,QP_solver,On_Mass_Shell_approx
 use frequency,      ONLY:W_reset
 use stderr,         ONLY:STRING_same
 !
#include<memory.h>
 !
 type(bz_samp),intent(in) :: q
 !
 ! Work Space
 !
 integer             ::iq,il
 !
 if (l_life) then
   QP_Sc_steps=1
   call QPHt_alloc("OMS_bare_Pole",QPH_OMS_bare_Pole,0)
   return
 endif
 !
 if (On_Mass_Shell_approx) call QPHt_alloc("OMS",QPH_OMS,QP_Sc_steps)
 call QPHt_alloc("OMS_bare_Pole",QPH_OMS_bare_Pole,QP_Sc_steps)
 call QPHt_alloc("QPH",QPH,QP_Sc_steps)
 if (l_QP_eval_GF) then
   call QPHt_alloc("FULL",QPH_full,QP_Sc_steps)
 else 
   call QPHt_alloc("DDFPT",QPH_DDFPT,0)
 endif
 !
 allocate(PH_SF_W(elph_branches(1):elph_branches(2),PH_Q(1):PH_Q(2)))
 !
 ! SF energy points
 do iq=PH_Q(1),PH_Q(2)
   do il=elph_branches(1),elph_branches(2)
     call W_reset(PH_SF_W(il,iq))
     PH_SF_W(il,iq)%dr=QP_G_damp
     PH_SF_W(il,iq)%n_freqs=QP_Sc_steps 
     PH_SF_W(il,iq)%er=QP_G_er
     call FREQUENCIES_setup(PH_SF_W(il,iq))
     if (On_Mass_Shell_approx) QPH_OMS%W=PH_SF_W(il,iq)%p
     QPH_OMS_bare_Pole%W=PH_SF_W(il,iq)%p
     QPH%W=PH_SF_W(il,iq)%p
     if (l_QP_eval_GF) QPH_full%W=PH_SF_W(il,iq)%p
   enddo
 enddo
 !
 ! SE energy points
 if (STRING_same(QP_solver,"n")) then
   do iq=PH_Q(1),PH_Q(2)
     do il=elph_branches(1),elph_branches(2)
       call W_reset(PH_SF_W(il,iq))
       QP_Sc_steps=4
       PH_SF_W(il,iq)%n_freqs=4 
       !
       ! Fake range just to call FREQUENCIES_setup
       PH_SF_W(il,iq)%er=(/0._SP,1._SP/)
       call FREQUENCIES_setup(PH_SF_W(il,iq))
       !
       ! Manual points
       PH_SF_W(il,iq)%p(  1)=cI*QP_G_damp
       PH_SF_W(il,iq)%p(2:3)=PHEL_fit_Energies*PH_energy(q,il,iq)+cI*QP_G_damp
       PH_SF_W(il,iq)%p(  4)=cI*PH_energy(q,il,iq)
     enddo
   enddo
 endif
 !
end subroutine PHEL_energy_and_KINDS_setup
