import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/colors.dart';
import '../data/models/outing_session_model.dart';

class ReceiptItem {
  String name;
  double price;
  final Set<String> sharedWithUids;

  ReceiptItem({
    required this.name,
    required this.price,
    Set<String>? sharedWithUids,
  }) : sharedWithUids = sharedWithUids ?? {};
}

class ReceiptSplitterScreen extends StatefulWidget {
  final List<OutingParticipant> participants;

  const ReceiptSplitterScreen({super.key, required this.participants});

  @override
  State<ReceiptSplitterScreen> createState() => _ReceiptSplitterScreenState();
}

class _ReceiptSplitterScreenState extends State<ReceiptSplitterScreen> {
  static const _ocrChannel = MethodChannel('com.laween.app/ocr');

  final List<ReceiptItem> _items = [];
  bool _isProcessing = false;
  double _taxPercent = 0.0;
  double _tipPercent = 0.0;

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile == null) return;

    setState(() {
      _isProcessing = true;
      _items.clear();
    });

    try {
      // Call Apple Vision OCR via native method channel
      final List<dynamic> lines = await _ocrChannel.invokeMethod('recognizeText', {
        'imagePath': pickedFile.path,
      });

      final List<ReceiptItem> extracted = [];
      for (var line in lines) {
        final text = (line as String).trim();
        final priceRegex = RegExp(r'(\d+[\.,]\d{1,2})\b');
        final match = priceRegex.allMatches(text).lastOrNull;

        if (match != null) {
          final priceStr = match.group(1)!.replaceAll(',', '.');
          final price = double.tryParse(priceStr);

          if (price != null && price > 0.0) {
            var name = text.substring(0, match.start).replaceAll(RegExp(r'[\.\-]+'), '').trim();
            if (name.isEmpty) name = "Item #${extracted.length + 1}";
            extracted.add(ReceiptItem(name: name, price: price));
          }
        }
      }

      if (mounted) {
        setState(() {
          _items.addAll(extracted);
          _isProcessing = false;
        });
      }
    } catch (e) {
      debugPrint("OCR Processing Error: $e");
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _addNewItem() {
    showDialog(
      context: context,
      builder: (context) {
        final nameController = TextEditingController();
        final priceController = TextEditingController();
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text("Add Custom Item", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: "Item Name",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: "Price",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                final price = double.tryParse(priceController.text);
                if (name.isNotEmpty && price != null) {
                  setState(() {
                    _items.add(ReceiptItem(name: name, price: price));
                  });
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.teal),
              child: const Text("Add"),
            ),
          ],
        );
      },
    );
  }

  void _showAssignBottomSheet(ReceiptItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Assign: ${item.name}",
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkSlate,
                    ),
                  ),
                  Text(
                    "Select who ate or shared this item",
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: widget.participants.length,
                      itemBuilder: (context, index) {
                        final p = widget.participants[index];
                        final isSelected = item.sharedWithUids.contains(p.uid);
                        return CheckboxListTile(
                          value: isSelected,
                          title: Text(
                            p.name,
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                          ),
                          activeColor: AppColors.teal,
                          onChanged: (val) {
                            setModalState(() {
                              if (val == true) {
                                item.sharedWithUids.add(p.uid);
                              } else {
                                item.sharedWithUids.remove(p.uid);
                              }
                            });
                            setState(() {});
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Map<String, double> _calculateSplits() {
    final Map<String, double> totals = {};
    for (var p in widget.participants) {
      totals[p.uid] = 0.0;
    }

    for (var item in _items) {
      if (item.sharedWithUids.isEmpty) continue;
      final splitPrice = item.price / item.sharedWithUids.length;
      for (var uid in item.sharedWithUids) {
        totals[uid] = (totals[uid] ?? 0.0) + splitPrice;
      }
    }

    // Apply tax and tip
    for (var p in widget.participants) {
      final subtotal = totals[p.uid] ?? 0.0;
      final tax = subtotal * (_taxPercent / 100.0);
      final tip = subtotal * (_tipPercent / 100.0);
      totals[p.uid] = subtotal + tax + tip;
    }

    return totals;
  }

  @override
  Widget build(BuildContext context) {
    final totals = _calculateSplits();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          "Receipt Splitter",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.darkSlate,
        elevation: 0,
      ),
      body: CustomScrollView(
        slivers: [
          // Top Option: Camera scan or custom input
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _pickImage(ImageSource.camera),
                            icon: const Icon(Icons.camera_alt_rounded, color: Colors.white),
                            label: const Text("Scan Receipt"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.teal,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _addNewItem,
                            icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.teal),
                            label: const Text("Add Custom"),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.teal,
                              side: const BorderSide(color: AppColors.teal),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_isProcessing) ...[
                      const SizedBox(height: 16),
                      const LinearProgressIndicator(color: AppColors.teal),
                      const SizedBox(height: 8),
                      Text("Scanning with Apple Vision AI...", style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey)),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // Receipt items list
          if (_items.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = _items[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "${item.price.toStringAsFixed(2)} JOD",
                                  style: GoogleFonts.outfit(color: AppColors.teal, fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () => _showAssignBottomSheet(item),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: item.sharedWithUids.isEmpty ? Colors.grey.shade200 : AppColors.teal.withValues(alpha: 0.1),
                              elevation: 0,
                              foregroundColor: item.sharedWithUids.isEmpty ? Colors.grey.shade700 : AppColors.teal,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text(
                              item.sharedWithUids.isEmpty
                                  ? "Assign"
                                  : "${item.sharedWithUids.length} Selected",
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 300.ms, delay: (index * 40).ms);
                  },
                  childCount: _items.length,
                ),
              ),
            ),

          // Tax and tip controls
          if (_items.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Extra Adjustments",
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                labelText: "Tax %",
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onChanged: (val) {
                                setState(() => _taxPercent = double.tryParse(val) ?? 0.0);
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                labelText: "Tip %",
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onChanged: (val) {
                                setState(() => _tipPercent = double.tryParse(val) ?? 0.0);
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Calculated totals
          if (_items.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final p = widget.participants[index];
                    final amt = totals[p.uid] ?? 0.0;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: amt > 0 ? AppColors.teal.withValues(alpha: 0.05) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: amt > 0 ? AppColors.teal.withValues(alpha: 0.3) : Colors.grey.shade100,
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            p.name,
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.darkSlate,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            "${amt.toStringAsFixed(2)} JOD",
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: amt > 0 ? AppColors.teal : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  childCount: widget.participants.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
