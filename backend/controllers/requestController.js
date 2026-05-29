const db = require('../config/db');

// 1. TAKER: Request an item
const requestItem = async (req, res) => {
    const { itemId } = req.params;
    const requesterId = req.user.id;

    try {
        const [items] = await db.query('SELECT user_id, status FROM items WHERE id = ?', [itemId]);
        if (items.length === 0) return res.status(404).json({ success: false, error: 'Item not found.' });
        if (items[0].status !== 'available') return res.status(400).json({ success: false, error: 'Item is no longer available.' });
        if (items[0].user_id === requesterId) return res.status(400).json({ success: false, error: 'You cannot request your own item.' });

        const [existing] = await db.query('SELECT id FROM requests WHERE item_id = ? AND requester_id = ? AND status != "rejected"', [itemId, requesterId]);
        if (existing.length > 0) return res.status(400).json({ success: false, error: 'You already have an active request for this item.' });

        await db.query('INSERT INTO requests (item_id, requester_id) VALUES (?, ?)', [itemId, requesterId]);
        res.status(201).json({ success: true, message: 'Request sent successfully!' });
    } catch (error) {
        res.status(500).json({ success: false, error: 'Server error while requesting item.' });
    }
};

// 2. GIVER: Propose Time
const proposeTime = async (req, res) => {
    const { requestId } = req.params;
    const { proposedTime } = req.body;
    const userId = req.user.id;

    try {
        const [requests] = await db.query(`SELECT r.item_id, i.user_id FROM requests r JOIN items i ON r.item_id = i.id WHERE r.id = ?`, [requestId]);
        if (requests.length === 0 || requests[0].user_id !== userId) return res.status(401).json({ success: false, error: 'Unauthorized.' });

        await db.query("UPDATE requests SET status = 'proposed', proposed_time = ? WHERE id = ?", [proposedTime, requestId]);
        res.status(200).json({ success: true, message: 'Pickup time proposed to taker!' });
    } catch (error) {
        res.status(500).json({ success: false, error: 'Server error proposing time.' });
    }
};

// 3. TAKER: Accept Proposal
const acceptProposal = async (req, res) => {
    const { requestId } = req.params;
    const userId = req.user.id;
    const connection = await db.getConnection();

    try {
        await connection.beginTransaction();
        const [requests] = await connection.query(`SELECT item_id, requester_id FROM requests WHERE id = ?`, [requestId]);
        if (requests.length === 0 || requests[0].requester_id !== userId) throw new Error('Unauthorized');

        const itemId = requests[0].item_id;

        // Accept this request, reject all others, update item status
        await connection.query("UPDATE requests SET status = 'accepted' WHERE id = ?", [requestId]);
        await connection.query("UPDATE requests SET status = 'rejected' WHERE item_id = ? AND id != ?", [itemId, requestId]);
        await connection.query("UPDATE items SET status = 'promised' WHERE id = ?", [itemId]);

        await connection.commit();
        res.status(200).json({ success: true, message: 'Pickup confirmed! Item is now promised to you.' });
    } catch (error) {
        await connection.rollback();
        res.status(400).json({ success: false, error: error.message });
    } finally {
        connection.release();
    }
};

// 4. BOTH: Dual Confirmation Handshake
const confirmHandshake = async (req, res) => {
    const { requestId } = req.params;
    const userId = req.user.id;
    const connection = await db.getConnection();

    try {
        await connection.beginTransaction();
        const [requests] = await connection.query(`
            SELECT r.*, i.user_id as giver_id 
            FROM requests r JOIN items i ON r.item_id = i.id 
            WHERE r.id = ?`, [requestId]
        );

        if (requests.length === 0) throw new Error('Request not found');
        const reqData = requests[0];

        // Determine role and update confirmation flag
        if (userId === reqData.giver_id) {
            await connection.query('UPDATE requests SET giver_confirmed = TRUE WHERE id = ?', [requestId]);
            reqData.giver_confirmed = 1;
        } else if (userId === reqData.requester_id) {
            await connection.query('UPDATE requests SET taker_confirmed = TRUE WHERE id = ?', [requestId]);
            reqData.taker_confirmed = 1;
        } else {
            throw new Error('Unauthorized');
        }

        // If BOTH have confirmed, finalize the transaction!
        if (reqData.giver_confirmed && reqData.taker_confirmed) {
            await connection.query("UPDATE requests SET status = 'completed' WHERE id = ?", [requestId]);
            await connection.query("UPDATE items SET status = 'completed' WHERE id = ?", [reqData.item_id]);
            await connection.query("UPDATE users SET community_score = community_score + 1 WHERE id = ?", [reqData.giver_id]);
            await connection.commit();
            return res.status(200).json({ success: true, message: 'Transaction Complete! +1 Community Score awarded to the Giver.' });
        }

        await connection.commit();
        res.status(200).json({ success: true, message: 'Your confirmation is logged. Waiting for the other party.' });
    } catch (error) {
        await connection.rollback();
        res.status(400).json({ success: false, error: error.message });
    } finally {
        connection.release();
    }
};

// 5. GETTERS & CANCEL (Standardized for both views)
const getReceivedRequests = async (req, res) => {
    try {
        const query = `
            SELECT r.id as request_id, r.status as request_status, r.proposed_time, r.giver_confirmed, r.taker_confirmed,
                   i.title as item_title, i.id as item_id, 
                   u.name as requester_name, u.phone as requester_phone, u.community_score as requester_score
            FROM requests r JOIN items i ON r.item_id = i.id JOIN users u ON r.requester_id = u.id
            WHERE i.user_id = ? AND r.status != 'rejected'
            ORDER BY r.created_at DESC
        `;
        const [requests] = await db.query(query, [req.user.id]);
        res.status(200).json({ success: true, data: requests });
    } catch (error) { res.status(500).json({ success: false }); }
};

const getMyRequests = async (req, res) => {
    try {
        const query = `
            SELECT r.id as request_id, r.status as request_status, r.proposed_time, r.giver_confirmed, r.taker_confirmed,
                   i.title as item_title, i.id as item_id, i.address, 
                   u.name as giver_name, u.phone as giver_phone
            FROM requests r JOIN items i ON r.item_id = i.id JOIN users u ON i.user_id = u.id
            WHERE r.requester_id = ? AND r.status != 'rejected'
            ORDER BY r.created_at DESC
        `;
        const [requests] = await db.query(query, [req.user.id]);
        res.status(200).json({ success: true, data: requests });
    } catch (error) { res.status(500).json({ success: false }); }
};

const cancelRequest = async (req, res) => {
    const { requestId } = req.params;
    await db.query("UPDATE requests SET status = 'rejected' WHERE id = ?", [requestId]);
    res.status(200).json({ success: true, message: 'Request cancelled.' });
};

// @desc    Check if I already requested an item
// @route   GET /api/requests/:itemId/check
const checkRequestStatus = async (req, res) => {
    const { itemId } = req.params;
    const requesterId = req.user.id;
    try {
        const [existing] = await db.query('SELECT id FROM requests WHERE item_id = ? AND requester_id = ? AND status != "rejected"', [itemId, requesterId]);
        res.status(200).json({ success: true, hasRequested: existing.length > 0 });
    } catch (error) {
        res.status(500).json({ success: false, hasRequested: false });
    }
};

module.exports = { requestItem, proposeTime, acceptProposal, confirmHandshake, getReceivedRequests, getMyRequests, cancelRequest, checkRequestStatus };