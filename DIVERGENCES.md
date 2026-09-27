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
- **Resolução no código:** [showToolbarActionsMenu](Zforge/ContentView.swift) consome a mesma matriz/handler de D-05, mantendo Quick Look, Informações, Tag desabilitada, Renomear, Duplicar e Compartilhar no overflow aplicável. **Confirmação:** o usuário informou que D-06 está OK. [Task ZF-06](TASKS.md).

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
- **Evidência:** build Debug macOS aprovada; suíte `ZforgeTests` aprovada; teste de UI com fixtures confirmou que o preview de `Welcome.txt` na primeira coluna é mais largo que o de `Inside.txt` após abrir `Sample.zip`, e que a segunda largura respeita 320 pt. Falta conferência visual com os arquivos das capturas e arraste do divisor em janela estreita.

## Pontos ainda não classificados como divergência

- A correção da janela aberta pelo Finder em C-06 integra o commit `d23e1f7` da branch `main`; a build e a abertura manual foram relatadas naquela conversa, mas não repetidas nesta revisão.
- As conversas antigas incluem muitos bugs de preview, sidebar, drag and drop e Colunas. O código atual contém mecanismos dirigidos a eles; esta revisão estática não reproduziu cada cenário. Falha de execução futura deve gerar divergência específica com passo de reprodução, versão e evidência.
- Direção de distribuição (MIT para código original, 7-Zip sob suas licenças, versão gratuita no site e paga na Mac App Store) é um objetivo em [PRODUCT-REQUIREMENTS.md](Documentation/Requirements/PRODUCT-REQUIREMENTS.md), não uma entrega pronta. Assinatura final, notarização, obrigações de fonte correspondente e revisão jurídica não foram auditadas nesta tarefa documental.
