import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/di/dependency_injection.dart';
import '../../domain/repositories/i_merchant_repository.dart';
import '../../domain/services/voice_recognition_service.dart';
import '../../domain/services/voice_cart_item_parser.dart';
import '../../domain/models/parsed_item.dart';
import '../providers/session_provider.dart';
import '../pages/number_pad_input_page.dart';
import 'barcode_scanner_page.dart';
import 'voice_language_selector.dart';

/// Fast Input Options Dialog
/// Provides multiple ways for users to quickly add items to cart
/// Perfect for users who don't know how to type or want express checkout
class FastInputOptionsDialog extends StatelessWidget {
  final String merchantId;

  const FastInputOptionsDialog({super.key, required this.merchantId});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Fast Input',
                  style: AppTypography.h4.copyWith(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Choose your preferred method to add items',
              style: AppTypography.body2.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),

            // Option 1: Voice Input (Recommended)
            _buildOptionCard(
              context: context,
              icon: Icons.mic,
              iconColor: AppColors.primaryBlue,
              title: 'Voice Input',
              subtitle: 'Say item name and quantity',
              badge: 'RECOMMENDED',
              onTap: () {
                Navigator.pop(context);
                _handleVoiceInput(context);
              },
            ),
            const SizedBox(height: 12),

            // Option 2: Barcode Scanner
            _buildOptionCard(
              context: context,
              icon: Icons.qr_code_scanner,
              iconColor: AppColors.success,
              title: 'Scan Barcode',
              subtitle: 'Scan product barcode for instant add',
              onTap: () async {
                Navigator.pop(context);
                await _handleBarcodeScanning(context);
              },
            ),
            const SizedBox(height: 12),

            // Option 3: Number Pad (for item codes)
            _buildOptionCard(
              context: context,
              icon: Icons.dialpad,
              iconColor: AppColors.warning,
              title: 'Number Pad',
              subtitle: 'Enter item code + quantity (fast)',
              badge: 'FASTEST',
              onTap: () {
                Navigator.pop(context);
                _showNumberPadInput(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    String? badge,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(width: 16),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: AppTypography.body1.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            badge,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.primaryBlue,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTypography.body2.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            // Arrow
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  /// Smart barcode scanning with auto-add (Option B: Smart Defaults)
  /// - Scans barcode
  /// - Searches by barcode in repository
  /// - If found: Auto-adds to cart with toast notification
  /// - If not found: Auto-creates temporary item with barcode
  Future<void> _handleBarcodeScanning(BuildContext context) async {
    try {
      // Open barcode scanner
      final barcode = await Navigator.push<String>(
        context,
        MaterialPageRoute(builder: (context) => const BarcodeScannerPage()),
      );

      if (barcode == null || barcode.isEmpty) return;

      // Show loading indicator
      if (context.mounted) {
        _showLoadingSnackBar(context, 'Searching for $barcode...');
      }

      // Get repository and search for item
      final repository = getIt<IMerchantRepository>();
      final item = await repository.searchItemByBarcode(merchantId, barcode);

      if (context.mounted) {
        // Remove loading indicator
        ScaffoldMessenger.of(context).clearSnackBars();

        if (item != null) {
          // ✅ Item found by barcode - Auto-add to cart
          final sessionProvider = context.read<SessionProvider>();
          sessionProvider.addToCart(item);

          // Show success toast with undo option
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(child: Text('✅ Added "${item.name}" to cart')),
                ],
              ),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 3),
              action: SnackBarAction(
                label: 'UNDO',
                textColor: Colors.white,
                onPressed: () {
                  sessionProvider.updateCartItemQuantity(item.name, 0);
                },
              ),
            ),
          );
        } else {
          // ⚠️ Item not found - Create temporary item
          _showBarcodeNotFoundDialog(context, barcode);
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showLoadingSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        duration: const Duration(seconds: 10), // Will be cleared manually
        backgroundColor: AppColors.primaryBlue,
      ),
    );
  }

  void _showBarcodeNotFoundDialog(BuildContext context, String barcode) {
    final nameController = TextEditingController();
    final priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.warning),
            SizedBox(width: 8),
            Text('Barcode Not Found'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Barcode: $barcode',
              style: AppTypography.body2.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(height: 16),
            const Text('Add this as a new item?'),
            const SizedBox(height: 12),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Item Name',
                border: OutlineInputBorder(),
                hintText: 'Enter item name',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceController,
              decoration: const InputDecoration(
                labelText: 'Price',
                border: OutlineInputBorder(),
                prefixText: '₹',
                hintText: '0.00',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              final priceText = priceController.text.trim();

              if (name.isEmpty || priceText.isEmpty) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text('Please fill all fields'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }

              final price = double.tryParse(priceText);
              if (price == null || price <= 0) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid price'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }

              Navigator.pop(dialogContext);
              _createAndAddTempItem(context, name, price, barcode);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
            child: const Text('Add to Cart'),
          ),
        ],
      ),
    );
  }

  void _createAndAddTempItem(
    BuildContext context,
    String name,
    double price,
    String barcode,
  ) {
    // Create temporary item that will be auto-synced to library later
    final sessionProvider = context.read<SessionProvider>();

    // For now, we create a session item directly
    // TODO: In production, you might want to create ItemEntity with barcode
    // and save it to the library immediately

    sessionProvider.addTemporaryItemToCart(
      name: name,
      price: price,
      barcode: barcode,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.add_shopping_cart, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text('✅ Added "$name" to cart (temporary)')),
          ],
        ),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Handle voice input for adding items to cart
  /// Uses speech recognition to capture item name and quantity
  /// Searches in database first, if not found prompts for price
  Future<void> _handleVoiceInput(BuildContext context) async {
    final voiceService = VoiceRecognitionService();
    final parser = VoiceCartItemParser();

    // Initialize voice service
    final initialized = await voiceService.initialize();
    if (!initialized) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              voiceService.errorMessage ??
                  'Failed to initialize voice recognition',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    if (!context.mounted) return;

    // Show voice input dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _VoiceInputDialog(
        voiceService: voiceService,
        parser: parser,
        merchantId: merchantId,
      ),
    );
  }

  void _showNumberPadInput(BuildContext context) {
    Navigator.pop(context); // Close dialog
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NumberPadInputPage(merchantId: merchantId),
      ),
    );
  }
}

