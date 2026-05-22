const express = require('express');
const router = express.Router();
const { signup, login, updateUser, deleteUser } = require('../controllers/userController');
const { protect } = require('../middleware/authMiddleware'); // Import middleware

// Public Routes
router.post('/signup', signup);
router.post('/login', login);

// Protected Routes (Injecting 'protect' before the controller runs)
router.put('/:id', protect, updateUser);
router.delete('/:id', protect, deleteUser);

module.exports = router;