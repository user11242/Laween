import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:laween/core/providers/locale_provider.dart';

class AppLocalizations {
  final String languageCode;

  AppLocalizations(this.languageCode);

  bool get isAr => languageCode == 'ar';

  static AppLocalizations? of(BuildContext context, {bool listen = true}) {
    try {
      final locale = Provider.of<LocaleProvider>(context, listen: listen).locale;
      return AppLocalizations(locale.languageCode);
    } catch (_) {
      return AppLocalizations('en');
    }
  }

  String get onboardingTitle => isAr ? "مرحباً بكم في لاوين" : "Welcome to Laween";
  String get onboardingSubtitle => isAr ? "تعلم وعلم في أي مكان وزمان" : "Learn and Teach anywhere, anytime";
  String get joinWithGoogle => isAr ? "سجل باستخدام جوجل" : "Join with Google";
  String get joinWithEmail => isAr ? "سجل باستخدام البريد الإلكتروني" : "Join with Email";
  String get alreadyHaveAccount => isAr ? "هل لديك حساب بالفعل؟ " : "Already have an account? ";
  String get signIn => isAr ? "تسجيل الدخول" : "Sign In";
  String get loginTitle => isAr ? "دعنا نلتقي!" : "Let's Meet Up!";
  String get loginSubtitle => isAr ? "مكان الاستراحة في انتظارك." : "Your hangout is waiting.";

  String get paste => isAr ? "لصق" : "Paste";
  String get invalidPassword => isAr ? "كلمة مرور غير صالحة." : "Invalid password.";
  String get continueRegistrationWithGoogle => isAr ? "متابعة التسجيل بجوجل" : "Continue registration with Google";
  String get continueWithGoogle => isAr ? "المتابعة باستخدام جوجل" : "Continue with Google";
  String get maybeLater => isAr ? "ربما لاحقاً" : "Maybe later";
  String get invalidMobileNumber => isAr ? "رقم الهاتف المحمول غير صالح" : "Invalid mobile number";
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
  String get pleaseTryAgain => isAr ? "أعد المحاولة من فضلك." : "Please try again.";
  String get verificationFailed => isAr ? "فشل التحقق." : "Verification failed.";
  String get resendCode => isAr ? "إعادة إرسال الرمز" : "Resend Code";
  String get unavailable => isAr ? "غير متاح" : "Unavailable";
  String get phoneNumberInUse => isAr ? "رقم الهاتف قيد الاستخدام" : "Phone number in use";
  String get required => isAr ? "مطلوب" : "Required";
  String get enterPhone => isAr ? "أدخل رقم هاتفك" : "Enter your phone number";
  String get termsRequired => isAr ? "الشروط مطلوبة" : "Terms Required";
  String get acceptTermsToFinish => isAr ? "اقبل الشروط للانتهاء" : "Accept terms to finish";
  String get finish => isAr ? "انتهاء" : "Finish";
  String get next => isAr ? "التالي" : "Next";
  String get applicationReceived => isAr ? "الطلب مستلم" : "Application Received";
  String get teacherUnderReview => isAr ? "طلب المعلم قيد المراجعة" : "Teacher application is under review";
  String get iAccept => isAr ? "انا اوافق على " : "I accept ";
  String get termsAndConditions => isAr ? "الشروط والأحكام" : "Terms and Conditions";
  String get and => isAr ? " و " : " and ";
  String get privacyPolicy => isAr ? "سياسة الخصوصية" : "Privacy Policy";
  String get verifyIdentity => isAr ? "تحقق من الهوية" : "Verify Identity";
  String get phoneNumber => isAr ? "رقم الهاتف" : "Phone Number";
  String get enterPortfolio => isAr ? "أدخل رابط المحفظة" : "Enter portfolio link";
  String get invalidPortfolio => isAr ? "رابط المحفظة غير صالح" : "Invalid portfolio link";
  String get finalizing => isAr ? "وضع اللمسات النهائية..." : "Finalizing...";
  String get finishAndRegister => isAr ? "إنهاء وتسجيل" : "Finish and Register";
  String get allVerified => isAr ? "تم التحقق من جميع الخطوات" : "All steps verified";
  String get password => isAr ? "كلمة المرور" : "Password";
  String get linkAccountButton => isAr ? "ربط الحساب" : "Link Account";
  String get cancel => isAr ? "إلغاء" : "Cancel";
  String get deleteAccountConfirmMessage => isAr ? "تأكيد الحذف" : "Confirm deletion";
  String get deleteMyAccount => isAr ? "حذف حسابي" : "Delete Account";
  String get success => isAr ? "نجاح" : "Success";
  String get teacherApplicationRejectedTitle => isAr ? "تم رفض الطلب" : "Application Rejected";
  String get teacherApplicationRejectedMessage => isAr ? "تفاصيل الرسالة" : "Message details";
  String get contactSupport => isAr ? "اتصل بالدعم" : "Contact Support";
  String get signOut => isAr ? "تسجيل الخروج" : "Sign Out";
  String get termsAndConditionsContent => isAr ? "محتوى الشروط" : "Terms content";
  String get chooseRole => isAr ? "اختر الدور" : "Choose Role";
  String get learnOrTeach => isAr ? "يتعلم أو يعلم" : "Learn or Teach";
  String get student => isAr ? "طالب/طالبة" : "Student";
  String get teacher => isAr ? "معلم/معلمة" : "Teacher";
  String get studentFinishMessage => isAr ? "الطالب مسجل" : "Student registered";
  String get teacherFinishMessage => isAr ? "المعلم مسجل" : "Teacher registered";
  String get portfolioLink => isAr ? "رابط المحفظة" : "Portfolio Link";
  String get portfolioHint => isAr ? "أدخل الرابط" : "Enter link";
  String get needDetails => isAr ? "نحن نحتاج الى تفاصيل" : "Need details";
  String get linkAccountTitle => isAr ? "ربط الحساب" : "Link Account";
  String get linkAccountMessage => isAr 
      ? "هذا البريد الإلكتروني مسجل بالفعل بكلمة مرور. أدخل كلمة المرور لربط حساب جوجل الخاص بك." 
      : "This email is already registered with a password. Enter your password to link your Google account.";
  String get logoutConfirmationTitle => isAr ? "تسجيل خروج" : "Logout";
  String get logoutConfirmationMessage => isAr ? "هل أنت متأكد أنك تريد تسجيل الخروج؟" : "Are you sure you want to logout?";
  String get stayLoggedIn => isAr ? "البقاء" : "Stay";
  String get logoutAnyway => isAr ? "خروج" : "Logout";
  String get logout => isAr ? "تسجيل خروج" : "Logout";
  String get teacherAccountPendingApproval => isAr ? "الحساب معلق" : "Account Pending";
  String get teacherPendingPageNote => isAr ? "حسابك قيد المراجعة" : "Your account is pending review";
  String get deleteAccountConfirmTitle => isAr ? "حذف الحساب" : "Delete Account";

