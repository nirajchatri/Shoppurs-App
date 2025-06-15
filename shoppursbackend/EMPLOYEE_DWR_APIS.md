# Employee DWR (Daily Work Report) APIs

## 📊 **3 New Employee APIs Created**

### **Endpoints**
1. `GET /api/employee/dwr/today` - Get today's DWR details
2. `POST /api/employee/dwr/start-day` - Start your workday
3. `PUT /api/employee/dwr/end-day` - End your workday

**Access:** Employee role only  
**Purpose:** Daily work report and attendance management

---

## 🗄️ **Database Table: `dwr_detail`**

```sql
Fields:
- DWR_ID (Primary Key, Auto-increment)
- DWR_EMP_ID (Employee ID from JWT)
- DWR_NO (Unique incremental number)
- DWR_DATE (Date of work)
- DWR_STATUS (Draft/approved)
- DWR_EXPENSES (Work expenses)
- DWR_START_STA (Starting station)
- DWR_END_STA (Ending station)
- DWR_START_LOC (Starting location)
- DWR_END_LOC (Ending location)
- DWR_REMARKS (End-of-day remarks)
- DWR_SUBMIT (Submission timestamp)
- DEL_STATUS (0=active, 1=deleted)
- LAST_USER (Last modified by)
- TIME_STAMP (Last update time)
```

---

## 📝 **Business Logic & Real-Life Conditions**

### **Daily Work Flow:**
1. **Morning**: Employee starts day with location & station
2. **Throughout Day**: System tracks the active DWR
3. **Evening**: Employee ends day with expenses & remarks

### **Business Rules:**
- ✅ **One DWR per employee per day** (prevents duplicate starts)
- ✅ **Must start before ending** (logical workflow)
- ✅ **Auto-incremental DWR numbers** (unique tracking)
- ✅ **Timezone-aware date handling** (accurate daily records)
- ✅ **Employee-specific access** (security & privacy)

---

## 🔧 **API 1: Get Today's DWR Details**

### **Endpoint**
```
GET /api/employee/dwr/today
```

### **Authentication**
- **Required**: Bearer Token (Employee role)
- **Data Source**: Uses `USER_ID` from JWT token

### **Response - No DWR Found**
```json
{
  "success": true,
  "message": "No DWR found for today. You can start your day.",
  "data": null,
  "has_started_day": false,
  "today_date": "2023-12-13",
  "employee_id": 123
}
```

### **Response - DWR Found (Day Started)**
```json
{
  "success": true,
  "message": "Today's DWR details fetched successfully",
  "data": {
    "DWR_ID": 456,
    "DWR_EMP_ID": 123,
    "DWR_NO": 1001,
    "DWR_DATE": "2023-12-13T00:00:00.000Z",
    "DWR_STATUS": "Draft",
    "DWR_EXPENSES": null,
    "DWR_START_STA": "HQ Office",
    "DWR_END_STA": null,
    "DWR_START_LOC": "Mumbai Central",
    "DWR_END_LOC": null,
    "DWR_REMARKS": null,
    "DWR_SUBMIT": "2023-12-13T09:30:00.000Z",
    "DEL_STATUS": 0,
    "LAST_USER": "employee_john",
    "TIME_STAMP": "2023-12-13T09:30:00.000Z"
  },
  "has_started_day": true,
  "has_ended_day": false,
  "today_date": "2023-12-13",
  "employee_id": 123
}
```

### **Testing Example**
```bash
curl -X GET "http://localhost:3000/api/employee/dwr/today" \
  -H "Authorization: Bearer YOUR_EMPLOYEE_TOKEN_HERE"
```

---

## 🌅 **API 2: Start Your Day**

### **Endpoint**
```
POST /api/employee/dwr/start-day
```

### **Request Body**
```json
{
  "DWR_START_STA": "HQ Office",
  "DWR_START_LOC": "Mumbai Central, Platform 1"
}
```

### **Auto-Generated Fields**
- `DWR_ID`: Auto-increment primary key
- `DWR_EMP_ID`: From JWT token `USER_ID`
- `DWR_NO`: Incremental unique number
- `DWR_DATE`: Today's date (YYYY-MM-DD)
- `DWR_STATUS`: "Draft"
- `DEL_STATUS`: 0
- `DWR_SUBMIT`: Current timestamp
- `TIME_STAMP`: Current timestamp
- `LAST_USER`: From JWT token `USERNAME`

