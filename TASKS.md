# Zforge — rastreamento de atividades

Atualizado em **2026-09-23**. Esta lista preserva os pedidos levantados nesta conversa. `CURRENT-STATE.md` descreve o comportamento existente; `DIVERGENCES.md` guarda lacunas e conflitos. D-01 a D-06 receberam implementação e build macOS sem assinatura. O ícone foi observado no Finder e o arraste de colunas foi exercitado no app; as demais validações pendentes continuam identificadas abaixo.

| ID | Atividade | Estado | Divergência |
| --- | --- | --- | --- |
| ZF-01 | Criar orientação para agentes, fonte de verdade e registro de divergências/tasks | Concluída nesta revisão documental | D-07 a D-12 |
| ZF-02 | Criar e aplicar novo ícone da aplicação | Implementada; ícone visto no Finder, validar Dock após executar pelo Xcode | D-01 |
| ZF-03 | Restaurar redimensionamento das colunas por arraste | Implementada e exercitada em Lista/Colunas | D-02 |
| ZF-04 | Implementar zoom por atalhos `⌘+` e `⌘−` | Implementada; validar teclado no app | D-03 |
| ZF-05 | Corrigir itens repetidos em Recentes | Correção provisória; investigar identidade real | D-04 |
| ZF-06 | Alinhar menu secundário e botão `•••` à matriz contextual de ações | Implementada; validar operações e breakpoints | D-05, D-06, D-12 |
| ZF-07 | Permitir arrastar o divisor do preview com 300 pt iniciais | Implementada e exercitada nos quatro modos | D-08 |

## ZF-01 — Documentação de referência e prevenção de regressões

**Pedido:** usar `AGENTS.md` para guiar o desenvolvimento, apontar para uma fonte de verdade versionada que descreva cada funcionalidade implementada, criar lista de tasks e registrar separadamente inconsistências com pedidos anteriores.

**Entregue nesta etapa:** `AGENTS.md` aponta para `CURRENT-STATE.md`, `DIVERGENCES.md` e este arquivo; o estado funcional foi mapeado a partir do código, do guia e de conversas anteriores. O levantamento é estático, sem nova execução do app. **Manutenção contínua:** toda alteração funcional precisa revisar o contrato e as divergências relevantes na mesma mudança.

## ZF-02 — Ícone do Zforge

**Pedido:** criar um novo ícone e usá-lo na aplicação, pois o atual não aparece.

**Implementado:** ícone novo com variantes PNG de 16 a 1024 px referenciadas pelo asset catalog; `Info.plist` declara explicitamente o nome do ícone e `AppDelegate` o atribui à aplicação na inicialização. O Finder mostrou o ícone no bundle anterior do DerivedData do Xcode e na nova build isolada. Falta confirmar sua aparência no Dock após uma nova execução pelo Xcode.

## ZF-03 — Larguras ajustáveis por mouse

**Pedido:** arrastar as divisórias para alterar larguras. O usuário relatou que a capacidade existia e regrediu.

**Implementado:** arraste das divisórias em Lista e Colunas por alças nativas de 20 pt com cursor de redimensionamento, larguras globais persistidas, limites e escala definidos em `CURRENT-STATE.md`. A área terminal do preview em Colunas é ajustável pela ZF-07. A build anterior foi exercitada manualmente nos dois modos e as divisórias se moveram.

## ZF-04 — Zoom nas views

**Pedido:** `⌘+` aumenta e `⌘−` diminui a escala, como no Finder.

**Implementado:** `⌘+` e `⌘=` aumentam; `⌘−` diminui; `⌘0` restaura 100%. Escala global em passos de 10%, de 70 a 160%, nas quatro views. Toolbar permanece sem controle de zoom. Falta conferir o mapeamento físico do teclado e o foco em execução.

## ZF-05 — Recentes sem duplicatas

**Pedido:** a aba Recentes não deve repetir o mesmo item. Captura de 2026-09-22 mostra `Archive.7z` repetido.

**Correção provisória:** além do caminho, a Lista de Recentes deduplica ID e assinatura de nome normalizado, tamanho e instante de modificação. Ainda é necessário observar URLs/identidades do caso original; cópias distintas com assinatura idêntica podem ser ocultadas. Revisar a regra com dados reais, preservando ordenação, ocultos e limite de resultados.

## ZF-06 — Matriz contextual nos dois menus

**Pedido:** clique secundário e botão `•••` da toolbar devem apresentar as mesmas ações aplicáveis à seleção, preservando ações já existentes e os estados habilitados.

| Seleção | Novas opções solicitadas |
| --- | --- |
| Um arquivo comum | Abrir; Comprimir; Comprimir customizado |
| Um archive | Abrir; Extrair aqui; Extrair para pasta com nome do archive; Extrair; Validar |
| Vários archives | Opções de archive **e** de arquivo; “Extrair para” lista nomes das pastas de saída, separados por vírgula |
| Vários itens com ao menos um arquivo comum | Mesmas opções indicadas para um arquivo comum |

**Implementado:** matriz e handler compartilhados nos dois menus; três destinos de extração, validação com `7zz t`, compressão customizada com painel de formato/nome/destino. Abrir vários archives cria janelas, validar/extrair vários processa em sequência. Itens de Recentes recebem as opções conforme o tipo, mas a ação principal da toolbar ali continua desabilitada (D-12). Falta conferir operações reais, conflitos, nomes longos e breakpoints em execução.

## ZF-07 — Largura ajustável do preview

**Pedido:** manter 300 pt como largura inicial, permitindo arrastar o divisor para redimensionar o preview.

**Implementado:** uma preferência global compartilhada pelos quatro modos guarda a largura entre 180 e 800 pt; cada divisor do preview tem alça nativa de 20 pt e cursor de redimensionamento. Em Colunas, a próxima coluna que ocupa a área terminal usa a mesma largura e o mesmo ajuste. A nova build compilou e o gesto foi exercitado em Lista, Ícones, Galeria e Colunas. O alinhamento da área terminal em janelas largas permanece registrado em D-13.

## Candidatas surgidas do levantamento, ainda sem escopo aprovado

- **Reconciliar notas de protótipo e persistência no `UI-UX-GUIDE.md`:** os conflitos de preview e seta esquerda já foram reconciliados; restam referências antigas de arquitetura (D-10).
- **Conferir o idioma dos tamanhos exibidos:** o limite de archive usa GB decimal conforme a apresentação de arquivos da Apple; resta verificar se `ByteCountFormatter` respeita o idioma escolhido no Zforge quando difere do idioma do macOS (D-11).
- **Alinhar a área terminal de Colunas à borda direita em janelas largas:** preservar ajustes independentes de coluna e preview (D-13).
- **Conferir a correção local de abertura pelo Finder antes de integrá-la ao histórico principal:** as alterações preexistentes em `AppDelegate.swift`, `ZforgeApp.swift` e `project.pbxproj` pertencem à tarefa C-06 e não foram modificadas por este levantamento.

Uma candidata vira task numerada após confirmar o escopo. O registro de divergências permanece separado para que observação, decisão e trabalho não se confundam.
