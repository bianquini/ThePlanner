# 💰 ThePlanner — Organizador Financeiro Pessoal

> Aplicativo Flutter para controle de finanças pessoais com autenticação Google, sincronização em tempo real via Firestore e dashboard visual completo.

---

## 📱 Funcionalidades

| Tela | O que faz |
|---|---|
| **Dashboard** | Visão geral do mês: saldo, total de gastos, total de rendas, alertas de limite e gráfico de pizza por categoria |
| **Gastos** | Lista de gastos do mês com swipe para editar/excluir, FAB para adicionar |
| **Rendas** | Lista de entradas do mês com swipe para editar/excluir, FAB para adicionar |
| **Planejamento** | Gráfico de barras com projeção dos próximos 6 meses, taxa de economia e dica financeira |
| **Detalhes do Mês** | Acessado tocando em uma barra do gráfico — breakdown por categoria (donut chart), por tipo (fixo/parcelado/avulso) e parcelas ativas com barra de progresso |
| **Simulador** | Simula o impacto de um novo gasto (avulso ou parcelado) no orçamento futuro antes de confirmar |
| **Perfil** | Foto e nome da conta Google, acesso a Configurações e botão de logout |
| **Configurações** | Define limite mensal geral e limite de alimentação (usado para alertas no Dashboard) |

### Tipos de Transação

- **Fixo** — gasto recorrente mensal (aluguel, academia, planos)
- **Parcelado** — compra dividida em N parcelas, com controle de parcela atual/total
- **Avulso** — gasto pontual do mês
- **Renda** — entrada de dinheiro (salário, freelance, investimentos)

### Swipe Actions

Em qualquer lista de transações, deslize para a **esquerda** para revelar:
- 🔵 **Editar** — abre o formulário pré-preenchido
- 🔴 **Excluir** — remove do Firestore

---

## 🛠 Stack

| Camada | Tecnologia |
|---|---|
| Framework | Flutter 3.x (Dart 3) |
| Autenticação | Firebase Auth + Google Sign-In |
| Banco de dados | Cloud Firestore (tempo real + cache offline) |
| Estado | Riverpod 2 (`StreamProvider`, `Provider.family`) |
| Gráficos | fl_chart (`BarChart`, `PieChart`) |
| Swipe actions | flutter_slidable 3 |
| Fontes | Google Fonts — Nunito |
| Formatação | intl (pt_BR, moeda BRL) |
| IDs únicos | uuid v4 |

---

## 🏗 Arquitetura

```
lib/
├── main.dart                           # Entry point, AuthGate, MainNavigation
├── core/
│   ├── auth/
│   │   └── auth_service.dart           # Wrapper Firebase Auth + Google Sign-In
│   ├── firestore/
│   │   ├── transaction_repository.dart # CRUD Firestore: add, update, remove
│   │   └── budget_repository.dart      # Save/load de limites orçamentários
│   └── theme/
│       └── app_theme.dart              # AppColors + AppTheme (Material 3)
├── models/
│   ├── transaction_model.dart          # Transaction + TransactionType enum
│   └── budget_model.dart               # Budget (limiteMensal, limiteAlimentacao)
├── providers/
│   ├── auth_provider.dart              # authStateProvider (StreamProvider<User?>)
│   ├── transactions_provider.dart      # Stream + derivados (gastos, rendas, saldo)
│   └── budget_provider.dart           # budgetProvider (StreamProvider<Budget>)
├── screens/
│   ├── auth/login_screen.dart          # Tela de login com botão Google
│   ├── dashboard/dashboard_screen.dart
│   ├── gastos/gastos_screen.dart
│   ├── rendas/rendas_screen.dart
│   ├── planejamento/planejamento_screen.dart
│   ├── detalhes_mes/detalhes_mes_screen.dart
│   ├── simulador/simulador_screen.dart
│   ├── perfil/perfil_screen.dart
│   └── configuracoes/configuracoes_screen.dart
└── widgets/
    ├── transaction_tile.dart           # Tile com Slidable (editar/excluir)
    └── add_transaction_sheet.dart      # Bottom sheet: adicionar ou editar transação
```

### Fluxo de Dados

```
Firebase Auth
    │
    ▼
authStateProvider (StreamProvider<User?>)
    │
    ├──► transactionsStreamProvider (StreamProvider<List<Transaction>>)
    │        │  Firestore: users/{uid}/transactions (tempo real)
    │        │
    │        ├──► gastosMesProvider      → totalGastosProvider
    │        ├──► rendasMesProvider      → totalRendasProvider → saldoProvider
    │        ├──► gastosMesDetalhadoProvider(DateTime)   ← family
    │        └──► rendasMesDetalhadoProvider(DateTime)   ← family
    │
    └──► budgetProvider (StreamProvider<Budget>)
             Firestore: users/{uid}/budget
```

