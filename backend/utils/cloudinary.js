const cloudinary = require('cloudinary').v2;
const { CloudinaryStorage } = require('multer-storage-cloudinary');
const multer = require('multer');
require('dotenv').config();

// Configure Cloudinary
cloudinary.config({
    cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
    api_key: process.env.CLOUDINARY_API_KEY,
    api_secret: process.env.CLOUDINARY_API_SECRET
});

// Configure Multer Storage engine to use Cloudinary
const storage = new CloudinaryStorage({
    cloudinary: cloudinary,
    params: {
        folder: 'lootlo_items', // The folder name inside your Cloudinary dashboard
        allowed_formats: ['jpg', 'jpeg', 'png', 'webp'],
        transformation: [{ width: 800, height: 800, crop: 'limit' }] // Compresses large mobile photos!
    }
});

const upload = multer({ storage: storage });

module.exports = { cloudinary, upload };