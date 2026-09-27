# Zforge — requisitos e decisões ainda abertos

Este documento mantém requisitos que ainda dependem de decisão, implementação ou verificação. Ele não altera o contrato vigente de [`CURRENT-STATE.md`](CURRENT-STATE.md). O andamento pertence a [`../../TASKS.md`](../../TASKS.md), e a evidência das diferenças pertence a [`../../DIVERGENCES.md`](../../DIVERGENCES.md).

| ID | Requisito ou decisão pendente | Estado e origem |
| --- | --- | --- |
| OR-02 | Conferir visualmente em inglês e português do Brasil os tamanhos formatados em Lista, preview/resumo e aviso de preview grande com idioma do app diferente do macOS. | A formatação explícita por locale está implementada; D-11. |
| OR-03 | Conferir a ação principal da toolbar e os destinos padrão de compressão/extração em Recentes, incluindo seleção de arquivos em pastas diferentes. | Regra decidida pelo usuário e implementada; execução real ainda pendente; D-12. |
| OR-04 | Conferir visualmente a primeira coluna à esquerda, a largura dinâmica do primeiro preview, a estabilidade da faixa terminal ao alternar pasta/arquivo, o recálculo após rolagem manual à esquerda e o overflow depois de arrastar os divisores. | Testes de UI confirmaram a geometria anterior e o ciclo da ZF-15 com mínimo de 240 pt, usando fixtures. Faltam conferência visual com os arquivos das capturas, divisor de coluna e arraste do preview em janela estreita; D-13 e D-15 a D-17. |

OR-01 foi reconciliado em [`UI-UX-GUIDE.md`](UI-UX-GUIDE.md). OR-05 já constava no commit `d23e1f7` da branch `main`; a entrega distribuída não foi verificada nesta interação.

## Como manter

- Quando uma decisão for tomada, atualizar primeiro o requisito e o contrato aplicável; depois ajustar `TASKS.md` e `DIVERGENCES.md` na mesma interação.
- Quando uma implementação for concluída, mover seu comportamento observável para `CURRENT-STATE.md` e registrar a cobertura em [`../../REGRESSION-COVERAGE.md`](../../REGRESSION-COVERAGE.md). Remover desta lista apenas o que estiver resolvido ou explicitamente descartado, mantendo a rastreabilidade pela task/divergência.
- Não transformar estas propostas em comportamento atual por inferência. Requisitos de estratégia de longo prazo permanecem em [`PRODUCT-REQUIREMENTS.md`](PRODUCT-REQUIREMENTS.md).