### Modelo de Dados — Firestore

```
users/
  {uid}/
    transactions/
      {uuid}/
        id:            String    (UUID v4)
        titulo:        String
        valor:         double
        tipo:          String    ("fixo" | "parcelado" | "avulso" | "renda")
        categoria:     String
        data:          Timestamp
        totalParcelas: int?      (somente parcelado)
        parcelaAtual:  int?      (somente parcelado)
    budget/
      config/
        limiteMensal:       double?
        limiteAlimentacao:  double?
```

### Lógica de Projeção (Planejamento + Detalhes do Mês)

Para meses futuros, os dados são **estimados** (sem transações reais no Firestore):

```
Gasto estimado(mês + i) = fixos do mês atual
                        + parcelados onde i ≤ (totalParcelas - parcelaAtual)
```

O mês atual usa **dados reais**. Meses passados usam **histórico real** do Firestore.

---

## 🚀 Como Rodar o Projeto

### Pré-requisitos

- Flutter SDK ≥ 3.11 (com Dart ≥ 3.0)
- Android Studio ou VS Code com extensão Flutter
- Conta Google Firebase
- Android Emulator ou dispositivo físico

### 1. Clone o repositório

```bash
git clone https://github.com/SEU_USUARIO/theplanner.git
cd theplanner
```

### 2. Configure o Firebase

> ⚠️ Os arquivos `google-services.json` e `firebase_options.dart` **não estão** no repositório por segurança. Siga os passos abaixo para criar seu próprio projeto Firebase.

