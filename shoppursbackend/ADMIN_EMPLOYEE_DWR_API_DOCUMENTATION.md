# Admin Employee DWR Details API Documentation

## 📊 **New Admin API for Employee DWR Management**

### **Endpoint**
```
GET /api/admin/employee-dwr-details/:userId
```

**Access:** Admin role only  
**Purpose:** View employee's Daily Work Report (DWR) details including day start/end time, station names & locations  
**Data Limit:** ⚠️ **Last 14 days only** - No data older than 14 days will be returned

---

## 🗄️ **Database Tables Used**

### **Primary Table: `dwr_detail`**
```sql
Fields Referenced:
- DWR_ID (Primary Key, Auto-increment)
- DWR_EMP_ID (Employee User ID)
- DWR_NO (Unique incremental DWR number)
- DWR_DATE (Date of work - YYYY-MM-DD)
- DWR_STATUS (Draft/approved)
- DWR_EXPENSES (Work expenses amount)
- DWR_START_STA (Foreign Key to sta_master.STA_ID)
- DWR_END_STA (Foreign Key to sta_master.STA_ID)
- DWR_START_LOC (Starting location details)
- DWR_END_LOC (Ending location details)
- DWR_REMARKS (End-of-day remarks)
- DWR_SUBMIT (Day start timestamp)
- TIME_STAMP (Day end/last update timestamp)
- DEL_STATUS (0=active, 1=deleted)
- LAST_USER (Last modified by username)
```

### **Station Master Table: `sta_master`**
```sql
Fields Referenced:
- STA_ID (Primary Key)
- STA_VSO_ID (VSO ID)
- STA_NAME (Station Name)
- DEL_STATUS (0=active, 1=deleted)
- LAST_USER (Last modified by)
- TIME_STAMP (Last update time)
```

### **Table Relationships:**
```sql
dwr_detail.DWR_START_STA → sta_master.STA_ID (Start Station)
dwr_detail.DWR_END_STA → sta_master.STA_ID (End Station)
```

---

## 🔧 **API Details**

### **Endpoint**
```
GET /api/admin/employee-dwr-details/:userId
```

### **Path Parameters**
- `userId` (required): The USER_ID of the employee whose DWR details to fetch

### **Query Parameters**
- `date` (optional): Filter by specific date in YYYY-MM-DD format (must be within last 14 days)
- `page` (optional): Page number for pagination (default: 1)
- `limit` (optional): Records per page (default: 10)

### **Data Limitations**
- ⚠️ **14-Day Limit**: Only returns DWR records from the last 14 days
- ⚠️ **Date Filter Restriction**: If using date filter, date must be within last 14 days
- ✅ **Station Names**: Automatically resolves station IDs to station names via `sta_master` table

### **Authentication**
- **Required**: Bearer Token (Admin role only)
- **Validation**: Checks that USER_ID belongs to an active employee

---

## 📋 **Request Examples**

### **Get All DWR Records for Employee (Last 14 Days)**
```bash
curl -X GET "http://localhost:3000/api/admin/employee-dwr-details/123" \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN_HERE"
```

### **Get DWR Records for Specific Date (Must be within 14 days)**
```bash
curl -X GET "http://localhost:3000/api/admin/employee-dwr-details/123?date=2023-12-13" \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN_HERE"
```

### **Get DWR Records with Pagination**
```bash
curl -X GET "http://localhost:3000/api/admin/employee-dwr-details/123?page=2&limit=5" \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN_HERE"
```

---

## 📊 **Response Format**

