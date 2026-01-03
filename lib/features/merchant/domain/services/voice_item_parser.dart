import '../models/parsed_item.dart';

/// Parses voice input to extract item name and price
///
/// 🔑 KEY INSIGHT: Google Speech API automatically converts spoken numbers to digits!
/// - Telugu: "అరవై" → "60"
/// - Hindi: "साठ" → "60"
/// - English: "sixty" → "60"
///
/// So we don't need manual number mappings! Just extract the digits!
class VoiceItemParser {
  /// Common price indicator words to remove (across all Indian languages)
  static const List<String> _priceIndicators = [
    // Telugu
    'రూపాయలు', 'రూపాయల', 'రూపాయ', 'rupaayalu', 'rupaayala',
    // Hindi
    'रुपये', 'रुपया', 'रुपए', 'rupaye', 'rupaya',
    // Tamil
    'ரூபாய்', 'ரூபா', 'roopai',
    // Kannada
    'ರೂಪಾಯಿ', 'ರೂಪಾ',
    // Malayalam
    'രൂപ', 'രൂപയ്',
    // Marathi
    'रुपये', 'रुपया',
    // Gujarati
    'રૂપિયા', 'રૂપિયો',
    // Punjabi
    'ਰੁਪਏ', 'ਰੁਪਿਆ',
    // Bengali
    'টাকা', 'রুপি',
    // Odia
    'ଟଙ୍କା', 'ରୁପି',
    // English
    'rupees', 'rupee', 'rs', 'inr', '₹', 'only', 'per',
  ];

  /// Unit patterns for all 11 Indian languages
  /// Captures: quantity + unit (e.g., "1 kg", "half kg", "500 ml")
  static const Map<String, List<String>> _unitPatterns = {
    // Weight units
    'weight': [
      // English
      'kg', 'kgs', 'kilogram', 'kilograms', 'kilo', 'kilos',
      'gram', 'grams', 'gm', 'gms', 'g',
      // Telugu
      'కిలో', 'కేజీ', 'గ్రాము', 'గ్రాములు',
      // Hindi
      'किलो', 'किलोग्राम', 'केजी', 'ग्राम',
      // Tamil
      'கிலோ', 'கிராம்',
      // Kannada
      'ಕಿಲೋ', 'ಗ್ರಾಂ',
      // Malayalam
      'കിലോ', 'ഗ്രാം',
      // Marathi
      'किलो', 'ग्रॅम',
      // Gujarati
      'કિલો', 'ગ્રામ',
      // Punjabi
      'ਕਿਲੋ', 'ਗ੍ਰਾਮ',
      // Bengali
      'কিলো', 'গ্রাম',
      // Odia
      'କିଲୋ', 'ଗ୍ରାମ',
    ],
    // Volume units
    'volume': [
      // English
      'liter', 'liters', 'litre', 'litres', 'l', 'lt', 'ltr',
      'ml', 'milliliter', 'milliliters',
      // Telugu
      'లీటర్', 'లీటర్లు', 'ఎమ్ఎల్',
      // Hindi
      'लीटर', 'मिलीलीटर', 'एमएल',
      // Tamil
      'லிட்டர்', 'மில்லி',
      // Kannada
      'ಲೀಟರ್', 'ಮಿಲಿ',
      // Malayalam
      'ലിറ്റർ', 'മില്ലി',
      // Marathi
      'लिटर', 'मिली',
      // Gujarati
      'લિટર', 'મિલી',
      // Punjabi
      'ਲੀਟਰ', 'ਮਿਲੀ',
      // Bengali
      'লিটার', 'মিলি',
      // Odia
      'ଲିଟର', 'ମିଲି',
    ],
    // Quantity units
    'quantity': [
      // English
      'piece', 'pieces', 'pc', 'pcs',
      'packet', 'packets', 'pack', 'packs',
      'box', 'boxes', 'dozen', 'pair', 'pairs',
      // Telugu
      'పీస్', 'ముక్క', 'ముక్కలు', 'ప్యాకెట్', 'బాక్స్',
      // Hindi
      'पीस', 'टुकड़ा', 'पैकेट', 'डिब्बा', 'दर्जन',
      // Tamil
      'துண்டு', 'பாக்கெட்', 'பெட்டி',
      // Kannada
      'ತುಂಡು', 'ಪ್ಯಾಕೆಟ್', 'ಪೆಟ್ಟಿಗೆ',
      // Malayalam
      'കഷണം', 'പാക്കറ്റ്', 'പെട്ടി',
      // Marathi
      'तुकडा', 'पॅकेट', 'डबा',
      // Gujarati
      'ટુકડો', 'પેકેટ', 'બોક્સ',
      // Punjabi
      'ਟੁਕੜਾ', 'ਪੈਕਟ', 'ਡੱਬਾ',
      // Bengali
      'টুকরা', 'প্যাকেট', 'বাক্স',
      // Odia
      'ଖଣ୍ଡ', 'ପ୍ୟାକେଟ୍', 'ବାକ୍ସ',
    ],
    // Fractional quantities
    'fractions': [
      // English
      'half', 'quarter', 'one fourth', 'three fourth',
      // Telugu
      'సగం', 'పావు', 'ముక్కాలు',
      // Hindi
      'आधा', 'पाव', 'तिहाई', 'चौथाई',
      // Tamil
      'அரை', 'கால்', 'முக்கால்',
      // Kannada
      'ಅರ್ಧ', 'ಕಾಲು', 'ಮುಕ್ಕಾಲು',
      // Malayalam
      'പകുതി', 'കാൽ', 'മുക്കാൽ',
      // Marathi
      'अर्धा', 'पाव', 'तीन चौथाई',
      // Gujarati
      'અડધું', 'પાવ', 'ત્રણ ચોથા',
      // Punjabi
      'ਅੱਧਾ', 'ਪਾਵ', 'ਤਿੰਨ ਚੌਥਾਈ',
      // Bengali
      'অর্ধেক', 'চতুর্থাংশ', 'তিন চতুর্থাংশ',
      // Odia
      'ଅଧା', 'ପାଉ', 'ତିନି ଚତୁର୍ଥାଂଶ',
    ],
  };

