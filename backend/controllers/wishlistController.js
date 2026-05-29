const db = require('../config/db');

// @desc    Check if an item is already saved (Needed for the Red/White Heart UI)
// @route   GET /api/wishlist/:itemId/check
const checkWishlist = async (req, res) => {
    const { itemId } = req.params;
    const userId = req.user.id;

    try {
        const [existing] = await db.query('SELECT id FROM saved_items WHERE user_id = ? AND item_id = ?', [userId, itemId]);
        
        // Tells Flutter if the heart should be filled in or not
        res.status(200).json({ success: true, inWishlist: existing.length > 0 });
    } catch (error) {
        console.error('Wishlist Check Error:', error);
        res.status(500).json({ success: false, inWishlist: false, error: 'Server error checking wishlist.' });
    }
};

// @desc    Toggle Save/Unsave an item
// @route   POST /api/wishlist/:itemId/toggle
const toggleWishlist = async (req, res) => {
    const { itemId } = req.params;
    const userId = req.user.id;

    try {
        // Check if it's already saved
        const [existing] = await db.query('SELECT id FROM saved_items WHERE user_id = ? AND item_id = ?', [userId, itemId]);

        if (existing.length > 0) {
            // Unsave it
            await db.query('DELETE FROM saved_items WHERE id = ?', [existing[0].id]);
            // Notice we return `inWishlist: false` so Flutter knows the exact state
            return res.status(200).json({ success: true, message: 'Item removed from wishlist.', inWishlist: false });
        } else {
            // Save it
            await db.query('INSERT INTO saved_items (user_id, item_id) VALUES (?, ?)', [userId, itemId]);
            // Return `inWishlist: true`
            return res.status(201).json({ success: true, message: 'Item saved to wishlist!', inWishlist: true });
        }
    } catch (error) {
        console.error('Wishlist Toggle Error:', error);
        res.status(500).json({ success: false, error: 'Server error updating wishlist.' });
    }
};

// @desc    Get user's saved items (For the upcoming Wishlist Screen)
// @route   GET /api/wishlist
const getMyWishlist = async (req, res) => {
    try {
        const query = `
            SELECT i.*, 
                   s.created_at as saved_at,
                   (SELECT image_url FROM item_images WHERE item_id = i.id AND is_main = 1 LIMIT 1) as main_image,
                   u.name as giver_name, u.community_score
            FROM saved_items s
            JOIN items i ON s.item_id = i.id
            JOIN users u ON i.user_id = u.id
            WHERE s.user_id = ? AND i.status = 'available'
            ORDER BY s.created_at DESC
        `;
        const [items] = await db.query(query, [req.user.id]);
        
        res.status(200).json({ success: true, count: items.length, data: items });
    } catch (error) {
        console.error('Fetch Wishlist Error:', error);
        res.status(500).json({ success: false, error: 'Server error fetching wishlist.' });
    }
};

module.exports = { checkWishlist, toggleWishlist, getMyWishlist };