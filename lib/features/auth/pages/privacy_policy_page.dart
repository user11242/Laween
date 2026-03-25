import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/gestures.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/theme/colors.dart';

const String _enPrivacy = '''Laween Privacy Policy

Effective Date: 25 May 2026

Laween (“Laween,” “we,” “us,” or “our”) is a mobile application created and operated by individual developers based in the Hashemite Kingdom of Jordan. This Privacy Policy explains how we collect, use, store, and protect information when you use the Laween app and related services (the “Service”).

By using Laween, you acknowledge that you have read this Privacy Policy.

1. Scope of This Policy

This Privacy Policy applies to the Laween mobile application and related services as currently offered and tested in Jordan. If Laween expands to other countries in the future, we may update this Privacy Policy to reflect additional legal or operational requirements.

2. Information We Collect

We collect only the information reasonably necessary to operate Laween and provide its features.

A. Information You Provide Directly

When you create an account or use Laween, we may collect:
- your name
- your email address
- your phone number
- account-related information you choose to provide
- information you enter when creating or joining outings or sessions
- content or information you voluntarily provide through the app

B. Login and Authentication Information

If you use Google login, we may receive account information made available through that sign-in process, such as your name, email address, and basic profile/account identifiers necessary to authenticate you and create or maintain your account. Google’s own documentation explains that when users connect through Sign in with Google, the third-party app’s own privacy policy and retention practices apply to how that app uses and keeps the shared data.

C. Session and Outing Information

Laween uses sessions and session tokens/codes/links to support outings and shared coordination features. When you create, join, or participate in a session, we may process:
- session identifiers or tokens
- participant-related session data
- outing/session details you submit
- information necessary to enable session functionality and access control

D. Permission-Based Information

With your permission, Laween may access certain device features only when needed for a feature you choose to use, including:
- Contacts
- Photos / media
- Camera

If you deny or revoke permission, related features may be unavailable or limited.

E. Location-Related Information

If Laween uses location-based features, we may process location-related information necessary for app functionality, coordination, routing, or meeting-point features. Under Jordan’s Personal Data Protection Law, “personal data” is defined broadly and includes data that identifies a person directly or indirectly; that law is in force in Jordan.

F. Cloud Storage and Technical Service Data

Laween uses Firebase and related cloud services to store and support app functionality. Firebase’s official privacy documentation states that, when customers use Firebase, Google generally acts as a processor/service provider on their behalf.

3. Information We Do Not Use for Current Operations

At this stage, Laween does not:
- send newsletters
- offer online payments in the app
- display third-party advertisements in the app
- use Facebook Pixel
- use retargeting advertising
- use digital analytics software for tracking or marketing purposes

If this changes in the future, we will update this Privacy Policy.

4. How We Use Information

We use the information we process to:
- create and manage user accounts
- authenticate users, including through Google login
- enable outings, sessions, and token-based participation
- provide Laween’s core features and app functionality
- allow selected permission-based features to work when users choose to enable them
- store and retrieve necessary app data using Firebase/cloud services
- maintain app security, integrity, and technical operation
- respond to support requests and user communications
- comply with legal obligations where applicable

We do not use your information for newsletter marketing, retargeting, or behavioral advertising at this stage.

5. Legal and Compliance Basis

Laween is based in Jordan and is intended to operate consistently with applicable Jordanian law, including Jordan’s Personal Data Protection Law No. 24 of 2023, which officially took effect on 17 March 2024, according to Jordan’s Ministry of Digital Economy and Entrepreneurship FAQ.

6. How Information Is Shared

We do not sell personal data.

We may share or disclose information only in the following limited circumstances:

A. With Service Providers and Infrastructure Providers
We may use third-party service providers that help us operate the Service, including:
- Google login / Google APIs
- Firebase / cloud storage and related infrastructure
- other limited technical providers required to run the app

These providers may process information on our behalf or as part of providing their own integrated services. Firebase’s official materials explain that Google generally acts as a processor/service provider for Firebase customers.

B. Within Sessions
If you create or join an outing/session, certain information you submit within that session may be visible to other participants in that same session as required for the feature to work.

C. For Legal Reasons
We may disclose information where required by applicable law, lawful request, court order, regulatory requirement, or to protect rights, safety, security, or the integrity of the Service.

7. Data Storage and Retention

We use cloud storage, including Firebase, to support Laween’s functionality. We retain information only for as long as reasonably necessary to operate the Service, maintain account functionality, support sessions, resolve technical issues, comply with legal obligations, and protect the security and integrity of the Service.

Because Laween is still in a testing stage, specific retention periods may be revised as the product matures.

8. Account and Session Security

We take reasonable technical and organizational steps to protect information and reduce the risk of unauthorized access, misuse, alteration, or disclosure. Firebase provides security tooling such as Security Rules for protecting access to app data, although actual implementation depends on how the app is configured.

However, no internet-based system or storage method is completely secure, and we cannot guarantee absolute security.

You are also responsible for helping protect your own account, device, login credentials, and session links/tokens.

9. Your Choices

You may choose whether to grant or deny device permissions such as contacts, camera, and photos. You may also choose whether to use Google login where supported.

You can usually control permissions through your device settings. If you revoke permissions, some features may stop working.

10. Your Rights and Requests

Depending on applicable law, you may have rights to request access to, correction of, deletion of, or information about personal data we hold about you.

Because Laween also relies on third-party services such as Google login and Firebase, some data may also be subject to those providers’ own systems, policies, and controls. Google’s documentation states that how long data is kept by the third-party app depends on that app’s own retention policy, while Firebase documentation explains Google’s role in processing customer data.

11. International Use

Laween is currently being tested for use in Jordan. If the Service later becomes available in other countries, user information may be processed through infrastructure or service providers operating in multiple jurisdictions, depending on the technical services used to run the app.

12. Children

Laween is not intended for users under 18 years old, and we do not intend for minors under that age to use the Service.

If we become aware that information has been collected from a user who is not eligible to use Laween under our Terms, we may take steps to delete the information and suspend or remove the account.

13. Changes to This Privacy Policy

We may update this Privacy Policy from time to time. If we make material changes, we will post the updated version and revise the effective date.

Your continued use of Laween after an updated Privacy Policy takes effect means you acknowledge the revised policy.

14. Contact Us

If you have questions about this Privacy Policy or privacy-related requests, please contact us at:

Email: laween.support@gmail.com
''';