### **Success Response**
```json
{
  "success": true,
  "message": "Day started successfully!",
  "data": {
    "DWR_ID": 456,
    "DWR_EMP_ID": 123,
    "DWR_NO": 1001,
    "DWR_DATE": "2023-12-13T00:00:00.000Z",
    "DWR_STATUS": "Draft",
    "DWR_EXPENSES": null,
    "DWR_START_STA": "HQ Office",
    "DWR_END_STA": null,
    "DWR_START_LOC": "Mumbai Central, Platform 1",
    "DWR_END_LOC": null,
    "DWR_REMARKS": null,
    "DWR_SUBMIT": "2023-12-13T09:30:00.000Z",
    "DEL_STATUS": 0,
    "LAST_USER": "employee_john",
    "TIME_STAMP": "2023-12-13T09:30:00.000Z"
  },
  "dwr_id": 456,
  "dwr_no": 1001,
  "started_at": "2023-12-13T09:30:00.000Z",
  "employee_id": 123
}
```

### **Error Response - Already Started**
```json
{
  "success": false,
  "message": "You already started your day today",
  "existing_dwr_id": 456
}
```

### **Testing Example**
```bash
curl -X POST "http://localhost:3000/api/employee/dwr/start-day" \
  -H "Authorization: Bearer YOUR_EMPLOYEE_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{
    "DWR_START_STA": "HQ Office",
    "DWR_START_LOC": "Mumbai Central, Platform 1"
  }'
```

---

## 🌆 **API 3: End Your Day**

### **Endpoint**
```
PUT /api/employee/dwr/end-day
```

### **Request Body**
```json
{
  "DWR_EXPENSES": 250.50,
  "DWR_END_STA": "Branch Office",
  "DWR_END_LOC": "Andheri West, Office Complex",
  "DWR_REMARKS": "Visited 5 clients, completed all scheduled meetings"
}
```

### **Updated Fields**
- `DWR_STATUS`: "approved"
- `DWR_EXPENSES`: From request (optional, defaults to 0)
- `DWR_END_STA`: From request (required)
- `DWR_END_LOC`: From request (required)
- `DWR_REMARKS`: From request (optional, defaults to empty)
- `LAST_USER`: From JWT token `USERNAME`
- `TIME_STAMP`: Current timestamp

### **Success Response**
```json
{
  "success": true,
  "message": "Day ended successfully!",
  "data": {
    "DWR_ID": 456,
    "DWR_EMP_ID": 123,
    "DWR_NO": 1001,
    "DWR_DATE": "2023-12-13T00:00:00.000Z",
    "DWR_STATUS": "approved",
    "DWR_EXPENSES": 250.50,
    "DWR_START_STA": "HQ Office",
    "DWR_END_STA": "Branch Office",
    "DWR_START_LOC": "Mumbai Central, Platform 1",
    "DWR_END_LOC": "Andheri West, Office Complex",
    "DWR_REMARKS": "Visited 5 clients, completed all scheduled meetings",
    "DWR_SUBMIT": "2023-12-13T09:30:00.000Z",
    "DEL_STATUS": 0,
    "LAST_USER": "employee_john",
    "TIME_STAMP": "2023-12-13T18:30:00.000Z"
  },
  "dwr_id": 456,
  "ended_at": "2023-12-13T18:30:00.000Z",
  "total_expenses": 250.50,
  "employee_id": 123
}
```

### **Error Response - Not Started**
```json
{
  "success": false,
  "message": "You need to start your day first before ending it"
}
```

### **Error Response - Already Ended**
```json
{
  "success": false,
  "message": "You have already ended your day today",
  "dwr_id": 456
}
```

### **Testing Example**
```bash
curl -X PUT "http://localhost:3000/api/employee/dwr/end-day" \
  -H "Authorization: Bearer YOUR_EMPLOYEE_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{
    "DWR_EXPENSES": 250.50,
    "DWR_END_STA": "Branch Office",
    "DWR_END_LOC": "Andheri West, Office Complex",
    "DWR_REMARKS": "Visited 5 clients, completed all scheduled meetings"
  }'
```

---

## 📋 **Complete Testing Workflow**

### **Step 1: Check Today's Status**
```bash
curl -X GET "http://localhost:3000/api/employee/dwr/today" \
  -H "Authorization: Bearer YOUR_EMPLOYEE_TOKEN_HERE"
```

### **Step 2: Start Your Day**
```bash
curl -X POST "http://localhost:3000/api/employee/dwr/start-day" \
  -H "Authorization: Bearer YOUR_EMPLOYEE_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{
    "DWR_START_STA": "Main Office",
    "DWR_START_LOC": "Ground Floor Reception"
  }'
```

### **Step 3: Check Status Again (Should show started)**
```bash
curl -X GET "http://localhost:3000/api/employee/dwr/today" \
  -H "Authorization: Bearer YOUR_EMPLOYEE_TOKEN_HERE"
```

