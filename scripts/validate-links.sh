#!/bin/bash

# Link Validation Script for ROG
# Checks for broken links and production URLs in dev builds

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

ERRORS=0
WARNINGS=0

echo "=== ROG Link Validator ==="
echo ""

# Build the site first
echo "Building site..."
rm -rf public
hugo --quiet

# Check 1: No production URLs in navigation links (exclude assets, canonical, preload)
echo "Checking for production URLs in navigation links..."
PROD_LINKS=$(grep -r "href=\"https://remnants.herbertyang.xyz" public/ --include="*.html" \
    | grep -v 'rel="canonical"' \
    | grep -v 'rel="preload' \
    | grep -v '\.css"' \
    | grep -v '\.js"' \
    | grep -v '\.png"' \
    | grep -v '\.ico"' \
    | grep -v '\.jpg"' \
    | grep -v '\.xml"' \
    | grep -v 'theme.png' \
    | wc -l | tr -d ' ')

if [ "$PROD_LINKS" -gt 0 ]; then
    echo -e "${RED}ERROR: Found $PROD_LINKS production URLs in navigation links${NC}"
    grep -r "href=\"https://remnants.herbertyang.xyz" public/ --include="*.html" \
        | grep -v 'rel="canonical"' \
        | grep -v 'rel="preload' \
        | grep -v '\.css"' \
        | grep -v '\.js"' \
        | grep -v '\.png"' \
        | grep -v '\.ico"' \
        | grep -v '\.jpg"' \
        | grep -v '\.xml"' \
        | grep -v 'theme.png' \
        | head -5
    echo "..."
    ERRORS=$((ERRORS + 1))
else
    echo -e "${GREEN}✓ No production URLs in navigation links${NC}"
fi

# Check 2: All internal links start with /
echo ""
echo "Checking internal link format..."
RELATIVE_LINKS=$(grep -rE 'href="[^/h#"][^"]*"' public/ --include="*.html" | grep -v "mailto:" | grep -v "javascript:" | wc -l | tr -d ' ')

if [ "$RELATIVE_LINKS" -gt 0 ]; then
    echo -e "${YELLOW}WARNING: Found $RELATIVE_LINKS potentially malformed internal links${NC}"
    grep -rE 'href="[^/h#"][^"]*"' public/ --include="*.html" | grep -v "mailto:" | grep -v "javascript:" | head -5
    WARNINGS=$((WARNINGS + 1))
else
    echo -e "${GREEN}✓ All internal links properly formatted${NC}"
fi

# Check 3: Taxonomy pages exist
echo ""
echo "Checking taxonomy pages..."
TAXONOMIES=("people" "cities" "countries")

for tax in "${TAXONOMIES[@]}"; do
    if [ -d "public/$tax" ]; then
        COUNT=$(ls -d public/$tax/*/ 2>/dev/null | wc -l | tr -d ' ')
        echo -e "${GREEN}✓ /$tax/ exists with $COUNT entries${NC}"
    else
        echo -e "${RED}ERROR: /$tax/ directory missing${NC}"
        ERRORS=$((ERRORS + 1))
    fi
done

# Check 4: Stories section exists
echo ""
echo "Checking stories section..."
if [ -d "public/stories" ]; then
    STORY_COUNT=$(find public/stories -name "index.html" | wc -l | tr -d ' ')
    echo -e "${GREEN}✓ /stories/ exists with $STORY_COUNT pages${NC}"
else
    echo -e "${RED}ERROR: /stories/ directory missing${NC}"
    ERRORS=$((ERRORS + 1))
fi

# Check 5: Menu links are valid
echo ""
echo "Checking menu links..."
MENU_LINKS=("/stories/" "/people/" "/cities/" "/countries/" "/about/")

for link in "${MENU_LINKS[@]}"; do
    DIR="public${link}"
    if [ -d "$DIR" ] || [ -f "${DIR}index.html" ]; then
        echo -e "${GREEN}✓ Menu link $link is valid${NC}"
    else
        echo -e "${RED}ERROR: Menu link $link has no content${NC}"
        ERRORS=$((ERRORS + 1))
    fi
done

# Summary
echo ""
echo "=== Summary ==="
if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}All checks passed!${NC}"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}$WARNINGS warning(s), no errors${NC}"
    exit 0
else
    echo -e "${RED}$ERRORS error(s), $WARNINGS warning(s)${NC}"
    exit 1
fi
