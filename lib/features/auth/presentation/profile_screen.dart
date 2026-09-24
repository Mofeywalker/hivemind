import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/locale_provider.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/l10n_extension.dart';
import '../../../shared/widgets/card_container.dart';
import '../../../shared/widgets/minimal_button.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _handleSignOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = context.l10n;
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? l10n.anonymous;
    final currentLanguage = ref.watch(localeProvider.notifier).currentLanguage;
    final currentThemeMode = ref.watch(themeProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.accountAndSettings)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Card
              CardContainer(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                      child: Text(
                        email.isNotEmpty ? email[0].toUpperCase() : 'U',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            email,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.hivemindMember,
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              Text(
                l10n.sectionApplication,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 12),

              CardContainer(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.version,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15.5,
                          ),
                        ),
                        Text(
                          '1.0.0',
                          style: TextStyle(
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                            fontSize: 15.5,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 28),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.theme,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15.5,
                          ),
                        ),
                        DropdownButtonHideUnderline(
                          child: DropdownButton<ThemeMode>(
                            value: currentThemeMode,
                            isDense: true,
                            style: TextStyle(
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                              fontSize: 15,
                            ),
                            dropdownColor: isDark
                                ? AppColors.darkSurface
                                : AppColors.lightSurface,
                            items: [
                              DropdownMenuItem(
                                value: ThemeMode.system,
                                child: Text(l10n.themeSystem),
                              ),
                              DropdownMenuItem(
                                value: ThemeMode.light,
                                child: Text(l10n.themeLightMode),
                              ),
                              DropdownMenuItem(
                                value: ThemeMode.dark,
                                child: Text(l10n.themeDarkMode),
                              ),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                ref
                                    .read(themeProvider.notifier)
                                    .setThemeMode(val);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 28),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.language,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15.5,
                          ),
                        ),
                        DropdownButtonHideUnderline(
                          child: DropdownButton<AppLanguage>(
                            value: currentLanguage,
                            isDense: true,
                            style: TextStyle(
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                              fontSize: 15,
                            ),
                            dropdownColor: isDark
                                ? AppColors.darkSurface
                                : AppColors.lightSurface,
                            items: [
                              DropdownMenuItem(
                                value: AppLanguage.system,
                                child: Text(l10n.languageSystem),
                              ),
                              DropdownMenuItem(
                                value: AppLanguage.english,
                                child: Text(l10n.languageEnglish),
                              ),
                              DropdownMenuItem(
                                value: AppLanguage.german,
                                child: Text(l10n.languageGerman),
                              ),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                ref
                                    .read(localeProvider.notifier)
                                    .setLanguage(val);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Sign Out Button
              MinimalButton(
                text: l10n.signOut,
                variant: MinimalButtonVariant.danger,
                icon: const Icon(
                  Icons.logout,
                  size: 18,
                  color: AppColors.error,
                ),
                onPressed: () => _handleSignOut(context),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
