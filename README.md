# diet_tracker

Flutter diet tracker with local logging, USDA FoodData Central, and Open Food Facts.

## API keys

USDA FoodData Central requires an API key ([get one](https://fdc.nal.usda.gov/api-key-signup.html)).  
Do **not** commit the key.

**Recommended (Cursor / VS Code):** copy `dart_defines.example.json` to `dart_defines.local.json`,  
paste your key, and use the **diet_tracker** run configuration (loads via `--dart-define-from-file`).

**CLI:**

```bash
flutter run --dart-define-from-file=dart_defines.local.json
```

Or:

```bash
flutter run --dart-define=USDA_API_KEY=your_key_here
```

Open Food Facts does not use a key. The app sends the User-Agent  
`DietTracker/1.0.0 (Flutter; diet-tracker-app)` as required by their API.

## Food search

- Built-in catalog and cached foods are searched first.
- Generic foods (e.g. paneer, rice, banana) query **USDA** when local results are thin.
- Packaged / branded queries and barcode numbers use **Open Food Facts**.
- Enter an 8–14 digit barcode in the search field for product lookup.
- Cached foods are stored in `shared_preferences` for offline reuse (7-day TTL).

## Tests

```bash
flutter analyze
flutter test
```

Network integration tests against live APIs are manual; unit tests cover parsers and nutrition math.