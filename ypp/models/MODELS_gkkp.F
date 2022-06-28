!
!        Copyright (C) 2000-2020 the YAMBO team
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
subroutine MODELS_gkkp(q)
 !
 use pars,             ONLY:SP,pi
 use MODELS,           ONLY:MODEL_E_ph,MODEL_elph_alpha
 use ELPH,             ONLY:ph_modes,elph_nb,PH_freqs_sq,PH_qpt,elph_use_q_grid,&
&                           PH_pol_vector,GKKP,GKKP,elph_nQ,elph_nk_bz
 use vec_operate,      ONLY:iku_v_norm
 use interfaces,       ONLY:ELPH_alloc
 use D_lattice,        ONLY:DL_vol
 use R_lattice,        ONLY:nkbz,nqbz,bz_samp
 use electrons,        ONLY:n_bands
 use IO_m,             ONLY:OP_APP_CL,REP,OP_WR_CL
 use IO_int,           ONLY:io_control
 use LIVE_t,           ONLY:live_timing
 !
 implicit none
 !
 type(bz_samp)      :: q
 !
 ! Work Space
 !
 integer            :: io_err,iq,ID
 integer, external  :: io_ELPH
 !
 call section("*","Electron-Phonon model interaction")
 !
 elph_nb   =n_bands
 elph_nQ   =nqbz
 elph_nk_bz=nkbz
 ph_modes  =1
 elph_use_q_grid=.TRUE.
 call ELPH_alloc("PHONONS")
 call ELPH_alloc("LEVELS dV DW",GKKP=GKKP)
 !
 ! Filling & I/O
 !
 PH_qpt=-q%pt
 !
 call live_timing('I/O',nqbz)
 !
 do iq=1,nqbz
   PH_freqs_sq(iq,1)=sqrt( MODEL_E_ph )
   PH_pol_vector=0.
   if (iq==1) call io_control(ACTION=OP_WR_CL,COM=REP,SEC=(/1,2/),ID=ID)
   if (iq> 1) call io_control(ACTION=OP_APP_CL,SEC=(/iq+1/),ID=ID)
   GKKP%dVr(1,:,:,:,1)=0.
   if (iq==1) GKKP%dVc(1,:,:,:,1)=0.
   if (STRING_same(MODEL_kind,"debye" )) then
     if (iq> 1) GKKP%dVc(1,:,:,:,1)=MODEL_elph_alpha
   else
     if (iq> 1) GKKP%dVc(1,:,:,:,1)=1._SP/iku_v_norm(PH_qpt(iq,:))*MODEL_elph_alpha*(sqrt(2*pi*MODEL_E_ph/DL_vol))
   endif
   io_err=io_ELPH(ID,'gkkp')
   call live_timing(steps=1)
 enddo
 call live_timing()
 !
end subroutine
