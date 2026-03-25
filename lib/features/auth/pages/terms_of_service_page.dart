import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/gestures.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/theme/colors.dart';

const String _enTerms = '''Laween Terms of Service

Effective Date: 25 May 2026

Welcome to Laween. These Terms of Service ("Terms") govern your access to and use of the Laween mobile application and related services (the "Service"). By creating an account, accessing, or using Laween, you agree to be bound by these Terms. If you do not agree, do not use the Service.

1. Who We Are

Laween is an application created and operated by individual developers based in the Hashemite Kingdom of Jordan. At this stage, the Service is being tested for use in Jordan, although it may later become available in other countries.

2. Eligibility

You must be at least 18 years old to use Laween.

By using Laween, you confirm that:

- you are at least 18 years old
- you have the legal capacity to enter into these Terms
- you will use the Service in compliance with applicable law

3. Description of the Service

Laween is a location-based application that may allow users to:

- create an account and sign in, including through Google login
- provide account information such as name, email address, and phone number
- create or join outing sessions
- coordinate meetups and session-based activities
- use location-based and sharing-related features where available
- use certain optional permission-based features, such as contacts, camera, or photos, if the user chooses to enable them

Some features may be limited during testing and may depend on device compatibility, permissions, internet connectivity, and third-party services.

4. Accounts and User Information

To use certain features, users may be required to create an account or sign in through a supported login method.

You agree to provide accurate, current, and complete information, including where requested your:

- name
- email address
- phone number

You are responsible for maintaining the security of your account, device, and login credentials, and for all activity carried out under your account.

5. Sessions and Shared Access

Laween may use session-based features, including session codes, links, or tokens, to allow users to join outings or group activities.

When you create or join a session:

- information you submit within that session may be visible to other participants in that same session
- you are responsible for deciding with whom you share session access
- you should not share session links, access codes, or tokens publicly unless you accept the risks of wider access

6. Permissions and Device Access

With your permission, Laween may request access to certain device features, including:

- contacts
- photos/media
- camera

These permissions are requested only to support specific app features. You may deny or revoke them through your device settings, although this may limit some functionality.

7. Acceptable Use

You must not use Laween to:

- violate any law
- harass, threaten, abuse, stalk, or impersonate others
- misuse sessions, permissions, or user data
- attempt unauthorized access to accounts, systems, or tokens
- interfere with or disrupt the Service
- use automated tools such as bots or scrapers without permission
- submit false or misleading information

We may suspend or terminate access where we reasonably believe misuse has occurred.

8. Privacy

Your use of Laween is also subject to our Privacy Policy.

Laween may process limited personal data necessary to operate the Service, including:

- name
- email address
- phone number
- login-related account information
- session-related information
- cloud-stored app data
- permission-based data or content where the user chooses to grant access
- location-related information where required for app functionality

At this stage, Laween does not:

- provide online payments
- send newsletters
- use digital analytics tracking software for marketing purposes
- use retargeting advertising
- use Facebook Pixel
- display in-app advertisements

9. Third-Party Services

Laween may rely on third-party services such as:

- Google login
- Google APIs
- Firebase cloud services
- mapping, geolocation, or infrastructure providers

Your use of those integrated features may also be subject to the terms and privacy policies of the relevant third parties. We are not responsible for the availability, accuracy, or practices of third-party services.

10. Disclaimers

Laween is provided on an “as is” and “as available” basis.

We do not guarantee that:

- the Service will always be uninterrupted or error-free
- sessions, shared features, or location-based features will always work correctly
- third-party integrations will always remain available
- information, routes, or meetup suggestions will always be accurate or complete

Laween is still under testing and development. Use of the Service is at your own risk.

11. Limitation of Liability

To the fullest extent permitted by law, Laween and its creators shall not be liable for indirect, incidental, consequential, special, or punitive damages, or for loss of profits, data, goodwill, or opportunity arising from or related to the use of the Service.

Nothing in these Terms excludes liability that cannot legally be excluded under applicable law.

12. Termination

We may suspend, restrict, or terminate access to Laween at any time if:

- you violate these Terms
- your use creates legal, technical, or safety risks
- we are required to do so by law
- we discontinue or modify the Service

13. Changes to These Terms

We may update these Terms from time to time. If we make material changes, we will post the updated version and revise the effective date. Continued use of Laween after the revised Terms take effect means you accept the updated Terms.

14. Governing Law

These Terms are governed by the laws of the Hashemite Kingdom of Jordan. Any dispute arising out of or in connection with these Terms or the Service shall be subject to the jurisdiction of the competent courts of Jordan, unless mandatory law requires otherwise.

15. Contact

If you have questions about these Terms, you may contact us at:

Email: laween.support@gmail.com
''';

