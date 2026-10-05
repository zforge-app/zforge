# Guia de UI/UX do gerenciador de arquivos para macOS

Este documento define a hierarquia visual, as interações e a responsividade do Zforge. Decisões aproveitadas de `UIDemo` foram incorporadas como regras da aplicação. Para o comportamento implementado vigente, prevalece [`CURRENT-STATE.md`](CURRENT-STATE.md); conflitos conhecidos estão em [`../../DIVERGENCES.md`](../../DIVERGENCES.md).

Antes de implementar ou corrigir uma interface, consulte este guia. Quando uma decisão mudar intencionalmente, atualize o documento junto com o código.

## 1. Direção do produto

- A aplicação deve parecer nativa do macOS, sem tentar reproduzir o Finder pixel a pixel.
- O Finder é a principal referência para navegação, seleção, teclado, visualizações e densidade da interface.
- APIs atuais do SwiftUI e do macOS devem ser preferidas.
- AppKit pode ser usado de forma isolada quando o SwiftUI não oferece controle suficiente ou altera comportamentos essenciais.
- Liquid Glass deve reforçar hierarquia e agrupamento, principalmente em toolbar e superfícies de navegação. Não deve ser aplicado como ornamento em toda a interface.
- Legibilidade, previsibilidade, acessibilidade e comportamento nativo têm prioridade sobre efeitos visuais.
- Cores e ícones do sistema devem ser usados sempre que possível para respeitar tema, contraste e preferências do usuário.

### Polimento obrigatório da experiência