  /// Parse voice input and extract item name, price, unit, and calculate per-unit price
  /// Example: "Rice 1 kg 60 rupees" → Rice, ₹60, 1 kg, ₹60/kg
  /// Example: "Milk half liter 25 rupees" → Milk, ₹25, 0.5 liter, ₹50/liter
  ParsedItem? parseVoiceInput(String voiceText) {
    if (voiceText.trim().isEmpty) return null;

    String cleanedText = voiceText.trim();

    // Validate input length (prevent extremely long inputs)
    if (cleanedText.length > 500) {
      cleanedText = cleanedText.substring(0, 500);
    }

    // Extract unit first (before removing numbers)
    String? unit = _extractUnit(cleanedText);

    // Extract price (Google Speech API already converted numbers)
    double? price = _extractPrice(cleanedText);
    if (price == null) return null;

    // Extract quantity and unit type from the unit string
    double? quantity;
    String? unitType;
    double? pricePerUnit;

    if (unit != null) {
      final unitInfo = _parseUnitInfo(unit);
      quantity = unitInfo['quantity'];
      unitType = unitInfo['unitType'];

      // Validate quantity (must be positive and reasonable)
      if (quantity != null) {
        if (quantity <= 0 || quantity > 10000) {
          // Invalid quantity, treat as no unit
          quantity = null;
          unitType = null;
          unit = null;
        } else {
          // Calculate price per unit (for billing)
          // Example: 1 kg for ₹60 → ₹60/kg
          // Example: 0.5 liter for ₹25 → ₹50/liter
          pricePerUnit = price / quantity;

          // Validate per-unit price (sanity check)
          if (pricePerUnit < 0.01 || pricePerUnit > 100000) {
            pricePerUnit = null;
          }
        }
      }
    }

    // Extract item name (everything before the price)
    String? itemName = _extractItemName(cleanedText, price);
    if (itemName == null || itemName.isEmpty) return null;

    // Final validation: item name shouldn't be just numbers or special characters
    if (RegExp(r'^[\d\s\-\.]+$').hasMatch(itemName)) {
      return null; // Invalid item name
    }

    return ParsedItem(
      name: _capitalizeFirstLetter(itemName.trim()),
      price: price,
      unit: unit,
      quantity: quantity,
      unitType: unitType,
      pricePerUnit: pricePerUnit,
    );
  }

