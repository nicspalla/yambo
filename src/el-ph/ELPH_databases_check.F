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
subroutine ELPH_databases_check(n_bands)
 ! 
 use IO_int,         ONLY:io_control
 use IO_m,           ONLY:REP,OP_RD_CL,deliver_IO_error_message
 use ELPH,           ONLY:l_GKKP_DB_exists,l_GKKP_DB_is_expanded,elph_nb
 !
 implicit none
 !
 integer :: n_bands
 !
 ! Work Space
 !
 integer             ::ID(2),io_err(2),i_db
 integer, external   ::io_ELPH
 logical             ::l_found(2)
 !
 ! I/O check
 !===========
 l_found=.FALSE.
 call io_control(ACTION=OP_RD_CL,COM=REP,SEC=(/1/),ID=ID(1))
 call io_control(ACTION=OP_RD_CL,COM=REP,SEC=(/1/),ID=ID(2))
 io_err(1)=io_ELPH(ID(1),'gkkp')
 io_err(2)=io_ELPH(ID(2),'gkkp_expanded')
 !
 do i_db=1,2
   if (io_err(i_db)==0.and.n_bands>0) l_found(i_db)=n_bands<=elph_nb
   if (io_err(i_db)==0.and.n_bands<0) l_found(i_db)=.TRUE.
 enddo
 !
 if (all(l_found)) call error("Both expanded and un-expandend GKKP database found")
 l_GKKP_DB_exists=any(l_found)
 l_GKKP_DB_is_expanded=l_found(2)
 if (.not.l_GKKP_DB_exists) then
   if (io_err(1)/=0) call deliver_IO_error_message(io_err(1),"GKKP",.TRUE.) 
   if (io_err(2)/=0) call deliver_IO_error_message(io_err(2),"GKKP_expanded",.TRUE.) 
 endif
 !
end subroutine ELPH_databases_check
