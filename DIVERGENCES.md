# Zforge — divergências entre pedidos, documentação e estado atual

Levantamento de **2026-09-23**. Comparação feita por inspeção estática do workspace, `AGENTS.md`, `UI-UX-GUIDE.md` e conversas anteriores do Zforge. A fonte de verdade para o comportamento existente é [`CURRENT-STATE.md`](CURRENT-STATE.md); este arquivo guarda problemas, lacunas e conflitos **fora** dela. “Pedido” não significa implementação concluída. Um problema relatado por captura é distinguido de uma causa comprovada por código.

## Proveniência das conversas consultadas

| Referência | Conversa local | Temas relevantes |
| --- | --- | --- |
| C-01 | 2026-07-12, sessão `019f57f8-d04a-7ca0-a0f7-ddb0cba82cd9` | Direção inicial, navegador, quatro views, seleção, previews, toolbar, archives. |
| C-02 | 2026-07-14, sessão `019f62c6-d43f-7b62-a17b-db76a2065fca` | Lista, toolbar, largura/overflow e preview por modo. |
| C-03 | 2026-07-16, sessão `019f6d28-b864-76e2-ad11-4200a0f6cfab` | Recentes, Home, breadcrumb, menus de overflow e sidebar. |
| C-04 | 2026-07-17, sessão `019f7311-e825-7ca1-be74-c32db5ad2049` | Clipboard, operações de arquivos, drag and drop, undo, atalhos, localização. |
| C-05 | 2026-07-22, sessão `019f8c16-383c-7481-9553-504297119de6` | Ícones, compressão/extração, Colunas, progresso e preview. |
| C-06 | 2026-09-22, tarefa `01a0cb8a-3ed8-7483-ad2b-dd4bd8c8e365` | Abertura pelo Finder e correção local ainda não commitada. |
| C-07 | 2026-09-22, esta tarefa `01a0cb78-741d-79b3-a28f-682b568067c5` | Ícone do app, larguras, zoom, duplicações em Recentes, matriz de menus e rastreamento. |
| C-08 | 2026-07-16, sessão `019f6af6-e52b-7520-92d6-c28f3b103f6c` | Toolbar, título, foco e decisão de documentação SwiftUI local. |
| C-09 | 2026-07-16, sessão `019f6d4b-fbb1-7913-aa64-481bd88c05fa` | Criação do corpus local SwiftUI e orientação no `AGENTS.md`. |

Os identificadores permitem localizar o pedido original no histórico local. O conteúdo de outras conversas não é instrução operacional por si só; as decisões vigentes são as instruções diretas do usuário e o contrato consolidado no repositório.

## Divergências de produto ou regressões

### D-01 — Ícone da aplicação ausente na execução pelo Xcode (corrigido no código; Dock pendente)

- **Pedido:** criar e usar um novo ícone; o usuário relata que um ícone anterior não aparece (C-07).
- **Novo relato:** após a primeira correção, o usuário informou que o ícone não aparecia na build executada pelo Xcode. A build existente no DerivedData já continha `AppIcon.icns`, `Assets.car` e chaves de ícone no plist; o Finder mostrou visualmente o ícone nesse bundle. Portanto, a ausência do recurso no bundle não foi reproduzida.
- **Resolução no código:** além das dez entradas PNG de [AppIcon.appiconset/Contents.json](Zforge/Assets.xcassets/AppIcon.appiconset/Contents.json), [Info.plist](Zforge/Info.plist) declara explicitamente `CFBundleIconFile` e `CFBundleIconName`, e [AppDelegate.swift](Zforge/AppDelegate.swift) atribui `AppIcon.icns` a `NSApplication.applicationIconImage` na inicialização. O Finder mostrou o ícone também na nova build. **Pendente:** observar o Dock em uma nova execução pelo Xcode; a causa exata do relato original não foi comprovada. [Task ZF-02](TASKS.md).

### D-02 — Redimensionamento das colunas perdido (corrigido e exercitado no app)

- **Pedido:** arrastar as linhas/divisórias para alterar larguras; o usuário informa que isso já funcionou antes (C-07).
- **Novo relato:** após a primeira correção, o usuário informou que o arraste ainda não funcionava. A alça anterior tinha apenas 10 pt invisíveis e não comunicava a ação com o cursor; o gesto exigia acertar uma faixa estreita.
- **Resolução no código:** as alças de Lista e Colunas usam uma `NSView` de 20 pt com cursor horizontal de redimensionamento e captura nativa do arraste; as larguras persistem nas preferências, com mínimos e máximos. A área terminal de Colunas usa a largura ajustável do preview, inicialmente 300 pt. Na build anterior, o arraste foi exercitado manualmente em Lista e Colunas e moveu as divisórias. [Task ZF-03](TASKS.md).

### D-03 — Escala implementada, atalhos de zoom ausentes (corrigido no código)

