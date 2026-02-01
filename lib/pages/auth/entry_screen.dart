import 'package:flutter/material.dart';
import '../../widgets/auth/auth_theme.dart';
import '../../widgets/auth/auth_button.dart';
import 'login_page.dart';
import 'register_page.dart';

/// Entry Screen - Login/Signup Selector (NeoTaste style)
class EntryScreen extends StatelessWidget {
  const EntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuthTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // NeoTaste Logo
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AuthTheme.accent,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: AuthTheme.accent.withOpacity(0.3),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.local_dining,
                  size: 60,
                  color: AuthTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 48),
              
              // Headline
              Text(
                'Discover the best food deals around you',
                style: AuthTheme.headingLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              
              // Subtitle
              Text(
                'Save money at your favorite restaurants',
                style: AuthTheme.subtitle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 64),
              
              // Continue with Email Button
              AuthButton(
                text: 'Continue with Email',
                onPressed: () {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          const RegisterPage(),
                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                        return SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(1.0, 0.0),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeInOut,
                          )),
                          child: child,
                        );
                      },
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              
              // Continue with Mobile Number Button
              AuthButton(
                text: 'Continue with Mobile Number',
                onPressed: () {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          const RegisterPage(),
                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                        return SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(1.0, 0.0),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeInOut,
                          )),
                          child: child,
                        );
                      },
                    ),
                  );
                },
              ),
              const Spacer(),
              
              // Secondary text button
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          const LoginPage(),
                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                        return SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(1.0, 0.0),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeInOut,
                          )),
                          child: child,
                        );
                      },
                    ),
                  );
                },
                child: Text(
                  'Already have an account? Log in',
                  style: AuthTheme.linkText,
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
