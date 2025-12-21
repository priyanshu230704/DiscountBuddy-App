# Discount Buddy API Documentation

## Base URL
```
http://your-domain.com/api
```

## Authentication

The API uses JWT (JSON Web Token) authentication. Most endpoints require authentication except for registration, login, and public voucher listing.

### How to Authenticate

1. **Login** using `/api/users/login/` to get access and refresh tokens
2. Include the access token in the Authorization header for protected endpoints:
   ```
   Authorization: Bearer <access_token>
   ```

### Token Details
- **Access Token Lifetime**: 30 minutes
- **Refresh Token Lifetime**: 7 days
- **Token Type**: Bearer

---

## Endpoints

### Core

#### Health Check
Check if the API is running.

**Endpoint:** `GET /api/core/health/`

**Authentication:** Not required

**Response:**
```json
{
  "status": "ok"
}
```

**Example:**
```bash
curl -X GET http://your-domain.com/api/core/health/
```

---

### Users

#### Register
Create a new user account.

**Endpoint:** `POST /api/users/register/`

**Authentication:** Not required

**Request Body:**
```json
{
  "email": "user@example.com",
  "username": "johndoe",
  "password": "securepassword123",
  "role": "customer"  // Options: "customer" or "merchant"
}
```

**Response:** `201 Created`
```json
{
  "id": 1,
  "email": "user@example.com",
  "username": "johndoe",
  "role": "customer"
}
```

**Example:**
```bash
curl -X POST http://your-domain.com/api/users/register/ \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "username": "johndoe",
    "password": "securepassword123",
    "role": "customer"
  }'
```

**Error Responses:**
- `400 Bad Request`: Validation errors (e.g., email already exists, invalid data)
- `400 Bad Request`: Invalid role (must be "customer" or "merchant")

---

#### Login
Authenticate and get JWT tokens.

**Endpoint:** `POST /api/users/login/`

**Authentication:** Not required

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "securepassword123"
}
```

**Response:** `200 OK`
```json
{
  "access": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
  "refresh": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
  "user": {
    "id": 1,
    "email": "user@example.com",
    "username": "johndoe",
    "is_merchant": false,
    "is_customer": true,
    "profile": {
      "role": "customer",
      "phone_number": "",
      "marketing_opt_in": true
    }
  }
}
```

**Example:**
```bash
curl -X POST http://your-domain.com/api/users/login/ \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "securepassword123"
  }'
```

**Error Responses:**
- `401 Unauthorized`: Invalid credentials

---

#### Get Current User
Get the authenticated user's profile information.

**Endpoint:** `GET /api/users/me/`

**Authentication:** Required (Bearer token)

**Response:** `200 OK`
```json
{
  "id": 1,
  "email": "user@example.com",
  "username": "johndoe",
  "is_merchant": false,
  "is_customer": true,
  "profile": {
    "role": "customer",
    "phone_number": "",
    "marketing_opt_in": true
  }
}
```

**Example:**
```bash
curl -X GET http://your-domain.com/api/users/me/ \
  -H "Authorization: Bearer <access_token>"
```

**Error Responses:**
- `401 Unauthorized`: Missing or invalid token

---

#### Refresh Token
Get a new access token using a refresh token.

**Endpoint:** `POST /api/users/token/refresh/`

**Authentication:** Not required (but requires refresh token)

**Request Body:**
```json
{
  "refresh": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9..."
}
```

**Response:** `200 OK`
```json
{
  "access": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9..."
}
```

**Example:**
```bash
curl -X POST http://your-domain.com/api/users/token/refresh/ \
  -H "Content-Type: application/json" \
  -d '{
    "refresh": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9..."
  }'
