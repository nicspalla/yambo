# Doxygen Quick Reference for Yambo Developers {#doxygen_quick_ref}

@page doxygen_quick_ref Doxygen Quick Reference

@tableofcontents

## 🚀 Quick Commands

```bash
# Generate documentation
./generate_docs.sh

# Quick generation (no graphs)
./generate_docs.sh -q

# Generate and open
./generate_docs.sh -o

# Clean and regenerate
./generate_docs.sh -c
```

## 📝 Basic Documentation Template

### Subroutine/Function
```fortran
!> @brief Brief one-line description of what this does
!> @author Your Name
!> @date 2025-01-15
!>
!> @details
!! Detailed description of the algorithm.
!! Can span multiple lines.
!!
!! Mathematical formula:
!! \f$ E = \sum_{i=1}^{N} \epsilon_i f_i \f$
!!
!> @param[in] input_var Description of input
!> @param[out] output_var Description of output
!> @param[in,out] inout_var Description of input/output
!>
!> @note Important information
!> @warning Potential issues
!> @see related_function
!>
subroutine example_routine(input_var, output_var, inout_var)
  implicit none
  real(8), intent(in) :: input_var     !< Brief inline description
  real(8), intent(out) :: output_var   !< Brief inline description
  real(8), intent(inout) :: inout_var  !< Brief inline description
  
  ! Implementation
  
end subroutine example_routine
```

### Module
```fortran
!> @brief Brief description of module purpose
!> @author Your Name
!>
!> @details
!! Detailed description of what this module provides.
!! List main functionality and data structures.
!!
module example_module
  implicit none
  
  !> @brief Description of this parameter
  integer, parameter :: max_size = 1000
  
  !> @brief Description of this variable
  real(8) :: module_variable
  
  !> @brief Description of this type
  type example_type
    real(8) :: field1  !< Description of field1
    integer :: field2  !< Description of field2
  end type example_type
  
contains
  ! Subroutines and functions
end module example_module
```

## 📐 Mathematical Formulas

### Inline Formula
```fortran
!! The energy is \f$ E = mc^2 \f$
```

### Display Formula
```fortran
!! The Schrödinger equation:
!! \f[
!!   \hat{H} \psi = E \psi
!! \f]
```

### Complex Multi-line Formula
```fortran
!! The GW self-energy:
!! \f[
!!   \Sigma(\mathbf{r}, \mathbf{r}', \omega) = 
!!   i \int \frac{d\omega'}{2\pi} 
!!   G(\mathbf{r}, \mathbf{r}', \omega + \omega') 
!!   W(\mathbf{r}, \mathbf{r}', \omega')
!! \f]
```

### Common LaTeX Symbols
```latex
\f$ \alpha, \beta, \gamma \f$           Greek letters
\f$ \mathbf{r}, \mathbf{k} \f$          Bold vectors
\f$ \hat{H}, \hat{p} \f$                Operators
\f$ \psi^*, \psi^\dagger \f$            Superscripts
\f$ \epsilon_i, n_k \f$                 Subscripts
\f$ \sum_{i=1}^{N} \f$                  Summation
\f$ \int_{-\infty}^{\infty} \f$         Integration
\f$ \frac{a}{b} \f$                     Fractions
\f$ \sqrt{x}, \sqrt[n]{x} \f$           Roots
\f$ \langle \psi | \phi \rangle \f$     Bra-ket notation
```

## 🏷️ Common Tags

| Tag | Usage | Example |
|-----|-------|---------|
| `@brief` | One-line description | `!> @brief Calculate density` |
| `@author` | Author name | `!> @author John Doe` |
| `@date` | Date | `!> @date 2025-01-15` |
| `@details` | Detailed description | `!> @details This routine...` |
| `@param[in]` | Input parameter | `!> @param[in] x Input value` |
| `@param[out]` | Output parameter | `!> @param[out] y Result` |
| `@param[in,out]` | Input/output | `!> @param[in,out] z Modified` |
| `@note` | Important note | `!> @note Must be normalized` |
| `@warning` | Warning | `!> @warning May fail for N=0` |
| `@todo` | Future work | `!> @todo Add GPU support` |
| `@bug` | Known bug | `!> @bug Incorrect for edge case` |
| `@see` | Cross-reference | `!> @see other_function` |
| `@cite` | Citation | `!> @cite Hedin1965` |
| `@callgraph` | Generate call graph | `!> @callgraph` |
| `@callergraph` | Generate caller graph | `!> @callergraph` |

## 🎨 Custom Aliases

```fortran
!> @am                    ! Expands to: @author Andrea Marini
!> @ch                    ! Expands to: @author Conor Hogan
!> @formula               ! Creates "Formula:" section
!> @algorithm             ! Creates "Algorithm:" section
!> @complexity            ! Creates "Complexity:" section
!> @physics               ! Creates "Physics Background:" section
```

## 📊 Inline Comments

