const jwt = require('jsonwebtoken');

const protect = async (req, res, next) => {
    let token;

    // 1. Check if the header exists and starts with 'Bearer'
    if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
        try {
            // 2. Extract the token
            token = req.headers.authorization.split(' ')[1];

            // 3. Verify the token using our secret key
            const decoded = jwt.verify(token, process.env.JWT_SECRET);

            // 4. Attach the user ID to the request so controllers can use it
            req.user = { id: decoded.id };

            // 5. Let them pass to the next function
            next();
        } catch (error) {
            console.error('🔒 JWT Error:', error.message);
            return res.status(401).json({ success: false, error: 'Session expired or invalid token.' });
        }
    }

    if (!token) {
        return res.status(401).json({ success: false, error: 'Not authorized, no token provided.' });
    }
};

module.exports = { protect };