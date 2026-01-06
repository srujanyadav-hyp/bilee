import '../models/parsed_item.dart';
import 'package:translator/translator.dart';

/// Parser for Voice Item Add (Adding NEW items TO the library)
/// REQUIRES: Item name + Price (mandatory)
/// OPTIONAL: Quantity, Unit
/// Use Case: "రెండు కిలోల టమాటో 50 రూపాయలు" → Add "Tomato" to library at ₹50/kg
class VoiceItemLibraryParser {
  final _translator = GoogleTranslator();

  /// Common price indicator words (across all Indian languages)
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
  static const Map<String, List<String>> _unitPatterns = {
    'weight': [
      'kilogram',
      'kilograms',
      'kilo',
      'kilos',
      'kg',
      'kgs',
      'gram',
      'grams',
      'gm',
      'gms',
      // 'g' removed - too ambiguous (matches 'dozen', 'egg', etc.)
      // Telugu (singular + plural)
      'కిలోలు', // kilolu (plural) - must come before కిలో
      'కిలో',
      'కేజీలు', // kglu (plural)
      'కేజీ',
      'గ్రాములు', // gramulu (plural)
      'గ్రాము',
      // Hindi
      'किलो',
      'केजी',
      // Tamil
      'கிலோ',
      // Kannada
      'ಕಿಲೋ',
    ],
    'volume': [
      'liter',
      'liters',
      'litre',
      'litres',
      'milliliter',
      'ml',
      // 'l' removed - too ambiguous (matches many words)
      // Telugu (singular + plural)
      'లీటర్లు', // literlu (plural) - must come before లీటర్
      'లీటర్',
      'లిటర్లు', // litrlu (plural)
      'లిటర్',
      'మిల్లీ',
      // Hindi
      'लीटर',
      'लिटर',
      // Tamil
      'லிட்டர்',
      // Kannada
      'ಲೀಟರ್',
    ],
    'quantity': [
      'dozen',
      'doz',
      'dozens',
      'packet',
      'packets',
      'pack',
      'packs',
      'piece',
      'pieces',
      'pcs',
      'pc',
      'box',
      'boxes',
      'bottle',
      'bottles',
      // Telugu (singular + plural)
      'డజనులు', // dozanlu (plural) - must come before డజన్
      'డజన్',
      'ప్యాకెట్లు', // packetlu (plural)
      'ప్యాకెట్',
      'పీస్లు', // pieceslu (plural)
      'పీస్',
      'బాటిల్లు', // bottlelu (plural)
      'బాటిల్',
      'బాక్స్లు', // boxlu (plural)
      'బాక్స్',
      // Hindi
      'दर्जन',
      'पैकेट',
      'पीस',
      'बोतल',
    ],
  };