```

**Error Responses:**
- `401 Unauthorized`: Invalid or expired refresh token

---

### Vouchers

#### List Vouchers
Get a paginated list of active vouchers from verified merchants.

**Endpoint:** `GET /api/vouchers/`

**Authentication:** Not required

**Query Parameters:**
- `search` (optional): Search in code, title, or merchant name
- `ordering` (optional): Order by field (e.g., `start_date`, `-end_date`, `sale_price`, `-discount_percent`)
  - Prefix with `-` for descending order
- `page` (optional): Page number (default: 1)
- `page_size` (optional): Items per page (default: 20)

**Response:** `200 OK`
```json
{
  "count": 100,
  "next": "http://your-domain.com/api/vouchers/?page=2",
  "previous": null,
  "results": [
    {
      "id": 1,
      "code": "SAVE20",
      "title": "20% Off Summer Sale",
      "description": "Get 20% off on all summer items",
      "merchant": {
        "id": 1,
        "name": "Fashion Store",
        "verified": true
      },
      "category": {
        "id": 1,
        "name": "Fashion",
        "slug": "fashion"
      },
      "discount_percent": 20.0,
      "original_price": "100.00",
      "sale_price": "80.00",
      "start_date": "2024-01-01T00:00:00Z",
      "end_date": "2024-12-31T23:59:59Z",
      "total_quantity": 1000,
      "sold_quantity": 250,
      "max_per_user": 5,
      "remaining_quantity": 750
    }
  ]
}
```

**Example:**
```bash
# Get all vouchers
curl -X GET http://your-domain.com/api/vouchers/

# Search vouchers
curl -X GET "http://your-domain.com/api/vouchers/?search=summer"

# Order by sale price (ascending)
curl -X GET "http://your-domain.com/api/vouchers/?ordering=sale_price"

# Order by discount percent (descending)
curl -X GET "http://your-domain.com/api/vouchers/?ordering=-discount_percent"
```

---

#### Get Merchant Vouchers
Get all vouchers created by the authenticated merchant.

**Endpoint:** `GET /api/vouchers/me/`

**Authentication:** Required (Bearer token, Merchant role)

**Query Parameters:**
- `page` (optional): Page number (default: 1)
- `page_size` (optional): Items per page (default: 20)

**Response:** `200 OK`
```json
{
  "count": 10,
  "next": null,
  "previous": null,
  "results": [
    {
      "id": 1,
      "code": "SAVE20",
      "title": "20% Off Summer Sale",
      "description": "Get 20% off on all summer items",
      "merchant": {
        "id": 1,
        "name": "Fashion Store",
        "verified": true
      },
      "category": {
        "id": 1,
        "name": "Fashion",
        "slug": "fashion"
      },
      "discount_percent": 20.0,
      "original_price": "100.00",
      "sale_price": "80.00",
      "start_date": "2024-01-01T00:00:00Z",
      "end_date": "2024-12-31T23:59:59Z",
      "total_quantity": 1000,
      "sold_quantity": 250,
      "max_per_user": 5,
      "remaining_quantity": 750
    }
  ]
}
```

**Example:**
```bash
curl -X GET http://your-domain.com/api/vouchers/me/ \
  -H "Authorization: Bearer <access_token>"
```

**Error Responses:**
- `401 Unauthorized`: Missing or invalid token
- `403 Forbidden`: User is not a merchant

---

#### Create Voucher
Create a new voucher (Merchant only).

**Endpoint:** `POST /api/vouchers/me/`

**Authentication:** Required (Bearer token, Merchant role)

**Request Body:**
```json
{
  "code": "SAVE20",
  "title": "20% Off Summer Sale",
  "description": "Get 20% off on all summer items",
  "category": 1,  // Category ID (optional)
  "discount_percent": 20.0,
  "original_price": "100.00",
  "sale_price": "80.00",
  "start_date": "2024-01-01T00:00:00Z",
  "end_date": "2024-12-31T23:59:59Z",
  "total_quantity": 1000,
  "max_per_user": 5
}
```

**Response:** `201 Created`
```json
{
  "id": 1,
  "code": "SAVE20",
  "title": "20% Off Summer Sale",
  "description": "Get 20% off on all summer items",
  "merchant": {
    "id": 1,
    "name": "Fashion Store",
    "verified": true
  },
  "category": {
    "id": 1,
    "name": "Fashion",
    "slug": "fashion"
  },
  "discount_percent": 20.0,
  "original_price": "100.00",
  "sale_price": "80.00",
  "start_date": "2024-01-01T00:00:00Z",
  "end_date": "2024-12-31T23:59:59Z",
  "total_quantity": 1000,
  "sold_quantity": 0,
  "max_per_user": 5,
  "remaining_quantity": 1000
}
```

**Example:**
```bash
curl -X POST http://your-domain.com/api/vouchers/me/ \
  -H "Authorization: Bearer <access_token>" \
  -H "Content-Type: application/json" \
  -d '{
    "code": "SAVE20",
    "title": "20% Off Summer Sale",
    "description": "Get 20% off on all summer items",
    "category": 1,
    "discount_percent": 20.0,
    "original_price": "100.00",
    "sale_price": "80.00",
    "start_date": "2024-01-01T00:00:00Z",
    "end_date": "2024-12-31T23:59:59Z",
    "total_quantity": 1000,
    "max_per_user": 5
  }'