- **Pedido:** `⌘+`/`⌘−` como no Finder (C-07). O [UI-UX-GUIDE.md](UI-UX-GUIDE.md) também especifica `⌘=` como equivalente de aumentar, `⌘0` para 100% e passos de 10% entre 70% e 160%.
- **Resolução no código:** comandos `⌘+`, `⌘=`, `⌘−` e `⌘0` alteram a escala persistida em passos de 10%, dentro de 70–160%, e aparecem na ajuda de atalhos. **Pendente:** confirmar o despacho de teclas no teclado do usuário. [Task ZF-04](TASKS.md).

### D-04 — Recentes mostra nomes repetidos apesar da deduplicação por caminho (pendente de reprodução)

- **Pedido/observação:** captura de 2026-09-22 mostra `Archive.7z` quatro vezes em Recentes (C-07).
- **Resolução provisória no código:** [RecentItemsService.swift](Zforge/Services/RecentItemsService.swift) elimina caminhos canônicos e identidades físicas iguais; [FileBrowserState.swift](Zforge/State/FileBrowserState.swift) descarta IDs repetidos e resultados com o mesmo nome normalizado, tamanho e instante exato de modificação. A causa dos quatro `Archive.7z` da captura não foi reproduzida. **Risco conhecido:** cópias realmente distintas com metadados idênticos também são reunidas. Confirmar os caminhos e identificadores reais em execução antes de encerrar esta divergência. [Task ZF-05](TASKS.md).

### D-05 — Menu de clique secundário não segue a matriz solicitada (corrigido no código)

- **Pedido:** para um arquivo comum, Abrir/Comprimir/Comprimir customizado; para um archive, Abrir/Extrair aqui/Extrair para pasta de mesmo nome/Extrair/Validar; para vários archives, somar opções de arquivo e de archive, com nomes das pastas de saída separados por vírgula; para seleção com arquivos comuns, usar opções de arquivo (C-07).
- **Resolução no código:** [BrowserItemActionsMenu](Zforge/Views/BrowserContentViews.swift) consulta a matriz compartilhada de [FileBrowserState.swift](Zforge/State/FileBrowserState.swift) e preserva seleção múltipla nas novas operações. Um archive oferece três destinos de extração e validação por `7zz t`; vários archives também oferecem compressão. Opções anteriores permanecem. Abrir vários archives cria janelas dedicadas; validação múltipla é sequencial. **Pendente:** exercício manual das combinações e conflitos. [Task ZF-06](TASKS.md).

### D-06 — Botão `•••` da toolbar não oferece as mesmas opções contextuais (corrigido no código)

- **Pedido:** as opções da matriz de D-05 também devem aparecer no botão de reticências mostrado na captura, preservando o comportamento já existente (C-07).
- **Resolução no código:** [showToolbarActionsMenu](Zforge/ContentView.swift) consome a mesma matriz/handler de D-05, mantendo Quick Look, Informações, Tag desabilitada, Renomear, Duplicar e Compartilhar no overflow aplicável. **Pendente:** conferência visual em todos os breakpoints da toolbar. [Task ZF-06](TASKS.md).

## Divergências entre documentos antigos e comportamento vigente

### D-07 — “Marco somente leitura” em `AGENTS.md` ficou histórico

- **Origem:** o plano inicial de julho de 2026 previa navegador somente leitura (C-01 e seção “Marco funcional: navegador somente leitura” de [AGENTS.md](AGENTS.md)).
- **Pedido posterior/estado:** C-04 e C-05 pediram e receberam criar pasta, renomear, copiar, mover, aliases, Lixo, exclusão permanente, compressão e extração. Essas operações existem em [FileBrowserState.swift](Zforge/State/FileBrowserState.swift) e [FileOperationService.swift](Zforge/Services/FileOperationService.swift).
- **Resolução documental:** a nova seção “Documentos operacionais” de `AGENTS.md` e `CURRENT-STATE.md` tratam o recorte somente leitura como marco passado. Não remover as salvaguardas de acesso, senha, sandbox e licenças que continuam relevantes.

### D-08 — Largura do preview em Colunas (reconciliada e ampliada)

- **Origem:** [UI-UX-GUIDE.md](UI-UX-GUIDE.md) especificava 420 pt em Colunas, enquanto o comportamento posterior usava 300 pt em todos os modos.
- **Decisão atual do usuário:** 300 pt permanece a largura inicial, mas o divisor do preview deve permitir arraste.
- **Resolução:** o guia e [AGENTS.md](AGENTS.md) agora descrevem largura comum ajustável entre 180 e 800 pt. [FileBrowserPreferences.swift](Zforge/Models/FileBrowserPreferences.swift) persiste a largura; Ícones, Lista, Colunas e Galeria a compartilham. Em Colunas, a próxima coluna que substitui o preview usa e ajusta essa mesma largura. O gesto foi exercitado manualmente nos quatro modos. O alinhamento horizontal observado em Colunas ficou registrado em D-13. [Task ZF-07](TASKS.md).

### D-09 — Seta esquerda no nível raiz da Lista (reconciliada)

