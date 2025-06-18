# AnwarFood Mobile App - APK Installation Guide

## 📱 APK Files Generated

Updated APK files have been created in `build/app/outputs/flutter-apk/`:

1. **app-release.apk** (24.9MB) - Production version with enhanced mobile connectivity
2. **app-debug.apk** (90MB) - Debug version with detailed logging

## 🆕 Latest Updates (v1.0.1)

- ✅ Enhanced mobile connectivity checking
- ✅ Better error handling for network issues
- ✅ Automatic API server health checks
- ✅ User-friendly connectivity error messages
- ✅ Improved CORS handling for development

## 🚀 Installation Steps

### For Android Devices:

1. **Enable Unknown Sources:**
   - Go to Settings > Security > Unknown Sources
   - Enable "Allow installation of apps from unknown sources"

2. **Install the APK:**
   - Transfer the APK file to your Android device
   - Tap on the APK file to install
   - Follow the installation prompts

3. **Grant Permissions:**
   - Allow internet access when prompted
   - Grant any other required permissions

## 🌐 API Configuration

The app is configured to connect to: **http://192.168.29.96:3000**

### Network Requirements:
- ✅ HTTPS connections enabled
- ✅ Internet permission granted
- ✅ Network security configuration set
- ✅ 30-second timeout for API calls

## 🔧 Troubleshooting API Issues

### If the app shows "No internet connection" or API errors:

1. **Check Internet Connection:**
   - Ensure your device has active internet
   - Try opening a web browser and visiting http://192.168.29.96:3000

2. **Clear App Data:**
   - Go to Settings > Apps > AnwarFood
   - Tap "Storage" > "Clear Data"
   - Restart the app

3. **Check Firewall/VPN:**
   - Disable any VPN or firewall that might block HTTPS requests
   - Some corporate networks block external API calls

4. **Use Debug APK:**
   - Install the debug version (app-debug.apk)
   - Check logs using `adb logcat` to see detailed error messages

## 📋 Debug Information

When you start the app, it will log the following in the console:

```
=== SERVICE URL VERIFICATION ===
API Config Base URL: http://192.168.29.96:3000
HTTP Client Base URL: http://192.168.29.96:3000
Auth Service Base URL: http://192.168.29.96:3000
Product Service Base URL: http://192.168.29.96:3000
Category Service Base URL: http://192.168.29.96:3000
Cart Service Base URL: http://192.168.29.96:3000
Address Service Base URL: http://192.168.29.96:3000
================================
```

## 🔍 Testing API Connectivity

To test if the API is working:

1. **Manual Test:**
   - Open browser on your phone
   - Visit: http://192.168.29.96:3000
   - You should see a response from the server

2. **App Test:**
   - Try to sign up or log in
   - Check if categories load on the home screen
   - Monitor for any error messages

## 📱 Device Requirements

- **Minimum Android Version:** 5.0 (API level 21)
- **Target Android Version:** 14 (API level 34)
- **Internet Connection:** Required
- **Storage:** ~30MB free space

## 🆔 App Details

- **Package Name:** com.anwarfood.app
- **Version:** 1.0.0
- **Version Code:** 1

## 🐛 Common Issues & Solutions

### Issue: "App not installed"
**Solution:** Enable unknown sources and ensure enough storage space

### Issue: "Network error occurred"
**Solution:** Check internet connection and try again

### Issue: "No authentication token found"
**Solution:** Clear app data and log in again

### Issue: App crashes on startup
**Solution:** Restart device and try again, or use debug APK for more info

## 📞 Support

If you encounter any issues:
1. Try the debug APK first
2. Check the troubleshooting steps above
3. Ensure your backend server (http://192.168.29.96:3000) is running
4. Verify API endpoints are accessible

---

**Note:** The app is configured to work with the production API at http://192.168.29.96:3000. Make sure your backend server is deployed and accessible from mobile networks. 