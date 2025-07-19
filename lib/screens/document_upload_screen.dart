
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class DocumentUploadScreen extends StatefulWidget {
  final Function(File) onDocumentUploaded;

  const DocumentUploadScreen({super.key, required this.onDocumentUploaded});

  @override
  State<DocumentUploadScreen> createState() => _DocumentUploadScreenState();
}

class _DocumentUploadScreenState extends State<DocumentUploadScreen> {
  bool _isUploading = false;
  String? _fileName;
  String? _error;

  Future<void> _pickAndUploadFile() async {
    setState(() {
      _isUploading = true;
      _error = null;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'txt', 'md'],
      );

      if (result != null) {
        final file = File(result.files.single.path!);
        widget.onDocumentUploaded(file);
        setState(() {
          _fileName = result.files.single.name;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to pick or read file: $e';
      });
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Medical Document'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (_isUploading)
                const CircularProgressIndicator()
              else
                ElevatedButton.icon(
                  onPressed: _pickAndUploadFile,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Select and Upload Document'),
                ),
              const SizedBox(height: 20),
              if (_fileName != null)
                Text(
                  'Successfully uploaded: $_fileName',
                  style: const TextStyle(color: Colors.green),
                ),
              if (_error != null)
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
