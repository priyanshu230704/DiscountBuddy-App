import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/theme_provider.dart';

/// Add/Edit Deal Page for Merchants
class AddDealPage extends StatelessWidget {
  const AddDealPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeoTasteColors.background,
      appBar: AppBar(
        title: Text(
          'Create Deal',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: NeoTasteColors.white,
        elevation: 0,
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Deal creation form coming soon...',
            style: TextStyle(color: NeoTasteColors.textSecondary),
          ),
        ),
      ),
    );
  }
}
