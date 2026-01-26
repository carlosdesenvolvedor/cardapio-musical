import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_system/core/constants/legal_constants.dart';
import 'package:music_system/features/auth/domain/entities/user_profile.dart';
import 'package:music_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PrivacySettingsPage extends StatelessWidget {
  final UserProfile profile;

  const PrivacySettingsPage({super.key, required this.profile});

  void _showLegalText(BuildContext context, String title, String content) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1e293b),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFFE5B80B),
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                content,
                style: const TextStyle(
                    color: Colors.white, fontSize: 16, height: 1.5),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _logAuditAction(String action, String reason) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await FirebaseFirestore.instance.collection('audit_logs').add({
      'userId': uid,
      'action': action,
      'timestamp': FieldValue.serverTimestamp(),
      'reason': reason,
      'method': 'human',
      'metadata': {
        'platform': 'flutter_app',
        'version': '1.0.0-feb-foundations',
      }
    });
  }

  void _confirmDeletion(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1e293b),
        title:
            const Text('Excluir Conta?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Esta ação é irreversível. Todos os seus dados, posts e perfil serão removidos permanentemente conforme a LGPD.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              // Log the audit first
              await _logAuditAction('account_deletion_request',
                  'User requested deletion via app settings');

              if (context.mounted) {
                // Here we would call a delete use case. For now, we'll trigger a logout and notify.
                // In a real scenario, a cloud function would handle the cleanup.
                context.read<AuthBloc>().add(SignOutRequested());
                Navigator.of(context).popUntil((route) => route.isFirst);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text(
                        'Solicitação de exclusão enviada. Seus dados serão removidos em até 48h.')));
              }
            },
            child: const Text('EXCLUIR TUDO',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Privacidade e Dados'),
        backgroundColor: Colors.black,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Conformidade LGPD',
            style: TextStyle(
              color: Color(0xFFE5B80B),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Gerencie seus dados e entenda como protegemos sua privacidade.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 30),
          _buildOption(
            icon: Icons.description,
            title: 'Termos de Uso',
            subtitle: 'Leia os termos atualizados para Fevereiro/2026',
            onTap: () => _showLegalText(
                context, 'Termos de Uso', LegalConstants.termsOfUse),
          ),
          _buildOption(
            icon: Icons.security,
            title: 'Política de Privacidade',
            subtitle: 'Como tratamos seus dados biométricos e de idade',
            onTap: () => _showLegalText(context, 'Política de Privacidade',
                LegalConstants.privacyPolicy),
          ),
          _buildOption(
            icon: Icons.download,
            title: 'Exportar Meus Dados',
            subtitle: 'Receba uma cópia de todos os seus dados por e-mail',
            onTap: () {
              _logAuditAction(
                  'data_export_request', 'User requested data export');
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text(
                      'Solicitação enviada! Você receberá os dados em seu e-mail cadastrado.')));
            },
          ),
          const Divider(color: Colors.white10, height: 40),
          const Text(
            'Zona Crítica',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          _buildOption(
            icon: Icons.delete_forever,
            title: 'Excluir Minha Conta',
            subtitle:
                'Remover permanentemente todos os seus dados do Music System',
            color: Colors.redAccent,
            onTap: () => _confirmDeletion(context),
          ),
        ],
      ),
    );
  }

  Widget _buildOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color color = Colors.white,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(title,
          style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle,
          style: const TextStyle(color: Colors.grey, fontSize: 12)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
    );
  }
}
