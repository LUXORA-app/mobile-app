import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'settings': 'Settings',
      'language': 'Language',
      'profile': 'Profile',
      'appearance': 'Appearance',
      'logout': 'Log out',
      'favouriteList': 'Favourite List',
      'search': 'Search',
      'login': 'Login',
      'signup': 'Sign Up',
      'email': 'Email',
      'password': 'Password',
      'forgotPassword': 'Forgot Password?',
      'resetPassword': 'Reset Password',
      'confirmPassword': 'Confirm Password',
      'name': 'Name',
      'explore': 'Explore',
      'chatBot': 'Chat bot',
      'scan': 'Scan',
      'gallery': 'Gallery',
      'welcome': 'Welcome!',
      'emailAddress': 'Email Address',
      'notAMember': 'Not a member? ',
      'registerNow': 'Register now',
      'landmarks': 'Landmarks',
      'seeMore': 'See more',
      'noLandmarksYet': 'No landmarks yet',
      'pleaseLoginFirst': 'Please login first.',
      'unknownLocation': 'Unknown location',
      'noDescriptionAvailable': 'No description available.',
      'pleaseEnterEmailAndPassword': 'Please enter email and password.',
      'chatAssistant': 'Chat Assistant',
      'typeMessage': 'Type message...',
      'chooseModeThenTake': 'Choose mode, then take a photo or pick from gallery',
      'translate': 'Translate',
      'ancientTextTranslation': 'Ancient text translation',
      'landmark': 'Landmark',
      'landmarkRecognition': 'Landmark recognition',
      'tapToSelectImage': 'Tap to select an image',
      'openCamera': 'Open Camera',
      'chooseFromGallery': 'Choose from Gallery',
      'selectImageSource': 'Select Image Source',
      'takeAPhoto': 'Take a Photo',
      'openCameraToScanText': 'Open camera to scan text',
      'openCameraToDetectLandmarks': 'Open camera to detect landmarks',
      'pickTextImageForTranslation': 'Pick text image for translation',
      'pickLandmarkImageForRecognition': 'Pick landmark image for recognition',
      'cameraPermissionRequired': 'Camera permission is required to scan.',
      'cameraPermission': 'Camera Permission',
      'cameraPermissionDescription': 'We need camera access to scan and translate text or recognize landmarks. Please enable it in the app settings.',
      'cancel': 'Cancel',
      'noScansYet': 'No scans yet',
    },
    'ar': {
      'settings': 'الإعدادات',
      'language': 'اللغة',
      'profile': 'الملف الشخصي',
      'appearance': 'المظهر',
      'logout': 'تسجيل الخروج',
      'favouriteList': 'قائمة المفضلة',
      'search': 'بحث',
      'login': 'تسجيل الدخول',
      'signup': 'إنشاء حساب',
      'email': 'البريد الإلكتروني',
      'password': 'كلمة المرور',
      'forgotPassword': 'نسيت كلمة المرور؟',
      'resetPassword': 'إعادة تعيين كلمة المرور',
      'confirmPassword': 'تأكيد كلمة المرور',
      'name': 'الاسم',
      'explore': 'استكشف',
      'chatBot': 'شات بوت',
      'scan': 'مسح',
      'gallery': 'معرض الصور',
      'welcome': 'مرحباً!',
      'emailAddress': 'البريد الإلكتروني',
      'notAMember': 'لست عضواً؟ ',
      'registerNow': 'سجل الآن',
      'landmarks': 'المعالم',
      'seeMore': 'عرض المزيد',
      'noLandmarksYet': 'لا توجد معالم بعد',
      'pleaseLoginFirst': 'يرجى تسجيل الدخول أولاً.',
      'unknownLocation': 'موقع غير معروف',
      'noDescriptionAvailable': 'لا يوجد وصف متاح.',
      'pleaseEnterEmailAndPassword': 'يرجى إدخال البريد الإلكتروني وكلمة المرور.',
      'chatAssistant': 'مساعد الشات',
      'typeMessage': 'اكتب رسالة...',
      'chooseModeThenTake': 'اختر الوضع، ثم اصور أو اختر من المعرض',
      'translate': 'ترجمة',
      'ancientTextTranslation': 'ترجمة النصوص القديمة',
      'landmark': 'معلم',
      'landmarkRecognition': 'التعرف على المعالم',
      'tapToSelectImage': 'اضغط لاختيار صورة',
      'openCamera': 'افتح الكاميرا',
      'chooseFromGallery': 'اختر من المعرض',
      'selectImageSource': 'اختر مصدر الصورة',
      'takeAPhoto': 'اصور',
      'openCameraToScanText': 'افتح الكاميرا لمسح النص',
      'openCameraToDetectLandmarks': 'افتح الكاميرا لاكتشاف المعالم',
      'pickTextImageForTranslation': 'اختر صورة نص للترجمة',
      'pickLandmarkImageForRecognition': 'اختر صورة معلم للتعرف',
      'cameraPermissionRequired': 'إذن الكاميرا مطلوب للمسح.',
      'cameraPermission': 'إذن الكاميرا',
      'cameraPermissionDescription': 'نحتاج إلى الوصول إلى الكاميرا لمسح وترجمة النصوص أو التعرف على المعالم. يرجى تفعيله في إعدادات التطبيق.',
      'cancel': 'إلغاء',
      'noScansYet': 'لا توجد مسحيات بعد',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]![key] ?? key;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'ar'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
