# Retailer Profile Update API

## Endpoint
`PUT /api/retailers/my-retailer`

## Description
Allows authenticated retailers to update their profile information including profile photo upload.

## Headers
- `Authorization: Bearer {token}` - Required JWT token
- `Content-Type: multipart/form-data` - Required for file upload

## Request Body (form-data)

### Profile Image (Optional)
- **Field**: `profileImage`
- **Type**: File
- **Description**: Profile photo upload (JPG, PNG, GIF)
- **Max Size**: 5MB
- **Storage**: `uploads/retailers/profiles/`

### Profile Fields (All Optional)
- **RET_NAME** (text): Retailer full name
- **RET_SHOP_NAME** (text): Shop name
- **RET_ADDRESS** (text): Complete address
- **RET_EMAIL_ID** (text): Email address
- **RET_TYPE** (text): Retailer type (e.g., "wholesale", "retail")
- **RET_PIN_CODE** (text): Pin code
- **RET_COUNTRY** (text): Country
- **RET_STATE** (text): State
- **RET_CITY** (text): City
- **RET_GST_NO** (text): GST number
- **RET_LAT** (text): Latitude coordinates
- **RET_LONG** (text): Longitude coordinates
- **SHOP_OPEN_STATUS** (text): Shop open status ("Y" or "N")

## Response

### Success Response (200)
```json
{
  "success": true,
  "message": "Retailer profile updated successfully",
  "data": {
    "RET_ID": 1,
    "RET_CODE": "RET001",
    "RET_TYPE": "wholesale",
    "RET_NAME": "Updated Retailer Name",
    "RET_SHOP_NAME": "Updated Shop Name",
    "RET_MOBILE_NO": "9876543210",
    "RET_ADDRESS": "123 Updated Address, City",
    "RET_PIN_CODE": "123456",
    "RET_EMAIL_ID": "updated@email.com",
    "RET_PHOTO": "retailer_profile_1703123456789-123456789.jpg",
    "RET_PHOTO_URL": "http://localhost:3000/uploads/retailers/profiles/retailer_profile_1703123456789-123456789.jpg",
    "RET_COUNTRY": "India",
    "RET_STATE": "Maharashtra",
    "RET_CITY": "Mumbai",
    "RET_GST_NO": "22AAAAA0000A1Z5",
    "RET_LAT": "19.0760",
    "RET_LONG": "72.8777",
    "RET_DEL_STATUS": "active",
    "SHOP_OPEN_STATUS": "Y",
    "CREATED_DATE": "2023-12-01T10:00:00.000Z",
    "UPDATED_DATE": "2023-12-21T15:30:00.000Z",
    "CREATED_BY": "system",
    "UPDATED_BY": "9876543210"
  },
  "uploadedFile": {
    "filename": "retailer_profile_1703123456789-123456789.jpg",
    "url": "http://localhost:3000/uploads/retailers/profiles/retailer_profile_1703123456789-123456789.jpg"
  }
}
```

### Error Responses

#### 400 - No Fields Provided
```json
{
  "success": false,
  "message": "No fields provided for update"
}
```

#### 404 - User Not Found
```json
{
  "success": false,
  "message": "User not found"
}
```

#### 404 - Retailer Not Found
```json
{
  "success": false,
  "message": "No retailer profile found for your account"
}
```

#### 400 - File Upload Error
```json
{
  "success": false,
  "message": "File size too large. Maximum size is 5MB."
}
```

## Usage Examples

### 1. Update Only Profile Photo
```bash
curl -X PUT "http://localhost:3000/api/retailers/my-retailer" \
  -H "Authorization: Bearer your_jwt_token" \
  -F "profileImage=@/path/to/profile.jpg"
```

### 2. Update Only Text Fields
```bash
curl -X PUT "http://localhost:3000/api/retailers/my-retailer" \
  -H "Authorization: Bearer your_jwt_token" \
  -F "RET_NAME=New Retailer Name" \
  -F "RET_SHOP_NAME=New Shop Name" \
  -F "RET_EMAIL_ID=newemail@example.com"
```

### 3. Update Both Photo and Text Fields
```bash
curl -X PUT "http://localhost:3000/api/retailers/my-retailer" \
  -H "Authorization: Bearer your_jwt_token" \
  -F "profileImage=@/path/to/profile.jpg" \
  -F "RET_NAME=New Retailer Name" \
  -F "RET_SHOP_NAME=New Shop Name" \
  -F "RET_EMAIL_ID=newemail@example.com" \
  -F "SHOP_OPEN_STATUS=Y"
```

## Frontend Integration

### HTML Form
```html
<form enctype="multipart/form-data" method="PUT" action="/api/retailers/my-retailer">
  <input type="file" name="profileImage" accept="image/*" />
  <input type="text" name="RET_NAME" placeholder="Retailer Name" />
  <input type="text" name="RET_SHOP_NAME" placeholder="Shop Name" />
  <input type="email" name="RET_EMAIL_ID" placeholder="Email" />
  <input type="text" name="RET_ADDRESS" placeholder="Address" />
  <select name="SHOP_OPEN_STATUS">
    <option value="Y">Open</option>
    <option value="N">Closed</option>
  </select>
  <button type="submit">Update Profile</button>
</form>
```

### JavaScript/React Example
```javascript
const updateRetailerProfile = async (formData) => {
  try {
    const response = await fetch('/api/retailers/my-retailer', {
      method: 'PUT',
      headers: {
        'Authorization': `Bearer ${token}`
      },
      body: formData // FormData object with files and text fields
    });
    
    const result = await response.json();
    if (result.success) {
      console.log('Profile updated:', result.data);
      if (result.uploadedFile) {
        console.log('New photo URL:', result.uploadedFile.url);
      }
    }
  } catch (error) {
    console.error('Update failed:', error);
  }
};
```

## Database Changes
- Updates `retailer_info` table
- Only updates provided fields (partial updates supported)
- Automatically sets `UPDATED_DATE` to current timestamp
- Sets `UPDATED_BY` to user's mobile number
- Stores only filename in `RET_PHOTO` field
- Full image URL provided in response for frontend use

## Security Features
- JWT authentication required
- Only allows updating own retailer profile (based on mobile number match)
- File type validation (images only)
- File size validation (5MB max)
- Unique filename generation prevents conflicts
- Soft delete check (`RET_DEL_STATUS = 'active'`)

## Notes
- All fields are optional - you can update just photo, just text fields, or both
- If no photo is uploaded, existing photo remains unchanged
- Profile photo URLs are accessible at: `http://localhost:3000/uploads/retailers/profiles/{filename}`
- The API automatically finds retailer record based on authenticated user's mobile number 