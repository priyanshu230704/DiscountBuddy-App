## Restaurant Flow - Complete Journey

### Step 1: Restaurant Registration

**Endpoint**: `POST /merchant/api/users/register/`

**Request**:
```json
{
  "email": "restaurant@example.com",
  "username": "restaurantowner",
  "password": "SecurePass123!",
  "role": "merchant"
}
```

**Response** (201 Created):
```json
{
  "id": 2,
  "email": "restaurant@example.com",
  "username": "restaurantowner",
  "is_merchant": true,
  "is_customer": false,
  "profile": {
    "role": "merchant",
    "phone_number": "",
    "marketing_opt_in": true
  }
}
```

**cURL**:
```bash
curl -X POST http://127.0.0.1:8000/merchant/api/users/register/ \
  -H "Content-Type: application/json" \
  -d '{
    "email": "restaurant@example.com",
    "username": "restaurantowner",
    "password": "SecurePass123!",
    "role": "merchant"
  }'
```

---

### Step 2: Restaurant Login

**Endpoint**: `POST /merchant/api/users/token/`

**Request**:
```json
{
  "email": "restaurant@example.com",
  "password": "SecurePass123!"
}
```

**Response** (200 OK):
```json
{
  "access": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "refresh": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "username": "restaurantowner",
  "role": "merchant",
  "current_date": "2024-01-26T12:00:00Z"
}
```

**cURL**:
```bash
curl -X POST http://127.0.0.1:8000/merchant/api/users/token/ \
  -H "Content-Type: application/json" \
  -d '{
    "email": "restaurant@example.com",
    "password": "SecurePass123!"
  }'
```

---

### Step 3: Create Restaurant

**Endpoint**: `POST /merchant/api/restaurants/restaurant/manage/`

**Headers**:
```
Authorization: Bearer <merchant_access_token>
Content-Type: application/json
```

**Request**:
```json
{
  "name": "My New Restaurant",
  "slug": "my-new-restaurant",
  "description": "A wonderful restaurant serving great food",
  "city": 1,
  "address": "456 Main Street",
  "postcode": "SW1A 2BB",
  "latitude": "51.5080",
  "longitude": "-0.1280",
  "phone": "+44 20 9876 5432",
  "email": "info@mynewrestaurant.com",
  "website": "https://mynewrestaurant.com",
  "price_range": 3,
  "opening_hours": {
    "monday": {"open": "09:00", "close": "22:00"},
    "tuesday": {"open": "09:00", "close": "22:00"}
  }
}
```

**Response** (201 Created):
```json
{
  "id": 6,
  "name": "My New Restaurant",
  "slug": "my-new-restaurant",
  "description": "A wonderful restaurant serving great food",
  "city": {
    "id": 1,
    "name": "London",
    "slug": "london",
    "country": {
      "id": 1,
      "name": "United Kingdom",
      "code": "GB"
    }
  },
  "address": "456 Main Street",
  "postcode": "SW1A 2BB",
  "latitude": "51.508000",
  "longitude": "-0.128000",
  "phone": "+44 20 9876 5432",
  "email": "info@mynewrestaurant.com",
  "website": "https://mynewrestaurant.com",
  "categories": [],
  "cuisines": [],
  "price_range": 3,
  "verified": false,
  "is_featured": false,
  "opening_hours": {
    "monday": {"open": "09:00", "close": "22:00"},
    "tuesday": {"open": "09:00", "close": "22:00"}
  },
  "images": [],
  "active_deals_count": 0,
  "is_saved": false,
  "created_at": "2024-01-26T12:00:00Z"
}
```

**cURL**:
```bash
curl -X POST http://127.0.0.1:8000/merchant/api/restaurants/restaurant/manage/ \
  -H "Authorization: Bearer <merchant_access_token>" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "My New Restaurant",
    "slug": "my-new-restaurant",
    "description": "A wonderful restaurant",
    "city": 1,
    "address": "456 Main Street",
    "price_range": 3
  }'
```

---

### Step 4: Add Opening Slots

**Endpoint**: `POST /merchant/api/restaurants/restaurant/opening-slots/`

