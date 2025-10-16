import 'package:flutter/material.dart';

class AppLayout extends StatefulWidget {
  final Widget child;
  final String currentRoute;

  const AppLayout({
    super.key,
    required this.child,
    required this.currentRoute,
  });

  @override
  State<AppLayout> createState() => _AppLayoutState();
}

class _AppLayoutState extends State<AppLayout> {
  bool _isCollapsed = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar Navigation
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: _isCollapsed ? 80 : 280,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.purple.shade700,
                  Colors.purple.shade900,
                  Colors.deepPurple.shade900,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(2, 0),
                ),
              ],
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: EdgeInsets.all(_isCollapsed ? 16 : 24),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(_isCollapsed ? 8 : 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.inventory_2_rounded,
                          color: Colors.white,
                          size: _isCollapsed ? 24 : 28,
                        ),
                      ),
                      if (!_isCollapsed) ...[
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Inventory',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Manager',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Divider(color: Colors.white24, height: 1),
                const SizedBox(height: 8),

                // Navigation Items
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    children: [
                      _buildNavItem(
                        icon: Icons.dashboard_rounded,
                        label: 'Dashboard',
                        route: '/api-home',
                        isActive: widget.currentRoute == '/api-home',
                      ),
                      _buildNavItem(
                        icon: Icons.inventory_rounded,
                        label: 'Inventory',
                        route: '/api-inventory',
                        isActive: widget.currentRoute == '/api-inventory',
                      ),
                      _buildNavItem(
                        icon: Icons.category_rounded,
                        label: 'Categories',
                        route: '/api-categories',
                        isActive: widget.currentRoute == '/api-categories',
                      ),
                      _buildNavItem(
                        icon: Icons.shopping_cart_rounded,
                        label: 'Add Product',
                        route: '/api-purchase',
                        isActive: widget.currentRoute == '/api-purchase',
                      ),
                      _buildNavItem(
                        icon: Icons.point_of_sale_rounded,
                        label: 'Sale',
                        route: '/api-sale',
                        isActive: widget.currentRoute == '/api-sale',
                      ),
                      const SizedBox(height: 8),
                      if (!_isCollapsed)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Text(
                            'REPORTS',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      if (_isCollapsed) const Divider(color: Colors.white24, height: 20),
                      _buildNavItem(
                        icon: Icons.account_balance_wallet_rounded,
                        label: 'Account',
                        route: '/api-account',
                        isActive: widget.currentRoute == '/api-account',
                      ),
                      _buildNavItem(
                        icon: Icons.analytics_rounded,
                        label: 'Reports',
                        route: '/api-reports',
                        isActive: widget.currentRoute == '/api-reports',
                      ),
                      const SizedBox(height: 8),
                      if (!_isCollapsed)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Text(
                            'PREFERENCES',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      if (_isCollapsed) const Divider(color: Colors.white24, height: 20),
                      _buildNavItem(
                        icon: Icons.settings_rounded,
                        label: 'Settings',
                        route: '/settings',
                        isActive: widget.currentRoute == '/settings',
                      ),
                    ],
                  ),
                ),

                // Collapse Button
                const Divider(color: Colors.white24, height: 1),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => setState(() => _isCollapsed = !_isCollapsed),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _isCollapsed
                                  ? Icons.chevron_right
                                  : Icons.chevron_left,
                              color: Colors.white,
                            ),
                            if (!_isCollapsed) ...[
                              const SizedBox(width: 8),
                              const Text(
                                'Collapse',
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Main Content
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.grey.shade50,
                    Colors.blue.shade50,
                    Colors.purple.shade50,
                  ],
                ),
              ),
              child: widget.child,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required String route,
    required bool isActive,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (!isActive) {
              // Use smooth fade transition for navigation
              Navigator.of(context).pushReplacementNamed(route);
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: _isCollapsed ? 12 : 16,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              color: isActive
                  ? Colors.white.withValues(alpha: 0.2)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isActive
                  ? Border.all(color: Colors.white.withValues(alpha: 0.3))
                  : null,
            ),
            child: _isCollapsed
                ? Center(
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: 24,
                    ),
                  )
                : Row(
                    children: [
                      Icon(
                        icon,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          label,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