  /// Parse unit string to extract quantity and unit type
  /// Example: "1 kg" → {quantity: 1.0, unitType: "kg"}
  /// Example: "half liter" → {quantity: 0.5, unitType: "liter"}
  /// Example: "2.5 kg" → {quantity: 2.5, unitType: "kg"}
  Map<String, dynamic> _parseUnitInfo(String unitString) {
    final lowerUnit = unitString.toLowerCase().trim();

    // Extract numeric quantity
    double? quantity;
    String? unitType;

    // Check for fractional quantities first (half, quarter, etc.)
    for (var fraction in _unitPatterns['fractions']!) {
      if (lowerUnit.contains(fraction.toLowerCase())) {
        // Convert fraction words to numbers
        if (lowerUnit.contains('half') ||
            lowerUnit.contains('సగం') ||
            lowerUnit.contains('आधा') ||
            lowerUnit.contains('அரை') ||
            lowerUnit.contains('ಅರ್ಧ') ||
            lowerUnit.contains('പകുതി') ||
            lowerUnit.contains('अर्धा') ||
            lowerUnit.contains('અડધું') ||
            lowerUnit.contains('ਅੱਧਾ') ||
            lowerUnit.contains('অর্ধেক') ||
            lowerUnit.contains('ଅଧା')) {
          quantity = 0.5;
        } else if (lowerUnit.contains('quarter') ||
            lowerUnit.contains('పావు') ||
            lowerUnit.contains('पाव') ||
            lowerUnit.contains('கால்') ||
            lowerUnit.contains('ಕಾಲು') ||
            lowerUnit.contains('കാൽ') ||
            lowerUnit.contains('पाव') ||
            lowerUnit.contains('પાવ') ||
            lowerUnit.contains('ਪਾਵ') ||
            lowerUnit.contains('চতুর্থাংশ') ||
            lowerUnit.contains('ପାଉ')) {
          quantity = 0.25;
        }
        break;
      }
    }

    // If no fraction found, try to extract numeric quantity
    if (quantity == null) {
      final numberMatch = RegExp(r'(\d+\.?\d*)').firstMatch(lowerUnit);
      if (numberMatch != null) {
        quantity = double.tryParse(numberMatch.group(0)!);
      }
    }

    // Extract unit type by checking against all units
    final allUnits = <String>[];
    _unitPatterns.forEach((category, units) {
      allUnits.addAll(units);
    });

    for (var unit in allUnits) {
      if (lowerUnit.contains(unit.toLowerCase())) {
        unitType = _normalizeUnitType(unit);
        break;
      }
    }

    return {
      'quantity': quantity ?? 1.0, // Default to 1 if not found
      'unitType': unitType,
    };
  }

  /// Normalize unit type to standard forms
  /// Example: "kgs", "kilogram" → "kg"
  /// Example: "liters", "litre" → "liter"
  String _normalizeUnitType(String unit) {
    final lower = unit.toLowerCase();

    // Weight units
    if (lower.contains('kg') ||
        lower.contains('kilo') ||
        lower.contains('कि') ||
        lower.contains('கி') ||
        lower.contains('ಕಿ') ||
        lower.contains('കി') ||
        lower.contains('કિ') ||
        lower.contains('ਕਿ') ||
        lower.contains('কি') ||
        lower.contains('କି')) {
      return 'kg';
    }

    if (lower.contains('gram') ||
        lower.contains('gm') ||
        lower.contains('గ్రా') ||
        lower.contains('ग्रा') ||
        lower.contains('கிரா') ||
        lower.contains('ಗ್ರಾ') ||
        lower.contains('ഗ്രാ') ||
        lower.contains('ग्रॅ') ||
        lower.contains('ગ્રા') ||
        lower.contains('ਗ੍ਰਾ') ||
        lower.contains('গ্রা') ||
        lower.contains('ଗ୍ରା')) {
      return 'gram';
    }

    // Volume units
    if (lower.contains('liter') ||
        lower.contains('litre') ||
        lower.contains('లీ') ||
        lower.contains('ली') ||
        lower.contains('லி') ||
        lower.contains('ಲೀ') ||
        lower.contains('ലി') ||
        lower.contains('લિ') ||
        lower.contains('ਲੀ') ||
        lower.contains('লি') ||
        lower.contains('ଲି')) {
      return 'liter';
    }

    if (lower.contains('ml') || lower.contains('मि') || lower.contains('மி')) {
      return 'ml';
    }

    // Quantity units
    if (lower.contains('piece') ||
        lower.contains('pc') ||
        lower.contains('పీ') ||
        lower.contains('पी') ||
        lower.contains('டு') ||
        lower.contains('ತು') ||
        lower.contains('കഷ') ||
        lower.contains('तु') ||
        lower.contains('ટુ') ||
        lower.contains('ਟੁ') ||
        lower.contains('টু') ||
        lower.contains('ଖ')) {
      return 'piece';
    }

    if (lower.contains('packet') ||
        lower.contains('pack') ||
        lower.contains('ప్యా') ||
        lower.contains('पै') ||
        lower.contains('பா') ||
        lower.contains('ಪ್ಯಾ') ||
        lower.contains('പാ') ||
        lower.contains('पॅ') ||
        lower.contains('પે') ||
        lower.contains('ਪੈ') ||
        lower.contains('প্যা') ||
        lower.contains('ପ୍ୟା')) {
      return 'packet';
    }

    // Return original if no match
    return unit;
  }

