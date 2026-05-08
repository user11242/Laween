import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:laween/core/providers/locale_provider.dart';

class AppLocalizations {
  final String languageCode;

  AppLocalizations(this.languageCode);

  bool get isAr => languageCode == 'ar';
  String get google => isAr ? "جوجل" : "Google";
  String get cancel => isAr ? "إلغاء" : "Cancel";

  static AppLocalizations? of(BuildContext context, {bool listen = true}) {
    try {
      final locale = Provider.of<LocaleProvider>(
        context,
        listen: listen,
      ).locale;
      return AppLocalizations(locale.languageCode);
    } catch (_) {
      return AppLocalizations('en');
    }
  }

  String get onboardingTitle =>
      isAr ? "مرحباً بكم في لوين!" : "Welcome to Laween!";
  String get onboardingSubtitle => isAr
      ? "نجعل اللقاءات أسهل للجميع."
      : "Making meetups easier for everyone.";
  String get onboardingSmallSubtitle =>
      isAr ? "تواصل، اختر، والتقِ." : "Connect, choose, and meet.";
  String get joinWithGoogle =>
      isAr ? "سجل باستخدام جوجل" : "Sign up with Google";
  String get joinWithEmail =>
      isAr ? "سجل باستخدام البريد الإلكتروني" : "Sign up with Email";
  String get alreadyHaveAccount =>
      isAr ? "هل لديك حساب بالفعل؟ " : "Already have an account? ";
  String get signIn => isAr ? "تسجيل الدخول" : "Sign In";
  String get signInWithGoogle =>
      isAr ? "تسجيل الدخول باستخدام جوجل" : "Sign in with Google";
  String get signInWithEmail =>
      isAr ? "تسجيل الدخول بالبريد الإلكتروني" : "Sign in with Email";
  String get dontHaveAccount =>
      isAr ? "ليس لديك حساب؟ " : "Don't have an account? ";
  String get signUpNow => isAr ? "سجل الآن" : "Sign up";
  String get loginTitle => isAr ? "دعنا نلتقي!" : "Let's Meet Up!";
  String get loginSubtitle =>
      isAr ? "مكان الاستراحة في انتظارك." : "Your hangout is waiting.";

  String get paste => isAr ? "لصق" : "Paste";
  String get invalidPassword =>
      isAr ? "كلمة مرور غير صالحة." : "Invalid password.";
  String get continueRegistrationWithGoogle =>
      isAr ? "متابعة التسجيل بجوجل" : "Continue registration with Google";
  String get continueWithGoogle =>
      isAr ? "المتابعة باستخدام جوجل" : "Continue with Google";
  String get maybeLater => isAr ? "ربما لاحقاً" : "Maybe later";
  String get invalidMobileNumber =>
      isAr ? "رقم الهاتف المحمول غير صالح" : "Invalid mobile number";
  String get checkInbox => isAr ? "تحقق من بريدك الوارد." : "Check your inbox.";
  String get otpSent => isAr ? "رقم سري متغير مرسل" : "OTP Sent";
  String get smsSent => isAr ? "تم إرسال رسالة نصية قصيرة" : "SMS Sent";
  String get checkMessages => isAr ? "تحقق من رسائلك." : "Check your messages.";
  String get smsError => isAr ? "خطأ في الرسالة" : "SMS Error";
  String get error => isAr ? "خطأ" : "Error";
  String get inputError => isAr ? "خطأ في الإدخال" : "Input Error";
  String get enter6Digits => isAr ? "أدخل ٦ أرقام" : "Enter 6 digits";
  String get idMissing => isAr ? "الرقم التعريفي مفقود" : "ID Missing";
  String get incorrectCode => isAr ? "رمز غير صحيح" : "Incorrect Code";
  String get pleaseTryAgain =>
      isAr ? "أعد المحاولة من فضلك." : "Please try again.";
  String get verificationFailed =>
      isAr ? "فشل التحقق." : "Verification failed.";
  String get resendCode => isAr ? "إعادة إرسال الرمز" : "Resend Code";
  String get unavailable => isAr ? "غير متاح" : "Unavailable";
  String get phoneNumberInUse =>
      isAr ? "رقم الهاتف قيد الاستخدام" : "Phone number in use";
  String get required => isAr ? "مطلوب" : "Required";
  String get enterPhone => isAr ? "أدخل رقم هاتفك" : "Enter your phone number";
  String get termsRequired => isAr ? "الشروط مطلوبة" : "Terms Required";
  String get acceptTermsToFinish =>
      isAr ? "اقبل الشروط للانتهاء" : "Accept terms to finish";
  String get finish => isAr ? "انتهاء" : "Finish";
  String get next => isAr ? "التالي" : "Next";
  String get accountUnderReview =>
      isAr ? "حسابك قيد المراجعة" : "Your account is under review";
  String get iAccept => isAr ? "انا اوافق على " : "I accept ";
  String get termsAndConditions =>
      isAr ? "الشروط والأحكام" : "Terms and Conditions";
  String get and => isAr ? " و " : " and ";
  String get privacyPolicy => isAr ? "سياسة الخصوصية" : "Privacy Policy";
  String get verifyIdentity => isAr ? "تحقق من الهوية" : "Verify Identity";
  String get phoneNumber => isAr ? "رقم الهاتف" : "Phone Number";
  String get enterPortfolio =>
      isAr ? "أدخل رابط المحفظة" : "Enter portfolio link";
  String get invalidPortfolio =>
      isAr ? "رابط المحفظة غير صالح" : "Invalid portfolio link";
  String get finalizing => isAr ? "وضع اللمسات النهائية..." : "Finalizing...";
  String get finishAndRegister => isAr ? "إنهاء وتسجيل" : "Finish and Register";

