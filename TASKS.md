# Zforge — rastreamento de atividades

Atualizado em **2026-09-27**. Esta lista preserva os pedidos levantados nesta conversa. `Documentation/Requirements/CURRENT-STATE.md` descreve o comportamento existente; `Documentation/Requirements/OPEN-REQUIREMENTS.md` reúne requisitos ainda abertos; `DIVERGENCES.md` guarda lacunas e conflitos. O usuário confirmou D-01, D-03, D-05 e D-06 como OK. O arraste de colunas e preview foi exercitado no app; as demais pendências continuam identificadas abaixo.

| ID | Atividade | Estado | Divergência |
| --- | --- | --- | --- |
| ZF-01 | Criar orientação para agentes, fonte de verdade e registro de divergências/tasks | Concluída nesta revisão documental | D-07 a D-12 |
| ZF-02 | Criar e aplicar novo ícone da aplicação | Concluída; confirmada pelo usuário | D-01 |
| ZF-03 | Restaurar redimensionamento das colunas por arraste | Implementada e exercitada em Lista/Colunas | D-02 |
| ZF-04 | Implementar zoom por atalhos `⌘+` e `⌘−` | Concluída; confirmada pelo usuário | D-03 |
| ZF-05 | Corrigir itens repetidos em Recentes | Concluída: identidade real e exclusão do staging interno, com testes de unidade e UI | D-04 |
| ZF-06 | Alinhar menu secundário e botão `•••` à matriz contextual de ações | Matriz concluída e confirmada; ação principal da toolbar em Recentes implementada na ZF-10, com execução real ainda pendente | D-05, D-06, D-12 |
| ZF-07 | Permitir arrastar o divisor do preview com 300 pt iniciais | Implementada e exercitada nos quatro modos | D-08 |
| ZF-08 | Cobrir contratos existentes e refatorar a arquitetura sem alterar o comportamento | Concluída; 80 testes unitários e 11 casos de UI aprovados, com limites manuais rastreados | Prevenção de regressões; não resolve D-10 a D-13 automaticamente |
| ZF-09 | Centralizar e indexar os requisitos em `Documentation/Requirements` | Concluída; fontes de requisito movidas, índices e manutenção contínua documentados | Organização documental e prevenção de regressões |
| ZF-10 | Resolver OR-01 a OR-05: guia, idioma dos tamanhos, operações em Recentes, alinhamento de Colunas e integração Finder | Código e documentação atualizados; OR-02 e OR-03 ainda requerem verificação visual/operacional, e OR-04 foi parcialmente conferida na ZF-11. OR-05 já estava no commit `d23e1f7` | D-10 a D-13, C-06 |
| ZF-11 | Renomear a ação de conexão para Remote e corrigir o recuo inicial de Colunas | Implementada; build assinada, janela larga com fixtures e arraste do divisor de preview conferidos. Divisor de coluna e overflow permanecem em OR-04 | D-13 |
| ZF-12 | Corrigir preview de arquivos `.html`/`.htm` que ficava carregando | Implementada com WebKit, JavaScript do documento desativado e entitlement de rede; testes de HTML/CSS local aprovados, cópia do arquivo do relato renderizada em build de teste assinada, inclusive após a desativação de scripts; build de distribuição ainda não conferida | D-14 |
| ZF-13 | Calcular a largura inicial de cada preview em Colunas pela sobra disponível | Implementada e confirmada pelo usuário; build, testes unitários e UI aprovados | D-15 |
| ZF-14 | Manter o alinhamento da coluna terminal ao alternar entre pasta e arquivo | Implementada; testes unitários e UI aprovados para o cenário das capturas; fluidez visual manual ainda em OR-04 | D-16 |

## ZF-01 — Documentação de referência e prevenção de regressões

**Pedido:** usar `AGENTS.md` para guiar o desenvolvimento, apontar para uma fonte de verdade versionada que descreva cada funcionalidade implementada, criar lista de tasks e registrar separadamente inconsistências com pedidos anteriores.

**Entregue nesta etapa:** `AGENTS.md` aponta para `Documentation/Requirements/CURRENT-STATE.md`, `DIVERGENCES.md` e este arquivo; o estado funcional foi mapeado a partir do código, do guia e de conversas anteriores. O levantamento é estático, sem nova execução do app. **Manutenção contínua:** toda alteração funcional precisa revisar o contrato e as divergências relevantes na mesma mudança.