#### 2a. Crie um projeto no Firebase Console
1. Acesse [console.firebase.google.com](https://console.firebase.google.com)
2. Clique em **Adicionar projeto** → nomeie como `ThePlanner`
3. Desative o Google Analytics (opcional) → **Criar projeto**

#### 2b. Adicione o app Android
1. No painel do projeto → **Adicionar app** → ícone Android
2. **Nome do pacote Android**: `com.theplanner.the_planner`
3. Baixe o `google-services.json` e coloque em `android/app/google-services.json`

#### 2c. Ative o Cloud Firestore
1. No menu lateral → **Firestore Database** → **Criar banco de dados**
2. Escolha **Modo de produção** → selecione a região (ex: `southamerica-east1`)
3. Configure as **Regras de segurança**:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

#### 2d. Ative o Firebase Auth
1. No menu lateral → **Authentication** → **Começar**
2. Aba **Método de login** → **Google** → Ativar → **Salvar**
3. Adicione o e-mail de suporte quando solicitado

#### 2e. Gere o `firebase_options.dart`

Instale o FlutterFire CLI:
```bash
dart pub global activate flutterfire_cli
```

No diretório do projeto:
```bash
flutterfire configure --project=SEU_PROJETO_ID
```

Isso gera `lib/firebase_options.dart` automaticamente. **Não commite este arquivo.**

> Se preferir, em `lib/main.dart` substitua `Firebase.initializeApp()` por
> `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)`
> e importe o arquivo gerado.

### 3. Instale as dependências

```bash
flutter pub get
```

### 4. Execute o app

```bash
# Listar dispositivos disponíveis
flutter devices

# Rodar em emulador específico
flutter run -d emulator-5554

# Rodar em modo release (mais rápido)
flutter run --release
```

---

## 🧪 Como Testar

### Fluxo Completo — Passo a Passo

#### 1. Login
- Abra o app → toque em **"Entrar com Google"**
- Selecione uma conta Google → aguarda redirecionar para o Dashboard

#### 2. Adicionar Rendas
- Aba **Rendas** (ícone 📈) → FAB `+`
- Preencha: Título = "Salário", Valor = 5000, Categoria = "Salário" → **Adicionar**
- A renda aparece na lista imediatamente (Firestore tempo real)

#### 3. Adicionar Gastos
- Aba **Gastos** (ícone 🧾) → FAB `+`
- **Fixo**: Título = "Aluguel", Valor = 1500, Tipo = Fixo, Categoria = "Moradia"
- **Avulso**: Título = "Mercado", Valor = 300, Tipo = Avulso, Categoria = "Alimentação"
- **Parcelado**: Título = "iPhone", Valor = 200, Tipo = Parcelado, Parcela = 4/12, Categoria = "Tecnologia"

#### 4. Verificar Dashboard
- Aba **Início** → confirme:
  - Saldo = Rendas − Gastos (R$ 5000 − R$ 2000 = R$ 3000)
  - Gráfico de pizza exibe as categorias com cores
  - Alertas surgem se os limites estiverem configurados

#### 5. Swipe para Editar / Excluir
- Na lista de Gastos, **deslize um item para a esquerda**
- Toque **Editar** (azul) → formulário abre pré-preenchido → altere um valor → **Salvar alterações**
- Deslize outro item → toque **Excluir** (vermelho) → item removido

#### 6. Planejamento + Detalhes do Mês
- Aba **Planos** (ícone 📊)
- Verifique o gráfico de barras com 6 meses (mês atual destacado com `●`)
- Toque em qualquer barra → abre **Detalhes do Mês**
  - Veja os 3 cards resumo: Entradas, Gastos, Saldo
  - Gráfico de rosca mostra breakdown por categoria
  - Lista com barras de progresso por categoria
  - Use **← →** na AppBar para navegar entre meses
  - Meses futuros mostram badge **"Projeção"** e banner 🔮

#### 7. Simulador
- Acesse via Dashboard (botão Simular, se disponível)
- Informe valor + número de parcelas → **Simular**
- Verifique a tabela de projeção: Verde = dentro do limite, Laranja = perto do limite, Vermelho = ultrapassou
- Toque **Confirmar e Adicionar** para registrar efetivamente

#### 8. Limites de Orçamento
- **Perfil** → **Configurações**
- Limite geral = R$ 3.000 | Limite Alimentação = R$ 500 → **Salvar**
- Volte ao Dashboard → adicione gastos que ultrapassem os limites → observe os alertas de cor no card

#### 9. Teste Offline
- Desative Wi-Fi/dados do emulador
- Adicione uma transação → registrada localmente (Firestore offline cache)
- Reative a conexão → sincronização automática com o servidor

#### 10. Logout e Re-login
- **Perfil** → **Sair da conta**
- Faça login novamente com a mesma conta → todos os dados retornam

---

### Build de Produção

```bash
# APK Android release
flutter build apk --release

# App Bundle (recomendado para Google Play)
flutter build appbundle --release

# APK gerado em:
# build/app/outputs/flutter-apk/app-release.apk
```

---

## 🎨 Design System

### Paleta de Cores

| Token | Hex | Uso |
|---|---|---|
| `primary` | `#4361EE` | Azul — ações principais, AppBar |
| `pink` / `expense` | `#F72585` | Rosa — gastos, FAB, alertas |
| `income` | `#2ECC71` | Verde — rendas, saldo positivo |
| `purple` | `#7209B7` | Roxo — parcelamentos |
| `cyan` | `#4CC9F0` | Ciano — acento secundário |
| `background` | `#F2F3F7` | Fundo geral |
| `textDark` | `#2C3E50` | Texto principal |
| `textGrey` | `#95A5A6` | Texto secundário |

### Fonte
**Nunito** (Google Fonts) — pesos w500, w600, w700, w800

### Raio de borda padrão
- Cards: `16px` | Chips: `20px` | Tiles: `14px`

---

## 📁 Arquivos de Configuração

| Arquivo | Git | Descrição |
|---|---|---|
| `android/app/google-services.json` | ❌ ignorado | Configuração Firebase Android |
| `lib/firebase_options.dart` | ❌ ignorado | Gerado pelo FlutterFire CLI |
| `android/key.properties` | ❌ ignorado | Chave de assinatura release |
| `pubspec.yaml` | ✅ incluso | Dependências e metadados |
| `.gitignore` | ✅ incluso | Padrão Flutter + Firebase |

---

## 🔒 Segurança

- Cada usuário acessa **somente seus próprios dados** (regra Firestore por `uid`)
- Autenticação via OAuth Google (sem senha armazenada)
- `google-services.json` e `firebase_options.dart` excluídos do repositório
- Dados cacheados localmente com Firestore persistence (funciona offline)

---

## 📦 Dependências Principais

```yaml
flutter_riverpod: ^2.6.1     # Gerenciamento de estado reativo
fl_chart: ^0.70.2            # Gráficos de barras e pizza
flutter_slidable: ^3.1.1     # Swipe actions nas listas
firebase_core: ^3.13.0       # Core Firebase
firebase_auth: ^5.5.2        # Autenticação
cloud_firestore: ^5.6.0      # Banco de dados NoSQL em tempo real
google_sign_in: ^6.2.2       # Login com Google
google_fonts: ^6.2.1         # Fonte Nunito
intl: ^0.19.0                # Formatação pt_BR e moeda BRL
uuid: ^4.5.1                 # Geração de IDs únicos
```

---

## 🤝 Contribuindo

1. Fork o repositório
2. Crie uma branch: `git checkout -b feature/nova-funcionalidade`
3. Commit suas mudanças: `git commit -m "feat: adicionar nova funcionalidade"`
4. Push: `git push origin feature/nova-funcionalidade`
5. Abra um Pull Request

---

## 📄 Licença

MIT © Iago B.
