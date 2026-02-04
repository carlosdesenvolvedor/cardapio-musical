import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';

class CommonDetailsForm extends StatefulWidget {
  final TextEditingController nameController;
  final TextEditingController descriptionController;
  final TextEditingController basePriceController;
  final TextEditingController priceDescController;
  final TextEditingController locationController;
  final GlobalKey<FormState> formKey;
  final Function(Uint8List? bytes, String? name) onImageSelected;
  final String? initialImageUrl;

  const CommonDetailsForm({
    super.key,
    required this.nameController,
    required this.descriptionController,
    required this.basePriceController,
    required this.priceDescController,
    required this.locationController,
    required this.formKey,
    required this.onImageSelected,
    this.initialImageUrl,
  });

  @override
  State<CommonDetailsForm> createState() => _CommonDetailsFormState();
}

class _CommonDetailsFormState extends State<CommonDetailsForm> {
  final ImagePicker _picker = ImagePicker();
  Uint8List? _selectedImageBytes;
  bool _isPicking = false;

  Future<void> _pickImage() async {
    setState(() => _isPicking = true);
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 1000,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
        });
        widget.onImageSelected(bytes, image.name);
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
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
          Center(
            child: GestureDetector(
              onTap: _isPicking ? null : _pickImage,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: const Color(0xFFFFC107).withOpacity(0.3)),
                  image: _selectedImageBytes != null
                      ? DecorationImage(
                          image: MemoryImage(_selectedImageBytes!),
                          fit: BoxFit.cover,
                        )
                      : (widget.initialImageUrl != null
                          ? DecorationImage(
                              image: NetworkImage(widget.initialImageUrl!),
                              fit: BoxFit.cover,
                            )
                          : null),
                ),
                child: _selectedImageBytes == null &&
                        widget.initialImageUrl == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_a_photo,
                            color: const Color(0xFFFFC107).withOpacity(0.5),
                            size: 40,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Adicionar Foto',
                            style:
                                TextStyle(color: Colors.white38, fontSize: 10),
                          ),
                        ],
                      )
                    : Container(
                        decoration: BoxDecoration(
                          color: Colors.black38,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.edit,
                            color: Colors.white, size: 24),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          _buildTextField(
            controller: widget.nameController,
            label: 'Nome do Serviço',
            icon: Icons.label,
            validator: (v) => v?.isEmpty == true ? 'Campo obrigatório' : null,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: widget.descriptionController,
            label: 'Descrição Detalhada',
            icon: Icons.description,
            maxLines: 4,
            validator: (v) => v?.isEmpty == true ? 'Campo obrigatório' : null,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: widget.locationController,
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
                  controller: widget.basePriceController,
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
                  controller: widget.priceDescController,
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
