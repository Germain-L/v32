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

1. **Add DNS entry** (v32.gmn.lan points to 192.168.0.40):
   ```bash
   echo "192.168.0.40 v32.gmn.lan" | sudo tee -a /etc/hosts
   ```

2. **Build and push image** to Harbor:
   ```bash
   cd /home/gmn/apps/v32/backend
   docker build -t harbor.gmn.lan/v32/backend:latest .
   docker push harbor.gmn.lan/v32/backend:latest
   ```

3. **Deploy to k3s**:
   ```bash
   kubectl apply -k k8s/
   ```

4. **Verify**:
   ```bash
   kubectl get pods -l app=v32-backend
   kubectl logs -l app=v32-backend
   curl http://v32.gmn.lan/health
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

## Querying from Clanker

Once deployed, Clanker can query meals:

```bash
curl -H "X-API-Key: v32_sk_d7f3a9c2e8b1f4d6a5c3e9f0b2d8a7c1" \
  http://v32.gmn.lan/meals?date=2026-03-24
```

## Flutter Integration

The Flutter app has been updated with:

1. `SyncService` - Handles syncing meals to backend
2. `SyncingMealRepository` - Wrapper that auto-syncs on save
3. `SyncConfig` - Configuration for sync URL and API key

**Note:** The app uses HTTP (not HTTPS) for local network access. Android requires cleartext traffic to be enabled in `android/app/src/main/AndroidManifest.xml`:

```xml
<application android:usesCleartextTraffic="true" ...>
```

The sync is enabled by default. To configure at build time:
```bash
flutter build apk --dart-define=SYNC_URL=http://v32.gmn.lan --dart-define=SYNC_API_KEY=v32_sk_d7f3a9c2e8b1f4d6a5c3e9f0b2d8a7c1
```
