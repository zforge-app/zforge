---
title: "SwiftUI guidance for Zforge"
synthesized_at: "2026-07-16"
scope: "Cross-cutting synthesis of the captured Apple Developer contexts"
authority: "Derived from primary Apple sources; verify details in linked contexts"
---

# Princípios SwiftUI para o Zforge

Este documento é uma síntese operacional. Os contextos linkados preservam a origem primária, a data e a disponibilidade; eles prevalecem quando for necessário decidir um detalhe de API.

## Modelo mental

- Declarar o aplicativo como uma composição de `App`, cenas e hierarquias de `View`. Uma view descreve o que deve aparecer para um estado, e o framework reconcilia as partes afetadas quando os dados mudam. Consulte [SwiftUI](contexts/swiftui.md), [App](contexts/swiftui-app.md), [App organization](contexts/swiftui-app-organization.md) e [View fundamentals](contexts/swiftui-view-fundamentals.md).
- Preferir composição a controle imperativo: combinar views, containers e modificadores; criar views ou modificadores próprios quando um padrão realmente se repete. Consulte [View configuration](contexts/swiftui-view-configuration.md) e [View styles](contexts/swiftui-view-styles.md).
- Tratar identidade, estado e dependências como parte do desenho da hierarquia. Evitar transformar `body` em um controlador de fluxo ou em local para trabalho pesado.

## Dados e atualização da interface

- Manter uma única fonte de verdade para cada dado. Usar estado local para UI transitória, bindings para acesso mutável a um valor pertencente a outra fonte, modelos observáveis para estado de domínio e environment para dependências compartilhadas pela hierarquia. Consulte [Model data](contexts/swiftui-model-data.md) e [Environment values](contexts/swiftui-environment-values.md).
- Escolher a ferramenta de menor alcance que resolva o problema. Estado global ou environment excessivo esconde dependências e amplia atualizações.
- Deixar a mudança de dados dirigir a atualização visual. Efeitos colaterais devem estar ligados a eventos, tarefas ou ciclos de vida explícitos, com cancelamento e isolamento apropriados.

## Composição, layout e navegação

- Começar por stacks, grids, listas, tabelas, scroll views e containers de navegação do sistema. Eles respondem a conteúdo e dimensões variáveis; recorrer a ajustes finos e layouts customizados somente depois. Consulte [Layout fundamentals](contexts/swiftui-layout-fundamentals.md), [Layout adjustments](contexts/swiftui-layout-adjustments.md) e [Custom layout](contexts/swiftui-custom-layout.md).
- No macOS, projetar desde o início para janelas redimensionáveis, teclado, foco, menus, comandos, toolbars, seleção, drag and drop e múltiplas janelas. Consulte [Windows](contexts/swiftui-windows.md), [Navigation](contexts/swiftui-navigation.md), [Toolbars](contexts/swiftui-toolbars.md), [Menus and commands](contexts/swiftui-menus-and-commands.md), [Focus](contexts/swiftui-focus.md) e [Drag and drop](contexts/swiftui-drag-and-drop.md).
- Usar a adaptação do sistema como padrão. Uma inferência operacional para o Zforge é evitar geometria fixa quando um container nativo já expressa a relação desejada.

## macOS e integração com AppKit

- Priorizar componentes SwiftUI nativos disponíveis no macOS e o comportamento definido no `UI-UX-GUIDE.md`. A semântica funcional pode ser multiplataforma, mas a interação final precisa pertencer ao Mac.
- Usar AppKit como ponte deliberada quando SwiftUI não expuser uma capacidade necessária. `NSViewRepresentable` e `NSViewControllerRepresentable` trazem AppKit para a hierarquia SwiftUI; hosting views e controllers fazem o caminho inverso. Consulte [AppKit integration](contexts/swiftui-appkit-integration.md) e [AppKit](contexts/appkit.md).
- Não introduzir uma ponte AppKit apenas por familiaridade. Ela acrescenta sincronização de estado, ciclo de vida, sizing e acessibilidade que precisam ser testados.

## Liquid Glass e componentes do sistema

- Primeiro compilar com o Xcode e SDK atuais e observar o aplicativo nos sistemas atuais. Componentes padrão de SwiftUI e AppKit recebem automaticamente grande parte da aparência contemporânea. Consulte [Adopting Liquid Glass](contexts/technologyoverviews-adopting-liquid-glass.md).
- Tratar o material como uma camada funcional para controles, navegação, menus, toolbars, janelas, modais e busca; não como decoração aplicada indiscriminadamente ao conteúdo.
- Adicionar efeitos explícitos apenas quando uma view customizada realmente precisar participar desse sistema visual. Preservar legibilidade, contraste, hierarquia, acessibilidade e performance.
- Para o Zforge, o `UI-UX-GUIDE.md` continua sendo a autoridade da composição visual e restringe efeitos explícitos a situações funcionais apropriadas.

## Acessibilidade e localização

- Considerar acessibilidade como estrutura, não acabamento: semântica, aparência legível, controles acionáveis, descrições úteis e navegação precisam acompanhar a hierarquia desde o início. Consulte [Accessibility fundamentals](contexts/swiftui-accessibility-fundamentals.md) e as coleções locais de aparência, controles, descrições e navegação.
- Componentes do sistema fornecem uma base melhor, mas não eliminam validação com VoiceOver, teclado, contraste, tamanhos de conteúdo e estados reduzidos de movimento ou transparência.
- Manter textos visíveis e rótulos acessíveis localizáveis pelo String Catalog, sem concatenar fragmentos que impeçam uma tradução natural.

## Previews, medição e performance

- Usar macros de preview para iterar views em estados, tamanhos e contextos representativos; previews aceleram feedback, mas não substituem testes no aplicativo real. Consulte [Previews in Xcode](contexts/swiftui-previews-in-xcode.md).
- Medir antes de otimizar. Instruments ajuda a localizar hangs, hitches, atualizações longas de `body` e invalidações frequentes. Consulte [Performance analysis](contexts/swiftui-performance-analysis.md).
- Evitar trabalho síncrono custoso no caminho de renderização e reduzir dependências de estado amplas que invalidem partes desnecessárias da árvore.

## Hierarquia de evidência

1. Contexto local capturado, quando recente e aplicável à plataforma alvo.
2. Página oficial Apple Developer incorporada ao corpus pelo protocolo incremental.
3. SDK e Xcode locais para assinatura, disponibilidade e comportamento de compilação.
4. Experimento mínimo ou teste no Zforge para comportamento que a documentação não determine completamente.

Quando essas evidências divergirem, registrar a versão, a plataforma e a incerteza em vez de generalizar.

