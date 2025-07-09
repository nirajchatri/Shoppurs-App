# Payment API Documentation

## Setup

### 1. Environment Variables
Add the following to your `.env` file:

```env
RAZORPAY_KEY_ID=your_razorpay_key_id_here
RAZORPAY_KEY_SECRET=your_razorpay_key_secret_here
```

### 2. Installation
Razorpay SDK is already installed in the project dependencies.

## API Endpoints

### Create Payment Order

**Endpoint:** `POST /api/payment/create-order`

**Description:** Creates a new Razorpay order for payment processing.

**Request Body:**
```json
{
  "amount": 100,
  "currency": "INR",
  "receipt": "receipt_001"
}
```

**Parameters:**
- `amount` (required): Amount in rupees (will be automatically converted to paise)
- `currency` (optional): Currency code (default: "INR")
- `receipt` (optional): Custom receipt ID (auto-generated if not provided)

**Success Response (200):**
```json
{
  "success": true,
  "message": "Order created successfully",
  "data": {
    "orderId": "order_MKxxxxxxxxxxx",
    "amount": 10000,
    "currency": "INR",
    "receipt": "receipt_001",
    "status": "created",
    "created_at": 1703123456
  }
}
```

**Error Response (400/500):**
```json
{
  "success": false,
  "message": "Amount is required",
  "error": "Additional error details"
}
```

### Verify Payment (Optional)

**Endpoint:** `POST /api/payment/verify-payment`

**Description:** Verifies the payment signature from Razorpay.

**Request Body:**
```json
{
  "razorpay_order_id": "order_MKxxxxxxxxxxx",
  "razorpay_payment_id": "pay_MKxxxxxxxxxxx",
  "razorpay_signature": "signature_string"
}
```

**Success Response (200):**
```json
{
  "success": true,
  "message": "Payment verified successfully",
  "data": {
    "orderId": "order_MKxxxxxxxxxxx",
    "paymentId": "pay_MKxxxxxxxxxxx",
    "verified": true
  }
}
```

## Usage Example

### cURL Example
```bash
curl -X POST http://localhost:3000/api/payment/create-order \
  -H "Content-Type: application/json" \
  -d '{
    "amount": 100,
    "currency": "INR",
    "receipt": "test_receipt_001"
  }'
```

### JavaScript Example
```javascript
const createOrder = async () => {
  try {
    const response = await fetch('/api/payment/create-order', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        amount: 100, // ₹100
        currency: 'INR',
        receipt: 'order_001'
      })
    });
    
    const data = await response.json();
    
    if (data.success) {
      console.log('Order created:', data.data.orderId);
      // Use this orderId to initiate Razorpay payment
    }
  } catch (error) {
    console.error('Error creating order:', error);
  }
};
```

## Important Notes

1. **Amount Conversion**: The API automatically converts rupees to paise (₹1 = 100 paise)
2. **Environment Variables**: Make sure to set your Razorpay credentials in the `.env` file
3. **Security**: Never expose your Razorpay key secret in frontend code
4. **Testing**: Use Razorpay test keys for development and testing

## Integration with Frontend

After creating an order, use the returned `orderId` to initialize Razorpay payment on the frontend:

```javascript
const options = {
  key: 'your_razorpay_key_id', // Use your Razorpay Key ID
  amount: data.data.amount, // Amount in paise
  currency: data.data.currency,
  name: 'Your Company Name',
  description: 'Payment for order',
  order_id: data.data.orderId, // Order ID from create-order API
  handler: function (response) {
    // Handle successful payment
    console.log('Payment successful:', response);
  },
  prefill: {
    name: 'Customer Name',
    email: 'customer@example.com',
    contact: '9999999999'
  }
};

const rzp = new Razorpay(options);
rzp.open();
``` 