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
subroutine rim_random_points_generator(GEO,pts,N_out)
 !
 use pars,          ONLY:SP,pi,DP
 use com,           ONLY:msg
 use LIVE_t,        ONLY:live_timing
 use vec_operate,   ONLY:v_norm_square
 use D_lattice,     ONLY:alat
 use R_lattice,     ONLY:RL_vol,k_grid_uc_vol,k_grid_b,nqbz,RIM_RL_vol,RIM_n_rand_pts
 use stderr,        ONLY:STRING_same
 !
#include<memory.h>
 !
 character(*)       :: GEO
 integer            :: N_out
 real(SP)           :: pts(3,RIM_n_rand_pts)
 !
 ! Work Space
 !
 integer   :: N_in,rep_factor,inn1,inn2,inn3,ic
 real(SP)  :: v1(3),v2(3),v1_norm,first_neighbour(26,3),fn_dist(26)
 integer   :: iseed(8)
 logical   :: l_UC,l_sphere
 real(DP), external :: dlaran
 !
 call section('=','RIM points for '//trim(GEO))
 !=============================================
 !  
 ! GEO...
 l_UC    =STRING_same(GEO,"unit-cell") 
 l_sphere=STRING_same(GEO,"sphere") 
 !
 call msg('r','8 x (sBL volume)        ',8._SP*k_grid_uc_vol,"[a.u.]")
 call msg('r','sBZ random points       ',RIM_n_rand_pts)
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
 !
 ! Loop setup
 N_in=1
 N_out=0
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
     v2(ic)=2.*dlaran(iseed(4:))-1
   enddo
   N_out=N_out+1
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
   pts(:,N_in)=v1*alat(:)/2._SP/pi
   N_in=N_in+1
   !
   if (mod(N_in,rep_factor)==0) call live_timing(steps=1)
   !
 enddo loop
 !
 call live_timing()
 !
 ! Report
 !
 call msg('r','Points outside the sBZ  ',N_out)
 !  
 ! Integrated RL VOLUME 
 !
 RIM_RL_vol=8._SP*k_grid_uc_vol*real(RIM_n_rand_pts)/real(N_out)*real(nqbz)
 call msg('r', 'RL volume               ',RL_vol,"[a.u.]")
 call msg('rn','Integrated volume       ',RIM_RL_vol,"[a.u.]")
 !
end subroutine
