const db = require('../config/db');

class RequestModel {
    static async getItemDetailsForRequest(itemId) {
        const [items] = await db.query('SELECT user_id, status FROM items WHERE id = ?', [itemId]);
        return items[0];
    }

    static async checkActiveRequest(itemId, requesterId) {
        const [existing] = await db.query('SELECT id FROM requests WHERE item_id = ? AND requester_id = ? AND status != "rejected"', [itemId, requesterId]);
        return existing.length > 0;
    }

    static async create(itemId, requesterId) {
        await db.query('INSERT INTO requests (item_id, requester_id) VALUES (?, ?)', [itemId, requesterId]);
    }

    static async proposeTime(requestId, proposedTime, userId) {
        const [requests] = await db.query(`SELECT r.item_id, i.user_id FROM requests r JOIN items i ON r.item_id = i.id WHERE r.id = ?`, [requestId]);
        if (requests.length === 0 || requests[0].user_id !== userId) throw new Error('Unauthorized');

        await db.query("UPDATE requests SET status = 'proposed', proposed_time = ? WHERE id = ?", [proposedTime, requestId]);
    }

    static async acceptProposal(requestId, userId) {
        const connection = await db.getConnection();
        try {
            await connection.beginTransaction();
            const [requests] = await connection.query(`SELECT item_id, requester_id FROM requests WHERE id = ?`, [requestId]);
            if (requests.length === 0 || requests[0].requester_id !== userId) throw new Error('Unauthorized');

            const itemId = requests[0].item_id;
            await connection.query("UPDATE requests SET status = 'accepted' WHERE id = ?", [requestId]);
            await connection.query("UPDATE requests SET status = 'rejected' WHERE item_id = ? AND id != ?", [itemId, requestId]);
            await connection.query("UPDATE items SET status = 'promised' WHERE id = ?", [itemId]);

            await connection.commit();
        } catch (error) {
            await connection.rollback();
            throw error;
        } finally {
            connection.release();
        }
    }

    static async processHandshake(requestId, userId) {
        const connection = await db.getConnection();
        try {
            await connection.beginTransaction();
            const [requests] = await connection.query(`SELECT r.*, i.user_id as giver_id FROM requests r JOIN items i ON r.item_id = i.id WHERE r.id = ?`, [requestId]);
            if (requests.length === 0) throw new Error('Request not found');
            const reqData = requests[0];

            if (userId === reqData.giver_id) {
                await connection.query('UPDATE requests SET giver_confirmed = TRUE WHERE id = ?', [requestId]);
                reqData.giver_confirmed = 1;
            } else if (userId === reqData.requester_id) {
                await connection.query('UPDATE requests SET taker_confirmed = TRUE WHERE id = ?', [requestId]);
                reqData.taker_confirmed = 1;
            } else {
                throw new Error('Unauthorized');
            }

            if (reqData.giver_confirmed && reqData.taker_confirmed) {
                await connection.query("UPDATE requests SET status = 'completed' WHERE id = ?", [requestId]);
                await connection.query("UPDATE items SET status = 'completed' WHERE id = ?", [reqData.item_id]);
                await connection.query("UPDATE users SET community_score = community_score + 1 WHERE id = ?", [reqData.giver_id]);
                await connection.commit();
                return { completed: true };
            }

            await connection.commit();
            return { completed: false };
        } catch (error) {
            await connection.rollback();
            throw error;
        } finally {
            connection.release();
        }
    }

    static async getReceived(userId) {
        const query = `
            SELECT r.id as request_id, r.status as request_status, r.proposed_time, r.giver_confirmed, r.taker_confirmed,
            i.title as item_title, i.id as item_id, u.name as requester_name, u.community_score as requester_score
            FROM requests r JOIN items i ON r.item_id = i.id JOIN users u ON r.requester_id = u.id
            WHERE i.user_id = ? AND r.status != 'rejected' ORDER BY r.id DESC
        `;
        const [rows] = await db.query(query, [userId]);
        return rows;
    }

    static async getMy(userId) {
        const query = `
            SELECT r.id as request_id, r.status as request_status, r.proposed_time, r.giver_confirmed, r.taker_confirmed,
            i.title as item_title, i.id as item_id, i.address, u.name as giver_name
            FROM requests r JOIN items i ON r.item_id = i.id JOIN users u ON i.user_id = u.id
            WHERE r.requester_id = ? AND r.status != 'rejected' ORDER BY r.id DESC
        `;
        const [rows] = await db.query(query, [userId]);
        return rows;
    }

    static async cancel(requestId) {
        await db.query("UPDATE requests SET status = 'rejected' WHERE id = ?", [requestId]);
    }
}

module.exports = RequestModel;