# Build stage
FROM golang:1.24-alpine AS builder

WORKDIR /app

# Install dependencies
RUN apk add --no-cache gcc musl-dev sqlite-dev

# Copy go mod files
COPY go.mod go.sum ./
RUN go mod download

# Copy source and build
COPY main.go ./
RUN CGO_ENABLED=1 GOOS=linux go build -ldflags="-s -w" -o server .

# Runtime stage
FROM alpine:3.19

WORKDIR /app

# Install runtime dependencies for SQLite
RUN apk add --no-cache sqlite-libs ca-certificates tzdata

# Copy binary
COPY --from=builder /app/server .

# Create data directory
RUN mkdir -p /data

EXPOSE 8080

ENV PORT=8080
ENV DB_PATH=/data/meals.db

CMD ["./server"]
