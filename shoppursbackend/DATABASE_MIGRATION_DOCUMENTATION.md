# Database Migration Documentation: Orders to Cust_Order

## Overview
Successfully migrated the entire backend system from using `orders` and `order_items` tables to the new `cust_order` and `cust_order_details` tables. This migration enhances the order management system with more comprehensive customer and retailer tracking capabilities.

## Table Schema Mapping

### Old Schema → New Schema

#### orders → cust_order
| Old Field | New Field | Notes |
|-----------|-----------|-------|
| ORDER_ID | CO_ID | Primary key |
| ORDER_NUMBER | CO_NO | Order number/reference |
| USER_ID | CO_CUST_CODE | Customer identifier (now mobile number) |
| ORDER_TOTAL | CO_TOTAL_AMT | Total order amount |
| ORDER_STATUS | CO_STATUS | Order status |
| DELIVERY_ADDRESS | CO_DELIVERY_ADDRESS | Delivery address |
| DELIVERY_CITY | CO_DELIVERY_CITY | Delivery city |
| DELIVERY_STATE | CO_DELIVERY_STATE | Delivery state |
| DELIVERY_COUNTRY | CO_DELIVERY_COUNTRY | Delivery country |
| DELIVERY_PINCODE | CO_PINCODE | Delivery pincode |
| PAYMENT_METHOD | CO_PAYMENT_MODE | Payment method |
| ORDER_NOTES | CO_DELIVERY_NOTE | Order/delivery notes |
| PAYMENT_IMAGE | CO_IMAGE | Payment receipt image |
| CREATED_DATE | CREATED_DATE | Creation timestamp |
| UPDATED_DATE | UPDATED_DATE | Last update timestamp |
| CREATED_BY | CREATED_BY | Created by user ID |
| UPDATED_BY | UPDATED_BY | Updated by user ID |

#### Additional Fields in cust_order:
- `CO_TRANS_ID` - Transaction ID
- `CO_DATE` - Order date
- `CO_DELIVERY_MODE` - Delivery mode (e.g., 'delivery')
- `CO_RET_ID` - Associated retailer ID
- `CO_CUST_NAME` - Customer name
- `CO_CUST_MOBILE` - Customer mobile number
- `CO_DELIVERY_LAT`, `CO_DELIVERY_LONG` - Delivery coordinates
- `CO_TOTAL_QTY` - Total quantity of items
- `CO_COUPON_CODE` - Applied coupon code
- `CO_PAYMENT_STATUS` - Payment status
- `CO_DELIVER_BY` - Delivery person
- `CO_RATINGS_BY_CUST` - Customer ratings
- `CO_CUST_REMARKS` - Customer remarks
- `CO_TYPE` - Order type (e.g., 'mobile', 'employee')

#### order_items → cust_order_details
| Old Field | New Field | Notes |
|-----------|-----------|-------|
| ORDER_ITEM_ID | COD_ID | Primary key |
| ORDER_ID | COD_CO_ID | Foreign key to cust_order |
| PROD_ID | PROD_ID | Product ID |
| UNIT_ID | - | Replaced by PROD_UNIT |
| QUANTITY | COD_QTY | Item quantity |
| UNIT_PRICE | PROD_SP | Selling price |
| TOTAL_PRICE | - | Calculated as COD_QTY * PROD_SP |

#### Additional Fields in cust_order_details:
- `PROD_NAME` - Product name
- `PROD_BARCODE` - Product barcode
- `PROD_DESC` - Product description
- `PROD_MRP` - Maximum retail price
- `PROD_CGST` - Central GST
- `PROD_IGST` - Integrated GST
- `PROD_SGST` - State GST
- `PROD_IMAGE_1`, `PROD_IMAGE_2`, `PROD_IMAGE_3` - Product images
- `PROD_CODE` - Product code
- `PROD_UNIT` - Product unit
- `IS_BARCODE_AVAILABLE` - Barcode availability flag

## Files Modified

### 1. Order Controller (`src/controllers/order.controller.js`)
**Changes Made:**
- Updated `getOrderList()` to query `cust_order` and `cust_order_details`
- Modified customer identification to use mobile number instead of user ID
- Updated `getOrderDetails()` to use new table structure
- Modified `cancelOrder()` to work with new schema
- Updated `searchOrders()` to search by customer mobile and order number

**Key Changes:**
```sql
-- Old Query
SELECT * FROM orders WHERE USER_ID = ?

-- New Query  
SELECT co.* FROM cust_order co WHERE co.CO_CUST_MOBILE = ?
```

### 2. Cart Controller (`src/controllers/cart.controller.js`)
**Changes Made:**
- Completely overhauled `placeOrder()` function
- Added customer mobile and name retrieval
- Enhanced product details collection (barcode, images, GST info)
- Implemented retailer association logic
- Added transaction ID generation
- Updated order creation to populate all new fields

**Key Enhancements:**
- Now stores complete product information in order details
- Associates orders with retailers based on customer mobile
- Calculates total quantity automatically
- Supports order type classification

