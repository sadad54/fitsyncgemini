#!/bin/bash

API_BASE="http://127.0.0.1:8000/api/v1/auth"

echo "=== Testing Auth Endpoints ==="

# 1. First registration (should succeed with 201)
echo "1. Testing first registration..."
curl -i -X POST "$API_BASE/register" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "ami@example.com",
    "password": "Test1234!",
    "confirm_password": "Test1234!",
    "username": "amisami",
    "first_name": "Ami",
    "last_name": "Sami"
  }'

echo -e "\n\n"

# 2. Duplicate email (should return 409)
echo "2. Testing duplicate email..."
curl -i -X POST "$API_BASE/register" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "ami@example.com",
    "password": "Test1234!",
    "confirm_password": "Test1234!",
    "username": "different",
    "first_name": "Ami",
    "last_name": "Sami"
  }'

echo -e "\n\n"

# 3. Duplicate username (should return 409)
echo "3. Testing duplicate username..."
curl -i -X POST "$API_BASE/register" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "different@example.com",
    "password": "Test1234!",
    "confirm_password": "Test1234!",
    "username": "amisami",
    "first_name": "Different",
    "last_name": "User"
  }'

echo -e "\n\n"

# 4. Password mismatch (should return 422)
echo "4. Testing password mismatch..."
curl -i -X POST "$API_BASE/register" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "Test1234!",
    "confirm_password": "Different123!",
    "username": "testuser",
    "first_name": "Test",
    "last_name": "User"
  }'

echo -e "\n\n"

# 5. Login with correct credentials (should return 200 with tokens)
echo "5. Testing login..."
curl -i -X POST "$API_BASE/login" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "ami@example.com",
    "password": "Test1234!"
  }'

echo -e "\n\n"

# 6. Login with wrong password (should return 401)
echo "6. Testing login with wrong password..."
curl -i -X POST "$API_BASE/login" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "ami@example.com",
    "password": "WrongPassword!"
  }'

echo -e "\n\n"
echo "=== Test Complete ==="