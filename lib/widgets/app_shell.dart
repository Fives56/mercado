import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/formatters.dart';
import '../core/theme.dart';
import '../state/providers.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const SafeArea(bottom: false, child: _Header()),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _Header extends ConsumerStatefulWidget {
  const _Header();

  @override
  ConsumerState<_Header> createState() => _HeaderState();
}

class _HeaderState extends ConsumerState<_Header> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _submitSearch(String value) {
    ref.read(catalogFiltersProvider.notifier).setText(value);
    context.go('/');
  }

  Future<void> _signOut() async {
    await ref.read(repositoryProvider).signOut();
    refreshCatalog(ref);
    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= 900;
    final user = ref.watch(currentUserProvider);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.ink,
        border: Border(bottom: BorderSide(color: AppColors.inkSoft)),
      ),
      padding: EdgeInsets.symmetric(horizontal: wide ? 28 : 16, vertical: 12),
      child: Row(
        children: [
          InkWell(
            onTap: () => context.go('/'),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.local_mall_rounded,
                      color: Colors.white,
                      size: 21,
                    ),
                  ),
                  if (width >= 400) ...[
                    const SizedBox(width: 10),
                    Text(
                      'Mercado',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (wide) ...[
            const SizedBox(width: 24),
            Expanded(
              child: SizedBox(
                height: 44,
                child: TextField(
                  controller: _searchController,
                  onSubmitted: _submitSearch,
                  textInputAction: TextInputAction.search,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Buscar productos, marcas o tiendas',
                    hintStyle: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 14,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppColors.muted,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: AppColors.accent,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ] else
            const Spacer(),
          const SizedBox(width: 12),
          if (!wide)
            IconButton(
              tooltip: 'Buscar',
              onPressed: () => context.go('/'),
              icon: const Icon(Icons.search_rounded, color: Colors.white70),
            ),
          const SizedBox(width: 4),
          if (wide)
            TextButton.icon(
              onPressed: () => context.go('/seller'),
              icon: const Icon(
                Icons.storefront_rounded,
                color: Colors.white,
                size: 19,
              ),
              label: const Text(
                'Vender',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
            )
          else
            IconButton(
              tooltip: 'Vender',
              onPressed: () => context.go('/seller'),
              icon: const Icon(Icons.storefront_rounded, color: Colors.white),
            ),
          const SizedBox(width: 4),
          if (user == null)
            FilledButton(
              onPressed: () => context.go('/login'),
              style: FilledButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: wide ? 18 : 12,
                  vertical: 12,
                ),
                minimumSize: const Size(0, 40),
              ),
              child: Text(wide ? 'Ingresar' : 'Entrar'),
            )
          else
            PopupMenuButton<String>(
              tooltip: 'Mi cuenta',
              onSelected: (value) {
                if (value == 'panel') context.go('/seller');
                if (value == 'signout') _signOut();
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  enabled: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.displayName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        user.email,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'panel',
                  child: Text('Mi panel de vendedor'),
                ),
                const PopupMenuItem(
                  value: 'signout',
                  child: Text('Cerrar sesión'),
                ),
              ],
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.accent,
                    child: Text(
                      initials(user.displayName),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  if (wide) ...[
                    const SizedBox(width: 8),
                    Text(
                      user.displayName.split(' ').first,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Colors.white70,
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}
