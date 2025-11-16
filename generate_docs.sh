#!/bin/bash
################################################################################
# Yambo Documentation Generator (FORD)
#
# This script generates comprehensive FORD documentation for the Yambo code
# with modern design, mathematical formulas, and professional dark theme.
#
# Usage: ./generate_docs.sh [options]
#
# Options:
#   -h, --help       Show this help message
#   -o, --open       Open documentation in browser after generation
#   -c, --clean      Clean previous documentation before generating
#   -v, --verbose    Verbose output
#   -s, --serve      Serve documentation locally after generation
################################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Default options
OPEN_BROWSER=false
CLEAN_FIRST=false
VERBOSE=false
SERVE_DOCS=false

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

################################################################################
# Functions
################################################################################

print_header() {
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}  🌊 Yambo Documentation Generator (FORD)                     ${BLUE}║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

show_help() {
    cat << EOF
Yambo Documentation Generator (FORD)

Usage: ./generate_docs.sh [options]

Options:
  -h, --help       Show this help message
  -o, --open       Open documentation in browser after generation
  -c, --clean      Clean previous documentation before generating
  -v, --verbose    Verbose output (show all FORD messages)
  -s, --serve      Serve documentation locally on http://localhost:8000

Examples:
  ./generate_docs.sh                    # Generate documentation
  ./generate_docs.sh -o                 # Generate and open in browser
  ./generate_docs.sh -c -v              # Clean and generate with verbose output
  ./generate_docs.sh -s                 # Generate and serve locally

EOF
}

check_dependencies() {
    print_info "Checking dependencies..."
    
    # Check for Python 3
    if ! command -v python3 &> /dev/null; then
        print_error "Python 3 is not installed!"
        echo "Please install Python 3.7 or higher"
        exit 1
    fi
    
    PYTHON_VERSION=$(python3 --version 2>&1 | awk '{print $2}')
    print_success "Python 3 found (version $PYTHON_VERSION)"
    
    # Check for ford
    if ! python3 -m pip show FORD &> /dev/null; then
        print_error "FORD is not installed!"
        echo "Please install FORD:"
        echo "  pip install FORD"
        echo ""
        echo "Or install from requirements:"
        echo "  pip install -r doc/requirements.txt"
        exit 1
    fi
    
    FORD_VERSION=$(python3 -c "import ford; print(ford.__version__)" 2>/dev/null || echo "unknown")
    print_success "FORD found (version $FORD_VERSION)"
    
    # Check for graphviz
    if ! command -v dot &> /dev/null; then
        print_warning "Graphviz (dot) is not installed - graphs will not be generated"
        echo "  macOS:   brew install graphviz"
        echo "  Ubuntu:  sudo apt-get install graphviz"
    else
        DOT_VERSION=$(dot -V 2>&1 | head -n1)
        print_success "Graphviz found ($DOT_VERSION)"
    fi
    
    echo ""
}

clean_documentation() {
    print_info "Cleaning previous documentation..."
    
    if [ -d "doc/ford_output" ]; then
        rm -rf doc/ford_output
        print_success "Removed doc/ford_output/"
    fi
    
    echo ""
}

generate_documentation() {
    print_info "Generating documentation with FORD..."
    echo ""
    
    START_TIME=$(date +%s)
    
    if [ "$VERBOSE" = true ]; then
        ford .ford
    else
        ford .ford 2>&1 | grep -E "(Building|Parsing|Creating|Documenting|Warning|Error)" || true
    fi
    
    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))
    
    echo ""
    print_success "Documentation generated in ${DURATION} seconds"
    
    # Add custom navigation menu
    if [ -f "doc/ford/add_nav_menu.py" ]; then
        print_info "Adding custom navigation menu..."
        python3 doc/ford/add_nav_menu.py
    fi
}

show_statistics() {
    print_info "Documentation statistics:"
    
    OUTPUT_DIR="doc/ford_output"
    
    if [ -d "$OUTPUT_DIR" ]; then
        NUM_HTML_FILES=$(find "$OUTPUT_DIR" -name "*.html" 2>/dev/null | wc -l | tr -d ' ')
        NUM_PAGE_FILES=$(find "$OUTPUT_DIR" -name "*.html" -path "*/page/*" 2>/dev/null | wc -l | tr -d ' ')
        TOTAL_SIZE=$(du -sh "$OUTPUT_DIR" 2>/dev/null | cut -f1)
        
        echo "  📄 HTML files: $NUM_HTML_FILES"
        echo "  📖 Documentation pages: $NUM_PAGE_FILES"
        echo "  💾 Total size: $TOTAL_SIZE"
    fi
    
    echo ""
}

open_documentation() {
    print_info "Opening documentation in browser..."
    
    INDEX_FILE="doc/ford_output/index.html"
    
    if [ ! -f "$INDEX_FILE" ]; then
        print_error "Documentation index file not found!"
        exit 1
    fi
    
    # Detect OS and open browser
    case "$(uname -s)" in
        Darwin*)
            open "$INDEX_FILE"
            ;;
        Linux*)
            if command -v xdg-open &> /dev/null; then
                xdg-open "$INDEX_FILE" &
            elif command -v firefox &> /dev/null; then
                firefox "$INDEX_FILE" &
            else
                print_warning "Could not detect browser. Please open manually:"
                echo "  file://$SCRIPT_DIR/$INDEX_FILE"
            fi
            ;;
        *)
            print_warning "Unknown OS. Please open manually:"
            echo "  file://$SCRIPT_DIR/$INDEX_FILE"
            ;;
    esac
    
    print_success "Documentation opened in browser"
}

serve_documentation() {
    print_info "Serving documentation on http://localhost:8000"
    echo "Press Ctrl+C to stop the server"
    echo ""
    
    OUTPUT_DIR="doc/ford_output"
    
    if [ ! -d "$OUTPUT_DIR" ]; then
        print_error "Documentation not found! Generate it first."
        exit 1
    fi
    
    cd "$OUTPUT_DIR"
    python3 -m http.server 8000 --bind 127.0.0.1
}

################################################################################
# Parse command line arguments
################################################################################

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -o|--open)
            OPEN_BROWSER=true
            shift
            ;;
        -c|--clean)
            CLEAN_FIRST=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -s|--serve)
            SERVE_DOCS=true
            shift
            ;;
        *)
            print_error "Unknown option: $1"
            echo "Use -h or --help for usage information"
            exit 1
            ;;
    esac
done

################################################################################
# Main execution
################################################################################

print_header

# Check dependencies
check_dependencies

# Clean if requested
if [ "$CLEAN_FIRST" = true ]; then
    clean_documentation
fi

# Generate documentation
generate_documentation

# Show statistics
show_statistics

# Open in browser if requested
if [ "$OPEN_BROWSER" = true ]; then
    open_documentation
fi

# Serve if requested
if [ "$SERVE_DOCS" = true ]; then
    serve_documentation
fi

# Final message
echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║${NC}  ✅ Documentation generation complete!                        ${GREEN}║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "📖 View documentation at: doc/ford_output/index.html"
echo ""
echo "📝 To serve documentation locally:"
echo "   ./generate_docs.sh -s"
echo ""

exit 0
