-- Customer Address table
CREATE TABLE IF NOT EXISTS `customer_address` (
  `ADDRESS_ID` int(11) NOT NULL AUTO_INCREMENT,
  `USER_ID` int(11) NOT NULL,
  `ADDRESS` text NOT NULL,
  `CITY` varchar(100) NOT NULL,
  `STATE` varchar(100) NOT NULL,
  `COUNTRY` varchar(100) NOT NULL,
  `PINCODE` varchar(20) NOT NULL,
  `LANDMARK` varchar(255) DEFAULT NULL,
  `ADDRESS_TYPE` enum('Home','Work','Other') DEFAULT 'Home',
  `IS_DEFAULT` tinyint(1) DEFAULT 0,
  `DEL_STATUS` enum('Y','N') DEFAULT 'N',
  `CREATED_DATE` datetime DEFAULT CURRENT_TIMESTAMP,
  `UPDATED_DATE` datetime DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`ADDRESS_ID`),
  KEY `idx_user_id` (`USER_ID`),
  KEY `idx_is_default` (`IS_DEFAULT`),
  KEY `idx_del_status` (`DEL_STATUS`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Cart table (if not exists)
CREATE TABLE IF NOT EXISTS `cart` (
  `CART_ID` int(11) NOT NULL AUTO_INCREMENT,
  `USER_ID` int(11) NOT NULL,
  `PROD_ID` int(11) NOT NULL,
  `UNIT_ID` int(11) NOT NULL,
  `QUANTITY` int(11) NOT NULL,
  `CREATED_DATE` datetime DEFAULT CURRENT_TIMESTAMP,
  `UPDATED_DATE` datetime DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`CART_ID`),
  KEY `idx_user_id` (`USER_ID`),
  KEY `idx_prod_id` (`PROD_ID`),
  KEY `idx_unit_id` (`UNIT_ID`),
  UNIQUE KEY `unique_user_product_unit` (`USER_ID`, `PROD_ID`, `UNIT_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Orders table
CREATE TABLE IF NOT EXISTS `orders` (
  `ORDER_ID` int(11) NOT NULL AUTO_INCREMENT,
  `ORDER_NUMBER` varchar(50) NOT NULL UNIQUE,
  `USER_ID` int(11) NOT NULL,
  `ORDER_TOTAL` decimal(10,2) NOT NULL,
  `ORDER_STATUS` enum('pending','confirmed','processing','shipped','delivered','cancelled') DEFAULT 'pending',
  `DELIVERY_ADDRESS` text NOT NULL,
  `DELIVERY_CITY` varchar(100) NOT NULL,
  `DELIVERY_STATE` varchar(100) NOT NULL,
  `DELIVERY_COUNTRY` varchar(100) NOT NULL,
  `DELIVERY_PINCODE` varchar(20) NOT NULL,
  `DELIVERY_LANDMARK` varchar(255) DEFAULT NULL,
  `PAYMENT_METHOD` enum('cod','online','card') DEFAULT 'cod',
  `ORDER_NOTES` text DEFAULT NULL,
  `CREATED_DATE` datetime DEFAULT CURRENT_TIMESTAMP,
  `UPDATED_DATE` datetime DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`ORDER_ID`),
  KEY `idx_user_id` (`USER_ID`),
  KEY `idx_order_status` (`ORDER_STATUS`),
  KEY `idx_created_date` (`CREATED_DATE`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Order Items table
CREATE TABLE IF NOT EXISTS `order_items` (
  `ORDER_ITEM_ID` int(11) NOT NULL AUTO_INCREMENT,
  `ORDER_ID` int(11) NOT NULL,
  `PROD_ID` int(11) NOT NULL,
  `UNIT_ID` int(11) NOT NULL,
  `QUANTITY` int(11) NOT NULL,
  `UNIT_PRICE` decimal(10,2) NOT NULL,
  `TOTAL_PRICE` decimal(10,2) NOT NULL,
  `CREATED_DATE` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`ORDER_ITEM_ID`),
  KEY `idx_order_id` (`ORDER_ID`),
  KEY `idx_prod_id` (`PROD_ID`),
  FOREIGN KEY (`ORDER_ID`) REFERENCES `orders` (`ORDER_ID`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4; 