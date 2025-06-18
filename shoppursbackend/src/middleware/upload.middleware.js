const multer = require('multer');
const path = require('path');
const fs = require('fs');

// Ensure upload directories exist
const createDirectory = (dirPath) => {
  if (!fs.existsSync(dirPath)) {
    fs.mkdirSync(dirPath, { recursive: true });
  }
};

// Create upload directories
createDirectory('./uploads/retailers/profiles');
createDirectory('./uploads/retailers/barcodes');
createDirectory('./uploads/products');
createDirectory('./uploads/orders'); // Add orders directory
createDirectory('./uploads/users/profiles'); // Add users profiles directory

// File filter function for images
const imageFilter = (req, file, cb) => {
  // Check if file is an image
  if (file.mimetype.startsWith('image/')) {
    cb(null, true);
  } else {
    cb(new Error('Only image files are allowed!'), false);
  }
};

// Storage configuration for retailer profile images
const retailerProfileStorage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, './uploads/retailers/profiles');
  },
  filename: (req, file, cb) => {
    // Generate unique filename: retailer_profile_timestamp_originalname
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    const extension = path.extname(file.originalname);
    cb(null, `retailer_profile_${uniqueSuffix}${extension}`);
  }
});

// Storage configuration for retailer barcode images
const retailerBarcodeStorage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, './uploads/retailers/barcodes');
  },
  filename: (req, file, cb) => {
    // Generate unique filename: retailer_barcode_timestamp_originalname
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    const extension = path.extname(file.originalname);
    cb(null, `retailer_barcode_${uniqueSuffix}${extension}`);
  }
});

// Storage configuration for product images
const productImageStorage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, './uploads/products');
  },
  filename: (req, file, cb) => {
    // Generate unique filename: product_timestamp_originalname
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    const extension = path.extname(file.originalname);
    cb(null, `product_${uniqueSuffix}${extension}`);
  }
});

// Storage configuration for order payment images
const orderPaymentStorage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, './uploads/orders');
  },
  filename: (req, file, cb) => {
    // Generate unique filename: payment_timestamp_originalname
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    const extension = path.extname(file.originalname);
    cb(null, `payment_${uniqueSuffix}${extension}`);
  }
});

// Storage configuration for user profile images
const userProfileStorage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, './uploads/users/profiles');
  },
  filename: (req, file, cb) => {
    // Generate unique filename: user_profile_timestamp_originalname
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    const extension = path.extname(file.originalname);
    cb(null, `user_profile_${uniqueSuffix}${extension}`);
  }
});

// Multer upload configurations
const uploadRetailerProfile = multer({
  storage: retailerProfileStorage,
  fileFilter: imageFilter,
  limits: {
    fileSize: 5 * 1024 * 1024, // 5MB limit
    files: 1 // Only one profile image
  }
}).single('profileImage'); // Field name: profileImage

const uploadRetailerBarcode = multer({
  storage: retailerBarcodeStorage,
  fileFilter: imageFilter,
  limits: {
    fileSize: 5 * 1024 * 1024, // 5MB limit
    files: 1 // Only one barcode image
  }
}).single('barcodeImage'); // Field name: barcodeImage

const uploadProductImages = multer({
  storage: productImageStorage,
  fileFilter: imageFilter,
  limits: {
    fileSize: 5 * 1024 * 1024, // 5MB limit per file
    files: 3 // Maximum 3 product images
  }
}).fields([
  { name: 'prodImage1', maxCount: 1 },
  { name: 'prodImage2', maxCount: 1 },
  { name: 'prodImage3', maxCount: 1 }
]);

const uploadOrderPayment = multer({
  storage: orderPaymentStorage,
  fileFilter: imageFilter,
  limits: {
    fileSize: 5 * 1024 * 1024, // 5MB limit
    files: 1 // Only one payment image
  }
}).single('paymentImage'); // Field name: paymentImage

const uploadUserProfile = multer({
  storage: userProfileStorage,
  fileFilter: imageFilter,
  limits: {
    fileSize: 5 * 1024 * 1024, // 5MB limit
    files: 1 // Only one profile image
  }
}).single('profilePhoto'); // Field name: profilePhoto

// Middleware wrapper functions with error handling
const retailerProfileUpload = (req, res, next) => {
  uploadRetailerProfile(req, res, (err) => {
    if (err instanceof multer.MulterError) {
      if (err.code === 'LIMIT_FILE_SIZE') {
        return res.status(400).json({
          success: false,
          message: 'File size too large. Maximum size is 5MB.'
        });
      }
      if (err.code === 'LIMIT_FILE_COUNT') {
        return res.status(400).json({
          success: false,
          message: 'Too many files. Only one profile image is allowed.'
        });
      }
      return res.status(400).json({
        success: false,
        message: 'File upload error: ' + err.message
      });
    } else if (err) {
      return res.status(400).json({
        success: false,
        message: err.message
      });
    }
    
    // Add file path to request object for database storage
    if (req.file) {
      req.uploadedFile = {
        path: req.file.path,
        filename: req.file.filename,
        originalname: req.file.originalname,
        size: req.file.size
      };
    }
    
    next();
  });
};

