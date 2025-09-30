# Web-Go Dockerfile - Direct SPIFFE client (no Ghostunnel needed!)
FROM golang:1.22-alpine AS builder

WORKDIR /app

# Copy go mod files first for better caching
COPY go.mod go.sum ./
RUN go mod download

# Copy source code
COPY . .

# Build the binary with optimizations
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-w -s" -o web-go main.go

# Final stage - minimal runtime
FROM alpine:latest

# Install ca-certificates for TLS and curl for health checks
RUN apk --no-cache add ca-certificates curl

WORKDIR /app

# Copy the binary from builder stage
COPY --from=builder /app/web-go .

# Copy public static files
COPY --from=builder /app/public ./public

# Create directory for socket mounting
RUN mkdir -p /shared

# Expose the web port
EXPOSE 8080

# Default environment variables for direct SPIFFE demo
ENV WEB_WORKLOAD_SOCKET=unix:///shared/web.sock
ENV WEB_PORT=8080
ENV BACKEND_URL=https://backend:8443
ENV BACKEND_SPIFFE_ID=spiffe://example.com/backend

# Health check to verify the service is running
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8080/status || exit 1

# Run as non-root user for security
RUN adduser -D -s /bin/sh appuser
USER appuser

CMD ["./web-go"]
