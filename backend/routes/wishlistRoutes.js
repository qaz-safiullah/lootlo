const express = require('express');
const router = express.Router();
const { checkWishlist, toggleWishlist, getMyWishlist } = require('../controllers/wishlistController');
const { protect } = require('../middlewares/authMiddleware');

router.use(protect);

router.get('/', getMyWishlist);
router.get('/:itemId/check', checkWishlist);       // <-- Added!
router.post('/:itemId/toggle', toggleWishlist);    // <-- Added!

module.exports = router;