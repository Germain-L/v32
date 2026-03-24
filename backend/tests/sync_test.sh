#!/bin/bash
# Integration tests for sync API
# Requires a running backend server

set -e

BASE_URL="${BASE_URL:-http://localhost:8080}"
API_KEY="${API_KEY:-test-key}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

PASS=0
FAIL=0

# Helper functions
api_call() {
    local method=$1
    local endpoint=$2
    local data=$3
    local expected_status=$4
    
    if [ -z "$data" ]; then
        response=$(curl -s -w "\n%{http_code}" -X $method \
            -H "X-API-Key: $API_KEY" \
            -H "Content-Type: application/json" \
            "${BASE_URL}${endpoint}")
    else
        response=$(curl -s -w "\n%{http_code}" -X $method \
            -H "X-API-Key: $API_KEY" \
            -H "Content-Type: application/json" \
            -d "$data" \
            "${BASE_URL}${endpoint}")
    fi
    
    status=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    if [ "$status" = "$expected_status" ]; then
        echo "$body"
        return 0
    else
        echo "Expected status $expected_status, got $status" >&2
        echo "Response: $body" >&2
        return 1
    fi
}

test_pass() {
    echo -e "${GREEN}✓${NC} $1"
    PASS=$((PASS + 1))
}

test_fail() {
    echo -e "${RED}✗${NC} $1"
    FAIL=$((FAIL + 1))
}

# Create a test meal
create_meal() {
    local slot=$1
    local date=$2
    api_call POST "/meals" "{\"slot\":\"$slot\",\"date\":$date}" 201
}

# Get current timestamp in millis
now_millis() {
    echo $(($(date +%s) * 1000))
}

echo "=========================================="
echo "   v32 Backend Sync Integration Tests"
echo "=========================================="
echo ""

# Test 1: Create a meal
echo -e "${YELLOW}Test 1: Create meal${NC}"
meal1=$(create_meal "breakfast" $(now_millis))
if [ $? -eq 0 ]; then
    meal1_id=$(echo $meal1 | jq -r '.id')
    test_pass "Created meal with ID: $meal1_id"
else
    test_fail "Failed to create meal"
    exit 1
fi

# Test 2: Get meal by ID
echo -e "${YELLOW}Test 2: Get meal by ID${NC}"
result=$(api_call GET "/meals/$meal1_id" "" 200)
if [ $? -eq 0 ]; then
    fetched_id=$(echo $result | jq -r '.id')
    if [ "$fetched_id" = "$meal1_id" ]; then
        test_pass "Retrieved meal by ID: $meal1_id"
    else
        test_fail "ID mismatch"
    fi
else
    test_fail "Failed to get meal by ID"
fi

# Test 3: Update meal
echo -e "${YELLOW}Test 3: Update meal${NC}"
update_data="{\"slot\":\"lunch\",\"date\":$(now_millis),\"description\":\"Updated meal\"}"
result=$(api_call PUT "/meals/$meal1_id" "$update_data" 200)
if [ $? -eq 0 ]; then
    updated_slot=$(echo $result | jq -r '.slot')
    updated_desc=$(echo $result | jq -r '.description')
    updated_at=$(echo $result | jq -r '.updatedAt')
    if [ "$updated_slot" = "lunch" ] && [ "$updated_desc" = "Updated meal" ] && [ "$updated_at" != "null" ]; then
        test_pass "Updated meal successfully"
    else
        test_fail "Update didn't apply correctly"
    fi
else
    test_fail "Failed to update meal"
fi

# Test 4: Get meals since timestamp (before the update)
echo -e "${YELLOW}Test 4: Get meals since timestamp${NC}"
# Use a timestamp from 1 minute ago
old_timestamp=$(($(now_millis) - 60000))
result=$(api_call GET "/meals/since?timestamp=$old_timestamp" "" 200)
if [ $? -eq 0 ]; then
    meals_count=$(echo $result | jq '.meals | length')
    deleted_count=$(echo $result | jq '.deletedIds | length')
    if [ "$meals_count" -ge 1 ]; then
        test_pass "Got $meals_count meals since timestamp, $deleted_count deleted"
    else
        test_fail "Expected at least 1 meal"
    fi
else
    test_fail "Failed to get meals since timestamp"
