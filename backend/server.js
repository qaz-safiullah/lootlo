const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
require('dotenv').config();

// Import Database Connection (Just to initialize it on startup)
require('./config/db');

const app = express();

// --- Global Middleware ---
app.use(helmet()); // Secures HTTP headers automatically
app.use(cors()); // Allows your Flutter app to communicate with this API
app.use(express.json()); // Parses incoming JSON payloads
app.use(express.urlencoded({ extended: true }));
app.use(morgan('dev')); // Logs all API requests to the terminal (Great for debugging!)

// --- Health Check Route ---
app.get('/api/health', (req, res) => {
    res.status(200).json({ 
        success: true, 
        message: 'Lootlo API is running flawlessly.' 
    });
});

// --- API Routes ---
app.use('/api/users', require('./routes/userRoutes'));
app.use('/api/items', require('./routes/itemRoutes'));
app.use('/api/requests', require('./routes/requestRoutes'));
app.use('/api/wishlist', require('./routes/wishlistRoutes'));

// --- Global Error Handler (Catches all unhandled errors) ---
app.use((err, req, res, next) => {
    console.error(err.stack);
    res.status(500).json({ 
        success: false, 
        error: 'A critical server error occurred.' 
    });
});

// --- Booting the Server ---
const PORT = process.env.PORT || 3000;

// Binding to '0.0.0.0' is crucial for testing on a physical mobile device over Wi-Fi
app.listen(PORT, '0.0.0.0', () => {
    console.log(`🚀 Server is flying on http://0.0.0.0:${PORT}`);
    console.log(`📱 For Flutter testing, use your laptop's IP (e.g., http://192.168.137.1:${PORT})`);
});