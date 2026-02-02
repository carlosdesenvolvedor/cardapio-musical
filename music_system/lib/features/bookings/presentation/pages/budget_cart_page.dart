import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/budget_cart_bloc.dart';
import '../../../service_provider/domain/entities/service_entity.dart';

class BudgetCartPage extends StatelessWidget {
  const BudgetCartPage({super.key});

  @override
  Widget build(BuildContext context) {
    final currencyFormatter =
        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Scaffold(
      backgroundColor: const Color(0xFF101010),
      appBar: AppBar(
        backgroundColor: const Color(0xFF101010),
        title: const Text(
          'MEU ORÇAMENTO',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep, color: Colors.white54),
            onPressed: () {
              context.read<BudgetCartBloc>().add(ClearBudgetCart());
            },
          ),
        ],
      ),
      body: BlocBuilder<BudgetCartBloc, BudgetCartState>(
        builder: (context, state) {
          if (state.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 80,
                    color: Colors.white.withOpacity(0.1),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Seu carrinho está vazio',
                    style: TextStyle(color: Colors.white54, fontSize: 18),
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFC107),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                    child: const Text('VOLTAR ÀS COMPRAS'),
                  ),
                ],
              ),
            );
          }

          double total = 0;
          for (var item in state.items) {
            total += item.basePrice;
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.items.length,
                  itemBuilder: (context, index) {
                    final service = state.items[index];
                    return _buildCartItem(context, service, currencyFormatter);
                  },
                ),
              ),
              _buildSummary(context, total, currencyFormatter),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCartItem(BuildContext context, ServiceEntity service,
      NumberFormat currencyFormatter) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFFFFC107).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getIconForCategory(service.category),
              color: const Color(0xFFFFC107),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _getCategoryName(service.category),
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                currencyFormatter.format(service.basePrice),
                style: const TextStyle(
                  color: Color(0xFFFFC107),
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.remove_circle_outline,
                    color: Colors.redAccent, size: 20),
                onPressed: () {
                  context
                      .read<BudgetCartBloc>()
                      .add(RemoveServiceFromCart(service.id));
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(
      BuildContext context, double total, NumberFormat currencyFormatter) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'VALOR TOTAL ESTIMADO',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                Text(
                  currencyFormatter.format(total),
                  style: const TextStyle(
                    color: Color(0xFFFFC107),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Implement final budget request logic
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Solicitando orçamento para todos...'),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFC107),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: const Text(
                  'FECHAR ORÇAMENTO',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getCategoryName(ServiceCategory category) {
    switch (category) {
      case ServiceCategory.artist:
        return 'ARTÍSTICO';
      case ServiceCategory.infrastructure:
        return 'TÉCNICA & ESTRUTURA';
      case ServiceCategory.catering:
        return 'ALIMENTAÇÃO';
      case ServiceCategory.security:
        return 'SEGURANÇA';
      case ServiceCategory.media:
        return 'MÍDIA';
    }
  }

  IconData _getIconForCategory(ServiceCategory category) {
    switch (category) {
      case ServiceCategory.artist:
        return Icons.mic;
      case ServiceCategory.infrastructure:
        return Icons.speaker_group;
      case ServiceCategory.catering:
        return Icons.restaurant;
      case ServiceCategory.security:
        return Icons.verified_user;
      case ServiceCategory.media:
        return Icons.camera_alt;
    }
  }
}
