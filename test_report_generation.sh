#!/bin/bash
################################################################################
# Test Script to Verify Report and Plot Generation Capabilities
# Tests the pipeline's ability to generate reports and plots
################################################################################

echo "========================================="
echo "Testing GWAS Pipeline Report & Plot Generation"
echo "========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

pass_count=0
fail_count=0

# Test function
test_component() {
    local test_name="$1"
    local command="$2"
    
    echo -n "Testing: $test_name... "
    if eval "$command" &>/dev/null; then
        echo -e "${GREEN}PASS${NC}"
        ((pass_count++))
        return 0
    else
        echo -e "${RED}FAIL${NC}"
        ((fail_count++))
        return 1
    fi
}

echo "1. Checking Dependencies"
echo "-------------------------"

# Check if bash is available
test_component "Bash shell" "bash --version"

# Check if awk is available
test_component "AWK" "awk --version"

# Check if Python3 is available
test_component "Python3" "python3 --version"

# Check Python packages
if command -v python3 &>/dev/null; then
    echo -n "Testing: Python pandas... "
    if python3 -c "import pandas" 2>/dev/null; then
        echo -e "${GREEN}PASS${NC}"
        ((pass_count++))
    else
        echo -e "${RED}FAIL${NC} - Install with: pip install pandas"
        ((fail_count++))
    fi
    
    echo -n "Testing: Python numpy... "
    if python3 -c "import numpy" 2>/dev/null; then
        echo -e "${GREEN}PASS${NC}"
        ((pass_count++))
    else
        echo -e "${RED}FAIL${NC} - Install with: pip install numpy"
        ((fail_count++))
    fi
    
    echo -n "Testing: Python matplotlib... "
    if python3 -c "import matplotlib" 2>/dev/null; then
        echo -e "${GREEN}PASS${NC}"
        ((pass_count++))
    else
        echo -e "${RED}FAIL${NC} - Install with: pip install matplotlib"
        ((fail_count++))
    fi
    
    echo -n "Testing: Python seaborn... "
    if python3 -c "import seaborn" 2>/dev/null; then
        echo -e "${GREEN}PASS${NC}"
        ((pass_count++))
    else
        echo -e "${YELLOW}WARN${NC} - Install with: pip install seaborn (optional)"
    fi
fi

echo ""
echo "2. Checking Required Scripts"
echo "-----------------------------"

# Check if generate_plots.py exists
if [ -f "generate_plots.py" ]; then
    echo -e "generate_plots.py: ${GREEN}FOUND${NC}"
    ((pass_count++))
    
    # Check if it's executable/readable
    if [ -r "generate_plots.py" ]; then
        echo -e "  - Readable: ${GREEN}YES${NC}"
        ((pass_count++))
    else
        echo -e "  - Readable: ${RED}NO${NC}"
        ((fail_count++))
    fi
else
    echo -e "generate_plots.py: ${RED}NOT FOUND${NC}"
    ((fail_count++))
fi

# Check if extract_top_snps.py exists
if [ -f "extract_top_snps.py" ]; then
    echo -e "extract_top_snps.py: ${GREEN}FOUND${NC}"
    ((pass_count++))
    
    if [ -r "extract_top_snps.py" ]; then
        echo -e "  - Readable: ${GREEN}YES${NC}"
        ((pass_count++))
    else
        echo -e "  - Readable: ${RED}NO${NC}"
        ((fail_count++))
    fi
else
    echo -e "extract_top_snps.py: ${RED}NOT FOUND${NC}"
    ((fail_count++))
fi

echo ""
echo "3. Testing Report Generation Components"
echo "----------------------------------------"

# Test basic report generation (shell script capabilities)
echo -n "Testing: Text report generation... "
if {
    echo "========================================="
    echo "Test Report"
    echo "========================================="
    echo "Date: $(date)"
    echo "Sample count: 100"
} > /tmp/test_report.txt 2>/dev/null; then
    echo -e "${GREEN}PASS${NC}"
    ((pass_count++))
    rm -f /tmp/test_report.txt
else
    echo -e "${RED}FAIL${NC}"
    ((fail_count++))
fi

