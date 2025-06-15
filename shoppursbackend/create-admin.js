const mysql = require('mysql2');
const bcrypt = require('bcryptjs');
require('dotenv').config();

// Create a connection
const connection = mysql.createConnection({
  host: 'bysjhtucyklqdqiszive-mysql.services.clever-cloud.com',
  user: 'uh6qrnhqahuccwz1',
  password: '6yj0tnzmP0i7RyuD7aLp',
  database: 'bysjhtucyklqdqiszive',
  port: 3306
});

async function createAdminUser() {
  try {
    // Hash password
    const hashedPassword = await bcrypt.hash('admin123', 10);
    
    // Insert admin user
    const query = `
      INSERT INTO user_info (
        UL_ID, USERNAME, EMAIL, MOBILE, PASSWORD, CITY, PROVINCE, ZIP, ADDRESS, 
        CREATED_DATE, USER_TYPE, ISACTIVE, is_otp_verify
      ) VALUES (
        1, 'admin', 'admin@anwarfood.com', 9999999999, ?, 'Admin City', 'Admin Province', '000000', 'Admin Address', 
        NOW(), 'admin', 'Y', 1
      )
    `;
    
    connection.execute(query, [hashedPassword], (error, results) => {
      if (error) {
        console.error('Error creating admin user:', error);
        if (error.code === 'ER_DUP_ENTRY') {
          console.log('Admin user already exists!');
        }
      } else {
        console.log('Admin user created successfully!');
        console.log('Email: admin@anwarfood.com');
        console.log('Password: admin123');
        console.log('Mobile: 9999999999');
      }
      
      connection.end();
    });
  } catch (error) {
    console.error('Error:', error);
    connection.end();
  }
}

createAdminUser(); 