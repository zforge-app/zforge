# Zforge — divergências entre pedidos, documentação e estado atual

Levantamento iniciado em **2026-09-23**, com caminhos documentais atualizados em **2026-09-24**. Comparação feita por inspeção estática do workspace, `AGENTS.md`, `Documentation/Requirements/UI-UX-GUIDE.md` e conversas anteriores do Zforge. A fonte de verdade para o comportamento existente é [`Documentation/Requirements/CURRENT-STATE.md`](Documentation/Requirements/CURRENT-STATE.md); este arquivo guarda problemas, lacunas e conflitos **fora** dela. “Pedido” não significa implementação concluída. Um problema relatado por captura é distinguido de uma causa comprovada por código.

## Proveniência das conversas consultadas

| Referência | Conversa local | Temas relevantes |
| --- | --- | --- |
| C-01 | 2026-07-12, sessão `019f57f8-d04a-7ca0-a0f7-ddb0cba82cd9` | Direção inicial, navegador, quatro views, seleção, previews, toolbar, archives. |
| C-02 | 2026-07-14, sessão `019f62c6-d43f-7b62-a17b-db76a2065fca` | Lista, toolbar, largura/overflow e preview por modo. |
| C-03 | 2026-07-16, sessão `019f6d28-b864-76e2-ad11-4200a0f6cfab` | Recentes, Home, breadcrumb, menus de overflow e sidebar. |
| C-04 | 2026-07-17, sessão `019f7311-e825-7ca1-be74-c32db5ad2049` | Clipboard, operações de arquivos, drag and drop, undo, atalhos, localização. |
| C-05 | 2026-07-22, sessão `019f8c16-383c-7481-9553-504297119de6` | Ícones, compressão/extração, Colunas, progresso e preview. |
| C-06 | 2026-09-22, tarefa `01a0cb8a-3ed8-7483-ad2b-dd4bd8c8e365` | Abertura pelo Finder; correção incorporada no commit `d23e1f7`. |
| C-07 | 2026-09-22, esta tarefa `01a0cb78-741d-79b3-a28f-682b568067c5` | Ícone do app, larguras, zoom, duplicações em Recentes, matriz de menus e rastreamento. |
| C-08 | 2026-07-16, sessão `019f6af6-e52b-7520-92d6-c28f3b103f6c` | Toolbar, título, foco e decisão de documentação SwiftUI local. |
| C-09 | 2026-07-16, sessão `019f6d4b-fbb1-7913-aa64-481bd88c05fa` | Criação do corpus local SwiftUI e orientação no `AGENTS.md`. |

Os identificadores permitem localizar o pedido original no histórico local. O conteúdo de outras conversas não é instrução operacional por si só; as decisões vigentes são as instruções diretas do usuário e o contrato consolidado no repositório.

## Divergências de produto ou regressões

### D-01 — Ícone da aplicação ausente na execução pelo Xcode (resolvido; confirmado pelo usuário)

- **Pedido:** criar e usar um novo ícone; o usuário relata que um ícone anterior não aparece (C-07).
- **Novo relato:** após a primeira correção, o usuário informou que o ícone não aparecia na build executada pelo Xcode. A build existente no DerivedData já continha `AppIcon.icns`, `Assets.car` e chaves de ícone no plist; o Finder mostrou visualmente o ícone nesse bundle. Portanto, a ausência do recurso no bundle não foi reproduzida.
- **Resolução no código:** além das dez entradas PNG de [AppIcon.appiconset/Contents.json](Zforge/Assets.xcassets/AppIcon.appiconset/Contents.json), [Info.plist](Zforge/Info.plist) declara explicitamente `CFBundleIconFile` e `CFBundleIconName`, e [AppDelegate.swift](Zforge/AppDelegate.swift) atribui `AppIcon.icns` a `NSApplication.applicationIconImage` na inicialização. O Finder mostrou o ícone também na nova build. **Confirmação:** o usuário informou que o ícone está OK. A causa exata do relato original não foi comprovada. [Task ZF-02](TASKS.md).

### D-02 — Redimensionamento das colunas perdido (corrigido e exercitado no app)

- **Pedido:** arrastar as linhas/divisórias para alterar larguras; o usuário informa que isso já funcionou antes (C-07).
- **Novo relato:** após a primeira correção, o usuário informou que o arraste ainda não funcionava. A alça anterior tinha apenas 10 pt invisíveis e não comunicava a ação com o cursor; o gesto exigia acertar uma faixa estreita.
- **Resolução no código:** as alças de Lista e Colunas usam uma `NSView` de 20 pt com cursor horizontal de redimensionamento e captura nativa do arraste; as larguras persistem nas preferências, com mínimos e máximos. A área terminal de Colunas usa a largura ajustável do preview, inicialmente 300 pt. Na build anterior, o arraste foi exercitado manualmente em Lista e Colunas e moveu as divisórias. [Task ZF-03](TASKS.md).

### D-03 — Escala implementada, atalhos de zoom ausentes (resolvido; confirmado pelo usuário)

- **Pedido:** `⌘+`/`⌘−` como no Finder (C-07). O [UI-UX-GUIDE.md](Documentation/Requirements/UI-UX-GUIDE.md) também especifica `⌘=` como equivalente de aumentar, `⌘0` para 100% e passos de 10% entre 70% e 160%.
- **Resolução no código:** comandos `⌘+`, `⌘=`, `⌘−` e `⌘0` alteram a escala persistida em passos de 10%, dentro de 70–160%, e aparecem na ajuda de atalhos. **Confirmação:** o usuário informou que o zoom está OK. [Task ZF-04](TASKS.md).

### D-04 — Recentes mostra cópias de trabalho como itens repetidos (corrigido)

- **Pedido/observação:** capturas de 2026-09-22 e 2026-09-24 mostram `Archive.7z` repetido em Recentes (C-07). A segunda regressão foi reproduzida na interface.
- **Causa identificada no fluxo:** o motor copia cada archive aberto para `temporaryDirectory/Zforge/ArchiveSessions/<UUID>`. Essas cópias têm o nome e a data do original, mas caminhos e identidades físicas novos; a deduplicação por caminho/inode não as excluía. A origem de cada linha específica da captura não foi inspecionada, mas o fluxo de staging e o teste com cópias reais reproduzem essa lacuna.
- **Resolução:** [RecentItemsService.swift](Zforge/Services/RecentItemsService.swift) ignora todo `temporaryDirectory/Zforge` antes de contar os 250 resultados. [FileBrowserState.swift](Zforge/State/FileBrowserState.swift) aplica a mesma regra antes de publicar a lista, mesmo com outro provedor de Recentes. [ZforgeTemporaryStorage.swift](Zforge/Services/ZforgeTemporaryStorage.swift) compartilha o caminho com o motor. Arquivos originais distintos com metadados iguais permanecem separados. As suítes unitária e de UI passaram; a build corrigida com Spotlight real mostrou uma única entrada `Archive.7z`. [Task ZF-05](TASKS.md).

### D-05 — Menu de clique secundário não segue a matriz solicitada (resolvido; confirmado pelo usuário)

- **Pedido:** para um arquivo comum, Abrir/Comprimir/Comprimir customizado; para um archive, Abrir/Extrair aqui/Extrair para pasta de mesmo nome/Extrair/Validar; para vários archives, somar opções de arquivo e de archive, com nomes das pastas de saída separados por vírgula; para seleção com arquivos comuns, usar opções de arquivo (C-07).
- **Resolução no código:** [BrowserItemActionsMenu](Zforge/Views/BrowserContentViews.swift) consulta a matriz compartilhada de [FileBrowserState.swift](Zforge/State/FileBrowserState.swift) e preserva seleção múltipla nas novas operações. Um archive oferece três destinos de extração e validação por `7zz t`; vários archives também oferecem compressão. Opções anteriores permanecem. Abrir vários archives cria janelas dedicadas; validação múltipla é sequencial. **Confirmação:** o usuário informou que D-05 está OK. [Task ZF-06](TASKS.md).