## ZF-02 — Ícone do Zforge

**Pedido:** criar um novo ícone e usá-lo na aplicação, pois o atual não aparece.

**Implementado e confirmado pelo usuário:** ícone novo com variantes PNG de 16 a 1024 px referenciadas pelo asset catalog; `Info.plist` declara explicitamente o nome do ícone e `AppDelegate` o atribui à aplicação na inicialização. O Finder mostrou o ícone no bundle anterior do DerivedData do Xcode e na nova build isolada.

## ZF-03 — Larguras ajustáveis por mouse

**Pedido:** arrastar as divisórias para alterar larguras. O usuário relatou que a capacidade existia e regrediu.

**Implementado:** arraste das divisórias em Lista e Colunas por alças nativas de 20 pt com cursor de redimensionamento, larguras globais persistidas, limites e escala definidos em `Documentation/Requirements/CURRENT-STATE.md`. A área terminal do preview em Colunas é ajustável pela ZF-07. A build anterior foi exercitada manualmente nos dois modos e as divisórias se moveram.

## ZF-04 — Zoom nas views

**Pedido:** `⌘+` aumenta e `⌘−` diminui a escala, como no Finder.

**Implementado e confirmado pelo usuário:** `⌘+` e `⌘=` aumentam; `⌘−` diminui; `⌘0` restaura 100%. Escala global em passos de 10%, de 70 a 160%, nas quatro views. Toolbar permanece sem controle de zoom.

## ZF-05 — Recentes sem duplicatas

**Pedido:** a aba Recentes não deve repetir o mesmo item. Captura de 2026-09-22 mostra `Archive.7z` repetido.

**Implementado e conferido:** a Lista de Recentes elimina repetições do mesmo caminho canônico ou arquivo físico quando sua identidade está disponível e também descarta IDs repetidos após carregar os itens. A regressão de 2026-09-24 mostrou que cópias criadas pelo próprio motor em `temporaryDirectory/Zforge/ArchiveSessions` passavam por essa regra por terem identidade física nova. Todo o armazenamento temporário do Zforge passou a ser excluído no serviço Spotlight e no estado da janela, antes de aplicar o limite de 250. Arquivos de usuário distintos com mesmo nome, tamanho e data continuam separados. Testes com cópias reais verificam a lista publicada e os quatro modos; um teste de UI usa o mesmo cenário com fixtures.

## ZF-06 — Matriz contextual nos dois menus

**Pedido:** clique secundário e botão `•••` da toolbar devem apresentar as mesmas ações aplicáveis à seleção, preservando ações já existentes e os estados habilitados.

| Seleção | Novas opções solicitadas |
| --- | --- |
| Um arquivo comum | Abrir; Comprimir; Comprimir customizado |
| Um archive | Abrir; Extrair aqui; Extrair para pasta com nome do archive; Extrair; Validar |
| Vários archives | Opções de archive **e** de arquivo; “Extrair para” lista nomes das pastas de saída, separados por vírgula |
| Vários itens com ao menos um arquivo comum | Mesmas opções indicadas para um arquivo comum |

**Implementado e confirmado pelo usuário:** matriz e handler compartilhados nos dois menus; três destinos de extração, validação com `7zz t`, compressão customizada com painel de formato/nome/destino. Abrir vários archives cria janelas, validar/extrair vários processa em sequência. Itens de Recentes recebem as opções conforme o tipo. A ação principal da toolbar em Recentes foi habilitada na ZF-10, com o destino padrão definido pelo usuário; a execução real ainda precisa ser conferida.

## ZF-07 — Largura ajustável do preview

**Pedido:** manter 300 pt como largura inicial, permitindo arrastar o divisor para redimensionar o preview.

**Implementado:** uma preferência global compartilhada pelos quatro modos guarda a largura entre 180 e 800 pt; cada divisor do preview tem alça nativa de 20 pt e cursor de redimensionamento. Em Colunas, a próxima coluna que ocupa a área terminal usa a mesma largura e o mesmo ajuste. A build da ZF-07 compilou e o gesto foi exercitado em Lista, Ícones, Galeria e Colunas. O alinhamento da área terminal em janelas largas foi alterado na ZF-10; falta conferência visual dessa mudança.

**Atualização em 2026-09-27:** a ZF-13 substituiu a largura compartilhada e a área terminal fixa apenas em Colunas. Esta seção registra o estado histórico da ZF-07; a preferência global continua em Ícones, Lista e Galeria.

