!
!        Copyright (C) 2000-2019 the YAMBO team
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
subroutine MODELS_driver( )
 !
 use pars,             ONLY:pi
 use YPP_models,       ONLY:MODEL_k,MODEL_kind,MODEL_overlap,MODEL_Eg
 use electrons,        ONLY:levels,default_nel,n_spin,nel,n_sp_pol,n_spinor,E_reset,n_bands
 use D_lattice,        ONLY:a, alat, nsym, i_time_rev, input_GS_Tel, dl_sop, &
&                           Tel, n_atoms_species_max,n_atomic_species,n_atoms_species,atom_pos, &
&                           Z_species, n_atoms, mag_syms
 use R_lattice,        ONLY:ng_vec, g_vec, bz_samp,bz_samp_reset,rl_sop
 use wave_func,        ONLY:wf_ncx, wf_nc_k, wf_igk,wf_ng,wf_nb_io,wf_nb_io_groups,io_WF
 use xc_functionals,   ONLY:GS_xc_KIND,GS_xc_FUNCTIONAL,GS_exx_FRACTION,GS_exx_SCREENING
 use global_XC,        ONLY:H_SE_Hartree
 use IO_m,             ONLY:io_control,OP_WR_CL,REP,mk_dir
 use com,              ONLY:com_path,more_io_path,core_io_path
 use vec_operate,      ONLY:define_b_and_DL_vol,iku_v_norm
 !
#include<memory.h>
 !
 ! Work Space
 !
 type(levels )      :: E
 type(bz_samp)      :: k
 integer            :: io_err,ID,is,i2,i3,ik
 integer, external  :: io_DB1
 !
 call section("*","Yambo "//trim(MODEL_kind)//" initialization")
 !
 call E_reset(E)
 call bz_samp_reset(k)
 !
 if (n_bands>0) return
 !
 ! DB1 filling
 !=============
 !
 ! DL 
 !
 alat=1.
 a(1,:)=(/1.,0.,0./)
 a(2,:)=(/0.,1.,0./)
 a(3,:)=(/0.,0.,1./)
 call define_b_and_DL_vol()
 n_atomic_species=1
 n_atoms_species_max=1
 YAMBO_ALLOC(n_atoms_species,(n_atomic_species))
 YAMBO_ALLOC(Z_species,(n_atomic_species))
 YAMBO_ALLOC(atom_pos,(3,n_atoms_species_max,n_atomic_species))
 n_atoms_species=1
 atom_pos=0.
 Z_species=0.
 !
 ! GS
 !
 input_GS_Tel=0.
 default_nel=1.
 GS_xc_KIND=H_SE_Hartree
 GS_xc_FUNCTIONAL=0
 GS_exx_FRACTION=0.
 GS_exx_SCREENING=0.
 !
 ! Syms
 !
 i_time_rev=0
 nsym=1
 mag_syms=.FALSE.
 YAMBO_ALLOC(dl_sop,(3,3,nsym))
 dl_sop(1,:,1)=(/1.,0.,0./)
 dl_sop(2,:,1)=(/0.,1.,0./)
 dl_sop(3,:,1)=(/0.,0.,1./)
 YAMBO_ALLOC(rl_sop,(3,3,nsym))
 do is=1,nsym
   forall (i2=1:3,i3=1:3) rl_sop(i2,i3,is)=dl_sop(i2,i3,is)*alat(i2)/alat(i3)
 enddo
 !
 ! K-points
 !
 call INTERPOLATION_create_the_grid(k,'i',MODEL_k)
 !
 ! RL
 !
 ng_vec=1
 wf_ncx=1
 wf_ng=1
 YAMBO_ALLOC(g_vec,(ng_vec,3))
 YAMBO_ALLOC(wf_nc_k,(k%nibz))
 YAMBO_ALLOC(wf_igk,(wf_ncx,k%nibz))
 g_vec=0.
 wf_nc_k=1
 wf_igk=1
 !
 ! Bands
 !
 n_spinor=1
 n_sp_pol=1
 E%nb=2
 wf_nb_io=2
 wf_nb_io_groups=2
 YAMBO_ALLOC(E%E,(E%nb,k%nibz,n_sp_pol))
 YAMBO_ALLOC(E%f,(E%nb,k%nibz,n_sp_pol))
 E%f(1,:,:)=2.
 E%f(2,:,:)=1.
 do ik=1,k%nibz
   E%E(1,ik,:)=-( 2.*MODEL_overlap*(1-cos(iku_v_norm(k%pt(ik,:))))+MODEL_Eg/2. )
   E%E(2,ik,:)= ( 2.*MODEL_overlap*(1-cos(iku_v_norm(k%pt(ik,:))))+MODEL_Eg/2. )
 enddo
 !
 ! I/O
 !=====
 !
 call mk_dir(more_io_path)
 call mk_dir(com_path)
 call mk_dir(trim(core_io_path)//"/SAVE")
 call mk_dir(trim(more_io_path)//"/SAVE")
 call io_control(ACTION=OP_WR_CL,COM=REP,SEC=(/1,2/),ID=ID)
 io_err=io_DB1(E,k,ID)
 call io_control(ACTION=OP_WR_CL,COM=REP,SEC=(/1/),ID=ID)
 io_err=io_WF(ID)
 !
end subroutine