fi

# Test 5: Create another meal for bulk test
echo -e "${YELLOW}Test 5: Create second meal${NC}"
meal2=$(create_meal "dinner" $(now_millis))
if [ $? -eq 0 ]; then
    meal2_id=$(echo $meal2 | jq -r '.id')
    test_pass "Created second meal with ID: $meal2_id"
else
    test_fail "Failed to create second meal"
fi

# Test 6: Soft delete meal
echo -e "${YELLOW}Test 6: Soft delete meal${NC}"
result=$(api_call DELETE "/meals/$meal2_id" "" 204)
if [ $? -eq 0 ]; then
    test_pass "Soft deleted meal: $meal2_id"
else
    test_fail "Failed to soft delete meal"
fi

# Test 7: Verify deleted meal returns 404
echo -e "${YELLOW}Test 7: Verify deleted meal returns 404${NC}"
result=$(api_call GET "/meals/$meal2_id" "" 404)
if [ $? -eq 0 ]; then
    test_pass "Deleted meal correctly returns 404"
else
    test_fail "Deleted meal should return 404"
fi

# Test 8: Check deleted meal appears in /meals/since
echo -e "${YELLOW}Test 8: Verify deleted meal in sync${NC}"
old_timestamp=$(($(now_millis) - 60000))
result=$(api_call GET "/meals/since?timestamp=$old_timestamp" "" 200)
if [ $? -eq 0 ]; then
    deleted_ids=$(echo $result | jq -r '.deletedIds')
    if echo "$deleted_ids" | grep -q "$meal2_id"; then
        test_pass "Deleted meal ID appears in deletedIds"
    else
        test_fail "Deleted meal ID not in deletedIds"
    fi
else
    test_fail "Failed to get meals since"
fi

# Test 9: Bulk create meals
echo -e "${YELLOW}Test 9: Bulk create meals${NC}"
bulk_data="[
    {\"slot\":\"breakfast\",\"date\":$(now_millis),\"description\":\"Bulk meal 1\"},
    {\"slot\":\"lunch\",\"date\":$(now_millis),\"description\":\"Bulk meal 2\"}
]"
result=$(api_call POST "/meals/bulk" "$bulk_data" 201)
if [ $? -eq 0 ]; then
    bulk_count=$(echo $result | jq 'length')
    if [ "$bulk_count" = "2" ]; then
        test_pass "Bulk created $bulk_count meals"
    else
        test_fail "Expected 2 bulk meals, got $bulk_count"
    fi
else
    test_fail "Failed to bulk create meals"
fi

# Test 10: Bulk with server_id (upsert behavior)
echo -e "${YELLOW}Test 10: Bulk with server_id${NC}"
# First create a meal with server_id
bulk_with_server="[{\"slot\":\"dinner\",\"date\":$(now_millis),\"description\":\"Server meal\",\"serverId\":99999}]"
result=$(api_call POST "/meals/bulk" "$bulk_with_server" 201)
if [ $? -eq 0 ]; then
    server_meal_id=$(echo $result | jq -r '.[0].id')
    test_pass "Created meal with server_id: id=$server_meal_id"
else
    test_fail "Failed to create meal with server_id"
fi

# Test 11: Update via bulk with same server_id
echo -e "${YELLOW}Test 11: Bulk update with server_id${NC}"
bulk_update="[{\"slot\":\"afternoonSnack\",\"date\":$(now_millis),\"description\":\"Updated server meal\",\"serverId\":99999}]"
result=$(api_call POST "/meals/bulk" "$bulk_update" 201)
if [ $? -eq 0 ]; then
    updated_id=$(echo $result | jq -r '.[0].id')
    if [ "$updated_id" = "$server_meal_id" ]; then
        test_pass "Bulk update preserved ID: $updated_id"
    else
        test_fail "Bulk update changed ID"
    fi
else
    test_fail "Failed to bulk update with server_id"
fi

# Summary
echo ""
echo "=========================================="
echo "              Test Summary"
echo "=========================================="
echo -e "${GREEN}Passed: $PASS${NC}"
echo -e "${RED}Failed: $FAIL${NC}"
echo ""

if [ $FAIL -eq 0 ]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed.${NC}"
    exit 1
fi
