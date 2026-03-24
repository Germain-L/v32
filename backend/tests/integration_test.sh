#!/bin/bash
# Integration test for v32 sync API
# Simulates what the Flutter app does

API_KEY="v32_sk_d7f3a9c2e8b1f4d6a5c3e9f0b2d8a7c1"
BASE_URL="https://v32.germainleignel.com"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

pass() { echo -e "${GREEN}✓ $1${NC}"; }
fail() { echo -e "${RED}✗ $1${NC}"; exit 1; }
info() { echo -e "${YELLOW}→ $1${NC}"; }

echo "=== v32 API Integration Tests ==="
echo ""

# Test 1: Health check
info "Test 1: Health check (no auth required)"
RESPONSE=$(curl -s -w "\n%{http_code}" $BASE_URL/health)
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | head -n-1)

if [ "$HTTP_CODE" = "200" ]; then
    pass "Health check returned 200"
    echo "  Body: $BODY"
else
    fail "Health check failed with $HTTP_CODE"
fi

# Test 2: Stats without auth (should fail)
info "Test 2: Stats without API key (should fail)"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" $BASE_URL/stats)
if [ "$HTTP_CODE" = "401" ]; then
    pass "Correctly rejected without API key"
else
    fail "Expected 401, got $HTTP_CODE"
fi

# Test 3: Stats with wrong API key (should fail)
info "Test 3: Stats with wrong API key (should fail)"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -H "X-API-Key: wrong_key" $BASE_URL/stats)
if [ "$HTTP_CODE" = "401" ]; then
    pass "Correctly rejected wrong API key"
else
    fail "Expected 401, got $HTTP_CODE"
fi

# Test 4: Create breakfast meal
info "Test 4: Create breakfast meal"
TIMESTAMP=$(($(date -d "2026-03-24 07:00:00" +%s) * 1000))
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST \
    -H "X-API-Key: $API_KEY" \
    -H "Content-Type: application/json" \
    -d "{\"slot\":\"breakfast\",\"date\":$TIMESTAMP,\"description\":\"Test breakfast from integration test\"}" \
    $BASE_URL/meals)
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | head -n-1)

if [ "$HTTP_CODE" = "201" ] || [ "$HTTP_CODE" = "200" ]; then
    MEAL_ID=$(echo "$BODY" | jq -r '.id')
    pass "Breakfast created with ID: $MEAL_ID"
    echo "  Body: $BODY"
else
    fail "Create meal failed with $HTTP_CODE: $BODY"
fi

# Test 5: Get meals for date
info "Test 5: Get meals for 2026-03-24"
RESPONSE=$(curl -s -w "\n%{http_code}" \
    -H "X-API-Key: $API_KEY" \
    "$BASE_URL/meals?date=2026-03-24")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | head -n-1)

if [ "$HTTP_CODE" = "200" ]; then
    COUNT=$(echo "$BODY" | jq 'length')
    pass "Got $COUNT meals for 2026-03-24"
    echo "  Meals: $(echo "$BODY" | jq -r '.[].slot' | tr '\n' ' ')"
else
    fail "Get meals failed with $HTTP_CODE"
fi

# Test 6: Get stats
info "Test 6: Get stats"
RESPONSE=$(curl -s -w "\n%{http_code}" \
    -H "X-API-Key: $API_KEY" \
    $BASE_URL/stats)
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | head -n-1)

if [ "$HTTP_CODE" = "200" ]; then
    TOTAL=$(echo "$BODY" | jq -r '.totalMeals')
    STREAK=$(echo "$BODY" | jq -r '.currentStreak')
    pass "Stats: $TOTAL meals, $STREAK day streak"
else
    fail "Get stats failed with $HTTP_CODE"
fi

