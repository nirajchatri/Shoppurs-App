# AnwarFood APK Build Information

## 📱 Latest Build Details

**Build Date:** May 27, 2025  
**Version:** 1.0.1 (Build 2)  
**Package:** com.anwarfood.app

## 📦 APK Files Generated

### Release APK (Production)
- **File:** `app-release.apk`
- **Size:** 24.9MB
- **Location:** `build/app/outputs/flutter-apk/app-release.apk`
- **Use:** Install on devices for production use

### Debug APK (Testing)
- **File:** `app-debug.apk`
- **Size:** 90.3MB
- **Location:** `build/app/outputs/flutter-apk/app-debug.apk`
- **Use:** Install for testing with detailed logs

## 🔧 Build Configuration

- **Minimum Android Version:** 5.0 (API 21)
- **Target Android Version:** 14 (API 34)
- **Architecture:** Universal APK (supports all devices)
- **Permissions:** Internet, Network State
- **Network Security:** HTTPS only, configured for anwarfood.onrender.com

## 🌐 API Configuration

- **Base URL:** http://192.168.29.96:3000
- **Health Check:** http://192.168.29.96:3000/health
- **Timeout:** 30 seconds
- **CORS:** Configured for web development

## ✅ Features Included

- ✅ Enhanced mobile connectivity checking
- ✅ Automatic API server health verification
- ✅ User-friendly error handling
- ✅ Network troubleshooting guidance
- ✅ Proper Android permissions
- ✅ HTTPS-only security configuration
- ✅ Debug logging for troubleshooting

## 📱 Installation Instructions

1. **Transfer APK to Android device**
2. **Enable "Unknown Sources" in device settings**
3. **Tap APK file to install**
4. **Grant internet permissions when prompted**

## 🔍 Testing Checklist

- [ ] APK installs successfully
- [ ] App opens without crashes
- [ ] Internet connectivity check works
- [ ] API calls succeed (login/signup)
- [ ] Error messages are user-friendly
- [ ] App works on both WiFi and mobile data

## 🐛 Troubleshooting

If you encounter issues:

1. **Use Debug APK** for detailed error logs
2. **Check internet connection** - visit http://192.168.29.96:3000 in browser
3. **Clear app data** if needed
4. **Try different network** (WiFi vs mobile data)

## 📞 Support

- **API Status:** http://192.168.29.96:3000/health
- **Debug Logs:** Use `adb logcat | grep flutter` with debug APK
- **Network Test:** Visit http://192.168.29.96:3000 in mobile browser

---

**Note:** This build includes your latest code changes and is ready for deployment on Android devices. 