**Headers**:
```
Authorization: Bearer <merchant_access_token>
Content-Type: application/json
```

**Request** (for each day):
```json
{
  "restaurant": 6,
  "day_of_week": 0,
  "opening_time": "09:00",
  "closing_time": "22:00",
  "is_closed": false
}
```

**Response** (201 Created):
```json
{
  "id": 1,
  "day_of_week": 0,
  "day_name": "Monday",
  "opening_time": "09:00",
  "closing_time": "22:00",
  "is_closed": false
}
```

**cURL**:
```bash
curl -X POST http://127.0.0.1:8000/merchant/api/restaurants/restaurant/opening-slots/ \
  -H "Authorization: Bearer <merchant_access_token>" \
  -H "Content-Type: application/json" \
  -d '{
    "restaurant": 6,
    "day_of_week": 0,
    "opening_time": "09:00",
    "closing_time": "22:00",
    "is_closed": false
  }'
```

---

### Step 5: Add Menu Categories

**Endpoint**: `POST /merchant/api/restaurants/restaurant/menu/`

**Headers**:
```
Authorization: Bearer <merchant_access_token>
Content-Type: application/json
```

**Request**:
```json
{
  "restaurant": 6,
  "name": "Appetizers",
  "description": "Start your meal with our delicious appetizers",
  "order": 0,
  "is_active": true
}
```

**Response** (201 Created):
```json
{
  "id": 1,
  "name": "Appetizers",
  "description": "Start your meal with our delicious appetizers",
  "order": 0,
  "is_active": true,
  "items": [],
  "items_count": 0
}
```

**cURL**:
```bash
curl -X POST http://127.0.0.1:8000/merchant/api/restaurants/restaurant/menu/ \
  -H "Authorization: Bearer <merchant_access_token>" \
  -H "Content-Type: application/json" \
  -d '{
    "restaurant": 6,
    "name": "Appetizers",
    "description": "Start your meal",
    "order": 0,
    "is_active": true
  }'
```

---

### Step 6: Add Menu Items

**Note**: Menu items are added through the menu category detail endpoint or via admin. For API, you would need to extend the serializer to accept items.

**Alternative**: Use Django admin or extend the API to support nested menu items creation.

---

### Step 7: Create a Deal/Offer

**Endpoint**: `POST /merchant/api/restaurants/merchant/deals/`

**Headers**:
```
Authorization: Bearer <merchant_access_token>
Content-Type: application/json
```

**Request**:
```json
{
  "restaurant": 6,
  "title": "20% Off All Main Courses",
  "description": "Get 20% discount on all main course items",
  "deal_type": "percentage",
  "discount_percentage": 20.0,
  "minimum_spend": "30.00",
  "start_date": "2024-02-01T00:00:00Z",
  "end_date": "2024-02-28T23:59:59Z",
  "max_uses": 100,
  "max_per_user": 1,
  "terms_and_conditions": "Valid for dine-in only. Cannot be combined with other offers.",
  "is_featured": true
}
```

**Response** (201 Created):
```json
{
  "id": 14,
  "restaurant": {
    "id": 6,
    "name": "My New Restaurant",
    "slug": "my-new-restaurant",
    "city_name": "London",
    "country_name": "United Kingdom",
    "latitude": "51.508000",
    "longitude": "-0.128000",
    "price_range": 3,
    "verified": false,
    "is_featured": false,
    "primary_image": null,
    "active_deals_count": 1
  },
  "title": "20% Off All Main Courses",
  "description": "Get 20% discount on all main course items",
  "deal_type": "percentage",
  "discount_percentage": 20.0,
  "discount_amount": null,
  "minimum_spend": "30.00",
  "terms_and_conditions": "Valid for dine-in only. Cannot be combined with other offers.",
  "start_date": "2024-02-01T00:00:00Z",
  "end_date": "2024-02-28T23:59:59Z",
  "max_uses": 100,
  "used_count": 0,
  "max_per_user": 1,
  "is_featured": true,
  "images": [],
  "is_active": true,
  "can_use": false,
  "is_saved": false,
  "created_at": "2024-01-26T12:00:00Z"
}
```

