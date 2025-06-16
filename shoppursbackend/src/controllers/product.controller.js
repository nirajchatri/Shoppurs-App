const { pool: db } = require('../config/database');

const getProductList = async (req, res) => {
  try {
    const [products] = await db.promise().query(`
      SELECT p.*, c.CATEGORY_NAME, sc.SUB_CATEGORY_NAME 
      FROM product_master p
      LEFT JOIN category c ON p.PROD_CAT_ID = c.CATEGORY_ID
      LEFT JOIN sub_category sc ON p.PROD_SUB_CAT_ID = sc.SUB_CATEGORY_ID
      WHERE p.DEL_STATUS IS NULL OR p.DEL_STATUS != 'Y'
    `);

    res.json({
      success: true,
      data: products
    });
  } catch (error) {
    console.error('Error fetching products:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching products',
      error: error.message
    });
  }
};

const getProductDetails = async (req, res) => {
  try {
    const { id } = req.params;

    const [products] = await db.promise().query(`
      SELECT p.*, c.CATEGORY_NAME, sc.SUB_CATEGORY_NAME,
      GROUP_CONCAT(pb.PRDB_BARCODE) as barcodes
      FROM product_master p
      LEFT JOIN category c ON p.PROD_CAT_ID = c.CATEGORY_ID
      LEFT JOIN sub_category sc ON p.PROD_SUB_CAT_ID = sc.SUB_CATEGORY_ID
      LEFT JOIN product_barcodes pb ON p.PROD_ID = pb.PRDB_PROD_ID
      WHERE p.PROD_ID = ? AND (p.DEL_STATUS IS NULL OR p.DEL_STATUS != 'Y')
      GROUP BY p.PROD_ID
    `, [id]);

    if (products.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Product not found'
      });
    }

    // Get only active product units
    const [units] = await db.promise().query(
      'SELECT * FROM product_unit WHERE PU_PROD_ID = ? AND PU_STATUS = "A"',
      [id]
    );

    const product = {
      ...products[0],
      units: units
    };

    res.json({
      success: true,
      data: product
    });
  } catch (error) {
    console.error('Error fetching product details:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching product details',
      error: error.message
    });
  }
};

const getProductsUnderCategory = async (req, res) => {
  try {
    const { categoryId } = req.params;

    // First verify if category exists
    const [categories] = await db.promise().query(
      'SELECT * FROM category WHERE CATEGORY_ID = ? AND DEL_STATUS != "Y"',
      [categoryId]
    );

    if (categories.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Category not found'
      });
    }

    // Get products under this category
    const [products] = await db.promise().query(`
      SELECT p.*, c.CATEGORY_NAME, sc.SUB_CATEGORY_NAME,
      GROUP_CONCAT(DISTINCT pu.PU_ID, ':', pu.PU_PROD_UNIT, ':', pu.PU_PROD_UNIT_VALUE, ':', pu.PU_PROD_RATE) as units
      FROM product_master p
      LEFT JOIN category c ON p.PROD_CAT_ID = c.CATEGORY_ID
      LEFT JOIN sub_category sc ON p.PROD_SUB_CAT_ID = sc.SUB_CATEGORY_ID
      LEFT JOIN product_unit pu ON p.PROD_ID = pu.PU_PROD_ID
      WHERE p.PROD_CAT_ID = ? AND (p.DEL_STATUS IS NULL OR p.DEL_STATUS != 'Y')
      GROUP BY p.PROD_ID
    `, [categoryId]);

    // Format the units data
    const formattedProducts = products.map(product => ({
      ...product,
      units: product.units
        ? product.units.split(',').map(unitStr => {
            const [unitId, unitName, unitValue, unitRate] = unitStr.split(':');
            return { 
              id: unitId, 
              name: unitName, 
              value: unitValue, 
              rate: unitRate 
            };
          })
        : []
    }));

    res.json({
      success: true,
      data: formattedProducts
    });
  } catch (error) {
    console.error('Error fetching products under category:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching products under category',
      error: error.message
    });
  }
};

const getProductsUnderSubCategory = async (req, res) => {
  try {
    const { subCategoryId } = req.params;

    // First verify if subcategory exists
    const [subCategories] = await db.promise().query(
      'SELECT * FROM sub_category WHERE SUB_CATEGORY_ID = ? AND DEL_STATUS != "Y"',
      [subCategoryId]
    );

    if (subCategories.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Sub-category not found'
      });
    }

    // Get products under this subcategory
    const [products] = await db.promise().query(`
      SELECT p.*, c.CATEGORY_NAME, sc.SUB_CATEGORY_NAME,
      GROUP_CONCAT(DISTINCT pu.PU_ID, ':', pu.PU_PROD_UNIT, ':', pu.PU_PROD_UNIT_VALUE, ':', pu.PU_PROD_RATE) as units
      FROM product_master p
      LEFT JOIN category c ON p.PROD_CAT_ID = c.CATEGORY_ID
      LEFT JOIN sub_category sc ON p.PROD_SUB_CAT_ID = sc.SUB_CATEGORY_ID
      LEFT JOIN product_unit pu ON p.PROD_ID = pu.PU_PROD_ID
      WHERE p.PROD_SUB_CAT_ID = ? AND (p.DEL_STATUS IS NULL OR p.DEL_STATUS != 'Y')
      GROUP BY p.PROD_ID
    `, [subCategoryId]);

    // Format the units data
    const formattedProducts = products.map(product => ({
      ...product,
      units: product.units
        ? product.units.split(',').map(unitStr => {
            const [unitId, unitName, unitValue, unitRate] = unitStr.split(':');
            return { 
              id: unitId, 
              name: unitName, 
              value: unitValue, 
              rate: unitRate 
            };
          })
        : []
    }));

    res.json({
      success: true,
      data: formattedProducts,
      count: formattedProducts.length
    });
  } catch (error) {
    console.error('Error fetching products under sub-category:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching products under sub-category',
      error: error.message
    });
  }
};

