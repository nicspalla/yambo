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
subroutine rim(mode)
 !
 use pars,          ONLY:SP,pi
 use com,           ONLY:msg
 use parallel_m,    ONLY:PP_indexes,myid,PP_indexes_reset
 use parallel_int,  ONLY:PP_redux_wait,PARALLEL_index 
 use LIVE_t,        ONLY:live_timing
 use R_lattice,     ONLY:k_grid_uc_vol,nqibz,RIM_epsm1,RIM_is_diagonal,&
&                        RIM_n_rand_pts,RIM_ng,RIM_W_ng,RIM_qpg,RIM_W_is_diagonal,&
&                        RIM_id_epsm1_reference,RIM_anisotropy,RIM_W,&
&                        cut_is_slab,idir
 use timing_m,      ONLY:timing
 !
#include<memory.h>
 !
 character(1)       :: mode
 !
 ! Work Space
 !
 type(PP_indexes)::px
 integer   :: iq,N_out,N_out_G,ic
 real(SP)  :: em1_anis(3),G_radii,G_circ
 real(SP), allocatable  :: qr(:,:)
 ! 
 if (mode == "x") call timing('RIM(V)',OPR='start')
 if (mode == "c") call timing('RIM(W)',OPR='start')
 !
 call PP_indexes_reset(px)
 !
 ! Anisotropy Setup
 !-----------------
 ! em1_anis refers to the X part only of epsm1 as in the self-energy
 ! the bare part is embodied in the exchange.
 !
 em1_anis=RIM_epsm1(:)-1.
 if (RIM_id_epsm1_reference<0.or.RIM_id_epsm1_reference>3) RIM_id_epsm1_reference=0
 if (RIM_id_epsm1_reference==0) em1_anis=0.
 if (RIM_id_epsm1_reference>0 .and. mode == "x") em1_anis=em1_anis/em1_anis(RIM_id_epsm1_reference)
 !
 ! Filling the small BZ with the random grid
 !===========================================
 if (mode=="x") then
   call section('+','RIM (bare interaction) initialization')
   if (RIM_is_diagonal) call msg('r','* Diagonal components only detected *')
 else  if (mode=="c") then
   call section('=','RIM (screened interaction) initialization')
   if (RIM_W_is_diagonal) call msg('r','* Diagonal components only detected *')
 end if
 !
 ! Random Points
 !---------------
 YAMBO_ALLOC(qr,(3,RIM_n_rand_pts))
 call rim_random_points_generator("Unit-Cell",qr,N_out)
 !
 !Only the 2D-BZ is sampled for 2D systems
 !----------------------------------------
 if (cut_is_slab) qr(idir(1),:) = 0._SP
 !
 call section('=','RIM integrals')
 !================================
 if (mode == "x") then
   YAMBO_ALLOC(RIM_qpg,(nqibz,RIM_ng,RIM_ng))
   RIM_qpg=0._SP
 else if (mode == "c") then
   YAMBO_ALLOC(RIM_W,(nqibz,RIM_W_ng,RIM_W_ng))
   RIM_W=0._SP
 end if
 !
 call PARALLEL_index(px,(/nqibz/))
 call live_timing('Momenta loop',px%n_of_elements(myid+1))
 !
 do iq=1,nqibz
   if (.not.px%element_1D(iq)) cycle
   if (mode == "x") then
     call rim_integrate_v(iq,qr,em1_anis,N_out,N_out_G,G_radii,G_circ)
     if (iq==1) then
       call msg('r','Gamma point sphere radius             ',G_radii,"[a.u.]")
       call msg('r','Points outside the sphere             ',N_out_G)
       call msg('r','[Int_sBZ(q=0) 1/q^2]*(Vol_sBZ)^(-1/3) =',4.*pi**3.*RIM_qpg(1,1,1)*k_grid_uc_vol**(-1./3.))
       call msg('r','                            should be <',7.7956_SP)
       if (RIM_id_epsm1_reference/=0) then 
         call msg('r','Anisotropy correction            [o/o]',(RIM_anisotropy-RIM_qpg(iq,1,1))/RIM_qpg(iq,1,1)*100.)
       endif
     endif
   else if (mode == "c") then
     call rim_integrate_w(iq,qr,N_out,em1_anis)
   endif
   call live_timing(steps=1)
 enddo
 call live_timing()
 !
 ! Redux
 !------
 if (mode == "x") call PP_redux_wait(RIM_qpg)
 if (mode == "c") call PP_redux_wait(RIM_W)
 call PP_redux_wait(RIM_anisotropy)
 !
 ! CLEAN
 !------
 call PP_indexes_reset(px)
 YAMBO_FREE(qr)
 !
 ! Timing
 !-------
 if (mode == "x") call timing('RIM(V)',OPR='stop')
 if (mode == "c") call timing('RIM(W)',OPR='stop')
 !
end subroutine
