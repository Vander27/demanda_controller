# Status de Politicas - Play Store

Atualizado em: 07/05/2026
Aplicativo: Demanda Controller

## 1. Conta e autenticacao
- [x] Login por e-mail e senha implementado
- [x] Recuperacao de senha por e-mail implementada
- [x] Exclusao de conta dentro do app (requisito critico da Play para apps com cadastro)

## 2. Privacidade e termos
- [x] Politica de privacidade publicada em pagina web
- [x] Termos e licenca de uso publicados em pagina web
- [ ] URL da politica cadastrada no Play Console

## 3. Dados e seguranca
- [x] Backup local (arquivo)
- [x] Backup na nuvem por usuario autenticado
- [x] Regras de Firestore criadas no projeto
- [x] Backup automatico do Android desabilitado para evitar persistencia fora do fluxo explicito do app
- [ ] Regras de Firestore publicadas no Firebase Console
- [ ] Data Safety do Play Console preenchido conforme dados coletados

## 4. Publicacao e assinatura
- [x] Keystore de release criada
- [x] Assinatura release configurada no Gradle
- [x] SHA1/SHA256 da release gerados
- [ ] SHA da App Signing Key do Google Play adicionado no Firebase (apos primeiro upload AAB)
- [ ] AAB enviado no Play Console

## 5. Faixa etaria e publico
- [ ] Target audience preenchido no Play Console
- [x] Documentacao legal atualizada para esclarecer que classificacao livre nao implica publico infantil
- [ ] Confirmar no Play Console que o app nao e direcionado a criancas e que o publico pretendido e profissional/adulto

## 6. Links oficiais para Play Console
- Home legal: https://vander27.github.io/demanda_controller/
- Politica de privacidade: https://vander27.github.io/demanda_controller/privacy-policy.html
- Termos e licenca: https://vander27.github.io/demanda_controller/terms-license.html
- Guia de uso do app: https://vander27.github.io/demanda_controller/como-usar-app.html

## 7. Proximo passo recomendado
1. Preencher o Play Console com base em ./play-console-preenchimento.md.
2. Cadastrar URL da politica no Play Console.
3. Publicar as regras de Firestore no Firebase Console.
4. Preencher Data Safety conforme os dados realmente tratados pelo app.
5. Usar ./play-data-safety.md como guia de resposta no Play Console.
