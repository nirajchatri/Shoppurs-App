const { pool: db } = require('../config/database');

const getCategoryList = async (req, res) => {
  try {
    const [categories] = await db.promise().query(`
      SELECT c.*, 
      GROUP_CONCAT(sc.SUB_CATEGORY_ID, ':', sc.SUB_CATEGORY_NAME) as sub_categories
      FROM category c
      LEFT JOIN sub_category sc ON c.CATEGORY_ID = sc.SUB_CATEGORY_CAT_ID
      WHERE c.DEL_STATUS != 'Y'
      GROUP BY c.CATEGORY_ID
    `);

    // Format sub-categories
    const formattedCategories = categories.map(category => ({
      ...category,
      sub_categories: category.sub_categories
        ? category.sub_categories.split(',').map(sub => {
            const [id, name] = sub.split(':');
            return { id, name };
          })
        : []
    }));

    res.json({
      success: true,
      data: formattedCategories
    });
  } catch (error) {
    console.error('Error fetching categories:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching categories',
      error: error.message
    });
  }
};

const getSubCategoriesByCategoryId = async (req, res) => {
  try {
    const { categoryId } = req.params;

    console.log('Received categoryId:', categoryId, 'Type:', typeof categoryId);

    if (!categoryId) {
      return res.status(400).json({
        success: false,
        message: 'Category ID is required'
      });
    }

    // Check what tables exist in the database
    const [tables] = await db.promise().query('SHOW TABLES');
    console.log('Available tables in database:', tables);

    // Test query to see all subcategories first
    const [allSubCategories] = await db.promise().query('SELECT * FROM sub_category LIMIT 5');
    console.log('Sample subcategories from database:', allSubCategories);

    const query = `
      SELECT 
        SUB_CATEGORY_ID,
        SUB_CATEGORY_NAME,
        SUB_CATEGORY_CAT_ID,
        SUB_CAT_IMAGE,
        DEL_STATUS,
        CREATED_BY,
        UPDATED_BY,
        CREATED_DATE,
        UPDATED_DATE
      FROM sub_category 
      WHERE SUB_CATEGORY_CAT_ID = ? 
      ORDER BY SUB_CATEGORY_NAME ASC
    `;

    console.log('Executing query:', query);
    console.log('With parameter:', [categoryId]);

    const [subCategories] = await db.promise().query(query, [categoryId]);

    console.log('Query result:', subCategories);
    console.log('Number of results:', subCategories.length);

    res.json({
      success: true,
      data: subCategories,
      count: subCategories.length
    });
  } catch (error) {
    console.error('Error fetching sub-categories:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching sub-categories',
      error: error.message
    });
  }
};

module.exports = {
  getCategoryList,
  getSubCategoriesByCategoryId
}; 