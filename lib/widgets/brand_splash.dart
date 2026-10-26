import 'package:flutter/material.dart';

import '../core/theme.dart';

class BrandSplash extends StatelessWidget {
  const BrandSplash({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.all(Radius.circular(18)),
              ),
              child: Padding(
                padding: EdgeInsets.all(14),
                child: Icon(
                  Icons.local_mall_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Mercado',
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.6,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                style: const TextStyle(color: AppColors.muted, fontSize: 13),
              ),
            ],
            const SizedBox(height: 24),
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            ),
          ],
        ),
      ),
    );
  }
}