```fortran
integer :: n_bands        !< Number of electronic bands
real(8) :: energy         !< Total energy in Hartree
complex(8) :: wf(:,:)     !< Wavefunction coefficients
logical :: converged      !< Convergence flag
```

## 🔗 Cross-References

```fortran
!> @see compute_density
!> @see electronic_structure::wavefunction_type
!> @see module_name
```

## 📚 Citations

Add to `doc/references.bib`:
```bibtex
@article{Author2025,
  title   = {Paper Title},
  author  = {Last, First},
  journal = {Journal Name},
  year    = {2025},
  doi     = {10.1234/journal.2025}
}
```

Use in code:
```fortran
!! See @cite Author2025 for details.
```

## 🎯 Best Practices

### DO ✅
- Document all public subroutines and functions
- Include mathematical formulas for physics calculations
- Add `@param` for all parameters
- Use `@brief` for quick overview
- Cross-reference related functions with `@see`
- Cite papers with `@cite`
- Add inline comments for important variables

### DON'T ❌
- Don't use `@callgraph` everywhere (slows generation)
- Don't duplicate information
- Don't leave parameters undocumented
- Don't forget to update docs when changing code
- Don't use overly technical jargon without explanation

## 🔍 Examples

### Simple Function
```fortran
!> @brief Calculate the norm of a vector
!> @param[in] vec Input vector
!> @param[in] n Vector size
!> @return Norm of the vector
function vector_norm(vec, n) result(norm)
  implicit none
  real(8), intent(in) :: vec(n)  !< Input vector
  integer, intent(in) :: n       !< Vector size
  real(8) :: norm                !< Computed norm
  
  norm = sqrt(sum(vec**2))
end function vector_norm
```

### Physics Routine
```fortran
!> @brief Compute electronic density from wavefunctions
!> @author Your Name
!> @date 2025-01-15
!>
!> @details
!! Computes the electronic density in real space using:
!! \f[
!!   n(\mathbf{r}) = \sum_{i=1}^{N} f_i |\psi_i(\mathbf{r})|^2
!! \f]
!! where \f$f_i\f$ are occupation numbers and \f$\psi_i\f$ are
!! Kohn-Sham wavefunctions.
!!
!> @param[in] wf Wavefunctions array (n_points, n_states)
!> @param[in] occ Occupation numbers (n_states)
!> @param[out] density Electronic density (n_points)
!> @param[in] n_points Number of real-space points
!> @param[in] n_states Number of electronic states
!>
!> @note Wavefunctions must be normalized
!> @warning Assumes real-space representation
!>
!> @see compute_wavefunction, normalize_density
!> @cite Kohn1965
!>
subroutine compute_density(wf, occ, density, n_points, n_states)
  implicit none
  complex(8), intent(in) :: wf(n_points, n_states)
  real(8), intent(in) :: occ(n_states)
  real(8), intent(out) :: density(n_points)
  integer, intent(in) :: n_points, n_states
  
  integer :: i, j
  
  density = 0.0d0
  do j = 1, n_states
    do i = 1, n_points
      density(i) = density(i) + occ(j) * abs(wf(i,j))**2
    end do
  end do
  
end subroutine compute_density
```

### Module with Type
```fortran
!> @brief Module for k-point sampling
!> @author Your Name
!>
!> @details
!! Provides data structures and routines for Brillouin zone
!! sampling and k-point operations.
!!
module kpoint_module
  implicit none
  
  !> @brief K-point type
  type kpoint_type
    real(8) :: coord(3)     !< K-point coordinates (crystal)
    real(8) :: weight       !< Integration weight
    integer :: n_bands      !< Number of bands at this k-point
    real(8), allocatable :: energies(:)  !< Band energies (Ha)
  end type kpoint_type
  
  !> @brief K-point mesh type
  type kmesh_type
    integer :: n_kpoints              !< Total number of k-points
    type(kpoint_type), allocatable :: kpts(:)  !< K-point array
  end type kmesh_type
  
contains

  !> @brief Initialize k-point mesh
  !> @param[out] kmesh K-point mesh structure
  !> @param[in] nk Number of k-points
  subroutine init_kmesh(kmesh, nk)
    type(kmesh_type), intent(out) :: kmesh
    integer, intent(in) :: nk
    
    kmesh%n_kpoints = nk
    allocate(kmesh%kpts(nk))
  end subroutine init_kmesh
  
end module kpoint_module
```

## 🛠️ Troubleshooting

| Problem | Solution |
|---------|----------|
| Graphs not showing | Install Graphviz: `brew install graphviz` |
| Formulas not rendering | Check internet connection |
| Warnings about undocumented | Add `@param` for all parameters |
| CSS not applied | Clear browser cache |
| Slow generation | Use `./generate_docs.sh -q` |

## 📖 More Information

- Full guide: `doc/README_DOCUMENTATION.md`
- Summary: `DOCUMENTATION_SUMMARY.md`
- Doxygen manual: https://www.doxygen.nl/manual/
- MathJax docs: https://docs.mathjax.org/

---

**Keep this reference handy while documenting! 📚✨**