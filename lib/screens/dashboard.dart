import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'upcoming_puja_screen.dart';

class Dashboard extends StatelessWidget {
  const Dashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard'),
        backgroundColor: AppTheme.gold,
        foregroundColor: AppTheme.primaryIndigo,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.dashboard, size: 80, color: AppTheme.primaryColor),
            SizedBox(height: 20),
            Text(
              'Welcome to AstroPandit Dashboard',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Login + OTP flow complete!',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 220,
              height: 46,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryIndigo,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const UpcomingPujaScreen()),
                  );
                },
                icon: const Icon(Icons.temple_hindu_rounded),
                label: const Text('Upcoming Puja'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