  /// Extract unit from text (e.g., "1 kg", "half liter", "500 ml")
  /// Captures quantity + unit across all 11 Indian languages
  String? _extractUnit(String text) {
    final lowerText = text.toLowerCase();

    // Create list of all possible units
    List<String> allUnits = [];
    _unitPatterns.forEach((category, units) {
      allUnits.addAll(units);
    });

    // Look for pattern: [number/fraction] [unit]
    // Examples: "1 kg", "half liter", "500 ml", "2.5 kg"
    for (var unit in allUnits) {
      // Create regex pattern to match number/fraction + unit
      // Matches: "1 kg", "1kg", "half kg", "0.5 kg", "500 ml"
      final pattern = RegExp(
        r'(\d+\.?\d*|\b(?:' +
            _unitPatterns['fractions']!.join('|') +
            r'))\s*' +
            RegExp.escape(unit) +
            r'\b',
        caseSensitive: false,
      );

      final match = pattern.firstMatch(lowerText);
      if (match != null) {
        return match.group(0)!.trim();
      }
    }

    return null;
  }

  /// Extract price from text
  /// Google Speech API already converts "అరవై" → "60", "sixty" → "60"
  /// We just need to find the number!
  double? _extractPrice(String text) {
    // Find all numbers in the text (integer or decimal)
    RegExp digitRegex = RegExp(r'\d+\.?\d*');
    Iterable<Match> matches = digitRegex.allMatches(text);

    if (matches.isEmpty) return null;

    // Strategy: Look for the last reasonable price
    // Prefer numbers after price indicators (rupees, రూపాయలు, etc.)
    List<double> allNumbers = [];
    List<int> numberPositions = [];

    for (var match in matches) {
      double? value = double.tryParse(match.group(0)!);
      if (value != null) {
        allNumbers.add(value);
        numberPositions.add(match.start);
      }
    }

    // Find number closest to price indicator words
    for (int i = allNumbers.length - 1; i >= 0; i--) {
      double value = allNumbers[i];
      int position = numberPositions[i];

      // Check if there's a price indicator after this number
      String afterNumber = text.substring(position);
      bool hasPriceIndicator = _priceIndicators.any(
        (indicator) =>
            afterNumber.toLowerCase().contains(indicator.toLowerCase()),
      );

      // Validate price (should be between 0.1 and 100,000)
      // Very small numbers (< 10) are likely quantities, not prices
      if (value >= 0.1 && value <= 100000) {
        // Prefer numbers followed by price indicators
        if (hasPriceIndicator) {
          return value;
        }

        // If no price indicator, prefer larger numbers (> 5) as price
        if (i == allNumbers.length - 1 || value > 5) {
          return value;
        }
      }
    }

    // Fallback: return last number if valid
    if (allNumbers.isNotEmpty) {
      double lastValue = allNumbers.last;
      if (lastValue >= 0.1 && lastValue <= 100000) {
        return lastValue;
      }
    }

    return null;
  }

