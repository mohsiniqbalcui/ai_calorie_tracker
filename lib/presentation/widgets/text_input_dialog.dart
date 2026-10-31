import 'package:flutter/material.dart';

class TextInputDialog extends StatefulWidget {
  final String title;
  final String hintText;
  final String? initialValue;
  final Function(String) onSubmitted;

  const TextInputDialog({
    Key? key,
    required this.title,
    required this.hintText,
    this.initialValue,
    required this.onSubmitted,
  }) : super(key: key);

  @override
  State<TextInputDialog> createState() => _TextInputDialogState();
}

class _TextInputDialogState extends State<TextInputDialog> {
  late TextEditingController _controller;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    if (_controller.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a food description')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await widget.onSubmitted(_controller.text.trim());
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: widget.hintText,
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.restaurant),
            ),
            maxLines: 3,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _handleSubmit(),
            enabled: !_isLoading,
          ),
          if (_isLoading) ...[
            SizedBox(height: 16),
            CircularProgressIndicator(),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleSubmit,
          child: _isLoading
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text('Add Food'),
        ),
      ],
    );
  }
}
