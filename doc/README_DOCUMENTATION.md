# Yambo Documentation Guide

Welcome to the Yambo documentation system! This guide will help you generate, customize, and maintain comprehensive documentation for the Yambo codebase.

## 🌊 Features

### Comprehensive Documentation
- **Full Source Code Coverage**: All modules, subroutines, and functions
- **Mathematical Formulas**: LaTeX equations rendered beautifully with MathJax
- **Interactive Graphs**: Call graphs, caller graphs, and dependency diagrams
- **Cross-References**: Easy navigation between related code sections
- **Search Functionality**: Fast, client-side search through all documentation

### Advanced Features
- **Call Graphs**: Visualize function call hierarchies
- **Caller Graphs**: See where functions are used
- **Include Dependencies**: Track file inclusion relationships
- **Directory Structure**: Navigate the codebase organization
- **Bibliography Support**: Cite scientific papers with BibTeX

## 🚀 Quick Start

### 1. Generate Documentation

The easiest way to generate documentation is using the provided script:

```bash
./generate_docs.sh
```

This will:
- Check for required dependencies (Doxygen, Graphviz)
- Generate complete documentation with graphs and formulas
- Create output in `doc/doxygen_output/html/`
- Show statistics about the generated documentation

### 2. View Documentation

Open the documentation in your browser:

```bash
# macOS
open doc/doxygen_output/html/index.html

# Linux
xdg-open doc/doxygen_output/html/index.html

# Or use the script with -o flag
./generate_docs.sh -o
```

### 3. Quick Generation (No Graphs)

For faster generation during development:

```bash
./generate_docs.sh -q
```

This disables graph generation, making the process much faster.

## 📋 Script Options

The `generate_docs.sh` script supports several options:

| Option | Description |
|--------|-------------|
| `-h, --help` | Show help message |
| `-q, --quick` | Quick generation (disable graphs) |
| `-o, --open` | Open documentation in browser after generation |
| `-c, --clean` | Clean previous documentation before generating |
| `-v, --verbose` | Show all Doxygen output messages |

### Examples

```bash
# Generate and open in browser
./generate_docs.sh -o

# Clean and regenerate with verbose output
./generate_docs.sh -c -v

# Quick generation and open
./generate_docs.sh -q -o
```

## 🔧 Prerequisites

### Required

**Doxygen** (version 1.9.0 or later)

```bash
# macOS
brew install doxygen

# Ubuntu/Debian
sudo apt-get install doxygen

# Fedora/RHEL
sudo dnf install doxygen
```

### Recommended

**Graphviz** (for generating graphs and diagrams)

```bash
# macOS
brew install graphviz

# Ubuntu/Debian
sudo apt-get install graphviz

# Fedora/RHEL
sudo dnf install graphviz
```

### Optional

**LaTeX** (for PDF generation)

```bash
# macOS
brew install --cask mactex

# Ubuntu/Debian
sudo apt-get install texlive-full
```

## 📁 File Structure

```
Yambo/
├── Doxyfile                              # Main Doxygen configuration
├── generate_docs.sh                      # Documentation generation script
├── doc/
│   ├── doxygen/
│   │   ├── custom_sea_theme.css         # Sea-inspired CSS theme
│   │   ├── mainpage.md                  # Main documentation page
│   │   └── 000_doxygen_example.F        # Example documentation
│   ├── references.bib                    # Bibliography (BibTeX format)
│   ├── images/                           # Images for documentation
│   ├── IO_System_Architecture.md         # I/O system comprehensive guide
│   ├── IO_System_Flowchart.md           # I/O system visual diagrams
│   ├── IO_Quick_Reference.md            # I/O quick reference card
│   └── doxygen_output/                   # Generated documentation (gitignored)
│       ├── html/                         # HTML output
│       └── latex/                        # LaTeX output (if enabled)
└── .gitignore                            # Excludes generated files
```

## 🎨 Customization

### Changing the Color Theme