  /// Parse voice input for library item addition
  /// REQUIRES: price (mandatory)
  Future<ParsedItem?> parse(String voiceText) async {
    try {
      print('🎯 LIBRARY PARSER: "$voiceText"');

      // Step 1: Translate if non-Latin
      String input = voiceText.trim().toLowerCase();
      if (_hasNonLatinScript(input)) {
        print('🌐 Translating to English...');
        final translation = await _translator.translate(voiceText, to: 'en');
        input = translation.text.toLowerCase();
        print('🌐 Translation: "$voiceText" → "$input"');
      }

      // Step 2: Extract numbers
      final numbers = _extractNumbers(input);
      print('   📊 Numbers: $numbers');

      // Step 3: Identify price FIRST (before units, so we can exclude it from quantity)
      double? price = _identifyPrice(input, numbers);
      if (price == null) {
        print('   ❌ FAIL: Price REQUIRED for library items');
        return null;
      }
      print('   💰 Price: ₹$price');

      // Step 4: Extract units (now we can exclude price from quantity detection)
      final units = _extractUnits(input, price);
      print('   📦 Units: ${units.map((u) => u['unit']).toList()}');

      // Step 5: Identify quantity & unit
      String? unitString;
      double? quantity;
      String? unitType;

      if (units.isNotEmpty) {
        final unitData = units.first;
        final unitWord = unitData['unit'] as String;
        quantity = unitData['quantity'] as double?;

        // If no quantity near unit, use first small number (1-20) that's NOT the price
        if (quantity == null && numbers.isNotEmpty) {
          for (final num in numbers) {
            if (num >= 0.1 && num <= 20 && num != price) {
              quantity = num;
              break;
            }
          }
        }

        quantity ??= 1.0;
        unitString = '$quantity $unitWord';
        unitType = _getUnitType(unitWord);
        print('   📏 Unit: $unitString (qty: $quantity)');
      }

      // Step 6: Extract item name
      String? itemName = _extractItemName(voiceText, units, numbers);
      if (itemName == null || itemName.trim().isEmpty) {
        print('   ❌ FAIL: No item name found');
        return null;
      }
      print('   🏷️  Item: $itemName');

      // Step 7: Calculate per-unit price
      double pricePerUnit = price;
      if (quantity != null && quantity > 1) {
        pricePerUnit = price / quantity;
        print('   💡 Per-unit: ₹$pricePerUnit (₹$price ÷ $quantity)');
      }

      print('   ✅ SUCCESS: $itemName at ₹$pricePerUnit');

      return ParsedItem(
        name: itemName,
        quantity: quantity ?? 1.0,
        unit: unitString,
        unitType: unitType,
        price: pricePerUnit,
      );
    } catch (e) {
      print('❌ Library parser error: $e');
      return null;
    }
  }

  bool _hasNonLatinScript(String text) {
    return text.codeUnits.any((unit) => unit > 0x024F);
  }

  /// Extract numbers WITH their positions in the text
  /// Returns a list of maps: {'value': 25.0, 'position': 21}
  List<Map<String, dynamic>> _extractNumbersWithPositions(String text) {
    final results = <Map<String, dynamic>>[];

    // Extract numeric digits with positions (e.g., "2", "100", "1.5")
    final matches = RegExp(r'\d+\.?\d*').allMatches(text);
    for (final match in matches) {
      final num = double.tryParse(match.group(0)!);
      if (num != null) {
        results.add({
          'value': num,
          'position': match.start,
          'text': match.group(0)!,
        });
      }
    }

    return results;
  }

  List<double> _extractNumbers(String text) {
    final numbers = <double>[];

    // Extract numeric digits (e.g., "2", "100", "1.5")
    final matches = RegExp(r'\d+\.?\d*').allMatches(text);
    for (final match in matches) {
      final num = double.tryParse(match.group(0)!);
      if (num != null) numbers.add(num);
    }

    // Convert English number words to numeric values
    final numberWords = {
      'zero': 0.0,
      'one': 1.0,
      'two': 2.0,
      'three': 3.0,
      'four': 4.0,
      'five': 5.0,
      'six': 6.0,
      'seven': 7.0,
      'eight': 8.0,
      'nine': 9.0,
      'ten': 10.0,
      'eleven': 11.0,
      'twelve': 12.0,
      'thirteen': 13.0,
      'fourteen': 14.0,
      'fifteen': 15.0,
      'sixteen': 16.0,
      'seventeen': 17.0,
      'eighteen': 18.0,
      'nineteen': 19.0,
      'twenty': 20.0,
      'thirty': 30.0,
      'forty': 40.0,
      'fifty': 50.0,
      'sixty': 60.0,
      'seventy': 70.0,
      'eighty': 80.0,
      'ninety': 90.0,
      'hundred': 100.0,
      'half': 0.5,
      'quarter': 0.25,
    };

    for (final entry in numberWords.entries) {
      if (text.contains(entry.key)) {
        numbers.add(entry.value);
      }
    }

    return numbers;
  }

