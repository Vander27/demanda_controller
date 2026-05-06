# Status de Politicas - Play Store

Atualizado em: 06/05/2026
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
- [ ] Confirmar que o app nao e direcionado a criancas

## 6. Links oficiais para Play Console
- Home legal: ./index.html
- Politica de privacidade: ./privacy-policy.html
- Termos e licenca: ./terms-license.html

## 7. Proximo passo recomendado
1. Publicar estas paginas no GitHub Pages.
2. Cadastrar URL da politica no Play Console.
3. Implementar exclusao de conta no app antes da revisao final.
