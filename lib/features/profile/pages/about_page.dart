import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/colors.dart';
import 'package:laween/l10n/app_localizations.dart';
import 'package:laween/features/home/pages/home_page.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── 1. Modern Slim AppBar ──
          SliverAppBar(
            expandedHeight: 0,
            floating: true,
            backgroundColor: AppColors.getBackground(context),
            elevation: 0,
            centerTitle: true,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios,
                color: AppColors.getTextPrimary(context),
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              l10n.aboutLaween,
              style: GoogleFonts.inter(
                color: AppColors.getTextPrimary(context),
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),

          SliverList(
            delegate: SliverChildListDelegate([
              // ── 2. Hero Section ──
              _buildHero(context, l10n),

              const SizedBox(height: 48),

              // ── 3. Why Choose Laween? (Feature Grid) ──
              _buildWhySection(context, l10n),

              const SizedBox(height: 64),

              // ── 4. How It Works (Steps) ──
              _buildStepsSection(context, l10n),

              const SizedBox(height: 64),

              // ── 5. Mission Section ──
              _buildMissionSection(context, l10n),

              const SizedBox(height: 80),

              // ── 6. Footer Call to Action ──
              _buildFooter(context, l10n),

              const SizedBox(height: 64),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildHero(BuildContext context, AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.teal.withValues(alpha: 0.05),
            AppColors.getBackground(context),
          ],
        ),
      ),
      child: Column(
        children: [
          Hero(
            tag: 'app_logo',
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: AppColors.getSurfaceElevated(context),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.teal.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset('assets/logo/Laween_transparent_iphone.png'),
              ),
            ),
          ).animate().fadeIn().scale(curve: Curves.easeOutBack),
          const SizedBox(height: 32),
          Text(
            l10n.aboutHeroTitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: AppColors.getTextPrimary(context),
              height: 1.2,
              letterSpacing: -1,
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              l10n.aboutHeroSubtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 16,
                color: AppColors.getTextSecondary(context),
                height: 1.6,
                fontWeight: FontWeight.w500,
              ),
            ),
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
        ],
      ),
    );
  }

  Widget _buildWhySection(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Text(
            l10n.whyChooseLaween,
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.getTextPrimary(context),
            ),
          ).animate().fadeIn().slideX(begin: -0.1),
          const SizedBox(height: 32),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 20,
            crossAxisSpacing: 20,
            childAspectRatio: 0.85,
            children: [
              _buildFeatureCard(
                context,
                l10n.fairForAllTitle,
                l10n.fairForAllDesc,
                Icons.balance_rounded,
                const Color(0xFF6366F1),
                0,
              ),
              _buildFeatureCard(
                context,
                l10n.easyToUseTitle,
                l10n.easyToUseDesc,
                Icons.touch_app_rounded,
                AppColors.teal,
                1,
              ),
              _buildFeatureCard(
                context,
                l10n.discoverPlacesTitle,
                l10n.discoverPlacesDesc,
                Icons.explore_rounded,
                const Color(0xFFF59E0B),
                2,
              ),
              _buildFeatureCard(
                context,
                l10n.perfectForGroupsTitle,
                l10n.perfectForGroupsDesc,
                Icons.groups_rounded,
                const Color(0xFFEC4899),
                3,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    String title,
    String desc,
    IconData icon,
    Color color,
    int index,
  ) {
    return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.getSurfaceElevated(context),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.getBorder(context)),
            boxShadow: [
              BoxShadow(
                color: AppColors.getShadow(context).withValues(alpha: 0.03),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: AppColors.getTextPrimary(context),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Text(
                  desc,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.getTextSecondary(context),
                    height: 1.5,
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(delay: (index * 100).ms)
        .scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildStepsSection(BuildContext context, AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
      decoration: BoxDecoration(color: AppColors.getSurface(context)),
      child: Column(
        children: [
          Text(
            l10n.howItWorks,
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.getTextPrimary(context),
            ),
          ),
          const SizedBox(height: 48),
          _buildStepRow(context, l10n.step1Title, l10n.step1Desc, "1", true),
          _buildStepDivider(),
          _buildStepRow(context, l10n.step2Title, l10n.step2Desc, "2", false),
          _buildStepDivider(),
          _buildStepRow(context, l10n.step3Title, l10n.step3Desc, "3", true),
          _buildStepDivider(),
          _buildStepRow(context, l10n.step4Title, l10n.step4Desc, "4", false),
        ],
      ),
    );
  }

  Widget _buildStepRow(
    BuildContext context,
    String title,
    String desc,
    String num,
    bool isLeft,
  ) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: AppColors.teal,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              num,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.getTextPrimary(context),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                desc,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.getTextSecondary(context),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn().slideX(begin: isLeft ? -0.1 : 0.1);
  }

  Widget _buildStepDivider() {
    return Container(
      margin: const EdgeInsets.only(left: 20, top: 8, bottom: 8),
      height: 30,
      width: 2,
      color: AppColors.teal.withValues(alpha: 0.2),
    );
  }

  Widget _buildMissionSection(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const Icon(Icons.auto_awesome, color: Color(0xFFF59E0B), size: 40),
          const SizedBox(height: 24),
          Text(
            l10n.ourMissionTitle,
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.getTextPrimary(context),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.ourMissionDesc,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 16,
              color: AppColors.getTextSecondary(context),
              height: 1.6,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    ).animate().fadeIn().scale();
  }

  Widget _buildFooter(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.getSurface(context),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: AppColors.getBorder(context)),
        ),
        child: Column(
          children: [
            Text(
              l10n.readyToMeet,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.getTextPrimary(context),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => const HomePage(initialIndex: 1),
                  ),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Text(
                l10n.startPlanning,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2);
  }
}
