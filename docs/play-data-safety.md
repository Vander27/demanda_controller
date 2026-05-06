# Data Safety - Resposta Recomendada

Atualizado em: 06/05/2026
Aplicativo: Demanda Controller

Este documento resume como preencher a secao Data Safety do Play Console com base no comportamento atual do app.

## 1. O app coleta ou compartilha dados?

- Coleta dados: sim.
- Compartilha dados com terceiros: sim, apenas com provedores essenciais de infraestrutura do proprio servico, como Firebase/Google.

## 2. Os dados sao criptografados em transito?

- Sim.

O app utiliza servicos do Firebase para autenticacao e backup em nuvem, com transmissao protegida em transito.

## 3. O usuario pode solicitar exclusao dos dados?

- Sim.

O aplicativo possui fluxo interno de exclusao de conta e dados.

## 4. Tipos de dados que devem ser declarados

### Informacoes pessoais

- E-mail

Finalidades aplicaveis:

- Funcionalidade do app
- Gerenciamento de conta

Coleta: sim.
Compartilhamento: sim, com Firebase Authentication como infraestrutura necessaria ao login.

### Outros dados inseridos pelo usuario

- Empresas
- Sites
- Adiantamentos
- Lancamentos financeiros
- Relatorios
- Configuracoes operacionais

Esses dados entram na categoria de dados fornecidos pelo usuario ou atividade no app, conforme a taxonomia exibida no Play Console.

Finalidades aplicaveis:

- Funcionalidade do app
- Backup, restauracao e sincronizacao

Coleta: sim.
Compartilhamento: sim, apenas com Firestore/Firebase para backup em nuvem vinculado a conta autenticada.

## 5. Tipos de dados que nao devem ser marcados

Nao marcar, salvo se o app mudar futuramente:

- Localizacao
- Contatos
- Fotos e videos
- Audio
- Arquivos pessoais fora do fluxo de backup/importacao iniciado pelo usuario
- Calendario
- Saude e fitness
- Mensagens
- Historico de navegacao na web
- Informacoes financeiras sensiveis do usuario fora do contexto operacional inserido manualmente
- Biometria
- Identificadores de publicidade

## 6. Uso dos dados

Linha recomendada para o formulario:

- Os dados sao usados para autenticacao, operacao do aplicativo, backup/restauracao e sincronizacao de dados da conta.
- O app nao vende dados pessoais.
- O app nao usa dados para publicidade.
- O app nao usa dados para rastreamento entre apps ou sites de terceiros.

## 7. Resumo pronto para marcar

- Coleta dados: sim.
- Compartilha dados: sim, apenas com provedores essenciais do servico.
- Criptografia em transito: sim.
- Solicitacao de exclusao: sim.
- Publicidade: nao.
- Venda de dados: nao.
- Rastreamento: nao.

## 8. Observacao de revisao

O AndroidManifest do app foi ajustado para desabilitar backup automatico do sistema operacional. Assim, o armazenamento persistente de backup fica restrito aos fluxos explicitos do proprio aplicativo, o que reduz ambiguidade regulatoria e operacional na publicacao.