### 3. Employee Controller (`src/controllers/employee.controller.js`)
**Changes Made:**
- Updated `fetchOrders()` to use new table structure
- Modified `searchOrders()` to search by customer mobile
- Updated `getOrderDetails()` with new field mappings
- Overhauled `updateOrderStatus()` function
- Updated `placeOrderForCustomer()` for employee-placed orders
- Modified invoice generation queries

**Key Features:**
- Employee orders now properly tagged with CO_TYPE = 'employee'
- Enhanced order tracking and status management
- Improved customer identification via mobile numbers

### 4. Admin Controller (`src/controllers/admin.controller.js`)
**Changes Made:**
- Updated `fetchAllOrders()` with pagination and filtering
- Modified `editOrderStatus()` to use new schema
- Updated `getOrderDetails()` for admin view
- Enhanced `searchOrders()` functionality
- Updated `fetchEmployeeOrders()` for employee tracking

**Admin Features:**
- Comprehensive order management dashboard
- Advanced filtering and search capabilities
- Employee order tracking
- Enhanced order status management

### 5. Retailer Controller (`src/controllers/retailer.controller.js`)
**Changes Made:**
- Updated `getRetailerByUserMobile()` analytics queries
- Modified `getRetailerByIdAdmin()` statistics
- Updated sales analytics to use new table structure
- Enhanced dashboard data for mobile-based customer tracking

**Analytics Features:**
- Sales summary calculations
- Monthly and daily sales graphs
- Top selling products analysis
- Recent orders tracking
- All now based on customer mobile numbers

## Key Architectural Changes

### 1. Customer Identification
- **Before:** Orders linked to users via USER_ID
- **After:** Orders linked to customers via mobile number (CO_CUST_MOBILE)
- **Benefit:** Better customer tracking across different user accounts

### 2. Product Information Storage
- **Before:** Minimal product info in order_items, relied on JOINs
- **After:** Complete product snapshot stored in cust_order_details
- **Benefit:** Historical accuracy, no data loss if products change

### 3. Order Enrichment
- **Before:** Basic order information
- **After:** Comprehensive order details including:
  - Retailer association
  - Customer details
  - Delivery coordinates
  - Order classification
  - Enhanced payment tracking

### 4. Invoice Generation
- **Before:** Simple invoice with basic order info
- **After:** Enhanced invoices with complete product details and GST information

## Benefits of the Migration

### 1. Enhanced Data Integrity
- Complete product information preserved at order time
- Customer details snapshot prevents data loss
- Better audit trail with comprehensive tracking

### 2. Improved Analytics
- Mobile-based customer tracking
- Better sales analytics for retailers
- Enhanced dashboard capabilities
- Improved product performance tracking

### 3. Better Business Intelligence
- Retailer association with orders
- Customer behavior tracking
- Geographic delivery insights
- Enhanced reporting capabilities

### 4. Scalability
- More flexible customer identification
- Support for multiple order types
- Enhanced payment tracking
- Better integration capabilities

## Testing Recommendations

### 1. Order Placement Testing
- Test order placement from mobile app
- Verify employee-placed orders
- Check retailer association logic
- Validate product information storage

### 2. Order Management Testing
- Test order status updates
- Verify search functionality
- Check order cancellation
- Test invoice generation

### 3. Analytics Testing
- Verify retailer dashboard data
- Test admin analytics
- Check employee order tracking
- Validate sales calculations

### 4. Data Migration Testing
If migrating existing data:
- Map old orders to new structure
- Preserve customer relationships
- Maintain order history
- Verify data integrity

## API Compatibility

### Maintained Endpoints
All existing API endpoints remain functional with the same request/response formats:
- `GET /api/orders` - Order listing
- `GET /api/orders/:id` - Order details
- `POST /api/cart/place-order` - Order placement
- `PUT /api/orders/:id/status` - Status updates

### Enhanced Responses
Response payloads now include additional fields where beneficial:
- Customer mobile numbers
- Enhanced product details
- Retailer information
- Additional order metadata

## Future Enhancements

### 1. Recommended Additions
- Add CO_INVOICE_URL field to cust_order table
- Implement order rating system
- Add delivery tracking capabilities
- Enhance customer communication features

### 2. Performance Optimizations
- Add indexes on CO_CUST_MOBILE
- Add indexes on CO_STATUS and CREATED_DATE
- Consider partitioning for large datasets
- Implement caching for analytics queries

## Deployment Checklist

### Pre-Deployment
- [ ] Backup existing database
- [ ] Test all API endpoints
- [ ] Verify mobile app compatibility
- [ ] Test admin panel functionality

### Post-Deployment
- [ ] Monitor error logs
- [ ] Verify order placement functionality
- [ ] Check analytics dashboard
- [ ] Validate invoice generation

### Rollback Plan
If issues arise:
1. Restore database backup
2. Revert code changes
3. Clear application caches
4. Notify stakeholders

## Conclusion

The migration from `orders`/`order_items` to `cust_order`/`cust_order_details` represents a significant improvement in the order management system. The new structure provides:

- Better data integrity and historical preservation
- Enhanced customer tracking capabilities
- Improved analytics and business intelligence
- Greater scalability and flexibility
- Comprehensive audit trails

The system is now better positioned to support future growth and enhanced functionality while maintaining full backward compatibility with existing applications. 