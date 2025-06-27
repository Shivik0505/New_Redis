const express = require('express');
const { client, connectRedis } = require('./redis-client');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.json());

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'OK', timestamp: new Date().toISOString() });
});

// Redis test endpoint
app.get('/redis-test', async (req, res) => {
  try {
    await client.set('test-key', 'Hello from Render Redis!');
    const value = await client.get('test-key');
    res.json({ 
      success: true, 
      message: 'Redis is working!', 
      value: value,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('Redis test failed:', error);
    res.status(500).json({ 
      success: false, 
      error: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

// Set a key-value pair
app.post('/set/:key', async (req, res) => {
  try {
    const { key } = req.params;
    const { value } = req.body;
    
    await client.set(key, JSON.stringify(value));
    res.json({ success: true, key, value });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// Get a value by key
app.get('/get/:key', async (req, res) => {
  try {
    const { key } = req.params;
    const value = await client.get(key);
    
    if (value === null) {
      return res.status(404).json({ success: false, message: 'Key not found' });
    }
    
    res.json({ success: true, key, value: JSON.parse(value) });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// Start server after Redis connection
const startServer = async () => {
  try {
    // Connect to Redis first
    await connectRedis();
    
    // Start Express server
    app.listen(PORT, '0.0.0.0', () => {
      console.log(`Server running on port ${PORT}`);
      console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
      console.log(`Redis URL configured: ${!!process.env.REDIS_URL}`);
    });
  } catch (error) {
    console.error('Failed to start server:', error);
    process.exit(1);
  }
};

// Graceful shutdown
process.on('SIGTERM', async () => {
  console.log('SIGTERM received, shutting down gracefully');
  await client.quit();
  process.exit(0);
});

process.on('SIGINT', async () => {
  console.log('SIGINT received, shutting down gracefully');
  await client.quit();
  process.exit(0);
});

startServer();