### **Success Response (Updated with Station Names)**
```json
{
  "success": true,
  "message": "Employee DWR details fetched successfully (Last 14 days)",
  "data": {
    "employee": {
      "user_id": 123,
      "username": "john_employee",
      "user_type": "employee"
    },
    "dwr_records": [
      {
        "dwr_id": 456,
        "dwr_number": 1001,
        "work_date": "2023-12-13",
        "status": "approved",
        "day_start": {
          "station_id": 5,
          "station_name": "HQ Office Station",
          "location": "Mumbai Central, Reception Area",
          "time": "09:30:00",
          "full_timestamp": "2023-12-13T09:30:00.000Z"
        },
        "day_end": {
          "station_id": 8,
          "station_name": "Client Office Station",
          "location": "Andheri West, Floor 3",
          "time": "18:15:00",
          "full_timestamp": "2023-12-13T18:15:00.000Z"
        },
        "expenses": 250.50,
        "remarks": "Visited 5 clients, completed all scheduled meetings",
        "last_updated_by": "john_employee",
        "is_completed": true
      },
      {
        "dwr_id": 455,
        "dwr_number": 1000,
        "work_date": "2023-12-12",
        "status": "approved",
        "day_start": {
          "station_id": 3,
          "station_name": "Branch Office Station",
          "location": "Bandra East, Ground Floor",
          "time": "10:00:00",
          "full_timestamp": "2023-12-12T10:00:00.000Z"
        },
        "day_end": {
          "station_id": 7,
          "station_name": "Field Location Station",
          "location": "Vashi, Market Area",
          "time": "17:45:00",
          "full_timestamp": "2023-12-12T17:45:00.000Z"
        },
        "expenses": 180.00,
        "remarks": "Field visits completed, all orders processed",
        "last_updated_by": "john_employee",
        "is_completed": true
      }
    ],
    "summary": {
      "total_dwr_entries": 12,
      "completed_days": 11,
      "draft_days": 1,
      "total_expenses": 2150.75,
      "first_work_date": "2023-11-30",
      "last_work_date": "2023-12-13",
      "completion_rate": 92
    },
    "pagination": {
      "currentPage": 1,
      "totalPages": 2,
      "totalRecords": 12,
      "limit": 10,
      "hasNext": true,
      "hasPrev": false
    },
    "filters": {
      "date_filter": null,
      "employee_id": "123",
      "data_limit": "Last 14 days only"
    }
  }
}
```

---

## ❌ **Error Responses**

### **Employee Not Found**
```json
{
  "success": false,
  "message": "Employee not found or not active"
}
```

### **Invalid Date Format**
```json
{
  "success": false,
  "message": "Invalid date format. Use YYYY-MM-DD format"
}
```

### **Date Outside 14-Day Limit**
```json
{
  "success": false,
  "message": "Date filter is limited to last 14 days only"
}
```

### **Authentication Error**
```json
{
  "success": false,
  "message": "Access denied. Admin privileges required."
}
```

### **Server Error**
```json
{
  "success": false,
  "message": "Error fetching employee DWR details",
  "error": "Database connection failed"
}
```

---

## 📈 **Business Use Cases**

### **For Admin Management:**
- 🕐 **Recent Attendance Monitoring**: View employee start and end times (last 14 days)
- 📍 **Location Tracking**: Monitor where employees start and end their day
- 🏢 **Station Management**: See which stations employees are using
- 💰 **Recent Expense Oversight**: Track daily expense claims by employee
- 📊 **Performance Analysis**: Review completion rates and work patterns
- 🔍 **Audit Trail**: Complete record of recent employee work activities
- 📈 **Productivity Metrics**: Analyze recent employee work consistency

### **Key Information Provided:**
- **Day Start Details**: Station ID, station name, location, exact time
- **Day End Details**: Ending station ID, station name, location, completion time
- **Work Summary**: Expenses, remarks, completion status
- **Recent Data**: Only last 14 days for focused monitoring
- **Statistical Summary**: Completion rates, total expenses, work patterns

---

## 🎯 **Data Structure Breakdown**

### **Employee Information**
```json
"employee": {
  "user_id": 123,           // Employee's USER_ID
  "username": "john_emp",   // Employee username
  "user_type": "employee"   // Confirms employee role
}
```

### **Enhanced DWR Record Details**
```json
"day_start": {
  "station_id": 5,                      // DWR_START_STA (Foreign Key)
  "station_name": "HQ Office Station",  // sta_master.STA_NAME
  "location": "Mumbai Central, Reception", // DWR_START_LOC
  "time": "09:30:00",                   // Extracted time from DWR_SUBMIT
  "full_timestamp": "2023-12-13T09:30:00" // Complete DWR_SUBMIT timestamp
},
"day_end": {
  "station_id": 8,                      // DWR_END_STA (Foreign Key)
  "station_name": "Client Office Station", // sta_master.STA_NAME
  "location": "Andheri West, Floor 3",  // DWR_END_LOC
  "time": "18:15:00",                   // Extracted time from TIME_STAMP
  "full_timestamp": "2023-12-13T18:15:00" // Complete TIME_STAMP
}
```

### **Station Name Handling**
```json
// If station found in sta_master
"station_name": "Actual Station Name"

// If station ID not found in sta_master
"station_name": "Station not found"

// If no station ID provided (day not ended)
"station_name": null
```