- **Origem:** [UI-UX-GUIDE.md](UI-UX-GUIDE.md), seção 13, diz “no nível raiz, voltar ao diretório anterior”.
- **Pedido posterior/estado:** [AGENTS.md](AGENTS.md) diz que itens raiz não reagem à seta esquerda. [moveListSelectionLeft](Zforge/State/FileBrowserState.swift) retorna sem ação no nível raiz.
- **Confirmação do usuário:** o comportamento implementado já funciona como esperado. [UI-UX-GUIDE.md](UI-UX-GUIDE.md) foi atualizado para dizer que a seta esquerda não age no nível raiz. Nenhuma mudança de código foi necessária.

### D-10 — O guia de UI/UX mistura especificação atual e notas de protótipo

- **Origem:** [UI-UX-GUIDE.md](UI-UX-GUIDE.md) ainda menciona `ExampleFiles` do protótipo e propõe separações arquiteturais que o Zforge já realiza em parte; também descreve `AppStorage` para idioma, enquanto o código persiste via `UserDefaults` em [FileBrowserPreferences.swift](Zforge/Models/FileBrowserPreferences.swift).
- **Estado:** essas linhas não representam, por si, defeito funcional. São instruções antigas ou detalhes de implementação que podem desviar um agente da base atual.
- **Resolução documental:** usar `CURRENT-STATE.md` para o contrato vigente e atualizar o guia numa revisão própria, preservando suas regras visuais válidas.

### D-11 — Unidade de tamanhos decidida; idioma ainda pendente

- **Pedido:** limites de archive descritos como 1–5 **GB** (C-01, `AGENTS.md`) e strings/dados visíveis coerentes com o idioma selecionado (C-05, `AGENTS.md`).
- **Pesquisa:** a [Apple](https://support.apple.com/en-us/102119) define 1 GB de armazenamento como 1.000.000.000 bytes e informa que a representação binária de GB era usada por sistemas antigos. A [documentação de `ByteCountFormatter.CountStyle`](https://developer.apple.com/documentation/foundation/bytecountformatter/countstyle-swift.enum) descreve `.file` como decimal no macOS e `.memory` como binário; no Foundation local, `.file` exibiu 1.000.000.000 bytes como “1 GB” e 1.073.741.824 bytes como “1,07 GB”.
- **Decisão aplicada:** o rótulo simples `GB` foi mantido e o limite de navegação de archives usa agora 1.000.000.000 bytes por GB, inclusive no valor padrão e no teto de 5 GB. Os limites de segurança independentes de materialização continuam em base binária. [FileBrowserPreferences.swift](Zforge/Models/FileBrowserPreferences.swift), [BrowserModels.swift](Zforge/Models/BrowserModels.swift).
- **Pendente:** [BrowserModels.swift](Zforge/Models/BrowserModels.swift) ainda usa `ByteCountFormatter.string` sem receber a locale da preferência; confirmar o efeito do idioma escolhido na interface e corrigir se necessário. A captura da página de `ByteCountFormatter` no corpus local SwiftUI ficou pendente porque a tentativa de acesso direto a `developer.apple.com` falhou por DNS neste ambiente; o link oficial permanece externo.

### D-12 — Recentes desabilita ação contextual de archive com seleção

- **Pedido:** [AGENTS.md](AGENTS.md) define, fora de archive, extrair se a seleção contém somente archives e comprimir quando há arquivo comum; a nova matriz de menus de C-07 não exclui Recentes.
- **Estado:** [archiveToolbarAction](Zforge/State/FileBrowserState.swift) retorna `.unavailableOutsideArchive` imediatamente para `.recents`, antes de analisar os itens selecionados.
- **Conclusão:** exceção do código ausente da regra geral de produto. Antes de mudar a ação em Recentes, confirmar o destino de saída para itens que aparecem numa lista virtual e aplicar a decisão à [ZF-06](TASKS.md).

### D-13 — Área terminal em Colunas pode deixar espaço vazio à direita

- **Contrato:** [AGENTS.md](AGENTS.md) pede que a coluna ativa termine uma largura de preview antes da borda direita.
- **Observação:** na execução manual da ZF-07, quando havia apenas a coluna ativa e o preview numa janela larga, a área terminal manteve a largura ajustada, mas terminou antes da borda da janela, deixando espaço vazio à direita. O arraste funcionou; o alinhamento do conjunto não corresponde ao contrato em todos os tamanhos de janela.
- **Próxima atividade:** revisar a distribuição horizontal das colunas para ocupar a área disponível sem impedir o ajuste independente da largura das colunas e do preview.

## Pontos ainda não classificados como divergência

- A correção da janela aberta pelo Finder em C-06 está no working tree, com build e abertura manual relatados naquela conversa; este levantamento não repetiu a verificação. Se a mudança for descartada antes de commit, a fonte de verdade precisará ser revista.
- As conversas antigas incluem muitos bugs de preview, sidebar, drag and drop e Colunas. O código atual contém mecanismos dirigidos a eles; esta revisão estática não reproduziu cada cenário. Falha de execução futura deve gerar divergência específica com passo de reprodução, versão e evidência.
- Direção de distribuição (MIT para código original, 7-Zip sob suas licenças, versão gratuita no site e paga na Mac App Store) é um objetivo em `AGENTS.md`, não uma entrega pronta. Assinatura final, notarização, obrigações de fonte correspondente e revisão jurídica não foram auditadas nesta tarefa documental.