  String resendIn(int seconds) => isAr ? "إعادة الإرسال خلال ($seconds)" : "Resend in $seconds";
  String enterCodeSentTo(String dest) => isAr ? "أدخل الرمز المرسل إلى: $dest" : "Enter code sent to $dest";
  String stepOf(int step, int total) => isAr ? "خطوة $step من $total" : "Step $step of $total";
  String welcomeUser(String? name) => isAr ? "مرحباً $name" : "Welcome $name";
  
  String get createAccount => isAr ? "إنشاء حساب" : "Create Account";
  String get welcome => isAr ? "مرحباً!" : "Welcome!";
  String get welcomeSubtitle => isAr ? "أنشئ حسابك للبدء في التخطيط\nللجلسات مع الأصدقاء" : "Create your account to start planning\nhangouts with friends";
  String get fullName => isAr ? "الاسم الكامل" : "Full Name";
  String get email => isAr ? "البريد الإلكتروني" : "Email";
  String get confirmPassword => isAr ? "تأكيد كلمة المرور" : "Confirm Password";
  String get orContinueWith => isAr ? "أو المتابعة باستخدام" : "Or Continue with";
  String get nameTaken => isAr ? "اسم المستخدم مستخدم بالفعل" : "Username is already taken";
  String get emailTaken => isAr ? "البريد الإلكتروني مسجل بالفعل" : "Email is already registered";
  String get phoneTaken => isAr ? "رقم الهاتف مستخدم بالفعل" : "Phone number is already in use";
  String get continueText => isAr ? "متابعة" : "Continue";

