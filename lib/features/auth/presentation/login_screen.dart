import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/l10n_extension.dart';
import '../../../core/widgets/hivemind_logo.dart';
import '../../../shared/widgets/minimal_button.dart';
import '../../../shared/widgets/minimal_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isSignUp = false;
  bool _useMagicLink = false;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleEmailPasswordAuth() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    try {
      if (_isSignUp) {
        final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        if (cred.user != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(cred.user!.uid)
              .set({
                'display_name': email.split('@').first,
                'email': email,
                'created_at': DateTime.now().toUtc().toIso8601String(),
                'updated_at': DateTime.now().toUtc().toIso8601String(),
              }, SetOptions(merge: true));
        }
        if (mounted) {
          context.go('/');
        }
      } else {
        try {
          await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: email,
            password: password,
          );
          if (mounted) {
            context.go('/');
          }
        } on FirebaseAuthException catch (e) {
          if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
            setState(() {
              _isSignUp = true;
              _errorMessage = 'Noch kein Konto gefunden. Bitte tippe auf "Konto erstellen", um dich zu registrieren.';
            });
            return;
          }
          rethrow;
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = context.l10n.errorUnexpected(e.toString());
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleMagicLinkAuth() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        _errorMessage = context.l10n.emailInvalid;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('emailForSignIn', email);

      final actionCodeSettings = ActionCodeSettings(
        url: 'https://hivemind-236c0.firebaseapp.com',
        handleCodeInApp: true,
        androidPackageName: 'de.mf1337.hivemind',
        androidInstallApp: true,
        androidMinimumVersion: '1',
      );
      await FirebaseAuth.instance.sendSignInLinkToEmail(
        email: email,
        actionCodeSettings: actionCodeSettings,
      );
      if (mounted) {
        setState(() {
          _successMessage = context.l10n.magicLinkSent;
        });
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = context.l10n.errorCouldNotSendMagicLink(e.toString());
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = context.l10n;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Brand Icon & Title
                    Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.25),
                              width: 1,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: const HivemindLogo.icon(size: 34),
                        ),
                        const SizedBox(width: 14),
                        Text(
                          'hivemind',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.8,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      _useMagicLink
                          ? l10n.authSubtitleMagicLink
                          : _isSignUp
                          ? l10n.authSubtitleSignUp
                          : l10n.authSubtitlePassword,
                      style: TextStyle(
                        fontSize: 16,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Success / Error Banner
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.error.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 18,
                              color: AppColors.error,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(
                                  color: AppColors.error,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    if (_successMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.success.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle_outline,
                              size: 18,
                              color: AppColors.success,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _successMessage!,
                                style: const TextStyle(
                                  color: AppColors.success,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Input Fields
                    MinimalTextField(
                      controller: _emailController,
                      label: l10n.emailLabel,
                      hintText: l10n.emailHint,
                      keyboardType: TextInputType.emailAddress,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return l10n.emailRequired;
                        }
                        if (!val.contains('@')) return l10n.emailInvalid;
                        return null;
                      },
                    ),

                    if (!_useMagicLink) ...[
                      const SizedBox(height: 16),
                      MinimalTextField(
                        controller: _passwordController,
                        label: l10n.passwordLabel,
                        hintText: l10n.passwordHint,
                        obscureText: true,
                        validator: (val) {
                          if (val == null || val.length < 6) {
                            return l10n.passwordTooShort;
                          }
                          return null;
                        },
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Primary Submit Button
                    MinimalButton(
                      text: _isLoading
                          ? l10n.loading
                          : _useMagicLink
                          ? l10n.buttonSendMagicLink
                          : _isSignUp
                          ? l10n.buttonCreateAccount
                          : l10n.buttonSignIn,
                      isLoading: _isLoading,
                      onPressed: _useMagicLink
                          ? _handleMagicLinkAuth
                          : _handleEmailPasswordAuth,
                    ),

                    const SizedBox(height: 16),

                    // Toggle Auth Mode
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        TextButton(
                          style: TextButton.styleFrom(
                            minimumSize: const Size(48, 44),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                          ),
                          onPressed: () {
                            setState(() {
                              _useMagicLink = !_useMagicLink;
                              _errorMessage = null;
                              _successMessage = null;
                            });
                          },
                          child: Text(
                            _useMagicLink
                                ? l10n.usePasswordInstead
                                : l10n.useMagicLink,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (!_useMagicLink)
                          TextButton(
                            style: TextButton.styleFrom(
                              minimumSize: const Size(48, 44),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 8,
                              ),
                            ),
                            onPressed: () {
                              setState(() {
                                _isSignUp = !_isSignUp;
                                _errorMessage = null;
                                _successMessage = null;
                              });
                            },
                            child: Text(
                              _isSignUp
                                  ? l10n.haveAccountSignIn
                                  : l10n.needAccountSignUp,
                              style: TextStyle(
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                                fontSize: 14.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