**cURL**:
```bash
curl -X POST http://127.0.0.1:8000/merchant/api/restaurants/merchant/deals/ \
  -H "Authorization: Bearer <merchant_access_token>" \
  -H "Content-Type: application/json" \
  -d '{
    "restaurant": 6,
    "title": "20% Off All Main Courses",
    "description": "Get 20% discount",
    "deal_type": "percentage",
    "discount_percentage": 20.0,
    "minimum_spend": "30.00",
    "start_date": "2024-02-01T00:00:00Z",
    "end_date": "2024-02-28T23:59:59Z",
    "max_uses": 100,
    "max_per_user": 1
  }'
```

---

### Step 8: View Restaurant Reviews

**Endpoint**: `GET /merchant/api/restaurants/restaurant/reviews/`

**Headers**:
```
Authorization: Bearer <merchant_access_token>
```

**Response** (200 OK):
```json
[
  {
    "id": 1,
    "user": 1,
    "user_email": "john.doe@example.com",
    "user_name": "johndoe",
    "restaurant": 6,
    "rating": 5,
    "comment": "Excellent food and service!",
    "is_verified": false,
    "created_at": "2024-01-26T12:00:00Z"
  }
]
```

**cURL**:
```bash
curl -X GET http://127.0.0.1:8000/merchant/api/restaurants/restaurant/reviews/ \
  -H "Authorization: Bearer <merchant_access_token>"
```

---

### Step 9: View Restaurant Bookings

**Endpoint**: `GET /merchant/api/restaurants/restaurant/bookings/`

**Headers**:
```
Authorization: Bearer <merchant_access_token>
```

**Query Parameters** (optional):
- `status` - Filter by status (pending, confirmed, cancelled, completed)
- `ordering` - Order by (booking_date, created_at)

**Response** (200 OK):
```json
[
  {
    "id": 1,
    "restaurant": 6,
    "restaurant_name": "My New Restaurant",
    "restaurant_slug": "my-new-restaurant",
    "booking_date": "2024-02-15T19:00:00Z",
    "number_of_guests": 4,
    "status": "pending",
    "special_requests": "Window seat please",
    "contact_phone": "+44 7123456789",
    "contact_name": "John Doe",
    "can_cancel": true,
    "created_at": "2024-01-26T12:00:00Z"
  }
]
```

**cURL**:
```bash
curl -X GET "http://127.0.0.1:8000/merchant/api/restaurants/restaurant/bookings/?status=pending" \
  -H "Authorization: Bearer <merchant_access_token>"
```

---




### Restaurant Management Endpoints (Merchant)

| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/merchant/api/restaurants/restaurant/manage/` | List owned restaurants | Yes (Merchant) |
| POST | `/merchant/api/restaurants/restaurant/manage/` | Create restaurant | Yes (Merchant) |
| PUT | `/merchant/api/restaurants/restaurant/manage/{id}/` | Update restaurant | Yes (Merchant) |
| DELETE | `/merchant/api/restaurants/restaurant/manage/{id}/` | Delete restaurant | Yes (Merchant) |
| GET | `/merchant/api/restaurants/restaurant/menu/` | List menu categories | Yes (Merchant) |
| POST | `/merchant/api/restaurants/restaurant/menu/` | Create menu category | Yes (Merchant) |
| GET | `/merchant/api/restaurants/restaurant/opening-slots/` | List opening slots | Yes (Merchant) |
| POST | `/merchant/api/restaurants/restaurant/opening-slots/` | Create opening slot | Yes (Merchant) |
| GET | `/merchant/api/restaurants/merchant/deals/` | List restaurant deals | Yes (Merchant) |
| POST | `/merchant/api/restaurants/merchant/deals/` | Create deal | Yes (Merchant) |
| GET | `/merchant/api/restaurants/restaurant/reviews/` | View restaurant reviews | Yes (Merchant) |
| GET | `/merchant/api/restaurants/restaurant/bookings/` | View restaurant bookings | Yes (Merchant) |