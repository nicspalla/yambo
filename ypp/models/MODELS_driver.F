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
 !use pars,          ONLY:SP,pi,schlen
 !use R_lattice,     ONLY:bz_samp
 !use com,           ONLY:error
 !use stderr,        ONLY:intc
 !use X_m,           ONLY:X_t
 !use QP_CTL_m,      ONLY:QP_apply
 !use electrons,     ONLY:levels,n_spin,n_sp_pol,spin,E_SOC_nbands
 !use YPP_interfaces,ONLY:excitons_sort_and_report
 !use YPPm,          ONLY:l_sort,l_exc_wf,l_spin,l_amplitude,EXCITONS_user_indexes,BSiq
 !use IO_m,          ONLY:io_control,OP_RD_CL,DUMP,NONE,REP,VERIFY
 !use BS_solvers,    ONLY:BSS_eh_table,BSS_write_eig_2_db,io_BSS_diago,BS_mat,BSS_n_eig
 !use BS,            ONLY:BS_H_dim,BS_K_dim,BS_bands,BS_K_coupling,BS_cpl_mode,&
!&                        BS_cpl_K_exchange,BS_cpl_K_corr,BSqpts
 !
end subroutine
