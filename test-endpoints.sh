#!/bin/bash

# BMI Chat Endpoint Testing Script
# Tests all API endpoints to ensure they work correctly

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
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

# Configuration
BASE_URL="http://localhost:3006"
API_URL="$BASE_URL/api/v1"

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0

# Function to run a test
run_test() {
    local test_name="$1"
    local method="$2"
    local endpoint="$3"
    local data="$4"
    local expected_status="$5"
    
    print_status "Testing: $test_name"
    
    # Build curl command
    local curl_cmd="curl -s -w '%{http_code}' -o /tmp/response.json"
    
    if [ "$method" = "GET" ]; then
        curl_cmd="$curl_cmd -X GET"
    elif [ "$method" = "POST" ]; then
        curl_cmd="$curl_cmd -X POST"
    elif [ "$method" = "PUT" ]; then
        curl_cmd="$curl_cmd -X PUT"
    elif [ "$method" = "DELETE" ]; then
        curl_cmd="$curl_cmd -X DELETE"
    fi
    
    if [ -n "$data" ]; then
        curl_cmd="$curl_cmd -H 'Content-Type: application/json' -d '$data'"
    fi
    
    curl_cmd="$curl_cmd '$endpoint'"
    
    # Run the test
    local response=$(eval $curl_cmd)
    local status_code=$(echo $response | tail -c 4)
    local response_body=$(cat /tmp/response.json 2>/dev/null || echo "")
    
    # Check if test passed
    if [ "$status_code" = "$expected_status" ]; then
        print_success "$test_name - Status: $status_code"
        ((TESTS_PASSED++))
    else
        print_error "$test_name - Expected: $expected_status, Got: $status_code"
        print_error "Response: $response_body"
        ((TESTS_FAILED++))
    fi
    
    echo ""
}

# Wait for backend to be ready
print_status "Waiting for backend to be ready..."
for i in {1..30}; do
    if curl -f "$BASE_URL/health" > /dev/null 2>&1; then
        print_success "Backend is ready!"
        break
    fi
    if [ $i -eq 30 ]; then
        print_error "Backend is not responding after 30 seconds"
        exit 1
    fi
    sleep 1
done

print_status "Starting endpoint tests..."
echo ""

# Test 1: Health Check
run_test "Health Check" "GET" "$BASE_URL/health" "" "200"

# Test 2: API Root
run_test "API Root" "GET" "$API_URL/" "" "200"

# Test 3: Chat Endpoints
run_test "Chat History" "GET" "$API_URL/chat/history" "" "200"
run_test "Chat Send Message" "POST" "$API_URL/chat/send" '{"message":"Hello, how are you?"}' "200"

# Test 4: Document Endpoints
run_test "Documents List" "GET" "$API_URL/documents" "" "200"
run_test "Documents Upload Info" "GET" "$API_URL/documents/upload-info" "" "200"

# Test 5: Search Endpoints
run_test "Search Documents" "POST" "$API_URL/search" '{"query":"test query"}' "200"

# Test 6: Widget Endpoints
run_test "Widget Config" "GET" "$API_URL/widget/config/1" "" "200"
run_test "Widget Health" "GET" "$API_URL/widget/health/1" "" "200"
run_test "Widget Chat" "POST" "$API_URL/widget/chat" '{"tenant_id":1,"session_id":"test-session","question":"Hello"}' "200"

# Test 7: Analytics Endpoints
run_test "Analytics Overview" "GET" "$API_URL/analytics/overview" "" "200"
run_test "Analytics Usage" "GET" "$API_URL/analytics/usage" "" "200"

# Test 8: Admin Endpoints (if available)
run_test "Admin Settings" "GET" "$API_URL/admin/settings" "" "200"

# Test 9: Error handling
run_test "404 Not Found" "GET" "$API_URL/nonexistent" "" "404"

# Test 10: CORS (if applicable)
run_test "CORS Preflight" "OPTIONS" "$API_URL/chat/send" "" "200"

# Summary
echo "=========================================="
print_status "Test Summary:"
echo "  Tests Passed: $TESTS_PASSED"
echo "  Tests Failed: $TESTS_FAILED"
echo "  Total Tests: $((TESTS_PASSED + TESTS_FAILED))"
echo "=========================================="

if [ $TESTS_FAILED -eq 0 ]; then
    print_success "All tests passed! 🎉"
    exit 0
else
    print_error "$TESTS_FAILED tests failed!"
    exit 1
fi 