### **Summary Statistics (14-Day Window)**
```json
"summary": {
  "total_dwr_entries": 12,      // Total DWR records in last 14 days
  "completed_days": 11,         // DWR_STATUS = 'approved' in last 14 days
  "draft_days": 1,              // DWR_STATUS = 'Draft' in last 14 days
  "total_expenses": 2150.75,    // Sum of all DWR_EXPENSES in last 14 days
  "first_work_date": "2023-11-30", // MIN(DWR_DATE) in last 14 days
  "last_work_date": "2023-12-13",  // MAX(DWR_DATE) in last 14 days
  "completion_rate": 92         // Percentage calculation
}
```

---

## 🔐 **Security Features**

1. **Admin-Only Access**: JWT token validation with admin role verification
2. **Employee Validation**: Ensures USER_ID belongs to active employee
3. **Input Validation**: Date format validation and parameter sanitization
4. **Date Range Validation**: Prevents access to data older than 14 days
5. **SQL Injection Protection**: Parameterized queries throughout
6. **Active Records Only**: Filters out deleted records (DEL_STATUS = 0)
7. **Role-based Authorization**: Only admin can access employee DWR data

---

## 📊 **Testing Scenarios**

### **Scenario 1: View Recent DWR Records**
```bash
# Request
curl -X GET "http://localhost:3000/api/admin/employee-dwr-details/123" \
  -H "Authorization: Bearer ADMIN_TOKEN"

# Expected: DWR records from last 14 days with station names
```

### **Scenario 2: Filter by Recent Date**
```bash
# Request (using yesterday's date)
curl -X GET "http://localhost:3000/api/admin/employee-dwr-details/123?date=2023-12-13" \
  -H "Authorization: Bearer ADMIN_TOKEN"

# Expected: Only DWR records for December 13, 2023 (if within 14 days)
```

### **Scenario 3: Try Old Date (Should Fail)**
```bash
# Request (using date older than 14 days)
curl -X GET "http://localhost:3000/api/admin/employee-dwr-details/123?date=2023-11-01" \
  -H "Authorization: Bearer ADMIN_TOKEN"

# Expected: 400 error - Date filter is limited to last 14 days only
```

### **Scenario 4: Pagination with 14-Day Limit**
```bash
# Request
curl -X GET "http://localhost:3000/api/admin/employee-dwr-details/123?page=2&limit=5" \
  -H "Authorization: Bearer ADMIN_TOKEN"

# Expected: Records 6-10 from last 14 days only
```

### **Scenario 5: Invalid Employee ID**
```bash
# Request
curl -X GET "http://localhost:3000/api/admin/employee-dwr-details/999" \
  -H "Authorization: Bearer ADMIN_TOKEN"

# Expected: 404 error - Employee not found
```

---

## 📋 **Database Query Details**

### **Main Query with Station Names**
```sql
SELECT 
  d.DWR_ID, d.DWR_EMP_ID, d.DWR_NO, d.DWR_DATE, d.DWR_STATUS, d.DWR_EXPENSES,
  d.DWR_START_STA, d.DWR_END_STA, d.DWR_START_LOC, d.DWR_END_LOC, 
  d.DWR_REMARKS, d.DWR_SUBMIT, d.DEL_STATUS, d.LAST_USER, d.TIME_STAMP,
  DATE(d.DWR_DATE) as work_date,
  TIME(d.DWR_SUBMIT) as start_time_only,
  TIME(d.TIME_STAMP) as end_time_only,
  start_sta.STA_NAME as start_station_name,
  end_sta.STA_NAME as end_station_name
FROM dwr_detail d
LEFT JOIN sta_master start_sta ON d.DWR_START_STA = start_sta.STA_ID AND start_sta.DEL_STATUS = 0
LEFT JOIN sta_master end_sta ON d.DWR_END_STA = end_sta.STA_ID AND end_sta.DEL_STATUS = 0
WHERE d.DWR_EMP_ID = ? AND d.DEL_STATUS = 0
AND d.DWR_DATE >= DATE_SUB(CURDATE(), INTERVAL 14 DAY)
ORDER BY d.DWR_DATE DESC, d.DWR_ID DESC
```

### **14-Day Filter Logic**
```sql
-- Always applied: Last 14 days only
AND DWR_DATE >= DATE_SUB(CURDATE(), INTERVAL 14 DAY)

-- If specific date requested, both conditions apply
AND DATE(DWR_DATE) = ? 
AND DWR_DATE >= DATE_SUB(CURDATE(), INTERVAL 14 DAY)
```

---

## 💡 **Advanced Features**