const retailerBarcodeUpload = (req, res, next) => {
  uploadRetailerBarcode(req, res, (err) => {
    if (err instanceof multer.MulterError) {
      if (err.code === 'LIMIT_FILE_SIZE') {
        return res.status(400).json({
          success: false,
          message: 'File size too large. Maximum size is 5MB.'
        });
      }
      if (err.code === 'LIMIT_FILE_COUNT') {
        return res.status(400).json({
          success: false,
          message: 'Too many files. Only one barcode image is allowed.'
        });
      }
      return res.status(400).json({
        success: false,
        message: 'File upload error: ' + err.message
      });
    } else if (err) {
      return res.status(400).json({
        success: false,
        message: err.message
      });
    }
    
    // Add file path to request object for database storage
    if (req.file) {
      req.uploadedFile = {
        path: req.file.path,
        filename: req.file.filename,
        originalname: req.file.originalname,
        size: req.file.size
      };
    }
    
    next();
  });
};

const productImagesUpload = (req, res, next) => {
  uploadProductImages(req, res, (err) => {
    if (err instanceof multer.MulterError) {
      if (err.code === 'LIMIT_FILE_SIZE') {
        return res.status(400).json({
          success: false,
          message: 'File size too large. Maximum size is 5MB per image.'
        });
      }
      if (err.code === 'LIMIT_FILE_COUNT') {
        return res.status(400).json({
          success: false,
          message: 'Too many files. Maximum 3 product images are allowed.'
        });
      }
      return res.status(400).json({
        success: false,
        message: 'File upload error: ' + err.message
      });
    } else if (err) {
      return res.status(400).json({
        success: false,
        message: err.message
      });
    }
    
    // Add file paths to request object for database storage
    if (req.files) {
      req.uploadedFiles = {
        prodImage1: req.files.prodImage1 ? req.files.prodImage1[0].filename : null,
        prodImage2: req.files.prodImage2 ? req.files.prodImage2[0].filename : null,
        prodImage3: req.files.prodImage3 ? req.files.prodImage3[0].filename : null
      };
    }
    
    next();
  });
};

const orderPaymentUpload = (req, res, next) => {
  uploadOrderPayment(req, res, (err) => {
    if (err instanceof multer.MulterError) {
      if (err.code === 'LIMIT_FILE_SIZE') {
        return res.status(400).json({
          success: false,
          message: 'File size too large. Maximum size is 5MB.'
        });
      }
      if (err.code === 'LIMIT_FILE_COUNT') {
        return res.status(400).json({
          success: false,
          message: 'Too many files. Only one payment image is allowed.'
        });
      }
      return res.status(400).json({
        success: false,
        message: 'File upload error: ' + err.message
      });
    } else if (err) {
      return res.status(400).json({
        success: false,
        message: err.message
      });
    }
    
    // Add file path to request object for database storage
    if (req.file) {
      req.uploadedFile = {
        path: req.file.path,
        filename: req.file.filename,
        originalname: req.file.originalname,
        size: req.file.size
      };
    }
    
    next();
  });
};

const userProfileUpload = (req, res, next) => {
  uploadUserProfile(req, res, (err) => {
    if (err instanceof multer.MulterError) {
      if (err.code === 'LIMIT_FILE_SIZE') {
        return res.status(400).json({
          success: false,
          message: 'File size too large. Maximum size is 5MB.'
        });
      }
      if (err.code === 'LIMIT_FILE_COUNT') {
        return res.status(400).json({
          success: false,
          message: 'Too many files. Only one profile photo is allowed.'
        });
      }
      return res.status(400).json({
        success: false,
        message: 'File upload error: ' + err.message
      });
    } else if (err) {
      return res.status(400).json({
        success: false,
        message: err.message
      });
    }
    
    // Add file path to request object for database storage
    if (req.file) {
      req.uploadedFile = {
        path: req.file.path,
        filename: req.file.filename,
        originalname: req.file.originalname,
        size: req.file.size
      };
    }
    
    next();
  });
};

module.exports = {
  retailerProfileUpload,
  retailerBarcodeUpload,
  productImagesUpload,
  orderPaymentUpload,
  userProfileUpload
}; 