const redis = require('redis');

// Redis connection configuration for Render
const getRedisClient = () => {
  const redisUrl = process.env.REDIS_URL || process.env.REDISCLOUD_URL;
  
  if (redisUrl) {
    // Production: Use Render's Redis service
    console.log('Connecting to Redis via URL:', redisUrl.replace(/\/\/.*@/, '//***:***@'));
    return redis.createClient({
      url: redisUrl,
      socket: {
        tls: redisUrl.startsWith('rediss://'),
        rejectUnauthorized: false
      }
    });
  } else {
    // Development: Use local Redis
    console.log('Connecting to local Redis on localhost:6379');
    return redis.createClient({
      host: 'localhost',
      port: 6379
    });
  }
};

// Create and configure Redis client
const client = getRedisClient();

// Error handling
client.on('error', (err) => {
  console.error('Redis Client Error:', err);
});

client.on('connect', () => {
  console.log('Connected to Redis successfully');
});

client.on('ready', () => {
  console.log('Redis client ready');
});

// Connect to Redis
const connectRedis = async () => {
  try {
    await client.connect();
    console.log('Redis connection established');
    return client;
  } catch (error) {
    console.error('Failed to connect to Redis:', error);
    throw error;
  }
};

module.exports = { client, connectRedis };
