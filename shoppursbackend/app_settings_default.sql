-- Create app_settings table if it doesn't exist
CREATE TABLE IF NOT EXISTS `app_settings` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `app_name` varchar(255) DEFAULT NULL,
  `support_number` varchar(20) DEFAULT NULL,
  `support_email` varchar(255) DEFAULT NULL,
  `bank_name` varchar(255) DEFAULT NULL,
  `branch` varchar(255) DEFAULT NULL,
  `ifsc_code` varchar(20) DEFAULT NULL,
  `account_number` varchar(50) DEFAULT NULL,
  `upi_image_url` varchar(500) DEFAULT NULL,
  `company_name` varchar(255) DEFAULT NULL,
  `company_address` text DEFAULT NULL,
  `gstin` varchar(50) DEFAULT NULL,
  `company_logo_url` varchar(500) DEFAULT NULL,
  `invoice_note` text DEFAULT NULL,
  `invoice_footer_text` text DEFAULT NULL,
  `invoice_prefix` varchar(10) DEFAULT 'INV',
  `default_currency` varchar(10) DEFAULT '₹',
  `tax_label_cgst` varchar(20) DEFAULT 'CGST',
  `tax_label_sgst` varchar(20) DEFAULT 'SGST',
  `payment_terms_text` text DEFAULT 'Payment Method: Cash',
  `upi_id` varchar(255) DEFAULT NULL,
  `created_at` timestamp DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Insert default settings if table is empty
INSERT INTO `app_settings` (
  `app_name`, `support_number`, `support_email`, `company_name`, 
  `company_address`, `gstin`, `invoice_footer_text`, `invoice_prefix`,
  `default_currency`, `tax_label_cgst`, `tax_label_sgst`, `payment_terms_text`
) 
SELECT 
  'Anwar Food', '9810162596', 'shop.westdelhi@shoppurs.in', 
  'Areeva Products & Services Pvt. Ltd.',
  'Hari Nagar, New Delhi, Delhi 110058, India',
  '07AAPCA4055P1Z3',
  'Thank you for shopping at Shoppurs.\nIn case you would like to Exchange any of the products purchased, we request you to carry your bill along.',
  'INV', '₹', 'CGST', 'SGST', 'Payment Method: Cash'
WHERE NOT EXISTS (SELECT 1 FROM `app_settings`); 