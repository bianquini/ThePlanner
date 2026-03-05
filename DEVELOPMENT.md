# ThePlanner — Developer Guide

> Documentação técnica para build, emulação e debug. Destinada a devs com conhecimento Flutter/Android.

---

## Índice

1. [Pré-requisitos](#pré-requisitos)
2. [Build para Play Store](#build-para-play-store)
3. [Emulador Android](#emulador-android)
4. [Debug e Testes](#debug-e-testes)
5. [Firebase](#firebase)
6. [Referência rápida](#referência-rápida)

---

## Pré-requisitos

| Ferramenta | Versão mínima | Verificar |
|---|---|---|
| Flutter SDK | 3.x | `flutter --version` |
| Android Studio | Hedgehog+ | — |
| Java (JBR) | 17 | `java -version` |
| Android SDK | API 35 | Android Studio SDK Manager |
| ADB | qualquer | `adb version` |

```bash
# Checagem completa do ambiente
flutter doctor -v
```

Todos os itens devem estar com ✅. Warnings no iOS podem ser ignorados (projeto Android-only).

---

## Build para Play Store

### Configuração de assinatura

O build release requer o keystore em `android/theplanner-release.jks` e o arquivo
`android/key.properties` (ambos **gitignored** — nunca commitar).

**Estrutura do `android/key.properties`:**
```properties
storePassword=theplanner2026
keyPassword=theplanner2026
keyAlias=theplanner
storeFile=../theplanner-release.jks
```

Se o keystore não existir na máquina, regenerá-lo:
```powershell
powershell -ExecutionPolicy Bypass -File tool/gen_keystore.ps1
```

> ⚠️ O keystore é a identidade permanente do app na Play Store.
> Sem ele não é possível publicar atualizações. Manter backup em local seguro.

---

### Ciclo de release

#### 1. Incrementar versão em `pubspec.yaml`

```yaml
# Formato: versionName+versionCode
version: 1.0.0+2   # versionCode=2, versionName=1.0.0
```

- **versionCode** (`+N`): inteiro que **sempre cresce**. O Play Console rejeita uploads com código ≤ ao atual.
- **versionName** (`x.y.z`): string exibida ao usuário. Alterar a cada release significativo.

#### 2. Gerar App Bundle (AAB)

```bash
flutter build appbundle --release
```

Arquivo de saída:
```
build/app/outputs/bundle/release/app-release.aab
```

#### 3. Gerar APK (opcional — para testes locais sem emulador)

```bash
flutter build apk --release
# output: build/app/outputs/flutter-apk/app-release.apk

# Instalar direto no dispositivo/emulador conectado
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

#### 4. Commitar e subir

```bash
git add pubspec.yaml
git commit -m "chore: bump versionCode para N"
git push
```

#### 5. Upload no Play Console

- Play Console → App → Release → Internal testing (ou Production)
- Criar novo release → Upload `app-release.aab`
- Preencher release notes → Salvar → Revisar → Publicar

---

### Flags úteis de build

```bash
# Build com output verbose (útil para debug de build failures)
flutter build appbundle --release --verbose

# Desabilitar tree-shaking de ícones (caso esteja perdendo ícones)
flutter build appbundle --release --no-tree-shake-icons

# Obfuscation + símbolos de debug (para crash reports no Firebase Crashlytics)
flutter build appbundle --release \
  --obfuscate \
  --split-debug-info=build/debug-info/
```

---

## Emulador Android

### Via Android Studio (GUI)

1. Abrir Android Studio
2. Menu: **Tools → Device Manager**
3. Selecionar um AVD e clicar ▶️

### Via linha de comando

```powershell
# Listar AVDs disponíveis
& "C:\Users\iagob\AppData\Local\Android\Sdk\emulator\emulator.exe" -list-avds

# Iniciar um AVD específico (substitua NOME_DO_AVD)
& "C:\Users\iagob\AppData\Local\Android\Sdk\emulator\emulator.exe" -avd NOME_DO_AVD

# Iniciar sem janela (headless — útil em CI)
& "C:\Users\iagob\AppData\Local\Android\Sdk\emulator\emulator.exe" -avd NOME_DO_AVD -no-window -no-audio
```

### Verificar dispositivos conectados

```bash
adb devices
# Saída esperada:
# List of devices attached
# emulator-5554   device
```

### Instalar e lançar o app debug no emulador

```bash
# Instalar APK debug
adb install -r build/app/outputs/flutter-apk/app-debug.apk

# Lançar o app
adb shell am start -n "com.theplanner.the_planner/.MainActivity"
```

### Atalhos úteis durante emulação

| Ação | Comando |
|---|---|
| Capturar screenshot | `adb shell screencap -p /sdcard/sc.png && adb pull /sdcard/sc.png` |
| Simular toque | `adb shell input tap X Y` |
| Simular swipe | `adb shell input swipe X1 Y1 X2 Y2 DURACAO_MS` |
| Pressionar Voltar | `adb shell input keyevent 4` |
| Pressionar Home | `adb shell input keyevent 3` |
| Injetar texto | `adb shell input text "texto_aqui"` |
| Rotacionar tela | `adb shell settings put system user_rotation 1` (landscape) |

---

## Debug e Testes

### Flutter run (desenvolvimento principal)

```bash
# Modo debug com hot reload
flutter run

# Selecionar dispositivo específico
flutter run -d emulator-5554

# Modo profile (performance real sem símbolos de debug)
flutter run --profile

# Modo release no dispositivo
flutter run --release
```

Durante `flutter run`:
- **r** → Hot Reload (preserva estado)
- **R** → Hot Restart (reinicia app)
- **p** → Mostrar/ocultar pixel grid
- **o** → Alternar plataforma (Android/iOS)
- **q** → Sair

---

### Logs

```bash
# Logs do Flutter em tempo real (filtra apenas logs do app)
flutter logs

# Logcat completo do Android (mais verboso)
adb logcat

# Logcat filtrado por tag
adb logcat -s flutter

# Logcat filtrado por nível (E = errors only)
adb logcat *:E

# Salvar logs em arquivo
adb logcat > debug.log
```

---

### Flutter DevTools

Interface visual para inspeção de widgets, performance e rede:

```bash
# Iniciar com a app rodando
flutter devtools

# Ou via browser, acessar a URL exibida no flutter run:
# Exemplo: http://127.0.0.1:9100?uri=...
```

Funcionalidades principais:
- **Widget Inspector** → inspecionar árvore de widgets, tamanhos, padding
- **Performance** → frame timing, jank detection
- **Memory** → heap snapshots, GC monitoring
- **Network** → requests HTTP/Firestore em tempo real
- **Logging** → console de logs estruturados

---

### Riverpod — Debug de estado

```dart
// Adicionar ProviderObserver para logar mudanças de estado
class AppProviderObserver extends ProviderObserver {
  @override
  void didUpdateProvider(ProviderBase provider, Object? prev, Object? next, ProviderContainer container) {
    print('[Riverpod] ${provider.name}: $prev → $next');
  }
}

// Em main.dart:
runApp(
  ProviderScope(
    observers: [AppProviderObserver()],
    child: const MyApp(),
  ),
);
```

---

### Firestore — Debug local

Para desenvolvimento sem consumir quota do Firestore em produção, usar o emulador local:

```bash
# Instalar Firebase CLI (uma vez)
npm install -g firebase-tools

# Iniciar emuladores locais
firebase emulators:start --only firestore

# UI do emulador disponível em:
# http://localhost:4000
```

Apontar o app para o emulador local em `main.dart`:
```dart
// Apenas em modo debug
if (kDebugMode) {
  FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
}
```

---

### Verificar SHA de certificados

```powershell
# SHA-256 do keystore RELEASE (necessário no Firebase Console)
powershell -ExecutionPolicy Bypass -File tool/get_sha256.ps1

# SHA-1 do keystore DEBUG (para registrar no Firebase se necessário)
& "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" `
  -list -v `
  -keystore "$env:USERPROFILE\.android\debug.keystore" `
  -alias androiddebugkey `
  -storepass android `
  -keypass android
```

---

### Análise estática e formatação

```bash
# Análise de código (warnings, erros de lint)
flutter analyze

# Formatar código automaticamente
dart format lib/

# Verificar dependências desatualizadas
flutter pub outdated

# Atualizar dependências (respeitando constraints do pubspec.yaml)
flutter pub upgrade
```

---

### Limpeza de cache (quando o build quebra por razões estranhas)

```bash
# Limpar build cache do Flutter
flutter clean

# Após limpar, sempre rodar pub get antes de build/run
flutter pub get

# Limpar cache do Gradle (solução para erros de build Android)
cd android && ./gradlew clean && cd ..
```

---

## Firebase

### Estrutura de coleções no Firestore

```
users/{uid}/
  ├── gastos_fixos/{id}       → { nome, valor, categoria, ativo }
  ├── gastos_parcelados/{id}  → { nome, valorTotal, parcelas, parcelaAtual, categoria }
  ├── gastos_avulsos/{id}     → { nome, valor, categoria, mes, ano }
  ├── rendas/{id}             → { nome, valor, tipo }
  └── configuracoes/{id}      → { limites: { categoria: valor } }
```

### Registrar SHA-256 release no Firebase (obrigatório para Google Sign-In em release)

1. Obter fingerprint: `powershell -ExecutionPolicy Bypass -File tool/get_sha256.ps1`
2. Firebase Console → Projeto → ⚙️ Configurações → App Android
3. **Adicionar impressão digital** → colar SHA-256
4. Baixar novo `google-services.json` → substituir em `android/app/`
5. Rebuild: `flutter build appbundle --release`

---

## Referência rápida

```bash
# Desenvolvimento diário
flutter run                              # debug no emulador
flutter run --release                    # release no dispositivo (sem Play Store)

# Build
flutter build appbundle --release        # AAB para Play Store
flutter build apk --release              # APK para instalação direta

# ADB
adb devices                              # listar dispositivos
adb install -r arquivo.apk              # instalar APK
adb logcat -s flutter                   # logs do Flutter

# Manutenção
flutter clean && flutter pub get         # limpar e restaurar
flutter analyze                         # lint
dart format lib/                         # formatar código
flutter pub outdated                     # checar dependências

# Ferramentas do projeto
powershell -ExecutionPolicy Bypass -File tool/gen_keystore.ps1      # gerar keystore
powershell -ExecutionPolicy Bypass -File tool/get_sha256.ps1        # ver SHA-256
powershell -ExecutionPolicy Bypass -File tool/take_all_screenshots.ps1  # screenshots
```
