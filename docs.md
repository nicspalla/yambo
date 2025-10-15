---
project: Yambo
author: Yambo Team
author_description: (See AUTHORS file)
license: gpl
doc_license: gpl
github: https://github.com/yambo-code/yambo
website: https://www.yambo-code.eu
favicon: ./doc/media/yambo_favicon.png
summary: <p>YAMBO is an open-source code released within the GPL licence implementing first-principles methods based on Green’s function theory to describe excited-state properties of realistic materials. These methods include the GW approximation, the Bethe-Salpeter equation (BSE), electron-phonon interaction and non-equilibrium Green’s function theory (NEGF).</p><p>YAMBO relies on previously computed ground-state properties and for this reason it is interfaced with other density functional theory (DFT) codes.</p>
media_dir: ./doc/media
page_dir: ./doc/ford
extensions: f90
            F
fixed_extensions: f
fpp_extensions: F
extra_filetypes: c //
src_dir: ./src
         ./driver
         ./lib
         ./ypp
         ./interfaces
exclude: src/wf_and_fft/scatter_Bamp_incl.F
         src/wf_and_fft/scatter_Gamp_incl.F
         src/wf_and_fft/WF_apply_symm_incl.F
         src/wf_and_fft/WF_symm_kpoint_incl.F
macro: DEV_SUB(x)=x
       DEV_VAR(x)=x
       DEV_ATTR= 
---

<p align="center">
<img alt="logo" src="media/yambo_logo.png">
</p>
{!README.md!}