// Debug function to check units for a product
const getProductUnits = async (req, res) => {
  try {
    const { productId } = req.params;

    // Check if product exists
    const [products] = await db.promise().query(
      'SELECT PROD_ID, PROD_NAME FROM product_master WHERE PROD_ID = ?',
      [productId]
    );

    if (products.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Product not found'
      });
    }

    // Get all units for this product
    const [units] = await db.promise().query(
      'SELECT * FROM product_unit WHERE PU_PROD_ID = ?',
      [productId]
    );

    res.json({
      success: true,
      product: products[0],
      units: units
    });
  } catch (error) {
    console.error('Error fetching product units:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching product units',
      error: error.message
    });
  }
};

const searchProducts = async (req, res) => {
  try {
    const { query, subcategory } = req.query;

    if (!query) {
      return res.status(400).json({
        success: false,
        message: 'Search query is required'
      });
    }

    // Build the base query
    let baseQuery = `
      SELECT p.*, c.CATEGORY_NAME, sc.SUB_CATEGORY_NAME,
      GROUP_CONCAT(DISTINCT pu.PU_ID, ':', pu.PU_PROD_UNIT, ':', pu.PU_PROD_UNIT_VALUE, ':', pu.PU_PROD_RATE) as units
      FROM product_master p
      LEFT JOIN category c ON p.PROD_CAT_ID = c.CATEGORY_ID
      LEFT JOIN sub_category sc ON p.PROD_SUB_CAT_ID = sc.SUB_CATEGORY_ID
      LEFT JOIN product_unit pu ON p.PROD_ID = pu.PU_PROD_ID
      WHERE p.PROD_NAME LIKE ?
      AND (p.DEL_STATUS = 'A' OR p.DEL_STATUS IS NULL)
    `;

    // Parameters for the query
    let queryParams = [`%${query}%`];

    // Add subcategory filter if provided
    if (subcategory) {
      baseQuery += ` AND p.PROD_SUB_CAT_ID = ?`;
      queryParams.push(subcategory);
    }

    // Complete the query with GROUP BY and ORDER BY
    baseQuery += `
      GROUP BY p.PROD_ID
      ORDER BY 
        CASE 
          WHEN p.PROD_NAME LIKE ? THEN 1
          WHEN p.PROD_NAME LIKE ? THEN 2
          ELSE 3
        END,
        p.PROD_NAME ASC
    `;

    // Add the ordering parameters
    queryParams.push(`${query}%`, `%${query}%`);

    // Execute the search query
    const [products] = await db.promise().query(baseQuery, queryParams);

    // Format the units data
    const formattedProducts = products.map(product => ({
      ...product,
      units: product.units
        ? product.units.split(',').map(unitStr => {
            const [unitId, unitName, unitValue, unitRate] = unitStr.split(':');
            return { 
              id: unitId, 
              name: unitName, 
              value: unitValue, 
              rate: unitRate 
            };
          })
        : []
    }));

    res.json({
      success: true,
      data: formattedProducts,
      count: formattedProducts.length,
      filters: {
        query: query,
        subcategory: subcategory || null
      }
    });
  } catch (error) {
    console.error('Error searching products:', error);
    res.status(500).json({
      success: false,
      message: 'Error searching products',
      error: error.message
    });
  }
};

const getProductIdByBarcode = async (req, res) => {
  try {
    const { PRDB_BARCODE } = req.body;

    // Validate input
    if (!PRDB_BARCODE) {
      return res.status(400).json({
        success: false,
        message: 'Barcode is required'
      });
    }

    // Find product using barcode
    const [barcodeResults] = await db.promise().query(
      'SELECT PRDB_PROD_ID FROM product_barcodes WHERE PRDB_BARCODE = ? AND SOLD_STATUS = "A"',
      [PRDB_BARCODE]
    );

    if (barcodeResults.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Product not found with this barcode or barcode is not active'
      });
    }

    const productId = barcodeResults[0].PRDB_PROD_ID;

    // Verify product exists and is not deleted
    const [products] = await db.promise().query(
      'SELECT PROD_ID, PROD_NAME FROM product_master WHERE PROD_ID = ? AND (DEL_STATUS IS NULL OR DEL_STATUS != "Y")',
      [productId]
    );

    if (products.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Product not found or deleted'
      });
    }

    res.json({
      success: true,
      message: 'Product found successfully',
      data: {
        barcode: PRDB_BARCODE,
        productId: productId,
        productName: products[0].PROD_NAME
      }
    });
  } catch (error) {
    console.error('Get product ID by barcode error:', error);
    res.status(500).json({
      success: false,
      message: 'Error finding product by barcode',
      error: error.message
    });
  }
};

module.exports = {
  getProductList,
  getProductDetails,
  getProductsUnderCategory,
  getProductsUnderSubCategory,
  getProductUnits,
  searchProducts,
  getProductIdByBarcode
}; 