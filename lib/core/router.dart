import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/login_page.dart';
import '../features/auth/register_page.dart';
import '../features/catalog/home_page.dart';
import '../features/catalog/product_detail_page.dart';
import '../features/seller/product_form_page.dart';
import '../features/seller/seller_dashboard_page.dart';
import '../features/seller/store_form_page.dart';
import '../features/vendor/store_page.dart';
import '../widgets/app_shell.dart';
import '../widgets/common.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(path: '/', builder: (context, state) => const HomePage()),
        GoRoute(
          path: '/product/:id',
          builder: (context, state) =>
              ProductDetailPage(productId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/store/:id',
          builder: (context, state) =>
              StorePage(storeId: state.pathParameters['id']!),
        ),
        GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterPage(),
        ),
        GoRoute(
          path: '/seller',
          builder: (context, state) => const SellerDashboardPage(),
        ),
        GoRoute(
          path: '/seller/store',
          builder: (context, state) => const StoreFormPage(),
        ),
        GoRoute(
          path: '/seller/products/new',
          builder: (context, state) => const ProductFormPage(),
        ),
        GoRoute(
          path: '/seller/products/:id/edit',
          builder: (context, state) =>
              ProductFormPage(productId: state.pathParameters['id']),
        ),
      ],
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: EmptyState(
      icon: Icons.explore_off_rounded,
      title: 'Página no encontrada',
      subtitle: state.uri.toString(),
      action: FilledButton(
        onPressed: () => context.go('/'),
        child: const Text('Volver al inicio'),
      ),
    ),
  ),
);