  /// Extract item name by removing price, units, and price indicators
  /// For loose items (rice, flour), returns just the item name without quantity
  /// Example: "Rice 1 kg 60 rupees" → "Rice" (NOT "Rice 1 kg")
  String? _extractItemName(String text, double price) {
    String itemName = text;

    // Remove the price number (the last number in the text)
    final priceStr = price.toString();
    final lastPriceIndex = itemName.lastIndexOf(priceStr);
    if (lastPriceIndex != -1) {
      itemName =
          itemName.substring(0, lastPriceIndex) +
          itemName.substring(lastPriceIndex + priceStr.length);
    }

    // Remove all unit/quantity information (numbers + unit words)
    // This ensures "Rice 1 kg" becomes just "Rice", not "Rice 1 Kg"
    // Get all unit words from all categories
    List<String> allUnits = [];
    _unitPatterns.forEach((category, units) {
      allUnits.addAll(units);
    });

    // Remove any number followed by optional space and unit
    // Matches: "1 kg", "2kg", "500 ml", "half liter", "one kg", "two kg", "వన్ కేజీ" etc.
    for (var unit in allUnits) {
      // Pattern: [optional number/fraction/word-number] [optional space] [unit]
      // Includes: digits (1, 2.5), fractions (half, quarter), word numbers (one, two, three)
      // Also includes Hinglish/Tenglish variations like "వన్" (one in Telugu)
      final pattern = RegExp(
        r'(\d+\.?\d*\s*|\b(?:' +
            _unitPatterns['fractions']!.join('|') +
            r'|one|two|three|four|five|six|seven|eight|nine|ten|' +
            r'ఒక|రెండు|మూడు|నాలుగు|ఐదు|ఆరు|ఏడు|ఎనిమిది|తొమ్మిది|పది|' +
            r'వన్|టూ|త్రీ|ఫోర్|ఫైవ్|సిక్స్|సెవెన్|ఎయిట్|నైన్|టెన్|' +
            r'एक|दो|तीन|चार|पांच|छह|सात|आठ|नौ|दस|' +
            r'ஒன்று|இரண்டு|மூன்று|நான்கு|ஐந்து|ஆறு|ஏழு|எட்டு|ஒன்பது|பத்து|' +
            r'ಒಂದು|ಎರಡು|ಮೂರು|ನಾಲ್ಕು|ಐದು|ಆರು|ಏಳು|ಎಂಟು|ಒಂಬತ್ತು|ಹತ್ತು|' +
            r'ഒന്ന്|രണ്ട്|മൂന്ന്|നാല്|അഞ്ച്|ആറ്|ഏഴ്|എട്ട്|ഒമ്പത്|പത്ത്|' +
            r'એક|બે|ત્રણ|ચાર|પાંચ|છ|સાત|આઠ|નવ|દસ|' +
            r'ਇੱਕ|ਦੋ|ਤਿੰਨ|ਚਾਰ|ਪੰਜ|ਛੇ|ਸੱਤ|ਅੱਠ|ਨੌਂ|ਦਸ|' +
            r'এক|দুই|তিন|চার|পাঁচ|ছয়|সাত|আট|নয়|দশ|' +
            r'ଏକ|ଦୁଇ|ତିନି|ଚାରି|ପାଞ୍ଚ|ଛଅ|ସାତ|ଆଠ|ନଅ|ଦଶ' +
            r')\s*)' +
            RegExp.escape(unit) +
            r'\b',
        caseSensitive: false,
      );
      itemName = itemName.replaceAll(pattern, '');
    }

    // Also remove standalone numbers and word numbers (in case not caught above)
    itemName = itemName.replaceAll(RegExp(r'\d+\.?\d*'), '');

    // Remove standalone English word numbers
    itemName = itemName.replaceAll(
      RegExp(
        r'\b(one|two|three|four|five|six|seven|eight|nine|ten)\b',
        caseSensitive: false,
      ),
      '',
    );

    // Remove standalone Telugu word numbers (both traditional and Hinglish/Tenglish)
    itemName = itemName.replaceAll(
      RegExp(
        r'\b(ఒక|రెండు|మూడు|నాలుగు|ఐదు|ఆరు|ఏడు|ఎనిమిది|తొమ్మిది|పది|వన్|టూ|త్రీ|ఫోర్|ఫైవ్|సిక్స్|సెవెన్|ఎయిట్|నైన్|టెన్)\b',
        caseSensitive: false,
      ),
      '',
    );

    // Remove standalone Hindi word numbers
    itemName = itemName.replaceAll(
      RegExp(r'\b(एक|दो|तीन|चार|पांच|छह|सात|आठ|नौ|दस)\b', caseSensitive: false),
      '',
    );

    // Remove price indicator words (case-insensitive)
    for (var indicator in _priceIndicators) {
      itemName = itemName.replaceAll(
        RegExp(indicator, caseSensitive: false),
        '',
      );
    }

    // Clean up extra spaces
    itemName = itemName.replaceAll(RegExp(r'\s+'), ' ').trim();

    // Validate item name
    if (itemName.isEmpty) return null;

    // Remove excessive special characters (keep only alphanumeric and basic punctuation)
    // Allow: letters (all languages), numbers, spaces, hyphens, apostrophes, parentheses
    itemName = itemName.replaceAll(RegExp(r"[^\w\s\-\'\(\)]+"), '');

    // Final cleanup
    itemName = itemName.trim();

    // Minimum length check (at least 2 characters)
    if (itemName.length < 2) return null;

    // Maximum length check (prevent extremely long names)
    if (itemName.length > 100) {
      itemName = itemName.substring(0, 100).trim();
    }

    return itemName.isNotEmpty ? itemName : null;
  }

