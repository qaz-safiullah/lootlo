const db = require('../config/db');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');

// Helper to generate tokens
const generateToken = (id) => {
    return jwt.sign({ id }, process.env.JWT_SECRET, {
        expiresIn: process.env.JWT_EXPIRES_IN,
    });
};

// @desc    Register a new user
// @route   POST /api/users/signup
const signup = async (req, res) => {
    const { name, email, password } = req.body;

    if (!name || !email || !password) {
        return res.status(400).json({ success: false, error: 'All fields are required.' });
    }

    try {
        // 1. Check if user exists
        const [existing] = await db.query('SELECT email FROM users WHERE email = ?', [email]);
        if (existing.length > 0) {
            return res.status(409).json({ success: false, error: 'Email is already in use.' });
        }

        // 2. Hash password
        const salt = await bcrypt.genSalt(10);
        const hashedPassword = await bcrypt.hash(password, salt);

        // 3. Insert into database (community_score defaults to 0)
        const [result] = await db.query(
            'INSERT INTO users (name, email, password) VALUES (?, ?, ?)',
            [name, email, hashedPassword]
        );

        const userId = result.insertId;

        // 4. Send success response
        res.status(201).json({
            success: true,
            token: generateToken(userId),
            user: { id: userId, name, email, community_score: 0 }
        });
    } catch (error) {
        console.error('Signup Error:', error);
        res.status(500).json({ success: false, error: 'Server error during signup.' });
    }
};

// @desc    Authenticate user & get token
// @route   POST /api/users/login
const login = async (req, res) => {
    const { email, password } = req.body;

    if (!email || !password) {
        return res.status(400).json({ success: false, error: 'Email and password are required.' });
    }

    try {
        // 1. Find user
        const [rows] = await db.query('SELECT * FROM users WHERE email = ?', [email]);
        if (rows.length === 0) {
            return res.status(401).json({ success: false, error: 'Invalid email or password.' });
        }

        const user = rows[0];

        // 2. Verify password
        const isMatch = await bcrypt.compare(password, user.password);
        if (!isMatch) {
            return res.status(401).json({ success: false, error: 'Invalid email or password.' });
        }

        // 3. Send response (DO NOT send the password hash back!)
        res.status(200).json({
            success: true,
            token: generateToken(user.id),
            user: {
                id: user.id,
                name: user.name,
                email: user.email,
                community_score: user.community_score,
                lat: user.lat,
                lng: user.lng
            }
        });
    } catch (error) {
        console.error('Login Error:', error);
        res.status(500).json({ success: false, error: 'Server error during login.' });
    }
};

// @desc    Get Current User Profile
// @route   GET /api/users/me
const getProfile = async (req, res) => {
    try {
        // req.user.id comes from our protect middleware!
        const [rows] = await db.query('SELECT id, name, email, phone, community_score, lat, lng FROM users WHERE id = ?', [req.user.id]);
        
        if (rows.length === 0) {
            return res.status(404).json({ success: false, error: 'User not found.' });
        }

        res.status(200).json({ success: true, user: rows[0] });
    } catch (error) {
        console.error('Profile Fetch Error:', error);
        res.status(500).json({ success: false, error: 'Server error fetching profile.' });
    }
};

// @desc    Update user profile (Name or Phone)
// @route   PUT /api/users/profile
const updateProfile = async (req, res) => {
    const { name, phone } = req.body;
    const userId = req.user.id;

    try {
        await db.query(
            'UPDATE users SET name = COALESCE(?, name), phone = COALESCE(?, phone) WHERE id = ?',
            [name, phone, userId]
        );
        res.status(200).json({ success: true, message: 'Profile updated successfully.' });
    } catch (error) {
        console.error('Update Profile Error:', error);
        res.status(500).json({ success: false, error: 'Server error updating profile.' });
    }
};

// @desc    Change Password
// @route   POST /api/users/change-password
const changePassword = async (req, res) => {
    const { currentPassword, newPassword } = req.body;
    const userId = req.user.id;

    if (!currentPassword || !newPassword) {
        return res.status(400).json({ success: false, error: 'Both passwords are required.' });
    }

    try {
        // 1. Get current user
        const [rows] = await db.query('SELECT password FROM users WHERE id = ?', [userId]);
        const user = rows[0];

        // 2. Verify current password
        const isMatch = await bcrypt.compare(currentPassword, user.password);
        if (!isMatch) {
            return res.status(401).json({ success: false, error: 'Incorrect current password.' });
        }

        // 3. Hash and save new password
        const salt = await bcrypt.genSalt(10);
        const hashedNewPassword = await bcrypt.hash(newPassword, salt);

        await db.query('UPDATE users SET password = ? WHERE id = ?', [hashedNewPassword, userId]);

        res.status(200).json({ success: true, message: 'Password updated successfully.' });
    } catch (error) {
        console.error('Change Password Error:', error);
        res.status(500).json({ success: false, error: 'Server error updating password.' });
    }
};


// @desc    Reset Password (Direct Override for Dev)
// @route   POST /api/users/reset-password
const resetPassword = async (req, res) => {
    const { email, newPassword } = req.body;

    if (!email || !newPassword) {
        return res.status(400).json({ success: false, error: 'Email and new password are required.' });
    }

    try {
        const salt = await bcrypt.genSalt(10);
        const hashedNewPassword = await bcrypt.hash(newPassword, salt);

        const [result] = await db.query('UPDATE users SET password = ? WHERE email = ?', [hashedNewPassword, email]);

        if (result.affectedRows === 0) {
            return res.status(404).json({ success: false, error: 'No account found with that email.' });
        }

        res.status(200).json({ success: true, message: 'Password reset successfully. You can now log in.' });
    } catch (error) {
        console.error('Reset Password Error:', error);
        res.status(500).json({ success: false, error: 'Server error resetting password.' });
    }
};



// DON'T FORGET to export them:
module.exports = { signup, login, getProfile, updateProfile, changePassword, resetPassword };
