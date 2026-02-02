import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/services/backend_storage_service.dart';

class FileUploadWidget extends StatefulWidget {
  final String label;
  final Function(String url) onFileUploaded;
  final List<String> allowedExtensions;
  final bool isImage;

  const FileUploadWidget({
    super.key,
    required this.label,
    required this.onFileUploaded,
    this.allowedExtensions = const ['jpg', 'png', 'pdf', 'jpeg'],
    this.isImage = false,
  });

  @override
  State<FileUploadWidget> createState() => _FileUploadWidgetState();
}

class _FileUploadWidgetState extends State<FileUploadWidget> {
  bool _isUploading = false;
  String? _fileName;
  String? _uploadedUrl;
  final BackendStorageService _storageService =
      GetIt.instance<BackendStorageService>();

  Future<void> _pickAndUpload() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: widget.allowedExtensions,
      );

      if (result != null) {
        setState(() {
          _isUploading = true;
          _fileName = result.files.single.name;
        });

        // BackendStorageService expects raw bytes for most reliable cross-platform upload (or File for mobile)
        // Since FilePicker gives us bytes on web and path on mobile, let's handle both.

        String url;
        if (kIsWeb) {
          if (result.files.single.bytes != null) {
            url = await _storageService.uploadBytes(result.files.single.bytes!,
                result.files.single.name, 'service_docs');
          } else {
            throw Exception('File bytes not available');
          }
        } else {
          // Mobile/Desktop
          if (result.files.single.path != null) {
            url = await _storageService.uploadFile(
                File(result.files.single.path!), 'service_docs');
          } else {
            throw Exception('File path not available');
          }
        }

        // Prepend base URL for display/access
        final fullUrl = "http://localhost/media/$url";

        setState(() {
          _isUploading = false;
          _uploadedUrl = fullUrl;
        });

        widget.onFileUploaded(fullUrl);
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
        _fileName = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro no upload: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _isUploading ? null : _pickAndUpload,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _uploadedUrl != null ? Colors.green : Colors.white24,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _uploadedUrl != null
                      ? Icons.check_circle
                      : Icons.cloud_upload,
                  color: _uploadedUrl != null
                      ? Colors.green
                      : const Color(0xFFFFC107),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _fileName ?? 'Selecionar Arquivo',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (_isUploading)
                        const Padding(
                          padding: EdgeInsets.only(top: 8.0),
                          child: LinearProgressIndicator(
                            minHeight: 2,
                            backgroundColor: Colors.white10,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFFFFC107)),
                          ),
                        ),
                      if (_uploadedUrl != null)
                        const Padding(
                          padding: EdgeInsets.only(top: 4.0),
                          child: Text(
                            'Upload concluído',
                            style: TextStyle(color: Colors.green, fontSize: 10),
                          ),
                        )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
