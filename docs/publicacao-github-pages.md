# Publicacao da Politica no GitHub Pages

## Objetivo
Publicar os arquivos HTML da pasta `docs/` para gerar uma URL publica que podera ser usada no Play Console.

## Arquivos que serao publicados
- `docs/index.html`
- `docs/privacy-policy.html`
- `docs/terms-license.html`

## Passo a passo no GitHub
1. Crie um repositorio no GitHub.
2. Envie este projeto para o repositorio.
3. Abra `Settings > Pages`.
4. Em `Build and deployment`:
   - `Source`: `Deploy from a branch`
   - `Branch`: `main` (ou `master`)
   - `Folder`: `/docs`
5. Clique em `Save`.
6. Aguarde a publicacao.

## URL esperada
Se o usuario do GitHub for `SEU_USUARIO` e o repositorio for `demanda_controller`, as URLs ficarao assim:

- Home legal:
  `https://SEU_USUARIO.github.io/demanda_controller/`
- Politica de privacidade:
  `https://SEU_USUARIO.github.io/demanda_controller/privacy-policy.html`
- Termos e licenca:
  `https://SEU_USUARIO.github.io/demanda_controller/terms-license.html`

## O que precisa aparecer no HTML da Politica de Privacidade
1. Nome do aplicativo.
2. Data da ultima atualizacao.
3. Quem e o responsavel pelo aplicativo.
4. E-mail de contato oficial.
5. Quais dados sao coletados.
6. Para que os dados sao usados.
7. Se ha compartilhamento com terceiros essenciais (ex.: Firebase/Google).
8. Como os dados sao armazenados e protegidos.
9. Como o usuario pode excluir conta e dados.
10. Informacao de que o app nao e destinado a criancas.

## O que precisa aparecer no HTML dos Termos e Licenca
1. Nome do aplicativo.
2. Data da ultima atualizacao.
3. Aceitacao dos termos.
4. Licenca de uso.
5. Restricoes de uso.
6. Responsabilidade do usuario com a conta.
7. Limite de responsabilidade.
8. Propriedade intelectual.
9. Encerramento/suspensao.
10. E-mail de contato.

## Observacao importante para a Play Store
A URL principal exigida normalmente e a da politica de privacidade. Os termos/licenca sao recomendados como reforco juridico.
