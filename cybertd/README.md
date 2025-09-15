# CyberTD – Godot 4 Tower Defense (skeleton)

Minimalní kostra tower defense hry v Godotu 4. Po spuštění editoru uvidíš nepřátele jedoucí po Path2D, ukázkovou věž a střely.

## Co je uvnitř

- `scenes/Main.tscn` – hlavní scéna s `Path2D`, `Timer`em a kontejnery pro Towers/Bullets.
- `scripts/Main.gd` – spawner nepřátel a auto‑vytvoření jednoduché křivky, když je prázdná.
- `scenes/Enemy.tscn` + `scripts/Enemy.gd` – nepřítel jako `PathFollow2D`, ve skupině `enemies`.
- `scenes/Tower.tscn` + `scripts/Tower.gd` – věž s `Area2D` dosahem, míří na cíl a střílí.
- `scenes/Bullet.tscn` + `scripts/Bullet.gd` – projektil, míří na cíl a po zásahu poškodí.

## Jak spustit

1. Otevři složku `cybertd/` v Godotu 4.
2. Projekt už má nastavenou hlavní scénu `scenes/Main.tscn`.
3. Stiskni Play (F5).

## Úprava Path2D

- Vyber v `Main` → `Path2D` a v editoru uprav body křivky.

## Věže

- Do `Main.tscn` pod uzel `Towers` můžeš přidat instanci `Tower.tscn`.
- Jedna ukázková věž je instancovaná skriptem `Main.gd` na pozici `(200, 140)`.

## VS Code rozšíření (volitelná)

- Godot Tools (geequlim.godot-tools) – spuštění/ladění, lint, syntax highlight.
- GDScript language support (geequlim.godot-tools).
- EditorConfig (EditorConfig.EditorConfig).

## Poznámky

- Kolize jsou zjednodušené. Enemy má malé `Area2D`, věž používá `Area2D` pro vyhledávání cílů.
- Placeholder grafiku můžeš nahradit vlastními sprity.

## Export na Android (Google Play)

Základní postup:

1. Nainstaluj Android export templates (Editor → Editor Settings → Export → Install Android Build Template, popř. stáhni oficiální šablony pro tvoji verzi Godotu).
2. Nastav Android SDK a JDK v Editor Settings (Environment → Android) – cesty na `ANDROID_HOME` a `JAVA_HOME`.
3. Project → Export → přidej preset „Android“.

- Package/Unique Name: např. `com.yourcompany.cybertd`
- Version Name/Code: dle Play Console
- Signing: nastav release keystore a hesla
- Permissions: povol Internet, pokud používáš online pluginy

1. Vytvoř release build (AAB) a nahrávej přes Play Console.

Google přihlášení (Play Games Services / Google Sign-In):

- Kód již obsahuje detekci Android pluginů v `AuthService.sign_in_google()`:
  - Hledá singleton `GodotGooglePlayGames` (GPGS) nebo `GodotGoogleSignIn`.
  - Na úspěch nastaví `provider = "google"` a `user_id` dle pluginu.
  - Uložené profily jsou namespacované: `user://saves/<provider>_<user_id>.save` (guest vs google se nepletou).
- Abys měl skutečné přihlášení:
  1) Nainstaluj a povol Android plugin (do `addons/`, poté Project Settings → Plugins).
  2) V Play Console nastav Play Games Services (OAuth klient, SHA‑1 podpis, propojení s balíčkem).
  3) Ověř, že package name, SHA‑1 a OAuth konfigurace se shodují s releasem.

Poznámka: Na desktopu a v editoru `sign_in_google()` jen vypíše varování; reálné přihlášení funguje až v Android buildu s nainstalovaným pluginem.