  // Chat
  String get sayHello => isAr ? "قل مرحباً لبدء المحادثة!" : "Say hello to start the conversation!";

  // Group Settings
  String get leaveGroup => isAr ? "مغادرة المجموعة" : "Leave Group";
  String get leaveGroupConfirm => isAr ? "هل أنت متأكد أنك تريد مغادرة هذه المجموعة؟" : "Are you sure you want to leave this group?";
  String get leave => isAr ? "مغادرة" : "Leave";
  String get deleteGroup => isAr ? "حذف المجموعة" : "Delete Group";
  String get deleteGroupConfirm => isAr ? "هل أنت متأكد أنك تريد حذف هذه المجموعة نهائياً؟ لا يمكن التراجع عن هذا الإجراء." : "Are you sure you want to permanently delete this group? This action cannot be undone.";
  String get delete => isAr ? "حذف" : "Delete";
  String get allVerified =>
      isAr ? "تم التحقق من جميع الخطوات" : "All steps verified";
  String get allDone => isAr ? "تم الانتهاء" : "All Done";
  String get verifyEmail => isAr ? "التحقق من البريد" : "Verify Email";
  String get verifyPhone => isAr ? "التحقق من الهاتف" : "Verify Phone";
  String get password => isAr ? "كلمة المرور" : "Password";
  String get linkAccountButton => isAr ? "ربط الحساب" : "Link Account";
  String get deleteAccountConfirmMessage =>
      isAr ? "تأكيد الحذف" : "Confirm deletion";
  String get deleteMyAccount => isAr ? "حذف حسابي" : "Delete Account";
  String get success => isAr ? "نجاح" : "Success";
  String get applicationRejectedTitle =>
      isAr ? "تم رفض الطلب" : "Application Rejected";
  String get applicationRejectedMessage =>
      isAr ? "تفاصيل الرسالة" : "Message details";
  String get contactSupport => isAr ? "اتصل بالدعم" : "Contact Support";
  String get signOut => isAr ? "تسجيل الخروج" : "Sign Out";
  String get termsAndConditionsContent =>
      isAr ? "محتوى الشروط" : "Terms content";
  String get userFinishMessage =>
      isAr ? "تم التسجيل بنجاح" : "User registered successfully";
  String get portfolioLink => isAr ? "رابط المحفظة" : "Portfolio Link";
  String get portfolioHint => isAr ? "أدخل الرابط" : "Enter link";
  String get needDetails => isAr ? "نحن نحتاج الى تفاصيل" : "Need details";
  String get linkAccountTitle => isAr ? "ربط الحساب" : "Link Account";
  String get linkAccountMessage => isAr
      ? "هذا البريد الإلكتروني مسجل بالفعل بكلمة مرور. أدخل كلمة المرور لربط حساب جوجل الخاص بك."
      : "This email is already registered with a password. Enter your password to link your Google account.";
  String get logoutConfirmationTitle => isAr ? "تسجيل خروج" : "Logout";
  String get logoutConfirmationMessage => isAr
      ? "هل أنت متأكد أنك تريد تسجيل الخروج؟"
      : "Are you sure you want to logout?";
  String get stayLoggedIn => isAr ? "البقاء" : "Stay";
  String get logoutAnyway => isAr ? "خروج" : "Logout";
  String get logout => isAr ? "تسجيل خروج" : "Logout";
  String get accountPendingApproval => isAr ? "الحساب معلق" : "Account Pending";
  String get accountPendingPageNote =>
      isAr ? "حسابك قيد المراجعة" : "Your account is pending review";
  String get deleteAccountConfirmTitle =>
      isAr ? "حذف الحساب" : "Delete Account";

  String resendIn(int seconds) =>
      isAr ? "إعادة الإرسال خلال ($seconds)" : "Resend in $seconds";
  String enterCodeSentTo(String dest) =>
      isAr ? "أدخل الرمز المرسل إلى: $dest" : "Enter code sent to $dest";
  String stepOf(int step, int total) =>
      isAr ? "خطوة $step من $total" : "Step $step of $total";
  String welcomeUser(String? name) => isAr ? "مرحباً $name" : "Welcome $name";

  String get createAccount => isAr ? "إنشاء حساب" : "Create Account";
  String get welcome => isAr ? "مرحباً!" : "Welcome!";
  String get welcomeSubtitle => isAr
      ? "أنشئ حسابك للبدء في التخطيط\nللجلسات مع الأصدقاء"
      : "Create your account to start planning\nhangouts with friends";
  String get fullName => isAr ? "الاسم الكامل" : "Full Name";
  String get email => isAr ? "البريد الإلكتروني" : "Email";
  String get confirmPassword => isAr ? "تأكيد كلمة المرور" : "Confirm Password";
  String get orContinueWith =>
      isAr ? "أو المتابعة باستخدام" : "Or Continue with";
  String get nameTaken =>
      isAr ? "اسم المستخدم مستخدم بالفعل" : "Username is already taken";
  String get emailTaken =>
      isAr ? "البريد الإلكتروني مسجل بالفعل" : "Email is already registered";
  String get phoneTaken =>
      isAr ? "رقم الهاتف مستخدم بالفعل" : "Phone number is already in use";
  String get continueText => isAr ? "متابعة" : "Continue";

