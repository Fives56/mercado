import 'dart:convert';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';

class AsyncView<T> extends StatelessWidget {
  const AsyncView({
    super.key,
    required this.value,
    required this.builder,
    this.loading,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) builder;
  final Widget? loading;

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: builder,
      loading: () =>
          loading ?? const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => ErrorState(message: '$error'),
    );
  }
}

class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 42,
              color: AppColors.muted,
            ),
            const SizedBox(height: 12),
            Text(
              'Algo salió mal',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: onRetry,
                child: const Text('Reintentar'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, color: AppColors.accentDark, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted),
              ),
            ],
            if (action != null) ...[const SizedBox(height: 20), action!],
          ],
        ),
      ),
    );
  }
}

enum AlertTone { error, info, success }

class InlineAlert extends StatelessWidget {
  const InlineAlert({
    super.key,
    required this.message,
    this.tone = AlertTone.error,
    this.title,
  });

  final String message;
  final AlertTone tone;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (tone) {
      AlertTone.error => (AppColors.danger, Icons.error_outline_rounded),
      AlertTone.info => (AppColors.accentDark, Icons.info_outline_rounded),
      AlertTone.success => (
        AppColors.success,
        Icons.check_circle_outline_rounded,
      ),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null) ...[
                  Text(
                    title!,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                ],
                Text(
                  message,
                  style: const TextStyle(
                    color: AppColors.inkSoft,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ProductImage extends StatelessWidget {
  const ProductImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.borderRadius = BorderRadius.zero,
  });

  final String? url;
  final BoxFit fit;
  final BorderRadius borderRadius;

  static final Map<String, Uint8List> _dataCache = {};

  @override
  Widget build(BuildContext context) {
    final source = url?.trim() ?? '';
    if (source.isEmpty) return _placeholder();

    Widget image;
    if (source.startsWith('data:')) {
      final bytes = _dataCache.putIfAbsent(source, () {
        final comma = source.indexOf(',');
        if (comma == -1) return Uint8List(0);
        try {
          return base64Decode(source.substring(comma + 1));
        } on FormatException {
          return Uint8List(0);
        }
      });
      if (bytes.isEmpty) return _placeholder();
      image = Image.memory(
        bytes,
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        gaplessPlayback: true,
      );
    } else {
      image = CachedNetworkImage(
        imageUrl: source,
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        placeholder: (context, url) =>
            Container(color: const Color(0xFFEEF1F5)),
        errorWidget: (context, url, error) => _placeholder(),
      );
    }

    return ClipRRect(borderRadius: borderRadius, child: image);
  }

  Widget _placeholder() {
    return Container(
      color: const Color(0xFFEEF1F5),
      alignment: Alignment.center,
      child: const Icon(Icons.image_outlined, color: AppColors.muted, size: 34),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(subtitle!, style: const TextStyle(color: AppColors.muted)),
              ],
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}
