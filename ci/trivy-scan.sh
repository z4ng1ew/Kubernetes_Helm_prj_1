#!/bin/bash

# Trivy Security Scanner Script
# Usage: ./trivy-scan.sh <image_name> <component_name>

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
TRIVY_VERSION="0.48.3"
TRIVY_CACHE_DIR="${TRIVY_CACHE_DIR:-.trivycache/}"
SEVERITY_LEVELS="CRITICAL,HIGH,MEDIUM"
FAIL_ON_SEVERITY="CRITICAL,HIGH"

# Input parameters
IMAGE_NAME="$1"
COMPONENT_NAME="$2"

if [[ -z "$IMAGE_NAME" || -z "$COMPONENT_NAME" ]]; then
    echo -e "${RED}Error: Usage: $0 <image_name> <component_name>${NC}"
    exit 1
fi

echo -e "${BLUE}=== Trivy Security Scanner ===${NC}"
echo -e "${BLUE}Image: $IMAGE_NAME${NC}"
echo -e "${BLUE}Component: $COMPONENT_NAME${NC}"
echo -e "${BLUE}Severity Levels: $SEVERITY_LEVELS${NC}"
echo ""

# Install Trivy
install_trivy() {
    echo -e "${YELLOW}Installing Trivy $TRIVY_VERSION...${NC}"
    
    # Download and install trivy
    curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin v$TRIVY_VERSION
    
    # Verify installation
    trivy --version
    echo -e "${GREEN}Trivy installed successfully${NC}"
}

# Create cache directory
mkdir -p "$TRIVY_CACHE_DIR"

# Install Trivy if not present
if ! command -v trivy &> /dev/null; then
    install_trivy
fi

# Update vulnerability database
echo -e "${YELLOW}Updating vulnerability database...${NC}"
trivy image --download-db-only --cache-dir "$TRIVY_CACHE_DIR"

# Define output files
JSON_OUTPUT="${COMPONENT_NAME}-scan-results.json"
XML_OUTPUT="${COMPONENT_NAME}-scan-results.xml"
TABLE_OUTPUT="${COMPONENT_NAME}-scan-results.txt"

# Run vulnerability scan
echo -e "${YELLOW}Running vulnerability scan...${NC}"

# JSON format for programmatic processing
trivy image \
    --format json \
    --severity "$SEVERITY_LEVELS" \
    --cache-dir "$TRIVY_CACHE_DIR" \
    --output "$JSON_OUTPUT" \
    "$IMAGE_NAME"

# Table format for human-readable output
trivy image \
    --format table \
    --severity "$SEVERITY_LEVELS" \
    --cache-dir "$TRIVY_CACHE_DIR" \
    --output "$TABLE_OUTPUT" \
    "$IMAGE_NAME"

# Convert JSON to JUnit XML format for GitLab CI
convert_to_junit() {
    echo -e "${YELLOW}Converting results to JUnit XML format...${NC}"
    
    # Create JUnit XML header
    cat > "$XML_OUTPUT" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<testsuites name="Trivy Security Scan" tests="0" failures="0" errors="0" time="0">
    <testsuite name="$COMPONENT_NAME" tests="0" failures="0" errors="0" time="0">
EOF

    # Parse JSON and add test cases
    python3 << 'PYTHON_SCRIPT'
import json
import sys
import xml.etree.ElementTree as ET

try:
    with open('JSON_OUTPUT'.replace('JSON_OUTPUT', sys.argv[1]), 'r') as f:
        data = json.load(f)
    
    testsuite = ET.Element('testsuite')
    testsuite.set('name', sys.argv[2])
    
    test_count = 0
    failure_count = 0
    
    if 'Results' in data:
        for result in data['Results']:
            if 'Vulnerabilities' in result:
                for vuln in result['Vulnerabilities']:
                    test_count += 1
                    testcase = ET.SubElement(testsuite, 'testcase')
                    testcase.set('name', f"{vuln['PkgName']} - {vuln['VulnerabilityID']}")
                    testcase.set('classname', f"{result.get('Target', 'unknown')}")
                    
                    if vuln['Severity'] in ['CRITICAL', 'HIGH']:
                        failure_count += 1
                        failure = ET.SubElement(testcase, 'failure')
                        failure.set('message', f"Vulnerability {vuln['VulnerabilityID']} found")
                        failure.set('type', vuln['Severity'])
                        failure.text = f"Package: {vuln['PkgName']}\nVersion: {vuln.get('InstalledVersion', 'unknown')}\nSeverity: {vuln['Severity']}\nDescription: {vuln.get('Description', 'No description')}"
    
    testsuite.set('tests', str(test_count))
    testsuite.set('failures', str(failure_count))
    
    # Write to file
    with open('XML_OUTPUT'.replace('XML_OUTPUT', sys.argv[3]), 'w') as f:
        f.write('<?xml version="1.0" encoding="UTF-8"?>\n')
        f.write('<testsuites>\n')
        f.write(ET.tostring(testsuite, encoding='unicode'))
        f.write('\n</testsuites>')
    
    print(f"Total vulnerabilities: {test_count}")
    print(f"Critical/High vulnerabilities: {failure_count}")
    
except Exception as e:
    print(f"Error processing JSON: {e}")
    sys.exit(1)
PYTHON_SCRIPT

    python3 - "$JSON_OUTPUT" "$COMPONENT_NAME" "$XML_OUTPUT"
    
    # Close JUnit XML
    echo "    </testsuite>" >> "$XML_OUTPUT"
    echo "</testsuites>" >> "$XML_OUTPUT"
}

