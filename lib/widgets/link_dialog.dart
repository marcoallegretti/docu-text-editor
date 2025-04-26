import 'package:flutter/material.dart';

class LinkDialog extends StatefulWidget {
  final String? initialUrl;
  final void Function(String url) onSubmit;

  const LinkDialog({Key? key, this.initialUrl, required this.onSubmit}) : super(key: key);

  @override
  State<LinkDialog> createState() => _LinkDialogState();
}

class _LinkDialogState extends State<LinkDialog> {
  late TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialUrl ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    String url = _controller.text.trim();
    if (url.isEmpty) {
      setState(() {
        _errorText = 'Please enter a valid URL.';
      });
      return;
    }
    // Accept if it looks like a domain or has a valid scheme
    final domainPattern = RegExp(r'^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}([/\w\-\.?%&=]*)?');
    if (!url.startsWith(RegExp(r'https?://')) && domainPattern.hasMatch(url)) {
      url = 'https://$url';
    }
    final uri = Uri.tryParse(url);
    if (uri == null || (!uri.isAbsolute && !domainPattern.hasMatch(url))) {
      setState(() {
        _errorText = 'Please enter a valid URL.';
      });
      return;
    }
    widget.onSubmit(url);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Insert Link'),
      content: TextField(
        controller: _controller,
        decoration: InputDecoration(
          labelText: 'URL',
          errorText: _errorText,
        ),
        autofocus: true,
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        if ((widget.initialUrl ?? '').isNotEmpty)
          TextButton(
            onPressed: () {
              widget.onSubmit('');
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Remove Link'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Apply'),
        ),
      ],
    );
  }
}