  String get invalidUsername => isAr
      ? "يجب أن يكون اسم المستخدم بين ٣ و ٣٠ حرفاً ولا يمكن أن يكون أرقاماً أو رموزاً فقط"
      : "Username must be 3-30 characters and cannot be only numbers or symbols";
  String get invalidEmail => isAr
      ? "يرجى إدخال بريد إلكتروني صالح"
      : "Please enter a valid email address";
  String get weakPassword => isAr
      ? "يجب أن تكون كلمة المرور ٨ أحرف على الأقل وتحتوي على حرف كبير ورقم ورقم ورمز"
      : "Password must be at least 8 characters long and include a capital letter, a number, and a symbol";
  String get passwordsDoNotMatch =>
      isAr ? "كلمات المرور غير متطابقة" : "Passwords do not match";
  String get invalidPhoneJordan => isAr
      ? "يجب أن يبدأ رقم الهاتف في الأردن بـ ٠٧٩ أو ٠٧٨ أو ٠٧٧"
      : "Jordanian phone numbers must start with 079, 078, or 077";

  // Login Page
  String get loginLabel => isAr ? "تسجيل الدخول" : "Log In";
  String get enterPhoneToLogin => isAr
      ? "أدخل رقم هاتفك لتسجيل الدخول"
      : "Enter your phone number to log in";
  String get forgotPasswordQ => isAr ? "نسيت كلمة المرور؟" : "Forgot Password?";
  String get loginWithFaceId =>
      isAr ? "المتابعة باستخدام بصمة الوجه" : "Continue with Face ID";

  // Forgot Password Page
  String get forgotPasswordTitle =>
      isAr ? "نسيت كلمة المرور" : "Forgot Password";
  String get forgotPasswordDesc => isAr
      ? "أدخل رقم هاتفك لتلقي رمز التحقق."
      : "Enter your phone number to receive a verification code.";
  String get verify => isAr ? "تحقق" : "Verify";
  String get enterPhoneError =>
      isAr ? "يرجى إدخال رقم الهاتف" : "Please enter phone number";
  String get pleaseEnterEmailAndPassword => isAr
      ? "يرجى إدخال البريد الإلكتروني وكلمة المرور"
      : "Please enter email and password";
  String get loginError => isAr ? "فشل تسجيل الدخول" : "Login Failed";

  // Face ID Dialog
  String get faceIdUnavailableTitle =>
      isAr ? "بصمة الوجه غير متوفرة" : "Face ID unavailable";
  String get faceIdUnavailableMessage => isAr
      ? "لا يمكن استخدام بصمة الوجه الآن. قم بإعدادها على جهازك، أو قم بتسجيل الدخول باستخدام البريد الإلكتروني وكلمة المرور"
      : "Face ID can't be used right now. Set it up on your device, or sign in with your email and password";
  String get useEmailAndPassword =>
      isAr ? "استخدام البريد الإلكتروني" : "Use Email and Password";

  // Create New Password Page
  String get createNewPasswordTitle =>
      isAr ? "إنشاء كلمة مرور جديدة" : "Create New Password";
  String get createNewPasswordDesc => isAr
      ? "أنشئ كلمة مرور جديدة لتسجيل الدخول."
      : "Create your new password to login.";
  String get createNewPasswordButton =>
      isAr ? "إنشاء كلمة مرور" : "Create Password";

  // OTP & Verification
  String get otpVerificationTitle =>
      isAr ? "التحقق من الرمز" : "OTP Verification";
  String get otpSendDesc => isAr
      ? "أدخل رمز التحقق الذي أرسلناه للتو على رقم هاتفك."
      : "Enter the verification code we just sent on your phone number.";
  String get didntReceiveCode =>
      isAr ? "لم تصلك الرسالة؟ " : "Didn't receive code? ";
  String get resend => isAr ? "إعادة إرسال" : "Resend";
  String get yourPhoneNumber => isAr ? "رقم هاتفك" : "Your Phone Number";

  // Forgot Password Overhaul
  String get resetPassword =>
      isAr ? "إعادة تعيين كلمة المرور" : "Reset Password";
  String get resetYourPassword =>
      isAr ? "إعادة تعيين كلمة المرور" : "Reset Your Password";
  String get resetPasswordDesc => isAr
      ? "أدخل رقم هاتفك وسنرسل لك رمزاً لإعادة تعيين كلمة المرور الخاصة بك"
      : "Enter your phone number and we'll send you a code to reset your password";
  String get sendCode => isAr ? "إرسال الرمز" : "Send Code";
  String get backToLogin => isAr ? "العودة لتسجيل الدخول" : "Back to Login";
  String get enterOtp => isAr ? "أدخل رمز التحقق" : "Enter OTP";
  String get weSentCodeTo => isAr ? "أرسلنا رمزاً إلى" : "We sent a code to";
  String resendCodeIn(String time) =>
      isAr ? "إعادة إرسال الرمز خلال $time" : "Resend code in $time";
  String get createNewPasswordSubtitle => isAr
      ? "يجب أن تكون كلمة المرور الجديدة مختلفة عن كلمات المرور المستخدمة سابقاً"
      : "Your new password must be different from previously used passwords";
  String get atLeast8Chars =>
      isAr ? "٨ أحرف على الأقل" : "At least 8 characters";
  String get oneNumber => isAr ? "رقم واحد" : "One number";
  String get oneUppercase => isAr ? "حرف واحد كبير" : "One uppercase letter";
  String get passwordChanged =>
      isAr ? "تم تغيير كلمة المرور" : "Password Changed";
  String get passwordChangedSuccessfully => isAr
      ? "تم تغيير كلمة المرور بنجاح، يرجى تسجيل الدخول!"
      : "Your password has been changed successfully, please login!";
  String get verification => isAr ? "التحقق" : "Verification";
  String get newPassword => isAr ? "كلمة مرور جديدة" : "New Password";

