# 🌊 Yambo FORD Documentation

> **Documentation for the Yambo many-body physics code**

## 🚀 Quick Start

### 1. Install FORD and Dependencies

```bash
# Using pip
pip install -r doc/requirements.txt

# Or install FORD directly
pip install FORD==7.0.11
```

### 2. Generate Documentation

```bash
./generate_docs.sh
```

### 3. View Documentation

```bash
# macOS
open doc/ford_output/index.html

# Linux
xdg-open doc/ford_output/index.html

# Or use the script's built-in browser opening
./generate_docs.sh -o
```

## 📋 Available Commands

```bash
./generate_docs.sh           # Generate documentation
./generate_docs.sh -o        # Generate and open in browser
./generate_docs.sh -c        # Clean previous docs first
./generate_docs.sh -v        # Verbose output
./generate_docs.sh -s        # Generate and serve on localhost:8000
./generate_docs.sh -c -v -o  # Combine options
```

## 📁 Documentation Structure

```
yambo/
├── .ford                                 # FORD configuration file
├── generate_docs.sh                      # Documentation generator script
├── README_FORD.md                        # This file
│
├── doc/
│   ├── ford/                             # FORD page directory
│   │   ├── index.md                      # Main documentation page
│   │   ├── dark_theme.css               # Professional dark theme
│   │   ├── *.md                         # All documentation files
│   │
│   ├── markdown/                         # Original markdown source
│   ├── media/                            # Logos and images
│   │   ├── yambo_favicon.png
│   │   └── yambo_logo.png
│   │
│   ├── ford_output/                      # Generated documentation
│   │   └── index.html                    # Start here!
│   │
│   └── requirements.txt                  # Python dependencies
│
└── src/                                  # Fortran source files
```

## 📚 Documentation Index

### Core Theory
- **YAMBO Theory Documentation** - Comprehensive theoretical foundations
- **YAMBO Theory README** - Introduction to the theory
- **YAMBO Theory Visual Guide** - Diagrams and illustrations
- **YAMBO Theory Code Examples** - Implementation examples

### Input/Output System
- **IO System Architecture** - Complete I/O design
- **IO System Flowchart** - Data flow diagrams
- **IO Quick Reference** - Common I/O procedures
- **Input Flags Reference** - All available input parameters

### Memory & Allocation
- **Allocation Architecture** - Memory management system
- **Allocation Documentation** - Complete API reference
- **Allocation Examples** - Practical usage examples
- **Allocation Quick Reference** - Quick lookup card

### Real-Time Dynamics
- **Real-Time Theory Documentation** - Theoretical framework
- **Real-Time Visual Guide** - Illustrated concepts
- **YPP Real-Time Documentation** - Post-processing guide
- **YPP Real-Time Flowcharts** - Processing workflows

### Advanced Topics
- **Two-Time Green Functions** - Advanced correlation methods
- **Kadanoff-Baym Implementation** - Integro-differential solvers

See **Complete Documentation Index** in the generated docs for full list.

## 🔧 Prerequisites

### Required
- **Python 3.7+**: `python3 --version`
- **FORD 7.0+**: `pip install FORD`

### Recommended
- **Graphviz**: For dependency graphs
  - macOS: `brew install graphviz`
  - Ubuntu: `sudo apt-get install graphviz`

### Optional
- **Git**: For version tracking (usually already installed)

## 🛠️ Configuration

The FORD configuration is in the `.ford` file (YAML format):


### Common Modifications

**Change colors**: Edit `doc/ford/dark_theme.css`

**Add new pages**: Place markdown files in `doc/ford/` (they'll be auto-discovered)

**Exclude directories**: Add to `.ford`:
```yaml
exclude_dir: ./lib
exclude_dir: ./config
```

## 📝 Documentation Guidelines

### Code Documentation Format

For Fortran code, use this format:

```fortran
!> @brief One-line description
!> @details
!! Detailed description
!!
!! Equation example:
!! \f$ E = \sum_{i} \epsilon_i f_i \f$
!!
!> @param[in] input  Description
!> @param[out] output Description
!>
subroutine example(input, output)
  real(8), intent(in) :: input
  real(8), intent(out) :: output
end subroutine example
```

### Markdown Documentation

Create `.md` files in `doc/ford/` with proper metadata:

```markdown
---
project: Yambo
summary: Your page title
---

# Your Title

Your content here...
```

## 🌐 Serving Documentation

For local development, serve the documentation:

```bash
# Using the script
./generate_docs.sh -s

# Or manually
cd doc/ford_output
python3 -m http.server 8000
```

Then visit: **http://localhost:8000**

## 💡 Tips & Tricks

### Development Workflow

```bash
# Quick check during development
./generate_docs.sh -o

# Full regeneration before commit
./generate_docs.sh -c -v

# Serve for testing
./generate_docs.sh -s
```

### Direct Access to Sections

After generation, directly visit:
- **Modules**: `doc/ford_output/module/index.html`
- **Files**: `doc/ford_output/src/index.html`
- **Types**: `doc/ford_output/type/index.html`
- **Procedures**: `doc/ford_output/proc/index.html`

### Sharing Documentation

```bash
# Create downloadable archive
cd doc
tar -czf yambo_docs.tar.gz ford_output/

# Or ZIP
zip -r yambo_docs.zip ford_output/
```

## 📄 License

Yambo is distributed under **GNU General Public License v2.0 (GPL-2.0)**.  
See the COPYING file for details.

---

**Version**: FORD 7.0+  
**Last Updated**: 2025  
**Status**: Production Ready

*For the previous Doxygen documentation, see README_DOXYGEN.md (archived)*
