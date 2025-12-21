import 'package:flutter/material.dart';

/// Common search bar widget with gradient border
/// Self-contained widget that includes border gradient internally
class CommonSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final bool enabled;

  const CommonSearchBar({
    super.key,
    required this.controller,
    this.hintText = 'Search...',
    this.onTap,
    this.onChanged,
    this.enabled = true,
  });

  @override
  State<CommonSearchBar> createState() => _CommonSearchBarState();
}

class _CommonSearchBarState extends State<CommonSearchBar> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    const double borderWidth = 0.5;
    final borderRadius = BorderRadius.circular(20);

    return Container(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          stops: [0.0, 0.75],
          colors: [
            Color.fromRGBO(255, 255, 255, 0.6), // White at 60% opacity
            Color.fromRGBO(255, 255, 255, 0.1), // White at 10% opacity
          ],
        ),
      ),
      child: Container(
        margin: EdgeInsets.all(borderWidth),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: borderRadius,
        ),
        child: TextField(
          controller: widget.controller,
          enabled: widget.enabled,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
            prefixIcon: const Icon(
              Icons.search,
              color: Colors.grey,
              size: 20,
            ),
            suffixIcon: widget.controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(
                      Icons.clear,
                      color: Colors.grey,
                      size: 18,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      widget.controller.clear();
                    },
                  )
                : null,
            filled: true,
            fillColor: const Color(0xFF1E1E1E),
            border: OutlineInputBorder(
              borderRadius: borderRadius,
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            isDense: true,
          ),
          onTap: widget.onTap,
          onChanged: (value) {
            setState(() {});
            widget.onChanged?.call(value);
          },
        ),
      ),
    );
  }
}

