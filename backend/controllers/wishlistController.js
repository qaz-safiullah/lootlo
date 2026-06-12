const Wishlist = require('../models/WishlistModel');

const checkWishlist = async (req, res) => {
    try {
        const existingId = await Wishlist.checkExists(req.user.id, req.params.itemId);
        res.status(200).json({ success: true, inWishlist: !!existingId });
    } catch (error) {
        console.error('Wishlist Check Error:', error);
        res.status(500).json({ success: false, inWishlist: false, error: 'Server error checking wishlist.' });
    }
};

const toggleWishlist = async (req, res) => {
    try {
        const existingId = await Wishlist.checkExists(req.user.id, req.params.itemId);

        if (existingId) {
            await Wishlist.remove(existingId);
            return res.status(200).json({ success: true, message: 'Item removed from wishlist.', inWishlist: false });
        } else {
            await Wishlist.add(req.user.id, req.params.itemId);
            return res.status(201).json({ success: true, message: 'Item saved to wishlist!', inWishlist: true });
        }
    } catch (error) {
        console.error('Wishlist Toggle Error:', error);
        res.status(500).json({ success: false, error: 'Server error updating wishlist.' });
    }
};

const getMyWishlist = async (req, res) => {
    try {
        const items = await Wishlist.getUserWishlist(req.user.id);
        res.status(200).json({ success: true, count: items.length, data: items });
    } catch (error) {
        console.error('Fetch Wishlist Error:', error);
        res.status(500).json({ success: false, error: 'Server error fetching wishlist.' });
    }
};

module.exports = { checkWishlist, toggleWishlist, getMyWishlist };