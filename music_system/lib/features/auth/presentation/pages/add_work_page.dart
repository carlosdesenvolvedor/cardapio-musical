import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_system/features/auth/domain/entities/work.dart';
import 'package:music_system/features/auth/presentation/bloc/works/works_bloc.dart';
import 'package:music_system/features/auth/presentation/bloc/works/works_event.dart';
import 'package:music_system/features/auth/presentation/bloc/works/works_state.dart';
import 'package:uuid/uuid.dart';

class AddWorkPage extends StatefulWidget {
  final String userId;
  final Work? workToEdit;

  const AddWorkPage({super.key, required this.userId, this.workToEdit});

  @override
  State<AddWorkPage> createState() => _AddWorkPageState();
}

class _AddWorkPageState extends State<AddWorkPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;

  File? _selectedFile;
  String? _selectedFileName;
  String? _selectedFileType; // 'pdf' or 'mp3'

  List<WorkLink> _links = [];
  final _linkTitleController = TextEditingController();
  final _linkUrlController = TextEditingController();
  bool _isAddingLink = false;

  @override
  void initState() {
    super.initState();
    _titleController =
        TextEditingController(text: widget.workToEdit?.title ?? '');
    _descriptionController =
        TextEditingController(text: widget.workToEdit?.description ?? '');

    if (widget.workToEdit != null) {
      _links = List.from(widget.workToEdit!.links);
      _selectedFileType = widget.workToEdit!.fileType;
      // Note: We can't easily repopulate _selectedFile from a URL for editing without downloading it,
      // so we rely on checks: if _selectedFile is null but widget.workToEdit.fileUrl exists, we keep the old one.
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _linkTitleController.dispose();
    _linkUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'mp3'],
    );

    if (result != null) {
      final file = File(result.files.single.path!);
      final sizeInBytes = await file.length();
      final sizeInMb = sizeInBytes / (1024 * 1024);

      if (sizeInMb > 10) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Arquivo muito grande. Máximo permitido: 10MB'),
                backgroundColor: Colors.red),
          );
        }
        return;
      }

      setState(() {
        _selectedFile = file;
        _selectedFileName = result.files.single.name;
        _selectedFileType = result.files.single.extension;
      });
    }
  }

  void _addLink() {
    if (_linkTitleController.text.isNotEmpty &&
        _linkUrlController.text.isNotEmpty) {
      setState(() {
        _links.add(WorkLink(
          title: _linkTitleController.text,
          url: _linkUrlController.text,
        ));
        _linkTitleController.clear();
        _linkUrlController.clear();
        _isAddingLink = false;
      });
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      // Validation: Must have a file OR description OR links. Not strict, but good practice.

      final workId = widget.workToEdit?.id ?? const Uuid().v4();
      final newWork = Work(
        id: workId,
        userId: widget.userId,
        title: _titleController.text,
        description: _descriptionController.text,
        fileUrl: widget.workToEdit?.fileUrl, // Keep old URL if editing
        fileType: _selectedFileType,
        links: _links,
        createdAt: widget.workToEdit?.createdAt ?? DateTime.now(),
      );

      if (widget.workToEdit != null) {
        // Edit mode
        // Note: UpdateWork event doesn't support file update in our simple implementation yet,
        // to fully support file replacement on edit, we would need to adjust the logic.
        // For now, let's assume AddWork handles both or explicitly handle Update.
        // However, our Bloc has UpdateWork which calls repository.updateWork (no file arg).
        // If the user selected a NEW file during edit, we should technically call something that supports upload.
        // Let's keep it simple: If new file selected, use AddWork logic (which overwrites if ID matches? No, ID generation in repo is ignored for Add).
        // Actually, Repository.addWork generates a NEW ID if we use .add().
        // Let's refactor Repository later to support set() or handle this better.
        // For MVP: Edit only updates text/links. New file requires delete + add or better backend support.
        // Or... we allow "AddWork" to handle updates if we pass specific ID?
        // In Repo: `add(workModel.toDocument())` always creates new doc.

        context.read<WorksBloc>().add(UpdateWork(newWork));
      } else {
        // Create mode
        context.read<WorksBloc>().add(AddWork(newWork, _selectedFile));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<WorksBloc, WorksState>(
      listener: (context, state) {
        if (state is WorksOperationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(state.message), backgroundColor: Colors.green),
          );
          Navigator.pop(context);
        } else if (state is WorksError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: Text(widget.workToEdit != null
              ? 'Editar Trabalho'
              : 'Adicionar Trabalho'),
          backgroundColor: Colors.black,
        ),
        body: BlocBuilder<WorksBloc, WorksState>(
          builder: (context, state) {
            if (state is WorksLoading) {
              return const Center(
                  child: CircularProgressIndicator(color: Color(0xFFE5B80B)));
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTextField(
                      controller: _titleController,
                      label: 'Título',
                      icon: Icons.title,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Informe o título' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _descriptionController,
                      label: 'Descrição',
                      icon: Icons.description,
                      maxLines: 5,
                    ),
                    const SizedBox(height: 16),

                    // File Picker Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Arquivo (MP3 ou PDF)',
                              style: TextStyle(color: Colors.grey)),
                          const SizedBox(height: 8),
                          if (_selectedFile != null)
                            Row(
                              children: [
                                Icon(
                                    _selectedFileType == 'pdf'
                                        ? Icons.picture_as_pdf
                                        : Icons.audio_file,
                                    color: const Color(0xFFE5B80B)),
                                const SizedBox(width: 8),
                                Expanded(
                                    child: Text(
                                        _selectedFileName ??
                                            'Arquivo selecionado',
                                        style: const TextStyle(
                                            color: Colors.white))),
                                IconButton(
                                  icon: const Icon(Icons.close,
                                      color: Colors.redAccent),
                                  onPressed: () => setState(() {
                                    _selectedFile = null;
                                    _selectedFileName = null;
                                    _selectedFileType = null;
                                  }),
                                )
                              ],
                            )
                          else if (widget.workToEdit?.fileUrl != null &&
                              widget.workToEdit!.fileUrl!.isNotEmpty)
                            Row(
                              children: [
                                const Icon(Icons.check_circle,
                                    color: Colors.green),
                                const SizedBox(width: 8),
                                const Expanded(
                                    child: Text(
                                        'Arquivo já enviado (Re-envio desabilitado na edição)',
                                        style:
                                            TextStyle(color: Colors.white70))),
                              ],
                            )
                          else
                            ElevatedButton.icon(
                              onPressed: _pickFile,
                              icon: const Icon(Icons.upload_file),
                              label: const Text('Selecionar Arquivo'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white10,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          const SizedBox(height: 4),
                          const Text('Max: 10MB',
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 10)),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),
                    const Divider(color: Colors.white24),
                    const SizedBox(height: 8),

                    // Links Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Links Extras',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: Icon(_isAddingLink ? Icons.close : Icons.add,
                              color: const Color(0xFFE5B80B)),
                          onPressed: () =>
                              setState(() => _isAddingLink = !_isAddingLink),
                        ),
                      ],
                    ),

                    if (_isAddingLink)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            TextField(
                              controller: _linkTitleController,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                labelText: 'Título do Link (ex: Instagram)',
                                labelStyle: TextStyle(color: Colors.grey),
                              ),
                            ),
                            TextField(
                              controller: _linkUrlController,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                labelText: 'URL',
                                labelStyle: TextStyle(color: Colors.grey),
                              ),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: _addLink,
                              child: const Text('Adicionar Link'),
                            )
                          ],
                        ),
                      ),

                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _links.length,
                      itemBuilder: (context, index) {
                        final link = _links[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading:
                              const Icon(Icons.link, color: Colors.white54),
                          title: Text(link.title,
                              style: const TextStyle(color: Colors.white)),
                          subtitle: Text(link.url,
                              style: const TextStyle(
                                  color: Colors.white38, fontSize: 12),
                              overflow: TextOverflow.ellipsis),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete,
                                color: Colors.redAccent, size: 20),
                            onPressed: () =>
                                setState(() => _links.removeAt(index)),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE5B80B),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        widget.workToEdit != null
                            ? 'SALVAR ALTERAÇÕES'
                            : 'CRIAR TRABALHO',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: const Color(0xFFE5B80B)),
        filled: true,
        fillColor: Colors.white10,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5B80B)),
        ),
      ),
    );
  }
}
