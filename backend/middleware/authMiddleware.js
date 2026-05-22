const jwt = require('jsonwebtoken');

const protect = async (req, res, next) => {
    let token;

    // Check if authorization header exists and starts with 'Bearer'
    if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
        try {
            // Split 'Bearer <token>' to extract the actual token string
            token = req.headers.authorization.split(' ')[1];

            // Verify the token cryptographically
            const decoded = jwt.verify(token, process.env.JWT_SECRET);

            // Attach the decoded user ID to the request object so downstream routes can use it
            req.user = { id: decoded.id };

            // Move on to the actual controller function
            next();
        } catch (error) {
            console.error('JWT Verification Error:', error.message);
            return res.status(401).json({ error: 'Not authorized, token failed' });
        }
    }

    if (!token) {
        return res.status(401).json({ error: 'Not authorized, no token provided' });
    }
};

module.exports = { protect };