  // Bottom Navigation Bar
  String get home => isAr ? "الرئيسية" : "Home";
  String get groups => isAr ? "المجموعات" : "Groups";
  String get favorite => isAr ? "المفضلة" : "Favorites";
  String get profile => isAr ? "الملف الشخصي" : "Profile";

  // Groups
  String get search => isAr ? "بحث..." : "search...";
  String get createGroup => isAr ? "إنشاء مجموعة" : "Create Group";
  String get joinGroup => isAr ? "الانضمام لمجموعة" : "Join Group";
  String get makeNewGroupDesc => isAr
      ? "أنشئ مجموعة جديدة لقضاء وقت ممتع"
      : "Make a new group for your hangouts";
  String get enterCodeToJoinDesc => isAr
      ? "أدخل الرمز للانضمام لمجموعة موجودة"
      : "Enter a code to join an existing group";
  String get createANewGroup =>
      isAr ? "إنشاء مجموعة جديدة" : "Create a New Group";
  String get groupName => isAr ? "اسم المجموعة" : "Group Name";
  String get members => isAr ? "الأعضاء" : "Members";
  String get addMembers => isAr ? "إضافة أعضاء" : "Add Members";
  String get scanQr => isAr ? "مسح QR" : "Scan QR";
  String get enterCode => isAr ? "إدخال الرمز" : "Enter Code";
  String get scanToJoin => isAr ? "امسح للانضمام" : "Scan to Join";
  String get pointCameraDesc => isAr
      ? "وجه كاميرتك نحو رمز QR الخاص بالمجموعة للانضمام فوراً"
      : "Point your camera at the group's QR code to join instantly";
  String get openCamera => isAr ? "فتح الكاميرا" : "Open Camera";
  String get enterGroupCode => isAr ? "أدخل رمز المجموعة" : "Enter Group Code";
  String get type6DigitCodeDesc => isAr
      ? "اكتب الرمز المكون من 6 أرقام المشترك من إعدادات المجموعة"
      : "Type the 6-digit code shared by the group settings";

  // Profile
  String get editProfile => isAr ? "تعديل الملف الشخصي" : "Edit Profile";
  String get myFavorites => isAr ? "مفضلاتي" : "My Favorites";
  String get language => isAr ? "اللغة" : "Language";
  String get darkMode => isAr ? "الوضع الليلي" : "Dark Mode";
  String get aboutLaween => isAr ? "عن لاوين" : "About Laween";
  String get logoutConfirm => isAr
      ? "هل أنت متأكد أنك تريد تسجيل الخروج؟"
      : "Are you sure you want to logout?";
  String get settings => isAr ? "الإعدادات" : "Settings";
  String get selectLanguage => isAr ? "اختر اللغة" : "Select Language";
  String get english => isAr ? "الإنجليزية" : "English";
  String get arabic => isAr ? "العربية" : "Arabic";
  String get save => isAr ? "حفظ" : "Save";
  String get phone => isAr ? "رقم الهاتف" : "Phone Number";
  String get successUpdate =>
      isAr ? "تم تحديث البيانات بنجاح" : "Information updated successfully";
  String get notifications => isAr ? "التنبيهات" : "Notifications";
  String get biometricVerificationTitle =>
      isAr ? "تأكيد كلمة المرور" : "Verify Password";
  String get biometricVerificationMessage => isAr
      ? "لتفعيل الدخول بالبصمة، يرجى إدخال كلمة المرور لحفظ بياناتك بشكل آمن."
      : "To enable biometric login, please enter your password to securely save your credentials.";
  String get enableBiometric => isAr ? "تفعيل" : "Enable";

  // New location and outings strings
  String get savedPlaces => isAr ? "الأماكن المحفوظة" : "Saved Places";
  String get outingsHistory => isAr ? "سجل الخرجات" : "Outing History";
  String get shareLocation => isAr ? "مشاركة الموقع" : "Share Location";
  String get shareLiveLocation => isAr ? "مشاركة الموقع المباشر" : "Share Live Location";
  String get shareLiveDesc => isAr ? "مشاركة إحداثياتك المباشرة" : "Share your real-time coordinates";
  String get chooseOnMap => isAr ? "اختر على الخريطة" : "Choose on Map";
  String get chooseOnMapDesc => isAr ? "تحديد موقع يدوياً على الخريطة" : "Manually pin a location to share";
  String get tapToOpenInMaps => isAr ? "اضغط للفتح في الخرائط" : "Tap to open in Maps";
  String get selectedLocation => isAr ? "الموقع المحدد" : "Selected Location";
  String get sendLocation => isAr ? "إرسال الموقع" : "Send Location";
  String get noMemoriesYet => isAr ? "لا توجد ذكريات بعد" : "No memories yet";
  String get finishOutingToSave => isAr ? "أنهِ خرجة في المجموعة لرؤيتها هنا!" : "Finish an outing in a group to see it here!";
  String get tapOnMapOrDragPin => isAr ? "اضغط على الخريطة أو اسحب الدبوس" : "Tap on the map or drag the pin";
  String get searchForAPlace => isAr ? "البحث عن مكان..." : "Search for a place...";
  String get yourLocation => isAr ? "موقعك" : "Your location";

