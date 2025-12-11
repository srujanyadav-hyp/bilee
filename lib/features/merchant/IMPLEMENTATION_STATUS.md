# BILEE Merchant Module - Clean Architecture Implementation

## ✅ Completed: Domain Layer

### Created Files:
1. **domain/entities/item_entity.dart** - Pure Dart item entity
2. **domain/entities/session_entity.dart** - Session & session item entities  
3. **domain/entities/daily_aggregate_entity.dart** - Daily aggregate entities
4. **domain/repositories/i_merchant_repository.dart** - Repository interface (contract)
5. **domain/usecases/item_usecases.dart** - 4 item use cases with validation
6. **domain/usecases/session_usecases.dart** - 4 session use cases
7. **domain/usecases/daily_aggregate_usecases.dart** - 3 aggregate use cases

## 🚧 Remaining Implementation

Due to token/length constraints, here's what needs to be created:

### Data Layer Files Needed:

#### 1. data/models/item_model.dart
```dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ItemModel {
  final String id;
  final String merchantId;
  final String name;
  final double price;
  final String? hsn;
  final String? category;
  final double taxRate;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Constructor, fromJson, toJson methods
  // Match field names: price (not basePrice), hsn (not hsnCode)
}
```

#### 2. data/models/session_model.dart
```dart
class SessionItemLine {
  final String name;
  final int qty;
  final double price;
  final double tax;
  // fromJson, toJson
}

class SessionModel {
  final String sessionId;
  final String merchantId;
  final String status;
  final List<SessionItemLine> items;
  // Match Firestore field names
}
```

#### 3. data/models/daily_aggregate_model.dart
#### 4. data/datasources/merchant_firestore_datasource.dart
- All Firestore operations
- Use FirebaseFirestore.instanceFor(databaseId: 'bilee')

#### 5. data/repositories/merchant_repository_impl.dart
- Implements IMerchantRepository
- Uses datasource + mappers

#### 6. data/mappers/entity_model_mapper.dart
- Extension methods to convert:
  - ItemModel ↔ ItemEntity
  - SessionModel ↔ SessionEntity  
  - DailyAggregateModel ↔ DailyAggregateEntity
- Handle field name differences (price vs basePrice, hsn vs hsnCode, etc.)

### Presentation Layer Files Needed:

#### 7. presentation/providers/item_provider.dart
#### 8. presentation/providers/session_provider.dart
#### 9. presentation/providers/daily_aggregate_provider.dart

#### 10. presentation/pages/item_library_page.dart
#### 11. presentation/pages/merchant_home_page.dart
#### 12. presentation/pages/start_billing_page.dart
#### 13. presentation/pages/live_session_page.dart
#### 14. presentation/pages/daily_summary_page.dart

### Core Files:

#### 15. core/di/dependency_injection.dart
- Setup GetIt for dependency injection
- Register datasources, repositories, use cases, providers

## Implementation Steps:

1. ✅ Domain layer complete (pure Dart, no dependencies)
2. ⏳ Create data models matching Firestore structure
3. ⏳ Create Firestore datasource
4. ⏳ Create repository implementation
5. ⏳ Create entity ↔ model mappers
6. ⏳ Create providers (state management)
7. ⏳ Create UI pages
8. ⏳ Setup dependency injection
9. ⏳ Update main.dart to initialize DI

## Key Architecture Rules:

- **Domain** → No Flutter/Firebase deps, pure business logic
- **Data** → Firebase/API implementation, implements domain interfaces
- **Presentation** → Flutter UI, depends on domain via providers
- **Data Flow**: UI → Provider → UseCase → Repository → DataSource → Firebase

## Next Action:

Run the following command to copy models from data/models backup (if exists):
```bash
# Or create them fresh using the structure above
```

Then verify with:
```bash
flutter analyze lib/features/merchant/domain/
```
