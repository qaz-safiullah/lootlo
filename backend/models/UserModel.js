const db = require('../config/db');

class UserModel {
    static async findByEmail(email) {
        const [rows] = await db.query('SELECT * FROM users WHERE email = ?', [email]);
        return rows[0];
    }

    static async findById(id) {
        const [rows] = await db.query('SELECT id, name, email, community_score, password FROM users WHERE id = ?', [id]);
        return rows[0];
    }

    static async create(name, email, hashedPassword) {
        const [result] = await db.query(
            'INSERT INTO users (name, email, password) VALUES (?, ?, ?)',
            [name, email, hashedPassword]
        );
        return result.insertId;
    }

    static async updateProfile(id, name, phone) {
        await db.query(
            'UPDATE users SET name = COALESCE(?, name), phone = COALESCE(?, phone) WHERE id = ?',
            [name, phone, id]
        );
    }

    static async updatePassword(id, hashedNewPassword) {
        await db.query('UPDATE users SET password = ? WHERE id = ?', [hashedNewPassword, id]);
    }

    static async resetPasswordByEmail(email, hashedNewPassword) {
        const [result] = await db.query('UPDATE users SET password = ? WHERE email = ?', [hashedNewPassword, email]);
        return result.affectedRows;
    }

    static async delete(id) {
        await db.query('DELETE FROM users WHERE id = ?', [id]);
    }
}

module.exports = UserModel;