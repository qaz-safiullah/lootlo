const User = require('../models/UserModel');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');

const generateToken = (id) => {
    return jwt.sign({ id }, process.env.JWT_SECRET, { expiresIn: process.env.JWT_EXPIRES_IN });
};

const signup = async (req, res) => {
    const { name, email, password } = req.body;
    if (!name || !email || !password) return res.status(400).json({ success: false, error: 'All fields are required.' });

    try {
        const existingUser = await User.findByEmail(email);
        if (existingUser) return res.status(409).json({ success: false, error: 'Email is already in use.' });

        const salt = await bcrypt.genSalt(10);
        const hashedPassword = await bcrypt.hash(password, salt);

        const userId = await User.create(name, email, hashedPassword);

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

const login = async (req, res) => {
    const { email, password } = req.body;
    if (!email || !password) return res.status(400).json({ success: false, error: 'Email and password are required.' });

    try {
        const user = await User.findByEmail(email);
        if (!user) return res.status(401).json({ success: false, error: 'Invalid email or password.' });

        const isMatch = await bcrypt.compare(password, user.password);
        if (!isMatch) return res.status(401).json({ success: false, error: 'Invalid email or password.' });

        res.status(200).json({
            success: true,
            token: generateToken(user.id),
            user: {
                id: user.id, name: user.name, email: user.email,
                community_score: user.community_score, lat: user.lat, lng: user.lng
            }
        });
    } catch (error) {
        console.error('Login Error:', error);
        res.status(500).json({ success: false, error: 'Server error during login.' });
    }
};

const getProfile = async (req, res) => {
    try {
        const user = await User.findById(req.user.id);
        if (!user) return res.status(404).json({ success: false, error: 'User not found.' });
        
        delete user.password; // Ensure password never leaks
        res.status(200).json({ success: true, user });
    } catch (error) {
        console.error('Profile Fetch Error:', error);
        res.status(500).json({ success: false, error: 'Server error fetching profile.' });
    }
};

const updateProfile = async (req, res) => {
    try {
        await User.updateProfile(req.user.id, req.body.name, req.body.phone);
        res.status(200).json({ success: true, message: 'Profile updated successfully.' });
    } catch (error) {
        console.error('Update Profile Error:', error);
        res.status(500).json({ success: false, error: 'Server error updating profile.' });
    }
};

const changePassword = async (req, res) => {
    const { currentPassword, newPassword } = req.body;
    if (!currentPassword || !newPassword) return res.status(400).json({ success: false, error: 'Both passwords are required.' });

    try {
        const user = await User.findById(req.user.id);
        const isMatch = await bcrypt.compare(currentPassword, user.password);
        if (!isMatch) return res.status(401).json({ success: false, error: 'Incorrect current password.' });

        const salt = await bcrypt.genSalt(10);
        const hashedNewPassword = await bcrypt.hash(newPassword, salt);
        await User.updatePassword(req.user.id, hashedNewPassword);

        res.status(200).json({ success: true, message: 'Password updated successfully.' });
    } catch (error) {
        console.error('Change Password Error:', error);
        res.status(500).json({ success: false, error: 'Server error updating password.' });
    }
};

const resetPassword = async (req, res) => {
    const { email, newPassword } = req.body;
    if (!email || !newPassword) return res.status(400).json({ success: false, error: 'Email and new password are required.' });

    try {
        const salt = await bcrypt.genSalt(10);
        const hashedNewPassword = await bcrypt.hash(newPassword, salt);
        
        const affectedRows = await User.resetPasswordByEmail(email, hashedNewPassword);
        if (affectedRows === 0) return res.status(404).json({ success: false, error: 'No account found.' });

        res.status(200).json({ success: true, message: 'Password reset successfully.' });
    } catch (error) {
        console.error('Reset Password Error:', error);
        res.status(500).json({ success: false, error: 'Server error resetting password.' });
    }
};

const deleteAccount = async (req, res) => {
    try {
        await User.delete(req.user.id);
        res.status(200).json({ success: true, message: 'Account deleted successfully.' });
    } catch (error) {
        console.error('Delete Account Error:', error);
        res.status(500).json({ success: false, error: 'Server error deleting account.' });
    }
};

module.exports = { signup, login, getProfile, updateProfile, changePassword, resetPassword, deleteAccount };