### D-06 — Botão `•••` da toolbar não oferece as mesmas opções contextuais (resolvido; confirmado pelo usuário)

- **Pedido:** as opções da matriz de D-05 também devem aparecer no botão de reticências mostrado na captura, preservando o comportamento já existente (C-07).
- **Resolução no código:** [showToolbarActionsMenu](Zforge/ContentView.swift) consome a mesma matriz/handler de D-05, mantendo Quick Look, Informações, Tags (habilitada para seleção local desde 2026-10-03), Renomear, Duplicar e Compartilhar no overflow aplicável. **Confirmação:** o usuário informou que D-06 está OK. [Task ZF-06](TASKS.md).

## Divergências entre documentos antigos e comportamento vigente

### D-07 — O marco somente leitura ficou histórico

- **Origem:** o plano inicial de julho de 2026 previa navegador somente leitura (C-01 e seção “Marco funcional: navegador somente leitura” de [PRODUCT-REQUIREMENTS.md](Documentation/Requirements/PRODUCT-REQUIREMENTS.md)).
- **Pedido posterior/estado:** C-04 e C-05 pediram e receberam criar pasta, renomear, copiar, mover, aliases, Lixo, exclusão permanente, compressão e extração. Essas operações existem em [FileBrowserState.swift](Zforge/State/FileBrowserState.swift) e [FileOperationService.swift](Zforge/Services/FileOperationService.swift).
- **Resolução documental:** [AGENTS.md](AGENTS.md), [PRODUCT-REQUIREMENTS.md](Documentation/Requirements/PRODUCT-REQUIREMENTS.md) e [CURRENT-STATE.md](Documentation/Requirements/CURRENT-STATE.md) tratam o recorte somente leitura como marco passado. Não remover as salvaguardas de acesso, senha, sandbox e licenças que continuam relevantes.

### D-08 — Largura do preview em Colunas (reconciliada e ampliada)

- **Origem:** [UI-UX-GUIDE.md](Documentation/Requirements/UI-UX-GUIDE.md) especificava 420 pt em Colunas, enquanto o comportamento posterior usava 300 pt em todos os modos.
- **Decisão atual do usuário:** 300 pt permanece a largura inicial, mas o divisor do preview deve permitir arraste.
- **Resolução:** o guia e [PRODUCT-REQUIREMENTS.md](Documentation/Requirements/PRODUCT-REQUIREMENTS.md) agora descrevem largura comum ajustável entre 180 e 800 pt. [FileBrowserPreferences.swift](Zforge/Models/FileBrowserPreferences.swift) persiste a largura; Ícones, Lista, Colunas e Galeria a compartilham. Em Colunas, a próxima coluna que substitui o preview usa e ajusta essa mesma largura. O gesto foi exercitado manualmente nos quatro modos. O alinhamento horizontal observado em Colunas ficou registrado em D-13. [Task ZF-07](TASKS.md).
- **Atualização em 2026-09-27:** a regra comum para Colunas foi substituída pelo pedido D-15; Ícones, Lista e Galeria continuam com a preferência persistida. O parágrafo anterior registra o estado da ZF-07, não o contrato atual.

### D-09 — Seta esquerda no nível raiz da Lista (reconciliada)

- **Origem:** [UI-UX-GUIDE.md](Documentation/Requirements/UI-UX-GUIDE.md), seção 13, diz “no nível raiz, voltar ao diretório anterior”.
- **Pedido posterior/estado:** [PRODUCT-REQUIREMENTS.md](Documentation/Requirements/PRODUCT-REQUIREMENTS.md) diz que itens raiz não reagem à seta esquerda. [moveListSelectionLeft](Zforge/State/FileBrowserState.swift) retorna sem ação no nível raiz.
- **Confirmação do usuário:** o comportamento implementado já funciona como esperado. [UI-UX-GUIDE.md](Documentation/Requirements/UI-UX-GUIDE.md) foi atualizado para dizer que a seta esquerda não age no nível raiz. Nenhuma mudança de código foi necessária.

### D-10 — O guia de UI/UX misturava especificação atual e notas de protótipo (reconciliada)

- **Origem:** [UI-UX-GUIDE.md](Documentation/Requirements/UI-UX-GUIDE.md) ainda menciona `ExampleFiles` do protótipo e propõe separações arquiteturais que o Zforge já realiza em parte; também descreve `AppStorage` para idioma, enquanto o código persiste via `UserDefaults` em [FileBrowserPreferences.swift](Zforge/Models/FileBrowserPreferences.swift).
- **Estado:** essas linhas não representam, por si, defeito funcional. São instruções antigas ou detalhes de implementação que podem desviar um agente da base atual.
- **Resolução documental:** o guia agora descreve os serviços reais, `FileBrowserPreferences`/`UserDefaults`, os componentes existentes e as operações reais, preservando as regras visuais aplicáveis. `CURRENT-STATE.md` continua sendo o contrato vigente.

### D-11 — Unidade de tamanhos e idioma da apresentação (implementada; conferência visual pendente)

