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
subroutine rim_integrate_elph(GEO,Np,points,p_weight,power,MULTIPLY_BY_Q)
 !
 ! Here I want to approx the integral
 !
 ! 1/vol \int_vol F(q) d3q = 1/vol \int_vol d3q/q^power [q^power F(q)] =
 !                         = 1/vol \sum_{Qi} \int_Si d3q/q^power [q^power F(q)] ~
 !                         ~ 1/vol \sum_{Qi} [Qi^power F(Qi)] \int_Si d3q/q^power
 !
 ! with Si a sphere of radius such that the sphere volume is RL_vol/Np or the RL small unit-cell depending on the value of GEO.
 !
 ! a) MULTIPLY_BY_Q=.TRUE. 
 !
 ! If F(q) is divergent at gamma and it goes like 1/q^power. Therefore [q^power F(q)] is regular.
 ! I use this property to regularize the integral and rewrite 
 ! 
 !  1/vol \int_vol F(q) d3q = 1/vol \int_vol q^power/q^power F(q) d3q 
 ! 
 ! with
 ! 
 !  1/vol \int_vol F(q) d3q ~ \sum_{Qi} Wi F(Qi)
 ! 
 ! and
 !  
 !  Wi = 1/vol Qi^power \int_Si d3q/q^power
 ! 
 !  a) MULTIPLY_BY_Q=.FALSE. 
 ! 
 ! In this case I want to integrate the 1/q^power straight away, i.e. F(q)=1/q^power
 ! 
 !  1/vol \int_vol F(q) d3q = 1/vol \int_vol 1./q^power d3q  ~ \sum_{Qi} Wi
 ! 
 ! with
 ! 
 !  Wi = 1/vol \int_Si d3q/q^power
 ! 
 use pars,          ONLY:SP
 use LIVE_t,        ONLY:live_timing
 use vec_operate,   ONLY:v_norm,iku_v_norm
 use RIM,           ONLY:RIM_n_rand_pts,RIM_UC_vol,RIM_IC_n_pts,RIM_pt,RIM_IC_vol
 !
#include<memory.h>
 !
 character(*),intent(in)    :: GEO
 integer,     intent(in)    :: Np,power
 real(SP),    intent(in)    :: points(Np,3)
 real(SP),    intent(inout) :: p_weight(Np)
 logical ,    intent(in)    :: MULTIPLY_BY_Q
 !
 ! Work Space
 !
 integer   :: ip,ir,ic
 !
 ! No RIM
 !--------
 if (RIM_n_rand_pts==0)then
   do ip=1,Np
     p_weight(ip)=0._SP
     if (     MULTIPLY_BY_Q                                   ) p_weight(ip)=1./float(Np)
     if (.not.MULTIPLY_BY_Q.and.iku_v_norm(points(ip,:))>0._SP) p_weight(ip)=1./float(Np)/iku_v_norm(points(ip,:))**power
   enddo
   return
 endif
 !
 ! Filling a larger Sphere with a random grid
 !--------------------------------------------
 call rim_random_points_generator(GEO,Np)
 !
 ! Weights calculation
 !--------------------
 call live_timing('Integrals',Np)
 do ip=1,Np
   p_weight(ip)=0.
   do ir=1,RIM_n_rand_pts
     p_weight(ip)=p_weight(ip)+1./iku_v_norm(RIM_pt(:,ir)+points(ip,:))**power*RIM_IC_vol/real(RIM_IC_n_pts)
   enddo
   p_weight(ip)=p_weight(ip)/RIM_UC_vol/real(Np)
   !
   if (MULTIPLY_BY_Q) p_weight(ip)=p_weight(ip)*iku_v_norm(points(ip,:))**power
   !
   call live_timing(steps=1)
 enddo
 call live_timing()
 !
 ! Clean
 !-------
#if !defined _MODELS
 YAMBO_FREE(RIM_pt)
#endif
 !
end subroutine