# Install Python if not present (for XML conversion)
if ! command -v python3 &> /dev/null; then
    echo -e "${YELLOW}Installing Python3...${NC}"
    apk add --no-cache python3
fi

# Convert to JUnit XML
convert_to_junit

# Display results summary
echo -e "${BLUE}=== Scan Results Summary ===${NC}"
if [[ -f "$JSON_OUTPUT" ]]; then
    # Parse JSON to show summary
    TOTAL_VULNS=$(python3 -c "
import json
with open('$JSON_OUTPUT') as f:
    data = json.load(f)
    total = 0
    if 'Results' in data:
        for result in data['Results']:
            if 'Vulnerabilities' in result:
                total += len(result['Vulnerabilities'])
    print(total)
" 2>/dev/null || echo "0")

    CRITICAL_HIGH=$(python3 -c "
import json
with open('$JSON_OUTPUT') as f:
    data = json.load(f)
    count = 0
    if 'Results' in data:
        for result in data['Results']:
            if 'Vulnerabilities' in result:
                for vuln in result['Vulnerabilities']:
                    if vuln['Severity'] in ['CRITICAL', 'HIGH']:
                        count += 1
    print(count)
" 2>/dev/null || echo "0")

    echo -e "${BLUE}Total vulnerabilities found: $TOTAL_VULNS${NC}"
    echo -e "${BLUE}Critical/High severity: $CRITICAL_HIGH${NC}"
    
    if [[ $CRITICAL_HIGH -gt 0 ]]; then
        echo -e "${RED}❌ Security scan failed: Found $CRITICAL_HIGH critical/high severity vulnerabilities${NC}"
        echo -e "${RED}Please review the detailed results in $JSON_OUTPUT${NC}"
        
        # Show critical/high vulnerabilities
        echo -e "${RED}Critical/High vulnerabilities:${NC}"
        python3 -c "
import json
with open('$JSON_OUTPUT') as f:
    data = json.load(f)
    if 'Results' in data:
        for result in data['Results']:
            if 'Vulnerabilities' in result:
                for vuln in result['Vulnerabilities']:
                    if vuln['Severity'] in ['CRITICAL', 'HIGH']:
                        print(f\"- {vuln['VulnerabilityID']} ({vuln['Severity']}): {vuln['PkgName']} - {vuln.get('Description', 'No description')[:100]}...\")
" 2>/dev/null || echo "Error parsing vulnerabilities"
        
        exit 1
    else
        echo -e "${GREEN}✅ Security scan passed: No critical/high severity vulnerabilities found${NC}"
    fi
fi

# Archive results
echo -e "${YELLOW}Archiving scan results...${NC}"
echo "Scan results saved to:"
echo "  - JSON: $JSON_OUTPUT"
echo "  - XML: $XML_OUTPUT"
echo "  - Table: $TABLE_OUTPUT"

# Create summary report
echo -e "${BLUE}=== Security Scan Report ===${NC}" > "${COMPONENT_NAME}-security-report.txt"
echo "Component: $COMPONENT_NAME" >> "${COMPONENT_NAME}-security-report.txt"
echo "Image: $IMAGE_NAME" >> "${COMPONENT_NAME}-security-report.txt"
echo "Scan Date: $(date)" >> "${COMPONENT_NAME}-security-report.txt"
echo "Total Vulnerabilities: $TOTAL_VULNS" >> "${COMPONENT_NAME}-security-report.txt"
echo "Critical/High Severity: $CRITICAL_HIGH" >> "${COMPONENT_NAME}-security-report.txt"
echo "" >> "${COMPONENT_NAME}-security-report.txt"
echo "Detailed results are available in $JSON_OUTPUT" >> "${COMPONENT_NAME}-security-report.txt"

echo -e "${GREEN}Security scan completed successfully${NC}"
