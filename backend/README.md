# v32 Meal Sync Backend

A minimal Go HTTP backend for syncing meal data from the v32 Flutter app.

## API Endpoints

### `GET /health`
Health check endpoint (no auth required, used by Kubernetes probes).

### `POST /meals`
Save a meal to the backend.

**Headers:**
- `X-API-Key`: Your API key (required)
- `Content-Type`: application/json

**Body:**
```json
{
  "slot": "breakfast",
  "date": 1711296000000,
  "description": "Oatmeal with berries",
  "imagePath": null
}
```

### `GET /meals?date=YYYY-MM-DD`
Get meals for a specific date.

**Headers:**
- `X-API-Key`: Your API key (required)

**Response:**
```json
[
  {
    "id": 1,
    "slot": "breakfast",
    "date": 1711296000000,
    "description": "Oatmeal with berries",
    "imagePath": null
  }
]
```

## Building

```bash
# Build locally
go build -o server .

# Build Docker image
docker build -t v32-backend:latest .
```

## Deploying to k3s

1. Push image to your registry:
   ```bash
   docker tag v32-backend:latest harbor.gmn.lan/v32/backend:latest
   docker push harbor.gmn.lan/v32/backend:latest
   ```

2. Apply Kubernetes manifests:
   ```bash
   kubectl apply -f k8s/
   ```

3. Verify deployment:
   ```bash
   kubectl get pods -l app=v32-backend
   kubectl logs -l app=v32-backend
   ```

## Configuration

Environment variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `API_KEY` | (required) | API key for authentication |
| `DB_PATH` | `/data/meals.db` | Path to SQLite database |
| `PORT` | `8080` | Server port |

## API Key

The generated API key for this deployment is:

```
v32_sk_d7f3a9c2e8b1f4d6a5c3e9f0b2d8a7c1
```

This is stored in the Kubernetes secret `v32-backend-secret`.

## Flutter Integration

The Flutter app has been updated with:

1. `SyncService` - Handles syncing meals to backend
2. `SyncingMealRepository` - Wrapper that auto-syncs on save
3. `SyncConfig` - Configuration for sync URL and API key

The sync is enabled by default. To configure:

```dart
// At app startup (already in main.dart):
SyncService.init(
  baseUrl: 'https://v32.gmn.lan',
  apiKey: 'v32_sk_d7f3a9c2e8b1f4d6a5c3e9f0b2d8a7c1',
  syncQueue: SQLiteSyncQueue(),
);
SyncService.instance.startPeriodicSync();
```

Or via environment variables at build time:
```bash
flutter build apk --dart-define=SYNC_URL=https://v32.gmn.lan --dart-define=SYNC_API_KEY=v32_sk_...
```
