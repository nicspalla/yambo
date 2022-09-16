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
subroutine MODELS_k_tables(E,k,q,px)
 !
 use pars,                ONLY:SP,schlen
 use electrons,           ONLY:levels
 use R_lattice,           ONLY:bz_samp
 use YPP_models,          ONLY:MODEL_B_shift,MODEL_kmq_table,OMS_Q
 use MODELS,              ONLY:MODEL_E_shells,MODEL_k
 use vec_operate,         ONLY:v_is_zero
 use parallel_int,        ONLY:PP_redux_wait
 use parallel_m,          ONLY:myid,PP_indexes
 use LIVE_t,              ONLY:live_timing
 use com,                 ONLY:msg,com_compose_msg
 use stderr,              ONLY:intc
 !
#include<memory.h>
 !
 type(bz_samp), intent(inout)   :: k,q
 type(levels ), intent(in)      :: E
 type(PP_indexes), intent(in)   :: px
 !
 ! Work Space
 !
 integer     :: ik,ib,iq,is,i_shift(3),ic,i_kmq,ib_kmq
 logical     :: l_warning=.FALSE.
 real(SP)    :: kmq(3),PERC_fail(E%nb)
 logical, external :: file_exists
 character(schlen) :: db_name
 !
 ! DB?
 !----
 db_name="ndb.K_table_k"//trim(intc(MODEL_k(1)))//"_S"//trim(intc(MODEL_E_shells))
 !
 if (.not.file_exists(trim(db_name)).and.E%nb==1) return
 !
 YAMBO_ALLOC(MODEL_kmq_table,(k%nibz,E%nb,OMS_Q%N,2))
 MODEL_kmq_table=0
  !
 if (file_exists(trim(db_name))) then
   open(unit=100,file=trim(db_name),form='unformatted')
   read (100) OMS_Q%N
   read (100) OMS_Q%indx
   read (100) MODEL_kmq_table
   close(unit=100)
   return
 endif
 !
 ! k-q table
 !----------
 call live_timing("K table",px%n_of_elements(myid+1)*OMS_Q%N)
 !
 do is=1,OMS_Q%N
   iq=OMS_Q%indx(is)
   do ib=1,E%nb
     do ik=1,k%nibz
       if (.not.px%element_2D(ib,ik)) cycle
       kmq=k%pt(ik,:)-q%pt(iq, :)+MODEL_B_shift(ib,ik,:)
       do ic=1,3
         i_shift(ic)=0
         if (kmq(ic)> 0.5) i_shift(ic)=-1
         if (kmq(ic)<-0.5) i_shift(ic)= 1
       enddo
       KMQ_loop: do i_kmq=1,k%nibz
         do ib_kmq=1,E%nb
          if (v_is_zero(kmq-k%pt(i_kmq,:)-MODEL_B_shift(ib_kmq,i_kmq,:))) then 
            MODEL_kmq_table(ik,ib,is,:)=(/ib_kmq,i_kmq/)
            exit KMQ_loop
          endif
         enddo
       enddo KMQ_loop
       call live_timing(steps=1) 
     enddo
   enddo
 enddo
 call live_timing()
 !
 do is=1,OMS_Q%N
   call PP_redux_wait(MODEL_kmq_table(:,:,is,:))
 enddo
 !
 ! Test.
 PERC_fail=0._SP
 do ib=1,E%nb
   do is=1,OMS_Q%N
     iq=OMS_Q%indx(is)
     do ik=1,k%nibz
       if (any(MODEL_kmq_table(ik,ib,is,:)==0)) then
         if (.not.l_warning) call warning("Out-of-the boundaries point found")
         l_warning=.TRUE.
         PERC_fail(ib)=PERC_fail(ib)+1./float(OMS_Q%N*k%nibz)
       endif
     enddo
   enddo
 enddo
 !
 call msg('sr',com_compose_msg(body="[MODEL] Table failures",post="(first 3 bands)"),&
&                              PERC_fail(1:min(3,E%nb))*100.,after_msg="[%]")
 call msg('sr',com_compose_msg(body="[MODEL] Table failures",post="(min Max)"),&
&                              (/minval(PERC_fail),maxval(PERC_fail)/)*100.,after_msg="[%]")
 !
 if (myid==0) then
   open(unit=100,file=trim(db_name),form='unformatted')
   write (100) OMS_Q%N
   write (100) OMS_Q%indx
   write (100) MODEL_kmq_table
   close(unit=100)
 endif
 !
end subroutine MODELS_k_tables