  // Additional chat and wallpaper localizations
  String get mediaTitle => isAr ? "الوسائط" : "Media";
  String get noMediaYet => isAr ? "لم يتم مشاركة أي وسائط بعد" : "No media shared yet";
  String get sharedLocationsTitle => isAr ? "المواقع المشتركة" : "Shared Locations";
  String get noLocationsYet => isAr ? "لم يتم مشاركة أي مواقع بعد" : "No locations shared yet";
  String get customWallpaper => isAr ? "خلفية مخصصة" : "Custom Wallpaper";
  String get customOptions => isAr ? "خيارات مخصصة" : "Custom Options";
  String get pickFromGallery => isAr ? "اختر من المعرض" : "Pick from Gallery";
  String get frostedGlassBlurDesc => isAr ? "سيتم تطبيق تأثير ضبابي مذهل" : "Will apply a stunning frosted-glass blur";
  String get removeWallpaper => isAr ? "إزالة الخلفية" : "Remove Wallpaper";
  String get restoreDefaultWallpaperDesc => isAr ? "استعادة الخلفية الرمادية الفاتحة الافتراضية" : "Restore the default light grey background";
  String get premiumGradients => isAr ? "تدرجات ألوان مميزة" : "Premium Gradients";
  String get solidColors => isAr ? "ألوان سادة" : "Solid Colors";

  // Activity & Favorites
  String get noRecentActivity => isAr ? "لا يوجد نشاط مؤخراً" : "No recent activity";
  String get favoritesComingSoon => isAr ? "المفضلة قريباً" : "My Favorites coming soon";
  String get addedToFavorites => isAr ? "تمت الإضافة للمفضلة" : "Added to Favorites";
  String get removedFromFavorites => isAr ? "تمت الإزالة من المفضلة" : "Removed from Favorites";
  String get quickActions => isAr ? "الإجراءات السريعة" : "Quick Actions";
  String get recentActivity => isAr ? "النشاط مؤخراً" : "Recent Activity";
  String get viewAll => isAr ? "عرض الكل" : "View All";
  String get publicSearch => isAr ? "البحث العام" : "Public Search";

  // About Laween Overhaul
  String get aboutHeroTitle => isAr ? "التقوا في المنتصف، بكل سهولة." : "Meet in the middle, effortlessly.";
  String get aboutHeroSubtitle => isAr 
    ? "لوين يزيل عناء البحث عن مكان لقاء يبدو منصفاً للجميع. سواء كنت تخطط للقاء قهوة، أو تجمع عائلي، لوين يجعل اللقاء بسيطاً ومبهجاً."
    : "Laween takes the stress out of finding a meeting spot that feels fair for everyone. Whether it's coffee or family, we make it simple.";
  
  String get whyChooseLaween => isAr ? "لماذا تختار لوين؟" : "Why choose Laween?";
  String get fairForAllTitle => isAr ? "منصف للجميع" : "Fair for all";
  String get fairForAllDesc => isAr ? "لا مزيد من الجدالات. نحسب نقطة لقاء تناسب الجميع بشكل عادل." : "No more debates. We calculate a meeting point that works fairly for everyone.";
  
  String get easyToUseTitle => isAr ? "سهل الاستخدام" : "Easy to use";
  String get easyToUseDesc => isAr ? "أدخل مواقعكم، واختر نوع الخرجة، واحصل على اقتراحات فورية." : "Enter locations, choose your vibe, and get instant suggestions.";
  
  String get discoverPlacesTitle => isAr ? "اكتشف أماكن جديدة" : "Discover new places";
  String get discoverPlacesDesc => isAr ? "استكشف المطاعم والمقاهي المختارة بعناية بالقرب من نقطة المنتصف." : "Explore curated restaurants and cafes near your midpoint.";
  
  String get perfectForGroupsTitle => isAr ? "مثالي للمجموعات" : "Perfect for groups";
  String get perfectForGroupsDesc => isAr ? "شارك الرابط واجعل الجميع يشاركون بإضافة نقطة انطلاقهم." : "Share the link and let everyone join in by adding their own starting point.";

  String get howItWorks => isAr ? "كيف يعمل لوين" : "How Laween works";
  String get step1Title => isAr ? "١. أدخل المواقع" : "1. Input locations";
  String get step1Desc => isAr ? "أضف نقاط انطلاقك أو شارك رابطاً للمجموعات الكبيرة." : "Add your starting points or share a link for larger groups.";
  String get step2Title => isAr ? "٢. جد نقطة المنتصف" : "2. Find your midpoint";
  String get step2Desc => isAr ? "نحسب نقطة لقاء عملية وعادلة بناءً على مواقع الجميع." : "We calculate an equitable meeting point based on the group.";
  String get step3Title => isAr ? "٣. اكتشف الأماكن" : "3. Discover places";
  String get step3Desc => isAr ? "تصفح أفضل الأماكن والأنشطة القريبة حول نقطة المنتصف." : "Browse the best places and activities around your midpoint.";
  String get step4Title => isAr ? "٤. قرر والتقِ" : "4. Decide and meet";
  String get step4Desc => isAr ? "اختر المكان المفضل وانتقل من التخطيط إلى اللقاء الفعلي." : "Pick the best spot and move from planning to actually meeting.";

  String get ourMissionTitle => isAr ? "مهمتنا" : "Our mission";
  String get ourMissionDesc => isAr 
    ? "مهمتنا هي جعل اللقاء بسيطاً ومبهجاً وعادلاً. نؤمن بأن التكنولوجيا يجب أن تسهل التواصل الحقيقي."
    : "Our mission is to make meeting up simple, joyful, and fair. We believe tech should make real-world connection easier.";
  
  String get readyToMeet => isAr ? "جاهز للالتقاء في المنتصف؟" : "Ready to meet in the middle?";
  String get startPlanning => isAr ? "ابدأ التخطيط الآن" : "Start Planning Now";

