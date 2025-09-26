# Web Dockerfile - AFTER state (no API keys)
FROM node:20-alpine

WORKDIR /app

# Copy package files first for better caching
COPY package*.json ./

# Install dependencies (production only for smaller image)
RUN npm ci --only=production

# Copy source code
COPY . .

# Install curl for health checks
RUN apk --no-cache add curl

# Create non-root user for security
RUN addgroup -g 1001 -S nodejs && \
    adduser -S webuser -u 1001 -G nodejs

# Change ownership of the app directory
RUN chown -R webuser:nodejs /app
USER webuser

# Expose the web port
EXPOSE 8080

# Default environment variables for AFTER demo
ENV WEB_PORT=8080
ENV WEB_GHOSTUNNEL_ONE_PORT=8081
ENV WEB_GHOSTUNNEL_TWO_PORT=8082

# Health check to verify the service is running (no API key needed!)
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8080/status || exit 1

CMD ["npm", "start"]
