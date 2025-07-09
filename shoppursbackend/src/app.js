const express = require('express');
const cors = require('cors');
const morgan = require('morgan');
require('dotenv').config();

const authRoutes = require('./routes/auth.routes');
const productRoutes = require('./routes/product.routes');
const categoryRoutes = require('./routes/category.routes');
const cartRoutes = require('./routes/cart.routes');
const orderRoutes = require('./routes/order.routes');
const addressRoutes = require('./routes/address.routes');
const retailerRoutes = require('./routes/retailer.routes');
const adminRoutes = require('./routes/admin.routes');
const employeeRoutes = require('./routes/employee.routes');
const settingsRoutes = require('./routes/settings.routes');
const userRoutes = require('./routes/user.routes');
const paymentRoutes = require('./routes/payment.routes');

const app = express();

// Request logging middleware
app.use((req, res, next) => {
  const startTime = Date.now();
  const timestamp = new Date().toISOString();
  
  // Log the incoming request
  console.log(`\n🔄 [${timestamp}] ${req.method} ${req.originalUrl}`);
  console.log(`📍 IP: ${req.ip || req.connection.remoteAddress}`);
  console.log(`🌐 User-Agent: ${req.get('User-Agent') || 'Unknown'}`);
  
  // Log request body for POST/PUT requests (excluding sensitive data)
  if ((req.method === 'POST' || req.method === 'PUT') && req.body) {
    const bodyToLog = { ...req.body };
    // Hide sensitive fields
    if (bodyToLog.password) bodyToLog.password = '[HIDDEN]';
    if (bodyToLog.token) bodyToLog.token = '[HIDDEN]';
    console.log(`📦 Body:`, JSON.stringify(bodyToLog, null, 2));
  }
  
  // Log query parameters
  if (Object.keys(req.query).length > 0) {
    console.log(`🔍 Query:`, req.query);
  }
  
  // Capture response end to log completion
  const originalSend = res.send;
  res.send = function(data) {
    const endTime = Date.now();
    const duration = endTime - startTime;
    
    console.log(`✅ [${new Date().toISOString()}] ${req.method} ${req.originalUrl} - ${res.statusCode} (${duration}ms)`);
    
    // Log response for errors
    if (res.statusCode >= 400) {
      console.log(`❌ Error Response:`, data);
    }
    
    console.log(`${'='.repeat(80)}`);
    
    originalSend.call(this, data);
  };
  
  next();
});

// CORS configuration for development and production
const corsOptions = {
  origin: function (origin, callback) {
    // Allow requests with no origin (like mobile apps or curl requests)
    if (!origin) return callback(null, true);
    
    // Allow localhost and 127.0.0.1 on any port
    if (origin.match(/^https?:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/)) {
      return callback(null, true);
    }
    
    // Allow any IP address on local network (192.168.x.x, 10.x.x.x, 172.16-31.x.x)
    if (origin.match(/^https?:\/\/(192\.168\.\d+\.\d+|10\.\d+\.\d+\.\d+|172\.(1[6-9]|2[0-9]|3[0-1])\.\d+\.\d+)(:\d+)?$/)) {
      return callback(null, true);
    }
    
    // Fallback for specific origins
    const allowedOrigins = [
    'http://localhost:3000',
    'http://localhost:65109',
    'http://localhost:65100',
    'http://localhost:65111',
    'http://localhost:8080',
    'http://127.0.0.1:3000',
    'http://127.0.0.1:65100',
    'http://127.0.0.1:65111',
    'http://127.0.0.1:8080',
    ];
    
    if (allowedOrigins.indexOf(origin) !== -1) {
      return callback(null, true);
    }
    
    callback(new Error('Not allowed by CORS'));
  },
  credentials: true,
  optionsSuccessStatus: 200,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With'],
};

// Middleware
app.use(cors(corsOptions));

// Morgan HTTP request logger - choose one format:
// 'combined' - Apache combined log format (detailed)
// 'common' - Apache common log format
// 'dev' - concise output colored by response status (good for development)
// 'short' - shorter than default, also including response time
// 'tiny' - minimal output
app.use(morgan('dev')); // Good for development - shows method, url, status, response time

app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Serve static files for uploaded images
app.use('/uploads', express.static('uploads'));

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({
    success: true,
    message: 'AnwarFood API is running',
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV || 'development'
  });
});

// Root endpoint
app.get('/', (req, res) => {
  res.json({
    success: true,
    message: 'Welcome to AnwarFood API',
    version: '1.0.0'
  });
});

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/products', productRoutes);
app.use('/api/categories', categoryRoutes);
app.use('/api/cart', cartRoutes);
app.use('/api/orders', orderRoutes);
app.use('/api/address', addressRoutes);
app.use('/api/retailers', retailerRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/employee', employeeRoutes);
app.use('/api/settings', settingsRoutes);
app.use('/api/user', userRoutes);
app.use('/api/payment', paymentRoutes);

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({
    success: false,
    message: 'Something went wrong!',
    error: err.message
  });
});

const PORT = process.env.PORT || 3000;
const HOST = '0.0.0.0'; // This allows access from all network interfaces

app.listen(PORT, HOST, () => {
  console.log(`Server is running on ${HOST}:${PORT}`);
  console.log(`Local access: http://localhost:${PORT}`);
  console.log(`Network access: http://[YOUR_IP_ADDRESS]:${PORT}`);
}); 