const String _arPrivacy = '''سياسة الخصوصية الخاصة بـ Laween

تاريخ السريان: 25 مايو 2026

تشير "Laween" أو "نحن" أو "لنا" إلى تطبيق تم إنشاؤه وتشغيله بواسطة مطورين أفراد في المملكة الأردنية الهاشمية. توضح سياسة الخصوصية هذه كيفية جمع المعلومات ومعالجتها وتخزينها وحمايتها عند استخدامك تطبيق Laween والخدمات المرتبطة به ("الخدمة").

باستخدامك Laween، فإنك تقر بأنك قد قرأت سياسة الخصوصية هذه.

1. نطاق هذه السياسة

تنطبق سياسة الخصوصية هذه على تطبيق Laween والخدمات المرتبطة به كما هي مطروحة ومختبرة حاليًا داخل الأردن. وإذا توسع Laween مستقبلًا إلى دول أخرى، فقد نقوم بتحديث هذه السياسة بما يعكس المتطلبات القانونية أو التشغيلية الإضافية.

2. المعلومات التي نجمعها

نحن نجمع فقط المعلومات اللازمة بشكل معقول لتشغيل Laween وتقديم ميزاته.

أ. المعلومات التي تقدمها مباشرة

عند إنشاء حساب أو استخدام Laween، قد نجمع:

الاسم
البريد الإلكتروني
رقم الهاتف
معلومات الحساب التي تختار تقديمها
المعلومات التي تدخلها عند إنشاء جلسات أو طلعات أو الانضمام إليها
أي محتوى أو معلومات تقدمها طوعًا عبر التطبيق
ب. معلومات تسجيل الدخول والمصادقة

إذا استخدمت تسجيل الدخول عبر Google، فقد نتلقى معلومات حساب يتيحها هذا النوع من تسجيل الدخول، مثل الاسم والبريد الإلكتروني وبعض المعرفات الأساسية اللازمة للتحقق من هويتك وإنشاء حسابك أو إدارته.

ج. معلومات الجلسات والطلعات

يستخدم Laween الجلسات والرموز أو الروابط أو الرموز المميزة الخاصة بالجلسات لدعم الطلعات وميزات التنسيق المشترك. وعند إنشاء جلسة أو الانضمام إليها أو المشاركة فيها، قد نقوم بمعالجة:

معرّفات الجلسات أو رموزها
بيانات المشاركين المرتبطة بالجلسة
تفاصيل الجلسة أو الطلعة التي تقدمها
المعلومات اللازمة لتفعيل وظائف الجلسة والتحكم في الوصول إليها
د. المعلومات المرتبطة بالصلاحيات

بموافقتك، قد يصل Laween إلى بعض خصائص الجهاز فقط عند الحاجة إلى ميزة تختار استخدامها، بما في ذلك:

جهات الاتصال
الصور / الوسائط
الكاميرا

إذا رفضت الصلاحية أو قمت بسحبها، فقد تصبح بعض الميزات غير متاحة أو محدودة.

هـ. المعلومات المتعلقة بالموقع

إذا استخدم Laween ميزات تعتمد على الموقع، فقد نعالج معلومات متعلقة بالموقع تكون لازمة لوظائف التطبيق أو التنسيق أو التوجيه أو اقتراح نقاط اللقاء.

و. التخزين السحابي والبيانات التقنية

يستخدم Laween Firebase وخدمات سحابية مرتبطة به لتخزين البيانات ودعم وظائف التطبيق.

3. أمور لا نستخدمها في المرحلة الحالية

في المرحلة الحالية، لا يقوم Laween بما يلي:

إرسال نشرات بريدية
توفير مدفوعات إلكترونية داخل التطبيق
عرض إعلانات طرف ثالث داخل التطبيق
استخدام Facebook Pixel
استخدام إعلانات إعادة الاستهداف
استخدام برامج تحليلات رقمية لأغراض التتبع أو التسويق

إذا تغيّر ذلك في المستقبل، فسنقوم بتحديث سياسة الخصوصية هذه.

4. كيف نستخدم المعلومات

نستخدم المعلومات التي نعالجها من أجل:

إنشاء الحسابات وإدارتها
التحقق من هوية المستخدمين، بما في ذلك عبر تسجيل الدخول باستخدام Google
تمكين الطلعات والجلسات والمشاركة المعتمدة على الرموز
توفير الميزات الأساسية للتطبيق
تمكين الميزات التي تعتمد على الصلاحيات عندما يختار المستخدم تفعيلها
تخزين واسترجاع البيانات اللازمة باستخدام Firebase والخدمات السحابية
الحفاظ على أمان التطبيق وسلامته وتشغيله الفني
الرد على طلبات الدعم والتواصل مع المستخدمين
الامتثال للالتزامات القانونية عند الاقتضاء

ونحن لا نستخدم معلوماتك في هذه المرحلة لأغراض النشرات البريدية أو إعادة الاستهداف أو الإعلانات السلوكية.

5. الامتثال القانوني

يعتمد Laween على الامتثال للقوانين المعمول بها في المملكة الأردنية الهاشمية، بما في ذلك ما يتعلق بحماية البيانات والجرائم الإلكترونية، وذلك بالقدر الذي ينطبق على طبيعة الخدمة وطريقة تشغيلها.

6. كيفية مشاركة المعلومات

نحن لا نبيع البيانات الشخصية.

وقد نشارك أو نفصح عن المعلومات فقط في الحالات المحدودة التالية:

أ. مع مزودي الخدمات والبنية التحتية

قد نستخدم مزودي خدمات من الأطراف الثالثة لتشغيل الخدمة، بما في ذلك:

Google login / Google APIs
Firebase / التخزين السحابي والخدمات المرتبطة به
مزودون تقنيون محدودون آخرون عند الحاجة لتشغيل التطبيق
ب. داخل الجلسات

إذا قمت بإنشاء جلسة أو الانضمام إلى جلسة، فقد تكون بعض المعلومات التي تقدمها داخل تلك الجلسة مرئية للمشاركين الآخرين في نفس الجلسة بالقدر اللازم لعمل الميزة.

ج. لأسباب قانونية

قد نفصح عن المعلومات إذا كان ذلك مطلوبًا بموجب القانون أو بطلب قانوني صالح أو أمر قضائي أو متطلب تنظيمي، أو لحماية الحقوق أو السلامة أو أمن الخدمة أو سلامتها.

7. تخزين البيانات والاحتفاظ بها

نستخدم التخزين السحابي، بما في ذلك Firebase، لدعم وظائف Laween. ونحتفظ بالمعلومات فقط للمدة اللازمة بشكل معقول لتشغيل الخدمة، والحفاظ على وظائف الحساب، ودعم الجلسات، وحل المشكلات التقنية، والامتثال للالتزامات القانونية، وحماية أمن الخدمة وسلامتها.

وبما أن Laween لا يزال في مرحلة الاختبار، فقد تتم مراجعة فترات الاحتفاظ المحددة مع تطور المنتج.

8. أمان الحساب والجلسات

نتخذ خطوات تقنية وتنظيمية معقولة لحماية المعلومات وتقليل مخاطر الوصول غير المصرح به أو إساءة الاستخدام أو التعديل أو الإفصاح.

ومع ذلك، لا توجد وسيلة نقل عبر الإنترنت أو نظام تخزين آمن بشكل مطلق، ولذلك لا يمكننا ضمان الأمان الكامل.

وأنت أيضًا مسؤول عن المساهمة في حماية حسابك وجهازك وبيانات تسجيل الدخول وروابط الجلسات أو رموزها.

9. خياراتك

يمكنك اختيار منح أو رفض صلاحيات الجهاز مثل جهات الاتصال والكاميرا والصور. كما يمكنك اختيار استخدام تسجيل الدخول عبر Google عند توفره.

وعادة يمكنك التحكم في هذه الصلاحيات من خلال إعدادات جهازك. وإذا قمت بسحب الصلاحيات، فقد تتوقف بعض الميزات عن العمل.

10. حقوقك وطلباتك

وفقًا للقانون المعمول به، قد تكون لك حقوق تتعلق بطلب الوصول إلى بياناتك الشخصية أو تصحيحها أو حذفها أو الاستفسار عنها.

إذا رغبت في تقديم طلب متعلق بالخصوصية، يمكنك التواصل معنا عبر:

البريد الإلكتروني: laween.support@gmail.com

وقد تخضع بعض البيانات أيضًا لأنظمة وسياسات وضوابط مقدمي الخدمات من الأطراف الثالثة مثل Google وFirebase.

11. الاستخدام الدولي

يتم حاليًا اختبار Laween للاستخدام داخل الأردن. وإذا أصبح التطبيق متاحًا في دول أخرى مستقبلًا، فقد تتم معالجة معلومات المستخدمين عبر بنى تحتية أو مزودي خدمات يعملون في ولايات قضائية متعددة، بحسب الخدمات التقنية المستخدمة لتشغيل التطبيق.

12. الأطفال

Laween غير مخصص للمستخدمين الذين تقل أعمارهم عن 18 عامًا، ولا نقصد أن يستخدمه من هم دون هذا العمر.

وإذا علمنا أنه تم جمع معلومات من مستخدم غير مؤهل لاستخدام Laween بموجب شروطنا، فقد نتخذ خطوات لحذف تلك المعلومات وتعليق الحساب أو إزالته.

13. التعديلات على سياسة الخصوصية

يجوز لنا تحديث سياسة الخصوصية هذه من وقت لآخر. وإذا أجرينا تغييرات جوهرية، فسنقوم بنشر النسخة المحدثة وتعديل تاريخ السريان.

ويعني استمرارك في استخدام Laween بعد سريان السياسة المحدثة أنك تقر بالنسخة المعدلة.

14. التواصل معنا

إذا كانت لديك أي أسئلة حول سياسة الخصوصية هذه أو أي طلبات متعلقة بالخصوصية، يمكنك التواصل معنا عبر:

البريد الإلكتروني: laween.support@gmail.com
''';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  List<Widget> _parseContent(String text, bool isAr) {
    final paragraphs = text.split('\n\n');
    return paragraphs.map((p) {
      p = p.trim();
      if (p.isEmpty) return const SizedBox.shrink();

      final isMainTitle = p.contains('Laween Privacy Policy') || p.contains('سياسة الخصوصية الخاصة بـ Laween');
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
          isAr ? 'سياسة الخصوصية' : 'Privacy Policy',
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
                    child: Icon(Icons.privacy_tip_outlined, size: 48, color: AppColors.teal),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isAr ? 'سياسة الخصوصية الخاصة بنا' : 'Our Privacy Policy',
                    textAlign: TextAlign.center,
                    style: isAr 
                      ? GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)
                      : GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isAr ? 'تعرف على كيفية حماية بياناتك' : 'Learn how we protect your data',
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
                  children: _parseContent(isAr ? _arPrivacy : _enPrivacy, isAr),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