- **Pedido:** limites de archive descritos como 1–5 **GB** (C-01, agora em `Documentation/Requirements/PRODUCT-REQUIREMENTS.md`) e strings/dados visíveis coerentes com o idioma selecionado (C-05, mesmo documento).
- **Pesquisa:** a [Apple](https://support.apple.com/en-us/102119) define 1 GB de armazenamento como 1.000.000.000 bytes e informa que a representação binária de GB era usada por sistemas antigos. A [documentação de `ByteCountFormatter.CountStyle`](https://developer.apple.com/documentation/foundation/bytecountformatter/countstyle-swift.enum) descreve `.file` como decimal no macOS e `.memory` como binário; no Foundation local, `.file` exibiu 1.000.000.000 bytes como “1 GB” e 1.073.741.824 bytes como “1,07 GB”.
- **Decisão aplicada:** o rótulo simples `GB` foi mantido e o limite de navegação de archives usa agora 1.000.000.000 bytes por GB, inclusive no valor padrão e no teto de 5 GB. Os limites de segurança independentes de materialização continuam em base binária. [FileBrowserPreferences.swift](Zforge/Models/FileBrowserPreferences.swift), [BrowserModels.swift](Zforge/Models/BrowserModels.swift).
- **Correção no código:** os tamanhos da Lista, do resumo/preview e do aviso de preview grande passam por `AppLocalization.byteCount`, com `ByteCountFormatStyle(style: .file, locale:)` e o idioma escolhido. O SDK macOS 27.0 local declara a propriedade `locale` dessa API; a aparência nos dois idiomas ainda precisa de conferência visual. A captura da página de `ByteCountFormatter` no corpus local SwiftUI ficou pendente porque a tentativa anterior de acesso direto a `developer.apple.com` falhou por DNS; o link oficial permanece externo.

### D-12 — Ação contextual de archive em Recentes (implementada; conferência visual pendente)

- **Pedido:** [PRODUCT-REQUIREMENTS.md](Documentation/Requirements/PRODUCT-REQUIREMENTS.md) define, fora de archive, extrair se a seleção contém somente archives e comprimir quando há arquivo comum; a nova matriz de menus de C-07 não exclui Recentes.
- **Decisão do usuário:** em Recentes, o destino padrão é a pasta real onde está o objeto da operação. Para extração em lote, cada archive usa seu próprio diretório; para compactação conjunta de origens diferentes, usa-se o diretório do item ativo. Sem item ativo, a primeira origem em ordem de caminho define o destino.
- **Correção no código:** a ação principal analisa a seleção também em Recentes; extração padrão, “Extrair aqui”, “Extrair…”, compressão padrão e customizada usam a regra acima. A inspeção visual e a execução real dessas operações ainda estão pendentes.

### D-13 — Alinhamento horizontal em Colunas (corrigido; arraste de coluna ainda requer conferência visual)

- **Contrato:** [PRODUCT-REQUIREMENTS.md](Documentation/Requirements/PRODUCT-REQUIREMENTS.md) pede que a coluna ativa termine uma largura de preview antes da borda direita.
- **Observação:** na execução manual da ZF-07, quando havia apenas a coluna ativa e o preview numa janela larga, a área terminal manteve a largura ajustada, mas terminou antes da borda da janela, deixando espaço vazio à direita. O arraste funcionou; o alinhamento do conjunto não corresponde ao contrato em todos os tamanhos de janela.
- **Regressão observada pelo usuário em 2026-09-24:** alinhar todo o conjunto à direita deslocou a primeira coluna para longe da borda esquerda; a captura mostra um vazio grande entre a sidebar e a primeira coluna.
- **Correção no código:** quando o conjunto cabe na janela, a primeira coluna absorve a largura livre. Ela começa na borda esquerda, mantém a próxima coluna ou preview adjacente e deixa a área terminal na borda direita. Quando não cabe, preserva as larguras ajustadas e o scroll horizontal. Uma build assinada com fixtures mostrou o resultado em janela larga com pasta/archive e preview de arquivo; o arraste do divisor do preview deslocou visualmente a borda. Falta conferir o divisor de coluna e o overflow em janela estreita.
- **Atualização em 2026-09-27:** a regra de absorção pela primeira coluna foi substituída por D-15. Cada coluna de navegação mantém sua largura base; o preview carregado usa a sobra à direita. A conferência do divisor de coluna e do overflow continua em OR-04.

### D-14 — Preview de HTML preso em carregamento (corrigido e conferido em build de teste)

- **Relato de 2026-09-27:** ao selecionar `tempo.html` em Documentos, o Finder mostra o layout estático da página, enquanto o Zforge permanece no indicador de carregamento do preview embutido. As capturas do usuário demonstram a diferença; a causa interna exata do Quick Look não foi diagnosticada.
- **Correção:** o hero de seleção simples encaminha `.html` e `.htm` para `WKWebView.loadFileURL(_:allowingReadAccessTo:)`, dando acesso à pasta do documento para CSS e recursos locais relativos. JavaScript do documento fica desativado. A view web anterior para de carregar e é removida quando a URL muda ou o preview é desmontado; os outros tipos mantêm seus caminhos atuais. `com.apple.security.network.client` foi adicionado ao sandbox do app para permitir a inicialização dos processos auxiliares do WebKit e carregar recursos externos referenciados pelo HTML.
- **Evidência:** `HTMLPreviewTests` passou carregando HTML com CSS relativo sem executar um script inline, trocando arquivo e renderizando no layout real do inspector. Numa build de teste assinada sem o entitlement de rede, até HTML mínimo deixou a área vazia e os logs mostraram encerramento dos processos WebKit; com o entitlement, uma cópia exata de `tempo.html` exibiu o layout estático em Ícones, Lista, Colunas e Galeria. Após desativar scripts, a build final de teste assinada exibiu o mesmo HTML na Lista e na Galeria, e um arquivo de prova mostrou o texto inicial intacto. Teste direto no Finder: um HTML local com imagem HTTP única causou requisição ao servidor local tanto na Galeria quanto no painel Quick Look; um HTML local com script inline manteve o texto inicial e não fez a requisição `fetch` em ambos os previews. A build de distribuição ainda não foi verificada. [Task ZF-12](TASKS.md).

### D-15 — Largura inicial fixa do preview em Colunas (corrigida no código e em teste de UI)

- **Relato de 2026-09-27:** a largura global persistida era carregada em novos previews e reservava espaço fixo à direita, deslocando as colunas à esquerda. As capturas comparam Zforge e Finder em caminhos rasos e profundos.
- **Decisão do usuário:** ao carregar cada preview, usar a largura disponível à direita das colunas abertas, com mínimo de 320 pt e sem máximo. Uma mudança no espaço disponível antes do preview seguinte deve alterar sua largura inicial.
- **Correção:** Colunas mantém as larguras de navegação e só insere o preview quando elegível. A largura do preview fica local à seleção; o divisor ajusta apenas o preview atual. O `SelectionOverview` deixa de impor a preferência global internamente. Ícones, Lista e Galeria preservam a largura compartilhada. `BrowserColumnsLayout` calcula o mínimo e a sobra disponível. [Task ZF-13](TASKS.md).
- **Evidência:** o usuário confirmou que o problema foi resolvido. Build Debug macOS aprovada; suíte `ZforgeTests` aprovada; teste de UI com fixtures confirmou que o preview de `Welcome.txt` na primeira coluna é mais largo que o de `Inside.txt` após abrir `Sample.zip`, e que a segunda largura respeita 320 pt. Falta conferência visual com os arquivos das capturas e arraste do divisor em janela estreita.

### D-16 — Oscilação do alinhamento entre coluna expandida e preview (corrigida no código e em teste de UI)

- **Relato de 2026-09-27:** após a correção D-15, navegar de arquivo para pasta e voltar a arquivo recalculava a largura terminal a cada seleção, deslocando a divisória horizontalmente. O vídeo e a sequência de três capturas do Finder mostram o preview inicial dinâmico, a pasta aberta à direita e o preview seguinte ocupando a mesma faixa da coluna filha.
- **Decisão do usuário:** ao abrir uma pasta/archive, a coluna nova deve ficar inteiramente visível; ao voltar para um arquivo da coluna anterior, o preview deve ocupar a mesma posição e largura. O cálculo dinâmico anterior à expansão e o mínimo de 320 pt permanecem.
- **Correção:** Colunas registra os níveis que abriram uma coluna filha, dimensiona a coluna terminal pela faixa final e usa essa mesma faixa para o preview seguinte naquele nível. Enquanto a abertura da pasta/archive ou o carregamento do arquivo estiver pendente, reserva a largura correspondente sem exibir conteúdo obsoleto. O preview oculto conserva as larguras base das colunas. [Task ZF-14](TASKS.md).
- **Evidência:** `ZforgeTests` passou; teste de UI assinado com `Welcome.txt → Sample.zip → Welcome.txt` confirmou largura e ambas as bordas iguais entre a coluna terminal e o preview substituto. O teste de UI anterior da largura dinâmica também passou após a mudança. Ainda falta conferir a fluidez visual em navegação rápida com os arquivos das capturas e os gestos dos divisores.

### D-17 — Preview não se reajusta após rolagem manual à esquerda (corrigido no código e em teste de UI)

- **Relato de 2026-09-27:** nas oito capturas, o preview inicial cabe na sobra à direita; abrir uma pasta expande a coluna terminal e o preview seguinte ocupa essa faixa. Depois de rolar manualmente à esquerda para exibir a coluna inteira, o preview largo fica cortado, como desejado. Selecionar outro arquivo, porém, volta a alinhar o conjunto à direita e mantém a largura expandida, em vez de ajustar o novo preview à sobra visível.
- **Decisão do usuário:** reduzir o mínimo do preview em Colunas para 240 pt. A rolagem manual não altera o preview atual; a próxima seleção de arquivo recalcula sua largura e preserva o enquadramento à esquerda. Uma pasta/archive selecionada depois volta a expandir a coluna terminal e alinha o conjunto à direita.
- **Correção:** observar fase e distância da rolagem horizontal para diferenciar deslocamento manual da rolagem programática. Enquanto a vista estiver afastada manualmente da borda direita, a próxima seleção de arquivo usa novamente a largura disponível e não solicita rolagem terminal. O próximo diretório restaura essa rolagem. O mínimo fica em `BrowserColumnsLayout.minimumPreviewWidth`; Ícones, Lista e Galeria conservam sua largura própria. [Task ZF-15](TASKS.md).
- **Evidência:** a rodada final passou com 85 testes unitários e quatro testes de UI assinados, incluindo os dois anteriores de Colunas, o novo ciclo de rolagem e o de Recentes afetado pela fixture. O ciclo percorreu arquivo → archive → arquivo → rolagem horizontal manual → outro arquivo → archive, confirmando as geometrias finais pedidas. As capturas reais e o arraste do divisor permanecem para inspeção visual.

### D-18 — Integração do ícone de metalurgia concluída; conferência visual aberta

- **Pedido posterior:** o ícone deve reunir um Z, referência ao papel de archiver e referência à metalurgia, em linguagem visual compatível com macOS 27. O usuário rejeitou a primeira prancha de 16 alternativas.
- **Estado atual:** o arquivo [`Zforge/zforge_icon.icon`](Zforge/zforge_icon.icon/icon.json), exportado pelo usuário no Icon Composer, foi integrado em Debug e Release. A build Debug assinada gerou `zforge_icon.icns` e `Assets.car`, e a prévia extraída do `.icns` mostra o Z prensado. A inspeção em Finder/Dock e das aparências claro, escuro e mono ainda está aberta. As notas abaixo preservam a cronologia anterior à integração. [ZF-19](TASKS.md), [OR-06](Documentation/Requirements/OPEN-REQUIREMENTS.md).
- **Refinamento posterior:** o usuário indicou elementos aproveitáveis em 02, 03, 04, 06, 07, 12 e 15, além de 16 para a direção do zíper. Foram geradas duas novas pranchas de 16 alternativas ([bigorna e martelo](Documentation/Design/Zforge-icon-concepts-anvil-hammer-16.png) e [zíper diagonal com laranja](Documentation/Design/Zforge-icon-concepts-diagonal-zipper-16.png)) e [um estudo de prensa](Documentation/Design/Zforge-icon-concept-press-07.png) para 07. A escolha final permanece pendente.
- **Exploração seguinte:** foram geradas quatro pranchas de 16 variações a partir dos números escolhidos pelo usuário: [bigorna/martelo](Documentation/Design/Zforge-icon-refinement-anvil-02-04-08.png), [zíper](Documentation/Design/Zforge-icon-refinement-zipper-01-03-12-14-16.png), [prensa](Documentation/Design/Zforge-icon-refinement-press-16.png) e [emblema gráfico](Documentation/Design/Zforge-icon-refinement-graphic-03-04-10.png). A “quarta imagem” foi interpretada como [esta prancha](Documentation/Design/Zforge-icon-source-graphic-fourth-16.png), exibida em quarto lugar na rodada anterior, com abordagens gráficas e tridimensionais. Nenhum asset do app foi substituído.
- **Seleção mais recente:** o usuário escolheu 02 da prancha de bigorna/martelo, 07/09/15 da prensa e 01/02/09/12 dos emblemas. Duas novas pranchas de 16 alternativas registram [uma síntese próxima](Documentation/Design/Zforge-icon-synthesis-selected-close-16.png) e [uma síntese com arranjos novos](Documentation/Design/Zforge-icon-synthesis-selected-hybrid-16.png). A decisão do asset final permanece aberta.
- **Método de exploração refinado:** o usuário informou que as pranchas resultam em qualidade inferior e pediu imagens individuais. Foram gerados [16 candidatos separados](Documentation/Design/IconCandidates/README.md), sem nova prancha. O candidato 07 foi refinado apenas na paleta, mantendo a primeira versão preservada em `Drafts`. O ícone usado pelo app ainda não foi substituído.
- **Referências físicas novas:** o usuário apontou inconsistências nas prensas anteriores e forneceu uma fotografia de prensa hidráulica e uma imagem de pastas de escritório coloridas. O [candidato 17](Documentation/Design/IconCandidates/17-hydraulic-press-folders-z.png) mostra pistão e platôs alinhados, com pastas deitadas e apoiadas entre eles e um Z no travessão superior, mas sua estrutura em H foi rejeitada; o asset instalado permanece o anterior.
- **Correção do estilo da prensa:** o usuário rejeitou a estrutura em H do candidato 17 e reiterou que cada rodada deve trazer somente uma imagem bem trabalhada. O [candidato 18](Documentation/Design/IconCandidates/18-hydraulic-cylinder-folders-z.png) usa cilindro amarelo e preto, pistão central e discos circulares alinhados com as pastas, seguindo a fotografia. O usuário confirmou essa direção; nenhum asset do app foi substituído.
- **Estilização:** o usuário confirmou que o candidato 18 segue a direção desejada e pediu uma versão apta a funcionar como ícone. O [candidato 19](Documentation/Design/IconCandidates/19-stylized-hydraulic-cylinder-folders-z.png) preserva o mecanismo e reduz a complexidade visual; o usuário posteriormente indicou ajustes de bordas, Z e fundo. O ícone instalado não mudou.
- **Refinamento de bordas, Z e fundo:** o usuário pediu que o topo e a base alcançassem as bordas da imagem, que o Z tivesse tridimensionalidade de futura camada, e rejeitou o fundo verde do candidato 19. O [candidato 20](Documentation/Design/IconCandidates/20-press-edge-to-edge-raised-z.png) aplica essas mudanças em PNG com alfa confirmado; não há ainda arquivo em camadas nem aprovação para substituir o asset do app.
- **Correção de materiais:** no candidato 20, o usuário identificou pastas com aparência de borracha e forma inadequada à perspectiva, além de metal pouco realista nos dois discos. O [candidato 21](Documentation/Design/IconCandidates/21-cardstock-folders-machined-steel.png) refaz as pastas como cartão dobrado com abas e bordas de papel e reforça o acabamento de aço usinado. Aguarda avaliação; o asset do app não mudou.
- **Novas referências de pastas:** duas imagens de pastas coloridas foram fornecidas sem instrução textual. O [candidato 22](Documentation/Design/IconCandidates/22-folder-reference-refinement.png) interpreta-as como referência de capas, abas e papéis internos, mantendo a pilha deitada entre os discos. A direção foi substituída pelo pedido posterior de um armário; o asset do app não mudou.
- **Armário no lugar das pastas:** após ver referências de outros archivers, o usuário pediu substituir a pilha por um armário de documentos. O [candidato 23](Documentation/Design/IconCandidates/23-hydraulic-press-filing-cabinet.png) usa um armário de duas gavetas entre os discos; o usuário depois solicitou maior altura e nova posição do Z. Não substitui o asset do app.
- **Altura e posição do Z:** o usuário pediu aumentar o armário do candidato 23, subir a parte superior da prensa e mover o Z para fora do cilindro. O [candidato 24](Documentation/Design/IconCandidates/24-tall-filing-cabinet-z-on-platen.png) usa três gavetas, prensa elevada e Z na face frontal do platô superior. Aguarda avaliação; o asset do app não mudou.
- **Retorno ao Z prensado:** o usuário descartou o armário como objeto entre os discos e pediu o próprio Z sendo prensado. O [candidato 25](Documentation/Design/IconCandidates/25-pressed-metal-z.png) explora um Z de metal entre os platôs; permanece pendente de avaliação e não altera o asset instalado.
- **Corte no Icon Composer:** a captura do usuário mostrou que o candidato 25 ficou cortado na composição. O [candidato 26](Documentation/Design/IconCandidates/26-pressed-z-icon-composer-framing.png) afasta a vista, encurta a parte superior e mantém margens transparentes. O resultado ainda depende de conferência no Icon Composer; o asset instalado não mudou.
- **Base até a borda:** o usuário marcou a margem vazia sob a base numa versão intermediária. O [candidato 27](Documentation/Design/IconCandidates/27-pressed-z-extended-base.png) prolonga o metal inferior até a borda da imagem; ainda precisa de conferência no Icon Composer e não altera o asset instalado.
- **Legibilidade e modo mono:** três capturas do Icon Composer mostram a composição detalhada nos modos claro, escuro e mono. O usuário pediu menos poluição visual e uma versão mono própria. O [candidato 28 colorido](Documentation/Design/IconCandidates/28-simplified-press-z-color.png) simplifica a prensa e o Z; a [versão mono](Documentation/Design/IconCandidates/28-simplified-press-z-mono.png) usa geometria branca plana. Ambos foram vistos em miniatura de 64 px, mas ainda não foram conferidos no Icon Composer; o asset instalado não mudou.
- **Ajuste das bordas e do centro:** o usuário marcou na versão colorida do candidato 28 a tampa lisa acima das listras, a margem abaixo da base e o Z baixo. O [candidato 29](Documentation/Design/IconCandidates/29-simplified-press-z-edge-crop.png) faz o cilindro listrado e a base alcançarem as bordas e sobe a zona de prensagem; avaliação no Icon Composer pendente, sem mudança no asset instalado.
- **Vista mais afastada:** sobre o candidato 29, o usuário pediu afastar a câmera. O [candidato 30](Documentation/Design/IconCandidates/30-simplified-press-z-distant.png) reduz a escala aparente dos platôs e do Z, aumentando as margens laterais sem perder a continuidade vertical do cilindro e da base; avaliação no Icon Composer pendente, sem mudança no asset instalado.
- **Separação em camadas:** o usuário pediu duas ou três camadas que preservem a composição do candidato 30. O [plano](Documentation/Design/IconCandidates/31-layer-plan.md) define três peças na ordem base, Z e cabeçote. A extração por ImageGen alterou escala e posição das peças, então ainda não há PNGs alinhados; o asset instalado não mudou.
- **Exportação e integração posteriores:** o usuário forneceu um `.icon` montado no Icon Composer, com três imagens em dois grupos, e pediu sua aplicação ao Zforge. O arquivo foi colocado na raiz do alvo, as configurações de build e o plist passaram a apontar para `zforge_icon`, e foi removida a atribuição manual do antigo `AppIcon.icns` na inicialização. O teste de bundle foi atualizado; o resultado visual em uso ainda precisa ser observado.

### D-19 — Extensão exibida ao trocar o formato no painel customizado (aberta)

- **Observação em 2026-09-28:** na build de teste com fixtures, trocar o formato do painel `Compress Custom…` de 7z para ZIP atualizou os controles e a altura, mas o campo `Save As` continuou mostrando `Welcome.7z`. O código calcula a extensão final a partir do formato escolhido após o painel, portanto a divergência observada é entre o nome exibido e o destino que o código pretende criar; a criação real não foi executada nesta conferência.
- **Próximo passo:** atualizar o nome sugerido no painel ao trocar de formato sem descartar um nome editado pelo usuário, e validar a URL criada para formatos simples e streams com camada TAR.

## Pontos ainda não classificados como divergência

- A correção da janela aberta pelo Finder em C-06 integra o commit `d23e1f7` da branch `main`; a build e a abertura manual foram relatadas naquela conversa, mas não repetidas nesta revisão.
- As conversas antigas incluem muitos bugs de preview, sidebar, drag and drop e Colunas. O código atual contém mecanismos dirigidos a eles; esta revisão estática não reproduziu cada cenário. Falha de execução futura deve gerar divergência específica com passo de reprodução, versão e evidência.
- Direção de distribuição (MIT para código original, 7-Zip sob suas licenças, versão gratuita no site e paga na Mac App Store) é um objetivo em [PRODUCT-REQUIREMENTS.md](Documentation/Requirements/PRODUCT-REQUIREMENTS.md), não uma entrega pronta. Assinatura final, notarização, obrigações de fonte correspondente e revisão jurídica não foram auditadas nesta tarefa documental.

### D-20 — Build e filtro global de tags após a reversão

**Corrigido no código e exercitado no app em 2026-10-02.** A reversão incompleta mantinha consumidores da API de colunas removida em `ContentView`; as definições e consumidores foram recuperados juntos. A busca de tags dependia exclusivamente de uma consulta Spotlight que retornava zero no sandbox da build assinada. O catálogo agora combina Spotlight com leitura real em segundo plano dos diretórios autorizados e FSEvents; o filtro valida as tags atuais, incluindo pastas, e a leitura individual remove o cache de recursos da URL. A linha inteira da sidebar recebe o clique. Foram conferidos filtro real, descoberta fora da pasta atual e atualização sem refresh; a cobertura e os limites restantes constam em `REGRESSION-COVERAGE.md` e OR-09.

### D-21 — Extração nativa no container do app com sandbox

**Corrigido em 2026-10-03 durante a preparação do benchmark de RAM.** A build Release instrumentada criava, listava e testava ZIP, mas falhava ao extrair um arquivo de 256 MiB no próprio tmp do app. A ponte abria os componentes absolutos desde `/`; esse percurso pelos ancestrais do destino falhava no caminho do container. A correção recebe a raiz de destino autorizada, abre seu descritor diretamente e só percorre os descendentes com `openat`/`O_NOFOLLOW`, preservando a proteção de caminhos. O caso real passou após a correção e conferiu SHA-256. 109 testes da variante dinâmica passaram, incluindo recusa de saída fora da raiz. Isso não comprova PowerBox/bookmarks externos nem todos os estados de UI; a matriz completa de RAM será registrada separadamente.


### D-22 — Build estática bloqueada pelo sandbox de scripts do Xcode

**Corrigida no projeto em 2026-10-03.** O relato do usuário foi reproduzido no DerivedData padrão do Xcode: `Build SevenZipCore` falhava ao criar `SevenZip/Debug` com `Operation not permitted`. O perfil gerado permitia somente os caminhos literais declarados em `DERIVED_FILE_DIR`, sem autorizar seus descendentes; uma lista explícita de objetos ainda bloqueava os arquivos temporários do `libtool`. A fase agora usa `TARGET_TEMP_DIR/SevenZip`, sob a área de temporários que o perfil autoriza recursivamente, declara a biblioteca final como saída e mantém os caminhos de linkagem sincronizados em Debug/Release. `ENABLE_USER_SCRIPT_SANDBOXING` permanece habilitado; não houve mudança de backend ou de permissões do app. Evidência de build em `REGRESSION-COVERAGE.md`; ZF-21.

### D-23 — Tags somente para leitura

**Corrigido e confirmado pelo usuário em 2026-10-03; 116 testes unitários e 6 de UI aprovados no refinamento final, matriz visual ampla pendente.** O pedido adiciona definição/criação de tags pelo menu de contexto e ícone entre Share e reticências, além da cor das pastas. A folha compartilhada edita metadados Finder locais, preserva tags não editadas de cada item e atualiza catálogo/filtro. A primeira versão adotava a primeira tag colorida na ordem do nome; o refinamento abaixo usa a cor da frente na pilha invertida. A evidência executada está em `REGRESSION-COVERAGE.md`.

#### Refinamento de D-23 solicitado após teste do usuário

A primeira versão só oferecia o item que abria a folha, empilhava círculos da esquerda para a direita e recoloria a pasta inteira (inclusive papel). O refinamento implementa linha rápida de sete tags, check/hover +/x e Edit Tags com símbolo, pilha da direita para a esquerda e escolha da cor da frente. A recoloração passa a operar apenas no material azul, mantendo papel e detalhes neutros; a rasterização usa 512 px para não ampliar uma representação lógica de 32 pt. Cobertura e limites em `REGRESSION-COVERAGE.md`.
### D-24 — Feedback de arraste inconstante e ícone substituído na sidebar

Relato de 2026-10-03, com gravações do Zforge e Finder e captura da seleção monocromática. A sidebar alternava entre o fundo nativo da List e o contorno customizado; os destinos trocavam seus símbolos por pasta aberta. Também não representava o diretório atual com destaque próprio.

**Reproduções 18:56 e 19:47:** a primeira revisão retinha highlight e falhava no acabamento/fim de lista; a segunda, com delegate global, regrediu o pin e foi revertida a pedido do usuário. Nesta terceira revisão voltam os handlers por item, com bordas superior/inferior, seleção monocromática, símbolos estáveis e limpeza nativa por owner. Removida somente a entrada visível “Add Folder…”. Pin via menu foi exercitado com referência descartável; pin com o payload real de URL foi executado em teste. A estabilidade do gesto contínuo ainda não foi confirmada por automação; D-24 permanece com conferência visual pendente.

### D-25 — Drag automático na própria pasta cria cópia

Gravação de 19:47 mostra cópia de PDF com sufixo depois da extensão. Corrigido no código: exportar a URL original como `public.file-url`, e verificar a igualdade canônica do diretório pai antes da inferência de operação por volume. Automatic/move para o mesmo pai retornam os originais sem criar arquivos. Option/paste/Duplicate continuam copiando. Teste com arquivo/pasta e URLs alternativas/symlink aprovado; provider de bytes carregado por NSURL e pin no destino original aprovados. O vídeo demonstra a reprodução anterior; não foi tratado como execução da build corrigida.

**Retorno 20:11:** usuário confirma que a parte funcional foi resolvida (pin e regressão de cópia), mas o indicador é recortado. O overlay de cada célula desenhava metade do círculo para fora dos seus limites. Ajustado somente o desenho: camada nativa acima da clip view, ancorada à célula, sem hit testing; handlers por item preservados. Teste da hierarquia nativa e build aprovados; acabamento da nova build durante gesto ainda não conferido por automação.

**Refinamento visual 20:22 (D-24):** vídeo confirma melhoria do recorte, mas highlight da pasta atual ainda cobria parte da linha. Corrigida a composição: backing layer próprio do indicador com zPosition superior às camadas irmãs, inclusive após criação tardia de highlight. Espessura da linha passa a 2 pt por pedido do usuário. Teste da hierarquia/composição aprovado; conferência durante drag real da build nova permanece pendente.

**Refinamento do círculo em 2026-10-03:** usuário confirma melhoria da linha e pede um círculo proporcional. Diâmetro externo aumentado de 5 para 8 pt, contorno de 1 para 2 pt; centro vertical, início à esquerda e extremidade direita preservados. Conferência visual do novo tamanho durante drag pendente.

**Ajuste solicitado em 2026-10-03:** círculo do indicador ampliado para 12 pt de diâmetro externo; contorno e linha mantidos em 2 pt. Centro vertical e limites horizontais preservados.

**Escolha final em 2026-10-03:** por pedido do usuário, círculo retorna a 8 pt de diâmetro externo, com contorno e linha de 2 pt. O estudo de 12 pt é histórico.

### D-26 — Pasta interna com forma e cor diferentes da pasta nativa

- **Relato e decisão do usuário:** diretórios dentro de archives devem continuar distintos, mas preservar a pasta do sistema. A diferença deve ser um carimbo circular do Zforge em relevo, inferior direito em tamanho grande e centralizado quando pequeno.
- **Correção:** `FileIconView` usa a pasta nativa para diretórios `.archive`, com selo vetorial monocromático da identidade prensa/Z. O limite compacto é 32 pt, aplicado ao tamanho apresentado após zoom. Pastas locais mantêm o cache, a composição de conteúdo e a transição no drop.
- **Evidência:** build e suíte unitária aprovadas; renderização AppKit isolada conferida entre 16 e 190 pt. A matriz visual no app permanece em OR-13; ZF-29 e `REGRESSION-COVERAGE.md`.
- **Refinamento solicitado:** selo mais alto, maior em 48 pt e menor nos previews grandes; base com menos faixas. Implementados no compositor e exportados três estados e selo avulso em `Documentation/Design/ArchiveFolderStamp`. Os estados com arquivos/aberta são estudos para revisão; não alteram a determinação de conteúdo nem o drop de diretórios virtuais.
- **Decisão posterior:** forma v3 aprovada; o usuário considerou a composição anterior semelhante a uma imagem sobreposta e pediu fisicalidade com luz/sombra e **debossing**, como pasta prensada. Aperfeiçoamento planejado em `Documentation/Design/ArchiveFolderStamp/DEBOSSING-PLAN.md`; ainda não implementado.
- **Integração autorizada e implementada:** v6 aplicada ao componente compartilhado via `ArchiveFolderRelief`, fonte única de máscaras neutras de luz/sombra. Substitui a geometria simplificada e mantém a pasta nativa. Círculo contínuo recorta a prensa. Build, 110 testes unitários e renderização isolada conferidos; iluminação fixa da referência, sem renderizador de altura/luz dinâmica. Matriz visual ampla permanece em OR-13.
- **Pasta com arquivos:** o usuário rejeitou a versão aberta de estudo e pediu a pasta fechada com papel para diretórios internos que contêm arquivos, em todos os modos. Implementada com `archiveDirectoryContainsFiles` calculado da listagem uma vez; arquivos descendentes/ocultos/zero bytes contam, subpastas vazias sozinhas não. Faixa de papel larga atrás da face nativa, selo v6 preservado. API da pasta aberta rejeitada removida; pastas locais não foram alteradas.

- **Novo estudo solicitado:** pasta aberta durante o recebimento por arraste, seguindo nova referência nativa. Apenas criação visual nesta etapa; o usuário decidirá quando usar. Não reintroduzir automaticamente a antiga versão aberta rejeitada nem substituir o estado fechado com arquivos.

- **Integração posterior autorizada:** proposta aberta v7 aprovada. Aplicar pasta aberta com selo apenas a diretórios internos expandidos na Lista, na linha e no hero do preview. Recolher restaura a pasta fechada; outros modos não herdam a abertura. Implementado sobre o ícone nativo aberto `ofld`, mantendo o selo por máscaras. Drag and drop de itens dentro de archives registrado como pendente em OR-14/ZF-30; adição de arquivos locais existente não substitui esse requisito.

- **Regressão visual relatada na versão aberta integrada:** `ofld` apresentou textura/cor diferentes, base com faixas e cantos inconsistentes com a pasta fechada. Corrigido para usar o mesmo material da pasta fechada: face arredondada e selo rasterizados juntos e inclinados com amostragem bilinear, painel traseiro preservado, papel condicionado a arquivos e sombra de contato. A regra de expansão não mudou.

- **Correção pontual posterior:** removidas as duas sobras arredondadas da face fechada que vazavam atrás do papel na versão aberta. O fundo passa a desenhar somente o topo nativo e estender uma faixa intacta do painel traseiro, evitando reutilizar a face fechada nessa região. Face inclinada, selo, regras de expansão e estados de conteúdo preservados.

- **Correção da interpretação da seleção e perspectiva:** o usuário pediu retirar linhas, não recortar vazados no painel traseiro. A edição raster com recortes foi descartada e não chegou ao app. Removido o contorno cinza do papel na versão aberta; a base agora preserva a largura original do painel, enquanto somente o topo da face se alarga por estar mais próximo do observador.

- **Linhas traseiras ainda visíveis:** a retirada do stroke do papel não resolveu as linhas indicadas no azul. A faixa de bitmap estendida foi substituída por gradiente contínuo amostrado do material nativo por coluna; a cor da sombra externa não participa da amostragem e o canto traseiro continua arredondado. Perspectiva e selo preservados.

- **Pasta fechada cheia:** o usuário aprovou a correção aberta e apontou papel sobre a borda externa na versão fechada. O recorte horizontal de restauração da face terminava abaixo de sua borda superior. Substituído pelo recorte arredondado da face completa, fazendo a borda nativa cobrir o papel. Selo, material, estados de conteúdo e pasta aberta preservados.

- **Pasta aberta vazia:** a exportação revelou degrau na borda esquerda e gradiente retangular residual, oculto pelo papel no estado cheio. A amostragem por coluna ainda alcançava a face fechada. Substituída por amostras exclusivamente do material traseiro intacto, com transição suave desde o topo nativo e alfa antialias na borda. Painel vazio contínuo; face/selo/perspectiva preservados.

### D-27 — Diretórios locais usam o design anterior às correções de archives

- **Pedido de 2026-10-03:** reutilizar os ícones aprovados para diretórios internos, retirando o indicador de compressão.
- **Correção implementada:** composição compartilhada para diretórios locais comuns, nos estados fechado/aberto e vazio/com conteúdo, sem máscaras do selo. Retirados o compositor local antigo e o recurso `ofld`; papel atrás da borda, base e painel traseiro seguem a geometria refinada. Expansão na Lista atualiza linha e preview; drop local conserva a transição. Arquivos/packages continuam com ícones próprios do sistema; a detecção local de conteúdo mantém qualquer filho direto.
- **Verificação:** renderização e testes registrados em `REGRESSION-COVERAGE.md`; conferência ampla dos modos e interação de drop continua em OR-13.

### D-28 — Teste de seleção rápida em Colunas falha intermitentemente na suíte

- **Evidência anterior:** `rapidColumnArchiveSelectionPublishesOnlyCurrentArchive` falhou em `firstStarted` na suíte integrada (135 aprovados/1 falha) e passou isolado. Não há regressão funcional comprovada nem causa de agendamento estabelecida.
- **Correção do teste:** retirada a consulta repetida com pausas de 1 ms; espera por sinal explícito do motor simulado. Primeiro carregamento fica suspenso até cancelamento, sem conclusão automática após 2 s; segundo não usa atraso artificial. Timeout de 10 s detecta travamento real e falha fatal na preparação encerra o cenário. Sinais antecipados são lembrados; continuations e watchdogs são removidos no sinal, cancelamento, timeout ou encerramento.
- **Escopo:** apenas fixture/testes e cobertura documentada; nenhum handler de produção alterado. Verificação repetida em `REGRESSION-COVERAGE.md`; ZF-32.

### D-29 — Clique secundário no espaço vazio não abre o menu de reticências (corrigido; conferência pontual nos quatro modos)

- **Relato:** gravação de 2026-10-03 às 22:18:43, em Ícones, mostra a área vazia sem o menu esperado.
- **Causa identificada:** ponte nativa instalada somente nas células dos itens; fundos tinham apenas o gesto primário de limpar seleção.
- **Correção implementada:** menu de ações compartilhado com o botão `•••`; ponte de fundo nas áreas vazias dos quatro modos com prioridade dos menus de item. Evidência executada e limites em `REGRESSION-COVERAGE.md`.

### D-30 — Trocar visualização em uma janela altera todas (corrigido; validação em REGRESSION-COVERAGE)

- **Relato:** usuário forneceu a gravação `Screen Recording 2026-10-04 at 20.51.06.mov` e pediu independência por janela.
- **Causa:** modo ativo residia no singleton `FileBrowserPreferences.shared`, observado por todas as janelas.
- **Correção:** `FileBrowserState.viewMode` é inicializado pelo padrão persistido e passa a orientar apresentação, toolbar, menus, atalhos, seleção, metadados, preview, drop e reconciliação de Colunas somente naquela janela/aba. Settings mantém o modo padrão para futuras instâncias.
- **Evidência e limites:** ZF-34; testes e conferência da interface registrados em `REGRESSION-COVERAGE.md`.

### D-31 — Confirmar adição por drop não inicia a atualização do archive

- **Reprodução do usuário em 2026-10-04:** gravação mostra arquivo local solto numa pasta interna expandida de ZIP na Lista; “Modify Archive?” aparece, mas responder Adicionar não produz atualização visível.
- **Causa no código:** o setter de `archiveAdditionBinding` limpa `pendingArchiveAddition` ao fechar o diálogo. A `Task` criada pelo botão só depois consultava esse estado, encontrava `nil` e retornava sem chamar o motor. O menu/picker compartilhava o mesmo handler.
- **Correção implementada:** a closure de ações usa o pedido de `presenting` e o passa explicitamente a `confirmArchiveAddition(_:)`. A tarefa não depende do estado de apresentação; preservados o bloqueio de operação concorrente, cancelamento, senha, staging, cópia das origens e refresh de sessões.
- **Evidência e limite:** suíte unitária aprovada; quatro casos com ZIP/7z reais, raiz/pasta interna, simulam o binding já limpo e conferem conteúdo extraído, origem intacta, cancelamento sem escrita e nova sessão/breadcrumb. Tentativa de UI falhou antes de abrir o diálogo no gesto automatizado, sem validar o clique ou a correção visual. OR-07 continua aberta. Resultados em `REGRESSION-COVERAGE.md`.

### D-32 — Adição bem-sucedida recolhe a hierarquia do archive

- **Refinamento do usuário em 2026-10-04:** confirmou que a adição funciona após D-31, mas o interior que estava sendo visualizado fecha. Pediu reabrir o archive atualizado e expandir a hierarquia para mostrar a adição de forma transparente.
- **Correção implementada:** na Lista, registrar os caminhos internos expandidos antes de invalidar a sessão; purgar a árvore do archive alterado, reabrir na mesma linha e restaurar disclosures com os novos IDs. Expandir também o caminho até o destino e selecionar todos os itens adicionados. O mesmo restauro/revelação se aplica à raiz aberta. Archives não alterados conservam suas sessões e expansões.
- **Limites:** o restauro cobre diretórios do archive raiz, sem expandir automaticamente archives aninhados nem todos os descendentes. Nos demais modos, mantém-se o refresh à raiz existente; a nova seleção/revelação da árvore é própria da Lista. Cancelamento/erro de escrita não executam o restauro. Testes e conferência visual pendente em `REGRESSION-COVERAGE.md`/OR-07.

### D-33 — Itens internos não podem ser arrastados para fora nem excluídos

- **Pedido de 2026-10-04:** copiar/extrair por padrão; Option movimenta para fora recriando o archive sem os itens. Mostrar indicador de cópia no primeiro caso e removê-lo no segundo.
- **Implementado:** fonte AppKit comum aos quatro modos, identidade virtual nos destinos internos e file promises externos. Política explícita ignora a tradução padrão de Option na origem virtual. Exportações terminam antes da remoção nativa validada. Exclusão compartilha matriz contextual/overflow, menu File e confirmação por `⌘Delete`. Árvores renovadas reutilizam ZF-18; outros archives conservam sessões.
- **Limites:** escrita somente no ZIP/7z raiz de volume único; cópia para formatos de leitura/conteúdo aninhado. Reorganização dentro/entre archives planejada. Testes reais cobrem motor/coordenação; gesto/badge/Option/Finder continuam em OR-14.

- **Retorno do usuário nesta etapa:** exclusão pelo menu funciona; arrastar para fora não produz efeito. Remoção confirmada em uso, sem confirmação da saída por drag.
- **Correção do gesto/payload:** substituir monitor por reconhecimento síncrono de mouseDragged no host da janela; conservar identidade ao inicializar o provider pelo inicializador designado; publicar token como dado imediato, não como promessa. Cumprir promises individualmente sem aguardar o callback final, mantendo remoção condicionada ao sucesso de todas e à aceitação de movimento. Gesto sintético ainda não validou entrega: fonte iniciou em CUA, mas terminou com operação vazia. Validação e limites em REGRESSION-COVERAGE.

- **D-33, entrega no destino ainda reportada ausente:** usuário reiterou que arrastar não extrai na pasta onde soltou. Adicionados receptores NSDraggingDestination para pastas internas do app, declaração do tipo virtual no bundle e sessão associada ao reconhecedor no macOS 27 (fallback por evento no 26). O receptor lê a identidade diretamente e publica na pasta do drop, mantendo a transferência após o callback final. Testes verificam conteúdo/destino e copy/move; duas tentativas de UI não iniciaram por timeout de automação e CUA iniciou a fonte sem comprovar entrega. Divergência permanece aberta para gesto físico/Finder/indicador, sem declarar a saída por drag concluída.

### D-33 — retorno e escopo refinado em 2026-10-04

- **Confirmado pelo usuário:** exclusão contextual e badge de cópia que desaparece com Option. Isso supera a pendência de confirmação desses dois comportamentos na build exercitada, sem comprovar a operação.
- **Falhas reportadas:** arraste não extrai/move; preview usa ícone grande em vez da representação local do modo e nasce no topo da tela antes de chegar ao cursor. Evidência relatada junto às gravações `Screen Recording 2026-10-04 at 18.19.47.mov` e `...18.22.35.mov`; esta atualização documental não afirma uma nova inspeção dos vídeos.
- **Requisito adicional definido:** toda a apresentação replica drag local; movimentos avisam que o archive original será modificado e permitem Return/Enter para aprovar e Escape para cancelar. Dentro do próprio archive, sem Option move e Option copia, regravando o archive em ambos os casos. A antiga pendência de decidir reorganização no próprio archive foi substituída por este contrato; entre archives diferentes permanece separado.
- **Estado:** [plano atualizado](Documentation/Requirements/ARCHIVE-DRAG-DROP-PLAN.md); implementação/correção e validação de ponta a ponta pendentes. Nenhuma mudança de código nesta interação.

### D-33 — execução do plano e regressão congelada em 2026-10-04

- Fonte final compartilhada por locais/internos usa snapshot de célula/linha com frame no host da sessão, sem ícone fixo/posição zero. Monitor local captura mouseDragged e respeita disclosure/área visível. Receptores escolhem o destino mais específico, incluindo coluna/pasta/sidebar, pela geometria.
- Saída para pastas do Zforge comprovada por gesto real nos quatro modos. Movimento externo Return/Escape e reorganização interna sem Option mover/com Option copiar executados em UI, com expansão do destino. Testes reais de ZIP/7z protegidos congelam integridade, conflitos, ciclos, cancelamento, mudança concorrente e refresh em todos os modos.
- Diagnóstico do Finder: a promessa fornece autorização para a URL final, sem autorizar sibling staging no diretório. A extração/validação continua em staging próprio e a publicação externa escreve somente nessa URL; destinos internos mantêm staging/rename vizinho. Remoção ainda exige todas as publicações e aceitação final de movimento. Resultados finais e limites em REGRESSION-COVERAGE/OR-14.
- As tentativas com reconhecedor e `press(forDuration:thenDragTo:)` acima são históricas. Os testes de gesto atuais usam `click(forDuration:thenDragTo:)`, que emite eventos de mouse no macOS.

- **Resultado final:** saída por gesto em pastas do Zforge nos quatro modos, Finder e outra janela aprovada. Mover/copiar internamente e confirmação Return/Escape aprovados. 164 casos unitários/189 execuções passaram; oito casos UI passaram com uma repetição do teste de navegação. D-33 resolvida funcionalmente na matriz executada; OR-14 conserva acabamento visual amplo/Mesa/troca de Option em voo, sem reabrir requisitos internos já implementados.

### D-34 — Mutação de archive apaga histórico e esvazia colunas ancestrais (resolvido; confirmado pelo usuário)

- **Evidência do usuário em 2026-10-04:** vídeos de 22:02 (Ícones) e 22:09 (Lista) e captura de Colunas. Inspeção dos quadros confirma cópia interna concluída, retorno prematuro a Downloads e breadcrumbs ainda operantes; a imagem mostra colunas ancestrais vazias. Aplica-se aos quatro modos.
- **Causa:** `refreshUpdatedArchive` removia todas as entradas de Voltar/Avançar com a sessão antiga, recriava somente os breadcrumbs e limpava `columnItems`/`columnSelections`, recarregando apenas o destino final.
- **Correção implementada:** migrar histórico válido por caminho para os novos IDs, descartar apenas destinos removidos/aninhados invalidados, registrar a navegação ao revelar outra pasta e repopular os ancestrais/seleções das colunas. Adição conserva a pasta atual; diretório removido recua ao pai sobrevivente sem uma parada duplicada em Voltar. Outros archives mantêm seu estado.
- **Verificação:** testes novos reproduziram 26 execuções com falha antes da correção; rodada focada posterior aprovou 24 casos/63 execuções. Validação ampliada aprovada: 166 casos unitários/229 execuções e 3 casos UI, incluindo o gesto e Voltar/Avançar nos quatro modos. Duas falhas iniciais de UI por ausência de janela foram resolvidas no setup e repetidas com aprovação. D-34 resolvida na matriz executada; evidências em REGRESSION-COVERAGE. Incorporar por amend ao commit funcional conforme instrução do usuário.


### D-35 — Coluna filha pisca com uma cópia da lista do pai (corrigido; regressão temporal aprovada)

- **Relato/inspeção em 2026-10-04:** usuário confirma D-34 resolvido e fornece a gravação de 22:53:59 (6,23 s). Quadros a cada 1/30 s mostram a lista de Downloads duplicada na coluna do archive nas trocas de seleção em aproximadamente 2,57 s, 3,53 s e 4,23 s; cada ocorrência dura cerca de um quadro.
- **Causa reproduzida:** a navegação publica a localização filha antes da leitura assíncrona dos seus itens. Quando ainda não há `columnItems` do destino, `ColumnBrowserView` usava `sortedItems`, que ainda contém a lista do pai. O teste de UI com atraso controlado falhou exatamente por `Welcome.txt` aparecer na coluna de `Sample.zip` antes de carregar seu conteúdo.
- **Correção implementada:** renderizar somente `sortedColumnItems(at:)` de cada localização. Uma coluna sem cache próprio aguarda sem linhas; caches/seleções das colunas anteriores e regras de layout/preview continuam no mesmo fluxo.
- **Verificação:** regressão temporal de UI aprovada em archive → pasta → archive, com capturas pendentes/carregadas inspecionadas. 166 casos unitários/229 execuções e cinco casos UI distintos aprovados nas rodadas finais, incluindo navegação após mutação nos quatro modos e três casos de preview/layout. Falhas de setup e coordenada do teste corrigidas e repetidas; evidências/limites em REGRESSION-COVERAGE. Build assinada aprovada. ZF-36, incorporada por amend conforme pedido do usuário.


**Integração na main em 2026-10-05:** D-31–D-35 coexistem com D-29/D-30 sem colisão de IDs. Refresh/drag seguem o modo da janela; menus compartilhados preservados. Histórico nos quatro modos, ausência de linhas duplicadas na coluna pendente e fluxos adjacentes passaram na matriz integrada, registrada em `REGRESSION-COVERAGE.md`. Os limites visuais de OR-14 e de runtime macOS 26 continuam abertos.
