const express = require('express');
const router = express.Router();
const { signup, login, getProfile, updateProfile, changePassword, resetPassword } = require('../controllers/authController');
const { protect } = require('../middlewares/authMiddleware');

// Public Routes
router.post('/signup', signup);
router.post('/login', login);

// Protected Routes (Requires JWT token)
router.get('/me', protect, getProfile);

// Add these to your protected userRoutes.js block
router.put('/profile', protect, updateProfile);
router.post('/change-password', protect, changePassword);

router.post('/reset-password', resetPassword);

module.exports = router;