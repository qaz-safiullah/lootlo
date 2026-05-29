const db = require('../config/db');

// @desc    Create a new giveaway item
// @route   POST /api/items
const createItem = async (req, res) => {
    const { title, description, category, city, address, phone, lat, lng } = req.body;
    const userId = req.user.id; // Comes from our JWT protect middleware

    // Added phone to the mandatory validation check!
    if (!title || !category || !city || !address || !phone || !lat || !lng) {
        return res.status(400).json({ success: false, error: 'Required fields missing.' });
    }

    // Start a MySQL Transaction to ensure if images fail, the item isn't created blindly
    const connection = await db.getConnection();
    
    try {
        await connection.beginTransaction();

        // 1. Insert the Item (Now explicitly includes phone)
        const [itemResult] = await connection.query(
            'INSERT INTO items (user_id, title, description, category, city, address, phone, lat, lng, status) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
            [userId, title, description || '', category, city || '', address || '', phone, lat, lng, 'available']
        );
        
        const itemId = itemResult.insertId;

        // 2. Insert Images (if any were uploaded)
        if (req.files && req.files.length > 0) {
            const imageQueries = req.files.map((file, index) => {
                const isMain = index === 0 ? true : false; // First image is the main cover photo
                return connection.query(
                    'INSERT INTO item_images (item_id, image_url, is_main) VALUES (?, ?, ?)',
                    [itemId, file.path, isMain]
                );
            });
            await Promise.all(imageQueries);
        }

        await connection.commit();
        res.status(201).json({ success: true, message: 'Giveaway created successfully!', itemId });
    } catch (error) {
        await connection.rollback();
        console.error('Create Item Error:', error);
        res.status(500).json({ success: false, error: 'Server error creating item.' });
    } finally {
        connection.release();
    }
};

// @desc    Get nearby items + Search & Filter Engine
// @route   GET /api/items/nearby?lat=X&lng=Y&radius=20&keyword=phone&category=electronics
const getNearbyItems = async (req, res) => {
    const userLat = parseFloat(req.query.lat) || 24.8607; 
    const userLng = parseFloat(req.query.lng) || 67.0011;
    const radius = parseInt(req.query.radius) || 20;
    
    // Search Filters
    const keyword = req.query.keyword ? `%${req.query.keyword}%` : '%';
    const category = req.query.category ? req.query.category : '%';

    try {
        // 1. Fetch items with distance calculation (Keeping main_image for quick feed loading)
        const query = `
            SELECT 
                i.*, 
                u.name AS giver_name, u.community_score,
                (SELECT image_url FROM item_images WHERE item_id = i.id AND is_main = 1 LIMIT 1) as main_image,
                ( 6371 * acos( cos( radians(?) ) * cos( radians( i.lat ) ) 
                * cos( radians( i.lng ) - radians(?) ) + sin( radians(?) ) 
                * sin( radians( i.lat ) ) ) ) AS distance 
            FROM items i
            JOIN users u ON i.user_id = u.id
            WHERE i.status = 'available' 
            AND (i.title LIKE ? OR i.description LIKE ?)
            AND i.category LIKE ?
            HAVING distance < ?
            ORDER BY distance ASC
            LIMIT 50
        `;

        const [items] = await db.query(query, [
            userLat, userLng, userLat, // For distance calculation
            keyword, keyword,          // For title and description search
            category,                  // For category filter
            radius                     // For radius limit
        ]);
        
        // If no items found, return an empty array immediately
        if (items.length === 0) {
            return res.status(200).json({ success: true, count: 0, data: [] });
        }

        // 2. THE UPGRADE: Fetch ALL images for these specific items
        const itemIds = items.map(item => item.id);
        const [allImages] = await db.query('SELECT item_id, image_url FROM item_images WHERE item_id IN (?)', [itemIds]);

        // 3. Map the images into a clean array inside each item object
        const itemsWithImages = items.map(item => {
            // Filter images that belong to this specific item
            const itemImages = allImages
                .filter(img => img.item_id === item.id)
                .map(img => img.image_url); // We just want the URL strings

            return {
                ...item,
                images: itemImages // Injects the array for the Flutter Carousel!
            };
        });
        
        res.status(200).json({ success: true, count: itemsWithImages.length, data: itemsWithImages });
    } catch (error) {
        console.error('Advanced Search Error:', error);
        res.status(500).json({ success: false, error: 'Server error fetching items.' });
    }
};