```

**Error Responses:**
- `400 Bad Request`: Validation errors (e.g., duplicate code, invalid dates, invalid prices)
- `401 Unauthorized`: Missing or invalid token
- `403 Forbidden`: User is not a merchant

**Field Validations:**
- `code`: Must be unique, max 50 characters
- `discount_percent`: Must be a positive number
- `original_price` and `sale_price`: Must be positive decimal numbers
- `sale_price`: Should be less than `original_price`
- `end_date`: Must be after `start_date`
- `total_quantity`: Must be a positive integer
- `max_per_user`: Must be a positive integer (default: 5)

---

### Wallet

#### Get Wallet
Get the authenticated user's wallet information.

**Endpoint:** `GET /api/wallet/`

**Authentication:** Required (Bearer token)

**Response:** `200 OK`
```json
{
  "id": 1,
  "balance": "150.50"
}
```

**Example:**
```bash
curl -X GET http://your-domain.com/api/wallet/ \
  -H "Authorization: Bearer <access_token>"
```

**Note:** If the user doesn't have a wallet, one will be automatically created with a balance of 0.

**Error Responses:**
- `401 Unauthorized`: Missing or invalid token

---

#### Get Wallet Transactions
Get a paginated list of wallet transactions for the authenticated user.

**Endpoint:** `GET /api/wallet/transactions/`

**Authentication:** Required (Bearer token)

**Query Parameters:**
- `page` (optional): Page number (default: 1)
- `page_size` (optional): Items per page (default: 20)

**Response:** `200 OK`
```json
{
  "count": 25,
  "next": "http://your-domain.com/api/wallet/transactions/?page=2",
  "previous": null,
  "results": [
    {
      "id": 1,
      "amount": "50.00",
      "transaction_type": "credit",
      "reason": "Manual top-up",
      "created_at": "2024-01-15T10:30:00Z"
    },
    {
      "id": 2,
      "amount": "25.50",
      "transaction_type": "debit",
      "reason": "Voucher purchase",
      "created_at": "2024-01-14T15:20:00Z"
    }
  ]
}
```

**Transaction Types:**
- `credit`: Money added to wallet
- `debit`: Money deducted from wallet

**Example:**
```bash
curl -X GET http://your-domain.com/api/wallet/transactions/ \
  -H "Authorization: Bearer <access_token>"
```

**Error Responses:**
- `401 Unauthorized`: Missing or invalid token

---

#### Top Up Wallet
Add money to the authenticated user's wallet.

**Endpoint:** `POST /api/wallet/topup/`

**Authentication:** Required (Bearer token)

**Request Body:**
```json
{
  "amount": "50.00"
}
```

**Response:** `200 OK`
```json
{
  "id": 1,
  "balance": "200.50"
}
```

**Example:**
```bash
curl -X POST http://your-domain.com/api/wallet/topup/ \
  -H "Authorization: Bearer <access_token>" \
  -H "Content-Type: application/json" \
  -d '{
    "amount": "50.00"
  }'
