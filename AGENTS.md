# Zforge — Diretrizes do projeto

## Visão do produto

Zforge é um gerenciador de arquivos compactados baseado no 7-Zip para macOS. O objetivo é alcançar a abrangência funcional do 7-Zip File Manager do Windows, oferecendo essa capacidade em uma aplicação nativa, moderna e integrada ao macOS.

O produto deve ser tratado como uma aplicação completa de gerenciamento de arquivos e arquivos compactados, e não apenas como uma interface mínima para compactar e extrair conteúdo.

## Plataforma e experiência nativa

- A aplicação é destinada ao macOS e deve priorizar tecnologias, padrões de interação e componentes nativos da plataforma.
- Utilizar as técnicas e APIs modernas e atuais do macOS sempre que forem compatíveis com os requisitos do projeto.
- Aplicar os recursos visuais e de interação do Liquid Glass de forma adequada ao contexto, preservando legibilidade, hierarquia, acessibilidade e usabilidade. O efeito não deve ser usado apenas como decoração.
- A experiência deve parecer pertencente ao macOS: menus, comandos, atalhos de teclado, barras de ferramentas, navegação, seleção, drag and drop, janelas, diálogos e feedback de operações devem seguir as convenções da plataforma.
- Ao tomar decisões de UI/UX, considerar tanto usuários casuais quanto usuários avançados que esperam eficiência semelhante à do 7-Zip File Manager.

## Referência obrigatória de UI/UX

O arquivo `UI-UX-GUIDE.md`, localizado na raiz deste workspace, é a referência principal para a criação e evolução da UI/UX. Ele deve ser consultado antes de implementar ou alterar interfaces, fluxos, componentes visuais ou padrões de interação.

## Projetos e materiais de referência

Há três recursos irmãos deste projeto que podem e devem ser consultados quando agregarem contexto:

- `../UIDemo`: projeto de testes criado anteriormente pelo usuário. Usá-lo como referência adicional para compreender suas preferências e seu raciocínio sobre a UI da aplicação. Ele complementa, mas não substitui, o `UI-UX-GUIDE.md`.
- `../7z2602-mac`: build mais recente disponibilizada do 7-Zip para macOS. Usá-la para entender os binários, ferramentas, comportamento e possibilidades de integração disponíveis na distribuição para macOS.
- `../7zip`: clone do repositório oficial do 7-Zip. Usá-lo como fonte técnica para compreender formatos, recursos, comportamento, interfaces e implementação do 7-Zip.

Não modificar os projetos e diretórios de referência sem uma solicitação explícita. Por padrão, eles devem ser tratados como fontes de consulta.

## Direção funcional

- Buscar paridade ampla com os recursos relevantes do 7-Zip File Manager do Windows, adaptando-os às convenções e expectativas do macOS em vez de reproduzir literalmente sua interface.
- Manter a arquitetura preparada para a evolução do produto como um gerenciador de arquivos completo.
- Basear a integração de compactação e extração no 7-Zip e nas fontes disponibilizadas no workspace.
- Ao existir conflito entre uma reprodução fiel do aplicativo do Windows e uma experiência genuinamente nativa no macOS, preservar a capacidade funcional e projetar a interação de acordo com o macOS.

## Estratégia de integração com o 7-Zip

A estratégia inicial recomendada é a GUI orquestrar o executável `7zz` oficial, empacotado com a aplicação, para listar, compactar, extrair, testar e modificar arquivos. Essa abordagem deve acelerar a primeira versão funcional e manter o motor de compactação isolado da interface.

Essa escolha não deve acoplar o domínio ou a UI diretamente à sintaxe e às saídas textuais da CLI:

