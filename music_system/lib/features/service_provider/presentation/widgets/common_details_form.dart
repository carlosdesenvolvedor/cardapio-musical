import 'package:flutter/material.dart';

class CommonDetailsForm extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController descriptionController;
  final TextEditingController basePriceController;
  final TextEditingController priceDescController;
  final TextEditingController locationController;
  final GlobalKey<FormState> formKey;

  const CommonDetailsForm({
    super.key,
    required this.nameController,
    required this.descriptionController,
    required this.basePriceController,
    required this.priceDescController,
    required this.locationController,
    required this.formKey,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informações do Serviço',
            style: TextStyle(
              color: Color(0xFFFFC107),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: nameController,
            label: 'Nome do Serviço',
            icon: Icons.label,
            validator: (v) => v?.isEmpty == true ? 'Campo obrigatório' : null,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: descriptionController,
            label: 'Descrição Detalhada',
            icon: Icons.description,
            maxLines: 4,
            validator: (v) => v?.isEmpty == true ? 'Campo obrigatório' : null,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: locationController,
            label: 'Endereço / Região',
            icon: Icons.location_on,
            validator: (v) => v?.isEmpty == true ? 'Campo obrigatório' : null,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildTextField(
                  controller: basePriceController,
                  label: 'Preço Base (R\$)',
                  icon: Icons.attach_money,
                  inputType: TextInputType.number,
                  validator: (v) => v?.isEmpty == true ? 'Obrigatório' : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 3,
                child: _buildTextField(
                  controller: priceDescController,
                  label: 'Unidade (ex: por hora, dia)',
                  icon: Icons.access_time,
                  validator: (v) => v?.isEmpty == true ? 'Obrigatório' : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType inputType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      keyboardType: inputType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white60),
        prefixIcon: Icon(icon, color: const Color(0xFFFFC107)),
        filled: true,
        fillColor: Colors.white10,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFFC107), width: 2),
        ),
      ),
      validator: validator,
    );
  }
}
