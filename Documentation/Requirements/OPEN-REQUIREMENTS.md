# Zforge — requisitos e decisões ainda abertos

Este documento mantém requisitos que ainda dependem de decisão, implementação ou verificação. Ele não altera o contrato vigente de [`CURRENT-STATE.md`](CURRENT-STATE.md). O andamento pertence a [`../../TASKS.md`](../../TASKS.md), e a evidência das diferenças pertence a [`../../DIVERGENCES.md`](../../DIVERGENCES.md).

| ID | Requisito ou decisão pendente | Estado e origem |
| --- | --- | --- |
| OR-02 | Conferir visualmente em inglês e português do Brasil os tamanhos formatados em Lista, preview/resumo e aviso de preview grande com idioma do app diferente do macOS. | A formatação explícita por locale está implementada; D-11. |
| OR-03 | Conferir a ação principal da toolbar e os destinos padrão de compressão/extração em Recentes, incluindo seleção de arquivos em pastas diferentes. | Regra decidida pelo usuário e implementada; execução real ainda pendente; D-12. |
| OR-04 | Conferir visualmente a primeira coluna à esquerda, a largura dinâmica do primeiro preview, a estabilidade da faixa terminal ao alternar pasta/arquivo, o recálculo após rolagem manual à esquerda e o overflow depois de arrastar os divisores. | Testes de UI confirmaram a geometria anterior e o ciclo da ZF-15 com mínimo de 240 pt, usando fixtures. Faltam conferência visual com os arquivos das capturas, divisor de coluna e arraste do preview em janela estreita; D-13 e D-15 a D-17. |
| OR-06 | Escolher e finalizar o novo ícone com Z, referência a archives e metalurgia; preparar as camadas e variantes necessárias para uso no macOS 27. | O usuário pediu uma imagem por vez e confirmou a direção da prensa cilíndrica do candidato 18. O candidato 19 é sua versão estilizada para avaliação como ícone de aplicação. Aprovação final, camadas e integração ao app pendentes; candidatos indexados em `Documentation/Design/IconCandidates/README.md`; ZF-19 e D-18. |
| OR-07 | Conferir o fluxo visual de “Add to Archive…” e do drop sobre archives e pastas internas nas quatro visualizações, incluindo confirmação/cancelamento, archive criptografado e refresh da sessão aberta. | Código e teste de atualização real de ZIP/7z implementados na ZF-18; gesto e diálogo ainda não foram exercitados manualmente. |
| OR-08 | Conferir o refinamento de `Compress Custom…` em uso real. | O topo agora usa uma linha larga para cada item (`Save As`, `Tags`, `Where`) e o seletor de perfil alcança a borda direita da grade. A folha própria preserva a escolha de pasta por `NSOpenPanel`, pois o `NSSavePanel` não documenta reposicionamento dos campos internos. A build e o teste de UI passaram também após uniformizar as margens laterais em 20 pt; conferir ainda criação real em pasta escolhida, tags, localização, tema claro, janela estreita e combinações de formato/senha. |
| OR-10 | Implementar e validar a integração estática do backend nativo do 7-Zip. | Linkagem estática confirmada pelo usuário em 2026-10-02. O [plano da ZF-21](SEVENZIP-STATIC-INTEGRATION-PLAN.md) adota execução no processo do app e ponte Objective-C++; build universal, retenção de handlers em Release, operações reais, acesso autorizado, assinatura e materiais de relinkagem permanecem pendentes. XPC não integra o escopo da primeira implementação. |

OR-01 foi reconciliado em [`UI-UX-GUIDE.md`](UI-UX-GUIDE.md). OR-05 já constava no commit `d23e1f7` da branch `main`; a entrega distribuída não foi verificada nesta interação.

## Como manter

- Quando uma decisão for tomada, atualizar primeiro o requisito e o contrato aplicável; depois ajustar `TASKS.md` e `DIVERGENCES.md` na mesma interação.
- Quando uma implementação for concluída, mover seu comportamento observável para `CURRENT-STATE.md` e registrar a cobertura em [`../../REGRESSION-COVERAGE.md`](../../REGRESSION-COVERAGE.md). Remover desta lista apenas o que estiver resolvido ou explicitamente descartado, mantendo a rastreabilidade pela task/divergência.
- Não transformar estas propostas em comportamento atual por inferência. Requisitos de estratégia de longo prazo permanecem em [`PRODUCT-REQUIREMENTS.md`](PRODUCT-REQUIREMENTS.md).