- Definir uma abstração própria de motor de arquivos, com modelos tipados para itens, propriedades, progresso, avisos, erros e resultados.
- Implementar o CLI como o primeiro backend dessa abstração, permitindo substituí-lo ou complementá-lo sem reescrever a UI.
- Manter aberta a evolução para um helper nativo em C++ baseado nas interfaces `IInArchive` e `IOutArchive` do 7-Zip quando forem necessários callbacks estruturados, maior fidelidade de nomes e propriedades, senhas sem protocolo interativo textual ou controle de progresso mais preciso.
- Executar o `7zz` diretamente como processo, nunca por meio de shell, e construir os argumentos como uma lista tipada para evitar ambiguidades e injeção de comandos.
- Separar stdout, stderr e progresso; solicitar UTF-8 explicitamente; interpretar códigos de saída; impedir perguntas interativas não controladas; oferecer cancelamento real das operações.
- Não incluir senhas nos argumentos do processo. Quando o backend CLI for usado, fornecê-las pelo stdin controlado ou por outro canal seguro.
- Fixar e testar uma versão conhecida do `7zz`. O executável distribuído deve ser universal, incorporado ao bundle, assinado junto com a aplicação e compatível com App Sandbox e Hardened Runtime.
- Tratar as saídas da CLI como um protocolo versionado: manter parsers isolados, fixtures reais e testes para arquivos grandes, criptografados, multivolume, nomes incomuns, avisos e falhas parciais.
- Acesso a arquivos fora do container deve seguir o modelo nativo de seleção do usuário e URLs ou bookmarks com escopo de segurança. O helper deve receber apenas o acesso necessário à operação.

A CLI é, portanto, o backend inicial e um limite de processo útil, mas não deve ser considerada obrigatoriamente o backend definitivo para todas as funcionalidades do produto.

### Fases de adoção do motor

- Na fase inicial de desenvolvimento, é aceitável usar a build pronta do `7zz` para validar funcionalidades, fluxos e a abstração `ArchiveEngine`.
- A build baixada não deve ser distribuída de forma bruta nem executada a partir de uma instalação externa. Ao ser incorporada ao aplicativo, deve perder o status de artefato baixado em quarentena, receber identidade própria de helper, herdar o sandbox, ser assinada junto com o Zforge e participar da verificação e notarização do produto final.
- Para distribuição fora da Mac App Store, assinar todo o código aninhado com Developer ID, do componente mais interno para o aplicativo, ativar Hardened Runtime, notarizar o artefato final e anexar o ticket de notarização.
- Não presumir que um `7zz` iniciado como processo filho recebe automaticamente os acessos dinâmicos concedidos ao aplicativo por painéis de abertura, PowerBox ou security-scoped URLs. Durante a fase CLI com App Sandbox, processar dentro do container e transferir os arquivos pela camada Swift que detém o acesso, ou validar explicitamente outra solução compatível com o canal de distribuição. Esse staging é aceitável para protótipos, mas não é a arquitetura final desejada para arquivos grandes.
- A evolução planejada é integrar e compilar o código-fonte oficial do 7-Zip disponibilizado em `../7zip`, preferencialmente por meio de um helper isolado com protocolo estruturado. O helper final deve ser capaz de receber e resolver bookmarks, operar diretamente sobre os arquivos autorizados e usar as interfaces do 7-Zip sem depender do protocolo textual da CLI.
- A transição da build pronta para o motor compilado a partir do código-fonte não deve alterar os modelos de domínio nem a UI; apenas a implementação do backend de `ArchiveEngine`.

## Licenciamento e distribuição comercial

Zforge é planejado como um projeto open source. O uso do 7-Zip não deve ocultar ou restringir os direitos concedidos pelas licenças dos componentes incorporados.

- Preservar uma separação clara entre o código original do Zforge e o motor derivado do 7-Zip. Preferir um executável ou helper independente a incorporar o código LGPL diretamente no executável principal, mantendo explícita a licença aplicável a cada componente.
- Incluir no produto uma seção de licenças de terceiros com o `License.txt` integral da versão distribuída, o texto da GNU LGPL aplicável, avisos BSD, atribuição ao 7-Zip e link para `https://www.7-zip.org/`.
- Disponibilizar de forma duradoura o código-fonte correspondente à versão exata do motor distribuído, incluindo patches, scripts de build e alterações feitas pelo projeto. Não depender apenas de o repositório original continuar disponível.
- Qualquer modificação no código LGPL do 7-Zip e qualquer wrapper derivado desse código deve continuar sob LGPL ou GPL e ter seu código-fonte correspondente publicado. O restante independente do Zforge deve usar a licença open source escolhida para o projeto.
- Se houver linkagem estática entre o 7-Zip e código sob outra licença, cumprir os requisitos de relinkagem da LGPL, inclusive disponibilizando os materiais necessários para o usuário produzir um executável com uma versão modificada da biblioteca. Por simplicidade e menor risco, evitar esse desenho sem revisão jurídica específica.
- Preservar os avisos e a restrição unRAR: o código relacionado pode ser usado para manipular e descompactar RAR, mas não para recriar o algoritmo proprietário de compressão RAR. Não apresentar o Zforge como capaz de criar arquivos RAR por meio desse código.
- Antes de uma distribuição comercial, especialmente pela Mac App Store, realizar uma revisão jurídica específica sobre LGPL, termos da loja, assinatura de código e possibilidade prática de modificação ou substituição do componente LGPL.

