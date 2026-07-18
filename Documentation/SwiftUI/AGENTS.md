# Operação da fonte local de SwiftUI

Estas instruções se aplicam a todo o conteúdo de `Documentation/SwiftUI`.

## Ordem obrigatória de consulta

1. Começar por `INDEX.md` para localizar a família conceitual apropriada. Para decisões amplas, usar `GUIDANCE.md` como síntese e abrir os contextos primários que sustentam a conclusão.
2. Pesquisar o corpus antes de abrir a web, preferencialmente com `rg -n -i '<conceito|símbolo|API>' Documentation/SwiftUI/contexts`.
3. Ler apenas os contextos que respondam à questão e conferir no front matter a URL, a data de captura, as plataformas, a disponibilidade e o nível de confiança.
4. Para decisões do Zforge, priorizar informações aplicáveis a macOS. Tratar UIKit, WatchKit e visionOS como contexto e preservar a adaptação nativa por SwiftUI/AppKit.
5. Quando assinatura, disponibilidade ou comportamento de compilação precisarem ser exatos, validar também contra o SDK e o Xcode locais. Registrar no trabalho qual SDK sustentou a conclusão.

O corpus local é a primeira fonte de recuperação. Não usar Context7 nem outro agregador externo para substituir esta fonte.

## Expansão incremental obrigatória

Todo link absoluto existente em um contexto representa uma fronteira ainda não ingerida. Sempre que for necessário acessar um desses links para obter informação:

1. Consultar a página oficial correspondente, sem percorrer automaticamente os links encontrados nela. Cada expansão continua limitada a uma página.
2. Criar antes de concluir a tarefa um novo arquivo em `contexts/`, usando `CONTEXT-TEMPLATE.md`. O nome deve ser estável, descritivo, em kebab-case e não pode colidir com outro contexto.
3. Registrar URL canônica, identificador DocC quando houver, instante da captura, hash SHA-256 do payload, ETag ou Last-Modified disponíveis, formato, plataforma, disponibilidade, origem e confiança.
4. Consolidar a página para recuperação: resumo curto, assinatura quando aplicável, mapa de seções, implicações práticas e todos os links secundários encontrados. Os links secundários permanecem absolutos e não são visitados nessa mesma expansão.
5. Atualizar `metadata/captures.json` e, quando aplicável, os índices de assets e blocos de código. Adicionar o contexto ao `INDEX.md` em uma seção apropriada de expansões sob demanda.
6. Somente depois de criar e verificar o novo arquivo, substituir no documento de origem o link externo consultado por uma referência Markdown relativa ao novo contexto. Substituir também ocorrências semanticamente idênticas no corpus quando apontarem para a mesma URL canônica. A URL oficial continua preservada no front matter e em Proveniência do novo arquivo.
7. Não substituir o link por um stub e não marcar uma página como local quando a captura falhar. Nesse caso, manter o link externo e registrar o bloqueio no trabalho em andamento.

Essa sequência é obrigatória: acessar um link do corpus implica materializar seu contexto local e trocar a referência externa pela referência local.

## Ausência de informação local

Se a informação necessária não existir no corpus:

1. Pesquisar primeiro no site oficial [Apple Developer](https://developer.apple.com/), restringindo a consulta às fontes oficiais da Apple.
2. Quando a resposta usar uma página encontrada, incorporá-la ao corpus pelo mesmo protocolo de expansão incremental antes de concluir a tarefa.
3. Se a documentação web e o SDK local divergirem, tratar a versão do SDK alvo do Zforge como evidência de compilação e a página oficial como orientação conceitual; registrar explicitamente a divergência.

## Manutenção e qualidade

- `contexts/` contém a camada normalizada e pesquisável; não copiar páginas integrais. Preservar sínteses compactas e índices de links.
- `metadata/captures.json` é o inventário autoritativo de cobertura, hashes e falhas. `metadata/assets.json` e `metadata/code-blocks.json` mantêm os índices separados dos materiais visuais e de código.
- `tools/bootstrap.py` reconstrói o recorte inicial e sobrescreve os contextos gerados. Usá-lo apenas em uma atualização completa e auditada; preservar expansões e anotações posteriores.
- Uma mudança de hash não prova mudança semântica. Comparar o contexto com a fonte antes de alterar recomendações.
- Não redistribuir o corpus nem payloads da Apple sem revisão dos termos aplicáveis.
