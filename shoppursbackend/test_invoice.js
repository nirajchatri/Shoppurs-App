const { generateInvoicePDF } = require('./src/utils/invoiceGenerator');

// Test data
const testOrder = {
  ORDER_NUMBER: 'TEST001',
  ORDER_TOTAL: 1500.00,
  CREATED_DATE: new Date(),
  USERNAME: 'John Doe',
  MOBILE: '9999999999'
};

const testOrderItems = [
  {
    PROD_NAME: 'Premium Cotton T-Shirt',
    QUANTITY: 2,
    TOTAL_PRICE: 800.00,
    PROD_HSN_CODE: '6204',
    PROD_MRP: 500.00,
    PROD_SP: 400.00,
    PROD_CGST: 6,
    PROD_SGST: 6,
    PROD_IGST: 0
  },
  {
    PROD_NAME: 'Denim Jeans',
    QUANTITY: 1,
    TOTAL_PRICE: 700.00,
    PROD_HSN_CODE: '6203',
    PROD_MRP: 850.00,
    PROD_SP: 700.00,
    PROD_CGST: 6,
    PROD_SGST: 6,
    PROD_IGST: 0
  }
];

async function testInvoiceGeneration() {
  try {
    console.log('Testing invoice generation with app_settings data...');
    
    const filePath = await generateInvoicePDF({
      order: testOrder,
      orderItems: testOrderItems,
      invoiceNumber: 'TEST001'
    });
    
    console.log('✅ Invoice generated successfully!');
    console.log('📁 File saved at:', filePath);
    
  } catch (error) {
    console.error('❌ Error generating invoice:', error.message);
    console.error('Stack trace:', error.stack);
  }
}

testInvoiceGeneration(); 