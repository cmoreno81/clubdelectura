import 'package:flutter/material.dart';

import '../navigation/app_page_route.dart';

import 'activation_email_page.dart';
import 'login_page.dart';
import 'registration_page.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.auto_stories_rounded,
                size: 88,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 28),
              Text(
                'Bienvenida a ClubReads',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Tu club de lectura, siempre contigo.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 44),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.push<void>(
                    context,
                    AppPageRoute(builder: (_) => const LoginPage()),
                  ),
                  child: const Text('Acceder'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.push<void>(
                    context,
                    AppPageRoute(builder: (_) => const RegistrationPage()),
                  ),
                  child: const Text('Crear una cuenta'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.push<void>(
                    context,
                    AppPageRoute(builder: (_) => const ActivationEmailPage()),
                  ),
                  child: const Text('Activar mi cuenta'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
