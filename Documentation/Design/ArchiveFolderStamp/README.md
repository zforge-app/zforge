# Selo de diretórios internos do Zforge

Refinamento v2, 2026-10-03. Os PNGs separados têm fundo transparente. `folder-states-v2.png` compara pasta comum, com arquivos e aberta com arquivos nos seis tamanhos; `zforge-stamp-v2.png` é o selo sozinho para revisão. Os estados com arquivos/aberta são estudos e não mudam a identificação de conteúdo de pastas internas no navegador. O ícone principal do app permanece o arquivo Icon Composer existente.

Renderização reproduzível, a partir da raiz do projeto, com serviços gráficos macOS disponíveis:

```sh
swiftc -module-cache-path /private/tmp/zforge-stamp-module-cache Zforge/Views/ArchiveFolderIconComposer.swift Documentation/Design/ArchiveFolderStamp/Render.swift -o /private/tmp/zforge-stamp-v2
/private/tmp/zforge-stamp-v2 Documentation/Design/ArchiveFolderStamp
```

## Estudo v3 — forma baseada no original mono

O usuário pediu separar o estudo da pasta e do embossing e aproximar o selo do ícone original na aparência mono. [Referência fornecida](reference-original-mono.png) e [novo estudo avulso](zforge-stamp-v3-original-mono.png). A nova forma preserva cilindro com faixas diagonais, pistão estreito, discos cilíndricos largos e Z espesso chanfrado, dentro de um círculo. O estudo raster apresenta relevo metálico mais pronunciado; não foi aplicado ao compositor vetorial nem ao app. A versão v2 e os arquivos de pasta foram preservados.

A forma v3 foi aprovada pelo usuário. O tratamento seguinte deve simular **debossing**, com depressão, luz e sombras internas no material da pasta. [Plano técnico e critérios](DEBOSSING-PLAN.md); [referência física](reference-debossing-paper.png). O compositor implementado ainda não recebeu essa técnica.

## Prévia v4 — debossing na pasta

[Prévia grande](folder-debossing-v4.png) gerada com ImageGen a partir da pasta v2, forma v3 aprovada e referência de papel prensado. A primeira geração ainda apresentava partes elevadas; o refinamento rebaixou Z e componentes da prensa, com sombras internas e luz nas bordas inferiores. Esta é uma proposta visual raster para revisão, não a saída do compositor do app nem prova de implementação do mapa de altura. Ainda sem conferência em tamanhos pequenos, estados com arquivos/aberta ou interface real. As versões anteriores permanecem preservadas.

## Refinamento v5 — volume preferido e cilindro até o círculo

O usuário preferiu visualmente a primeira composição volumétrica na pasta (`folder-preferred-volume-reference.png`), embora a v4 representasse debossing mais literal. A nova direção preserva esse volume, luz e sombra, com a cavidade circular integrada à pasta. [Estudo v5](folder-pressed-relief-v5.png): o cilindro superior com faixas foi prolongado até a borda interna superior do círculo, sem espaço vazio acima e sem ultrapassar a marca. Essa preferência prevalece sobre a leitura estritamente rebaixada de todos os componentes da v4. Estudo raster ainda sem integração; referências e versões anteriores preservadas.

## Refinamento v6 — círculo contínuo sobre a prensa

O usuário corrigiu o encontro superior: o círculo deve recortar a prensa e manter toda sua linha visível. [Estudo v6](folder-pressed-relief-v6.png) restaura o arco interno contínuo sobre o cilindro. O cilindro alcança a abertura, mas fica recortado dentro dela, sem cobrir a faixa do círculo. Estudo raster para revisão, sem integração; v5 preservada.

## Integração autorizada — v6

O usuário aprovou a v6 e pediu a implementação. Fonte de produção: `Zforge/Assets.xcassets/ArchiveFolderRelief.imageset/approved-relief.png`. `ArchiveFolderIconComposer.Relief` isola o selo e deriva máscaras neutras de luz/sombra comparando sua luminosidade ao gradiente intacto nas laterais. Isso conserva a forma e iluminação aprovadas sobre o material nativo, sem pintar o fundo azul nem manter um PNG por tamanho. O cálculo ocorre uma vez e a composição é cacheada por faixa. Iluminação fixa da referência; não há mapa de altura/luz dinâmica.

[Renderização da implementação](implemented-relief-states.png) conferida nos seis tamanhos e três estados. Para reproduzir fora do bundle, passar o caminho da referência como segundo argumento do renderizador:

```sh
/private/tmp/zforge-stamp-implemented /private/tmp/ZforgeApprovedReliefPreview Zforge/Assets.xcassets/ArchiveFolderRelief.imageset/approved-relief.png
```

Os estudos anteriores e o ícone principal do app foram preservados.

## Pasta fechada com arquivos — implementação

O usuário rejeitou a versão aberta de estudo. O compositor agora apresenta apenas estados fechados: [com arquivos](closed-folder-with-files-implemented.png) e [comparação com/sem arquivos nos seis tamanhos](closed-folders-implemented-states.png). A faixa de papel segue a referência de pasta fechada, atrás da face nativa, com o selo v6 preservado. `Render.swift` foi atualizado para esses dois estados; o arquivo `implemented-relief-states.png` e as pranchas anteriores permanecem registros históricos, incluindo a versão aberta rejeitada.

