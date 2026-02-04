import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../config/theme/app_theme.dart';
import '../../domain/entities/event_entity.dart';

class EventDashboardPage extends StatelessWidget {
  final EventEntity event;

  const EventDashboardPage({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final currencyFormatter =
        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(event.title.toUpperCase(),
            style: const TextStyle(
                fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        actions: [
          IconButton(
              icon: const Icon(Icons.edit, color: Colors.white54),
              onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCreditCard(currencyFormatter),
            const SizedBox(height: 30),
            _buildBudgetStats(currencyFormatter),
            const SizedBox(height: 30),
            const Text('PRESTADORES CONTRATADOS',
                style: TextStyle(
                    color: Colors.white38,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 1.5)),
            const SizedBox(height: 15),
            _buildProvidersList(),
          ],
        ),
      ),
    );
  }

  Widget _buildCreditCard(NumberFormat formatter) {
    return Container(
      width: double.infinity,
      height: 200,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2C2C2C), Color(0xFF1A1A1A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withAlpha(128),
              blurRadius: 20,
              offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('MIXART CONTRACTOR',
                  style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                      letterSpacing: 2)),
              Icon(Icons.contactless, color: Colors.white.withOpacity(0.2)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('SALDO DISPONÍVEL',
                  style: TextStyle(color: Colors.white38, fontSize: 10)),
              Text(formatter.format(event.budgetLimit - event.currentExpenses),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(event.status.toUpperCase(),
                  style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
              const Text('VALENTE DESDE 2026',
                  style: TextStyle(color: Colors.white24, fontSize: 8)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetStats(NumberFormat formatter) {
    double progress =
        (event.currentExpenses / event.budgetLimit).clamp(0.0, 1.0);
    if (event.budgetLimit == 0) progress = 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(12)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _statItem('Investido', formatter.format(event.currentExpenses),
                  Colors.redAccent),
              _statItem('Estimado', formatter.format(event.budgetLimit),
                  AppTheme.primaryColor),
              _statItem(
                  'Restante',
                  formatter.format(event.budgetLimit - event.currentExpenses),
                  Colors.greenAccent),
            ],
          ),
          const SizedBox(height: 25),
          Stack(
            children: [
              Container(
                height: 12,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryColor,
                        progress > 0.8
                            ? Colors.redAccent
                            : AppTheme.primaryColor.withOpacity(0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${(progress * 100).toInt()}% do budget utilizado',
                  style: const TextStyle(color: Colors.white38, fontSize: 10)),
              Text(
                progress > 0.9 ? 'LIMITE PRÓXIMO' : 'DENTRO DO PLANO',
                style: TextStyle(
                  color: progress > 0.9 ? Colors.redAccent : Colors.greenAccent,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white24, fontSize: 10)),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }

  Widget _buildProvidersList() {
    if (event.hiredProviderIds.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            children: [
              Icon(Icons.search,
                  size: 40, color: Colors.white.withOpacity(0.1)),
              const SizedBox(height: 10),
              const Text('Nenhum prestador contratado',
                  style: TextStyle(color: Colors.white24, fontSize: 12)),
            ],
          ),
        ),
      );
    }
    // Implementação da lista de prestadores...
    return const SizedBox.shrink();
  }
}