# Test 7: Create all 4 meals (simulating a day)
info "Test 7: Create all 4 meal slots"
for SLOT in breakfast lunch afternoonSnack dinner; do
    case $SLOT in
        breakfast) TIME="07:00:00" ;;
        lunch) TIME="12:00:00" ;;
        afternoonSnack) TIME="16:00:00" ;;
        dinner) TIME="19:00:00" ;;
    esac
    TIMESTAMP=$(($(date -d "2026-03-25 $TIME" +%s) * 1000))
    
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST \
        -H "X-API-Key: $API_KEY" \
        -H "Content-Type: application/json" \
        -d "{\"slot\":\"$SLOT\",\"date\":$TIMESTAMP,\"description\":\"Test $SLOT\"}" \
        $BASE_URL/meals)
    
    if [ "$HTTP_CODE" = "201" ] || [ "$HTTP_CODE" = "200" ]; then
        pass "  Created $SLOT"
    else
        fail "  Failed to create $SLOT (HTTP $HTTP_CODE)"
    fi
done

# Test 8: Verify all meals for 2026-03-25
info "Test 8: Verify 4 meals logged for 2026-03-25"
RESPONSE=$(curl -s -H "X-API-Key: $API_KEY" "$BASE_URL/meals?date=2026-03-25")
COUNT=$(echo "$RESPONSE" | jq 'length')
if [ "$COUNT" = "4" ]; then
    pass "All 4 meals logged correctly"
else
    fail "Expected 4 meals, got $COUNT"
fi

# Test 9: Image upload
info "Test 9: Upload image for meal"
# Get the first meal ID from 2026-03-25
MEAL_ID=$(curl -s -H "X-API-Key: $API_KEY" "$BASE_URL/meals?date=2026-03-25" | jq -r '.[0].id')

# Create a test image
echo "FAKE IMAGE DATA FOR INTEGRATION TEST" > /tmp/test_meal_image.jpg

RESPONSE=$(curl -s -w "\n%{http_code}" -X POST \
    -H "X-API-Key: $API_KEY" \
    -F "mealId=$MEAL_ID" \
    -F "image=@/tmp/test_meal_image.jpg" \
    $BASE_URL/upload)
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | head -n-1)

if [ "$HTTP_CODE" = "201" ] || [ "$HTTP_CODE" = "200" ]; then
    IMAGE_URL=$(echo "$BODY" | jq -r '.url')
    pass "Image uploaded: $IMAGE_URL"
else
    fail "Image upload failed with $HTTP_CODE: $BODY"
fi

# Test 10: Verify image is accessible
info "Test 10: Verify image is accessible (no auth needed)"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL$IMAGE_URL")
if [ "$HTTP_CODE" = "200" ]; then
    pass "Image accessible without auth"
else
    fail "Image not accessible (HTTP $HTTP_CODE)"
fi

# Test 11: Day rating
info "Test 11: Create day rating"
TIMESTAMP=$(($(date -d "2026-03-25 00:00:00" +%s) * 1000))
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST \
    -H "X-API-Key: $API_KEY" \
    -H "Content-Type: application/json" \
    -d "{\"date\":$TIMESTAMP,\"score\":4}" \
    $BASE_URL/rating)
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)

if [ "$HTTP_CODE" = "200" ]; then
    pass "Day rating saved"
else
    fail "Rating failed with $HTTP_CODE"
fi

# Test 12: Invalid slot (should fail)
info "Test 12: Create meal with invalid slot (should fail)"
TIMESTAMP=$(($(date +%s) * 1000))
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST \
    -H "X-API-Key: $API_KEY" \
    -H "Content-Type: application/json" \
    -d "{\"slot\":\"invalid\",\"date\":$TIMESTAMP,\"description\":\"Test\"}" \
    $BASE_URL/meals)
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)

if [ "$HTTP_CODE" = "400" ]; then
    pass "Correctly rejected invalid slot"
else
    fail "Expected 400, got $HTTP_CODE"
fi

# Cleanup
rm -f /tmp/test_meal_image.jpg

echo ""
echo -e "${GREEN}=== All Integration Tests Passed ===${NC}"
