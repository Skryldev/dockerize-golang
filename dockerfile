# Stage 1: Build
FROM golang:1.25.6-trixie AS builder

# نصب ابزارهای لازم
RUN apt-get update && apt-get install -y --no-install-recommends \
    git build-essential ca-certificates \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
    go build -ldflags="-s -w" -o main .

# Stage 2: Production
FROM gcr.io/distroless/base-debian11

# اضافه کردن certificates برای TLS/HTTPS
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

# کپی binary
COPY --from=builder /app/main /app/main

# تنظیم working directory
WORKDIR /app

# استفاده از non-root user
USER nonroot:nonroot

# Expose port
EXPOSE 8080

# Environment variables برای runtime tuning
ENV APP_ENV=production
ENV APP_PORT=8080
ENV GOMAXPROCS=4
ENV GOGC=100

# Healthcheck ساده و سریع
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s CMD ["/app/main", "health"] || exit 1

# اجرای برنامه
CMD ["/app/main"]