  // Outing Creation Strings
  String get createOuting => isAr ? "إنشاء خروجة" : "Create Outing";
  String get directOuting => isAr ? "خروج مباشر" : "Direct Outing";
  String get findPerfectMidpoint => isAr ? "البحث عن نقطة المنتصف المثالية" : "Find the perfect mid-point";
  String get pickDestinationAndGo => isAr ? "اختر وجهة ودعنا نذهب!" : "Pick a destination and let's go!";
  String get calculationMode => isAr ? "وضع الحساب" : "Calculation Mode";
  String get selectCategory => isAr ? "اختر الفئة" : "Select Category";
  String get joinTimeLimit => isAr ? "مهلة الانضمام" : "Join Time Limit";
  String get scheduleSession => isAr ? "جدولة الجلسة" : "Schedule Session";
  String get scheduleForLater => isAr ? "جدولة لوقت لاحق" : "Schedule for Later";
  String get offStartNow => isAr ? "إيقاف - ابدأ الجلسة الآن" : "Off - Start the session now";
  String get startJourney => isAr ? "ابدأ الرحلة" : "Start Journey";
  String get launchOutingSession => isAr ? "إطلاق جلسة خروج" : "Launch Outing Session";
  String get whereAreWeGoing => isAr ? "إلى أين نحن ذاهبون؟" : "Where are we going?";
  String get restaurant => isAr ? "مطعم" : "Restaurant";
  String get cafe => isAr ? "مقهى" : "Cafe";
  String get park => isAr ? "حديقة" : "Park";
  String get mall => isAr ? "مول" : "Mall";
  String get sporty => isAr ? "رياضي" : "Sporty";
  String get cinema => isAr ? "سينما" : "Cinema";
  String get minLabel => isAr ? "دقيقة" : "min";
  String get kmLabel => isAr ? "كم" : "KM";
  String get timeLabel => isAr ? "وقت" : "Time";
  String get outingSetForFuture => isAr ? "تم تحديد موعد الخروج في وقت لاحق" : "Outing set for a future time";
  String get tapToPickDateTime => isAr ? "اضغط لاختيار التاريخ والوقت" : "Tap to pick Date & Time";
  String get selectSpecificLocation => isAr ? "يرجى اختيار موقع محدد من الاقتراحات" : "Please select a specific location from the suggestions";

  // Waiting Room Strings
  String get outingWaitingRoom => isAr ? "غرفة انتظار الخروجة" : "Outing Waiting Room";
  String get live => isAr ? "مباشر" : "LIVE";
  String get sessionNumber => isAr ? "جلسة رقم" : "Session #";
  String get membersJoined => isAr ? "أعضاء انضموا" : "Members Joined";
  String get targetDestination => isAr ? "الوجهة المستهدفة" : "TARGET DESTINATION";
  String get outingMode => isAr ? "وضع الخروج" : "Outing Mode";
  String get discovering => isAr ? "اكتشاف" : "Discovering";
  String get participantsLabel => isAr ? "المشاركون" : "PARTICIPANTS";
  String get youLabel => isAr ? "أنت" : "You";
  String get leaveSession => isAr ? "مغادرة الجلسة" : "Leave Session";
  String get startJourneyNow => isAr ? "ابدأ الرحلة الآن" : "Start Journey Now";
  String get needAtLeast2People => isAr ? "تحتاج إلى شخصين على الأقل لبدء الخروجة!" : "You need at least 2 people to start an outing!";
  String get sessionCancelledNoParticipants => isAr ? "تم إلغاء الجلسة: لم ينضم عدد كافٍ من المشاركين." : "Session cancelled: Not enough participants joined.";

  // Outing Map Screen Strings
  String get placesTab => isAr ? "📍 الأماكن" : "📍 Places";
  String get chatTab => isAr ? "💬 الدردشة" : "💬 Chat";
  String get noMessagesYet => isAr ? "لا توجد رسائل بعد.\nكن أول من يقول مرحبًا! 👋" : "No messages yet.\nBe the first to say hi! 👋";
  String get saySomething => isAr ? "قل شيئًا..." : "Say something...";
  String get voiceMessage => isAr ? "🎤 رسالة صوتية" : "🎤 Voice message";
  String get voteNow => isAr ? "صوّت الآن" : "Vote Now";
  String get unvote => isAr ? "إلغاء التصويت" : "Unvote";
  String get votesLabel => isAr ? "أصوات" : "Votes";
  String get routeUnavailable => isAr ? "المسار غير متوفر" : "Route unavailable";
  String get winnerDecided => isAr ? "تم تحديد الفائز" : "WINNER DECIDED";
  String get friendsOnTheWay => isAr ? "الأصدقاء في الطريق" : "Friends on the way";
  String get calculating => isAr ? "جاري الحساب..." : "Calculating...";
  String get arrived => isAr ? "وصل" : "Arrived";
  String get navigateToVenue => isAr ? "انتقل إلى الوجهة" : "Navigate to Venue";
  String get liveTrackGroup => isAr ? "تتبع المجموعة مباشرة" : "Live Track Group";
  String get outingToolsSafety => isAr ? "أدوات الخروجة والأمان" : "Outing Tools & Safety";
  String get sosEmergency => isAr ? "طوارئ SOS" : "SOS Emergency";
  String get cancelSosEmergency => isAr ? "إلغاء طوارئ SOS" : "Cancel SOS Emergency";
  String get sosAlertEveryone => isAr ? "تنبيه الجميع في حالة الطوارئ" : "Alert everyone in case of emergency";
  String get sosClickToClear => isAr ? "اضغط لمسح تنبيه SOS الخاص بك" : "Click to clear your SOS alert";
  String get sosCleared => isAr ? "تم مسح SOS" : "SOS Cleared";
  String get triggerSosTitle => isAr ? "🚨 تفعيل SOS؟" : "🚨 Trigger SOS?";
  String get triggerSosContent => isAr ? "سيؤدي هذا إلى تنبيه الجميع في الجلسة وإرسال موقعك إلى دردشة المجموعة. هل تريد الاستمرار؟" : "This will alert everyone in the session and send your location to the group chat. Continue?";
  String get yesSos => isAr ? "نعم، SOS" : "YES, SOS";
  String get sosActivated => isAr ? "🚨 تم تفعيل SOS. ابقَ في مكانك!" : "🚨 SOS ACTIVATED. Stay where you are!";
  String get arFriendCompass => isAr ? "بوصلة الأصدقاء AR" : "AR Friend Compass";
  String get visual3DPointer => isAr ? "مؤشر بصري ثلاثي الأبعاد للعثور على الأصدقاء" : "Visual 3D pointer to find friends";
  String get noOtherParticipants => isAr ? "لا يوجد مشاركون آخرون في هذه الخروجة" : "No other participants in this outing";
  String get selectParticipantToFind => isAr ? "اختر مشاركًا للعثور عليه باستخدام مؤشر AR البصري" : "Select a participant to find with the visual AR pointer";
  String get noLocationAvailableFriend => isAr ? "لا يتوفر موقع لهذا الصديق" : "No location available for this friend";
  String get splitBillAI => isAr ? "تقسيم الفاتورة (AI)" : "Split Bill (AI)";
  String get autoExtractItems => isAr ? "استخراج العناصر تلقائيًا وتحليل الأسعار" : "Auto extract items and parse prices";
  String get finishOuting => isAr ? "إنهاء الخروجة" : "Finish Outing";
  String get finishOutingTitle => isAr ? "إنهاء الخروجة؟" : "Finish Outing?";
  String get finishOutingContent => isAr ? "سيؤدي هذا إلى إغلاق الجلسة للجميع. هل أنت متأكد أنك انتهيت؟" : "This will close the session for everyone. Are you sure you're done?";
  String get notYet => isAr ? "ليس بعد" : "Not yet";
  String get yesFinish => isAr ? "نعم، أنهِ!" : "Yes, finish!";

