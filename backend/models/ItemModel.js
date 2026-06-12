const db = require('../config/db');

class ItemModel {
    static async createWithImages(itemData, files) {
        const connection = await db.getConnection();
        try {
            await connection.beginTransaction();
            const [itemResult] = await connection.query(
                'INSERT INTO items (user_id, title, description, category, city, address, phone, lat, lng, status) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
                [itemData.userId, itemData.title, itemData.description || '', itemData.category, itemData.city || '', itemData.address || '', itemData.phone, itemData.lat, itemData.lng, 'available']
            );
            
            const itemId = itemResult.insertId;

            if (files && files.length > 0) {
                const imageQueries = files.map((file, index) => {
                    const isMain = index === 0 ? 1 : 0;
                    return connection.query('INSERT INTO item_images (item_id, image_url, is_main) VALUES (?, ?, ?)', [itemId, file.path, isMain]);
                });
                await Promise.all(imageQueries);
            }

            await connection.commit();
            return itemId;
        } catch (error) {
            await connection.rollback();
            throw error;
        } finally {
            connection.release();
        }
    }

    static async getNearbyFiltered(userLat, userLng, radius, keyword, category) {
        const query = `
            SELECT i.*, u.name AS giver_name, u.community_score,
            (SELECT image_url FROM item_images WHERE item_id = i.id AND is_main = 1 LIMIT 1) as main_image,
            ( 6371 * acos( cos( radians(?) ) * cos( radians( i.lat ) ) * cos( radians( i.lng ) - radians(?) ) + sin( radians(?) ) * sin( radians( i.lat ) ) ) ) AS distance 
            FROM items i JOIN users u ON i.user_id = u.id
            WHERE i.status = 'available' AND (i.title LIKE ? OR i.description LIKE ?) AND i.category LIKE ?
            HAVING distance < ? ORDER BY distance ASC LIMIT 50
        `;
        const [items] = await db.query(query, [userLat, userLng, userLat, keyword, keyword, category, radius]);
        if (items.length === 0) return [];

        const itemIds = items.map(item => item.id);
        const [allImages] = await db.query('SELECT item_id, image_url FROM item_images WHERE item_id IN (?)', [itemIds]);

        return items.map(item => ({
            ...item,
            images: allImages.filter(img => img.item_id === item.id).map(img => img.image_url)
        }));
    }

    static async getByUserId(userId) {
        const query = `
            SELECT i.*, (SELECT image_url FROM item_images WHERE item_id = i.id AND is_main = 1 LIMIT 1) as main_image
            FROM items i WHERE i.user_id = ? ORDER BY created_at DESC
        `;
        const [items] = await db.query(query, [userId]);
        if (items.length === 0) return [];

        const itemIds = items.map(item => item.id);
        const [allImages] = await db.query('SELECT item_id, image_url FROM item_images WHERE item_id IN (?)', [itemIds]);

        return items.map(item => ({
            ...item,
            images: allImages.filter(img => img.item_id === item.id).map(img => img.image_url)
        }));
    }

    static async checkOwnership(itemId, userId) {
        const [items] = await db.query('SELECT user_id FROM items WHERE id = ?', [itemId]);
        return items.length > 0 && items[0].user_id === userId;
    }

    static async updateWithImages(id, data, retainedImages, files) {
        const connection = await db.getConnection();
        try {
            await connection.beginTransaction();

            await connection.query(
                'UPDATE items SET title = COALESCE(?, title), description = COALESCE(?, description), category = COALESCE(?, category), phone = COALESCE(?, phone), city = COALESCE(?, city), address = COALESCE(?, address) WHERE id = ?',
                [data.title, data.description, data.category, data.phone, data.city, data.address, id]
            );

            if (retainedImages.length > 0) {
                await connection.query('DELETE FROM item_images WHERE item_id = ? AND image_url NOT IN (?)', [id, retainedImages]);
            } else {
                await connection.query('DELETE FROM item_images WHERE item_id = ?', [id]);
            }

            if (files && files.length > 0) {
                const imageQueries = files.map(file => connection.query('INSERT INTO item_images (item_id, image_url, is_main) VALUES (?, ?, 0)', [id, file.path]));
                await Promise.all(imageQueries);
            }

            await connection.query('UPDATE item_images SET is_main = 0 WHERE item_id = ?', [id]);
            await connection.query('UPDATE item_images SET is_main = 1 WHERE item_id = ? LIMIT 1', [id]);

            await connection.commit();
        } catch (error) {
            await connection.rollback();
            throw error;
        } finally {
            connection.release();
        }
    }

    static async delete(id) {
        await db.query('DELETE FROM items WHERE id = ?', [id]);
    }
}

module.exports = ItemModel;