## ZF-08 — Cobertura de caracterização e refatoração arquitetural

**Objetivo:** reduzir acoplamento, duplicação e tamanho das unidades de código, preservando os contratos observáveis de `Documentation/Requirements/CURRENT-STATE.md`. Aplicar Clean Code e SOLID onde produzirem fronteiras úteis; empregar padrões apenas quando simplificarem uma dependência ou fluxo concreto. Esta task não altera intencionalmente a experiência do usuário nem incorpora as mudanças funcionais de D-10 a D-13.

### Mapa de oportunidades no código atual

| Área | Evidência e risco | Direção de refatoração |
| --- | --- | --- |
| Estado da janela | `FileBrowserState.swift` tem ~3.150 linhas e concentra navegação, histórico, seleção, hierarquia, Colunas, preview, Quick Look, segurança de acesso, operações locais, archives, Clipboard e drop. Há muitos campos mutáveis, caches com revisões próprias e tarefas assíncronas. | Dividir por responsabilidades coesas, mantendo um coordenador observável por janela. Extrair modelos/colaboradores internos para navegação e histórico, seleção/hierarquia, preview e orquestração de operações; definir invariantes explícitas para seleção primária, coluna ativa, caminho e invalidação de caches. Evitar criar protocolos para estruturas que só precisam de tipos concretos. |
| Fluxos assíncronos | `FileBrowserState` guarda gerações e `Task`s separadas para refresh, preview, ativação de coluna e expansão; callbacks de `NSWorkspace`, monitores e providers também atualizam estado. Um resultado atrasado pode reintroduzir dados de seleção/localização anterior. | Centralizar a política de cancelamento e validade por operação/sessão; usar identificadores tipados ou snapshots imutáveis quando necessários; manter a atualização síncrona de seleção e invalidação do preview. Definir propriedade e término de cada tarefa ao navegar, fechar janela e cancelar operação. |
| Ações e menus | A matriz contextual está em `FileBrowserState`, o menu do clique secundário em `BrowserContentViews.swift` e o menu da toolbar/overflow em `ContentView.swift`. Há apresentações e estados habilitados adicionais em cada superfície. A ação principal da toolbar tem caminho próprio de compressão/extração. | Introduzir uma descrição tipada de ações disponíveis para uma seleção e localização, consumida por menus, toolbar e atalhos. Reusar um executor de ações; manter a apresentação nativa SwiftUI/AppKit em adaptadores de UI. Tratar D-12 como comportamento atual até decisão funcional específica. |
| Archives | `ArchiveEngine.swift` tem ~1.050 linhas: protocolo `ArchiveServing`, sessões, staging, política de tamanho/profundidade, parser `7zz`, construção de argumentos, extração, conflito e materialização. `SevenZipProcessRunner` concentra processo e cancelamento. | Preservar `ArchiveServing` como fronteira do motor; separar parser e comandos versionados, registro de sessões/staging, política de materialização e fluxo de conflitos em unidades testáveis. Compartilhar validação/cancelamento entre operações sem levar texto da CLI para domínio/UI. Manter senha fora de argumentos/logs. |
| Sistema de arquivos e permissões | `FileBrowserState` orquestra `FileSystemServing`, `FileOperationServing`, `AccessGrantStoring`, `RecentItemsServing`, `DirectoryMonitor`, `NSWorkspace` e `NSPasteboard`. O fluxo de autorização e retorno à intenção original depende de estado interno. | Encapsular transições de autorização e destino de operações em tipos explícitos; manter os serviços substituíveis por fixtures. Concentrar interação com AppKit nas bordas, preservando URLs originais, bookmarks, undo e semântica de drag and drop. |
| Recentes | `SpotlightRecentItemsService` consulta metadados e deduplica por caminho/identidade física; `FileBrowserState` carrega itens e deduplica IDs. O teto de 250 vale após deduplicação. | Extrair a normalização/identidade para unidade determinística testável e deixar `NSMetadataQuery` como adaptador. Não colapsar arquivos diferentes por nome/tamanho/data; preservar ordem, filtro e cancelamento da consulta. |
| Views e layout | `BrowserContentViews.swift` tem ~1.670 linhas e contém os quatro modos, headers/linhas, layout, menus, foco, resize e drop. `ContentView.swift` tem ~1.000 linhas e reúne composição da janela, toolbar, painéis, alertas e foco. `PreviewView.swift` tem ~740 linhas. | Separar arquivos por modo/componente e extrair cálculos puros de layout, larguras e scroll para tipos pequenos. Compartilhar só apresentação/gestos que tenham a mesma regra; preservar escopo de `@State`, identidade das views, foco persistente e ciclo de vida de `QLPreviewView`. |
| Preferências, localização e ciclo de vida | `FileBrowserPreferences` combina persistência, limites e zoom; `ZforgeApp.swift` declara muitos comandos; a abertura pelo Finder atravessa `AppDelegate` e `WindowGroup`. | Isolar validação e leitura/escrita de preferências sem alterar chaves nem valores existentes. Centralizar definições de comandos/atalhos quando reduzirem divergência com Ajuda. Manter a mesma rota de inicialização para janela comum e arquivo vindo do Finder. Revisar strings visíveis no String Catalog durante o toque de cada área. |
| Testabilidade | `ZforgeTests.swift` tem ~1.550 linhas e mistura testes de vários domínios; `FileOperationServiceTests.swift` tem ~660. Há fixtures úteis em `UIFixtureServices.swift`, mas vários caminhos de AppKit/Spotlight são difíceis de exercitar de forma determinística. | Agrupar testes por contrato e expandir fixtures nas fronteiras já existentes. Preferir testes de regra pura/estado a UI para casos combinatórios; usar UI tests para gesto, menu, foco e integração de janela. Não associar porcentagem de linhas a proteção contra regressão. |

