const db = require('../config/db');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken'); // 1. Import JWT

// Helper function to generate JWT
const generateToken = (id) => {
    return jwt.sign({ id }, process.env.JWT_SECRET, {
        expiresIn: process.env.JWT_EXPIRES_IN
    });
};

// @desc    Register a new user
// @route   POST /api/users/signup
const signup = async (req, res) => {
    const { name, email, password } = req.body;

    if (!name || !email || !password) {
        return res.status(400).json({ error: 'Name, email, and password are required' });
    }

    try {
        const [existingUser] = await db.execute('SELECT email FROM users WHERE email = ?', [email]);
        if (existingUser.length > 0) {
            return res.status(409).json({ error: 'Email already exists' });
        }

        const salt = await bcrypt.genSalt(10);
        const hashedPassword = await bcrypt.hash(password, salt);

        const query = 'INSERT INTO users (name, email, password) VALUES (?, ?, ?)';
        const [result] = await db.execute(query, [name, email, hashedPassword]);

        const userId = result.insertId;

        // 2. Generate token and send it back
        res.status(201).json({
            message: 'User created successfully',
            user: { id: userId, name, email },
            token: generateToken(userId)
        });
    } catch (error) {
        console.error('Signup Error:', error);
        res.status(500).json({ error: 'Server error during signup' });
    }
};

// @desc    Authenticate user & get token
// @route   POST /api/users/login
const login = async (req, res) => {
    const { email, password } = req.body;

    if (!email || !password) {
        return res.status(400).json({ error: 'Email and password are required' });
    }

    try {
        const [rows] = await db.execute('SELECT * FROM users WHERE email = ?', [email]);
        if (rows.length === 0) {
            return res.status(401).json({ error: 'Invalid credentials' });
        }

        const user = rows[0];
        const isMatch = await bcrypt.compare(password, user.password);
        if (!isMatch) {
            return res.status(401).json({ error: 'Invalid credentials' });
        }

        delete user.password;
        
        // 3. Generate token and send it back
        res.status(200).json({
            message: 'Login successful',
            user: user,
            token: generateToken(user.id)
        });
    } catch (error) {
        console.error('Login Error:', error);
        res.status(500).json({ error: 'Server error during login' });
    }
};



// @desc    Update user profile (e.g., changing name)
// @route   PUT /api/users/:id
const updateUser = async (req, res) => {
    const { id } = req.params;
    const { name } = req.body;

    if (!name) {
        return res.status(400).json({ error: 'Name is required to update' });
    }

    try {
        const query = 'UPDATE users SET name = ? WHERE id = ?';
        const [result] = await db.execute(query, [name, id]);

        if (result.affectedRows === 0) {
            return res.status(404).json({ error: 'User not found' });
        }

        res.status(200).json({ message: 'User profile updated successfully' });
    } catch (error) {
        console.error('Update Error:', error);
        res.status(500).json({ error: 'Server error during update' });
    }
};

// @desc    Delete a user account
// @route   DELETE /api/users/:id
const deleteUser = async (req, res) => {
    const { id } = req.params;

    try {
        const query = 'DELETE FROM users WHERE id = ?';
        const [result] = await db.execute(query, [id]);

        if (result.affectedRows === 0) {
            return res.status(404).json({ error: 'User not found' });
        }

        res.status(200).json({ message: 'User account deleted successfully' });
    } catch (error) {
        console.error('Delete Error:', error);
        res.status(500).json({ error: 'Server error during deletion' });
    }
};


module.exports = {
    signup,
    login,
    updateUser,
    deleteUser
};