  List<Map<String, dynamic>> _extractUnits(
    String text,
    double? priceToExclude,
  ) {
    final result = <Map<String, dynamic>>[];
    for (final category in _unitPatterns.entries) {
      for (final unit in category.value) {
        // Use word boundary matching to avoid false positives
        // e.g., 'g' should not match 'dozen', 'l' should not match 'oil'
        final pattern = RegExp(
          r'\b' + RegExp.escape(unit.toLowerCase()) + r'\b',
          caseSensitive: false,
        );
        final match = pattern.firstMatch(text);

        if (match != null) {
          final index = match.start;
          // Look for quantity near unit (but NOT the price!)
          double? quantity;
          final start = (index - 30).clamp(0, text.length);
          final end = (index + unit.length + 30).clamp(0, text.length);
          final context = text.substring(start, end);

          final numMatches = RegExp(r'(\d+\.?\d*)').allMatches(context);
          for (final match in numMatches) {
            final num = double.tryParse(match.group(0)!);
            // 🔥 Exclude the price number from quantity detection
            if (num != null &&
                num >= 0.1 &&
                num <= 20 &&
                num != priceToExclude) {
              quantity = num;
              break;
            }
          }

          result.add({'unit': unit, 'quantity': quantity, 'position': index});
          break;
        }
      }
    }
    return result;
  }

  double? _identifyPrice(String text, List<double> numbers) {
    if (numbers.isEmpty) return null;

    print('   🔍 Price detection: text="$text", numbers=$numbers');

    // Get numbers with positions for accurate matching
    final numbersWithPos = _extractNumbersWithPositions(text);
    print('   📍 Numbers with positions: $numbersWithPos');

    // Check for ₹ symbol FIRST
    final rupeeIndex = text.indexOf('₹');
    if (rupeeIndex != -1) {
      print('   💱 Found ₹ symbol at position $rupeeIndex');

      // Find closest number to ₹ symbol
      double? closestNum;
      int closestDistance = 999999;

      for (final numData in numbersWithPos) {
        final distance = ((numData['position'] as int) - rupeeIndex).abs();
        if (distance < 15 && distance < closestDistance) {
          closestNum = numData['value'] as double;
          closestDistance = distance;
        }
      }

      if (closestNum != null) {
        print(
          '   ✅ Price from ₹ symbol: $closestNum (distance: $closestDistance)',
        );
        return closestNum;
      }
    }

    // Check price indicators with better word boundary detection
    for (final indicator in _priceIndicators) {
      final lowerIndicator = indicator.toLowerCase();

      // Use word boundary regex for better matching
      final pattern = RegExp(
        r'\b' + RegExp.escape(lowerIndicator) + r'\b',
        caseSensitive: false,
      );
      final match = pattern.firstMatch(text);

      if (match != null) {
        final index = match.start;
        print('   💵 Found indicator "$indicator" at position $index');

        // Find closest number to this indicator (within 40 chars)
        // Use actual positions from _extractNumbersWithPositions
        double? closestNum;
        int closestDistance = 999999;

        for (final numData in numbersWithPos) {
          final numPosition = numData['position'] as int;
          final numValue = numData['value'] as double;
          final distance = (numPosition - index).abs();

          if (distance < 40 && distance < closestDistance) {
            closestNum = numValue;
            closestDistance = distance;
          }
        }

        if (closestNum != null) {
          print(
            '   ✅ Price from indicator "$indicator": $closestNum (distance: $closestDistance)',
          );
          return closestNum;
        }
      }
    }

    // For library: if only one number, assume it's price (no minimum threshold)
    if (numbers.length == 1) {
      print(
        '   ✅ Only one number found, assuming it\'s the price: ${numbers[0]}',
      );
      return numbers[0];
    }

    // If multiple numbers, pick the largest as price
    if (numbers.length > 1) {
      final largest = numbers.reduce((a, b) => a > b ? a : b);
      print('   ✅ Multiple numbers, picking largest as price: $largest');
      return largest;
    }

    print('   ❌ No price found');
    return null;
  }

