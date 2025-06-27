FROM redis:7-alpine

# Copy custom Redis configuration if needed
COPY redis.conf /usr/local/etc/redis/redis.conf

# Expose Redis port
EXPOSE 6379

# Set working directory
WORKDIR /data

# Start Redis server with custom config
CMD ["redis-server", "/usr/local/etc/redis/redis.conf"]
