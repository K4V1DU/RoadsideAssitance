import 'package:flutter/material.dart';

import '../../../entities/app_user.dart';
import 'login_page.dart';

/// First screen shown to a signed-out user. Lets them pick which role
/// they're signing up/logging in as before phone verification, so that
/// once OTP succeeds, a brand-new account lands on the correct
/// complete-profile page. Existing users are routed to their real,
/// already-stored role regardless of what they tap here.
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  void _goToLogin(BuildContext context, UserType intendedRole) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => LoginPage(intendedRole: intendedRole)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Top hero image.
          SizedBox(
            height: 280,
            width: double.infinity,
            child: Image.asset(
              'assets/images/welcome.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: Colors.grey.shade300,
                child: Icon(
                  Icons.build_circle_outlined,
                  size: 80,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 28),
                  Image.asset(
                    'assets/images/logo.png',
                    height: 56,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.local_shipping,
                      size: 48,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Ceylon Roadside Assistant',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Peace of mind behind\nthe wheel',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () => _goToLogin(context, UserType.driver),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE30613),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: const Text(
                        'Get Started',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () =>
                        _goToLogin(context, UserType.assistanceProvider),
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: const TextSpan(
                        style: TextStyle(fontSize: 14, color: Colors.black87),
                        children: [
                          TextSpan(text: 'Want to earn? '),
                          TextSpan(
                            text: 'Register as a Assistant',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
