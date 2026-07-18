# Fonte local de conhecimento SwiftUI

Este diretório é a camada local, versionável e pesquisável da documentação oficial usada pelo Zforge. A captura inicial cobre a home de SwiftUI e todos os 64 destinos únicos expostos diretamente por Overview, Featured samples e Topics em 16 de julho de 2026.

O conteúdo é normalizado para recuperação por agente: cada contexto registra resumo, papel, módulo, disponibilidade, declaração quando aplicável, mapa da página, links do segundo nível e proveniência. Não é um espelho integral da documentação da Apple.

## Como consultar

Comece por [`INDEX.md`](INDEX.md). Para uma busca direta:

```sh
rg -n -i 'NavigationSplitView|toolbar|focus|accessibility' Documentation/SwiftUI/contexts
```

Leia depois somente os contextos relevantes. Links relativos apontam para páginas já ingeridas; links absolutos são fronteiras pendentes e seguem o protocolo obrigatório de expansão definido em [`AGENTS.md`](AGENTS.md).

## Estrutura

- `INDEX.md`: roteador temático e inventário humano.
- `GUIDANCE.md`: síntese transversal das práticas e do modelo mental relevantes ao Zforge.
- `contexts/`: 65 documentos Markdown da captura inicial e futuras expansões.
- `metadata/captures.json`: cobertura, URL de coleta, hash, ETag, tamanho, profundidade e falhas.
- `metadata/assets.json`: referências visuais encontradas, separadas do texto normalizado.
- `metadata/code-blocks.json`: hashes e metadados dos blocos de código encontrados.
- `tools/bootstrap.py`: crawler reprodutível do recorte inicial, baseado em endpoints DocC e na página HTML SwiftUI Pathway.
- `CONTEXT-TEMPLATE.md`: contrato para novos contextos incrementais.

## Atualização completa

Uma recaptura do primeiro nível requer acesso de rede ao Apple Developer:

```sh
python3 Documentation/SwiftUI/tools/bootstrap.py --workers 4
```

O crawler mantém os payloads somente em memória e persiste hashes e metadados. Ele sobrescreve os documentos gerados e o índice; portanto, uma atualização completa deve ser revisada e reconciliada com expansões posteriores.