const String _arTerms = '''شروط استخدام Laween

تاريخ السريان: 25 مايو 2026

مرحبًا بكم في Laween. تحكم شروط الاستخدام هذه ("الشروط") وصولكم إلى تطبيق Laween واستخدامكم له ولأي خدمات مرتبطة به نقدمها ("الخدمة"). من خلال إنشاء حساب أو الدخول إلى Laween أو استخدامه، فإنكم توافقون على الالتزام بهذه الشروط. إذا كنتم لا توافقون عليها، يرجى عدم استخدام الخدمة.

1. من نحن

Laween هو تطبيق تم إنشاؤه وتشغيله بواسطة مطورين أفراد مقيمين في المملكة الأردنية الهاشمية. وفي هذه المرحلة، يتم اختبار الخدمة للاستخدام داخل الأردن، وقد تتوسع لاحقًا إلى دول أخرى.

2. الأهلية

يجب أن يكون عمرك 18 عامًا أو أكثر لاستخدام Laween.

وباستخدامك Laween، فإنك تؤكد ما يلي:

أن عمرك لا يقل عن 18 عامًا
أن لديك الأهلية القانونية للدخول في هذه الشروط
أنك ستستخدم الخدمة وفقًا للقوانين والأنظمة المعمول بها

يجوز لنا تعليق أو إنهاء الوصول إلى الخدمة إذا تبين لنا بشكل معقول أن المستخدم لا يستوفي هذه المتطلبات.

3. وصف الخدمة

Laween هو تطبيق اجتماعي يعتمد على الموقع الجغرافي، وقد يتيح للمستخدمين ما يلي:

إنشاء حساب وتسجيل الدخول، بما في ذلك عبر تسجيل الدخول باستخدام Google
تقديم معلومات الحساب مثل الاسم والبريد الإلكتروني ورقم الهاتف
إنشاء جلسات أو طلعات والانضمام إليها
تنسيق اللقاءات والأنشطة المعتمدة على الجلسات
استخدام ميزات تعتمد على الموقع أو المشاركة عند توفرها
استخدام بعض الميزات الاختيارية التي تتطلب صلاحيات من الجهاز، مثل جهات الاتصال أو الكاميرا أو الصور، إذا اختار المستخدم تفعيلها

قد تكون بعض الميزات محدودة خلال مرحلة الاختبار، كما قد تعتمد على توافق الجهاز أو الصلاحيات أو الاتصال بالإنترنت أو خدمات الأطراف الثالثة.

4. الحسابات ومعلومات المستخدم

قد يُطلب من المستخدم إنشاء حساب أو تسجيل الدخول باستخدام وسيلة مدعومة للاستفادة من بعض الميزات.

أنت توافق على تقديم معلومات صحيحة وحديثة وكاملة، بما في ذلك عند الطلب:

الاسم
البريد الإلكتروني
رقم الهاتف

وأنت مسؤول عن الحفاظ على أمان حسابك وجهازك وبيانات تسجيل الدخول الخاصة بك، كما تتحمل مسؤولية جميع الأنشطة التي تتم من خلال حسابك.

5. الجلسات والوصول المشترك

قد يستخدم Laween ميزات قائمة على الجلسات، بما في ذلك رموز الجلسات أو الروابط أو الرموز المميزة، للسماح للمستخدمين بالانضمام إلى الطلعات أو الأنشطة الجماعية.

عند إنشائك جلسة أو انضمامك إليها:

قد تكون المعلومات التي تقدمها داخل تلك الجلسة مرئية للمشاركين الآخرين في نفس الجلسة
أنت مسؤول عن تحديد من تشارك معه إمكانية الوصول إلى الجلسة
لا ينبغي لك مشاركة روابط الجلسة أو رموز الوصول أو الرموز المميزة بشكل علني ما لم تكن مدركًا لمخاطر اتساع نطاق الوصول
6. الصلاحيات والوصول إلى الجهاز

بموافقتك، قد يطلب Laween الوصول إلى بعض خصائص الجهاز، بما في ذلك:

جهات الاتصال
الصور / الوسائط
الكاميرا

تُطلب هذه الصلاحيات فقط لدعم ميزات محددة داخل التطبيق. ويمكنك رفضها أو سحبها من خلال إعدادات جهازك، إلا أن ذلك قد يؤدي إلى تقييد بعض الوظائف.

7. الاستخدام المقبول

يجب عليك عدم استخدام Laween من أجل:

مخالفة أي قانون
مضايقة الآخرين أو تهديدهم أو الإساءة إليهم أو ملاحقتهم أو انتحال شخصياتهم
إساءة استخدام الجلسات أو الصلاحيات أو بيانات المستخدمين
محاولة الوصول غير المصرح به إلى الحسابات أو الأنظمة أو الرموز
التدخل في الخدمة أو تعطيلها
استخدام أدوات آلية مثل البوتات أو أدوات الاستخلاص دون إذن
تقديم معلومات كاذبة أو مضللة

يجوز لنا تعليق أو إنهاء الوصول إلى الخدمة إذا تبيّن لنا بشكل معقول حدوث إساءة استخدام.

8. الخصوصية

يخضع استخدامك لـ Laween أيضًا إلى سياسة الخصوصية الخاصة بنا.

قد يعالج Laween قدرًا محدودًا من البيانات الشخصية اللازمة لتشغيل الخدمة، بما في ذلك:

الاسم
البريد الإلكتروني
رقم الهاتف
معلومات الحساب المرتبطة بتسجيل الدخول
المعلومات المتعلقة بالجلسات
البيانات المخزنة سحابيًا الخاصة بالتطبيق
البيانات أو المحتوى المرتبط بالصلاحيات عندما يختار المستخدم منحها
المعلومات المتعلقة بالموقع عند الحاجة لوظائف التطبيق

وفي هذه المرحلة، فإن Laween لا يقوم بما يلي:

توفير مدفوعات إلكترونية عبر التطبيق
إرسال نشرات بريدية
استخدام برامج تحليلات رقمية لأغراض التتبع التسويقي
استخدام إعلانات إعادة الاستهداف
استخدام Facebook Pixel
عرض إعلانات داخل التطبيق
9. خدمات الأطراف الثالثة

قد يعتمد Laween على خدمات أطراف ثالثة مثل:

تسجيل الدخول عبر Google
واجهات Google البرمجية
خدمات Firebase السحابية
مزودي الخرائط أو تحديد الموقع أو البنية التحتية

وقد يخضع استخدامك لبعض الميزات المدمجة أيضًا لشروط وسياسات الخصوصية الخاصة بهذه الجهات. ولسنا مسؤولين عن توفر أو دقة أو ممارسات هذه الخدمات الخارجية.

10. إخلاء المسؤولية

يتم توفير Laween "كما هو" و**"حسب التوفر"**.

ولا نضمن ما يلي:

أن تكون الخدمة متاحة دائمًا دون انقطاع أو خالية من الأخطاء
أن تعمل الجلسات أو الميزات المشتركة أو الميزات المعتمدة على الموقع دائمًا بالشكل الصحيح
أن تظل تكاملات الأطراف الثالثة متاحة دائمًا
أن تكون المعلومات أو المسارات أو اقتراحات اللقاء دقيقة أو كاملة دائمًا

Laween لا يزال في مرحلة الاختبار والتطوير، واستخدامك للخدمة يكون على مسؤوليتك الخاصة.

11. حدود المسؤولية

إلى أقصى حد يسمح به القانون، لا يتحمل Laween أو منشئوه أي مسؤولية عن أي أضرار غير مباشرة أو عرضية أو تبعية أو خاصة أو تأديبية، أو عن أي خسارة في الأرباح أو البيانات أو السمعة أو الفرص، الناشئة عن أو المرتبطة باستخدام الخدمة.

ولا يوجد في هذه الشروط ما يستبعد أي مسؤولية لا يجوز استبعادها قانونًا بموجب القوانين المعمول بها.

12. الإنهاء

يجوز لنا تعليق أو تقييد أو إنهاء الوصول إلى Laween في أي وقت إذا:

خالفت هذه الشروط
أدى استخدامك إلى مخاطر قانونية أو تقنية أو تتعلق بالسلامة
كنا ملزمين بذلك بموجب القانون
قمنا بإيقاف الخدمة أو تعديلها
13. التعديلات على هذه الشروط

يجوز لنا تحديث هذه الشروط من وقت لآخر. وإذا أجرينا تغييرات جوهرية، فسنقوم بنشر النسخة المحدثة وتعديل تاريخ السريان. ويعني استمرارك في استخدام Laween بعد سريان الشروط المعدلة أنك توافق عليها.

14. القانون الواجب التطبيق

تخضع هذه الشروط لقوانين المملكة الأردنية الهاشمية. وتخضع أي نزاعات تنشأ عن هذه الشروط أو عن الخدمة لاختصاص المحاكم المختصة في الأردن، ما لم يقتضِ القانون الإلزامي خلاف ذلك.

15. التواصل

إذا كانت لديك أي أسئلة بخصوص هذه الشروط، يمكنك التواصل معنا عبر:

البريد الإلكتروني: laween.support@gmail.com
''';