### Cobertura a criar antes de alterar cada comportamento

O inventário de `Documentation/Requirements/CURRENT-STATE.md` é a lista de contratos; os testes existentes devem ser mantidos. Para cada extração, registrar o cenário anterior e um teste que falhe se ele mudar. Lacunas identificadas por inspeção estática das fontes de `ZforgeTests` e `ZforgeUITests`:

| Contrato a proteger | Cobertura nova esperada |
| --- | --- |
| Janela e navegação | Abertura comum em Recentes, arquivo enviado pelo Finder abrindo janela dedicada pelo mesmo `WindowGroup`, autorização/cancelamento/repetição de grant, retorno à intenção após autorização, breadcrumb, histórico independente por janela, refresh preservando seleção e symlink/alias sem ciclo. |
| Recentes | Resultados repetidos do Spotlight pelo mesmo caminho, symlink e identidade física; arquivos distintos com mesmo nome/tamanho/data; ordenação por uso; teto de 250 **itens únicos**; resultados inexistentes/ocultos; nova consulta cancelando a anterior sem publicar resposta antiga. O teste atual de Recentes usa apenas dois URLs distintos. |
| Seleção e hierarquia | Seleção simples, Command e Shift pela ordem achatada, teclado esquerda/direita em pasta expandida e item raiz, expansão ZIP/7z e limites de aninhamento, descarte de ramo antigo em Colunas e reconciliação ao trocar de modo sem novo histórico. Complementar casos com carregamentos que terminam fora de ordem. |
| Quatro modos, zoom e larguras | `⌘+`, `⌘=`, `⌘−`, `⌘0` e limites 70–160% em Ícones, Lista, Colunas e Galeria; largura persistida e arraste real dos divisores da Lista, Colunas e preview nos quatro modos, inclusive mínimo/máximo, overflow e redimensionamento da janela. Testes atuais cobrem alguns cálculos de layout, mas não os gestos/atalhos. |
| Preview e Quick Look | Invalidar preview antes de carregar outro item, descartar resultado obsoleto, 10 MB automático versus manual, arquivos/pastas/archives e seleção múltipla, troca de URL recriando `QLPreviewView`, visibilidade independente por modo e foco após alternar. Preservar as verificações existentes de ordem, layout e seleção rápida. |
| Ações contextuais e toolbar | Matriz completa para arquivo, archive, vários archives e seleção mista; menu secundário e `•••`/overflow com mesmas opções e estados, seleção múltipla preservada no clique secundário, títulos de saída múltipla, ação principal e breakpoints 678/780/840/900 pt, inclusive exceção atual de Recentes. Exercitar handler real além de conferir rótulos. |
| Motor de archive | Fixtures de saída real do `7zz` para parser, nomes especiais, falhas e avisos; formatos, volumes, tamanho/profundidade, senha por stdin, staging, materialização e limpeza de sessão, cancelamento/progresso, conflitos, criação, extração e validação em lote. Há testes de ZIP, formatos, senha e aninhamento; faltam casos dedicados de parser/protocolo e falhas parciais. |
| Arquivos e drag and drop | Destino por linha/coluna, cópia/movimentação/alias conforme modificadores e volume, providers iniciados dentro de `performDrop`, colisões, undo, Lixo/exclusão permanente, confirmação e Clipboard com URL original. Parte das regras já tem teste de serviço/estado; completar os fluxos de UI e limites entre AppKit/SwiftUI. |
| Preferências, idioma e ícone | Compatibilidade das chaves persistidas após refatorar, idioma das strings fora do SwiftUI, zoom/larguras/preview e limites de archive; inspeção do bundle compilado para `AppIcon`/`Assets.car` e verificação de abertura pelo Xcode/Finder. Confirmar strings e estados de controles nos dois idiomas. |

