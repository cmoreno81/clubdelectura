import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Campo de URL con acciones visibles para no depender de la pulsación larga.
class UrlTextField extends StatefulWidget {
  const UrlTextField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.hintText,
    this.prefixIcon = Icons.link_rounded,
    this.textInputAction = TextInputAction.next,
    this.errorText,
    this.onChanged,
  });

  final TextEditingController controller;
  final String labelText;
  final String hintText;
  final IconData prefixIcon;
  final TextInputAction textInputAction;
  final String? errorText;
  final ValueChanged<String>? onChanged;

  @override
  State<UrlTextField> createState() => _UrlTextFieldState();
}

class _UrlTextFieldState extends State<UrlTextField> {
  static final RegExp _urlPattern = RegExp(r'https?://[^\s]+');

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_refresh);
  }

  @override
  void didUpdateWidget(covariant UrlTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_refresh);
      widget.controller.addListener(_refresh);
    }
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _paste() async {
    final clipboard = await Clipboard.getData(Clipboard.kTextPlain);
    if (!mounted) return;

    final contents = clipboard?.text?.trim() ?? '';
    if (contents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay ningún enlace para pegar')),
      );
      return;
    }

    final match = _urlPattern.firstMatch(contents);
    var value = match?.group(0) ?? contents;
    value = value.replaceFirst(RegExp(r'[\]\[),.;]+$'), '');

    widget.controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
    widget.onChanged?.call(value);
  }

  void _clear() {
    widget.controller.clear();
    widget.onChanged?.call('');
  }

  @override
  Widget build(BuildContext context) {
    final hasText = widget.controller.text.trim().isNotEmpty;

    return TextField(
      controller: widget.controller,
      keyboardType: TextInputType.url,
      textInputAction: widget.textInputAction,
      autocorrect: false,
      enableSuggestions: false,
      smartDashesType: SmartDashesType.disabled,
      smartQuotesType: SmartQuotesType.disabled,
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        labelText: widget.labelText,
        hintText: widget.hintText,
        prefixIcon: Icon(widget.prefixIcon),
        errorText: widget.errorText,
        suffixIconConstraints: const BoxConstraints(minWidth: 48),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Pegar enlace',
              onPressed: _paste,
              icon: const Icon(Icons.content_paste_rounded),
            ),
            if (hasText)
              IconButton(
                tooltip: 'Borrar enlace',
                onPressed: _clear,
                icon: const Icon(Icons.close_rounded),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    widget.controller.removeListener(_refresh);
    super.dispose();
  }
}