Edit `doc/doxygen/custom_sea_theme.css` and modify the CSS variables:

```css
:root {
  --primary-blue: #4A90E2;      /* Main blue color */
  --light-blue: #E3F2FD;        /* Light backgrounds */
  --medium-blue: #64B5F6;       /* Medium accents */
  --dark-blue: #1565C0;         /* Dark text/headers */
  --accent-turquoise: #00ACC1;  /* Accent color */
  --light-turquoise: #B2EBF2;   /* Light turquoise */
  --text-color: #263238;        /* Main text color */
  --background: #F8FCFF;        /* Page background */
}
```

### Adding Custom Pages

1. Create a Markdown file in `doc/doxygen/`:
   ```bash
   touch doc/doxygen/my_custom_page.md
   ```

2. Add it to the `INPUT` list in `Doxyfile`:
   ```
   INPUT = src \
           driver \
           ypp \
           doc/doxygen/mainpage.md \
           doc/doxygen/my_custom_page.md
   ```

3. Regenerate documentation:
   ```bash
   ./generate_docs.sh
   ```

### Modifying Doxygen Settings

Edit the `Doxyfile` in the root directory. Key settings:

```
PROJECT_NAME           = "Yambo"
PROJECT_NUMBER         = "1.0"
PROJECT_BRIEF          = "Many-Body Computational Physics Code"
OUTPUT_DIRECTORY       = doc/doxygen_output
OPTIMIZE_FOR_FORTRAN   = YES
USE_MATHJAX            = YES
HAVE_DOT               = YES
CALL_GRAPH             = YES
CALLER_GRAPH           = YES
```

## 📝 Writing Documentation

### Documenting Subroutines

Use Doxygen comments before subroutines:

```fortran
!> @brief Calculate the electronic density from wavefunctions
!> @author Your Name
!> @date 2025-01-15
!>
!> @details
!! This routine computes the electronic density in real space
!! from the Kohn-Sham wavefunctions using the formula:
!! \f[
!!   n(\mathbf{r}) = \sum_{i=1}^{N} f_i |\psi_i(\mathbf{r})|^2
!! \f]
!! where \f$f_i\f$ are the occupation numbers.
!!
!> @param[in] wf Wavefunctions array
!> @param[in] occ Occupation numbers
!> @param[out] density Electronic density
!> @param[in] n_states Number of states
!>
!> @note The wavefunctions must be normalized
!> @warning This routine assumes real-space representation
!>
!> @see compute_wavefunction, normalize_density
!>
!> @callgraph
!> @callergraph
subroutine compute_density(wf, occ, density, n_states)
  implicit none
  complex(8), intent(in) :: wf(:,:)
  real(8), intent(in) :: occ(:)
  real(8), intent(out) :: density(:)
  integer, intent(in) :: n_states
  
  ! Implementation here
  
end subroutine compute_density
```

### Documenting Modules

```fortran
!> @brief Module for electronic structure calculations
!> @author Your Name
!>
!> @details
!! This module provides data structures and routines for
!! electronic structure calculations including:
!! - Wavefunction storage and manipulation
!! - Density calculations
!! - Energy computations
!!
module electronic_structure
  implicit none
  
  !> @brief Maximum number of bands
  integer, parameter :: max_bands = 1000
  
  !> @brief Electronic state type
  type electronic_state
    real(8) :: energy        !< Energy eigenvalue (Ha)
    real(8) :: occupation    !< Occupation number (0-2)
    complex(8), allocatable :: wavefunction(:) !< Wavefunction coefficients
  end type electronic_state
  
contains
  ! Subroutines and functions
end module electronic_structure
```

### Mathematical Formulas

#### Inline Formulas
```fortran
!! The energy is given by \f$ E = \hbar \omega \f$
```

#### Display Formulas
```fortran
!! The Schrödinger equation is:
!! \f[
!!   \hat{H} \psi = E \psi
!! \f]
```

