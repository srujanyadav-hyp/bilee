import '../models/parsed_item.dart';
import 'package:translator/translator.dart';

/// Parser for Fast Input / Cart Addition (Adding items FROM library to cart)
/// REQUIRES: Item name, Quantity
/// OPTIONAL: Unit (defaults to 'piece')
/// NO PRICE REQUIRED: Will search library for existing item and use its price
/// Use Case: "రెండు కిలోల టమాటో" → Search "Tomato" in library, add 2 kg to cart
class VoiceCartItemParser {
  final _translator = GoogleTranslator();

  /// Unit patterns for all 11 Indian languages
  /// IMPORTANT: Plural forms MUST come before singular (కిలోలు before కిలో)
  static const Map<String, List<String>> _unitPatterns = {
    'weight': [
      'kg',
      'kgs',
      'kilogram',
      'kilograms',
      'kilo',
      'kilos',
      'gram',
      'grams',
      'gm',
      'gms',
      'g',
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
      'l',
      'ml',
      'milliliter',
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

  /// Parse voice input for cart item addition (no price needed)
  Future<ParsedItem?> parse(String voiceText) async {
    try {
      print('🛒 CART PARSER: "$voiceText"');

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

      // Step 3: Extract units
      final units = _extractUnits(input);
      print('   📦 Units: ${units.map((u) => u['unit']).toList()}');

      // Step 4: NO PRICE CHECK (cart items get price from library)
      print('   💰 Price: Will fetch from library');

      // Step 5: Identify quantity & unit
      String? unitString;
      double quantity = 1.0;
      String? unitType;

      if (units.isNotEmpty) {
        final unitData = units.first;
        final unitWord = unitData['unit'] as String;
        double? unitQuantity = unitData['quantity'] as double?;

        // If no quantity near unit, use first small number
        if (unitQuantity == null && numbers.isNotEmpty) {
          for (final num in numbers) {
            if (num >= 0.1 && num <= 100) {
              // Allow up to 100 for cart quantities
              unitQuantity = num;
              break;
            }
          }
        }

        quantity = unitQuantity ?? 1.0;
        unitString = '$quantity $unitWord';
        unitType = _getUnitType(unitWord);
        print('   📏 Unit: $unitString (qty: $quantity)');
      } else {
        // No unit found - use first reasonable number as quantity
        if (numbers.isNotEmpty) {
          for (final num in numbers) {
            if (num >= 0.1 && num <= 100) {
              quantity = num;
              break;
            }
          }
        }
        unitString = '$quantity piece';
        unitType = 'quantity';
        print('   📏 Unit: $unitString (default piece)');
      }

      // Step 6: Extract item name
      String? itemName = _extractItemName(voiceText, units, numbers);
      if (itemName == null || itemName.trim().isEmpty) {
        print('   ❌ FAIL: No item name found');
        return null;
      }
      print('   🏷️  Item: $itemName');
      print('   ✅ SUCCESS: $quantity x $itemName (price from library)');

      return ParsedItem(
        name: itemName,
        quantity: quantity,
        unit: unitString,
        unitType: unitType,
        price: null, // Will be fetched from library
      );
    } catch (e) {
      print('❌ Cart parser error: $e');
      return null;
    }
  }

  bool _hasNonLatinScript(String text) {
    return text.codeUnits.any((unit) => unit > 0x024F);
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

  List<Map<String, dynamic>> _extractUnits(String text) {
    final result = <Map<String, dynamic>>[];
    for (final category in _unitPatterns.entries) {
      for (final unit in category.value) {
        final index = text.indexOf(unit.toLowerCase());
        if (index != -1) {
          // Look for quantity near unit - pick CLOSEST number to unit
          double? quantity;
          int closestDistance = 999999;
          final start = (index - 30).clamp(0, text.length);
          final end = (index + unit.length + 30).clamp(0, text.length);
          final context = text.substring(start, end);

          final numMatches = RegExp(r'(\d+\.?\d*)').allMatches(context);
          for (final match in numMatches) {
            final num = double.tryParse(match.group(0)!);
            if (num != null && num >= 0.1 && num <= 100) {
              // Calculate distance from number to unit
              final numPosition = start + match.start;
              final distance = (numPosition - index).abs();

              // Pick number closest to unit
              if (distance < closestDistance) {
                quantity = num;
                closestDistance = distance;
              }
            }
          }

          result.add({'unit': unit, 'quantity': quantity, 'position': index});
          break;
        }
      }
    }
    return result;
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
