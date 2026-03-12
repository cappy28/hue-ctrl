# HUE CTRL 🔵🔴
**Contrôleur Philips Hue Bluetooth 9.27 — Flutter Android**

## 📱 Fonctionnalités
- Connexion Bluetooth directe aux ampoules Philips Hue (BLE)
- ON/OFF, luminosité, température de couleur
- 16 couleurs prédéfinies + picker personnalisé
- **Effets :** Gyrophare (rouge/bleu), Réactif son (micro), Veilleuse, Party, Aurora, Strobe, Bougie
- **Scènes :** Cinéma, Lecture, Focus, Romantique, Gaming, Réveil
- Interface dark néon

---

## 🚀 Compiler l'APK (5 étapes)

### Prérequis
- [Flutter SDK](https://flutter.dev/docs/get-started/install) installé
- [Android Studio](https://developer.android.com/studio) avec Android SDK
- Un téléphone Android **ou** un émulateur avec BLE activé

### Étapes

```bash
# 1. Aller dans le dossier du projet
cd hue_ctrl

# 2. Télécharger les dépendances
flutter pub get

# 3. Vérifier que tout est OK
flutter doctor

# 4. Compiler l'APK (debug pour test rapide)
flutter build apk --debug

# 5. APK disponible ici :
# build/app/outputs/flutter-apk/app-debug.apk
```

### APK release (pour installer sans Android Studio)
```bash
flutter build apk --release
# → build/app/outputs/flutter-apk/app-release.apk
```

### Installer directement sur ton téléphone
```bash
# Téléphone branché en USB avec mode développeur activé
flutter install
```

---

## 📲 Activer le mode développeur sur Android
1. Paramètres → À propos du téléphone
2. Appuie 7 fois sur "Numéro de build"
3. Paramètres → Options développeur → Activer le débogage USB

---

## 🔧 UUIDs Philips Hue Bluetooth
| Caractéristique | UUID |
|---|---|
| Service | `932c32bd-0000-47a2-835a-a8d455b859dd` |
| Power | `932c32bd-0002-47a2-835a-a8d455b859dd` |
| Brightness | `932c32bd-0003-47a2-835a-a8d455b859dd` |
| Color Temp | `932c32bd-0004-47a2-835a-a8d455b859dd` |
| Color XY | `932c32bd-0005-47a2-835a-a8d455b859dd` |

---

## ⚠️ Notes importantes
- L'app cherche uniquement les appareils exposant le **service Hue BLE**
- Android 12+ : les permissions `BLUETOOTH_SCAN` et `BLUETOOTH_CONNECT` sont demandées au lancement
- L'effet **Réactif son** nécessite la permission microphone
- Compatible Android 5.0+ (API 21+)
