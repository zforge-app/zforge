# ZF-30 — plano de drag and drop de itens de archives

Atualizado em **2026-10-04** por instrução do usuário. **Implementação e testes de regressão executados.** Evidência e limites de validação registrados abaixo e na matriz de regressão.

O usuário aceitou esta versão como base razoável para commit. Os bugs que informar em seguida serão corrigidos com testes pertinentes e incorporados por amend ao commit funcional; isso não altera os limites de validação registrados abaixo.

## Histórico observado

O usuário confirmou a exclusão pelo menu e o indicador de cópia que desaparece ao pressionar Option. Relatou que as operações de arraste continuam sem ocorrer e que a representação usa um ícone grande, com animação desde o topo da tela, diferente do arraste de itens locais. As gravações enviadas e esse relato são referências para a próxima validação; os testes anteriores de motor/receptor não comprovam entrega por gesto real.

## Contrato implementado

As regras abaixo aplicam-se a itens já contidos em um archive. O contexto do destino determina o significado de Option; o indicador deve acompanhar mudanças de destino e modificador durante todo o gesto, e a operação deve capturar ambos ao soltar.

| Origem e destino | Sem Option | Com Option |
| --- | --- | --- |
| Item interno → pasta real, outra janela do Zforge, Finder ou Mesa | Copiar: extrair no destino e preservar a entrada no archive; indicador de cópia | Mover: extrair no destino e retirar a entrada do archive; sem indicador de cópia |
| Item interno → raiz ou pasta do próprio archive | Mover a entrada para o destino interno; sem indicador de cópia | Copiar a entrada para o destino interno, preservando a origem; indicador de cópia |

Ambas as operações dentro do próprio archive **modificam o arquivo compactado original**. Transferência entre archives diferentes permanece uma decisão separada; não é inferida desta regra. O fluxo existente de adicionar arquivos locais a um archive mantém seu contrato de confirmação e preservação das fontes.

### Aparência e interação

- Replicar integralmente o drag and drop existente fora de archives em cada modo: representação, dimensões, formação da seleção múltipla, posição relativa ao cursor, animações de início/cancelamento/conclusão, indicador e feedback dos destinos.
- Na Lista, arrastar a representação da linha como no item local equivalente; não substituir a linha por um ícone grande. Ícones, Colunas e Galeria usam o comportamento local do respectivo modo.
- A representação começa na posição do item e segue o ponto de captura do cursor, sem aparecer no topo da tela ou voar até ele.
- Preservar seleção, cliques, duplo clique, menus, teclado, disclosure, preview, zoom, rolagem e redimensionamento. Pastas alvo e sidebar mantêm seu feedback já existente.

### Confirmação e teclado

- Antes de executar um movimento que altera o archive, avisar explicitamente que **o arquivo compactado original será modificado**. Isso inclui Option + arraste para fora e arraste sem Option dentro do próprio archive.
- O aviso identifica o archive, a quantidade de itens e o destino; informa que as entradas serão removidas da origem após a transferência. Oferece confirmação e cancelamento nativos e localizados.
- Aprovar com Return/Enter e cancelar com Escape, sem depender do mouse. Tab/Shift+Tab e Space permitem navegar e acionar os botões pelos controles nativos.
- Capturar o pedido completo antes de apresentar o aviso: origens, destino e operação. Fechar o diálogo não pode descartar um pedido aprovado nem reinterpretar Option depois do drop.
- Cancelar o movimento não extrai, não altera o destino e não modifica o archive. A cópia para fora não modifica o archive. Para a cópia interna, preservar a confirmação de alteração já usada pela adição de conteúdos a archives.

### Resultado e integridade

- A extração grava exatamente na pasta onde o item foi solto, mantendo seu nome e sem recriar os ancestrais internos. Área vazia de pasta usa a pasta exibida; linha de pasta usa aquela pasta; Colunas usam a coluna de destino.
- Pastas incluem descendentes. Seleção múltipla normaliza pai/descendente e não duplica a mesma entrada.
- Resolver conflitos de nome segundo os controles existentes; itens mantidos por decisão do usuário conservam suas origens.
- Para mover para fora, concluir as exportações aprovadas antes de remover entradas. Falha/cancelamento não remove origens; relatar eventuais cópias já publicadas em falha parcial.
- Para copiar/mover dentro do mesmo archive, preparar a reorganização em uma cópia, validar e substituir o original somente após sucesso. Não gravar estados intermediários de adição seguida de remoção no original.
- Recusar mover uma pasta para si mesma ou para seus descendentes. Mover para a própria pasta de origem é uma operação sem alteração; copiar no mesmo diretório exige tratar o nome de destino sem apagar a origem silenciosamente.
- Preservar as proteções atuais de senha, autorização, cancelamento, caminhos e detecção de sessão obsoleta. A escrita atual é limitada a ZIP/7z raiz de volume único; não ampliar suporte a formatos/volumes/conteúdo aninhado por inferência deste plano.
- Após sucesso, atualizar somente o archive alterado. Migrar Voltar/Avançar para a nova sessão, preservando caminhos válidos e a ordem de navegação; repopular todas as colunas ancestrais e suas seleções. Revelar outro diretório registra navegação para que Voltar retorne à pasta anterior. Descartar destinos removidos e recuar ao ancestral sobrevivente se o atual desaparecer. Manter sua navegação e os diretórios sobreviventes expandidos, abrir ancestrais do destino interno e revelar/selecionar o resultado. Outras árvores conservam seu estado. Na cópia para fora, conservar a árvore original.
- A exclusão contextual/teclado já existente continua com confirmação e atualização da árvore.