  String get invalidUsername => isAr ? "يجب أن يكون اسم المستخدم بين ٣ و ٣٠ حرفاً ولا يمكن أن يكون أرقاماً أو رموزاً فقط" : "Username must be 3-30 characters and cannot be only numbers or symbols";
  String get invalidEmail => isAr ? "يرجى إدخال بريد إلكتروني صالح" : "Please enter a valid email address";
  String get weakPassword => isAr ? "يجب أن تكون كلمة المرور ٨ أحرف على الأقل وتحتوي على حرف كبير ورقم ورقم ورمز" : "Password must be at least 8 characters long and include a capital letter, a number, and a symbol";
  String get passwordsDoNotMatch => isAr ? "كلمات المرور غير متطابقة" : "Passwords do not match";
  String get invalidPhoneJordan => isAr ? "يجب أن يبدأ رقم الهاتف في الأردن بـ ٠٧٩ أو ٠٧٨ أو ٠٧٧" : "Jordanian phone numbers must start with 079, 078, or 077";

  // Login Page
  String get loginLabel => isAr ? "تسجيل الدخول" : "Log In";
  String get enterPhoneToLogin => isAr ? "أدخل رقم هاتفك لتسجيل الدخول" : "Enter your phone number to log in";
  String get forgotPasswordQ => isAr ? "نسيت كلمة المرور؟" : "Forgot Password?";
  String get loginWithFaceId => isAr ? "المتابعة باستخدام بصمة الوجه" : "Continue with Face ID";
  
  // Forgot Password Page
  String get forgotPasswordTitle => isAr ? "نسيت كلمة المرور" : "Forgot Password";
  String get forgotPasswordDesc => isAr ? "أدخل رقم هاتفك لتلقي رمز التحقق." : "Enter your phone number to receive a verification code.";
  String get verify => isAr ? "تحقق" : "Verify";
  String get enterPhoneError => isAr ? "يرجى إدخال رقم الهاتف" : "Please enter phone number";
  String get pleaseEnterEmailAndPassword => isAr ? "يرجى إدخال البريد الإلكتروني وكلمة المرور" : "Please enter email and password";
  String get loginError => isAr ? "فشل تسجيل الدخول" : "Login Failed";
  
  // Face ID Dialog
  String get faceIdUnavailableTitle => isAr ? "بصمة الوجه غير متوفرة" : "Face ID unavailable";
  String get faceIdUnavailableMessage => isAr ? "لا يمكن استخدام بصمة الوجه الآن. قم بإعدادها على جهازك، أو قم بتسجيل الدخول باستخدام البريد الإلكتروني وكلمة المرور" : "Face ID can't be used right now. Set it up on your device, or sign in with your email and password";
  String get useEmailAndPassword => isAr ? "استخدام البريد الإلكتروني" : "Use Email and Password";

  // Create New Password Page
  String get createNewPasswordTitle => isAr ? "إنشاء كلمة مرور جديدة" : "Create New Password";
  String get createNewPasswordDesc => isAr ? "أنشئ كلمة مرور جديدة لتسجيل الدخول." : "Create your new password to login.";
  String get createNewPasswordButton => isAr ? "إنشاء كلمة مرور" : "Create Password";

  // OTP & Verification
  String get otpVerificationTitle => isAr ? "التحقق من الرمز" : "OTP Verification";
  String get otpSendDesc => isAr ? "أدخل رمز التحقق الذي أرسلناه للتو على رقم هاتفك." : "Enter the verification code we just sent on your phone number.";
  String get didntReceiveCode => isAr ? "لم تصلك الرسالة؟ " : "Didn't receive code? ";
  String get resend => isAr ? "إعادة إرسال" : "Resend";
  String get yourPhoneNumber => isAr ? "رقم هاتفك" : "Your Phone Number";
  
