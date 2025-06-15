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