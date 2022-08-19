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
subroutine rim_random_points_generator(GEO,N_grid)
 !
 use pars,          ONLY:SP,pi,DP
 use com,           ONLY:msg,com_compose_msg
 use LIVE_t,        ONLY:live_timing
 use vec_operate,   ONLY:v_norm_square,v_norm
 use D_lattice,     ONLY:alat
 use RIM,           ONLY:RIM_UC_integrated_vol,RIM_n_rand_pts,RIM_pt,RIM_IC_n_pts,&
&                        RIM_IC_vol,RIM_UC_integrated_vol
 use R_lattice,     ONLY:RL_vol,k_grid_uc_vol,k_grid_b
 use stderr,        ONLY:STRING_same
 !
#include<memory.h>
 !
 character(*)       :: GEO
 integer            :: N_grid
 !
 ! Work Space
 !
 integer   :: N_in,rep_factor,inn1,inn2,inn3,ic,iseed(8) 
 real(SP)  :: v1(3),v2(3),v1_norm,first_neighbour(26,3),fn_dist(26),radius,scaling
 logical   :: l_UC,l_sphere
 real(DP), external :: dlaran
 !
 if (RIM_n_rand_pts==0) return
 !
 YAMBO_ALLOC(RIM_pt,(3,RIM_n_rand_pts))
 !
 call section('=','RIM points for '//trim(GEO))
 !=============================================
 !  
 ! GEO...
 l_UC    =STRING_same(GEO,"unit-cell") 
 l_sphere=STRING_same(GEO,"sphere") 
 !
 !.. UC
 !------
 if (l_UC) then
   !
   RIM_IC_vol=8.*k_grid_uc_vol
   scaling   =1._SP
   !
   ! First neighbours of the gamma point in the k_grid_b units
   ic=0
   do inn1=-1,1
     do inn2=-1,1
       do inn3=-1,1
         if (all((/inn1,inn2,inn3/)==0)) cycle
         ic=ic+1
         first_neighbour(ic,:)=matmul(transpose(k_grid_b),(/inn1,inn2,inn3/))
       enddo
     enddo
   enddo
   !
   ! Precompute the neighbours distances
   do inn1=1,26
     fn_dist(inn1)=v_norm_square(first_neighbour(inn1,:))  
   end do
 endif
 !
 if (l_sphere) then
   !
   radius    =(3._SP*RL_vol/float(N_grid)/4._SP/pi)**(1._SP/3._SP)
   RIM_IC_vol=(2.*radius*1.2)**3.
   scaling   =radius*1.2_SP
   !
 endif
 !
 ! Loop setup
 N_in=1
 RIM_IC_n_pts=0
 rep_factor=RIM_n_rand_pts/100
 if (rep_factor==0) rep_factor=1
 !
 call live_timing('Random points',RIM_n_rand_pts/rep_factor)
 !
 ! Random generator seed. AF: fixing the seed for the sake of data reproducibility.
 iseed=0
 iseed(4:8) = (/5,6,7,8,9/)
 !
 loop: do while(.not.N_in==RIM_n_rand_pts+1)
   !
   do ic=1,3
     v2(ic)=(2.*dlaran(iseed(4:))-1)*scaling
   enddo
   RIM_IC_n_pts=RIM_IC_n_pts+1
   !
   if (l_UC) then
     !
     ! From rlu in the k_grid_b units (v2) to Cartesian (v1)
     !
     v1=matmul(transpose(k_grid_b),v2) 
     do inn1=1,26
       v1_norm=(v1(1)* first_neighbour(inn1,1) &
               +v1(2)* first_neighbour(inn1,2) &
               +v1(3)* first_neighbour(inn1,3))*2._SP
       if (fn_dist(inn1)<v1_norm)  cycle loop
     enddo
     !
   endif
   !
   if (l_sphere) then
     if (v_norm(v2)>radius) cycle loop
     v1=v2
   endif
   !
   ! to IKU
   RIM_pt(:,N_in)=v1*alat(:)/2._SP/pi
   N_in=N_in+1
   !
   if (mod(N_in,rep_factor)==0) call live_timing(steps=1)
   !
 enddo loop
 !
 call live_timing()
 !
 ! Report
 call msg('r',com_compose_msg(body="Points in the IC (integration cell)"),RIM_IC_n_pts)
 RIM_UC_integrated_vol=RIM_IC_vol*real(RIM_n_rand_pts)/real(RIM_IC_n_pts)*real(N_grid)
 call msg('r',com_compose_msg(body="Points in the UC (unit-cell)"),RIM_n_rand_pts)
 call msg('r',com_compose_msg(body=GEO//" UC volume",post="(reference) [a.u.]"),RL_vol)
 call msg('r',com_compose_msg(body=GEO//" UC volume",post="(integrated) [a.u.]"),RIM_UC_integrated_vol)
 !
end subroutine