# Test awk report generation
echo -n "Testing: AWK data processing... "
if echo -e "1\t2\t3\n4\t5\t6" | awk '{print $1, $2, $3}' > /dev/null 2>&1; then
    echo -e "${GREEN}PASS${NC}"
    ((pass_count++))
else
    echo -e "${RED}FAIL${NC}"
    ((fail_count++))
fi

echo ""
echo "4. Testing Python Script Syntax"
echo "--------------------------------"

if command -v python3 &>/dev/null; then
    # Test generate_plots.py syntax
    echo -n "Testing: generate_plots.py syntax... "
    if python3 -m py_compile generate_plots.py 2>/dev/null; then
        echo -e "${GREEN}PASS${NC}"
        ((pass_count++))
    else
        echo -e "${RED}FAIL${NC}"
        ((fail_count++))
    fi
    
    # Test extract_top_snps.py syntax
    echo -n "Testing: extract_top_snps.py syntax... "
    if python3 -m py_compile extract_top_snps.py 2>/dev/null; then
        echo -e "${GREEN}PASS${NC}"
        ((pass_count++))
    else
        echo -e "${RED}FAIL${NC}"
        ((fail_count++))
    fi
fi

echo ""
echo "5. Testing Mock Data Processing"
echo "--------------------------------"

# Create mock association data
MOCK_ASSOC="/tmp/mock_assoc.assoc"
cat > "$MOCK_ASSOC" << 'EOF'
CHR SNP BP A1 F_A F_U A2 CHISQ P OR
1 rs123 1000 A 0.5 0.4 G 2.5 0.001 1.2
1 rs456 2000 T 0.3 0.2 C 4.2 0.00001 1.5
2 rs789 3000 G 0.6 0.5 A 1.8 0.05 1.1
EOF

if command -v python3 &>/dev/null && python3 -c "import pandas" 2>/dev/null; then
    echo -n "Testing: Python SNP extraction... "
    if python3 extract_top_snps.py "$MOCK_ASSOC" "/tmp" 2>/dev/null; then
        if [ -f "/tmp/top_100_snps.txt" ]; then
            echo -e "${GREEN}PASS${NC}"
            ((pass_count++))
            rm -f /tmp/top_*.txt /tmp/genome_wide_*.txt /tmp/suggestive_*.txt /tmp/summary_statistics.txt
        else
            echo -e "${RED}FAIL${NC} - Output file not created"
            ((fail_count++))
        fi
    else
        echo -e "${RED}FAIL${NC}"
        ((fail_count++))
    fi
fi

# Clean up mock data
rm -f "$MOCK_ASSOC"

echo ""
echo "========================================="
echo "Test Results Summary"
echo "========================================="
echo -e "Passed: ${GREEN}${pass_count}${NC}"
echo -e "Failed: ${RED}${fail_count}${NC}"
echo ""

if [ $fail_count -eq 0 ]; then
    echo -e "${GREEN}✓ All tests passed!${NC}"
    echo "The pipeline should be able to generate reports and plots correctly."
    echo ""
    echo "Note: If running on a cluster without display, plots will use the"
    echo "non-interactive 'Agg' backend (already configured in generate_plots.py)."
else
    echo -e "${YELLOW}⚠ Some tests failed${NC}"
    echo ""
    echo "Recommendations:"
    if ! command -v python3 &>/dev/null; then
        echo "  - Install Python3"
    fi
    if command -v python3 &>/dev/null; then
        if ! python3 -c "import pandas" 2>/dev/null; then
            echo "  - Install pandas: pip install pandas"
        fi
        if ! python3 -c "import numpy" 2>/dev/null; then
            echo "  - Install numpy: pip install numpy"
        fi
        if ! python3 -c "import matplotlib" 2>/dev/null; then
            echo "  - Install matplotlib: pip install matplotlib"
        fi
        if ! python3 -c "import seaborn" 2>/dev/null; then
            echo "  - Install seaborn: pip install seaborn"
        fi
    fi
fi

echo ""
echo "========================================="
echo "Report Generation: Shell-based reports will ALWAYS work"
echo "Plot Generation: Requires Python3 + matplotlib/pandas/numpy"
echo "========================================="