`archiveDirectoryContainsFiles` é fornecido pela listagem do motor para todas as views e previews; a classificação inclui qualquer arquivo descendente, inclusive oculto/zero bytes, mas não subpastas vazias sozinhas. Não há extração para determinar o ícone.

## Novo estudo de pasta aberta no arraste

Pedido de 2026-10-03: criar somente o ícone da pasta aberta como alvo de recebimento durante o arraste, com o material azul e selo aprovado. A referência nativa mostra a face dianteira inclinada para frente e papel no interior. Este estudo é separado da pasta fechada com arquivos já integrada e da antiga proposta aberta rejeitada. Aplicação e momento de uso dependem de instrução posterior do usuário.

[Proposta v7](open-folder-drop-study-v7.png), gerada com ImageGen integrado: imagem única com transparência, face dianteira inclinada e alargada no topo, documentos visíveis, sombras internas e selo circular prensa/Z na face inferior direita. Conferida visualmente como estudo; sem integração, mudanças no compositor, build ou novos testes.

Especificação do prompt: transformar a pasta fechada aprovada em alvo aberto de recebimento por arraste, usando a referência nativa; preservar azul/material, forma do selo e círculo contínuo, inclinar a face dianteira sutilmente, mostrar papel e sombra no interior, aplicar perspectiva coerente ao selo, gradientes suaves, fundo transparente, sem texto/UI ou variantes na mesma imagem.

## Integração da pasta expandida

A v7 foi aprovada para a linha de diretório interno expandido na Lista e o respectivo hero do preview (incluindo seleção múltipla). A produção usa `NSWorkspace` com OSType `ofld`, papel condicionado a `archiveDirectoryContainsFiles` e as máscaras v6 do selo; não usa o PNG completo da v7. Cache distingue escala, arquivos e expansão. Os outros modos mantêm pasta fechada. Drag and drop de itens internos não foi implementado e consta em OR-14/ZF-30.

## Correção do material da pasta aberta

O usuário rejeitou a implementação `ofld` por textura/cor, base e cantos inconsistentes. A versão corrigida usa exclusivamente a mesma pasta nativa fechada; recorta sua face arredondada, aplica o selo e inclina os dois juntos por reamostragem bilinear em 1024 px, com sombras de contato. Não usa o PNG de estudo como ícone inteiro. O antigo render está preservado como `open-folder-ofld-historical.png`; [novo render](open-folder-implemented.png) e [comparação](folder-expanded-implemented-states.png).

Refinamento posterior: removidas as duas sobras da face fechada ao lado do papel. A camada traseira usa somente o topo nativo e uma extensão da faixa intacta do painel traseiro. A exportação anterior foi preservada como `open-folder-before-side-cleanup.png`; o caminho `open-folder-implemented.png` contém a exportação atual.

## Perspectiva com base preservada e papel sem contorno

Refinamento do usuário: remover as linhas ao lado do papel, sem recortar o painel traseiro. A edição ImageGen que fez vazados não foi integrada. O compositor remove o stroke do papel na versão aberta e mantém a base na largura da pasta original; apenas o topo da face avança para fora. Exportação anterior preservada em `open-folder-before-perspective-fix.png`; `open-folder-implemented.png` é a saída atual do compositor.

## Linhas no painel traseiro

O usuário confirmou a perspectiva, mas ainda apontou linhas no azul ao lado do papel. A extensão de uma faixa de bitmap foi substituída por um gradiente contínuo rasterizado com as cores nativas, preservando alfa e canto arredondado e excluindo a sombra externa da amostragem de cor. `open-folder-before-rear-lines-fix.png` preserva o render anterior; exportação atual em `open-folder-implemented.png`.

## Pasta fechada: papel atrás da borda

Após aprovação do refinamento aberto, o usuário apontou que o papel cobria a borda superior da pasta fechada cheia. O recorte horizontal abaixo da borda foi substituído pelo recorte arredondado da face nativa completa. A nova exportação em `closed-folder-with-files-implemented.png` conserva a faixa de papel atrás da borda e o selo. Render anterior preservado em `closed-folder-before-lip-fix.png`.

## Pasta aberta vazia — exportação separada

A pedido do usuário, [versão aberta sem papel](open-empty-folder-implemented.png) exportada pelo mesmo compositor (`isOpen: true`, `containsFiles: false`), preservando perspectiva, material, sombra e selo. Esse estado já existia no compositor/cache e nos testes; nesta etapa foi criada somente a exportação separada para revisão, sem mudar o comportamento do app. `Render.swift` passa a exportar esse arquivo adicional.

Refinamento da pasta aberta vazia: removido degrau esquerdo e gradiente retangular residual. O painel usa cores do material traseiro acima da face fechada, interpolação contínua e transição suave com o topo nativo. Exportação anterior preservada em `open-empty-folder-before-panel-fix.png`; `open-empty-folder-implemented.png` contém a versão corrigida. O painel é compartilhado com a pasta aberta cheia.
