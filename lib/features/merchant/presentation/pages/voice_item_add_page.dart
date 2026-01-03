import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../domain/entities/item_entity.dart';
import '../../domain/models/parsed_item.dart';
import '../../domain/services/voice_recognition_service.dart';
import '../../domain/services/voice_item_parser.dart';
import '../../domain/services/item_duplicate_checker.dart';
import '../providers/item_provider.dart';
import '../widgets/voice_language_selector.dart';
import '../widgets/voice_item_confirmation_card.dart';
import '../widgets/duplicate_item_dialog.dart';

/// Voice-based bulk item addition page
/// Allows merchants to add multiple items quickly by speaking
class VoiceItemAddPage extends StatefulWidget {
  final String merchantId;

  const VoiceItemAddPage({super.key, required this.merchantId});

  @override
  State<VoiceItemAddPage> createState() => _VoiceItemAddPageState();
}

class _VoiceItemAddPageState extends State<VoiceItemAddPage> {
  late VoiceRecognitionService _voiceService;
  late VoiceItemParser _parser;
  late ItemDuplicateChecker _duplicateChecker;

  ParsedItem? _currentParsedItem;
  final List<ItemEntity> _addedItems = [];
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _voiceService = VoiceRecognitionService();
    _parser = VoiceItemParser();
    _duplicateChecker = ItemDuplicateChecker();

