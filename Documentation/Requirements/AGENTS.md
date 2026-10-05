# Zforge — índice e manutenção dos requisitos

Este diretório é a localização dos requisitos do projeto. Começar por este índice e abrir os documentos relacionados à funcionalidade em questão. [`../../AGENTS.md`](../../AGENTS.md) contém as instruções gerais do agente; [`../AGENTS.md`](../AGENTS.md) indexa toda a documentação.

## Documentos de requisito

| Documento | Autoridade e conteúdo |
| --- | --- |
| [`CURRENT-STATE.md`](CURRENT-STATE.md) | Fonte de verdade para os contratos observáveis implementados, sua evidência e os pontos de código. Consultar antes de alterar qualquer funcionalidade. |
| [`UI-UX-GUIDE.md`](UI-UX-GUIDE.md) | Requisitos de apresentação, interação nativa, teclado, responsividade e acessibilidade. As notas de protótipo identificadas em `DIVERGENCES.md` não substituem o contrato vigente. |
| [`PRODUCT-REQUIREMENTS.md`](PRODUCT-REQUIREMENTS.md) | Visão, plataforma, segurança, integração 7-Zip, licenças, distribuição e direção funcional. Identifica como histórico o primeiro marco somente leitura e como planejadas as etapas futuras. |
| [`OPEN-REQUIREMENTS.md`](OPEN-REQUIREMENTS.md) | Requisitos e decisões ainda pendentes, com vínculo às tasks e divergências. Não redefine funcionalidades prontas. |
| [`DOCUMENTATION-REQUIREMENTS.md`](DOCUMENTATION-REQUIREMENTS.md) | Requisitos de cobertura, indexação, proveniência e atualização do corpus local SwiftUI/macOS. |
| [`SEVENZIP-STATIC-INTEGRATION-PLAN.md`](SEVENZIP-STATIC-INTEGRATION-PLAN.md) | Plano da ZF-21: build estática do 7-Zip, adaptador nativo, migração, validação e distribuição. Backend implementado; evidências e verificações restantes estão registradas no plano e na matriz de regressão. |
| [`ARCHIVE-DRAG-DROP-PLAN.md`](ARCHIVE-DRAG-DROP-PLAN.md) | Plano vigente da ZF-30: paridade visual com itens locais, confirmação por teclado, saída e reorganização dentro do próprio archive. Implementação e testes de regressão registrados; limites de validação separados. |

## Precedência e atualização

1. A instrução direta do usuário prevalece. Quando implementada, registrar a nova regra no documento de requisito adequado nesta mesma interação.
2. Para o comportamento já existente, `CURRENT-STATE.md` prevalece sobre uma intenção futura ou uma nota de protótipo. `UI-UX-GUIDE.md` orienta alterações visuais e de interação onde não houver conflito com o contrato vigente.
3. A direção planejada permanece em `PRODUCT-REQUIREMENTS.md`; decisões e correções abertas ficam em `OPEN-REQUIREMENTS.md`. O estado de execução fica em [`../../TASKS.md`](../../TASKS.md). Conflitos e regressões ficam em [`../../DIVERGENCES.md`](../../DIVERGENCES.md), separados da fonte de verdade.
4. Em **toda interação com o projeto**, revisar os contratos pertinentes e mantê-los atualizados. Registrar requisitos, decisões, correções e evidência nova na mesma mudança. Atualizar [`../../REGRESSION-COVERAGE.md`](../../REGRESSION-COVERAGE.md) ao mudar ou caracterizar um contrato. Não criar edições sem mudança real nem converter uma proposta em funcionalidade entregue.
5. Manter links relativos válidos ao mover documentos. Referenciar o código a partir deste diretório com `../../Zforge/`, `../../ZforgeTests/` ou `../../ZforgeUITests/`.