Diretriz de 2026-10-04, vinculada aos [requisitos RNF-Q01 a RNF-Q06](PRODUCT-REQUIREMENTS.md#qualidade-polimento-e-prevenção-de-regressões): buscar um **“Wow effect”** pela qualidade do uso. **“Design is how it works”** exige avaliar o fluxo inteiro; a diretriz não é uma declaração de que todas as superfícies atuais já receberam essa validação.

- Ícones, cores e formas devem comunicar ação, tipo e estado com coerência entre modos, menus, toolbar e preview. Nomenclatura e traduções devem ser claras, naturais e consistentes, incluindo tooltips, erros e labels de acessibilidade no String Catalog.
- Posicionamento, ordenação, tamanhos e espaçamentos devem seguir a hierarquia da tarefa, com alinhamento estável, áreas de interação adequadas e legibilidade nas larguras e escalas suportadas. Conferir textos longos, idiomas suportados, temas claro/escuro, contraste aumentado e cor de destaque.
- Gestos, mouse e teclado devem produzir os resultados especificados e feedback inequívoco, preservando seleção e foco conforme o contrato. Revisar estados normal, hover, selecionado, desabilitado, carregamento, erro e cancelamento quando aplicáveis.
- Animações e transições devem explicar a mudança de estado, manter continuidade e responder a ações rápidas ou interrompidas. Não admitir saltos indevidos, recortes, cintilação nem retorno de conteúdo obsoleto. Respeitar redução de movimento e evitar efeitos que atrasem a ação ou prejudiquem acessibilidade.
- Verificar sequência, geometria e comportamento por testes representativos e conferir o acabamento na interface em execução. Registrar condições, resultado e limites; aprovação de uma geometria final não comprova fluidez durante a transição. Aplicar o checklist de regressão deste guia às superfícies e aos fluxos adjacentes afetados.

### Ícone da aplicação

O arquivo [zforge_icon.icon](../../Zforge/zforge_icon.icon/icon.json), exportado pelo usuário no Icon Composer, é a fonte atualmente selecionada para o app. Os estudos abaixo registram a evolução da direção visual; referências a integração ou aprovação pendente descrevem o estado de cada rodada, antes da exportação atual. A legibilidade e as variantes de aparência ainda precisam de conferência no app instalado.

- A identidade atual reúne um **Z legível** sendo comprimido por uma prensa hidráulica, relacionando archives e metalurgia. O Z e a ação da prensa devem continuar legíveis em tamanho reduzido.
- A composição deve funcionar na linguagem de ícones do macOS 27 e nas aparências do Icon Composer. A prancha em [`../Design/Zforge-icon-concepts-16-metallurgy.png`](../Design/Zforge-icon-concepts-16-metallurgy.png) foi um estudo inicial, não a fonte selecionada.
- Da prancha de metalurgia, o usuário apontou elementos aproveitáveis em **02, 03, 04, 06, 07, 12 e 15**; incluiu **16** como referência adicional para o zíper. Refinamentos solicitados: [16 estudos de bigorna e martelo](../Design/Zforge-icon-concepts-anvil-hammer-16.png) a partir de 03/12; [16 estudos de zíper diagonal com acentos laranja](../Design/Zforge-icon-concepts-diagonal-zipper-16.png) a partir de 02/06/16; e [um estudo com prensa](../Design/Zforge-icon-concept-press-07.png) a partir de 07. São alternativas conceituais; a seleção final segue aberta.
- Na rodada seguinte, o usuário selecionou **02/04/08 da [primeira prancha exibida](../Design/Zforge-icon-source-anvil-first-16.png)**, **01/03/12/14/16 da [segunda](../Design/Zforge-icon-source-zipper-second-16.png)**, **o estudo da prensa** e **03/04/10 da [quarta prancha exibida](../Design/Zforge-icon-source-graphic-fourth-16.png)** (a de tratamento gráfico plano e emblema industrial). Foram geradas quatro novas pranchas de 16 variações cada: [bigorna e martelo](../Design/Zforge-icon-refinement-anvil-02-04-08.png), [zíper diagonal](../Design/Zforge-icon-refinement-zipper-01-03-12-14-16.png), [prensa](../Design/Zforge-icon-refinement-press-16.png) e [emblemas gráficos](../Design/Zforge-icon-refinement-graphic-03-04-10.png). Nenhum desses estudos define ainda o ícone final.
- Seleção mais recente: **02 da prancha de bigorna/martelo**, **07/09/15 da prancha da prensa** e **01/02/09/12 da prancha de emblemas gráficos**. As características foram combinadas em duas novas pranchas de 16: [síntese próxima às referências](../Design/Zforge-icon-synthesis-selected-close-16.png) e [síntese com arranjos novos](../Design/Zforge-icon-synthesis-selected-hybrid-16.png). Ambas são estudos para escolha e refinamento posteriores.
- O usuário refinou o método de exploração: **gerar cada alternativa como imagem individual**, pois as pranchas reduzem a qualidade percebida. Foram criados [16 candidatos independentes](../Design/IconCandidates/README.md) a partir das características selecionadas, sem montar uma nova prancha. A escolha final permanece aberta.
- Entre os candidatos individuais, o usuário apontou **02, 10, 09, 11 e 12** como opções com potencial, mas declarou insatisfação com os resultados em geral. Esses números são referências para uma eventual próxima etapa, não uma escolha final.
- Na exploração seguinte, usar como referência visual uma prensa hidráulica real e pastas de escritório de várias cores. A arte deve incluir **prensa hidráulica, pastas multicoloridas e Z** e preservar uma relação física inteligível entre cilindro, pistão, platô móvel, pastas e base. O usuário rejeitou a estrutura em H do [candidato 17](../Design/IconCandidates/17-hydraulic-press-folders-z.png): a direção correta é a prensa **cilíndrica**, com discos metálicos circulares e pintura de segurança amarela e preta, como na fotografia fornecida. Gerar **uma imagem por vez** e concentrar a qualidade nela. O [candidato 18](../Design/IconCandidates/18-hydraulic-cylinder-folders-z.png) explora essa correção; a escolha final permanece aberta.
- O usuário confirmou a direção do candidato 18 e solicitou uma versão estilizada que funcione como ícone de aplicação. O [candidato 19](../Design/IconCandidates/19-stylized-hydraulic-cylinder-folders-z.png) mantém o arranjo físico e simplifica superfícies e contornos para leitura em tamanho reduzido. A aprovação final e a integração ao app continuam pendentes.
- No refinamento do candidato 19, o usuário pediu que o topo do cilindro alcance a borda superior, a base alcance a borda inferior, o Z apresente volume como futura camada independente e o fundo verde seja substituído. O [candidato 20](../Design/IconCandidates/20-press-edge-to-edge-raised-z.png) usa recorte nas bordas, Z em relevo e fundo transparente; ainda é uma imagem raster única para avaliação.
- No refinamento seguinte, as pastas devem mostrar material de **cartão/papel dobrado** e forma coerente com a perspectiva, incluindo capas finas, vincos, abas e bordas de folhas; não devem parecer borracha ou blocos maciços. Pistão e discos circulares devem parecer **aço usinado** com espessura e reflexos convincentes. O [candidato 21](../Design/IconCandidates/21-cardstock-folders-machined-steel.png) explora esses ajustes; permanece pendente de avaliação.
- Duas imagens adicionais fornecidas pelo usuário mostram pastas de escritório coloridas com abas escalonadas, capas planas e papéis internos. O [candidato 22](../Design/IconCandidates/22-folder-reference-refinement.png) usa essas características como referência visual, mantendo as pastas deitadas entre os discos da prensa. Essa direção foi substituída pelo pedido posterior de um armário de documentos.
- Após avaliar referências de outros aplicativos de archives, o usuário pediu **um armário de documentos no lugar das pastas**. O [candidato 23](../Design/IconCandidates/23-hydraulic-press-filing-cabinet.png) explora um armário compacto de duas gavetas entre os discos, preservando a prensa cilíndrica e o Z. A escolha final continua aberta.
- Para o próximo refinamento, o usuário pediu **armário mais alto**, com o conjunto superior da prensa deslocado para cima e o Z transferido para outro local porque o cilindro perde espaço. O [candidato 24](../Design/IconCandidates/24-tall-filing-cabinet-z-on-platen.png) apresenta três gavetas e Z em relevo no platô móvel; a escolha final permanece aberta.
- O usuário voltou à ideia do **Z sendo prensado**, sem armário. O [candidato 25](../Design/IconCandidates/25-pressed-metal-z.png) coloca um único Z metálico entre os discos da prensa cilíndrica, em contato com ambos; permanece um estudo raster, sem aprovação final.
- A prévia do candidato 25 no Icon Composer cortou demais a composição. O [candidato 26](../Design/IconCandidates/26-pressed-z-icon-composer-framing.png) afasta o enquadramento, reduz a altura da parte superior e deixa margens transparentes para manter prensa e Z dentro da área útil; o encaixe no Icon Composer ainda precisa ser conferido pelo usuário.
- Para o [candidato 27](../Design/IconCandidates/27-pressed-z-extended-base.png), o usuário apontou a margem vazia sob a base em uma versão intermediária do enquadramento. A base metálica inferior agora se prolonga até a borda da imagem, mantendo o Z entre os platôs; continua pendente a avaliação no Icon Composer.
- As prévias do Icon Composer mostraram excesso de detalhes e perda de legibilidade do Z, especialmente em tamanhos pequenos e na apresentação mono. O [candidato 28 colorido](../Design/IconCandidates/28-simplified-press-z-color.png) reduz a composição a cilindro curto com pintura de segurança, dois platôs e Z dominante, sem faíscas. A [versão mono](../Design/IconCandidates/28-simplified-press-z-mono.png) usa silhueta branca plana correspondente, com [fonte SVG](../Design/IconCandidates/28-simplified-press-z-mono.svg). A avaliação no Icon Composer continua pendente.
- No refinamento da versão colorida, o usuário pediu que o cilindro listrado avance até a borda superior, que a base metálica alcance a borda inferior e que o conjunto suba para centralizar verticalmente o Z. O [candidato 29](../Design/IconCandidates/29-simplified-press-z-edge-crop.png) aplica esses recortes e deslocamento; a versão mono do candidato 28 permanece sem alteração nesta rodada.
- O usuário pediu uma versão colorida mais afastada da câmera. O [candidato 30](../Design/IconCandidates/30-simplified-press-z-distant.png) reduz a escala aparente do Z e dos platôs, deixando mais espaço lateral, enquanto o cilindro listrado continua pela borda superior e a base metálica pela borda inferior. A versão mono permanece a do candidato 28; o encaixe no Icon Composer continua pendente.
- O usuário pediu separar o candidato 30 em duas ou três camadas coerentes para o Icon Composer. O [plano de três camadas](../Design/IconCandidates/31-layer-plan.md) define base ao fundo, Z no meio e cabeçote da prensa à frente, todos no mesmo canvas e sem incluir o fundo arredondado da prévia. As tentativas de isolamento por geração alteraram escala e posição; ainda não há camadas alinhadas entregues.
- Posteriormente, o usuário exportou seu próprio `zforge_icon.icon` no Icon Composer, com três imagens em dois grupos e variantes de aparência, e pediu seu uso no aplicativo. O arquivo exportado agora é a fonte do ícone em Debug e Release; a comparação visual com as prévias do Composer permanece pendente.

## 2. Estrutura principal da janela

A janela usa `NavigationSplitView` com:

- sidebar à esquerda;
- conteúdo principal à direita;
- toolbar integrada ao título da janela;
- barra de caminho no rodapé do conteúdo.

### Sidebar

- Usar `List` com `.listStyle(.sidebar)`.
- Manter Recentes como a primeira linha, sem seção ou cabeçalho de categoria, usando o símbolo `clock` e abrindo a lista virtual correspondente no navegador.
- Cada janela comum abre inicialmente em Recentes. Quando ainda não houver bookmark para a Home, solicitar essa autorização na abertura porque ela delimita o escopo da consulta do Spotlight; o cancelamento mantém a explicação e a ação para tentar novamente.
- O diretório real da conta do usuário aparece como a primeira entrada de Locais, identificado pelo nome da pasta (por exemplo, `felipe`) em vez do rótulo genérico “Home”. Não usar como destino o diretório Home redirecionado para o container do App Sandbox.
- Em “Go to Folder”, `~` e caminhos iniciados por `~/` são expandidos a partir desse mesmo diretório real da conta, nunca pela Home redirecionada do App Sandbox.
- Os favoritos Desktop, Documents e Downloads apontam para as pastas correspondentes dentro do diretório real da conta do usuário. As APIs de busca redirecionadas pelo App Sandbox não devem fazer essas entradas apontarem para `Library/Containers/.../Data`.
- Favoritos permite fixar novas pastas reais por “Add to Sidebar” no menu contextual compartilhado pelos quatro modos, ou por drop no cabeçalho, entre as entradas e após o último favorito. A sidebar não exibe “Add Folder…”. O cabeçalho insere no início, os intervalos inserem antes da próxima entrada e o espaço final acrescenta ao fim. Fixar não transfere o conteúdo; o corpo dos destinos conserva cópia/movimentação/alias. “Remove from Sidebar” remove apenas a referência.
- Fixar aceita seleção múltipla composta apenas por pastas, rejeita arquivos, packages e conteúdo virtual de archives, evita duplicatas e persiste a ordem entre sessões/janelas. “Remove from Sidebar” remove somente a referência. O corpo de cada destino conserva o fluxo de copiar/mover arquivos já implementado. O usuário confirmou o funcionamento em 2026-10-03; os limites da automação permanecem na matriz de regressão.
- **Refinamento visual escolhido em 2026-10-03 — alternativa B, espessura refinada em 20:22:** linha accent de `2 pt`, círculo vazado de `8 pt` com contorno de `2 pt`, começando `8 pt` à esquerda do conteúdo. Desenhar no limite completo das linhas numa camada visual acima das células nativas, sem recortar o círculo/linha e sem interceptar cliques ou drops; acompanhar scroll. O backing layer do indicador deve permanecer acima das camadas de highlight, inclusive após atualizações nativas. Usar insets verticais nativos zerados e padding equivalente dentro do botão, preservando altura. Os primeiros/últimos `5 pt` de cada favorito representam inserção; o corpo representa transferência. A borda inferior do último favorito e o cabeçalho de Locais permitem acrescentar ao fim. Favoritos vazio aceita pin no cabeçalho. Manter handlers por item; não substituir por um destino global na List.
- A sidebar mantém os símbolos originais durante drag; nunca os troca por pasta aberta. O alvo de transferência recebe um fundo accent sólido arredondado, com texto e símbolo branco, sem alternância para contorno. A pasta real atual, quando representada na sidebar, recebe fundo monocromático discreto (`unemphasizedSelectedContentBackgroundColor`) e nome semibold, como na captura de referência; arraste tem prioridade e a seleção retorna ao sair. O fundo mantém margem horizontal de 10 pt.
- O highlight transitório desaparece ao sair do destino ou soltar o drag; a limpeza também acompanha posição/botão nativos do destino ativo. Callbacks de owners anteriores não podem limpar um alvo novo. Desativar somente o feedback nativo da tabela da sidebar, preservando tabelas e handlers de conteúdo.
- A seção Tags fica ao fim da sidebar e exibe o catálogo global dos arquivos autorizados e favoritos do Finder, independente da pasta atual. Seus círculos medem 12 pt (redução de 4 pt), com cor real ou contorno para tags sem cor. Toda a linha aceita clique e abre o filtro global correspondente, incluindo pastas marcadas. Alterações de tags atualizam a sidebar e o filtro aberto automaticamente; a descoberta inicial é progressiva. Voltar/avançar preserva o filtro.
- Para localizações do sistema de arquivos, o breadcrumb sempre mostra o caminho completo desde o volume, por exemplo `Macintosh HD > Users > felipe`, mesmo quando a navegação começou por uma entrada intermediária da sidebar. Esses ancestrais visuais não devem criar níveis vazios na visualização em Colunas.
- A superfície deve continuar visualmente pelo topo da janela, sem corte entre sidebar e titlebar.
- Usar material do sistema, atualmente `.ultraThinMaterial`, respeitando as safe areas.
- Largura mínima: `180 pt`.
- Largura ideal: `220 pt`.
- Largura máxima: largura atual da janela menos `360 pt`, preservando sempre essa largura mínima para o conteúdo principal.
- `navigationSplitViewColumnWidth(min:ideal:max:)` expressa larguras preferidas e, isoladamente, não impede que o divisor ultrapasse o máximo no macOS. Manter esse modificador para o layout SwiftUI e aplicar o mesmo teto em `NSSplitViewItem.maximumThickness`, que restringe também o redimensionamento manual.
- Redimensionar a janela não altera a largura escolhida para a sidebar. Quando a janela fica estreita demais, limitar a sidebar apenas enquanto necessário e restaurar sua largura anterior assim que houver espaço novamente.
- Se a sidebar for ocultada automaticamente, deve reaparecer quando houver espaço.
- Se o usuário a ocultar manualmente, essa escolha deve ser preservada.

### Superfície principal

- Usar a mesma cor em todas as visualizações.
- A referência atual é `NSColor.underPageBackgroundColor`.
- Toolbar, lista, colunas, ícones e galeria não devem apresentar mudanças arbitrárias de tonalidade.
- Manter oculto o background automático da `windowToolbar`, impedindo que o efeito de scroll edge altere sua tonalidade ao trocar de visualização ou redimensionar a janela.
- Separadores devem ser discretos e usados apenas quando esclarecem a estrutura.

## 3. Responsividade da janela

Os limites atuais são baseados nas dimensões reais da grade em zoom de 100%.

| Decisão | Valor atual |
| --- | ---: |
| Largura da célula da grade | `110 pt` |
| Espaçamento entre células | `24 pt` |
| Padding lateral da grade | `16 pt` |
| Largura mínima da janela | `544 pt` |
| Ocultação automática da sidebar | `678 pt` |

A largura mínima equivale a quatro células:

```text
4 × 110 + 3 × 24 + 2 × 16 = 544 pt
```

A janela usa `.windowResizability(.contentMinSize)` para fazer o macOS respeitar o tamanho mínimo do conteúdo.

### Regras

- Na largura mínima, quatro ícones devem caber com a sidebar oculta e zoom em 100%.
- A decisão de ocultar a sidebar considera a largura total da janela, não apenas a área de conteúdo.
- Mudanças responsivas devem acontecer em etapas, aproveitando o espaço liberado por cada compactação.
- Evitar compactar vários grupos simultaneamente se a primeira compactação já liberar espaço suficiente.

## 4. Toolbar

O modo de visualização é individual por janela/aba. Os seletores completo, compacto e de overflow, os menus e os atalhos `⌘1`–`⌘4` atuam somente na janela correspondente. Cada nova janela inicia no modo definido por “Default View” em Settings (Ícones na ausência de preferência); mudar esse padrão não altera janelas existentes, e trocar o modo de uma janela não modifica o padrão.

### Estrutura

A toolbar deve conter:

1. botão para alternar a sidebar;
2. botões de voltar e avançar;
3. título nativo com o nome do diretório atual;
4. seletor do tipo de visualização;
5. grupo de ações de archive, compartilhamento e menu adicional;
6. menu de ações adicionais.

O breadcrumb não deve ocupar a toolbar. A tentativa de usá-lo como `ToolbarItem` prejudicou o cálculo de overflow, a responsividade e a leitura do título.

### Voltar, avançar e título

- As setas mantêm um histórico real de caminhos.
- Voltar e avançar devem ser desabilitados quando não houver destino.
- O título usa `navigationTitle`, com apresentação inline, e mostra apenas o nome do diretório atual.
- A ordem visual à esquerda é sempre: botão da sidebar, cápsula de voltar/avançar e título. No macOS, itens `.navigation` independentes podem ser reordenados pelo sistema; para preservar essa sequência, remover o `.sidebarToggle` automático e reunir o botão equivalente e o `ControlGroup` das setas, nessa ordem, dentro de um único `ToolbarItem` aplicado à coluna da sidebar. O botão envia `NSSplitViewController.toggleSidebar(_:)` pela responder chain, reproduzindo a ação nativa sem observar geometria.
- O título e os itens à direita pertencem à toolbar da coluna de detalhe. Essa separação impede que o `NavigationSplitView` mova as setas para a seção das ações enquanto preserva o `navigationTitle` nativo.
- Navegação histórica e seleção de arquivos são estados diferentes.

### Seletor de visualização

O seletor tem três apresentações:

- completa: quatro segmentos com ícones;
- compacta: ícone do modo atual acompanhado de chevrons verticais;
- overflow: submenu `View` dentro do menu do duplo chevron.

No menu de overflow:

- `View` abre um submenu nativo;
- o submenu mostra ícone e nome de cada visualização;
- marcar a visualização atual;
- permitir escolher ícones, lista, colunas ou galeria.

Entre `678` e `899 pt`, o seletor usa uma cápsula compacta própria, com o ícone do modo atual e chevrons verticais. Abaixo de `678 pt`, o seletor entra no overflow e passa a ser o submenu `View`. Ao reduzir a janela a partir da apresentação completa, compactar o seletor antes de ocultar a ação contextual de archive e não voltar à apresentação segmentada em larguras menores.

### Grupo de ações

Na apresentação expandida, o grupo permanece com quatro ações:

1. ação contextual de archive;
2. Share;
3. Tags (`tag`), para editar a seleção local;
4. reticências para ações adicionais.

As quatro ações compartilham uma única cápsula nativa, separada da cápsula do seletor de visualização. Cada label preserva uma faixa visual de `25 pt` para manter o padding regular entre os símbolos.
Elas devem ser declaradas como itens nativos de um `ToolbarItemGroup`, delimitado do seletor por um `ToolbarSpacer` fixo. Não envolver o conjunto em um `ControlGroup` adaptativo dentro de um único `ToolbarItem`: depois de passar pelo overflow, essa composição pode retornar à toolbar conservando o espaçamento compacto.

Em Recentes, a ação contextual é habilitada conforme a seleção. A extração usa por padrão a pasta real de cada archive, e a compressão conjunta grava o archive na pasta do item ativo. A escolha explícita de destino nos painéis continua disponível.

Quando o grupo de ações não cabe, um botão com duplo chevron reproduz o indicador nativo de overflow da toolbar. Entre `840` e `899 pt`, a ação contextual de archive continua visível em cápsula própria e o menu começa por Share; abaixo de `840 pt`, a ação de archive também entra no menu. Open, Quick Look, Get Info, Edit Tags, Rename e Duplicate permanecem sempre expandidos no nível principal desse menu. Diferentemente do Finder, esse conteúdo não vira um submenu `Action`. Abaixo de `678 pt`, o submenu `View` é acrescentado no início. As ações usam os mesmos handlers e estados habilitados da apresentação expandida; não delegar esse comportamento ao overflow automático da `NSToolbar`.

No espaço vazio da área de itens, o clique secundário e Control-clique abrem o menu do botão `•••` expandido, conservando a seleção atual e os estados habilitados. Sem seleção, manter as ações visíveis e desabilitadas. Aplicar aos quatro modos; o menu próprio da célula tem prioridade. Preservar o clique primário que limpa a seleção, os previews e os controles de layout.

No clique secundário de um item, oferecer Open with, Share e Copy sem perder a seleção múltipla quando o item já pertence a ela. Open with é um submenu dos apps compatíveis, com Other… para escolha manual; com Option vira Always open with para arquivos locais. Copy vira Copy pathname com Option, copiando texto em vez de referências de arquivo. Quick Look vira Slideshow com Option. No menu File, New tab usa `⌘T` e Open with/Always open with e Quick Look/Slideshow seguem a mesma alternância nativa. Desabilitar ações sem alvo válido e localizar todos os novos rótulos.

O duplo chevron usa cor secundária enquanto o menu está fechado e só assume a cor primária durante o ciclo real de apresentação do `NSMenu`, retornando ao estado secundário em `menuDidClose`. Quando archive ou overflow aparecem como botões isolados, seus labels usam uma área quadrada de `18 pt` e símbolos menores que os do grupo expandido, preservando um background circular em vez de oval.

### Breakpoints da toolbar

| Largura da janela | Seletor de visualização | Ações |
| --- | --- | --- |
| `≥ 900 pt` | completo | quatro ações |
| `840–899 pt` | cápsula compacta | archive visível; demais no duplo chevron |
| `678–839 pt` | cápsula compacta | expandidas no menu de duplo chevron |
| `< 678 pt` | submenu no menu de duplo chevron | expandidas no mesmo menu |

Esses valores são parâmetros de calibração. Caso tamanhos de ícones, título ou ações mudem, medir novamente antes de alterá-los.

## 5. Lições sobre toolbar no SwiftUI

Estas restrições devem ser consideradas antes de tentar corrigir a toolbar:

- A `NSToolbar` pode enviar um `ToolbarItem` ao overflow sem antes propor uma largura menor ao conteúdo. Por isso, `ViewThatFits` dentro da toolbar pode nunca receber a oportunidade de compactar.
- Um `Menu` colocado diretamente na toolbar pode normalizar o label para um único ícone, descartando padding, HStacks e símbolos adicionais.
- `.secondaryAction` não significa “overflow apenas”. O macOS pode promover essas ações de volta para a toolbar quando houver espaço.
- Um `ControlGroup` adaptativo dentro de um único `ToolbarItem` pode conservar sua aparência compacta depois de sair do overflow.
- Para responsividade determinística, preferir breakpoints explícitos baseados na largura da janela e trocar a hierarquia do controle antes do overflow.
- Para botões compactos com composição visual própria, usar um `Button` SwiftUI comum.
- Apresentações condicionais da toolbar usam identificadores próprios por estágio; não reutilizar o mesmo `ToolbarItem` entre hierarquias diferentes, pois o AppKit pode conservar a cápsula nativa enquanto descarta temporariamente seu conteúdo SwiftUI durante o redimensionamento.
- Para menus que precisam de ícones, estados marcados, seções ou conteúdo plano previsível, uma ponte pequena para `NSMenu` é aceitável.
- Não usar `.id(windowWidth)` para forçar reconstrução durante cada pixel de redimensionamento; isso mascara o problema e causa trabalho excessivo de layout.

### Abas de janela

- Usar o sistema nativo de abas do `NSWindow`, compartilhando um `tabbingIdentifier` entre as janelas comuns do navegador e mantendo `tabbingMode = .automatic`.
- O menu View usa apenas o comando nativo Show Tab Bar/Hide Tab Bar do macOS, com `Shift + Command + T`; não acrescentar um segundo comando para a mesma ação.
- A barra de abas pertence à moldura da janela, não ao conteúdo SwiftUI. Portanto, atravessa toda a largura da janela acima da sidebar, do conteúdo e do preview; não deve ser recortada pelo split interno do inspector.
- A URL do diretório atual deve ser atribuída a `representedURL`, permitindo que o AppKit apresente a hierarquia de pastas ao clicar no título da janela com Command.
- Referência local: [NSWindow](../SwiftUI/contexts/appkit-nswindow.md).

## 6. Barra de caminho no rodapé

O breadcrumb fica no canto inferior do conteúdo, em uma barra persistente com separador superior discreto.

### Regras

- Exibir no máximo os três últimos níveis da hierarquia.
- Se houver níveis anteriores, começar com `… ›`.
- Nomes de diretórios ancestrais com mais de 10 caracteres exibem os sete primeiros caracteres mais `...`.
- O diretório atual mantém o nome completo enquanto houver espaço.
- Cada componente é clicável e navega diretamente para aquele diretório.
- Quando nem a apresentação reduzida couber, mostrar apenas o diretório atual como menu.
- O menu compacto deve listar o caminho completo e permitir navegar para qualquer ancestral.
- Usar ícones reais de diretório em cada componente.

## 7. Modelo de interação comum

As quatro visualizações compartilham as mesmas regras fundamentais:

- clique simples seleciona;
- clique duplo abre;
- clique secundário seleciona o item e abre o menu de contexto;
- clicar em uma área vazia desfaz toda a seleção;
- a área clicável deve cobrir toda a célula ou linha, usando `contentShape` quando necessário;
- botões internos, como disclosure arrows, executam sua ação sem depender do clique no texto ou ícone;
- trocar o tipo de visualização não deve deixar o foco preso na toolbar;
- a seleção atual deve continuar coerente ao trocar de visualização sempre que o item ainda for válido.
- Quando arquivos ocultos estiverem visíveis, atenuar ícone, nome e metadados para `55%` de opacidade nas quatro visualizações. Para um oculto selecionado, usar `72%` para preservar a legibilidade; o fundo de seleção permanece com opacidade integral.
- `Return` inicia a renomeação inline quando houver exatamente um item local selecionado; `Return` confirma e `Escape` cancela enquanto o campo estiver ativo.
- Uma pasta criada por `Shift + Command + N` é selecionada e entra imediatamente no mesmo modo de renomeação inline.
- `Command + Z` usa o `UndoManager` da janela ativa para desfazer a última operação de arquivo concluída. Criar pasta, renomear, copiar, mover, criar alias, duplicar e mover para o Lixo registram sua inversa somente após sucesso; navegação e seleção não entram nesse histórico.
- Itens do navegador não usam `Command + X`: `Command + C` é a única ação que os coloca no Clipboard, `Command + V` sempre os copia e `Option + Command + V` os move.
- `Command + C` publica as `NSURL` originais diretamente no `NSPasteboard`, usando `clearContents()` e `writeObjects(_:)`, não representações materializadas por `NSItemProvider`. Assim, `Option + Command + V` entrega ao `FileManager.moveItem` a origem real, move os itens para o destino e os remove da localização anterior.
- No menu Editar, Move Items Here é a alternativa nativa de Paste por meio de `modifierKeyAlternate(.option)`. A movimentação valida as URLs do Clipboard ao ser executada e chama a operação `.move` do serviço de arquivos.
- A origem de drag de arquivos locais anuncia suporte a cópia, movimentação e alias dentro e fora da aplicação. Durante o arraste, `Option` força cópia, `Command` força movimentação e `Option + Command` cria alias; a operação é resolvida a partir de um estado de referência atualizado pelo SwiftUI e compartilhado com o `DropDelegate` durante toda a sessão.
- Soltar um item na própria pasta sem modificador não duplica o item, inclusive quando as URLs usam symlinks ou marcação diferente de diretório. O payload de drag deve conservar a localização original. Option continua solicitando cópia; o drop de pin adiciona somente uma referência.
- Pastas nas quatro visualizações e destinos de pasta na sidebar aceitam drops e permanecem destacados enquanto o cursor estiver sobre o alvo válido. Nas views de conteúdo, o destaque usa a cor semântica de accent do sistema, com preenchimento translúcido e contorno, e desaparece em `dropExited` ou antes de executar o drop. Nas quatro views de conteúdo, enquanto uma pasta é o alvo, seu ícone transiciona por `0,18 s` para o ícone nativo de pasta aberta e retorna ao ícone original ao sair. A sidebar é exceção: mantém seu símbolo e usa o feedback sólido descrito na seção Sidebar. Na sidebar, o conteúdo do destino mantém padding interno de `4 pt` na horizontal e `8 pt` na vertical, com insets verticais nativos zerados para preservar altura e alinhar as zonas de drop.
- “Add to Archive…” aparece nas ações contextuais de itens locais e abre um painel para escolher o archive. Um archive ZIP ou 7z visível e pastas internas do archive raiz aceitam drops com destaque de destino; nesse fluxo de adição de itens locais, a operação é sempre cópia. Antes de modificar o archive escolhido ou o alvo do drop, um diálogo identifica o destino e a quantidade de itens e oferece Adicionar ou Cancelar. Adicionar deve executar o pedido confirmado mesmo quando o fechamento do diálogo limpa o estado de apresentação antes da tarefa assíncrona; Cancelar/dispensar não modifica o archive. Após sucesso dentro de um archive aberto, conservar a pasta atual sobrevivente e o breadcrumb anterior ao archive. Renovar o histórico de Voltar/Avançar sem saltar níveis nem sair prematuramente do archive; repopular todas as colunas ancestrais e suas seleções com os endereços da nova sessão. Na Lista, reabrir o archive que estava expandido inline, restaurar seus diretórios expandidos por caminho interno e abrir os ancestrais do destino; selecionar os novos itens para mostrar o resultado sem exigir expansão manual. Preservar as árvores e sessões dos demais archives.
- **Itens internos para fora:** sem modificador, extrair copiando e mostrar indicador nativo de cópia; Option extrai e remove do archive, usando `.move` sem o indicador. Ignorar a tradução automática de modificadores do AppKit na origem virtual e aplicar a política explicitamente. Destinos internos consultam os modificadores atuais no update/drop; arquivos locais mantêm Option = cópia.
- A origem virtual inicia a sessão no despacho de `mouseDragged`, conservando cliques e menus SwiftUI. O token interno é dado imediato no pasteboard; somente o conteúdo é uma promessa. Cada promessa pode ser cumprida antes do callback final da origem e antes de o receptor solicitar o próximo arquivo. A remoção depende de todas as publicações bem-sucedidas e da operação final `.move`; cancelamento preserva o archive.
- File promises escrevem na URL fornecida, sem recriar os ancestrais internos. Todas as exportações devem terminar antes da remoção; falha, cancelamento ou conflito mantido conserva origens. Escrita somente no ZIP/7z raiz de volume único; formatos de leitura/conteúdo aninhado permitem copiar. Renovar a sessão/árvore alterada, conservando árvores de outros archives.
- “Remove from Archive…” na matriz contextual/overflow, menu File e `⌘Delete` para seleção interna compatível usa confirmação de remoção permanente, sem Lixo/undo. Cancelar não modifica o archive; pastas incluem descendentes e remover o último item mantém um archive vazio navegável.
- `performDrop(info:)` inicia o carregamento de todos os `NSItemProvider` antes de retornar. As conclusões podem chegar depois e então acionar a transferência assíncrona, mas não se deve adiar a própria chamada de carregamento para uma `Task`, pois o sistema restringe o acesso ao payload ao escopo inicial do drop.
- Referência local: [modifierKeyAlternate(_:_:)](../SwiftUI/contexts/swiftui-modifier-key-alternate.md).

### Seleção múltipla

- Clique comum substitui a seleção.
- `Command` + clique adiciona ou remove um item individualmente.
- `Shift` + clique seleciona o intervalo entre a âncora e o novo item.
- `Shift` + setas amplia a seleção pelo teclado.
- A aplicação mantém separadamente:
  - item ativo;
  - conjunto de itens selecionados;
  - âncora da seleção por intervalo.

### Cor da seleção

- Usar `NSColor.selectedContentBackgroundColor` como referência.
- Não fixar um azul customizado excessivamente saturado.
- A seleção deve respeitar tema e cor de destaque do usuário.
- Na visão de ícones, seguir o Finder: destaque discreto no ícone e azul concentrado no rótulo, evitando um grande bloco azul na célula inteira.
- Na visão de colunas, a seleção da coluna ativa usa a cor de seleção; a hierarquia aberta em colunas anteriores usa cinza discreto.

## 8. Visualização de ícones

- Usar `LazyVGrid` adaptativa.
- Célula base: `110 pt`.
- Espaçamento base: `24 pt`.
- Padding externo: `16 pt`.
- Ícone base: `64 pt`, dentro de uma área visual de `84 × 72 pt`.
- Nome em até duas linhas, centralizado.
- A célula inteira é a hitbox.
- A navegação por teclado acompanha o número real de colunas visíveis.
- Ao selecionar pelo teclado, rolar automaticamente para manter o item visível.

## 9. Visualização de lista

### Estrutura

Colunas exibidas inicialmente:

- Nome;
- Data de modificação;
- Tamanho;
- Tipo.

Clique secundário em qualquer header abre as opções de colunas do Finder. Nome fica fixo; Data de Criação, Última Abertura, Data de Adição, Versão, Comentários e Tags podem ser ativadas. Modificado por e Compartilhado por ficam indisponíveis sem dados de colaboração. Arrastar os demais headers altera a ordem por diretório. Settings controla a visibilidade e a ordem globais; o menu local termina com uma linha horizontal e **Restore defaults** (**Restaurar padrão**), removendo a substituição da pasta. O padrão inicial de quatro colunas é preservado. Os círculos de tags medem 8 pt em 100% e ficam à direita do nome independentemente da coluna Tags.

Os headers são clicáveis:

- primeiro clique ordena de forma ascendente;
- novo clique no mesmo campo inverte a direção;
- o campo ativo mostra chevron para cima ou para baixo.

### Linhas

| Métrica | Valor base |
| --- | ---: |
| Altura da linha | `24 pt` |
| Ícone | `16 pt` |
| Inset horizontal da área | `8 pt` |
| Inset interno da linha | `4 pt` |
| Área da disclosure arrow | `18 pt` |
| Corner radius | `7 pt` |
| Largura mínima da coluna Nome | `168 pt` |
| Largura mínima da tabela | `612 pt` |

- Não usar linhas divisórias entre itens.
- Alternar fundos para facilitar leitura: uma linha transparente e outra com `Color.primary.opacity(0.06)`.
- As faixas claras e escuras devem ter exatamente a mesma altura.
- A zebra deve preencher a hitbox, sem intervalos verticais.
- O nome deve começar na mesma posição independentemente da largura visual do símbolo.
- Cabeçalho e linhas formam uma única superfície horizontal e preservam exatamente o mesmo alinhamento durante a rolagem.
- O cabeçalho mantém uma borda inferior visível separando-o dos arquivos e divisores verticais entre suas células. Todos os títulos usam inset interno de `6 pt` em relação aos divisores. Em Data de Modificação, Tamanho e Tipo, os valores usam o mesmo inset e permanecem alinhados aos respectivos títulos; o conteúdo das linhas da primeira coluna mantém seu alinhamento original. Os divisores não alteram as larguras das colunas nem restringem a área clicável usada para ordenação.
- A tabela nunca deve reduzir a coluna Nome abaixo de `168 pt` para tentar caber na janela. Abaixo da largura mínima de `612 pt` em escala de 100%, ela conserva as larguras das colunas e passa a rolar horizontalmente.
- Sem preview, a superfície da Lista ocupa toda a área principal e o conteúdo excedente continua à direita, acessível por rolagem horizontal.
- Com preview, a largura útil da tabela é a largura da área principal menos a largura ajustável do painel à direita (padrão `300 pt`). Enquanto essa largura útil for menor que os `612 pt` mínimos, a tabela conserva suas colunas, transborda por trás do painel translúcido e a área rolável inclui uma folga final igual à largura do preview.
- Assim que a tabela mínima couber inteira ao lado do preview, nenhuma coluna permanece encoberta. A coluna Nome só começa a crescer além de `168 pt` usando o espaço que sobrar depois de acomodar todas as outras colunas e o painel.
- Enquanto a tabela exigir rolagem horizontal, os fundos alternados e de seleção das linhas ficam sem margem lateral e sem cantos arredondados, para que a borda visível não pareça diferente da borda encoberta. O conteúdo textual mantém o mesmo alinhamento com o cabeçalho. Quando a tabela voltar a caber inteira, retornam a margem de `8 pt` e o corner radius de `7 pt`.
- Largura mínima da tabela, larguras das colunas e folga do preview acompanham a escala visual da janela.

### Hierarquia

- Pastas exibem chevron à direita quando recolhidas e para baixo quando expandidas.
- Clicar diretamente no chevron expande ou recolhe.
- `Option` + clique no chevron alterna toda a hierarquia: expande recursivamente quando o item raiz está recolhido e, quando ele já está expandido, recolhe o item raiz e todos os descendentes expandidos.
- Filhos usam indentação de `20 pt` por nível.
- Expandir não deve abrir a pasta como diretório atual.
- Comandos de criação, cópia, movimentação e alias usam como destino o diretório que contém a linha ativa. Uma linha no nível raiz pertence ao diretório atual; uma linha filha visível pertence à pasta expandida imediatamente acima dela. A pasta selecionada nunca passa a ser o destino apenas por estar selecionada.
- Pastas expandidas observam alterações no próprio diretório e atualizam seus filhos sem exigir recolher, navegar para outro local ou reabrir a pasta.
- Quando o item ativo deixa de existir durante uma atualização, o cursor ocupa a mesma posição na ordem achatada, selecionando assim o próximo item; se não houver item nessa posição, seleciona o último item restante.
- Com muitos itens, ordenação, projeção achatada da hierarquia e consulta de ícones devem ser reutilizadas enquanto suas entradas não mudarem. Atualizações de seleção e layout não podem repetir ordenações `O(n log n)` nem novas consultas ao `NSWorkspace` para cada linha visível.

## 10. Visualização de colunas

- Cada coluna tem largura base de `260 pt`.
- A primeira coluna começa na borda esquerda da área de conteúdo e conserva a largura base; a sobra à direita pertence ao espaço disponível para um preview que venha a ser carregado.
- Linhas usam as mesmas métricas da visualização de lista.
- Colunas têm separadores verticais discretos.
- Selecionar uma pasta cria a próxima coluna.
- Durante o carregamento da próxima coluna, preservar as linhas/seleção da coluna de origem e exibir apenas dados pertencentes à localização de destino. Sem dados próprios carregados, a nova coluna permanece sem linhas; nunca usar a lista global anterior como fallback nem duplicá-la por um quadro. A regra vale para pastas reais, archives e alternância de ramo.
- Selecionar um item em uma coluna anterior elimina todas as colunas posteriores que não fazem mais parte do caminho.
- O item selecionado na coluna ativa permanece azul mesmo depois que uma pasta abre a coluna seguinte; o carregamento dos filhos não pode limpar essa seleção nem rebaixá-la para cinza.
- Seleções preservadas em colunas inativas recebem destaque cinza.
- Ao sair de Colunas para Ícones, Lista ou Galeria, se o item ativo tiver aberto uma coluna filha, a nova visualização retorna para a localização da coluna ativa e mantém esse item selecionado. A troca não entra no item nem cria uma entrada no histórico.
- Ao adicionar uma coluna ou preview além da largura visível, rolar horizontalmente até o fim.
- Antes de expandir uma pasta/archive naquele ramo, cada preview carregado usa a largura livre à direita das colunas visíveis, respeitando o mínimo de 240 pt. Uma alteração manual do divisor vale apenas para o preview atual.
- Ao expandir uma pasta/archive, exibir por inteiro a nova coluna à direita. Ela preenche o espaço restante, respeitando ao menos a largura base e 240 pt quando o preview está visível. Enquanto a visão segue alinhada à direita, o preview de arquivo na coluna anterior substitui essa coluna na mesma posição e largura.
- Se o usuário rolar horizontalmente à esquerda, conservar a largura do preview atual mesmo quando parte dele ficar fora da janela. Ao selecionar outro arquivo, recalcular a largura do novo preview pela sobra à direita da coluna visível e preservar a posição de rolagem à esquerda; ao abrir uma pasta/archive, voltar a exibir a coluna terminal por inteiro e alinhar à direita.
- Ao voltar para uma coluna anterior com o teclado, a pasta que originou a próxima coluna deve estar selecionada.
- Selecionar um arquivo cria um painel de preview, não uma coluna de diretório vazia.

### Preview em colunas

- Largura inicial antes da expansão do ramo, ou após rolagem manual à esquerda: espaço disponível à direita das colunas abertas no momento do carregamento, com mínimo de `240 pt` e sem máximo. Após a expansão, previews seguintes naquele nível ocupam a faixa da coluna terminal enquanto a navegação permanecer alinhada à direita. O divisor permite ajuste manual apenas do preview atual.
- Exibir preview do arquivo, nome, tipo, tamanho, datas e etiquetas.
- Para múltiplos itens, exibir resumo agregado.
- Usar Quick Look para conteúdo real quando disponível.
- Avisos de extensões internas do Quick Look que não impedem o preview não devem ser confundidos com erros da aplicação.

## 11. Visualização de galeria

- Área principal dedicada ao preview.
- Faixa horizontal de itens no rodapé, com altura base de `96 pt`.
- Cada miniatura ocupa aproximadamente `96 × 72 pt`.
- A miniatura selecionada recebe destaque discreto.
- Clicar no espaço vazio da área principal ou da faixa inferior desfaz a seleção.
- Quando não há seleção, deixar a área principal vazia; não mostrar “Pasta vazia”.
- Metadados ficam em um inspector à direita, com largura inicial de `300 pt`, ajustável pelo divisor com o mouse e compartilhada com os previews de Ícones e Lista.
- O inspector deve existir tanto para seleção simples quanto múltipla.

## 12. Preview e seleção múltipla

- A visibilidade do preview é persistida de forma independente para Ícones, Lista, Colunas e Galeria. Ao trocar de modo ou reabrir a aplicação, restaurar o último estado usado naquele modo sem sobrescrever os demais.

### Seleção simples

- Pasta: usar ícone real do sistema em tamanho grande.
- Arquivo: usar Quick Look quando possível.
- Para `.html` e `.htm`, renderizar o documento local no preview com o layout, CSS e recursos estáticos relativos ao arquivo, como no Finder; a troca de seleção descarta a página anterior. O conteúdo local estático aparece sem esperar recursos remotos. Imagens, CSS e fontes remotos referenciados pelo arquivo podem ser requisitados, como no Finder; não executar JavaScript do documento.
- Exibir nome, tipo, tamanho, datas e etiquetas.

### Seleção múltipla

- Mostrar até cinco ícones no hero.
- Tamanho base dos ícones: `200 pt`.
- Criar uma pilha informal, com pequenas rotações e offsets.
- Ordenar a pilha pela recência da seleção: o último item selecionado aparece sempre no topo.
- O efeito deve lembrar papéis soltos, sem ângulos extremos.
- Usar sombra discreta para separar as camadas.
- Mostrar quantidade de itens, composição entre documentos e pastas, tamanho total, intervalo de datas e etiquetas agregadas.
- No inspector compacto, usar no máximo três ícones pequenos empilhados.

## 13. Navegação por teclado

### Comandos globais

- `Command + ↑`: voltar para o diretório pai.
- `Command + ↓`: abrir o item selecionado.
- `Command + +` ou `Command + =`: aumentar escala.
- `Command + -`: diminuir escala.
- `Command + 0`: restaurar escala para 100%.

A escala atual varia de 70% a 160%, em passos de 10%.

### Ícones

- Esquerda/direita: item anterior ou seguinte na linha.
- Cima/baixo: mesma coluna visual na linha anterior ou seguinte.
- O cálculo deve usar a quantidade real de colunas da grade.

### Lista

- Cima/baixo: mover entre linhas visíveis.
- Direita: expandir a pasta selecionada.
- Esquerda: recolher pasta expandida; se já estiver recolhida, selecionar o pai visível. No nível raiz, não há ação.

### Colunas

- Cima/baixo: mover entre itens da coluna ativa.
- Esquerda/direita: mover entre colunas.
- Direita sobre pasta: abrir próxima coluna.
- Esquerda: voltar mantendo selecionada a pasta que originou a coluna seguinte.

### Galeria

- Esquerda/direita percorrem a faixa de itens.
- A miniatura selecionada deve rolar para a área visível.

## 14. Ícones e dados reais

- Usar `NSWorkspace.shared.icon(forFile:)` para obter os mesmos ícones do sistema.
- Não pintar pastas e documentos com um azul arbitrário quando houver ícone real disponível.
- Diretórios dentro de archives preservam a pasta nativa e recebem o selo da **v6 aprovada**, com cavidade circular e volume interno da prensa/Z. A faixa e toda a linha do círculo são contínuas sobre o cilindro, que alcança a abertura sem ultrapassá-la. A forma, luz e sombra usam a referência aprovada, por máscaras neutras que modulam o material da pasta; não copiar o fundo azul nem substituir a pasta por uma imagem completa. A iluminação atual é fixa; mapa de altura/luz dinâmica era uma proposta anterior, não a técnica implementada.
- Até 32 pt inclusive, centralizar o selo na face; acima disso, usar a face inferior direita. Ajustar pelo tamanho após zoom: 48% de diâmetro no compacto, 38% até 48 pt, 34% abaixo de 128 pt e 30% nos previews grandes, com posicionamento mais alto aprovado. Um único recurso alimenta todas as escalas.
- Pastas locais comuns reutilizam a composição nativa refinada das pastas internas, removendo somente o selo de compressão. Manter os quatro estados (aberta/fechada, vazia/com conteúdo), material, borda sobre o papel e perspectiva aprovados; usar a composição compartilhada nos quatro modos, previews e Informações. Na Lista, expansão abre linha e preview; recolhimento fecha. Outros modos não herdam expansão anterior. Preservar a transição aberta no drop local e a detecção de qualquer filho direto (incluindo ocultos e subpastas). Arquivos e packages mantêm seus ícones específicos do sistema.
- Pastas internas com arquivos usam uma pasta **fechada**, com faixa de papel larga e cantos arredondados atrás da face nativa, conforme a referência do usuário. O papel deve ficar atrás de toda a borda superior arredondada da face: restaurar o recorte completo da face nativa acima do papel, sem interrompê-la com corte horizontal abaixo da borda. O selo aprovado permanece na face. Detectar arquivos pelos metadados reais do archive, inclusive descendentes, ocultos e zero bytes; não inferir pelo tamanho agregado. Pastas vazias ou apenas com subpastas vazias mantêm a versão sem papel. A antiga versão aberta de estudo foi rejeitada e retirada do compositor; a regra abaixo define a nova pasta aberta aprovada. Aplicar o mesmo estado em Lista, Colunas, Ícones, Galeria e previews. Histórico, referências e [plano](../Design/ArchiveFolderStamp/DEBOSSING-PLAN.md) preservados em `../Design/ArchiveFolderStamp`; a v6 foi autorizada e integrada.
- **Pasta aberta aprovada e integrada:** na Lista, a expansão de um diretório interno troca seu ícone e o hero do preview pela versão aberta da mesma pasta nativa com selo aprovado; aplicar também aos heros de seleção múltipla. Recolher restaura a pasta fechada, com papel apenas quando há arquivos. Seleção não equivale a expansão. A composição deve preservar cor, gradiente e cantos arredondados da pasta fechada, inclinar face e selo juntos e ter sombra de contato; a área atrás do papel deve mostrar somente o painel traseiro, sem sobras arredondadas da face fechada nas duas laterais e sem linhas/faixas horizontais junto ao papel; usar gradiente contínuo do material traseiro para essa região, amostrado apenas acima da face fechada; a versão vazia deve ter painel contínuo, sem silhueta/gradiente residual do papel e sem degrau na borda esquerda; remover o contorno cinza do papel, sem recortes/vazados; manter a largura da base original e alargar somente a borda superior da face que avança para o observador; não usar o recurso antigo `ofld`, cuja textura e base foram rejeitadas pelo usuário. Os outros três modos mantêm o estado fechado. A nova proposta v7 substitui apenas a antiga ideia de pasta aberta; o estudo aberto anterior permanece rejeitado. Drag and drop de itens internos de archives ainda é pendência, sem novo comportamento de arraste nesta integração.

- Usar `URLResourceValues` para tamanho, datas e etiquetas.
- Separar leitura do sistema de arquivos, estado de navegação e composição visual.
- As visualizações usam os itens reais do serviço de arquivos, de Recentes ou do motor de archives. Fixtures de desenvolvimento não definem o conteúdo mostrado ao usuário.

## 15. Localização

### Referência de atalhos

- O menu Ajuda contém `Keyboard Shortcuts…` (`Command + /`), que abre uma janela auxiliar única da aplicação.
- A janela agrupa comandos de arquivos, navegação, visualização, preview e interações modificadas com mouse ou arraste. A referência deve permanecer sincronizada com os atalhos realmente registrados nos menus e handlers da aplicação.
- A janela oferece busca nativa na toolbar e filtra ações, categorias e representações dos atalhos sem ocultar o agrupamento dos resultados.
- As combinações usam os glifos nativos do macOS (`⌃`, `⌥`, `⇧` e `⌘`) e mantêm a ação correspondente legível e localizável.
- Quando uma mesma ação aceita mais de uma combinação equivalente, como Quick Look com `Space` ou `Command + Y`, ela ocupa uma única linha e apresenta as combinações em cápsulas separadas lado a lado.

Idiomas atuais:

- inglês;
- português do Brasil.

Regras:

- A preferência padrão é o idioma do sistema.
- Percorrer `Locale.preferredLanguages` até encontrar um idioma suportado.
- Mapear qualquer variante de português para `pt-BR` enquanto for a única tradução em português.
- Mapear inglês para `en`.
- Se nenhum idioma puder ser mapeado, usar inglês.
- Permitir escolha manual em Settings.
- Persistir a escolha em `UserDefaults` por meio de `FileBrowserPreferences`.
- Injetar a `Locale` selecionada no ambiente SwiftUI.
- Manter textos em String Catalog (`Localizable.xcstrings`).
- Datas, tamanhos e plurais devem respeitar a locale ativa.

## 16. Acessibilidade e foco

- Todo botão apenas com ícone precisa de label de acessibilidade e help.
- Disclosure arrows devem anunciar expandir ou recolher.
- Controles da toolbar não devem capturar permanentemente o foco do conteúdo.
- Após trocar visualização ou executar uma ação de toolbar, devolver foco ao navegador de arquivos.
- Durante navegação rápida, coalescer restauração de foco, rolagens e carregamentos de preview; antes de publicar um preview pendente, confirmar que o item ainda é a seleção primária.
- Usar cores semânticas do sistema para temas claro, escuro, contraste aumentado e cor de destaque.
- Não depender apenas de cor para indicar direção de ordenação, expansão ou tipo de controle.
- Hitboxes devem ser maiores que o desenho visual sempre que necessário.

## 17. Feedback de ações

- Ações concluídas podem usar um aviso temporário no topo do conteúdo.
- O feedback deve ser curto, animado e desaparecer automaticamente.
- Menus de contexto e toolbar devem chamar o mesmo modelo de ações.
- Uma ação desabilitada deve permanecer visível quando isso ajuda o usuário a entender sua disponibilidade.
- Os comandos de archive executam operações reais e preservam a mesma hierarquia visual nos menus e na toolbar.
- Em Settings, Compactação apresenta o perfil padrão e um editor de perfis com criação, atualização e exclusão. `Compress Custom…` permite escolher um perfil e ajustar opções somente para a operação atual; criação e salvamento de perfis ficam exclusivamente em Settings. A folha de compactação usa Save As, Tags e Where em linhas separadas com controles largos; o seletor de perfil se estende até a borda direita da grade. Where abre um seletor nativo de pasta. A altura acompanha o conteúdo visível, sem campo de nome de perfil nem ações de salvar perfil. A [alternativa A](../Design/CompressionModal/ALTERNATIVES.md) define uma grade compacta de duas colunas, com `Protect with password` à esquerda logo abaixo de `Solid archive`; ao marcar a proteção, os campos seguros de senha e confirmação aparecem abaixo do check na coluna esquerda, e o painel cresce para mantê-los inteiramente visíveis. Ao desmarcar, o painel encolhe; `Encrypt file names` permanece na coluna direita. Exibir apenas controles aceitos pelo formato e método selecionados: nível, método, dicionário, bytes rápidos, sólido, threads, senha, nomes criptografados em 7z e tipo de criptografia ZIP. Senhas são confirmadas em campo seguro e permanecem somente em memória nesta sessão; um perfil que exige senha solicita-a novamente quando não houver valor em memória. A compactação rápida usa o perfil padrão, inclusive nas quatro visualizações e em Recentes.
- Após avaliar a grade, o usuário decidiu manter Save As, Tags e Where em linhas próprias e ampliar os três controles. A folha própria substitui o topo estreito do `NSSavePanel`; [os estudos anteriores](../Design/CompressionModal/ALTERNATIVES.md#refinamento-em-avaliação) permanecem como histórico de exploração. O destino continua sendo escolhido pelo seletor nativo do macOS.
- Na folha implementada, cabeçalho, área superior, grade de opções e rodapé compartilham a mesma margem lateral de 20 pt. `Tags` e `Where` têm a mesma largura; `Save As` acompanha essa largura e os limites direitos desses controles, do seletor de perfil, da coluna direita e de Save ficam alinhados. Os seletores de opções têm rótulos acima e controles de largura uniforme por coluna. A [consulta às fontes Apple](../Design/CompressionModal/ALTERNATIVES.md#direção-após-consulta-às-diretrizes-apple) confirmou que rótulos superiores são compatíveis com os princípios de alinhamento, associação e adaptação, embora o `Form` macOS padrão apresente rótulos laterais. Preservar controles nativos, ordem de foco, VoiceOver, localização, espaçamento e expansão vertical da senha. A folha própria mantém a escolha de pasta pelo `NSOpenPanel` e grava tags no archive criado; conferir esses fluxos em archive real, além da revisão visual nos idiomas suportados.

## 18. Organização vigente

`FileBrowserState` coordena navegação, seleção, operações e preview por janela; `FileSystemService` e os demais serviços isolam o acesso a arquivos e archives. `ContentView` compõe janela e toolbar. Sidebar, preview e cada um dos quatro modos possuem views próprias, enquanto componentes e métricas compartilhados residem em arquivos comuns. Todas as visualizações projetam o mesmo estado por janela; não duplicar seleção ou navegação ao evoluir uma delas. A fonte para pontos de código e limites de evidência é [`CURRENT-STATE.md`](CURRENT-STATE.md).

## 19. Checklist de regressão

Antes de considerar uma mudança visual concluída, verificar:

### Janela e toolbar

- redimensionar lentamente da largura máxima até a mínima e voltar;
- confirmar a ordem dos dois breakpoints da toolbar;
- confirmar que nenhum controle volta com espaçamento corrompido;
- abrir todos os menus na apresentação completa e compacta;
- verificar títulos de diretório muito longos;
- testar sidebar aberta, oculta automaticamente e oculta manualmente.

### Conteúdo

- testar diretório vazio, poucos itens e muitos itens;
- testar nomes longos e extensões variadas;
- testar clique simples, duplo, secundário e área vazia;
- testar seleção simples, `Command`, `Shift` e seleção por teclado;
- trocar entre as quatro visualizações com seleção ativa;
- navegar profundamente e voltar para níveis anteriores.

### Aparência e acessibilidade

- tema claro e escuro;
- cor de destaque diferente de azul;
- português e inglês;
- zoom de 70%, 100% e 160%;
- foco de teclado depois de interagir com a toolbar;
- labels de acessibilidade e tooltips dos controles por ícone.

## 20. Critério para novas decisões

Ao surgir uma dúvida de UI/UX:

1. observar o comportamento atual do Finder e de aplicativos nativos equivalentes;
2. identificar se o comportamento vem do SwiftUI, da `NSToolbar`, do AppKit ou do nosso layout;
3. preferir API semântica do sistema quando ela produz o comportamento desejado;
4. não depender de comportamento automático que já tenha se mostrado instável durante resize ou overflow;
5. quando necessário, criar adaptação explícita e determinística;
6. manter a ponte AppKit pequena, isolada e substituível;
7. testar a sequência completa de estados, não apenas a aparência estática final;
8. registrar neste documento a decisão e o motivo.

### Edição de tags — 2026-10-03

O menu de contexto e o ícone entre Share e reticências abrem a mesma folha de edição localizada. Mostrar estado integral/parcial das tags na seleção múltipla, catálogo existente e criação por nome/cor, com Cancelar e Aplicar. Preservar tags não editadas de cada item. A pilha de círculos avança da direita para a esquerda e a primeira tag colorida à esquerda (última colorida nos metadados) define a cor da pasta nos quatro modos, previews e drop; packages e arquivos mantêm seus ícones. Conferir a nova largura do grupo nas transições de toolbar antes de declarar a validação visual completa.

#### Refinamento dos menus e material da pasta — 2026-10-03

A seção de tags em contexto e reticências/overflow tem duas linhas: sete primeiros nomes do catálogo em círculos (sem mostrar os demais), seguidos por Edit Tags com símbolo `tag`. Check indica aplicação em todos os alvos; hover mostra x nos aplicados e + nos não aplicados. Seleção parcial usa traço e hover +, aplicando a todos ao clicar. O clique rápido grava imediatamente; Edit Tags continua abrindo a folha. A linha customizada AppKit mantém tooltips, estado e nomes para acessibilidade; o editor completo continua disponível como item convencional de teclado.

Os círculos de tags na Lista preservam a ordem dos metadados invertida visualmente, com o círculo à esquerda cobrindo parte do vizinho à direita. A pasta adota a primeira cor dessa pilha, ignorando tags sem cor. A recoloração deve substituir apenas a matiz do material azul, preservar luminosidade, sombras, papel branco e detalhes neutros, e renderizar as representações nativas em resolução de preview antes da alteração de pixels. Não aplicar uma camada uniforme sobre a pasta composta. Os ícones de sistema continuam sendo obtidos por APIs públicas, sem recursos privados do Finder.

### Recepção da saída de archive — refinamento de 2026-10-04

Soltar na pasta real deve publicar o arquivo nessa pasta com seu nome, não apenas aceitar o gesto ou selecionar o item. Receptores nativos em pastas/área livre/sidebar recebem a identidade virtual diretamente e fornecem a URL do destino à extração. Não aguardar a conversão da promessa em URL antes de escolher esse destino. Hit testing nativo limita-se ao gesto ativo, preservando cliques após o drop enquanto a exportação termina. A sessão por evento começa durante mouseDragged no host comum aos frames de todos os itens, no macOS 26/27. A fonte e sua representação são compartilhadas com itens locais. Entrega por gesto real em pastas do Zforge nos quatro modos está executada; cobertura externa/visual detalhada na matriz de regressão.

### ZF-30 — contrato de interação implementado em 2026-10-04

O [plano vigente](ARCHIVE-DRAG-DROP-PLAN.md) amplia a ZF-30 para reorganização dentro do próprio archive. O usuário confirmou o badge na saída, mas reportou operações sem efeito e divergência visual. As regras abaixo foram implementadas com testes do motor/estado e gestos reais de UI; os limites de conferência visual e externa permanecem explícitos em REGRESSION-COVERAGE.

- Toda a apresentação do drag replica o item local equivalente no modo atual: linha na Lista, representação/formação do modo nos outros três, dimensões, ponto de captura, início/conclusão/cancelamento, feedback do alvo e seleção múltipla. Eliminar o ícone grande substituindo a linha e o salto desde o topo.
- Item interno para fora: sem Option copia/extrai com badge; Option move/extrai e remove a origem, sem badge. Item interno para a raiz ou pasta do próprio archive: sem Option move; Option copia com badge. Destino e modificador atualizam o indicador durante o gesto e são capturados ao soltar.
- Antes de movimentos que modificam o archive, aviso nativo identifica o original, itens e destino e informa que o arquivo compactado original será modificado. Return/Enter aprova, Escape cancela, Tab/Shift+Tab e Space permitem operar os controles sem mouse. Isso cobre Option + saída e movimento interno sem Option. Cancelamento anterior à execução não grava em nenhum destino. Cópia interna mantém a confirmação de alteração usada ao adicionar conteúdo.
- Cópia/movimento internos regravam o próprio archive de forma validada, tratam conflitos, impedem ciclos e conservam origem em cópias. Após sucesso, manter hierarquia sobrevivente, revelar o destino interno e preservar outras árvores. Transferência entre archives diferentes permanece fora dessa decisão.

### Navegação após mutação de archive — D-34, 2026-10-04

Adição, exclusão, saída por movimento e reorganização interna compartilham o restauro da navegação. Os breadcrumbs, Voltar/Avançar e Colunas devem apontar para a mesma sessão renovada: preservar a ordem do histórico e seus diretórios sobreviventes, descartando apenas caminhos removidos ou sessões aninhadas invalidadas. Revelar outro diretório é navegação e permite voltar ao local exibido antes da operação. Se o diretório exibido desaparecer, recuar ao ancestral sobrevivente mais próximo, sem criar uma parada duplicada. Recarregar os itens de cada ancestral das colunas, inclusive a pasta real que contém o archive, e selecionar a entrada que abre o nível seguinte. Preservar o restauro de disclosures/seleção do resultado na Lista e o estado dos demais archives.