## Etapas de execução

1. **Caracterizar o arraste local em cada modo e diagnosticar a entrega.** Comparar itens locais/internos lado a lado com arquivos de teste. Seguir origem, aceite do destino, pedido confirmado, extração e resultado gravado. Não considerar início do gesto ou badge como prova de operação.
2. **Compartilhar apresentação e resolução da operação.** Reutilizar o comportamento visual local; separar identidade virtual da aparência. Resolver cópia/movimento pelo contexto de destino e Option atual, capturando a decisão ao soltar.
3. **Implementar pedido e confirmação.** Cobrir aprovação/cancelamento só pelo teclado, retenção do pedido e ausência de escrita ao cancelar. Manter a confirmação de alteração ao copiar para dentro.
4. **Concluir saída e reorganização interna.** Corrigir gravação no destino real e remoção após sucesso; acrescentar cópia/movimento dentro do mesmo archive com substituição validada, conflitos e proteção contra ciclos.
5. **Renovar a visão e validar de ponta a ponta.** Conferir conteúdo no destino e no archive, estado expandido e paridade visual nos quatro modos. Atualizar contratos com evidência executada; conservar limites pendentes explicitamente.

## Critérios de aceite

- Cópia e movimento para fora comprovados por gesto real e conteúdo existente no destino, incluindo Finder/Mesa e outra janela do Zforge.
- Cópia e movimento internos comprovados pelo conteúdo reaberto do archive, com a inversão correta de Option e preservação da origem na cópia.
- Confirmação explica alteração do original; Return aprova e Escape cancela sem escrita, tanto na saída por movimento quanto na reorganização interna.
- Apresentação equivalente ao item local em Lista, Ícones, Colunas e Galeria, incluindo seleção múltipla, badge, mudança de Option/destino e início/cancelamento sem salto desde o topo.
- Pastas, conflitos, senha, falhas, cancelamento, sessão obsoleta e destinos inválidos conservam a integridade das origens.
- Refresh revela o resultado e preserva hierarquia, navegação, seleção coerente e outros archives abertos.

Rastreamento: [ZF-30](../../TASKS.md), [D-31](../../DIVERGENCES.md), [OR-14](OPEN-REQUIREMENTS.md) e [REGRESSION-COVERAGE](../../REGRESSION-COVERAGE.md).

## Execução do plano

- Origem nativa compartilhada entre locais e internos, com snapshot real da linha/célula, formação por modo e coordenadas no host da sessão. Identidade virtual imediata e file promises; destinos nativos roteiam para o alvo visível mais específico.
- Confirmação do original antes de qualquer escrita em movimentos e cópias internas; pedido completo retido. Atualização interna única validada, publicação externa na URL exata autorizada pelo AppKit após staging/validação próprios e remoção condicionada a sucesso de todas as promises.
- Refresh conserva navegação sobrevivente, revela destino/seleção e restaura expansão da Lista. Fontes locais mantêm NSURL original e semântica nativa de Option.
- `ArchiveMutationTests` congela política por contexto, ZIP/7z protegidos, bytes de origem/destino, pastas, conflitos, cancelamento, alteração concorrente, publicações sequenciais e refresh nos quatro modos. `ZforgeUITests` usa `click(forDuration:thenDragTo:)` para gesto macOS real; `press` não produzia mouseDragged nas tentativas anteriores.
- Evidência inicial aprovada: cópia externa nos quatro modos e reorganização interna em `/tmp/zforge-plan-ui-internal.xcresult`; movimento externo Return/Escape em `/tmp/zforge-plan-ui-final.xcresult`; integridade/refresh em `/tmp/zforge-plan-expanded2.xcresult`. Rodada final, Finder, fluxos locais e limites visuais em [REGRESSION-COVERAGE](../../REGRESSION-COVERAGE.md).

Validação final: 164 casos unitários/189 execuções e oito casos de UI aprovados, incluindo Finder e outra janela. A primeira rodada de UI teve uma falha na navegação para inspeção após confirmar; esse passo foi estabilizado e o caso repetido com aprovação. Conferência visual ampla e Mesa separada permanecem em OR-14, conforme matriz de regressão.

### Correção da navegação após mutação — D-32

As gravações de 22:02 e 22:09 mostram que a escrita termina, mas Voltar sai do archive; a captura de Colunas mostra ancestrais vazios enquanto os breadcrumbs conservam os níveis. O refresh removia integralmente as entradas de histórico da sessão antiga e limpava os dados das colunas sem reenumerar os ancestrais. O restauro agora migra caminhos válidos para a sessão nova, reconstrói dados/seleções de cada coluna e registra a revelação de outro diretório como navegação. A adição também conserva a pasta interna atual. Novos testes caracterizam histórico profundo, destinos removidos, fallback e reorganização; evidências executadas na matriz de regressão.