### Sequência e critérios de aceite

1. Registrar uma matriz rastreável `contrato de CURRENT-STATE.md → teste existente → lacuna → novo teste`, com indicação do que é teste unitário, integração `7zz`, UI ou verificação manual. Priorizar os fluxos com regressão recente: Recentes, larguras, zoom, menus, ícone e abertura pelo Finder.
2. Criar a cobertura de caracterização da fatia antes de refatorá-la; usar arquivos temporários/fixtures e defaults isolados. Para dependências do macOS que não permitam automação confiável, documentar o limite e executar roteiro manual reprodutível no caminho real de abertura.
3. Refatorar em fatias pequenas, começando por regras puras/identidade e ações; seguir por coordenação de seleção/preview, serviços de archive, views e persistência. Cada fatia deve preservar API pública quando possível, sem migração silenciosa de preferências ou alteração visual acidental.
4. Ao executar esta task, rodar os testes afetados e a suíte completa, build Debug e verificações de UI no app pelo Xcode e pelo Finder quando pertinentes. Registrar resultados, falhas preexistentes e qualquer limitação; atualizar `Documentation/Requirements/CURRENT-STATE.md` e `DIVERGENCES.md` apenas se a evidência/contrato mudar.

**Pronto quando:** responsabilidades tiverem fronteiras claras e nomes orientados ao domínio, a duplicação identificada tiver sido reduzida sem abstrações artificiais, todos os contratos tocados estiverem cobertos ou tiverem verificação manual e limitação explícitas, e os fluxos principais se comportarem como antes nos quatro modos e nas duas rotas de abertura.

**Resultado em 2026-09-23:** a matriz em `REGRESSION-COVERAGE.md` foi criada; identidade de Recentes, seleção de ações, parser de listagem `7zz`, projeção/cache de itens e cálculos de layout receberam fronteiras próprias. Os quatro modos foram separados em arquivos Swift individuais. Reloads antigos não podem publicar resultados sobre uma consulta mais nova, inclusive na hierarquia expandida; refresh de extração e remoção em Colunas preserva as chaves reais das URLs. Compressão compartilha um executor entre menu e toolbar. Os contratos tocados têm testes de caracterização ou verificação manual explícita. A última rodada registrou 80 testes unitários e 11 casos distintos de UI aprovados; gestos de divisor e Launch Services foram conferidos na interface. Limites de integração do macOS e lacunas de funcionalidades não alteradas permanecem descritos na matriz, sem redefinir o estado esperado de `Documentation/Requirements/CURRENT-STATE.md`.

## ZF-09 — Diretório e índices de requisitos

**Pedido:** colocar os requisitos do projeto em `Documentation/Requirements`, criar índices em `Documentation/AGENTS.md` e `Documentation/Requirements/AGENTS.md`, apontar para eles no `AGENTS.md` da raiz e manter a documentação atualizada em cada interação do agente.

**Entregue:** a fonte de verdade do estado atual e o guia de UI/UX foram movidos para o diretório de requisitos. A direção de produto, motor e distribuição foi preservada em `PRODUCT-REQUIREMENTS.md`, e as decisões abertas foram reunidas em `OPEN-REQUIREMENTS.md`. Os três `AGENTS.md` estabelecem índice, precedência e rotina de atualização. Os caminhos antigos na raiz são redirecionamentos para evitar perder referências já compartilhadas.

## ZF-10 — Pendências do levantamento