### Modelo de distribuição

- Disponibilizar o código-fonte e uma distribuição gratuita completa no site oficial do projeto.
- Oferecer a mesma aplicação como distribuição paga na Mac App Store para usuários que desejem apoiar financeiramente o desenvolvimento e receber a conveniência do canal da Apple.
- Manter paridade funcional entre as distribuições. O pagamento na Mac App Store não deve desbloquear funcionalidades exclusivas nem transformar recursos do projeto aberto em paywall.
- Manter um único código-fonte, com diferenças de build apenas quando exigidas pelos canais de distribuição.
- A distribuição do site deve ser assinada com Developer ID, usar Hardened Runtime, ser notarizada e ter o ticket anexado, para funcionar normalmente com Gatekeeper.
- A distribuição da Mac App Store deve usar Apple Distribution, permanecer em App Sandbox e receber atualizações exclusivamente pela Mac App Store. Não incluir atualizador externo nessa variante.
- Licenciar o código original do Zforge sob a licença MIT. Componentes, fontes e modificações derivados do 7-Zip permanecem sob LGPL ou suas demais licenças aplicáveis e devem ser identificados separadamente; a licença MIT do Zforge não substitui nem relicencia esses componentes.
- Comunicar de forma transparente que a compra na Mac App Store apoia o desenvolvimento e oferece conveniência de instalação e atualização, enquanto a versão oficial gratuita permanece completa.

## Marco funcional: navegador somente leitura

O primeiro marco funcional do Zforge é um gerenciador de arquivos nativo somente leitura. Até que uma fase posterior autorize explicitamente operações de escrita, a aplicação deve permitir navegação, seleção, inspeção, compartilhamento, Quick Look e abertura, mas não copiar, mover, excluir, renomear, duplicar, criar pastas nem editar arquivos compactados.

- Cada nova janela comum começa na Home. Preferências visuais podem persistir globalmente, mas o último caminho visitado não deve ser restaurado.
- Janelas abertas a partir de um arquivo enviado pelo Finder são dedicadas a esse arquivo compactado.
- A interface oferece Ícones, Lista, Colunas e Galeria, com sidebar para favoritos, discos, volumes removíveis e compartilhamentos montados.
- O acesso persistente a locais externos ao container usa security-scoped bookmarks. A primeira navegação pela Home deve solicitar autorização e o cancelamento deve manter uma explicação com uma ação clara para tentar novamente.
- A sidebar observa mount, unmount e rename. A conexão de servidor cobre `smb`, `afp` e `nfs` por meio do fluxo do macOS; descoberta Bonjour não faz parte deste marco.
- Packages são tratados como arquivos. Aliases e symlinks são resolvidos ao abrir e ciclos devem ser impedidos.
- Arquivos ocultos permanecem ocultos por padrão e podem ser alternados com `Command + Shift + .`.
- A experiência permanece independente por janela e o monitoramento do diretório atual deve preservar seleções ainda válidas após atualizações.

### Navegação transparente em arquivos compactados