#### Complex Equations
```fortran
!! The GW self-energy is:
!! \f[
!!   \Sigma(\mathbf{r}, \mathbf{r}', \omega) = 
!!   i \int \frac{d\omega'}{2\pi} 
!!   G(\mathbf{r}, \mathbf{r}', \omega + \omega') 
!!   W(\mathbf{r}, \mathbf{r}', \omega')
!! \f]
```

### Special Commands

| Command | Purpose | Example |
|---------|---------|---------|
| `@brief` | One-line description | `!> @brief Calculate density` |
| `@author` | Author name | `!> @author John Doe` |
| `@date` | Date | `!> @date 2025-01-15` |
| `@details` | Detailed description | `!> @details This routine...` |
| `@param[in]` | Input parameter | `!> @param[in] x Input value` |
| `@param[out]` | Output parameter | `!> @param[out] y Output value` |
| `@param[in,out]` | Input/output parameter | `!> @param[in,out] z Modified value` |
| `@note` | Important note | `!> @note Must be normalized` |
| `@warning` | Warning | `!> @warning May fail for large N` |
| `@todo` | Future work | `!> @todo Add GPU support` |
| `@bug` | Known bug | `!> @bug Fails for N=0` |
| `@see` | Cross-reference | `!> @see other_function` |
| `@cite` | Citation | `!> @cite Hedin1965` |
| `@callgraph` | Generate call graph | `!> @callgraph` |
| `@callergraph` | Generate caller graph | `!> @callergraph` |

### Custom Aliases

Predefined aliases for convenience:

```fortran
!> @am                    ! Expands to: @author Andrea Marini
!> @ch                    ! Expands to: @author Conor Hogan
!> @formula               ! Creates "Formula:" section
!> @algorithm             ! Creates "Algorithm:" section
!> @complexity            ! Creates "Complexity:" section
!> @physics               ! Creates "Physics Background:" section
```

## 📚 Adding References

Add scientific references to `doc/references.bib` in BibTeX format:

```bibtex
@article{YourReference2025,
  title     = {Title of the Paper},
  author    = {Last, First and Other, Author},
  journal   = {Journal Name},
  volume    = {123},
  number    = {4},
  pages     = {567--890},
  year      = {2025},
  publisher = {Publisher},
  doi       = {10.1234/journal.2025.123456}
}
```

Then cite in your documentation:

```fortran
!! See @cite YourReference2025 for details.
```

## 🔍 Troubleshooting

### Graphs Not Appearing

**Problem**: Call graphs and dependency graphs are missing.

**Solutions**:
1. Install Graphviz: `brew install graphviz` (macOS) or `apt-get install graphviz` (Linux)
2. Verify installation: `dot -V`
3. Check `HAVE_DOT = YES` in Doxyfile
4. Regenerate: `./generate_docs.sh -c`

### Formulas Not Rendering

**Problem**: Mathematical formulas show as raw LaTeX code.

**Solutions**:
1. Check internet connection (MathJax loads from CDN)
2. Verify `USE_MATHJAX = YES` in Doxyfile
3. Clear browser cache and reload
4. For offline use, download MathJax locally and update `MATHJAX_RELPATH`

### Slow Generation

**Problem**: Documentation takes too long to generate.

**Solutions**:
1. Use quick mode: `./generate_docs.sh -q`
2. Reduce graph complexity: Set `DOT_GRAPH_MAX_NODES = 30` in Doxyfile
3. Disable source browser: Set `SOURCE_BROWSER = NO`
4. Use multiple threads: Set `DOT_NUM_THREADS = 4`

### Many Warnings

**Problem**: Lots of warnings about undocumented items.

**Solutions**:
1. Suppress warnings: Set `WARN_IF_UNDOCUMENTED = NO` in Doxyfile
2. Better: Add documentation to your code!
3. View warnings: `cat doc/doxygen_warnings.log`

### CSS Not Applied

**Problem**: Custom sea theme not showing.

