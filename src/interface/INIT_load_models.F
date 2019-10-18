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
subroutine INIT_load_models(defs)
 !
 use MODELS,         ONLY:MODEL_U
 use it_m,           ONLY:initdefs,E_unit
 use it_tools,       ONLY:it
 !
 implicit none
 !
 type(initdefs)   ::defs
 !
 call it(defs,'OnSiteU','Coloumb parameter',MODEL_U,unit=E_unit)
 call it('f',defs,'SkipIntraBand','Skip Intraband collision')
 !
end subroutine