class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

  List<Widget> _parseContent(String text, bool isAr) {
    final paragraphs = text.split('\n\n');
    return paragraphs.map((p) {
      p = p.trim();
      if (p.isEmpty) return const SizedBox.shrink();

      final isMainTitle = p.contains('Laween Terms of Service') || p.contains('شروط استخدام Laween');
      final isHeading = RegExp(r'^\d+\.\s').hasMatch(p) || RegExp(r'^[A-Zأ-ي]\.\s').hasMatch(p);
      final isEmail = p.contains('laween.support@gmail.com');

      final baseStyle = isAr 
          ? GoogleFonts.cairo(fontSize: 15, height: 1.8, color: Colors.grey.shade800)
          : GoogleFonts.nunito(fontSize: 15, height: 1.6, color: Colors.grey.shade800);

      if (isMainTitle) {
         return Padding(
           padding: const EdgeInsets.only(bottom: 24, top: 8),
           child: Text(
             p,
             style: isAr 
                ? GoogleFonts.cairo(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.teal)
                : GoogleFonts.nunito(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.teal),
             textAlign: isAr ? TextAlign.right : TextAlign.left,
             textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
           ),
         );
      }

      if (isHeading) {
         return Padding(
           padding: const EdgeInsets.only(top: 24, bottom: 12),
           child: Text(
             p,
             style: isAr 
                ? GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black87)
                : GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black87),
             textAlign: isAr ? TextAlign.right : TextAlign.left,
             textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
           ),
         );
      }

      if (isEmail) {
         final parts = p.split('laween.support@gmail.com');
         return Padding(
           padding: const EdgeInsets.only(bottom: 16),
           child: RichText(
             textAlign: isAr ? TextAlign.right : TextAlign.left,
             textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
             text: TextSpan(
               style: baseStyle,
               children: [
                 TextSpan(text: parts[0]),
                 TextSpan(
                   text: 'laween.support@gmail.com',
                   style: baseStyle.copyWith(
                     color: AppColors.teal, 
                     fontWeight: FontWeight.bold, 
                     decoration: TextDecoration.underline
                   ),
                   recognizer: TapGestureRecognizer()..onTap = () {
                     launchUrl(Uri.parse('mailto:laween.support@gmail.com'));
                   }
                 ),
                 if (parts.length > 1) TextSpan(text: parts[1]),
               ]
             )
           )
         );
      }

      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Text(
          p,
          style: baseStyle,
          textAlign: isAr ? TextAlign.right : TextAlign.left,
          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
        )
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final bool isAr = AppLocalizations.of(context)?.isAr ?? false;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          isAr ? 'الشروط والأحكام' : 'Terms of Service',
          style: isAr
              ? GoogleFonts.cairo(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18)
              : GoogleFonts.nunito(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.grey.shade50,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // Header Graphic
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 32, bottom: 24, left: 24, right: 24),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.teal.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.description_outlined, size: 48, color: AppColors.teal),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isAr ? 'شروط استخدام تطبيقنا' : 'Our Terms of Service',
                    textAlign: TextAlign.center,
                    style: isAr 
                      ? GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)
                      : GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isAr ? 'يرجى قراءة الشروط بعناية قبل استخدام التطبيق' : 'Please read these terms carefully before using the app',
                    textAlign: TextAlign.center,
                    style: isAr 
                      ? GoogleFonts.cairo(fontSize: 14, color: Colors.grey.shade600)
                      : GoogleFonts.nunito(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            
            // Content
            Container(
              margin: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 32.0),
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 16,
                    spreadRadius: 2,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 4,
                    spreadRadius: 0,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: _parseContent(isAr ? _arTerms : _enTerms, isAr),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