**Solutions**:
1. Verify file exists: `ls doc/doxygen/custom_sea_theme.css`
2. Check path in Doxyfile: `HTML_EXTRA_STYLESHEET = doc/doxygen/custom_sea_theme.css`
3. Clear browser cache: Ctrl+Shift+R (or Cmd+Shift+R on macOS)
4. Regenerate: `./generate_docs.sh -c`

## 🎯 Best Practices

### Documentation Standards

1. **Always document public interfaces**: All subroutines and functions that are called from other modules
2. **Include mathematical formulas**: For physics calculations, show the equations
3. **Add examples**: Show how to use complex routines
4. **Cross-reference**: Link related functions with `@see`
5. **Cite papers**: Reference scientific literature with `@cite`
6. **Use call graphs sparingly**: Only for important routines (they slow generation)

### Code Organization

1. **Group related functions**: Use `@defgroup` to create logical groups
2. **Document modules thoroughly**: Explain the purpose and contents
3. **Keep descriptions concise**: Brief should be one line, details can be longer
4. **Update documentation with code**: Keep docs in sync with implementation

### Maintenance

1. **Regenerate regularly**: After significant code changes
2. **Review warnings**: Check `doc/doxygen_warnings.log` periodically
3. **Update references**: Add new papers to `references.bib`
4. **Test links**: Verify cross-references work correctly
5. **Version control**: Commit Doxyfile and CSS changes

## 📚 Additional Documentation

### I/O System Documentation

- **[I/O System Architecture](IO_System_Architecture.md)** - Complete guide to the I/O system
  - Overview of the I/O architecture and design principles
  - Core components (control, connection, data layers)
  - Parallel I/O strategies (MPI + OpenMP)
  - Database structure and sections
  - Common I/O patterns and examples
  - Performance considerations and debugging tips

## 📖 Resources

### Doxygen
- [Official Manual](https://www.doxygen.nl/manual/)
- [Markdown Support](https://www.doxygen.nl/manual/markdown.html)
- [Formula Support](https://www.doxygen.nl/manual/formulas.html)
- [Fortran Support](https://www.doxygen.nl/manual/fortran.html)

### MathJax
- [MathJax Documentation](https://docs.mathjax.org/)
- [LaTeX Commands](https://www.mathjax.org/docs/latest/input/tex/macros/)
- [LaTeX Math Symbols](https://www.overleaf.com/learn/latex/List_of_Greek_letters_and_math_symbols)

### Graphviz
- [Graphviz Documentation](https://graphviz.org/documentation/)
- [DOT Language Guide](https://graphviz.org/doc/info/lang.html)

## 💡 Tips and Tricks

### Faster Development Workflow

```bash
# Quick generation during development
./generate_docs.sh -q -o

# Full generation before commit
./generate_docs.sh -c -v
```

### Viewing Specific Sections

After generation, you can directly open specific pages:
- **Modules**: `doc/doxygen_output/html/modules.html`
- **Files**: `doc/doxygen_output/html/files.html`
- **Functions**: `doc/doxygen_output/html/globals.html`

### Searching Documentation

Use the search box in the generated documentation for fast navigation. It supports:
- Function names
- Module names
- Variable names
- Text in descriptions

### Exporting Documentation

To share documentation:

```bash
# Create archive
cd doc/doxygen_output
tar -czf Yambo_docs.tar.gz html/

# Or zip
zip -r Yambo_docs.zip html/
```

## 🤝 Contributing

When contributing to Yambo:

1. **Document your code**: Follow the guidelines above
2. **Test documentation**: Run `./generate_docs.sh` and check output
3. **Fix warnings**: Address any warnings in your new code
4. **Update this guide**: If you add new documentation features

## 📞 Support

For questions or issues:

- Check this README
- Review the [Doxygen manual](https://www.doxygen.nl/manual/)
- See the ISSUES file in the repository
- Contact the development team (see AUTHORS file)

---

**Happy Documenting! 🌊📚✨**