```

**Error Responses:**
- `400 Bad Request`: Amount must be positive
- `401 Unauthorized`: Missing or invalid token

**Note:** If the user doesn't have a wallet, one will be automatically created.

---

## Error Responses

All error responses follow a consistent format:

### 400 Bad Request
```json
{
  "field_name": ["Error message"],
  "detail": "General error message"
}
```

### 401 Unauthorized
```json
{
  "detail": "Authentication credentials were not provided."
}
```
or
```json
{
  "detail": "Given token not valid for any token type"
}
```

### 403 Forbidden
```json
{
  "detail": "You do not have permission to perform this action."
}
```

### 404 Not Found
```json
{
  "detail": "Not found."
}
```

### 500 Internal Server Error
```json
{
  "detail": "A server error occurred."
}
```

---

## Pagination

List endpoints use pagination with the following structure:

**Response Format:**
```json
{
  "count": 100,
  "next": "http://your-domain.com/api/endpoint/?page=2",
  "previous": "http://your-domain.com/api/endpoint/?page=1",
  "results": [...]
}
```

**Query Parameters:**
- `page`: Page number (default: 1)
- `page_size`: Items per page (default: 20, max: 100)

---

## Data Types

### Dates and Times
All datetime fields are in ISO 8601 format (UTC):
```
2024-01-15T10:30:00Z
```

### Decimal Numbers
All monetary values are returned as strings with 2 decimal places:
```
"100.50"
```

### Boolean
Standard JSON boolean values:
```json
true
false
```

---

## User Roles

The system supports three user roles:

1. **customer**: Regular users who can browse and purchase vouchers
2. **merchant**: Users who can create and manage vouchers
3. **admin**: System administrators (not exposed via API)

When registering, users can choose between `customer` and `merchant` roles.

---

## Flutter Integration Tips

### 1. HTTP Client Setup
Use `http` or `dio` package for making API calls:

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

final baseUrl = 'http://your-domain.com/api';
```

### 2. Token Storage
Store JWT tokens securely using `flutter_secure_storage`:

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final storage = FlutterSecureStorage();
await storage.write(key: 'access_token', value: accessToken);
await storage.write(key: 'refresh_token', value: refreshToken);
```

### 3. Authentication Header
Include the token in all authenticated requests:

```dart
final token = await storage.read(key: 'access_token');
final headers = {
  'Authorization': 'Bearer $token',
  'Content-Type': 'application/json',
};
```

### 4. Token Refresh
Implement automatic token refresh when access token expires:

```dart
Future<String?> refreshAccessToken() async {
  final refreshToken = await storage.read(key: 'refresh_token');
  final response = await http.post(
    Uri.parse('$baseUrl/users/token/refresh/'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'refresh': refreshToken}),
  );
  
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    await storage.write(key: 'access_token', value: data['access']);
    return data['access'];
  }
  return null;
}
```

### 5. Error Handling
Handle different HTTP status codes appropriately:

```dart
if (response.statusCode == 401) {
  // Try to refresh token
  final newToken = await refreshAccessToken();
  if (newToken != null) {
    // Retry the request
  } else {
    // Redirect to login
  }
} else if (response.statusCode >= 400) {
  final error = jsonDecode(response.body);
  // Show error message to user
}
```

### 6. Pagination
Handle paginated responses:

```dart
class PaginatedResponse<T> {
  final int count;
  final String? next;
  final String? previous;
  final List<T> results;
  
  PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJson,
  ) : count = json['count'],
       next = json['next'],
       previous = json['previous'],
       results = (json['results'] as List).map((item) => fromJson(item)).toList();
}
```

---

## Testing

You can test the API using:
- **Swagger UI**: `http://your-domain.com/api/docs/swagger/`
- **ReDoc**: `http://your-domain.com/api/docs/redoc/`
- **Postman/Insomnia**: Import the endpoints using the examples above
- **cURL**: Use the provided curl examples

---

## Support

For issues or questions, please contact the development team.

---

**Last Updated:** January 2024
**API Version:** v1
