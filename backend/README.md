# v32 Meal Sync Backend

A Go HTTP backend for syncing meal data from the v32 Flutter app. Designed for Clanker (AI assistant) to query what you ate.

## API Endpoints

### `GET /health`
Health check (no auth required).

### Meals

#### `GET /meals?date=YYYY-MM-DD`
Get all meals for a specific date, including images.

**Headers:** `X-API-Key: <key>`

**Response:**
```json
[
  {
    "id": 1,
    "slot": "breakfast",
    "date": 1711296000000,
    "description": "Oatmeal with berries",
    "images": [
      {"id": 1, "mealId": 1, "filename": "photo.jpg", "url": "/images/1/photo.jpg"}
    ]
  }
]
```

#### `POST /meals`
Save a meal.

**Headers:** `X-API-Key: <key>`, `Content-Type: application/json`

**Body:**
```json
{
  "slot": "breakfast",
  "date": 1711296000000,
  "description": "Oatmeal with berries"
}
```

#### `GET /meals/recent?days=7`
Get meals from the last N days (default 7, max 30).

### Images

#### `POST /upload`
Upload an image for a meal.

**Headers:** `X-API-Key: <key>`, `Content-Type: multipart/form-data`

**Form fields:**
- `mealId` (required) - the meal ID
- `image` (required) - the image file (max 20MB)

**Response:**
```json
{
  "status": "ok",
  "filename": "photo.jpg",
  "url": "/images/1/photo.jpg"
}
```

#### `GET /images/{mealId}/{filename}`
Serve an image (no auth required for viewing).

### Stats

#### `GET /stats`
Get usage statistics.

**Response:**
```json
{
  "totalMeals": 156,
  "mealsBySlot": {"breakfast": 40, "lunch": 42, "afternoonSnack": 35, "dinner": 39},
  "currentStreak": 7,
  "daysLogged": 45,
  "avgRating": 3.8
}
```

### Day Ratings

#### `GET /rating?date=<epoch_millis>`
Get the rating for a specific day.

#### `POST /rating`
Save a day rating (1-5).

**Body:**
```json
{
  "date": 1711296000000,
  "score": 4
}
```

## Building

```bash
cd /home/gmn/apps/v32/backend
go mod tidy
go build -o server ./cmd/server
```

## Deploying to k3s

```bash
# Build and push
docker build -t harbor.gmn.lan/v32/backend:latest .
docker push harbor.gmn.lan/v32/backend:latest

# Deploy
kubectl apply -k k8s/
```

## API Key

```
v32_sk_d7f3a9c2e8b1f4d6a5c3e9f0b2d8a7c1
```

## Clanker Usage

Query today's meals:
```bash
curl -H "X-API-Key: v32_sk_d7f3a9c2e8b1f4d6a5c3e9f0b2d8a7c1" \
  https://v32.germainleignel.com/meals?date=2026-03-24
```

Get recent meals for pattern analysis:
```bash
curl -H "X-API-Key: v32_sk_d7f3a9c2e8b1f4d6a5c3e9f0b2d8a7c1" \
  https://v32.germainleignel.com/meals/recent?days=7
```

Get stats:
```bash
curl -H "X-API-Key: v32_sk_d7f3a9c2e8b1f4d6a5c3e9f0b2d8a7c1" \
  https://v32.germainleignel.com/stats
```

## Project Structure

```
backend/
├── cmd/server/main.go      # Entry point
├── internal/
│   ├── handlers/           # HTTP handlers
│   ├── middleware/         # Auth middleware
│   ├── models/             # Data models
│   └── storage/            # Database & file storage
├── k8s/                    # Kubernetes manifests
├── Dockerfile
└── README.md
```
