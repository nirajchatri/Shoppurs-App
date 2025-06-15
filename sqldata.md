CREATE DATABASE  IF NOT EXISTS shoppurs  /*!40100 DEFAULT CHARACTER SET latin1 */;
USE shoppurs;
-- MySQL dump 10.13  Distrib 8.0.30, for Win64 (x86_64)
--
-- Host:     Database: shoppurs
-- ------------------------------------------------------
-- Server version	5.6.43

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table category
--
DROP TABLE IF EXISTS category;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE category (
  CATEGORY_ID bigint(20) NOT NULL AUTO_INCREMENT,
  CATEGORY_NAME varchar(100) NOT NULL,
  CAT_IMAGE varchar(200) DEFAULT NULL,
  DEL_STATUS char(2) NOT NULL,
  CREATED_BY varchar(200) NOT NULL,
  UPDATED_BY varchar(200) NOT NULL,
  CREATED_DATE datetime NOT NULL,
  UPDATED_DATE datetime NOT NULL,
  PRIMARY KEY (CATEGORY_ID)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;
--
-- Dumping data for table category
--
LOCK TABLES category WRITE;
/*!40000 ALTER TABLE category DISABLE KEYS */;
/*!40000 ALTER TABLE category ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table ret_sub_category
--
DROP TABLE IF EXISTS sub_category;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE sub_category (
  SUB_CATEGORY_ID bigint(20) NOT NULL AUTO_INCREMENT,
  SUB_CATEGORY_NAME varchar(100) NOT NULL,
  SUB_CATEGORY_CAT_ID int(11) NOT NULL,
  SUB_CAT_IMAGE varchar(200) DEFAULT NULL,
  DEL_STATUS char(2) NOT NULL,
  CREATED_BY varchar(200) NOT NULL,
  UPDATED_BY varchar(200) NOT NULL,
  CREATED_DATE datetime NOT NULL,
  UPDATED_DATE datetime NOT NULL,
  PRIMARY KEY (SUB_CATEGORY_ID)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;
--
-- Dumping data for table sub_category
--
LOCK TABLES sub_category WRITE;
/*!40000 ALTER TABLE sub_category DISABLE KEYS */;
/*!40000 ALTER TABLE sub_category ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table product
--
DROP TABLE IF EXISTS product;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE product (
  PROD_ID bigint(20) NOT NULL AUTO_INCREMENT,
  PROD_SUB_CAT_ID int(11) NOT NULL,
  PROD_NAME varchar(200) NOT NULL,
  PROD_CODE varchar(200) DEFAULT NULL,
  PROD_DESC text,
  PROD_MRP decimal(10,2) DEFAULT NULL,
  PROD_SP decimal(10,2) DEFAULT NULL,
  PROD_REORDER_LEVEL varchar(200) DEFAULT NULL,
  PROD_QOH varchar(200) DEFAULT NULL,
  PROD_HSN_CODE varchar(200) DEFAULT NULL,
  PROD_CGST varchar(200) DEFAULT NULL,
  PROD_IGST varchar(200) DEFAULT NULL,
  PROD_SGST varchar(200) DEFAULT NULL,
  PROD_MFG_DATE datetime DEFAULT NULL,
  PROD_EXPIRY_DATE datetime DEFAULT NULL,
  PROD_MFG_BY varchar(200) DEFAULT NULL,
  PROD_IMAGE_1 varchar(200) DEFAULT NULL,
  PROD_IMAGE_2 varchar(200) DEFAULT NULL,
  PROD_IMAGE_3 varchar(200) DEFAULT NULL,
  CREATED_BY varchar(200) NOT NULL,
  UPDATED_BY varchar(200) NOT NULL,
  CREATED_DATE datetime NOT NULL,
  UPDATED_DATE datetime NOT NULL,
  DEL_STATUS varchar(2) DEFAULT NULL,
  IS_BARCODE_AVAILABLE char(1) DEFAULT NULL,
  PROD_CAT_ID int(11) DEFAULT NULL,
  PRIMARY KEY (PROD_ID)
) ENGINE=InnoDB AUTO_INCREMENT=174 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;
--
-- Dumping data for table product
--
LOCK TABLES product WRITE;
/*!40000 ALTER TABLE product DISABLE KEYS */;
/*!40000 ALTER TABLE product ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table product_barcodes
--
DROP TABLE IF EXISTS product_barcodes;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE product_barcodes (
  PRDB_ID bigint(20) NOT NULL AUTO_INCREMENT,
  PRDB_PROD_ID bigint(20) NOT NULL,
  PRDB_CODE varchar(200) NOT NULL,
  PRDB_BARCODE varchar(100) NOT NULL,
  SOLD_STATUS varchar(2) DEFAULT NULL,
  PRIMARY KEY (PRDB_ID)
) ENGINE=InnoDB AUTO_INCREMENT=143 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;
--
-- Dumping data for table product_barcodes
--
LOCK TABLES product_barcodes WRITE;
/*!40000 ALTER TABLE product_barcodes DISABLE KEYS */;
/*!40000 ALTER TABLE product_barcodes ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table product_unit
--
DROP TABLE IF EXISTS product_unit;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE product_unit (
  PU_ID bigint(20) NOT NULL AUTO_INCREMENT,
  PU_PROD_ID bigint(20) NOT NULL,
  PU_PROD_UNIT varchar(20) NOT NULL,
  PU_PROD_UNIT_VALUE varchar(20) NOT NULL,
  PU_PROD_RATE decimal(10,2) NOT NULL,
  PU_STATUS char(1) NOT NULL,
  CREATED_BY varchar(200) NOT NULL,
  UPDATED_BY varchar(200) NOT NULL,
  CREATED_DATE datetime NOT NULL,
  UPDATED_DATE datetime NOT NULL,
  PRIMARY KEY (PU_ID)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;
--
-- Dumping data for table product_unit
--
LOCK TABLES product_unit WRITE;
/*!40000 ALTER TABLE product_unit DISABLE KEYS */;
/*!40000 ALTER TABLE product_unit ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table retailer_info
--
DROP TABLE IF EXISTS retailer_info;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE retailer_info (
  RET_ID bigint(20) NOT NULL AUTO_INCREMENT,
  RET_CODE varchar(200) NOT NULL,
  RET_TYPE varchar(100) DEFAULT NULL,
  RET_NAME varchar(200) NOT NULL,
  RET_SHOP_NAME varchar(200) DEFAULT NULL,
  RET_MOBILE_NO bigint(20) NOT NULL,
  RET_ADDRESS varchar(200) NOT NULL,
  RET_PIN_CODE int(11) NOT NULL,
  RET_EMAIL_ID varchar(200) NOT NULL,
  RET_PHOTO varchar(200) NOT NULL,
  RET_COUNTRY varchar(200) NOT NULL,
  RET_STATE varchar(200) NOT NULL,
  RET_CITY varchar(200) NOT NULL,
  RET_GST_NO varchar(200) DEFAULT NULL,
  RET_LAT varchar(200) DEFAULT NULL,
  RET_LONG varchar(200) DEFAULT NULL,
  RET_DEL_STATUS varchar(200) NOT NULL DEFAULT 'active',
  CREATED_DATE datetime NOT NULL,
  UPDATED_DATE datetime NOT NULL,
  CREATED_BY varchar(200) NOT NULL,
  UPDATED_BY varchar(200) NOT NULL,
  SHOP_OPEN_STATUS char(1) DEFAULT NULL,
  PRIMARY KEY (RET_ID)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;
--
-- Dumping data for table retailer_info
--
LOCK TABLES retailer_info WRITE;
/*!40000 ALTER TABLE retailer_info DISABLE KEYS */;
/*!40000 ALTER TABLE retailer_info ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table cust_order
--
DROP TABLE IF EXISTS cust_order;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE cust_order (
  CO_ID bigint(20) NOT NULL AUTO_INCREMENT,
  CO_NO varchar(100) NOT NULL,
  CO_TRANS_ID varchar(100) DEFAULT NULL,
  CO_DATE datetime NOT NULL,
  CO_DELIVERY_NOTE text,
  CO_DELIVERY_MODE varchar(200) DEFAULT NULL,
  CO_PAYMENT_MODE varchar(200) NOT NULL,
  CO_IMAGE varchar(200) NOT NULL,
  CO_RET_ID int(20) NOT NULL,
  CO_CUST_CODE varchar(100) NOT NULL,
  CO_CUST_NAME varchar(200) NOT NULL,
  CO_CUST_MOBILE bigint(20) NOT NULL,
  CO_DELIVERY_ADDRESS varchar(200) NOT NULL,
  CO_DELIVERY_COUNTRY varchar(100) DEFAULT NULL,
  CO_DELIVERY_STATE varchar(100) DEFAULT NULL,
  CO_DELIVERY_CITY varchar(100) DEFAULT NULL,
  CO_DELIVERY_LAT varchar(20) DEFAULT NULL,
  CO_DELIVERY_LONG varchar(20) DEFAULT NULL,
  CO_PINCODE varchar(100) NOT NULL,
  CO_TOTAL_QTY int(11) NOT NULL,
  CO_TOTAL_AMT decimal(18,2) NOT NULL,
  CO_COUPON_CODE varchar(100) DEFAULT NULL,
  CO_PAYMENT_STATUS varchar(20) DEFAULT NULL,
  CO_DELIVER_BY varchar(200) DEFAULT NULL,
  CO_RATINGS_BY_CUST decimal(10,2) DEFAULT NULL,
  CO_CUST_REMARKS text,
  CO_TYPE varchar(20) DEFAULT 'normal',
  CO_STATUS varchar(100) DEFAULT NULL,
  CREATED_BY varchar(200) NOT NULL,
  UPDATED_BY varchar(200) NOT NULL,
  CREATED_DATE datetime NOT NULL,
  UPDATED_DATE datetime NOT NULL,
  PRIMARY KEY (CO_ID)
) ENGINE=InnoDB AUTO_INCREMENT=77 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;
--
-- Dumping data for table cust_order
--
LOCK TABLES cust_order WRITE;
/*!40000 ALTER TABLE cust_order DISABLE KEYS */;
/*!40000 ALTER TABLE cust_order ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table cust_order_details
--
DROP TABLE IF EXISTS cust_order_details;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE cust_order_details (
  COD_ID bigint(20) NOT NULL AUTO_INCREMENT,
  COD_CO_ID int(11) NOT NULL,
  COD_QTY int(11) NOT NULL,
  PROD_NAME varchar(200) NOT NULL,
  PROD_BARCODE varchar(200) DEFAULT NULL,
  PROD_DESC text,
  PROD_MRP decimal(10,2) DEFAULT NULL,
  PROD_SP decimal(10,2) DEFAULT NULL,
  PROD_CGST decimal(10,2) DEFAULT NULL,
  PROD_IGST decimal(10,2) DEFAULT NULL,
  PROD_SGST decimal(10,2) DEFAULT NULL,
  PROD_IMAGE_1 varchar(200) DEFAULT NULL,
  PROD_IMAGE_2 varchar(200) DEFAULT NULL,
  PROD_IMAGE_3 varchar(200) DEFAULT NULL,
  PROD_CODE varchar(200) DEFAULT NULL,
  PROD_ID bigint(20) DEFAULT NULL,
  PROD_UNIT varchar(20) DEFAULT NULL,
  IS_BARCODE_AVAILABLE char(1) DEFAULT NULL,
  PRIMARY KEY (COD_ID)
) ENGINE=InnoDB AUTO_INCREMENT=515 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;
--
-- Dumping data for table cust_order_details
--
LOCK TABLES cust_order_details WRITE;
/*!40000 ALTER TABLE cust_order_details DISABLE KEYS */;
/*!40000 ALTER TABLE cust_order_details ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table cust_payment
--
DROP TABLE IF EXISTS cust_payment;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE cust_payment (
  PAYMENT_ID bigint(20) NOT NULL AUTO_INCREMENT,
  PAYMENT_STATUS_MESSAGE varchar(100) NOT NULL,
  PAYMENT_TRANSACTION_ID varchar(200) NOT NULL,
  PAYMENT_TRANSACTION_TYPE varchar(100) NOT NULL,
  PAYMENT_MERCHANT_ID varchar(200) NOT NULL,
  PAYMENT_CARD_BRAND varchar(100) DEFAULT NULL,
  PAYMENT_CARD_LEVEL varchar(100) DEFAULT NULL,
  PAYMENT_CARD_NUMBER varchar(100) DEFAULT NULL,
  PAYMENT_CARD_TYPE varchar(100) DEFAULT NULL,
  PAYMENT_PAN_LENGTH int(11) DEFAULT NULL,
  PAYMENT_PAYMENT_ID varchar(200) DEFAULT NULL,
  PAYMENT_PIN_VERIFIED_FLAG varchar(4) DEFAULT NULL,
  PAYMENT_RESPONSE_CODE varchar(20) DEFAULT NULL,
  PAYMENT_RESPONSE_MESSAGE varchar(100) DEFAULT NULL,
  PAYMENT_FAILURE_MESSAGE varchar(200) DEFAULT NULL,
  PAYMENT_CURRENCY_CODE varchar(20) DEFAULT NULL,
  PAYMENT_SECURE_HASH varchar(220) DEFAULT NULL,
  PAYMENT_AID varchar(200) DEFAULT NULL,
  PAYMENT_AID_NAME varchar(100) DEFAULT NULL,
  PAYMENT_RRN varchar(200) DEFAULT NULL,
  PAYMENT_TSI varchar(100) DEFAULT NULL,
  PAYMENT_TVR varchar(100) DEFAULT NULL,
  PAYMENT_ECI varchar(100) DEFAULT NULL,
  PAYMENT_MERCHANT_REF_INVOICE_NO varchar(200) DEFAULT NULL,
  PAYMENT_APPROVED varchar(4) DEFAULT NULL,
  PAYMENT_CARD_HOLDER_NAME varchar(200) DEFAULT NULL,
  PAYMENT_AMOUNT decimal(10,2) DEFAULT NULL,
  PAYMENT_MER_AMOUNT decimal(10,2) DEFAULT NULL,
  PAYMENT_DISCOUNT_VALUE decimal(10,2) DEFAULT NULL,
  PAYMENT_STATUS varchar(10) DEFAULT NULL,
  PAYMENT_STATUS_CODE varchar(20) DEFAULT NULL,
  PAYMENT_AUTH_CODE varchar(10) DEFAULT NULL,
  PAYMENT_BANK_MERCHANT_ID varchar(100) DEFAULT NULL,
  PAYMENT_BANK_TERMINAL_ID varchar(100) DEFAULT NULL,
  PAYMENT_BANK_REF_NO varchar(200) DEFAULT NULL,
  PAYMENT_BATCH_NO varchar(100) DEFAULT NULL,
  PAYMENT_PAYMENT_METHOD varchar(100) DEFAULT NULL,
  PAYMENT_PAYMENT_BRAND varchar(100) DEFAULT NULL,
  PAYMENT_PAYMENT_MODE varchar(100) DEFAULT NULL,
  PAYMENT_PAYMENT_DATE varchar(100) DEFAULT NULL,
  PAYMENT_PAYMENT_INVOICE_NO varchar(200) DEFAULT NULL,
  PAYMENT_MERCHANT_NAME varchar(200) DEFAULT NULL,
  PAYMENT_MERCHANT_ADDRESS varchar(200) DEFAULT NULL,
  PAYMENT_PAYMENT_TC varchar(200) DEFAULT NULL,
  PAYMENT_RETRY varchar(20) DEFAULT NULL,
  PAYMENT_DELIVERY_NAME varchar(200) DEFAULT NULL,
  PAYMENT_DELIVERY_COUNTRY varchar(100) DEFAULT NULL,
  PAYMENT_DELIVERY_STATE varchar(100) DEFAULT NULL,
  PAYMENT_DELIVERY_CITY varchar(100) DEFAULT NULL,
  PAYMENT_DELIVERY_TEL varchar(100) DEFAULT NULL,
  PAYMENT_DELIVERY_ZIP varchar(100) DEFAULT NULL,
  PAYMENT_BILLING_NAME varchar(200) DEFAULT NULL,
  PAYMENT_BILLING_CITY varchar(200) DEFAULT NULL,
  PAYMENT_BILLING_NOTES varchar(200) DEFAULT NULL,
  PAYMENT_BILLING_ADDRESS varchar(200) DEFAULT NULL,
  PAYMENT_BILLING_TEL varchar(20) DEFAULT NULL,
  PAYMENT_BILLING_COUNTRY varchar(100) DEFAULT NULL,
  PAYMENT_BILLING_STATE varchar(100) DEFAULT NULL,
  PAYMENT_BILLING_EMAIL varchar(200) DEFAULT NULL,
  PAYMENT_BILLING_ZIP varchar(20) DEFAULT NULL,
  CREATED_BY varchar(200) NOT NULL,
  UPDATED_BY varchar(200) NOT NULL,
  CREATED_DATE datetime NOT NULL,
  UPDATED_DATE datetime NOT NULL,
  PRIMARY KEY (PAYMENT_ID)
) ENGINE=InnoDB AUTO_INCREMENT=75 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;
--
-- Dumping data for table cust_payment
--
LOCK TABLES cust_payment WRITE;
/*!40000 ALTER TABLE cust_payment DISABLE KEYS */;
/*!40000 ALTER TABLE cust_payment ENABLE KEYS */;
UNLOCK TABLES;

DROP TABLE IF EXISTS invoice_master;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE invoice_master (
  INVM_ID bigint(20) NOT NULL AUTO_INCREMENT,
  INVM_NO varchar(200) NOT NULL,
  INVM_TRANS_ID varchar(200) NOT NULL,
  INVM_DATE datetime NOT NULL,
  INVM_CUST_ID bigint(20) DEFAULT NULL,
  INVM_CUST_CODE varchar(100) DEFAULT NULL,
  INVM_CUST_NAME varchar(100) DEFAULT NULL,
  INVM_CUST_ADDRESS varchar(200) DEFAULT NULL,
  INVM_CUST_MOBILE varchar(100) DEFAULT NULL,
  INVM_CUST_GST varchar(100) DEFAULT NULL,
  INVM_TOT_CGST decimal(10,2) DEFAULT NULL,
  INVM_TOT_SGST decimal(10,2) DEFAULT NULL,
  INVM_TOT_IGST decimal(10,2) DEFAULT NULL,
  INVM_TOT_DISCOUNT_AMOUNT decimal(10,2) DEFAULT NULL,
  INVM_TOT_TAX_AMOUNT decimal(10,2) DEFAULT NULL,
  INVM_TOT_AMOUNT decimal(10,2) DEFAULT NULL,
  INVM_TOT_NET_PAYABLE decimal(10,2) DEFAULT NULL,
  INVM_STATUS varchar(100) DEFAULT NULL,
  INVM_PAYMENT_MODE varchar(100) DEFAULT NULL,
  CREATED_BY varchar(200) NOT NULL,
  UPDATED_BY varchar(200) NOT NULL,
  CREATED_DATE datetime NOT NULL,
  UPDATED_DATE datetime NOT NULL,
  PRIMARY KEY (INVM_ID)
) ENGINE=InnoDB AUTO_INCREMENT=72 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;
--
-- Dumping data for table invoice_master
--
LOCK TABLES invoice_master WRITE;
/*!40000 ALTER TABLE invoice_master DISABLE KEYS */;
/*!40000 ALTER TABLE invoice_master ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table invoice_detail
--
DROP TABLE IF EXISTS invoice_detail;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE invoice_detail (
  INVD_ID bigint(20) NOT NULL AUTO_INCREMENT,
  INVD_INVM_ID bigint(20) NOT NULL,
  INVD_PROD_ID bigint(20) NOT NULL,
  INVD_PROD_CODE varchar(200) DEFAULT NULL,
  INVD_PROD_NAME varchar(200) NOT NULL,
  INVD_PROD_UNIT varchar(20) DEFAULT NULL,
  INVD_QTY int(11) NOT NULL,
  INVD_HSN_CODE varchar(100) NOT NULL,
  INVD_MRP decimal(10,2) NOT NULL,
  INVD_SP decimal(10,2) NOT NULL,
  INVD_DISCOUNT_PERCENTAGE decimal(10,2) NOT NULL,
  INVD_DISCOUNT_AMOUNT decimal(10,2) NOT NULL,
  INVD_CGST decimal(10,2) DEFAULT NULL,
  INVD_SGST decimal(10,2) DEFAULT NULL,
  INVD_IGST decimal(10,2) DEFAULT NULL,
  INVD_PROD_IMAGE_1 varchar(200) DEFAULT NULL,
  INVD_PROD_IMAGE_2 varchar(200) DEFAULT NULL,
  INVD_PROD_IMAGE_3 varchar(200) DEFAULT NULL,
  INVD_TAMOUNT decimal(10,2) DEFAULT NULL,
  INVD_PROD_STATUS char(1) DEFAULT NULL,
  CREATED_BY varchar(200) NOT NULL,
  UPDATED_BY varchar(200) NOT NULL,
  CREATED_DATE datetime NOT NULL,
  UPDATED_DATE datetime NOT NULL,
  PRIMARY KEY (INVD_ID)
) ENGINE=InnoDB AUTO_INCREMENT=443 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;
--
-- Dumping data for table invoice_detail
--
LOCK TABLES invoice_detail WRITE;
/*!40000 ALTER TABLE invoice_detail DISABLE KEYS */;
/*!40000 ALTER TABLE invoice_detail ENABLE KEYS */;
UNLOCK TABLES;

DROP TABLE IF EXISTS sales_return;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE sales_return (
  SR_ID bigint(20) NOT NULL AUTO_INCREMENT,
  SR_INV_NO varchar(200) NOT NULL,
  SR_TRANS_ID varchar(200) NOT NULL,
  CUST_CODE varchar(200) NOT NULL,
  PROD_ID bigint(20) DEFAULT NULL,
  PROD_QTY int(11) DEFAULT NULL,
  PROD_CODE varchar(200) DEFAULT NULL,
  PROD_NAME varchar(200) NOT NULL,
  PROD_BARCODE varchar(200) DEFAULT NULL,
  PROD_DESC text,
  PROD_MRP decimal(10,2) DEFAULT NULL,
  PROD_SP decimal(10,2) DEFAULT NULL,
  PROD_CGST decimal(10,2) DEFAULT NULL,
  PROD_IGST decimal(10,2) DEFAULT NULL,
  PROD_SGST decimal(10,2) DEFAULT NULL,
  PROD_IMAGE_1 varchar(200) DEFAULT NULL,
  PROD_IMAGE_2 varchar(200) DEFAULT NULL,
  PROD_IMAGE_3 varchar(200) DEFAULT NULL,
  PROD_UNIT varchar(20) DEFAULT NULL,
  CREATED_BY varchar(200) NOT NULL,
  UPDATED_BY varchar(200) NOT NULL,
  CREATED_DATE datetime NOT NULL,
  UPDATED_DATE datetime NOT NULL,
  STATUS char(1) DEFAULT NULL,
  PRIMARY KEY (SR_ID)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;
--
-- Dumping data for table sales_return
--
LOCK TABLES sales_return WRITE;
/*!40000 ALTER TABLE sales_return DISABLE KEYS */;
/*!40000 ALTER TABLE sales_return ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table user_info
--
DROP TABLE IF EXISTS user_info;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE user_info (
  USER_ID bigint(20) NOT NULL AUTO_INCREMENT,
  UL_ID bigint(20) NOT NULL,
  USERNAME varchar(100) NOT NULL,
  EMAIL varchar(100) NOT NULL,
  MOBILE bigint(20) DEFAULT NULL,
  PASSWORD varchar(150) NOT NULL,
  CITY varchar(50) DEFAULT NULL,
  PROVINCE varchar(50) DEFAULT NULL,
  ZIP varchar(10) DEFAULT NULL,
  ADDRESS varchar(200) DEFAULT NULL,
  PHOTO varchar(200) DEFAULT NULL,
  FCM_TOKEN text,
  CREATED_DATE datetime NOT NULL,
  CREATED_BY varchar(20) DEFAULT NULL,
  UPDATED_DATE datetime DEFAULT NULL,
  UPDATED_BY varchar(20) DEFAULT NULL,
  USER_TYPE varchar(20) DEFAULT NULL,
  ISACTIVE char(1) NOT NULL,
  PRIMARY KEY (USER_ID),
  UNIQUE KEY EMAIL_UNIQUE (EMAIL),
  UNIQUE KEY MOBILE_UNIQUE (MOBILE)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;
--
-- Dumping data for table user_info
--
LOCK TABLES user_info WRITE;
/*!40000 ALTER TABLE user_info DISABLE KEYS */;
/*!40000 ALTER TABLE user_info ENABLE KEYS */;
UNLOCK TABLES;


give a database structure according to this sql 