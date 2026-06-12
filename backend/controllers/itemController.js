const Item = require('../models/ItemModel');

const createItem = async (req, res) => {
    const { title, description, category, city, address, phone, lat, lng } = req.body;
    
    if (!title || !category || !city || !address || !phone || !lat || !lng) {
        return res.status(400).json({ success: false, error: 'Required fields missing.' });
    }

    try {
        const itemId = await Item.createWithImages({
            userId: req.user.id, title, description, category, city, address, phone, lat, lng
        }, req.files);
        
        res.status(201).json({ success: true, message: 'Giveaway created successfully!', itemId });
    } catch (error) {
        console.error('Create Item Error:', error);
        res.status(500).json({ success: false, error: 'Server error creating item.' });
    }
};

const getNearbyItems = async (req, res) => {
    const userLat = parseFloat(req.query.lat) || 24.8607; 
    const userLng = parseFloat(req.query.lng) || 67.0011;
    const radius = parseInt(req.query.radius) || 100;
    const keyword = req.query.keyword ? `%${req.query.keyword}%` : '%';
    const category = req.query.category ? req.query.category : '%';

    try {
        const itemsWithImages = await Item.getNearbyFiltered(userLat, userLng, radius, keyword, category);
        res.status(200).json({ success: true, count: itemsWithImages.length, data: itemsWithImages });
    } catch (error) {
        console.error('Advanced Search Error:', error);
        res.status(500).json({ success: false, error: 'Server error fetching items.' });
    }
};

const getMyListings = async (req, res) => {
    try {
        const itemsWithImages = await Item.getByUserId(req.user.id);
        res.status(200).json({ success: true, count: itemsWithImages.length, data: itemsWithImages });
    } catch (error) {
        res.status(500).json({ success: false, error: 'Server error fetching your listings.' });
    }
};

const updateItem = async (req, res) => {
    const { id } = req.params;
    let retainedImages = req.body.retained_images || '[]';
    if (typeof retainedImages === 'string') retainedImages = JSON.parse(retainedImages);

    try {
        const isOwner = await Item.checkOwnership(id, req.user.id);
        if (!isOwner) return res.status(401).json({ success: false, error: 'Unauthorized or Item not found.' });

        await Item.updateWithImages(id, req.body, retainedImages, req.files);
        res.status(200).json({ success: true, message: 'Item and images updated successfully.' });
    } catch (error) {
        console.error('Update Item Error:', error.message);
        res.status(500).json({ success: false, error: 'Server error updating item.' });
    }
};

const deleteItem = async (req, res) => {
    try {
        const isOwner = await Item.checkOwnership(req.params.id, req.user.id);
        if (!isOwner) return res.status(401).json({ success: false, error: 'Unauthorized or Item not found.' });

        await Item.delete(req.params.id);
        res.status(200).json({ success: true, message: 'Item deleted permanently.' });
    } catch (error) {
        console.error('Delete Item Error:', error);
        res.status(500).json({ success: false, error: 'Server error deleting item.' });
    }
};

module.exports = { createItem, getNearbyItems, getMyListings, updateItem, deleteItem };