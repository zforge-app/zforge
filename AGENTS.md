# Zforge — instruções para agentes

## Leitura obrigatória

- Começar pelo índice de [`Documentation/AGENTS.md`](Documentation/AGENTS.md) e pelo índice de requisitos em [`Documentation/Requirements/AGENTS.md`](Documentation/Requirements/AGENTS.md).
- Consultar [`Documentation/Requirements/CURRENT-STATE.md`](Documentation/Requirements/CURRENT-STATE.md) antes de alterar uma funcionalidade. Ele é a fonte de verdade versionada para o comportamento implementado e esperado agora.
- Consultar [`Documentation/Requirements/UI-UX-GUIDE.md`](Documentation/Requirements/UI-UX-GUIDE.md) antes de criar ou mudar interfaces, fluxos ou interações.
- Consultar [`Documentation/Requirements/PRODUCT-REQUIREMENTS.md`](Documentation/Requirements/PRODUCT-REQUIREMENTS.md) para visão de produto, plataforma, motor, licenciamento, distribuição e requisitos do marco inicial. As passagens do marco somente leitura são históricas quando contradizem o estado atual.
- Consultar [`Documentation/Requirements/OPEN-REQUIREMENTS.md`](Documentation/Requirements/OPEN-REQUIREMENTS.md) para requisitos e decisões ainda pendentes; propostas ali não alteram o comportamento implementado.
- Consultar [`Documentation/Requirements/DOCUMENTATION-REQUIREMENTS.md`](Documentation/Requirements/DOCUMENTATION-REQUIREMENTS.md) ao manter a fonte local de SwiftUI e APIs macOS.
- Consultar [`TASKS.md`](TASKS.md) para o trabalho rastreado, [`DIVERGENCES.md`](DIVERGENCES.md) para conflitos e regressões, e [`REGRESSION-COVERAGE.md`](REGRESSION-COVERAGE.md) para cobertura dos contratos. Uma intenção futura ou divergência não redefine o estado atual por si só.

## Manutenção contínua dos contratos

- Em **toda interação do agente com este projeto**, conferir os documentos de requisitos pertinentes e mantê-los atualizados na mesma interação. Registrar imediatamente requisitos novos ou refinados, decisões, mudanças de comportamento e evidência nova. Se a interação não trouxer mudança de requisito ou estado, preservar o conteúdo sem edição artificial.
- Ao implementar ou corrigir uma funcionalidade, atualizar o contrato correspondente em `Documentation/Requirements` junto com o código; sincronizar `TASKS.md`, `DIVERGENCES.md` e `REGRESSION-COVERAGE.md` quando o estado, a divergência ou a cobertura mudar.
- Distinguir explicitamente comportamento implementado, requisito planejado, nota histórica e verificação pendente. Não declarar uma função pronta com base apenas em plano, build ou inspeção estática. Em conflito, seguir a instrução direta do usuário; para o comportamento existente, usar `Documentation/Requirements/CURRENT-STATE.md` até que a mudança seja implementada e documentada.
- Antes de concluir uma alteração, conferir os fluxos adjacentes que compartilham estado ou handler, especialmente os quatro modos, seleção múltipla, menus, toolbar, teclado, preview, localização e redimensionamento. Em refatorações, caracterizar os contratos afetados antes da extração e registrar os limites da validação.

## Fontes técnicas e referências

- Para SwiftUI e APIs macOS, seguir [`Documentation/SwiftUI/AGENTS.md`](Documentation/SwiftUI/AGENTS.md), começar pelo [`INDEX.md`](Documentation/SwiftUI/INDEX.md) e pesquisar o corpus local antes de recorrer à web. A política de captura e expansão está nesse `AGENTS.md` especializado.
- Os projetos irmãos `../UIDemo`, `../7z2602-mac` e `../7zip` são referências de UI, binários macOS e código-fonte oficial do 7-Zip. Consultá-los quando útil; não modificá-los sem pedido explícito.
- Preservar tecnologia e interação nativas do macOS, localização de toda string visível no String Catalog, acesso a arquivos por autorização apropriada, isolamento do motor 7-Zip e os demais requisitos detalhados nos documentos indexados acima.