**Escopo autorizado nesta interação:** resolver as cinco pendências listadas em `OPEN-REQUIREMENTS.md`. A regra informada pelo usuário para o destino de operações em Recentes corresponde a D-12; D-13 continua sendo o alinhamento da área terminal de Colunas.

- OR-01/D-10: removidas referências operacionais a `ExampleFiles`, `AppStorage` e à arquitetura proposta do protótipo; preservadas as regras visuais do guia.
- OR-02/D-11: os tamanhos apresentados usam `ByteCountFormatStyle` com a locale do aplicativo; o limite configurável de archive continua em GB decimal.
- OR-03/D-12: a ação de archive da toolbar funciona em Recentes conforme a seleção. Extrações usam o diretório real de cada archive; compressão conjunta usa o diretório do item ativo, ou a primeira origem por caminho se não houver item ativo.
- OR-04/D-13: as Colunas se alinham à borda direita quando o conjunto é menor que a largura visível, sem alterar as preferências de largura.
- OR-05/C-06: a rota Finder → `WindowGroup` já integra `main` no commit `d23e1f7`; não havia alteração local desse fluxo a integrar.

**Limite atual:** a compilação e a inspeção de código não substituem a conferência visual de idioma, gestos em Colunas e execução de operações reais em Recentes. Esses pontos permanecem em `OPEN-REQUIREMENTS.md` e `REGRESSION-COVERAGE.md` até validação no app.

**Compilação:** `xcodebuild` Debug macOS sem assinatura concluiu com `BUILD SUCCEEDED` em 2026-09-24 usando `/tmp/zforge-open-requirements-build`. A tentativa inicial no sandbox falhou por indisponibilidade da macro `@Observable`; a repetição com acesso ao serviço do Xcode compilou. Nenhum teste foi executado nesta interação.

## ZF-13 — Largura do preview em Colunas por seleção

**Pedido:** cada preview inicia com toda a largura disponível à direita das colunas abertas no momento do carregamento, com mínimo de 320 pt e sem máximo. Uma mudança de espaço antes da próxima seleção deve ser refletida no novo preview.

**Implementado:** antes de expandir um ramo, Colunas mantém as colunas de navegação na largura base, sem reservar slot fixo para preview. Ao carregar um item elegível, calcula a largura com a geometria atual; o divisor altera apenas essa seleção. A próxima seleção recalcula a largura, sem consultar ou alterar a preferência global dos outros modos. O conteúdo de `SelectionOverview` recebe a largura proposta pelo pai. A regra após expansão foi refinada na ZF-14.

**Validação:** build Debug macOS aprovada; suíte `ZforgeTests` aprovada; teste de UI assinado com fixtures passou em arquivo da primeira coluna e arquivo de uma coluna interna, confirmando largura diferente e mínimo de 320 pt. A conferência visual com os arquivos das capturas e o arraste em janela estreita permanecem em OR-04.

**Confirmação do usuário:** o problema da largura inicial foi resolvido. A ZF-14 refinou o comportamento após abrir uma coluna filha.

## ZF-14 — Alinhamento estável da faixa terminal em Colunas

**Pedido:** depois de abrir uma pasta/archive à direita, manter a nova coluna inteiramente visível. Ao selecionar um arquivo na coluna anterior, o preview deve ocupar a mesma faixa e largura, sem a divisória oscilar; preservar a largura dinâmica do preview antes dessa expansão.

**Implementado:** a coluna terminal preenche a largura livre, com mínimo da largura base e de 320 pt quando o preview está visível. O ramo registra que já abriu uma coluna filha; previews posteriores no mesmo nível usam a faixa terminal correspondente. Um slot vazio mantém a geometria durante abertura assíncrona da coluna ou carregamento de preview. Sem preview visível, as colunas continuam com a largura base.

**Validação:** `ZforgeTests` passou com 85 testes; `RefactoringCharacterizationTests.columnTerminalWidth` verifica a geometria. Os dois testes de UI assinados passaram em `/private/tmp/ZforgeTerminalAlignmentFinal`: `testColumnPreviewKeepsExpandedTerminalAlignment` confirmou as mesmas bordas e largura para coluna expandida e preview substituto em `Welcome.txt → Sample.zip → Welcome.txt`, além da reabertura da coluna na mesma posição; `testColumnPreviewRecalculatesWidthForNewDepth` preservou o cálculo dinâmico anterior. Navegação visual rápida com os arquivos das capturas e arraste manual continuam em OR-04.
