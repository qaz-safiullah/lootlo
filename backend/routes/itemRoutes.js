const express = require('express');
const router = express.Router();
const { createItem, getNearbyItems, getMyListings, updateItem, deleteItem } = require('../controllers/itemController');
const { protect } = require('../middlewares/authMiddleware');
const { upload } = require('../utils/cloudinary'); // Multer config

// --- Protected Routes ---

// 1. Create Item (Multipart)
router.post('/', protect, upload.array('images', 3), createItem);

// 2. Fetch Feeds
router.get('/nearby', protect, getNearbyItems);
router.get('/my-listings', protect, getMyListings);

// 3. Update Item (CRITICAL FIX: Added Multer upload.array middleware!)
router.put('/:id', protect, upload.array('images', 3), updateItem);

// 4. Delete Item
router.delete('/:id', protect, deleteItem);

module.exports = router;