  // Forgot Password Overhaul
  String get resetPassword => isAr ? "إعادة تعيين كلمة المرور" : "Reset Password";
  String get resetYourPassword => isAr ? "إعادة تعيين كلمة المرور" : "Reset Your Password";
  String get resetPasswordDesc => isAr ? "أدخل رقم هاتفك وسنرسل لك رمزاً لإعادة تعيين كلمة المرور الخاصة بك" : "Enter your phone number and we'll send you a code to reset your password";
  String get sendCode => isAr ? "إرسال الرمز" : "Send Code";
  String get backToLogin => isAr ? "العودة لتسجيل الدخول" : "Back to Login";
  String get enterOtp => isAr ? "أدخل رمز التحقق" : "Enter OTP";
  String get weSentCodeTo => isAr ? "أرسلنا رمزاً إلى" : "We sent a code to";
  String resendCodeIn(String time) => isAr ? "إعادة إرسال الرمز خلال $time" : "Resend code in $time";
  String get createNewPasswordSubtitle => isAr ? "يجب أن تكون كلمة المرور الجديدة مختلفة عن كلمات المرور المستخدمة سابقاً" : "Your new password must be different from previously used passwords";
  String get atLeast8Chars => isAr ? "٨ أحرف على الأقل" : "At least 8 characters";
  String get oneNumber => isAr ? "رقم واحد" : "One number";
  String get oneUppercase => isAr ? "حرف واحد كبير" : "One uppercase letter";
  String get passwordChanged => isAr ? "تم تغيير كلمة المرور" : "Password Changed";
  String get passwordChangedSuccessfully => isAr ? "تم تغيير كلمة المرور بنجاح، يرجى تسجيل الدخول!" : "Your password has been changed successfully, please login!";
  String get verification => isAr ? "التحقق" : "Verification";
  String get newPassword => isAr ? "كلمة مرور جديدة" : "New Password";

  // Bottom Navigation Bar
  String get home => isAr ? "الرئيسية" : "Home";
  String get groups => isAr ? "المجموعات" : "Groups";
  String get favorite => isAr ? "المفضلة" : "Favorite";
  String get profile => isAr ? "الملف الشخصي" : "Profile";

  // Groups
  String get search => isAr ? "بحث..." : "search...";
  String get createGroup => isAr ? "إنشاء مجموعة" : "Create Group";
  String get joinGroup => isAr ? "الانضمام لمجموعة" : "Join Group";
  String get makeNewGroupDesc => isAr ? "أنشئ مجموعة جديدة لقضاء وقت ممتع" : "Make a new group for your hangouts";
  String get enterCodeToJoinDesc => isAr ? "أدخل الرمز للانضمام لمجموعة موجودة" : "Enter a code to join an existing group";
  String get createANewGroup => isAr ? "إنشاء مجموعة جديدة" : "Create a New Group";
  String get groupName => isAr ? "اسم المجموعة" : "Group Name";
  String get members => isAr ? "الأعضاء" : "Members";
  String get addMembers => isAr ? "إضافة أعضاء" : "Add Members";
  String get scanQr => isAr ? "مسح QR" : "Scan QR";
  String get enterCode => isAr ? "إدخال الرمز" : "Enter Code";
  String get scanToJoin => isAr ? "امسح للانضمام" : "Scan to Join";
  String get pointCameraDesc => isAr ? "وجه كاميرتك نحو رمز QR الخاص بالمجموعة للانضمام فوراً" : "Point your camera at the group's QR code to join instantly";
  String get openCamera => isAr ? "فتح الكاميرا" : "Open Camera";
  String get enterGroupCode => isAr ? "أدخل رمز المجموعة" : "Enter Group Code";
  String get type6DigitCodeDesc => isAr ? "اكتب الرمز المكون من 6 أرقام المشترك من إعدادات المجموعة" : "Type the 6-digit code shared by the group settings";

  // Profile
  String get editProfile => isAr ? "تعديل الملف الشخصي" : "Edit Profile";
  String get myFavorites => isAr ? "مفضلاتي" : "My Favorites";
  String get language => isAr ? "اللغة" : "Language";
  String get darkMode => isAr ? "الوضع الليلي" : "Dark Mode";
  String get aboutCalligro => isAr ? "عن لاوين" : "About Laween";
  String get logoutConfirm => isAr ? "هل أنت متأكد أنك تريد تسجيل الخروج؟" : "Are you sure you want to logout?";
  String get settings => isAr ? "الإعدادات" : "Settings";
  String get selectLanguage => isAr ? "اختر اللغة" : "Select Language";
  String get english => isAr ? "الإنجليزية" : "English";
  String get arabic => isAr ? "العربية" : "Arabic";
  String get save => isAr ? "حفظ" : "Save";
  String get phone => isAr ? "رقم الهاتف" : "Phone Number";
  String get successUpdate => isAr ? "تم تحديث البيانات بنجاح" : "Information updated successfully";
  String get notifications => isAr ? "التنبيهات" : "Notifications";
}