  String? _extractItemName(
    String text,
    List<Map<String, dynamic>> units,
    List<double> numbers,
  ) {
    String name = text;

    // Remove 11-language number words
    final indianNumberWords = [
      'ఒకటి',
      'ఒక',
      'రెండు',
      'మూడు',
      'ముడు',
      'నాలుగు',
      'ఐదు',
      'అరుగు',
      'ఆరు',
      'ఏడు',
      'ఎనిమిది',
      'తొమిమిది',
      'పది',
      'పదు',
      'एक',
      'दो',
      'तीन',
      'चार',
      'पाँच',
      'पांच',
      'छह',
      'सात',
      'आठ',
      'नौ',
      'दस',
      'ஒன்று',
      'இரண்டு',
      'மூன்று',
      'நான்கு',
      'ஐந்து',
      'ஆறு',
      'ஏழு',
      'எட்டு',
      'ஒன்பது',
      'பத்து',
    ];
    for (final word in indianNumberWords) {
      name = name.replaceAll(word, ' ');
    }

    // Remove Telugu unit words with suffixes (sorted by length)
    final teluguUnits = [
      'కిలోల',
      'కిలోలు',
      'కిలోళ్ళ',
      'కిలో',
      'కేజీల',
      'కేజీలు',
      'కేజీ',
      'లీటర్ల',
      'లీటర్లు',
      'లీటర్',
      'లిటర్ల',
      'లిటర్లు',
      'లిటర్',
      'గ్రాముల',
      'గ్రాములు',
      'గ్రాము',
      'ప్యాకెట్ల',
      'ప్యాకెట్లు',
      'ప్యాకెట్',
      'ప్యాకెట్స్లు',
      'ప్యాకెట్స్',
      'బాటిల్ల',
      'బాటిల్లు',
      'బాటిల్',
      'బాక్స్ల',
      'బాక్స్లు',
      'బాక్స్',
      'పీస్ల',
      'పీస్లు',
      'పీస్',
      'డజన్ల',
      'డజన్లు',
      'డజన్',
    ];
    teluguUnits.sort((a, b) => b.length.compareTo(a.length));
    for (final unit in teluguUnits) {
      name = name.replaceAll(unit, ' ');
    }

    // Remove digits
    name = name.replaceAll(RegExp(r'\s+\d+\.?\d*\s+'), ' ');
    name = name.replaceAll(RegExp(r'^\d+\.?\d*\s+'), '');
    name = name.replaceAll(RegExp(r'\s+\d+\.?\d*$'), '');

    // Remove price symbols
    name = name.replaceAll(RegExp(r'[₹$£€¥]\s*\d+\.?\d*'), '');

    // Remove price indicators
    for (final indicator in _priceIndicators) {
      name = name.replaceAll(RegExp(indicator, caseSensitive: false), ' ');
    }

    // Remove English units
    for (final units in _unitPatterns.values) {
      for (final unit in units) {
        name = name.replaceAll(RegExp(unit, caseSensitive: false), ' ');
      }
    }

    // Final cleanup - remove Telugu suffixes
    final suffixes = [' ల ', ' లు ', ' ళ్ళ ', ' స్ ', ' ్ '];
    for (final suffix in suffixes) {
      name = name.replaceAll(suffix, ' ');
    }
    name = name.replaceAll(RegExp(r'^(ల|లు|ళ్ళ|స్|్)\s+'), '');
    name = name.replaceAll(RegExp(r'\s+(ల|లు|ళ్ళ|స్|్)$'), '');

    name = name.replaceAll(RegExp(r'\s+'), ' ').trim();
    return name.isEmpty ? null : name;
  }

  String? _getUnitType(String unit) {
    for (final entry in _unitPatterns.entries) {
      if (entry.value.any((u) => u.toLowerCase() == unit.toLowerCase())) {
        return entry.key;
      }
    }
    return 'other';
  }
}
