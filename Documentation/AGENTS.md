# Zforge — índice de Documentation

Este diretório reúne os requisitos versionados do Zforge e a documentação técnica local usada para implementá-los. As instruções gerais para o agente estão em [`../AGENTS.md`](../AGENTS.md).

## Requisitos do projeto

1. [`Requirements/AGENTS.md`](Requirements/AGENTS.md) — índice dos documentos de requisito, precedência e rotina de manutenção. Ler primeiro ao trabalhar em requisitos ou funcionalidade.
2. [`Requirements/CURRENT-STATE.md`](Requirements/CURRENT-STATE.md) — contratos observáveis já implementados, pontos de código e limites de evidência; fonte de verdade do comportamento vigente.
3. [`Requirements/UI-UX-GUIDE.md`](Requirements/UI-UX-GUIDE.md) — especificação de interface, interação, responsividade e acessibilidade; notas de protótipo são subordinadas ao estado vigente.
4. [`Requirements/PRODUCT-REQUIREMENTS.md`](Requirements/PRODUCT-REQUIREMENTS.md) — visão de produto, plataforma, 7-Zip, segurança, licenciamento, distribuição e requisitos do marco inicial, com status explicitado no próprio documento.
5. [`Requirements/OPEN-REQUIREMENTS.md`](Requirements/OPEN-REQUIREMENTS.md) — requisitos e decisões ainda abertos, separados do comportamento implementado.
6. [`Requirements/DOCUMENTATION-REQUIREMENTS.md`](Requirements/DOCUMENTATION-REQUIREMENTS.md) — requisitos da fonte local de documentação SwiftUI e macOS.

## Documentação técnica SwiftUI

- [`SwiftUI/AGENTS.md`](SwiftUI/AGENTS.md) — regras próprias de consulta, atualização incremental e proveniência do corpus Apple.
- [`SwiftUI/INDEX.md`](SwiftUI/INDEX.md) — mapa dos contextos locais; [`SwiftUI/GUIDANCE.md`](SwiftUI/GUIDANCE.md) sintetiza decisões amplas.
- [`SwiftUI/README.md`](SwiftUI/README.md) — estrutura do corpus; `SwiftUI/contexts/` contém contextos primários, `SwiftUI/metadata/` registra capturas, assets e blocos de código, e `SwiftUI/tools/` guarda ferramentas de manutenção.

## Rastreamento relacionado fora de Documentation

- [`../TASKS.md`](../TASKS.md) — atividades e decisões pendentes.
- [`../DIVERGENCES.md`](../DIVERGENCES.md) — diferenças entre pedidos, documentos e comportamento observado.
- [`../REGRESSION-COVERAGE.md`](../REGRESSION-COVERAGE.md) — matriz de contratos, testes e verificações manuais.

Em cada interação, consultar os requisitos afetados e atualizar seus contratos quando houver informação nova. Mudanças de estado das atividades e divergências devem ser refletidas nos documentos de rastreamento correspondentes na mesma interação.