  // Receipt Splitter Strings
  String get receiptSplitter => isAr ? "مقسم الفاتورة" : "Receipt Splitter";
  String get addCustomItem => isAr ? "إضافة عنصر مخصص" : "Add Custom Item";
  String get itemName => isAr ? "اسم العنصر" : "Item Name";
  String get price => isAr ? "السعر" : "Price";
  String get add => isAr ? "إضافة" : "Add";
  String get assignLabel => isAr ? "تعيين" : "Assign";
  String get selectWhoShared => isAr ? "اختر من شارك هذا العنصر" : "Select who shared this item";
  String get scanReceipt => isAr ? "مسح الفاتورة" : "Scan Receipt";
  String get addCustom => isAr ? "إضافة مخصص" : "Add Custom";
  String get scanningWithAI => isAr ? "جاري المسح باستخدام Apple Vision AI..." : "Scanning with Apple Vision AI...";
  String get extraAdjustments => isAr ? "تعديلات إضافية" : "Extra Adjustments";
  String get taxPercent => isAr ? "الضريبة %" : "Tax %";
  String get tipPercent => isAr ? "البقشيش %" : "Tip %";
  String get selectedLabel => isAr ? "تم اختيارهم" : "Selected";
  String get itemNumber => isAr ? "عنصر رقم" : "Item #";

  // Outing Tracking Strings
  String get liveTracking => isAr ? "تتبع مباشر" : "LIVE TRACKING";
  String get destination => isAr ? "الوجهة" : "Destination";
  String get following => isAr ? "متابعة" : "FOLLOWING";
  String get friendsArrivalTimes => isAr ? "أوقات وصول الأصدقاء" : "Friends Arrival Times";
  String get liveLocationSafety => isAr ? "تم مشاركة الموقع المباشر من أجل الأمان" : "Live location shared for safety";
  String get meLabel => isAr ? "أنا" : "ME";
  String get joinedMasterpiece => isAr ? "انضم إلى التحفة الفنية" : "Joined the masterpiece";
  String get kmLeft => isAr ? "كم متبقي" : "km left";
  String get arrivedStatus => isAr ? "وصل" : "ARRIVED";
  String get privateGhost => isAr ? "خاص (شبح)" : "PRIVATE (GHOST)";
  String get sharingLocation => isAr ? "مشاركة الموقع" : "SHARING LOCATION";

  // AR Friend Compass Strings
  String get initializingArCompass => isAr ? "جاري تشغيل بوصلة الأصدقاء AR..." : "Initializing AR Friend Compass...";
  String get arFriendCompassTitle => isAr ? "بوصلة الأصدقاء AR" : "AR FRIEND COMPASS";
  String get awayFrom => isAr ? "بعيد عن" : "away from";
  String get waitingForUpdate => isAr ? "في انتظار تحديث موقع الصديق." : "Waiting for updated friend location.";
  String get locationOutdated => isAr ? "قد يكون موقع الصديق قديماً." : "Friend location may be outdated.";
  String get calibrateCompass => isAr ? "حرك الهاتف بحركة رقم 8 لمعايرة البوصلة." : "Move phone in a figure-8 to calibrate compass.";
  String get weakAccuracyIndoors => isAr ? "دقة الموقع ضعيفة في الداخل." : "Location accuracy is weak indoors.";
  String get nearbyGpsInaccurate => isAr ? "قريب جداً — قد يكون نظام تحديد المواقع غير دقيق في الداخل." : "Nearby — GPS may be inaccurate indoors.";
  String get pointAtFriend => isAr ? "✨ وجه الهاتف مباشرة نحو" : "✨ Point directly at";
  String get friendBehindYou => isAr ? "🔄 الصديق خلفك. التفت للخلف." : "🔄 Friend is behind you. Turn around.";
  String get turnRightToFind => isAr ? "🔄 اتجه يميناً للعثور على" : "🔄 Turn right to find";
  String get turnLeftToFind => isAr ? "🔄 اتجه يساراً للعثور على" : "🔄 Turn left to find";