// @desc    Get logged-in user's items
// @route   GET /api/items/my-listings
const getMyListings = async (req, res) => {
    try {
        const query = `
            SELECT i.*, 
            (SELECT image_url FROM item_images WHERE item_id = i.id AND is_main = 1 LIMIT 1) as main_image
            FROM items i
            WHERE i.user_id = ?
            ORDER BY created_at DESC
        `;
        const [items] = await db.query(query, [req.user.id]);
        
        if (items.length === 0) return res.status(200).json({ success: true, count: 0, data: [] });

        // THE UPGRADE: Fetch ALL images so the Edit Screen can see them!
        const itemIds = items.map(item => item.id);
        const [allImages] = await db.query('SELECT item_id, image_url FROM item_images WHERE item_id IN (?)', [itemIds]);

        const itemsWithImages = items.map(item => {
            const itemImages = allImages.filter(img => img.item_id === item.id).map(img => img.image_url);
            return { ...item, images: itemImages };
        });
        
        res.status(200).json({ success: true, count: itemsWithImages.length, data: itemsWithImages });
    } catch (error) {
        res.status(500).json({ success: false, error: 'Server error fetching your listings.' });
    }
};

// @desc    Update an item (Edit Listing + Images)
// @route   PUT /api/items/:id
const updateItem = async (req, res) => {
    const { id } = req.params;
    const { title, description, category, phone, city, address } = req.body;
    const userId = req.user.id;
    
    // Parse the retained images from Flutter
    let retainedImages = req.body.retained_images || '[]';
    if (typeof retainedImages === 'string') retainedImages = JSON.parse(retainedImages);

    const connection = await db.getConnection();
    try {
        await connection.beginTransaction();

        // 1. Verify ownership
        const [items] = await connection.query('SELECT user_id FROM items WHERE id = ?', [id]);
        if (items.length === 0) throw new Error('Item not found.');
        if (items[0].user_id !== userId) throw new Error('Unauthorized.');

        // 2. Update Text Fields (Now includes city and address!)
        await connection.query(
            'UPDATE items SET title = COALESCE(?, title), description = COALESCE(?, description), category = COALESCE(?, category), phone = COALESCE(?, phone), city = COALESCE(?, city), address = COALESCE(?, address) WHERE id = ?',
            [title, description, category, phone, city, address, id]
        );

        // 3. Image Deletion Logic
        if (retainedImages.length > 0) {
            // Delete images that the user removed in the UI
            await connection.query('DELETE FROM item_images WHERE item_id = ? AND image_url NOT IN (?)', [id, retainedImages]);
        } else {
            // User deleted ALL existing images
            await connection.query('DELETE FROM item_images WHERE item_id = ?', [id]);
        }

        // 4. Image Insertion Logic (New Files)
        if (req.files && req.files.length > 0) {
            const imageQueries = req.files.map((file) => {
                return connection.query('INSERT INTO item_images (item_id, image_url, is_main) VALUES (?, ?, 0)', [id, file.path]);
            });
            await Promise.all(imageQueries);
        }

        // 5. Ensure EXACTLY ONE image is the main cover
        await connection.query('UPDATE item_images SET is_main = 0 WHERE item_id = ?', [id]);
        await connection.query('UPDATE item_images SET is_main = 1 WHERE item_id = ? LIMIT 1', [id]);

        await connection.commit();
        res.status(200).json({ success: true, message: 'Item and images updated successfully.' });
    } catch (error) {
        await connection.rollback();
        console.error('Update Item Error:', error.message);
        res.status(500).json({ success: false, error: error.message });
    } finally {
        connection.release();
    }
};
// @desc    Delete an item
// @route   DELETE /api/items/:id
const deleteItem = async (req, res) => {
    const { id } = req.params;
    const userId = req.user.id;

    try {
        // Verify ownership
        const [items] = await db.query('SELECT user_id FROM items WHERE id = ?', [id]);
        if (items.length === 0) return res.status(404).json({ success: false, error: 'Item not found.' });
        if (items[0].user_id !== userId) return res.status(401).json({ success: false, error: 'Unauthorized.' });

        // Because we used ON DELETE CASCADE in MySQL, deleting this item 
        // automatically wipes its images and requests from the database!
        await db.query('DELETE FROM items WHERE id = ?', [id]);

        res.status(200).json({ success: true, message: 'Item deleted permanently.' });
    } catch (error) {
        console.error('Delete Item Error:', error);
        res.status(500).json({ success: false, error: 'Server error deleting item.' });
    }
};

module.exports = { createItem, getNearbyItems, getMyListings, updateItem, deleteItem };