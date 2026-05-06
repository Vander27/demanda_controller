<div align="center">

# ⚡ DEMANDA CONTROLLER

### Sistema Inteligente de Gestão de Demandas TSSR

![Flutter](https://img.shields.io/badge/Flutter-3.11+-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.11+-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20Windows-green?style=for-the-badge)
![Version](https://img.shields.io/badge/Version-1.0.0-blueviolet?style=for-the-badge)
![License](https://img.shields.io/badge/License-Proprietário-red?style=for-the-badge)

**Desenvolvido por Vanderlei Campos — TECHNOLOGY BR**

</div>

---

## 📋 Visão Geral

**Demanda Controller** é uma aplicação móvel/desktop de alta performance desenvolvida em **Flutter**, projetada para profissionais de telecomunicações que gerenciam vistorias TSSR (Telecommunications Site Survey Report). O sistema oferece controle financeiro completo, rastreamento de sites em tempo real e geração automatizada de relatórios profissionais.

---

## 🏗️ Arquitetura do Sistema

```
┌─────────────────────────────────────────────────┐
│                   PRESENTATION                   │
│  ┌───────────┐ ┌───────────┐ ┌────────────────┐ │
│  │ Dashboard │ │   Sites   │ │  Relatório     │ │
│  │  Screen   │ │   List    │ │  Diário TSSR   │ │
│  └─────┬─────┘ └─────┬─────┘ └───────┬────────┘ │
│        │              │               │          │
│  ┌─────┴──────────────┴───────────────┴────────┐ │
│  │           DemandaController                 │ │
│  │         (ChangeNotifier / State)            │ │
│  └─────────────────┬───────────────────────────┘ │
├────────────────────┼────────────────────────────┤
│                    │        DOMAIN               │
│  ┌─────────────────┴───────────────────────────┐ │
│  │  EmpresaModel │ SiteModel │ RelatorioDiario │ │
│  │  AdiantamentoModel │ RelatorioConfig        │ │
│  └─────────────────┬───────────────────────────┘ │
├────────────────────┼────────────────────────────┤
│                    │     INFRASTRUCTURE          │
│  ┌─────────────────┴───────────────────────────┐ │
│  │         SharedPreferences (Local DB)        │ │
│  └─────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────┘
```

---

## ✨ Funcionalidades

### 🏢 Gestão Multi-Empresa
- Cadastro ilimitado de empresas com configurações independentes
- Valor por site customizável por empresa
- Troca rápida entre empresas via seletor dinâmico

### 📡 Controle de Sites TSSR
- **3 Status de Rastreamento**: Concluído ✅ | Não Concluído ❌ | Aguardando ⏳
- Registro de motivos para sites não concluídos
- Data de conclusão individual por site
- Busca e filtros avançados por status

### 💰 Motor Financeiro
| Funcionalidade | Descrição |
|---|---|
| **Estimativa Total** | Cálculo automático baseado em sites × valor |
| **Valor Ganho** | Soma dos sites concluídos |
| **Valor Perdido** | Sites não concluídos |
| **Adiantamentos** | Controle por lote (%) ou valor fixo |
| **Saldo a Receber** | Com e sem adiantamentos |
| **Pagamento Final** | Confirmação com valor e data |

### 📊 Relatório Diário TSSR
- Checklist interativo de sites visitados
- Registro de problemas de acesso com motivo
- Configuração: Operadora, Fabricante, Projeto, Região (UF)
- Histórico completo de relatórios anteriores
- Importação em massa de Site IDs (colar lista)

### 📤 Exportação Profissional
| Formato | Descrição |
|---|---|
| **PDF** | Relatório completo com cabeçalho, tabelas, gráficos de resumo e seção de relatório diário |
| **Excel** | Planilha multi-aba (uma por empresa) com todos os dados |
| **WhatsApp** | Texto formatado com emojis para compartilhamento direto |
| **Clipboard** | Cópia rápida para área de transferência |

### 💾 Backup & Restauração
- Exportação completa em JSON (empresas + relatórios + configurações)
- Restauração com confirmação de segurança
- Compatível entre versões do app

### 📈 Dashboard Analítico
- Gráfico em pizza do progresso (fl_chart)
- Cards de resumo com gradientes visuais
- Barra de progresso por lote
- Resumo global multi-empresa
- Alerta inteligente para solicitar adiantamento

---

## 🛠️ Stack Tecnológico

| Tecnologia | Versão | Uso |
|---|---|---|
| **Flutter** | 3.11+ | Framework UI multiplataforma |
| **Dart** | 3.11+ | Linguagem de programação |
| **pdf** | 3.11.1 | Geração de PDFs profissionais |
| **printing** | 5.13.3 | Preview e impressão de PDFs |
| **excel** | 4.0.6 | Geração de planilhas .xlsx |
| **fl_chart** | 0.69.2 | Gráficos interativos |
| **shared_preferences** | 2.3.3 | Persistência local |
| **share_plus** | 10.1.4 | Compartilhamento nativo |
| **file_picker** | 8.1.6 | Seleção de arquivos (backup) |
| **path_provider** | 2.1.4 | Diretórios do sistema |
| **google_fonts** | 6.2.1 | Tipografia personalizada |

---

## 📁 Estrutura do Projeto

```
lib/
├── main.dart                          # Entry point + Splash Screen
├── controllers/
│   └── demanda_controller.dart        # State management central
├── models/
│   ├── empresa_model.dart             # Modelo de empresa + cálculos
│   ├── site_model.dart                # Modelo de site TSSR
│   ├── adiantamento_model.dart        # Modelo de adiantamento
│   └── relatorio_model.dart           # Modelo relatório diário + config
├── screens/
│   ├── dashboard_screen.dart          # Dashboard + gráficos + tabs
│   ├── sites_list_screen.dart         # Lista de sites + CRUD
│   ├── adiantamentos_screen.dart      # Gestão de adiantamentos
│   ├── relatorio_diario_screen.dart   # Relatório diário TSSR
│   ├── exportar_screen.dart           # PDF / Excel / WhatsApp / Backup
│   └── empresa_form_screen.dart       # Formulário de empresa
├── theme/
│   └── app_theme.dart                 # Design system (cores, gradientes)
assets/
└── images/
    ├── logo_vc.png                    # Logo principal
    ├── icon_dev.png                   # Ícone do desenvolvedor
    └── banner_vc.png                  # Banner
```

---

## 🚀 Como Executar

### Pré-requisitos
- Flutter SDK 3.11+
- Dart SDK 3.11+
- Android Studio / VS Code

### Instalação

```bash
# Clonar o repositório
git clone <repo-url>
cd demanda_controller

# Instalar dependências
flutter pub get

# Executar no dispositivo/emulador
flutter run

# Build APK de produção
flutter build apk --release

# Build para Windows
flutter build windows --release
```

---

## 🔐 Documentos Legais (Play Store)

Os documentos legais do aplicativo estão prontos na pasta `docs/`:

- `docs/index.html`
- `docs/privacy-policy.html`
- `docs/terms-license.html`
- `docs/playstore-policy-status.md`

### Publicar no GitHub Pages

1. Envie o projeto para um repositório no GitHub
2. No GitHub, abra **Settings > Pages**
3. Em **Build and deployment**, selecione:
   - **Source**: Deploy from a branch
   - **Branch**: `main` (ou `master`) / pasta `/docs`
4. Salve e aguarde a publicação

Depois disso, os links ficarão no formato:

- `https://SEU_USUARIO.github.io/NOME_REPO/`
- `https://SEU_USUARIO.github.io/NOME_REPO/privacy-policy.html`
- `https://SEU_USUARIO.github.io/NOME_REPO/terms-license.html`

---

## 📱 Fluxo de Uso

```
1. Cadastrar Empresa
   └── Definir: nome, valor/site, tipo adiantamento
        └── Sites são importados ou adicionados manualmente

2. Trabalho Diário (Aba Relatório)
   └── Colar lista de sites do dia
   └── Marcar: FEITO ✅ ou PROBLEMA ❌ (com motivo)
   └── Compartilhar via WhatsApp

3. Acompanhar Financeiro (Aba Dashboard)
   └── Progresso visual por empresa
   └── Solicitar adiantamento ao completar lote
   └── Confirmar pagamento final

4. Exportar Relatórios
   └── PDF profissional com todos os dados + relatório diário
   └── Excel para análise detalhada
   └── Backup JSON para segurança
```

---

## 🔧 Modelo de Dados

### EmpresaModel
```
├── id, nome, valorPorSite
├── sites: List<SiteModel>
├── adiantamentos: List<AdiantamentoModel>
├── tipoAdiantamento: percentualPorLote | valorFixoSemanal | valorFixoUnico | sem
├── percentualAdiantamento, sitesPorLote
└── foiPago, dataPagamento, valorPago
```

### SiteModel
```
├── siteId (ex: BASDR_0002)
├── status: concluido | naoConcluido | pendente
├── motivoNaoConcluido
└── dataConclusao
```

### RelatorioDiario
```
├── id, data
├── operadora, projeto, fabricante, regiao
└── sites: List<RelatorioSiteItem>
    ├── siteId, feito, motivo
    └── dataExecucao
```

---

## 🎨 Design System

| Token | Valor | Uso |
|---|---|---|
| `primaryColor` | Indigo 900 | Cor principal |
| `secondaryColor` | Cyan Accent | Destaques |
| `successColor` | Green | Sites concluídos |
| `errorColor` | Red | Sites não concluídos |
| `warningColor` | Amber | Sites aguardando / alertas |
| `surfaceColor` | Grey 50 | Background geral |

Gradientes: `primaryGradient`, `successGradient`, `warningGradient`, `dangerGradient`, `accentGradient`

---

## 📊 Tipos de Adiantamento

| Tipo | Descrição | Exemplo |
|---|---|---|
| **Percentual por Lote** | X% a cada N sites concluídos | 40% a cada 20 sites |
| **Valor Fixo Semanal** | Valor fixo por semana | R$ 2.000/semana |
| **Valor Fixo Único** | Pagamento único antecipado | R$ 5.000 |
| **Sem Adiantamento** | Pagamento somente ao final | — |

---

## 🔒 Segurança & Persistência

- Dados armazenados localmente via `SharedPreferences`
- Sem envio de dados para servidores externos
- Sistema de backup/restauração manual em JSON
- Validação de entrada em todos os formulários

---

<div align="center">

### ⚡ Demanda Controller

**v1.0.0** — Desenvolvido por **Vanderlei Campos** — TECHNOLOGY BR

*Sistema projetado para otimizar a gestão de demandas TSSR com eficiência e precisão.*

</div>