### **Step 4: End Your Day**
```bash
curl -X PUT "http://localhost:3000/api/employee/dwr/end-day" \
  -H "Authorization: Bearer YOUR_EMPLOYEE_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{
    "DWR_EXPENSES": 150.75,
    "DWR_END_STA": "Client Office",
    "DWR_END_LOC": "Bandra East, Floor 3",
    "DWR_REMARKS": "All tasks completed successfully"
  }'
```

### **Step 5: Final Status Check (Should show completed)**
```bash
curl -X GET "http://localhost:3000/api/employee/dwr/today" \
  -H "Authorization: Bearer YOUR_EMPLOYEE_TOKEN_HERE"
```

---

## ❌ **Error Scenarios & Responses**

### **Missing Required Fields (Start Day)**
```json
{
  "success": false,
  "message": "DWR_START_STA and DWR_START_LOC are required"
}
```

### **Missing Required Fields (End Day)**
```json
{
  "success": false,
  "message": "DWR_END_STA and DWR_END_LOC are required"
}
```

### **Authentication Errors**
```json
{
  "success": false,
  "message": "Access denied. Employee privileges required."
}
```

### **Duplicate Start Attempt**
```json
{
  "success": false,
  "message": "You already started your day today",
  "existing_dwr_id": 456
}
```

### **End Day Without Starting**
```json
{
  "success": false,
  "message": "You need to start your day first before ending it"
}
```

### **Duplicate End Attempt**
```json
{
  "success": false,
  "message": "You have already ended your day today",
  "dwr_id": 456
}
```

---

## 🛠️ **Postman Collection Setup**

### **Environment Variables:**
```
base_url: http://localhost:3000
employee_token: [GET FROM LOGIN]
```

### **Collection Structure:**
```
📁 DWR APIs
├── 📄 1. Get Today's DWR
├── 📄 2. Start Day
├── 📄 3. End Day
├── 📄 4. Error Test - Duplicate Start
└── 📄 5. Error Test - End Without Start
```

---

## 🔐 **Security Features**

1. **Employee-Only Access**: JWT token validation with employee role
2. **User Isolation**: Each employee can only access their own DWR data
3. **SQL Injection Protection**: Parameterized queries throughout
4. **Input Validation**: Required field validation and sanitization
5. **Business Logic Validation**: Prevents invalid workflow states
6. **Audit Trail**: Tracks who created/modified records with timestamps

---

## 📈 **Real-Life Use Cases**

### **For Field Employees:**
- 🌅 **Morning Check-in**: Start workday with current location
- 📍 **Location Tracking**: Record starting and ending stations
- 💰 **Expense Tracking**: Log daily work-related expenses
- 📝 **Daily Summary**: Add remarks about work completed
- 📊 **Attendance Proof**: Formal record of work hours

### **For Management:**
- 📈 **Attendance Monitoring**: Track employee work patterns
- 💳 **Expense Management**: Monitor daily expense claims
- 📍 **Location Oversight**: Verify employee work locations
- 📋 **Performance Tracking**: Review daily work summaries
- 🔍 **Audit Trail**: Complete record for compliance

---

## 📊 **Workflow States**

```mermaid
graph TD
    A[Employee Logs In] --> B[Check Today's DWR]
    B --> C{DWR Exists?}
    C -->|No| D[Start Day API]
    C -->|Yes| E{Day Started?}
    E -->|Yes| F{Day Ended?}
    F -->|No| G[End Day API]
    F -->|Yes| H[View Completed DWR]
    D --> I[DWR Created - Draft Status]
    G --> J[DWR Updated - Approved Status]
```

---

## ✅ **Status: PRODUCTION READY**

All 3 DWR APIs are:
- ✅ **Fully functional** with comprehensive business logic
- ✅ **Security validated** with role-based access control
- ✅ **Error handling** for all edge cases
- ✅ **Real-world tested** workflow implementation
- ✅ **Database optimized** with proper indexing considerations

---

## 🎯 **Quick Test Commands**

Replace `YOUR_EMPLOYEE_TOKEN_HERE` with actual token:

```bash
# Check today's status
curl -X GET "http://localhost:3000/api/employee/dwr/today" \
  -H "Authorization: Bearer YOUR_EMPLOYEE_TOKEN_HERE"

# Start your day
curl -X POST "http://localhost:3000/api/employee/dwr/start-day" \
  -H "Authorization: Bearer YOUR_EMPLOYEE_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{"DWR_START_STA":"Office","DWR_START_LOC":"Main Building"}'

# End your day
curl -X PUT "http://localhost:3000/api/employee/dwr/end-day" \
  -H "Authorization: Bearer YOUR_EMPLOYEE_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{"DWR_END_STA":"Field","DWR_END_LOC":"Client Site","DWR_EXPENSES":100}'
```

The DWR APIs are ready for immediate production use! 🚀 