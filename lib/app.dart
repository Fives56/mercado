import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config.dart';
import 'core/router.dart';
import 'core/theme.dart';
import 'state/providers.dart';
import 'widgets/brand_splash.dart';
import 'widgets/common.dart';

class MarketplaceBootstrap extends StatefulWidget {
  const MarketplaceBootstrap({super.key});

  @override
  State<MarketplaceBootstrap> createState() => _MarketplaceBootstrapState();
}

class _MarketplaceBootstrapState extends State<MarketplaceBootstrap> {
  late Future<void> _initialization;

  @override
  void initState() {
    super.initState();
    _initialization = _initializeBackend();
  }

  Future<void> _initializeBackend() {
    if (!AppConfig.hasSupabase) return Future.value();
    return Supabase.initialize(
      url: AppConfig.supabaseUrl,
      publishableKey: AppConfig.supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        persistSession: true,
        autoRefreshToken: true,
      ),
    ).timeout(const Duration(seconds: 12));
  }

  void _retry() {
    setState(() => _initialization = _initializeBackend());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _BootstrapFrame(
            child: BrandSplash(message: 'Preparando tu sesión…'),
          );
        }
        if (snapshot.hasError) {
          return _BootstrapFrame(
            child: _StartupErrorScreen(error: snapshot.error!, onRetry: _retry),
          );
        }
        return const MercadoApp();
      },
    );
  }
}

class MercadoApp extends StatelessWidget {
  const MercadoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Mercado',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      routerConfig: appRouter,
      builder: (context, child) =>
          _AuthBootstrap(child: child ?? const SizedBox.shrink()),
    );
  }
}

class _AuthBootstrap extends ConsumerWidget {
  const _AuthBootstrap({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    if (auth.isLoading) {
      return const BrandSplash(message: 'Restaurando tu sesión…');
    }
    return child;
  }
}

class _BootstrapFrame extends StatelessWidget {
  const _BootstrapFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mercado',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: child,
    );
  }
}

class _StartupErrorScreen extends StatelessWidget {
  const _StartupErrorScreen({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  String get _message {
    final text = error.toString().replaceFirst('Exception: ', '');
    return text.length > 300 ? '${text.substring(0, 300)}…' : text;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.cloud_off_rounded,
                      color: AppColors.danger,
                      size: 40,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No pudimos conectar con Supabase',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Revisa tu conexión a internet y vuelve a intentarlo. '
                      'Si el problema continúa, verifica que el proyecto de '
                      'Supabase esté activo.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.muted, height: 1.5),
                    ),
                    const SizedBox(height: 18),
                    InlineAlert(message: _message),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Reintentar'),
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
