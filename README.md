# ChickFarm

ChickFarm is a Flutter/Firebase poultry-management MVP for farm expenses,
workers, flock mortality, vaccination schedules, egg production and egg sales.

## Production data model

- `users/{uid}` stores the user's active tenant.
- `tenants/{tenantId}` stores farm identity.
- `tenants/{tenantId}/members/{uid}` controls farm access.
- Expenses and workers are tenant-scoped.
- Mortalities, vaccinations, egg collections and egg sales are scoped under
  the active flock.
- Sellable egg stock is updated atomically when good eggs are collected or sold.
- Egg sales support trays, loose eggs, buyer details and paid, partial or credit status.
- Stock corrections are append-only and require a reason, preserving an audit trail.

Firestore rules in `firestore.rules` enforce the same boundary. Root-level
legacy collections are intentionally inaccessible to the hardened client.

## Firebase setup

1. Enable Email/Password authentication in Firebase Authentication.
2. Deploy rules and indexes: `firebase deploy --only firestore`.
3. Add an ignored `android/key.properties` and release keystore for signed Android builds.
4. Build with `flutter build appbundle` or `flutter build web`.

Existing prototype records in root collections are not migrated automatically;
copy them into the appropriate tenant/flock only after assigning ownership.

## Verification

```sh
flutter pub get
flutter analyze
flutter test
flutter build appbundle
```