### **Automatic Calculations (14-Day Window):**
- ✅ **Work Duration**: Calculates time between start and end
- ✅ **Completion Rate**: Percentage of completed vs draft DWRs (last 14 days)
- ✅ **Expense Totals**: Sum of all expense claims (last 14 days)
- ✅ **Date Range**: First and last work dates (within 14-day window)

### **Station Name Resolution:**
- ✅ **Automatic Lookup**: Resolves station IDs to readable names
- ✅ **Fallback Handling**: Shows "Station not found" for invalid IDs
- ✅ **Active Stations Only**: Only includes active stations (DEL_STATUS = 0)

### **Smart Filtering:**
- ✅ **14-Day Limitation**: Automatically limits all data to last 14 days
- ✅ **Date Validation**: Prevents queries for dates older than 14 days
- ✅ **Pagination Support**: Handle large datasets efficiently within 14-day window

### **Data Enrichment:**
- ✅ **Time Extraction**: Separate time from full timestamps
- ✅ **Status Indicators**: Boolean flags for completion
- ✅ **Station Information**: Both ID and name for reference
- ✅ **Formatted Output**: User-friendly data structure

---

## ⚠️ **Important Notes**

### **Data Limitations:**
1. **14-Day Window**: No data older than 14 days will be returned
2. **Date Filter Restriction**: Date parameter must be within last 14 days
3. **Summary Statistics**: All calculations are based on 14-day window only
4. **Pagination**: Pagination applies only to records within 14-day limit

### **Station Master Integration:**
1. **Foreign Key Relationship**: DWR_START_STA and DWR_END_STA reference sta_master.STA_ID
2. **Active Stations Only**: Only stations with DEL_STATUS = 0 are included
3. **Graceful Handling**: Invalid station IDs show "Station not found"
4. **Both ID and Name**: Response includes both station_id and station_name

---

## ✅ **Status: PRODUCTION READY**

### **Implementation Complete:**
- ✅ **API Endpoint**: GET /api/admin/employee-dwr-details/:userId
- ✅ **14-Day Limit**: All queries limited to last 14 days
- ✅ **Station Integration**: Joined with sta_master for station names
- ✅ **Admin Authentication**: JWT token validation
- ✅ **Employee Validation**: Active employee verification
- ✅ **Date Filtering**: Optional date-based filtering (within 14-day limit)
- ✅ **Pagination Support**: Efficient data handling
- ✅ **Summary Statistics**: Comprehensive analytics (14-day window)
- ✅ **Error Handling**: All edge cases covered including date validation
- ✅ **Security Features**: Role-based access control

### **Database Operations:**
1. **Employee Validation**: Verify active employee status
2. **14-Day Data Retrieval**: Fetch filtered DWR records (last 14 days only)
3. **Station Name Resolution**: Join with sta_master for readable station names
4. **Summary Calculations**: Generate statistical overview (14-day window)
5. **Pagination Handling**: Count and limit results within date range

---

## 🎯 **Quick Test Commands**

Replace tokens and IDs with actual values:

```bash
# Get all recent DWR records for employee (last 14 days)
curl -X GET "http://localhost:3000/api/admin/employee-dwr-details/123" \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN"

# Get DWR for specific recent date
curl -X GET "http://localhost:3000/api/admin/employee-dwr-details/123?date=2023-12-13" \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN"

# Get paginated results (last 14 days)
curl -X GET "http://localhost:3000/api/admin/employee-dwr-details/123?page=1&limit=5" \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN"

# Test date validation (should fail for old dates)
curl -X GET "http://localhost:3000/api/admin/employee-dwr-details/123?date=2023-01-01" \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN"
```

---

## 📊 **Sample Use Case: Recent Monitoring**

**Daily Admin Check (Recent Activity):**
```bash
# Check recent employee activity
curl -X GET "http://localhost:3000/api/admin/employee-dwr-details/123" \
  -H "Authorization: Bearer ADMIN_TOKEN"
```

**Weekly Review (Last 7 Days):**
```bash
# Get recent DWR records for weekly analysis
curl -X GET "http://localhost:3000/api/admin/employee-dwr-details/123?limit=7" \
  -H "Authorization: Bearer ADMIN_TOKEN"
```

**Station Usage Analysis:**
```bash
# Analyze which stations employee has been using recently
curl -X GET "http://localhost:3000/api/admin/employee-dwr-details/123" \
  -H "Authorization: Bearer ADMIN_TOKEN"
# Response will include both station_id and station_name for analysis
```

The Enhanced Admin Employee DWR Details API with 14-day limit and station name resolution is ready for immediate use! 🚀 