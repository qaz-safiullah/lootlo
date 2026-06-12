const db = require('../config/db');

class WishlistModel {
    static async checkExists(userId, itemId) {
        const [existing] = await db.query('SELECT id FROM saved_items WHERE user_id = ? AND item_id = ?', [userId, itemId]);
        return existing.length > 0 ? existing[0].id : null;
    }

    static async add(userId, itemId) {
        await db.query('INSERT INTO saved_items (user_id, item_id) VALUES (?, ?)', [userId, itemId]);
    }

    static async remove(saveId) {
        await db.query('DELETE FROM saved_items WHERE id = ?', [saveId]);
    }

    static async getUserWishlist(userId) {
        const query = `
            SELECT i.*, s.created_at as saved_at,
            (SELECT image_url FROM item_images WHERE item_id = i.id AND is_main = 1 LIMIT 1) as main_image,
            u.name as giver_name, u.community_score
            FROM saved_items s JOIN items i ON s.item_id = i.id JOIN users u ON i.user_id = u.id
            WHERE s.user_id = ? AND i.status = 'available' ORDER BY s.created_at DESC
        `;
        const [items] = await db.query(query, [userId]);
        return items;
    }
}

module.exports = WishlistModel;