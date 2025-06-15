# Image Upload Middleware Guide

This document explains how to use the three image upload middlewares created for the AnwarFood backend.

## 📁 Folder Structure

```
uploads/
├── retailers/
│   ├── profiles/     # Retailer profile images
│   └── barcodes/     # Retailer barcode images
└── products/         # Product images
```

## 🔧 Middleware Overview

### 1. Retailer Profile Upload
- **Middleware**: `retailerProfileUpload`
- **Field Name**: `profileImage`
- **File Limit**: 1 file
- **Size Limit**: 5MB
- **Storage**: `./uploads/retailers/profiles/`
- **Filename Format**: `retailer_profile_{timestamp}_{random}.{ext}`

### 2. Retailer Barcode Upload
- **Middleware**: `retailerBarcodeUpload`
- **Field Name**: `barcodeImage`
- **File Limit**: 1 file
- **Size Limit**: 5MB
- **Storage**: `./uploads/retailers/barcodes/`
- **Filename Format**: `retailer_barcode_{timestamp}_{random}.{ext}`

### 3. Product Images Upload
- **Middleware**: `productImagesUpload`
- **Field Name**: `productImages`
- **File Limit**: 3 files
- **Size Limit**: 5MB per file
- **Storage**: `./uploads/products/`
- **Filename Format**: `product_{timestamp}_{random}.{ext}`

## 🚀 Usage Examples

### Import Middlewares
```javascript
const { 
  retailerProfileUpload, 
  retailerBarcodeUpload, 
  productImagesUpload 
} = require('../middleware/upload.middleware');
```

### Using in Routes

#### Retailer Profile Upload
```javascript
router.post('/upload-profile', authMiddleware, retailerProfileUpload, (req, res) => {
  // Access uploaded file via req.uploadedFile
  const fileInfo = req.uploadedFile;
  // fileInfo contains: path, filename, originalname, size
});
```

#### Retailer Barcode Upload
```javascript
router.post('/upload-barcode', authMiddleware, retailerBarcodeUpload, (req, res) => {
  // Access uploaded file via req.uploadedFile
  const fileInfo = req.uploadedFile;
});
```

#### Product Images Upload
```javascript
router.post('/upload-images', authMiddleware, productImagesUpload, (req, res) => {
  // Access uploaded files via req.uploadedFiles (array)
  const filesInfo = req.uploadedFiles;
  // Each file contains: path, filename, originalname, size
});
```

## 📋 API Endpoints

### 1. Upload Retailer Profile Image
- **URL**: `POST /api/retailers/upload-profile`
- **Headers**: `Authorization: Bearer {token}`
- **Body**: `form-data` with key `profileImage`
- **Response**:
```json
{
  "success": true,
  "message": "Profile image uploaded successfully",
  "data": {
    "filename": "retailer_profile_1703123456789-123456789.jpg",
    "path": "./uploads/retailers/profiles/retailer_profile_1703123456789-123456789.jpg",
    "url": "http://localhost:3000/uploads/retailers/profiles/retailer_profile_1703123456789-123456789.jpg",
    "originalname": "profile.jpg",
    "size": 245760
  }
}
```

### 2. Upload Retailer Barcode Image
- **URL**: `POST /api/retailers/upload-barcode`
- **Headers**: `Authorization: Bearer {token}`
- **Body**: `form-data` with key `barcodeImage`
- **Response**: Similar to profile upload

### 3. Upload Product Images
- **URL**: `POST /api/products/upload-images`
- **Headers**: `Authorization: Bearer {token}`
- **Body**: `form-data` with key `productImages` (can select multiple files)
- **Response**:
```json
{
  "success": true,
  "message": "3 product image(s) uploaded successfully",
  "data": {
    "images": [
      {
        "filename": "product_1703123456789-123456789.jpg",
        "path": "./uploads/products/product_1703123456789-123456789.jpg",
        "url": "http://localhost:3000/uploads/products/product_1703123456789-123456789.jpg",
        "originalname": "product1.jpg",
        "size": 245760
      }
    ],
    "count": 3
  }
}
```

## 🔒 Security Features

1. **File Type Validation**: Only image files are allowed
2. **File Size Limits**: Maximum 5MB per file
3. **File Count Limits**: 
   - Profile/Barcode: 1 file
   - Products: 3 files maximum
4. **Unique Filenames**: Prevents filename conflicts
5. **Authentication Required**: All endpoints require valid JWT token

## ⚠️ Error Responses

### File Size Too Large
```json
{
  "success": false,
  "message": "File size too large. Maximum size is 5MB."
}
```

### Invalid File Type
```json
{
  "success": false,
  "message": "Only image files are allowed!"
}
```

### Too Many Files
```json
{
  "success": false,
  "message": "Too many files. Maximum 3 product images are allowed."
}
```

### No File Uploaded
```json
{
  "success": false,
  "message": "No profile image uploaded"
}
```

## 🌐 Accessing Uploaded Images

Images are served as static files and can be accessed via:
- **Base URL**: `http://localhost:3000/uploads/`
- **Profile Images**: `http://localhost:3000/uploads/retailers/profiles/{filename}`
- **Barcode Images**: `http://localhost:3000/uploads/retailers/barcodes/{filename}`
- **Product Images**: `http://localhost:3000/uploads/products/{filename}`

## 💡 Integration Tips

### Save to Database
After successful upload, save the file information to your database:

```javascript
// For single file
const profileImagePath = req.uploadedFile.filename;
await db.query('UPDATE retailers SET profile_image = ? WHERE id = ?', [profileImagePath, retailerId]);

// For multiple files
const imagePaths = req.uploadedFiles.map(file => file.filename);
await db.query('UPDATE products SET images = ? WHERE id = ?', [JSON.stringify(imagePaths), productId]);
```

### Frontend Usage (React/HTML)
```html
<!-- Single file upload -->
<form enctype="multipart/form-data">
  <input type="file" name="profileImage" accept="image/*" />
  <button type="submit">Upload Profile</button>
</form>

<!-- Multiple files upload -->
<form enctype="multipart/form-data">
  <input type="file" name="productImages" accept="image/*" multiple max="3" />
  <button type="submit">Upload Product Images</button>
</form>
```

### Postman Testing
1. Set method to POST
2. Add `Authorization` header with Bearer token
3. In Body tab, select `form-data`
4. Add key with the correct field name (`profileImage`, `barcodeImage`, or `productImages`)
5. Set type to `File` and select your image file(s)

## 🛠️ Customization

To modify the middleware behavior, edit `src/middleware/upload.middleware.js`:

- Change file size limits in the `limits` object
- Modify storage paths in the destination functions
- Update filename patterns in the filename functions
- Add additional file type validations in `imageFilter`

## 📱 Mobile App Integration

For mobile apps, ensure:
1. Set proper `Content-Type: multipart/form-data` header
2. Include JWT token in Authorization header
3. Use the correct field names for form data
4. Handle progress indicators for large uploads

The middlewares are production-ready and include comprehensive error handling for robust file upload functionality! 