#!/bin/bash
# Test script for osdo-sast action
# Tests both clean and vulnerable code scenarios

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ACTION_DIR="$SCRIPT_DIR"

echo "🧪 Testing osdo-sast Action"
echo "================================"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Test counter
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Helper function
run_test() {
    local test_name=$1
    local expected_result=$2  # "pass" or "fail"
    TESTS_RUN=$((TESTS_RUN + 1))
    
    echo ""
    echo "Test $TESTS_RUN: $test_name"
    echo "----------------------------"
    
    if [ "$expected_result" = "fail" ]; then
        if ! eval "$3"; then
            echo -e "${GREEN}✓ Test passed (expected failure)${NC}"
            TESTS_PASSED=$((TESTS_PASSED + 1))
        else
            echo -e "${RED}✗ Test failed (expected failure, got success)${NC}"
            TESTS_FAILED=$((TESTS_FAILED + 1))
        fi
    else
        if eval "$3"; then
            echo -e "${GREEN}✓ Test passed${NC}"
            TESTS_PASSED=$((TESTS_PASSED + 1))
        else
            echo -e "${RED}✗ Test failed${NC}"
            TESTS_FAILED=$((TESTS_FAILED + 1))
        fi
    fi
}

# Setup test directories
TEST_DIR=$(mktemp -d)
trap "rm -rf $TEST_DIR" EXIT

echo "Test directory: $TEST_DIR"

# Test 1: Clean Python code
mkdir -p "$TEST_DIR/clean-python"
cat > "$TEST_DIR/clean-python/main.py" << 'EOF'
def safe_function(user_input: str) -> str:
    """Safely return user input."""
    return f"Hello, {user_input}!"

if __name__ == "__main__":
    result = safe_function("World")
    print(result)
EOF

run_test "Clean Python code should pass" "pass" "
    cd $TEST_DIR/clean-python && \
    semgrep --config auto --json . > output.json 2>&1 && \
    [ \$(jq '.results | length' output.json) -eq 0 ]
"

# Test 2: Vulnerable Python code (SQL injection)
mkdir -p "$TEST_DIR/vuln-sql"
cat > "$TEST_DIR/vuln-sql/app.py" << 'EOF'
import sqlite3

def get_user(user_id):
    conn = sqlite3.connect('db.sqlite')
    # Vulnerable: SQL injection
    query = f"SELECT * FROM users WHERE id = {user_id}"
    cursor = conn.execute(query)
    return cursor.fetchone()
EOF

run_test "SQL injection should be detected" "fail" "
    cd $TEST_DIR/vuln-sql && \
    semgrep --config auto --json . > output.json 2>&1 && \
    [ \$(jq '.results | length' output.json) -eq 0 ]
"

# Test 3: Vulnerable Python code (Command injection)
mkdir -p "$TEST_DIR/vuln-cmd"
cat > "$TEST_DIR/vuln-cmd/shell.py" << 'EOF'
import os

def run_command(user_input):
    # Vulnerable: Command injection
    os.system("ls " + user_input)
EOF

run_test "Command injection should be detected" "fail" "
    cd $TEST_DIR/vuln-cmd && \
    semgrep --config auto --json . > output.json 2>&1 && \
    [ \$(jq '.results | length' output.json) -eq 0 ]
"

# Test 4: Clean JavaScript code
mkdir -p "$TEST_DIR/clean-js"
cat > "$TEST_DIR/clean-js/app.js" << 'EOF'
function safeGreeting(name) {
    const sanitized = name.replace(/[<>]/g, '');
    return `Hello, ${sanitized}!`;
}

module.exports = { safeGreeting };
EOF

run_test "Clean JavaScript code should pass" "pass" "
    cd $TEST_DIR/clean-js && \
    semgrep --config auto --json . > output.json 2>&1 && \
    [ \$(jq '.results | length' output.json) -eq 0 ]
"

# Test 5: Vulnerable JavaScript (XSS)
mkdir -p "$TEST_DIR/vuln-xss"
cat > "$TEST_DIR/vuln-xss/web.js" << 'EOF'
function displayUser(name) {
    // Vulnerable: XSS
    document.innerHTML = name;
}
EOF

run_test "XSS vulnerability should be detected" "fail" "
    cd $TEST_DIR/vuln-xss && \
    semgrep --config auto --json . > output.json 2>&1 && \
    [ \$(jq '.results | length' output.json) -eq 0 ]
"

# Test 6: Multiple files
mkdir -p "$TEST_DIR/multi-file"
cat > "$TEST_DIR/multi-file/safe.py" << 'EOF'
def safe_func():
    return "ok"
EOF

cat > "$TEST_DIR/multi-file/unsafe.py" << 'EOF'
import pickle
def load_data(data):
    # Vulnerable: Unsafe deserialization
    return pickle.loads(data)
EOF

run_test "Should detect vulnerability in multi-file project" "fail" "
    cd $TEST_DIR/multi-file && \
    semgrep --config auto --json . > output.json 2>&1 && \
    [ \$(jq '.results | length' output.json) -eq 0 ]
"

# Summary
echo ""
echo "================================"
echo "Test Summary"
echo "================================"
echo "Tests run:    $TESTS_RUN"
echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✅ All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}❌ Some tests failed${NC}"
    exit 1
fi
