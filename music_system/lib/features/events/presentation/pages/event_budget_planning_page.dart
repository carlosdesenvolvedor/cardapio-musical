import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dartz/dartz.dart' hide State;
import '../../../../config/theme/app_theme.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../injection_container.dart';
import '../../../auth/presentation/pages/profile_page.dart';
import '../../../bookings/presentation/bloc/budget_cart_bloc.dart';
import '../../../service_provider/domain/entities/service_entity.dart';
import '../../../service_provider/domain/usecases/get_all_services.dart';
import '../../../community/presentation/pages/artist_network_page.dart';

class EventBudgetPlanningPage extends StatefulWidget {
  const EventBudgetPlanningPage({super.key});

  @override
  State<EventBudgetPlanningPage> createState() =>
      _EventBudgetPlanningPageState();
}

class _EventBudgetPlanningPageState extends State<EventBudgetPlanningPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'Todos';

  final List<String> _categories = [
    'Todos',
    'Cantor',
    'Músico',
    'Banda',
    'Dj',
    'Fotógrafo',
    'Videógrafo',
    'Segurança',
    'Buffet/Catering',
    'Equipe Técnica',
    'Decoração',
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isDesktop = constraints.maxWidth > 900;
        return Scaffold(
          backgroundColor: const Color(0xFF0A0A0A),
          drawer: isDesktop ? null : _buildMobileDrawer(),
          body: Row(
            children: [
              if (isDesktop) _buildSidebar(),
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    _buildAppBar(isDesktop),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildAnalyticsSection(isDesktop),
                            const SizedBox(height: 32),
                            _buildSearchAndFilters(isDesktop),
                            const SizedBox(height: 24),
                            _buildProvidersContent(isDesktop),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (isDesktop) _buildCartPanel(),
            ],
          ),
          bottomNavigationBar: isDesktop ? null : _buildMobileBottomNav(),
        );
      },
    );
  }

  Widget _buildAppBar(bool isDesktop) {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: const Text(
        'CRIAÇÃO DE ORÇAMENTO',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
      leading: isDesktop
          ? null
          : Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu, color: AppTheme.primaryColor),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
      actions: [
        if (!isDesktop) ...[
          IconButton(
            icon: const _CartBadge(),
            onPressed: () {
              // Show cart bottom sheet for mobile
              _showMobileCart();
            },
          ),
          const SizedBox(width: 8),
        ],
      ],
      floating: true,
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 260,
      height: double.infinity,
      color: const Color(0xFF121212),
      child: Column(
        children: [
          const SizedBox(height: 40),
          _sidebarItem(Icons.home_outlined, 'Voltar para MixArt', onTap: () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                  builder: (context) => const ArtistNetworkPage()),
              (route) => false,
            );
          }),
          const Divider(color: Colors.white10),
          _sidebarItem(Icons.dashboard_outlined, 'Visão Geral',
              isSelected: true),
          _sidebarItem(Icons.analytics_outlined, 'Dashboard'),
          _sidebarItem(Icons.chat_bubble_outline, 'Chat com Perfis',
              badge: '1'),
          _sidebarItem(Icons.settings_outlined, 'Configurações', badge: '1'),
        ],
      ),
    );
  }

  Widget _sidebarItem(IconData icon, String label,
      {bool isSelected = false, String? badge, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: isSelected ? AppTheme.primaryColor : Colors.white54,
                size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? AppTheme.primaryColor : Colors.white70,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                    color: Color(0xFFE5B80B), shape: BoxShape.circle),
                child: Text(badge,
                    style: const TextStyle(
                        color: Colors.black,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsSection(bool isDesktop) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _analyticsCard('Budget/Gastos', child: _buildCircularChart()),
          const SizedBox(width: 16),
          _analyticsCard('Lucro Estimado', child: _buildLineChart()),
          const SizedBox(width: 16),
          _analyticsCard(
            'Status do Evento',
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Faltam',
                    style: TextStyle(color: Colors.white54, fontSize: 12)),
                const Text('30',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.bold)),
                const Text('Dias',
                    style: TextStyle(color: Colors.white, fontSize: 18)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.cloud_outlined, color: Colors.white54, size: 16),
                    SizedBox(width: 4),
                    Text('Rio, 25°C',
                        style: TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          _analyticsCard('Lucro Estimado',
              child: _buildLineChart(isGreen: true)),
        ],
      ),
    );
  }

  Widget _analyticsCard(String title, {required Widget child}) {
    return Container(
      width: 200,
      height: 240,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
                color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
          ),
          Expanded(child: Center(child: child)),
        ],
      ),
    );
  }

  Widget _buildCircularChart() {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 100,
          height: 100,
          child: CircularProgressIndicator(
            value: 0.7,
            strokeWidth: 12,
            backgroundColor: Colors.white10,
            color: const Color(0xFFE5B80B),
          ),
        ),
        const Text('70%',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildLineChart({bool isGreen = false}) {
    // Mock for line chart
    return CustomPaint(
      size: const Size(120, 60),
      painter: LineChartPainter(
          color: isGreen ? Colors.greenAccent : AppTheme.primaryColor),
    );
  }

  Widget _buildSearchAndFilters(bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 54,
          decoration: BoxDecoration(
            color: const Color(0xFF121212),
            borderRadius: BorderRadius.circular(27),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Buscar Prestadores...',
              hintStyle: const TextStyle(color: Colors.white38),
              prefixIcon: const Icon(Icons.search, color: Colors.white38),
              suffixIcon: Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ActionChip(
                  label: Text(_selectedCategory,
                      style:
                          const TextStyle(color: Colors.black, fontSize: 12)),
                  backgroundColor: AppTheme.primaryColor,
                  onPressed: _showCategoryPicker,
                ),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 15),
            ),
            onChanged: (val) => setState(() => _searchQuery = val),
          ),
        ),
        if (!isDesktop) const SizedBox(height: 16),
        if (!isDesktop)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _categories
                  .map((cat) => Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(cat),
                          selected: _selectedCategory == cat,
                          onSelected: (val) =>
                              setState(() => _selectedCategory = cat),
                          backgroundColor: Colors.white10,
                          selectedColor: AppTheme.primaryColor,
                          labelStyle: TextStyle(
                              color: _selectedCategory == cat
                                  ? Colors.black
                                  : Colors.white70),
                        ),
                      ))
                  .toList(),
            ),
          ),
      ],
    );
  }

  void _showCategoryPicker() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Selecionar Categoria'),
        backgroundColor: const Color(0xFF2C2C2C),
        children: _categories
            .map((cat) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(context, cat),
                  child: Text(cat, style: const TextStyle(color: Colors.white)),
                ))
            .toList(),
      ),
    );
    if (result != null) {
      setState(() => _selectedCategory = result);
    }
  }

  Widget _buildProvidersContent(bool isDesktop) {
    return FutureBuilder<Either<Failure, List<ServiceEntity>>>(
      future: sl<GetAllServices>()(NoParams()),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData) {
          return const Center(
              child: Text('Erro ao carregar serviços.',
                  style: TextStyle(color: Colors.white38)));
        }

        return snapshot.data!.fold(
          (failure) => Center(
            child: Text('Erro: ${failure.message}',
                style: const TextStyle(color: Colors.redAccent)),
          ),
          (services) {
            // Apply local filtering
            var filteredServices = services;

            // Filter by category
            if (_selectedCategory != 'Todos') {
              final cat = _selectedCategory.toLowerCase();
              ServiceCategory targetCat = ServiceCategory.artist;
              if (['cantor', 'músico', 'banda', 'dj'].contains(cat)) {
                targetCat = ServiceCategory.artist;
              } else if (cat == 'fotógrafo' || cat == 'videógrafo') {
                targetCat = ServiceCategory.media;
              } else if (cat == 'segurança') {
                targetCat = ServiceCategory.security;
              } else if (cat == 'buffet/catering') {
                targetCat = ServiceCategory.catering;
              } else if (cat == 'equipe técnica') {
                targetCat = ServiceCategory.infrastructure;
              }
              filteredServices = filteredServices
                  .where((s) => s.category == targetCat)
                  .toList();
            }

            // Filter by search query
            if (_searchQuery.isNotEmpty) {
              final query = _searchQuery.toLowerCase();
              filteredServices = filteredServices
                  .where((s) => s.name.toLowerCase().contains(query))
                  .toList();
            }

            if (filteredServices.isEmpty) {
              return const Center(
                  child: Text('Nenhum prestador encontrado.',
                      style: TextStyle(color: Colors.white38)));
            }

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isDesktop ? 2 : 1,
                childAspectRatio: isDesktop ? 2.2 : 1.2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: filteredServices.length,
              itemBuilder: (context, index) {
                return _buildProviderCard(filteredServices[index]);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildProviderCard(ServiceEntity service) {
    return BlocBuilder<BudgetCartBloc, BudgetCartState>(
      builder: (context, state) {
        final isInCart = state.items.any((i) => i.id == service.id);

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF151515),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getCategoryIcon(service.category),
                  color: AppTheme.primaryColor,
                  size: 40,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            service.name,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.verified,
                            color: Colors.blueAccent, size: 16),
                      ],
                    ),
                    Text(
                      service.category.toString().split('.').last.toUpperCase(),
                      style:
                          const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    const Row(
                      children: [
                        Icon(Icons.star, color: Color(0xFFE5B80B), size: 14),
                        SizedBox(width: 4),
                        Text(
                          '4.8',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'R\$ ${service.basePrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 32,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProfilePage(
                                userId: service.providerId,
                                email:
                                    '', // Email not strictly required for viewing
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE5B80B),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          textStyle: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 10),
                        ),
                        child: const Text('VER PERFIL'),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  isInCart ? Icons.check_circle : Icons.add_circle,
                  color: isInCart ? Colors.green : AppTheme.primaryColor,
                ),
                onPressed: () {
                  if (isInCart) {
                    context
                        .read<BudgetCartBloc>()
                        .add(RemoveServiceFromCart(service.id));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${service.name} removido!')),
                    );
                  } else {
                    context
                        .read<BudgetCartBloc>()
                        .add(AddServiceToCart(service));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${service.name} adicionado!')),
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _getCategoryIcon(ServiceCategory category) {
    switch (category) {
      case ServiceCategory.artist:
        return Icons.mic;
      case ServiceCategory.infrastructure:
        return Icons.settings_input_component;
      case ServiceCategory.catering:
        return Icons.restaurant;
      case ServiceCategory.security:
        return Icons.security;
      case ServiceCategory.media:
        return Icons.camera_alt;
    }
  }

  Widget _buildCartPanel() {
    return Container(
      width: 320,
      height: double.infinity,
      color: const Color(0xFF0F0F0F),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Selecionados | (carrinho)',
            style: TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white10),
          Expanded(
            child: BlocBuilder<BudgetCartBloc, BudgetCartState>(
              builder: (context, state) {
                if (state.items.isEmpty) {
                  return const Center(
                      child: Text('Carrinho vazio',
                          style: TextStyle(color: Colors.white24)));
                }
                return ListView.builder(
                  itemCount: state.items.length,
                  itemBuilder: (context, index) {
                    final item = state.items[index];
                    return _cartItem(item);
                  },
                );
              },
            ),
          ),
          const Divider(color: Colors.white10),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: BlocBuilder<BudgetCartBloc, BudgetCartState>(
              builder: (context, state) {
                double total = 0;
                for (var item in state.items) {
                  total += item.basePrice;
                }
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Geral:',
                        style: TextStyle(color: Colors.white54, fontSize: 16)),
                    Text('R\$ ${total.toStringAsFixed(2)}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold)),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _cartItem(ServiceEntity item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(item.name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold)),
              ),
              IconButton(
                icon: const Icon(Icons.remove_circle_outline,
                    color: Colors.redAccent, size: 18),
                onPressed: () {
                  context
                      .read<BudgetCartBloc>()
                      .add(RemoveServiceFromCart(item.id));
                },
              ),
            ],
          ),
          Text(
              'R\$ ${item.basePrice.toStringAsFixed(2)} - ${item.category.toString().split('.').last}',
              style: const TextStyle(color: Color(0xFFE5B80B), fontSize: 12)),
          const SizedBox(height: 4),
          const Divider(color: Colors.white10),
        ],
      ),
    );
  }

  Widget _buildMobileDrawer() {
    return Drawer(
      backgroundColor: const Color(0xFF121212),
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Colors.black),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.dashboard_customize,
                      color: AppTheme.primaryColor, size: 40),
                  const SizedBox(height: 12),
                  const Text('MENU',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          _sidebarItem(Icons.home_outlined, 'Voltar para MixArt', onTap: () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                  builder: (context) => const ArtistNetworkPage()),
              (route) => false,
            );
          }),
          const Divider(color: Colors.white10),
          _sidebarItem(Icons.dashboard_outlined, 'Visão Geral',
              isSelected: true),
          _sidebarItem(Icons.analytics_outlined, 'Dashboard'),
          _sidebarItem(Icons.chat_bubble_outline, 'Chat com Perfis',
              badge: '1'),
          _sidebarItem(Icons.settings_outlined, 'Configurações', badge: '1'),
        ],
      ),
    );
  }

  Widget _buildMobileBottomNav() {
    return BottomNavigationBar(
      backgroundColor: const Color(0xFF121212),
      selectedItemColor: AppTheme.primaryColor,
      unselectedItemColor: Colors.white38,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Geral'),
        BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'Dash'),
        BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Config'),
      ],
    );
  }

  void _showMobileCart() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => _buildCartPanel(),
    );
  }
}

class LineChartPainter extends CustomPainter {
  final Color color;
  LineChartPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(0, size.height * 0.8)
      ..quadraticBezierTo(size.width * 0.2, size.height * 0.7, size.width * 0.4,
          size.height * 0.5)
      ..quadraticBezierTo(size.width * 0.6, size.height * 0.3, size.width * 0.8,
          size.height * 0.4)
      ..lineTo(size.width, size.height * 0.1);

    canvas.drawPath(path, paint);

    // Draw area under path
    final areaPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withOpacity(0.3), color.withOpacity(0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final areaPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(areaPath, areaPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CartBadge extends StatelessWidget {
  const _CartBadge();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BudgetCartBloc, BudgetCartState>(
      builder: (context, state) {
        final count = state.items.length;
        if (count == 0) {
          return const Icon(Icons.shopping_cart_outlined,
              color: Colors.white70);
        }
        return Stack(
          alignment: Alignment.center,
          children: [
            const Icon(Icons.shopping_cart_outlined,
                color: AppTheme.primaryColor),
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                    color: Colors.red, shape: BoxShape.circle),
                child: Text('$count',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        );
      },
    );
  }
}