  // History Page Strings
  String get groupLabel => isAr ? "مجموعة" : "Group";
  String get noRecapRecorded => isAr ? "لم يتم تسجيل ملخص." : "No recap recorded.";
  String outingAt(String venue) => isAr ? "خروجة في $venue" : "Outing at $venue";

  // Dashboard Strings
  String get viewDetails => isAr ? "عرض التفاصيل" : "View Details";
  String arrivedStatusLabel(int arrived, int total) => isAr ? "وصل $arrived/$total" : "arrived $arrived/$total";
  String get everyoneArrived => isAr ? "وصل الجميع! 🎉" : "Everyone has arrived! 🎉";
  String get allLabel => isAr ? "الكل" : "ALL";
  String get favoritesLabel => isAr ? "المفضلة" : "FAVORITES";
  String get aiRecapLabel => isAr ? "ملخص AI" : "AI RECAP";
  String get squadMemoriesLabel => isAr ? "ذكريات الفريق" : "SQUAD MEMORIES";
  String get epicOutingLabel => isAr ? "خروجة ملحمية" : "Epic Outing";
  String get squadHistory => isAr ? "سجل الفريق" : "Squad History";
  String photosLabel(int count) => isAr ? "$count صور" : "$count Photos";
  String get noFavoritesYet => isAr ? "لا توجد مفضلات بعد" : "No favorites yet";
  String get noMemoriesYetLabel => isAr ? "لا توجد ذكريات بعد" : "No memories yet";
  String get tapHeartToSave => isAr ? "اضغط على القلب في أي ذكرى لحفظها هنا!" : "Tap the heart on any memory to save it here!";
  String get finishOutingToSaveMemories => isAr ? "أنهِ الخروجة لحفظ الذكريات هنا!" : "Finish an outing to save it here!";

  // Chat Page Strings
  String get editMessage => isAr ? "تعديل الرسالة" : "Edit Message";
  String get messageInfo => isAr ? "معلومات الرسالة" : "Message Info";
  String get deleteForEveryone => isAr ? "الحذف لدى الجميع" : "Delete for everyone";
  String get permanentRemoval => isAr ? "إزالة نهائية" : "Permanent removal";
  String get deleteForMe => isAr ? "حذف بالنسبة لي" : "Delete for me";
  String get readBy => isAr ? "قرأها" : "Read by";
  String get membersLabel => isAr ? "أعضاء" : "members";
  String get noOneReadYet => isAr ? "لم يقرأها أحد بعد" : "No one has read this yet";
  String get reactionsLabel => isAr ? "التفاعلات" : "Reactions";

  // Outing Card Strings
  String get outingSession => isAr ? "جلسة خروجة" : "Outing Session";
  String get liveLabel => isAr ? "مباشر" : "Live";
  String minRemaining(int min) => isAr ? "متبقي $min دقائق" : "$min min remaining";
  String get destinationLocked => isAr ? "تم تحديد الوجهة" : "Destination Locked";
  String get collectingMemories => isAr ? "جمع الذكريات" : "Collecting Memories";
  String get savedInHistory => isAr ? "محفوظ في السجل" : "Saved in History";
  String get expired => isAr ? "منتهي الصلاحية" : "Expired";
  String get joinLabel => isAr ? "انضمام" : "Join";
  String get celebrateLabel => isAr ? "احتفل!" : "Celebrate!";
  String get winnerLabel => isAr ? "الفائز" : "Winner";
  String get memoriesLabel => isAr ? "الذكريات" : "Memories";
  String get recapLabel => isAr ? "ملخص" : "Recap";
  String get onlyParticipantsDetails => isAr ? "المشاركون فقط يمكنهم عرض التفاصيل." : "Only participants can view details.";
  String sosNeedsHelp(String name) => isAr ? "نجدة! $name يحتاج للمساعدة!" : "SOS! $name needs help!";
  String get emergencyLabel => isAr ? "طوارئ 🚨" : "🚨 EMERGENCY";
  String get sharedLocationLabel => isAr ? "موقع مشترك 📍" : "📍 Shared Location";
  String get openInGoogleMaps => isAr ? "فتح في خرائط جوجل" : "Open in Google Maps";
  String get sosActiveLabel => isAr ? "نجدة نشطة" : "SOS ACTIVE";
  String get needsHelpSuffix => isAr ? " يحتاج للمساعدة!" : " NEEDS HELP!";
  String get stopAlarm => isAr ? "إيقاف التنبيه" : "STOP ALARM";
  String get seeOnMap => isAr ? "عرض على الخريطة" : "SEE ON MAP";
  String get deleteForEveryoneTitle => isAr ? "الحذف لدى الجميع؟" : "Delete for everyone?";
  String get deleteForEveryoneContent => isAr ? "هل أنت متأكد أنك تريد حذف هذه الرسالة لدى الجميع؟" : "Are you sure you want to delete this message for everyone?";
  String get deleteAction => isAr ? "حذف" : "Delete";
  String participantCount(int joined, int total) => isAr ? "$joined / $total انضموا" : "$joined / $total joined";
  String get sessionMemories => isAr ? "ذكريات هذه الجلسة" : "Memories of this session";
  String get bestMomentLabel => isAr ? "أفضل لحظة (AI)" : "Best Moment (AI)";
  String membersCount(int count) => isAr ? "$count أعضاء" : "$count members";
}