- Formatos reconhecidos aparecem como containers navegáveis no mesmo breadcrumb do sistema de arquivos. Arquivos compactados aninhados podem ser abertos recursivamente, materializando apenas o item interno necessário, dentro de dois limites globais configuráveis: profundidade máxima de 1 a 10 sub-archives, com padrão 5, e tamanho máximo do archive raiz entre 1 e 5 GB, com padrão 1 GB. O archive raiz não conta na profundidade; o limite representa quantos archives podem ser abertos dentro dele. A navegação aninhada só é habilitada quando a soma dos volumes do archive mais externo for estritamente menor que o limite configurado. Ao atingir qualquer limite — ou quando o tamanho raiz não puder ser determinado com segurança — archives internos permanecem visíveis como arquivos comuns, sem disclosure, chevron ou abertura de nova coluna. Os valores são capturados ao criar a sessão, herdados por todos os seus endereços virtuais e valem igualmente para Lista e Colunas.
- O backend inicial é o `7zz` universal 26.02 incorporado em `Contents/MacOS`. O arquivo raiz e volumes relacionados são copiados para uma sessão temporária antes de executar a CLI, porque o helper não deve depender de acesso dinâmico do sandbox do processo principal.
- Sessões residem em `temporaryDirectory/Zforge/ArchiveSessions/<UUID>`. Previews, arquivos aninhados e itens abertos externamente são limpos ao fechar a janela ou sessão; diretórios órfãos com mais de 24 horas são removidos na inicialização seguinte.
- Preview automático de itens internos tem limite de 10 MB. Acima disso, exibir metadados e uma ação explícita para carregar o preview. Esse limite não se aplica ao Quick Look de arquivos locais.
- Materializações com tamanho desconhecido têm teto de segurança de 1 GB. Para itens declarados, interromper a escrita se ela ultrapassar o tamanho informado mais uma margem de 1 MB. Confirmar operações declaradas acima de 1 GB e fornecer progresso e cancelamento.
- Senhas permanecem somente em memória durante a sessão. Nunca incluí-las em argumentos, logs ou persistência; o backend CLI deve fornecê-las por stdin.
- Itens internos comuns abertos por duplo clique são cópias temporárias somente leitura, preservam nome e extensão, recebem a quarentena do archive raiz quando existente e abrem no aplicativo padrão. Alterações externas não retornam ao arquivo compactado.
- O processo `7zz` é iniciado diretamente, sem shell, com stdout e stderr separados. Cancelamento começa com interrupt e usa terminate como fallback.
- A UI e o domínio não podem depender do texto do `7zz`; parser, construção de comandos, cache e processo devem continuar isolados atrás de `ArchiveEngine` para permitir a futura troca por um helper C++ estruturado.

### UI e plataforma deste marco

