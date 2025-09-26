# Backend Dockerfile - AFTER state (no API keys)
FROM golang:1.22-alpine AS builder

WORKDIR /app

# Copy go mod files first for better caching
COPY go.mod go.sum ./
RUN go mod download

# Copy source code
COPY . .

# Build the binary with optimizations
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-w -s" -o backend main.go

# Final stage - minimal runtime
FROM alpine:latest

# Install ca-certificates for TLS and curl for health checks
RUN apk --no-cache add ca-certificates curl

WORKDIR /app

# Copy the binary from builder stage
COPY --from=builder /app/backend .

# Create directory for socket mounting
RUN mkdir -p /shared

# Expose the backend port
EXPOSE 8443

# Default environment variables for AFTER demo (can be overridden)
ENV WORKLOAD_API_SOCKET=unix:///shared/backend.sock
ENV BACKEND_APPROVED_CLIENT_SPIFFEID=spiffe://example.com/web
ENV BACKEND_NAME="Backend (Containerized AFTER Demo)"
ENV BACKEND_INFRA=Docker
ENV BACKEND_PORT=8443

# Health check to verify the service is running (no API key needed!)
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD curl -f -k https://localhost:8443/whoami || exit 1

# Run as non-root user for security
RUN adduser -D -s /bin/sh appuser
USER appuser

CMD ["./backend"]