/// Voice Input Dialog for adding items to cart
/// Listens to voice, searches database, and adds items
class _VoiceInputDialog extends StatefulWidget {
  final VoiceRecognitionService voiceService;
  final VoiceCartItemParser parser;
  final String merchantId;

  const _VoiceInputDialog({
    required this.voiceService,
    required this.parser,
    required this.merchantId,
  });

  @override
  State<_VoiceInputDialog> createState() => _VoiceInputDialogState();
}

class _VoiceInputDialogState extends State<_VoiceInputDialog> {
  String _transcript = '';
  ParsedItem? _parsedItem;
  bool _isProcessing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Start listening automatically when dialog opens
    _startListening();
  }

  @override
  void dispose() {
    widget.voiceService.stopListening();
    widget.voiceService.dispose();
    super.dispose();
  }

  Future<void> _startListening() async {
    setState(() {
      _transcript = '';
      _parsedItem = null;
      _errorMessage = null;
    });

    // Enable continuous mode - microphone stays active until user closes dialog
    await widget.voiceService.startListening(
      onResult: _handleVoiceResult,
      onPartialResult: (partial) {
        setState(() {
          _transcript = partial;
        });
      },
      continuousMode: true, // Keep listening after each phrase
    );
  }

  Future<void> _handleVoiceResult(String transcript) async {
    setState(() {
      _transcript = transcript;
      _isProcessing = true;
      _errorMessage = null;
    });

    // Validate transcript length
    if (transcript.trim().length < 3) {
      setState(() {
        _errorMessage = 'Too short. Please speak item name clearly.';
        _isProcessing = false;
      });
      // No need to restart - continuous mode keeps listening
      return;
    }

    // Parse the voice input
    final parsed = await widget.parser.parse(transcript);

    if (!mounted) return;

    if (parsed == null || parsed.name.isEmpty) {
      setState(() {
        _errorMessage = 'Not clear. Say: "2 kg rice" or "Milk 1 liter"';
        _isProcessing = false;
      });
      // No need to restart - continuous mode keeps listening
      return;
    }

    // ✅ SUCCESS! Show parsed item (price optional - will search library)
    setState(() {
      _parsedItem = parsed;
      _isProcessing = false;
    });

    // Don't auto-process - let user confirm by tapping "Add to Cart" button
  }

  Future<void> _processVoiceInput() async {
    if (_parsedItem == null) return;

    setState(() {
      _isProcessing = true;
    });

    // Search for item in database
    await _searchAndAddItem(_parsedItem!);
  }

  Future<void> _searchAndAddItem(ParsedItem parsed) async {
    final repository = getIt<IMerchantRepository>();

    try {
      // 🔍 STEP 1: Search library for existing item (by name)
      final items = await repository.getItemsStream(widget.merchantId).first;
      final matchedItem = items.firstWhere(
        (item) => item.name.toLowerCase().contains(parsed.name.toLowerCase()),
        orElse: () => throw Exception('Item not found'),
      );

      if (!mounted) return;

      // ✅ Item found in library - use existing price, just apply quantity
      final sessionProvider = context.read<SessionProvider>();
      final quantity = parsed.quantity?.toInt() ?? 1;

      for (int i = 0; i < quantity; i++) {
        sessionProvider.addToCart(matchedItem);
      }

      // Don't close dialog - let user add more items
      setState(() {
        _transcript = '';
        _parsedItem = null;
        _errorMessage = null;
        _isProcessing = false;
      });

      // Show success message but keep dialog open
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: ExcludeSemantics(
            // 🔥 Prevent device TTS from reading snackbar during voice input
            child: Text(
              '✅ Added $quantity x ${matchedItem.name} at ₹${matchedItem.price} each',
            ),
          ),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      // ❌ Item NOT in library - need price to create temporary item
      if (!mounted) return;

      // If user already spoke price, use it; otherwise ask for price
      if (parsed.price != null && parsed.price! > 0) {
        // User already provided price - add temporary item directly
        _addTemporaryItem(parsed);
      } else {
        // No price provided - show price input dialog
        _showPriceInputDialog(parsed);
      }
    }
  }

  void _addTemporaryItem(ParsedItem parsed) {
    final sessionProvider = context.read<SessionProvider>();
    final quantity = parsed.quantity?.toInt() ?? 1;
    final price = parsed.price ?? 0.0;

    for (int i = 0; i < quantity; i++) {
      sessionProvider.addTemporaryItemToCart(
        name: parsed.name,
        price: price,
        unit: parsed.unitType,
      );
    }

    // Reset state for next item
    setState(() {
      _transcript = '';
      _parsedItem = null;
      _errorMessage = null;
      _isProcessing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: ExcludeSemantics(
          // 🔥 Prevent device TTS from reading snackbar during voice input
          child: Text('✅ Added $quantity x ${parsed.name} at ₹$price each'),
        ),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showPriceInputDialog(ParsedItem parsed) {
    final priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (priceDialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: AppColors.info),
            SizedBox(width: 8),
            Text('Item Not Found'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Item: ${parsed.name}',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            if (parsed.quantity != null) ...[
              const SizedBox(height: 4),
              Text(
                'Quantity: ${parsed.quantity}',
                style: TextStyle(color: Colors.grey[700]),
              ),
            ],
            const SizedBox(height: 16),
            const Text('This item is not in your inventory.'),
            const Text('Please enter the price:'),
            const SizedBox(height: 12),
            TextField(
              controller: priceController,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Price per item',
                border: OutlineInputBorder(),
                prefixText: '₹',
                hintText: '0.00',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(priceDialogContext); // Close price dialog only
              // Keep voice dialog open for next item
              setState(() {
                _transcript = '';
                _parsedItem = null;
                _errorMessage = null;
                _isProcessing = false;
              });
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final priceText = priceController.text.trim();
              final price = double.tryParse(priceText);

              if (price == null || price <= 0) {
                ScaffoldMessenger.of(priceDialogContext).showSnackBar(
                  SnackBar(
                    content: ExcludeSemantics(
                      // 🔥 Prevent device TTS from reading snackbar during voice input
                      child: const Text('Please enter a valid price'),
                    ),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }

              Navigator.pop(priceDialogContext); // Close price dialog
              // Keep voice dialog open for next item

              // Add temporary item to cart
              final sessionProvider = context.read<SessionProvider>();
              final quantity = parsed.quantity?.toInt() ?? 1;

              for (int i = 0; i < quantity; i++) {
                sessionProvider.addTemporaryItemToCart(
                  name: parsed.name,
                  price: price,
                  unit: parsed.unitType,
                );
              }

              // Reset state for next item
              setState(() {
                _transcript = '';
                _parsedItem = null;
                _errorMessage = null;
                _isProcessing = false;
              });

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: ExcludeSemantics(
                    // 🔥 Prevent device TTS from reading snackbar during voice input
                    child: Text(
                      '✅ Added $quantity x ${parsed.name} at ₹$price each',
                    ),
                  ),
                  backgroundColor: AppColors.success,
                  duration: const Duration(seconds: 3),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
            child: const Text('Add to Cart'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.mic, color: AppColors.primaryBlue),
          const SizedBox(width: 8),
          const Text('Voice Input'),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
      content: ExcludeSemantics(
        // 🔥 Exclude from TalkBack/VoiceOver to prevent feedback loop
        // Device TTS reading screen text interferes with microphone
        child: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Language selector
              VoiceLanguageSelector(
                selectedLanguage: widget.voiceService.selectedLanguage,
                onLanguageChanged: (language) async {
                  await widget.voiceService.setLanguage(language);
                  // Restart listening with new language
                  if (widget.voiceService.isListening) {
                    await widget.voiceService.stopListening();
                    await _startListening();
                  }
                },
              ),
              const SizedBox(height: 16),

              // Listening indicator
              if (widget.voiceService.isListening)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.mic, color: Colors.red, size: 48),
                )
              else
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.mic_off,
                    color: Colors.grey,
                    size: 48,
                  ),
                ),
              const SizedBox(height: 16),

              // Status text
              Text(
                widget.voiceService.isListening
                    ? '🎤 Listening continuously... Speak items one by one'
                    : _isProcessing
                    ? '⏳ Processing your item...'
                    : 'Initializing microphone...',
                style: TextStyle(
                  color: widget.voiceService.isListening
                      ? Colors.red
                      : Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Transcript
              if (_transcript.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.info.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'You said:',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _transcript,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Parsed info
              if (_parsedItem != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.success.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: AppColors.success,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Understood:',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_parsedItem!.name}${_parsedItem!.quantity != null ? ' x ${_parsedItem!.quantity}' : ''}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Error message
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.error.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: AppColors.error,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Instructions
              Text(
                widget.voiceService.isListening
                    ? '💡 Say each item: "Rice 2 kg 50" → Add → "Milk 60" → Add'
                    : _errorMessage != null
                    ? '🔄 Speak again - Still listening'
                    : '💡 Microphone will stay active until you close',
                style: TextStyle(
                  fontSize: 12,
                  color: widget.voiceService.isListening
                      ? Colors.red
                      : Colors.grey[600],
                  fontWeight: widget.voiceService.isListening
                      ? FontWeight.w600
                      : FontWeight.normal,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ), // ExcludeSemantics
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        if (!widget.voiceService.isListening &&
            !_isProcessing &&
            _parsedItem == null &&
            _errorMessage != null)
          ElevatedButton.icon(
            onPressed: _startListening,
            icon: const Icon(Icons.refresh),
            label: const Text('Restart Mic'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: Colors.white,
            ),
          ),
        if (_parsedItem != null && !_isProcessing)
          ElevatedButton.icon(
            onPressed: _processVoiceInput,
            icon: const Icon(Icons.add_shopping_cart),
            label: const Text('Add to Cart'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
          ),
      ],
    );
  }
}