- `UI-UX-GUIDE.md` continua sendo a autoridade visual. `NavigationSplitView`, materiais e controles nativos devem fornecer Liquid Glass automaticamente; efeito explícito fica restrito a overlays transitórios de progresso ou feedback, nunca a células de arquivo.
- O background automático da `windowToolbar` permanece oculto para evitar que o scroll edge mude a tonalidade da toolbar ao trocar entre Ícones, Lista, Colunas e Galeria ou ao redimensionar a janela; a toolbar deve continuar integrada à mesma superfície cromática do conteúdo.
- As quatro visualizações do conteúdo principal devem manter paridade visual e estrutural com o projeto `../UIDemo`: Ícones usa grade adaptativa ocupando toda a superfície; Lista usa tabela hierárquica de largura total; Colunas usa níveis Finder-like com preview como coluna final; Galeria usa hero central, inspector lateral e miniaturas inferiores. O inspector não deve comprimir permanentemente Ícones ou Lista, e o breadcrumb permanece na barra inferior da área de conteúdo.
- Superfícies de conteúdo focadas não devem exibir bordas ou anéis azuis; o foco de teclado continua funcional de forma invisível. Quando o breadcrumb inferior exceder a largura disponível, ele deve rolar automaticamente para manter o componente final do caminho visível, inclusive após redimensionamento, preservando uma margem final de 12 pt em relação à borda da área de conteúdo.
- Na visualização em Lista, toda a área de cada célula do header de coluna deve aceitar o clique de ordenação, não apenas o texto ou o indicador de direção.
- Na visualização em Lista, o header deve exibir uma borda inferior visível separando-o dos arquivos e divisores verticais entre as células. Todos os títulos usam inset interno de 6 pt em relação aos divisores. Em Data de Modificação, Tamanho e Tipo, os valores usam o mesmo inset e permanecem alinhados aos respectivos títulos; o conteúdo das linhas da primeira coluna mantém seu alinhamento original. Os divisores não alteram as larguras das colunas nem reduzem a área clicável de ordenação.
- Na visualização em Lista, cabeçalho e linhas compartilham uma única superfície horizontal. A coluna Nome mantém largura mínima de 168 pt e a tabela mantém largura mínima de 612 pt em escala de 100%; quando a área disponível for menor, as colunas não se comprimem e a Lista passa a rolar horizontalmente. Sem preview, o conteúdo excedente continua à direita da janela. Com preview, a largura útil da tabela desconta o painel translúcido de 300 pt fixo à direita: enquanto restarem menos de 612 pt, a tabela transborda por trás dele e a rolagem inclui folga equivalente ao painel; assim que todas as colunas couberem na área descoberta, nenhuma permanece encoberta e somente o espaço adicional posterior expande a coluna Nome além de 168 pt. Essas medidas acompanham a escala visual.
- Na visualização em Lista, enquanto houver overflow horizontal, os fundos alternados e de seleção das linhas são edge-to-edge, sem margem lateral nem cantos arredondados, preservando internamente o alinhamento do conteúdo com o header. Quando a tabela couber inteira na largura descoberta, retornam a margem lateral de 8 pt e o corner radius de 7 pt.
- Na visualização em Lista, seleção por intervalo com Shift, incluindo Shift + setas e Shift + clique, segue estritamente a ordem achatada das linhas visíveis; filhos de pastas expandidas participam do intervalo na posição exibida, sem saltos pela hierarquia de itens raiz.
- Na visualização em Lista, a seta direita expande a pasta focada quando ela está recolhida. A seta esquerda primeiro retrai a pasta focada quando ela está expandida; se o diretório já estiver retraído ou o item focado for um arquivo, move a seleção para seu diretório-pai visível. Itens no nível raiz não reagem à seta esquerda. Setas verticais permanecem dedicadas à navegação e seleção das linhas visíveis.
- Na visualização em Lista, somente archives ZIP e 7z não multivolume participam da hierarquia expansível das pastas, pois oferecem listagem estrutural rápida. Eles podem ser expandidos e retraídos inline recursivamente para revelar a árvore virtual sem sair da localização atual, preservando a ordem achatada das linhas visíveis e os mesmos comportamentos de seleção e teclado. A listagem é assíncrona, executada uma vez por archive e reutilizada pelas expansões das pastas internas. A recursão respeita os limites de profundidade e tamanho raiz capturados pela sessão; ao atingir qualquer um deles, archives internos aparecem como itens comuns sem disclosure inline. TAR e variantes, streams comprimidos, RAR, outros formatos e multivolume continuam abrindo apenas pela navegação normal.
- A toolbar principal não exibe controle de zoom; ajustes de escala permanecem fora da barra para preservar uma composição mais limpa.
- À direita do seletor de visualização, a toolbar principal mantém apenas três ações, nesta ordem: ação contextual de archive, Compartilhar e botão de reticências. As três ações compartilham sempre a mesma cápsula nativa, enquanto um espaçador fixo mantém o seletor de visualização em uma cápsula separada tanto na apresentação segmentada quanto na compacta. Abrir, Quick Look, Obter Informações, Adicionar Tag, Renomear e Duplicar ficam no menu nativo aberto pelo botão de reticências.
- A ação contextual usa ícone de extração dentro de archives, mesmo desabilitada. Fora de archives, extrai todos os archives selecionados quando a seleção contém apenas archives; comprime a seleção quando ao menos um item não é archive; sem seleção usa o ícone de compressão desabilitado. Dentro de archive, extrai os itens selecionados e fica desabilitada sem seleção.
- Enquanto compressão e extração não estiverem implementadas, a ação contextual deve apresentar feedback transitório descrevendo a operação que seria executada. Seus ícones e os de Compartilhar/reticências devem preservar linguagem visual coerente com SF Symbols e controles nativos do macOS.
- O seletor de visualização usa quatro segmentos em janelas com pelo menos 780 pt e, abaixo desse breakpoint, torna-se um botão compacto com o ícone do modo atual, chevrons verticais e menu com os quatro modos e checkmark. A identidade dos demais itens da toolbar deve permanecer estável durante essa transição para que somente o seletor seja reconstruído, sem piscar ou perder ícones. Galeria usa o símbolo `rectangle.bottomthird.inset.filled`.
- Na visualização em Colunas, cada clique é resolvido a partir da coluna onde ocorreu: selecionar um item em uma coluna anterior elimina imediatamente o ramo obsoleto à direita; pastas e archives abrem uma nova coluna a partir desse ponto, enquanto arquivos comuns deixam a coluna de origem como último nível e exibem seu preview. A coluna clicada permanece visualmente ativa e seu item selecionado continua azul mesmo após o carregamento da coluna seguinte; somente seleções preservadas em colunas inativas usam cinza. As setas esquerda e direita movem a coluna ativa para o nível anterior ou seguinte, atualizam a seleção visível na coluna de destino e centralizam horizontalmente essa coluna; à direita do último nível, a seta direita abre o item-container selecionado quando possível. Uma coluna vazia pode permanecer visível para representar o conteúdo de um diretório vazio, mas nunca recebe o cursor: nesse caso, a coluna ativa e a seleção permanecem no diretório da coluna anterior.
- Ao trocar de Ícones, Lista ou Galeria para Colunas, uma pasta ou archive navegável que já esteja selecionado deve abrir imediatamente seu conteúdo na coluna seguinte, exatamente como se tivesse sido ativado dentro da própria visão de Colunas. Essa reconciliação de apresentação não cria uma entrada adicional no histórico de navegação.
- Ao sair de Colunas para Ícones, Lista ou Galeria, se o item ativo tiver aberto uma coluna filha, a nova visualização retorna para a localização da coluna ativa e mantém esse item selecionado, em vez de permanecer dentro dele. Essa reconciliação também não cria uma entrada no histórico.
- O preview de arquivo deve ser invalidado sincronamente antes de uma seleção pendente de diretório, sem exibir o conteúdo anterior nem por um frame. Na visualização em Colunas, seleção, item primário e invalidação do preview são atualizados no mesmo ciclo do evento; somente a enumeração e abertura do novo ramo ficam assíncronas. Diretórios e archives navegáveis não são candidatos a preview. A coluna ativa termina sempre exatamente uma área terminal de 300 pt antes da borda direita, igual à largura do inspector da Galeria: quando o item selecionado é um arquivo, essa área mostra o preview; quando é um container, a próxima coluna ocupa a mesma área e largura, como substituta do preview. Colunas descendentes além da próxima ficam ocultas até se tornarem a próxima coluna pela navegação horizontal. Para um arquivo comum, o conteúdo do preview só é inserido nessa área quando estiver materializado ou houver um estado explícito de carregamento manual. Materializações assíncronas só podem publicar seu resultado se o mesmo arquivo continuar sendo a seleção primária.
- Archives e diretórios nunca devem iniciar Quick Look embutido nem exibir um indicador de preview carregando indefinidamente. Nas superfícies de preview que representam o próprio item, incluindo Galeria e inspectors, eles usam diretamente o ícone fornecido pelo `NSWorkspace` para a URL local ou o símbolo virtual equivalente.
- `Command + Shift + P` alterna o preview da janela em qualquer um dos quatro modos. Em Ícones e Lista, o preview aparece como painel lateral de 300 pt, igual ao inspector da Galeria, com o mesmo hero e metadados compartilhados; em Colunas, controla uma área terminal também de 300 pt e sua reserva de largura; em Galeria, controla o inspector lateral sem remover o hero central inerente ao modo. A visibilidade é persistida de forma independente para Ícones, Lista, Colunas e Galeria; ao trocar de modo ou reabrir a aplicação, restaurar o último estado usado naquele modo sem sobrescrever os demais. Quando oculto fora da Galeria, não materializar previews internos em segundo plano. Após a alternância, restaurar o foco da área principal.
- O foco de teclado de cada janela pertence por padrão a uma superfície persistente da área de conteúdo, situada acima das quatro visualizações para não ser destruída durante a troca de modo. Ele deve ser restaurado após inicialização, navegação, carregamento e interação com sidebar, toolbar ou diálogos. Controles da toolbar não capturam foco; as setas continuam operando a visualização ativa sem exigir clique prévio na área de arquivos.
- A largura da sidebar deve permanecer entre 180 e 300 pt, com ideal de 220 pt, e a janela deve respeitar os breakpoints de 678 e 780 pt definidos no guia.
- O produto oferece inglês e português do Brasil por String Catalog e mantém Settings para idioma, preferências visuais e segurança da navegação em archives. Os controles de profundidade e tamanho raiz devem exibir textos curtos explicando, respectivamente, que o archive raiz não entra na contagem e que volumes relacionados são somados para avaliar o limite de tamanho.
- O Zforge é registrado apenas como Viewer de formatos de archive comuns. Não assumir associação de DMG, documentos Office nem outros formatos especializados baseados em ZIP.
- O helper incorporado deve ser universal, receber identidade própria, `app-sandbox` + `inherit`, Hardened Runtime e assinatura aninhada. A licença integral do 7-Zip deve acompanhar os recursos do aplicativo.

## Manutenção deste arquivo

Sempre que o usuário fornecer um direcionamento relevante para o rumo futuro do desenvolvimento, atualizar este `AGENTS.md` na mesma tarefa para registrar a nova orientação de maneira duradoura.

Ao atualizar o arquivo:

- incorporar a orientação na seção mais apropriada;
- evitar duplicações e instruções contraditórias;
- preservar decisões anteriores que continuem válidas;
- registrar princípios duradouros, decisões de produto, arquitetura, UI/UX e fluxo de trabalho;
- não registrar pedidos pontuais que não tenham impacto futuro no projeto.
