# Radio Stanice RS

Flutter aplikacija za slusanje internet radio stanica iz Srbije.

## Sta aplikacija trenutno radi

- Moderan dark UI sa splash ekranom.
- Lista unapred definisanih stanica (Red, Radio S1, Radio OK, TDI, JAT, Rock Radio, Karolina).
- Pokretanje i zaustavljanje reprodukcije dodirom na stanicu.
- Dinamicko trazenje stream URL-ova preko Radio Browser API mirror hostova.
- Redosled kandidata po jednostavnom scoring-u i fallback na vise URL kandidata.
- Lokalni cache uspesnog stream URL-a po nazivu stanice.
- Prikaz loading stanja i poruka o gresci ako stream ne moze da se pusti.
- Wakelock je ukljucen kako bi se izbeglo gasenje ekrana tokom slusanja.

## Tehnologije

- Flutter
- Dart
- just_audio
- http
- wakelock_plus

## Zahtevi

- Flutter SDK
- Dart SDK `^3.11.1` (definisano u `pubspec.yaml`)
- Android Studio / Xcode (zavisno od platforme)

## Pokretanje projekta

1. Kloniraj repozitorijum.
2. Instaliraj zavisnosti:

```bash
flutter pub get
```

3. Pokreni aplikaciju:

```bash
flutter run
```

## Build

Android APK:

```bash
flutter build apk --release
```

Android App Bundle:

```bash
flutter build appbundle --release
```

iOS:

```bash
flutter build ios --release
```

## Struktura projekta

```text
lib/
	main.dart                     # Ulazna tacka (inicijalizacija i runApp)
	app.dart                      # Tema i root widget
	models/
		radio_station.dart          # Model stanice
	pages/
		splash_page.dart            # Splash ekran
		radio_home_page.dart        # Glavni ekran + audio logika
	services/
		radio_browser_service.dart  # Trazenje i rangiranje stream URL-ova
	widgets/
		station_card.dart           # Kartica stanice
		radio_home_header.dart      # Header sekcija
```

## Mrezne i Android napomene

- Aplikacija koristi internet streamove i oslanja se na Radio Browser API.
- U Android manifestu su ukljucene relevantne dozvole (`INTERNET`, `ACCESS_NETWORK_STATE`, `WAKE_LOCK`, foreground media service dozvole).
- Ako pojedina stanica ne radi, razlog je najcesce neispravan ili nedostupan stream URL na strani provajdera.

## Ogranicenja trenutne verzije

- Nema pretrage stanica iz UI-ja (search polje je vizuelno, bez logike pretrage).
- Nema trajnih favorita ni lokalne baze.
- Nema full background/lockscreen kontrole kroz audio handler (trenutno fokus na foreground reprodukciji).
- Pokriven je ogranicen skup unapred definisanih stanica.

## Korisni Flutter komandni primeri

Analiza koda:

```bash
flutter analyze
```

Testovi:

```bash
flutter test
```

Ciscenje build artefakata:

```bash
flutter clean
```

## Sledeci koraci (predlog)

- Dodati funkcionalnu pretragu i filtriranje stanica.
- Dodati favorite sa perzistencijom (npr. shared_preferences ili sqflite).
- Dodati robustniji audio background setup i lockscreen kontrole.
- Dodati automatsko ucitavanje vecih lista stanica po zanru i drzavi.