    // Initialize voice service
    _initializeVoice();
  }

  Future<void> _initializeVoice() async {
    await _voiceService.initialize();
    if (!mounted) return;

    if (_voiceService.errorMessage != null) {
      _showError(_voiceService.errorMessage!);
    }
  }

  @override
  void dispose() {
    _voiceService.stopListening();
    _voiceService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _voiceService,
      child: Scaffold(
        backgroundColor: AppColors.lightBackground,
        appBar: _buildAppBar(),
        body: SafeArea(
          child: Column(
            children: [
              _buildLanguageSelector(),
              Expanded(child: _buildMainContent()),
              _buildBottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Voice Add Items'),
      flexibleSpace: Container(
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.help_outline),
          onPressed: _showInstructions,
          tooltip: 'How to use',
        ),
      ],
    );
  }

  Widget _buildLanguageSelector() {
    return Consumer<VoiceRecognitionService>(
      builder: (context, service, child) {
        return VoiceLanguageSelector(
          selectedLanguage: service.selectedLanguage,
          onLanguageChanged: (language) {
            service.setLanguage(language);
          },
        );
      },
    );
  }

  Widget _buildMainContent() {
    return Consumer<VoiceRecognitionService>(
      builder: (context, service, child) {
        if (!service.hasPermission) {
          return _buildPermissionRequired();
        }

        if (!service.isInitialized) {
          return _buildInitializing();
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.paddingMD),
          child: Column(
            children: [
              _buildVoiceInputCard(service),
              const SizedBox(height: AppDimensions.spacingLG),
              if (_currentParsedItem != null) _buildConfirmationCard(),
              const SizedBox(height: AppDimensions.spacingLG),
              _buildAddedItemsList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVoiceInputCard(VoiceRecognitionService service) {
    return Card(
      elevation: AppDimensions.elevationMD,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingXL),
        child: Column(
          children: [
            // Microphone button
            _buildMicrophoneButton(service),

            const SizedBox(height: AppDimensions.spacingLG),

            // Status text
            _buildStatusText(service),

            const SizedBox(height: AppDimensions.spacingMD),

            // Live transcription
            if (service.currentTranscript.isNotEmpty)
              _buildTranscriptionText(service.currentTranscript),

            // Error message
            if (service.errorMessage != null)
              _buildErrorMessage(service.errorMessage!),
          ],
        ),
      ),
    );
  }

  Widget _buildMicrophoneButton(VoiceRecognitionService service) {
    final isListening = service.isListening;

    return GestureDetector(
      onTap: _isProcessing ? null : () => _toggleListening(service),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: isListening
              ? const LinearGradient(colors: [Colors.red, Colors.redAccent])
              : AppColors.primaryGradient,
          boxShadow: [
            BoxShadow(
              color: isListening
                  ? Colors.red.withOpacity(0.4)
                  : AppColors.primaryBlue.withOpacity(0.4),
              blurRadius: isListening ? 20 : 12,
              spreadRadius: isListening ? 8 : 4,
            ),
          ],
        ),
        child: Icon(
          isListening ? Icons.mic : Icons.mic_none,
          size: AppDimensions.icon3XL,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildStatusText(VoiceRecognitionService service) {
    String statusText;
    Color statusColor;

    if (_isProcessing) {
      statusText = 'Processing...';
      statusColor = AppColors.warning;
    } else if (service.isListening) {
      if (_addedItems.isNotEmpty && _currentParsedItem == null) {
        statusText = '🎤 Ready for next item - Speak now!';
        statusColor = AppColors.success;
      } else {
        statusText = 'Listening... Speak now';
        statusColor = Colors.red;
      }
    } else {
      statusText = 'Tap microphone to start';
      statusColor = AppColors.lightTextSecondary;
    }

    return Text(
      statusText,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: statusColor,
        fontWeight: FontWeight.w600,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildTranscriptionText(String transcript) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMD),
      decoration: BoxDecoration(
        color: AppColors.infoLight.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        border: Border.all(color: AppColors.infoLight.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'You said:',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingXS),
          Text(
            transcript,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage(String error) {
    return Container(
      margin: const EdgeInsets.only(top: AppDimensions.spacingMD),
      padding: const EdgeInsets.all(AppDimensions.paddingMD),
      decoration: BoxDecoration(
        color: AppColors.errorLight.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error),
          const SizedBox(width: AppDimensions.spacingSM),
          Expanded(
            child: Text(
              error,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationCard() {
    return VoiceItemConfirmationCard(
      parsedItem: _currentParsedItem!,
      onConfirm: _confirmAndAddItem,
      onSkip: _skipCurrentItem,
      onEdit: _editCurrentItem,
      isProcessing: _isProcessing,
    );
  }

  Widget _buildAddedItemsList() {
    if (_addedItems.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingLG),
          child: Column(
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: AppDimensions.icon2XL,
                color: AppColors.lightTextTertiary,
              ),
              const SizedBox(height: AppDimensions.spacingSM),
              Text(
                'No items added yet',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: AppDimensions.spacingXS),
              Text(
                'Start speaking to add items',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.lightTextTertiary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingMD),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: AppColors.success,
                  size: AppDimensions.iconMD,
                ),
                const SizedBox(width: AppDimensions.spacingSM),
                Text(
                  'Items Added (${_addedItems.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _addedItems.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = _addedItems[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.success.withOpacity(0.1),
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  item.name,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                trailing: Text(
                  '₹${item.price.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMD),
      decoration: BoxDecoration(
        color: AppColors.lightSurface,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowMedium,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Item count
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_addedItems.length} items',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'added successfully',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Done button
            Flexible(
              child: ElevatedButton.icon(
                onPressed: _addedItems.isEmpty ? null : _finishAndClose,
                icon: const Icon(Icons.check),
                label: const Text('Done'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingXL,
                    vertical: AppDimensions.paddingMD,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionRequired() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.mic_off,
              size: AppDimensions.icon3XL,
              color: AppColors.lightTextTertiary,
            ),
            const SizedBox(height: AppDimensions.spacingLG),
            Text(
              'Microphone Permission Required',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.spacingSM),
            Text(
              'To use voice input, please grant microphone permission in your device settings.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.lightTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.spacingXL),
            ElevatedButton.icon(
              onPressed: _initializeVoice,
              icon: const Icon(Icons.settings),
              label: const Text('Request Permission'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingXL,
                  vertical: AppDimensions.paddingMD,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitializing() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: AppDimensions.spacingLG),
          Text('Initializing voice recognition...'),
        ],
      ),
    );
  }

  // === Action Methods ===

  Future<void> _toggleListening(VoiceRecognitionService service) async {
    if (service.isListening) {
      await service.stopListening();
    } else {
      await service.startListening(
        onResult: _handleVoiceResult,
        onPartialResult: (partial) {
          // Live transcription - just display
          setState(() {});
        },
      );
    }
  }

  void _handleVoiceResult(String result) {
    if (result.trim().isEmpty) return;

    setState(() => _isProcessing = true);

    // Parse the voice input
    final parsed = _parser.parseVoiceInput(result);

    setState(() {
      _isProcessing = false;
      _currentParsedItem = parsed;
    });

    if (parsed == null) {
      _showError(
        'Did not understand. Please speak clearly: Item name and price',
      );
    }
  }

  Future<void> _confirmAndAddItem() async {
    if (_currentParsedItem == null) return;

    setState(() => _isProcessing = true);

    final itemProvider = context.read<ItemProvider>();

    // Check for duplicates
    final existingItem = _duplicateChecker.findSimilarItem(
      _currentParsedItem!.name,
      itemProvider.items,
    );

    if (existingItem != null && mounted) {
      // Show duplicate dialog
      final result = await showDialog<String>(
        context: context,
        builder: (context) => DuplicateItemDialog(
          newItemName: _currentParsedItem!.name,
          newItemPrice: _currentParsedItem!.price,
          existingItem: existingItem,
        ),
      );

      if (result == 'update') {
        // Update existing item
        await _updateExistingItem(existingItem);
      } else if (result == 'add_new') {
        // Add as new item
        await _addNewItem();
      } else {
        // User cancelled
        setState(() {
          _isProcessing = false;
          _currentParsedItem = null;
        });
        return;
      }
    } else {
      // No duplicate, add directly
      await _addNewItem();
    }

    setState(() {
      _isProcessing = false;
      _currentParsedItem = null;
    });

    // Auto-restart listening for next item
    await _restartListening();
  }

  Future<void> _addNewItem() async {
    if (_currentParsedItem == null) return;

    final item = ItemEntity(
      id: '',
      merchantId: widget.merchantId,
      name: _currentParsedItem!.name,
      hsnCode: null,
      price: _currentParsedItem!.price,
      taxRate: 18.0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final success = await context.read<ItemProvider>().createItem(item);

    if (success) {
      setState(() {
        _addedItems.add(item);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ Added: ${item.name} - ₹${item.price}'),
            duration: const Duration(seconds: 1),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  Future<void> _updateExistingItem(ItemEntity existingItem) async {
    if (_currentParsedItem == null) return;

    final updatedItem = existingItem.copyWith(
      price: _currentParsedItem!.price,
      updatedAt: DateTime.now(),
    );

    final success = await context.read<ItemProvider>().updateItem(updatedItem);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✓ Updated: ${updatedItem.name} - ₹${updatedItem.price}',
          ),
          duration: const Duration(seconds: 1),
          backgroundColor: AppColors.info,
        ),
      );
    }
  }

  void _skipCurrentItem() {
    setState(() {
      _currentParsedItem = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Item skipped'),
        duration: Duration(seconds: 1),
      ),
    );

    // Auto-restart listening for next item
    _restartListening();
  }

  void _editCurrentItem() {
    // TODO: Implement manual edit dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Edit feature coming soon. For now, skip and add manually.',
        ),
      ),
    );
  }

  Future<void> _restartListening() async {
    // Small delay to ensure previous processing is complete
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    // Use stored _voiceService instead of context.read to avoid Provider errors
    if (!_voiceService.isListening && _voiceService.isInitialized) {
      await _voiceService.startListening(
        onResult: _handleVoiceResult,
        onPartialResult: (partial) {
          setState(() {});
        },
      );
    }
  }

  void _finishAndClose() {
    Navigator.of(context).pop(_addedItems.length);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: AppDimensions.spacingSM),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showInstructions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('How to Use Voice Input'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInstructionStep(
                '1',
                'Select Language',
                'Choose your preferred language (Telugu, Hindi, English, etc.)',
              ),
              const SizedBox(height: AppDimensions.spacingMD),
              _buildInstructionStep(
                '2',
                'Tap Microphone',
                'Tap the microphone button to start listening',
              ),
              const SizedBox(height: AppDimensions.spacingMD),
              _buildInstructionStep(
                '3',
                'Speak Clearly',
                'Say item name and price. Example:\n• "Rice sixty rupees"\n• "రైస్ అరవై రూపాయలు"\n• "Parle-G five"',
              ),
              const SizedBox(height: AppDimensions.spacingMD),
              _buildInstructionStep(
                '4',
                'Confirm or Skip',
                'Review the detected item and tap ✓ to add or × to skip. Microphone will automatically restart!',
              ),
              const SizedBox(height: AppDimensions.spacingMD),
              _buildInstructionStep(
                '5',
                'Keep Speaking',
                'After confirming, speak the next item immediately. Add multiple items continuously!',
              ),
              const SizedBox(height: AppDimensions.spacingMD),
              _buildInstructionStep(
                '6',
                'Finish',
                'When done adding all items, tap the "Done" button',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got It'),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionStep(
    String number,
    String title,
    String description,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: AppColors.primaryBlue,
          child: Text(
            number,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: AppDimensions.spacingSM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  color: AppColors.lightTextSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
