const express = require('express');
const router = express.Router();
// IMPORTANT: Make sure you import deleteAccount here!
const { 
    signup, login, getProfile, updateProfile, changePassword, resetPassword, deleteAccount 
} = require('../controllers/authController');
const { protect } = require('../middlewares/authMiddleware');

// Public Routes
router.post('/signup', signup);
router.post('/login', login);
router.post('/reset-password', resetPassword);

// Protected Routes
router.get('/me', protect, getProfile);
router.delete('/me', protect, deleteAccount); // <-- ADD THIS LINE

router.put('/profile', protect, updateProfile);
router.post('/change-password', protect, changePassword);

module.exports = router;