  /// Capitalize first letter of each word (for English/Latin text only)
  String _capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;

    // For Indian language scripts, return as-is (no case conversion)
    // Unicode ranges:
    // - Devanagari (Hindi, Marathi): \u0900-\u097F
    // - Bengali: \u0980-\u09FF
    // - Gujarati: \u0A80-\u0AFF
    // - Gurmukhi (Punjabi): \u0A00-\u0A7F
    // - Odia: \u0B00-\u0B7F
    // - Tamil: \u0B80-\u0BFF
    // - Telugu: \u0C00-\u0C7F
    // - Kannada: \u0C80-\u0CFF
    // - Malayalam: \u0D00-\u0D7F
    if (RegExp(r'[\u0900-\u0D7F]').hasMatch(text)) {
      return text;
    }

    // For English/Latin text, capitalize each word
    return text
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;

          // Keep special characters intact (e.g., "Parle-G" stays "Parle-G")
          if (word.contains('-')) {
            return word
                .split('-')
                .map((part) {
                  if (part.isEmpty) return part;
                  return part[0].toUpperCase() +
                      part.substring(1).toLowerCase();
                })
                .join('-');
          }

          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }

  /// Test the parser with sample inputs
  static void test() {
    final parser = VoiceItemParser();

    print('🧪 Testing Voice Item Parser\n');
    print(
      'Note: Google Speech API converts spoken numbers to digits automatically\n',
    );

    final testCases = [
      // Telugu (Google converts "అరవై" to "60" automatically)
      'రైస్ 60 రూపాయలు',
      'పప్పు 120',
      'చక్కెర 50 రూపాయలు',
      'బియ్యం 60 rupaayalu',

      // English
      'Rice 60 rupees',
      'Parle-G 5',
      'Sugar 50',
      'Oil 150',

      // With units (should ignore unit numbers)
      'Milk 1 liter 60 rupees', // Should extract 60, not 1
      'Rice 5 kg 300 rupees', // Should extract 300, not 5
    ];

    for (var input in testCases) {
      final result = parser.parseVoiceInput(input);
      if (result != null) {
        print('✓ "$input"');
        print('  → Name: ${result.name}, Price: ₹${result.price}\n');
      } else {
        print('❌ "$input" → Failed to parse\n');
      }
    }

    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('💡 How it works:');
    print('   1. Google Speech API hears "అరవై రూపాయలు"');
    print('   2. Converts to text: "60 rupees" or "60 రూపాయలు"');
    print('   3. Parser extracts: Price = 60');
    print('   4. No manual number mapping needed! 🎉');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  }
}
