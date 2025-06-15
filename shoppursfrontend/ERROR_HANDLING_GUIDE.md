# Error Handling System Documentation

This document describes the new comprehensive error handling system implemented in the Anwar Food application.

## Overview

The error handling system provides:

1. **User-friendly error messages** - No raw server errors exposed to users
2. **Maintenance popup** - Shown when server is unreachable (user cannot close until app restart)
3. **Consistent API error handling** - All API calls use standardized error responses
4. **Sanitized error messages** - Technical details are hidden from end users

## Components

### 1. ErrorHandler Service (`lib/services/error_handler.dart`)

Central service that handles all API errors and provides user-friendly messages.

**Key Features:**
- Processes HTTP responses and converts technical errors to user-friendly messages
- Shows maintenance popup for server connectivity issues
- Handles authentication errors (token expiry)
- Sanitizes endpoint URLs for logging (replaces actual server with localhost:3000)

### 2. MaintenancePopup Widget (`lib/widgets/maintenance_popup.dart`)

A non-dismissible popup shown when the server is unreachable.

**Features:**
- Cannot be closed by back button or tapping outside
- Only way to dismiss is by restarting the app
- Clean, informative UI explaining the situation

### 3. Enhanced HttpClient (`lib/services/http_client.dart`)

Updated to use the ErrorHandler for all API calls.

**Changes:**
- Returns `Map<String, dynamic>` instead of raw HTTP responses
- Automatically processes errors through ErrorHandler
- Supports BuildContext for showing popups

### 4. Error Message Widgets (`lib/widgets/error_message_widget.dart`)

Reusable widgets for displaying errors consistently across the app.

**Components:**
- `ErrorMessageWidget` - Full-screen error display
- `InlineErrorWidget` - Inline error display for forms/lists

## Usage Examples

### Making API Calls

```dart
// In your service
Future<Map<String, dynamic>> fetchData(BuildContext? context) async {
  final result = await HttpClient.get(
    '/api/endpoint',
    token: token,
    context: context, // Important for error handling
  );
  
  return result; // Already processed by ErrorHandler
}

// In your widget
void _loadData() async {
  final result = await _service.fetchData(context);
  
  if (result['success'] == true) {
    // Handle success
    setState(() {
      _data = result['data'];
    });
  } else {
    // Error already handled by ErrorHandler
    // Optionally show additional UI feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result['message'])),
    );
  }
}
```

### Displaying Errors

```dart
// Full-screen error
if (_hasError) {
  return ErrorMessageWidget(
    message: _errorMessage,
    onRetry: _loadData,
  );
}

// Inline error
if (_hasError) {
  return InlineErrorWidget(
    message: _errorMessage,
    onRetry: _loadData,
  );
}
```

## Error Message Examples

### Before (Raw Server Errors)
```
SocketException: Failed host lookup: '192.168.29.96'
Internal Server Error: Cannot read property 'id' of undefined
Database connection timeout after 30000ms
```

### After (User-Friendly Messages)
```
Unable to connect to server. Please check your internet connection.
Something went wrong. Please try again.
Server is temporarily unavailable. Please try again later.
```

### Logging/Debug Messages
```
localhost:3000/api/products/list - Error in fetching data
localhost:3000/api/auth/login - Error in fetching data
```

## Server Response Status Codes

| Status Code | User Message | Action |
|-------------|--------------|---------|
| 200-299 | Success | Process data normally |
| 400 | Invalid request. Please check your input and try again. | Show error message |
| 401 | Your session has expired. Please login again. | Redirect to login |
| 403 | You don't have permission to perform this action. | Show error message |
| 404 | The requested resource was not found. | Show error message |
| 500-504 | Server is temporarily unavailable. Please try again later. | Show maintenance popup |
| Network Error | Unable to connect to server. Please check your internet connection. | Show maintenance popup |

## Maintenance Popup Behavior

The maintenance popup is shown when:
- Network connection fails (SocketException)
- Server returns 5xx status codes
- Request timeout occurs

**Important:** Once shown, the popup cannot be dismissed until the user restarts the app. This ensures users don't get stuck in a broken state.

## Implementation Checklist

To update existing services to use the new error handling:

1. **Import the HttpClient**
   ```dart
   import 'http_client.dart';
   ```

2. **Update method signatures to include context**
   ```dart
   Future<Map<String, dynamic>> yourMethod({BuildContext? context}) async
   ```

3. **Replace direct HTTP calls with HttpClient methods**
   ```dart
   // Before
   final response = await http.get(Uri.parse(url));
   
   // After
   final result = await HttpClient.get('/endpoint', context: context);
   ```

4. **Return structured responses**
   ```dart
   return {
     'success': true/false,
     'message': 'User-friendly message',
     'data': actualData, // if success
   };
   ```

5. **Handle responses in UI**
   ```dart
   if (result['success'] == true) {
     // Handle success
   } else {
     // Error already handled, optionally show UI feedback
   }
   ```

## Benefits

1. **Better User Experience** - Users see helpful messages instead of technical errors
2. **Consistent Error Handling** - All errors are handled the same way across the app
3. **Server Protection** - Raw server errors and endpoints are not exposed
4. **Graceful Degradation** - App handles server outages gracefully with maintenance mode
5. **Developer Friendly** - Clear logging with sanitized endpoints for debugging

## Testing

To test the error handling system:

1. **Network Errors** - Turn off WiFi/mobile data and try API calls
2. **Server Errors** - Stop the backend server and try API calls
3. **Invalid Tokens** - Use expired/invalid auth tokens
4. **Maintenance Mode** - The popup should appear and be non-dismissible

The system will automatically show appropriate messages and popups based on the error type. 