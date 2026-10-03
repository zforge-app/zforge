# 7-Zip: CLI, linkagem estática e dinâmica

Execução em 2026-10-03. Branches solicitadas: `feat/7zz-static-linking` e `feat/7zz-dinamic-linking`; Git não permite `:` no nome. Referência estática: `d584002`, sobre fontes oficiais 26.02 (`08fa476`). A variante dinâmica mantém a mesma ponte e políticas, mas incorpora `libSevenZipNative.dylib` em `Contents/Frameworks`, assinada por `CodeSignOnCopy`. A implementação dinâmica não altera automaticamente a escolha de distribuição do produto.

## Método e reprodução

Mesma suíte de núcleo da rodada anterior: ZIP Store (`x=0` / `-mx=0`), criar, listar, testar e extrair. Dados determinísticos: um arquivo de 64 MiB (sequência 0–255 repetida) e 2.000 arquivos de 256 B (mesma sequência). Três repetições, cache aquecido, ordem CLI/estática/dinâmica rotacionada por repetição. Hashes SHA-256 dos arquivos extraídos conferidos fora dos temporizadores: todos coincidiram em todas as 18 execuções.

Host macOS 27.0.1 arm64; Apple Clang 21.0.0, SDK 27.0; nativo O2, mínimo macOS 26.0. O CLI é o `Vendor/7zz` oficial. Revisão, hashes dos binários/ponte, medições individuais, RSS e medianas estão em [7zip-linking-results.json](7zip-linking-results.json). Os resultados desta execução substituem a comparação de duas variantes para comparação atual, mantendo aquela rodada como evidência histórica.

- [Harness Objective-C++](../../BuildSupport/SevenZip/Benchmarks/native.mm) comum às duas integrações.
- [Runner Python](../../BuildSupport/SevenZip/Benchmarks/run.py) compila ambos os harnesses, gera os dados e compara com CLI. Não requer bibliotecas Python externas.
- Compilar Release estática na branch correspondente e preservar sua `.a` em DerivedData separado. Compilar Release dinâmica na outra branch e preservar a dylib assinada do bundle. Os paths são passados explicitamente ao runner, permitindo executá-lo em ambas as branches.

```sh
python3 BuildSupport/SevenZip/Benchmarks/run.py \
  --static-library /private/tmp/ZforgeNativeRelease/Build/Intermediates.noindex/Zforge.build/Release/Zforge.build/DerivedSources/SevenZip/libSevenZipCore.a \
  --dynamic-library /private/tmp/ZforgeDynamicRelease/Build/Products/Release/Zforge.app/Contents/Frameworks/libSevenZipNative.dylib \
  --output-dir /private/tmp/ZforgeThreeWayBenchmarkRepeat
```

O diretório de saída precisa ser novo. Artefatos da execução registrada: `/private/tmp/ZforgeThreeWayBenchmark`, log `/private/tmp/zforge-three-way-benchmark.log`. Toda extração é feita em diretórios de saída separados.

## Medianas em milissegundos

| Dados | Integração | Criar | Listar | Testar | Extrair |
| --- | --- | ---: | ---: | ---: | ---: |
| 64 MiB / 1 arquivo | CLI | 26,075 | 3,411 | 11,225 | 25,324 |
| 64 MiB / 1 arquivo | Estática | 23,463 | 0,500 | 8,735 | 26,374 |
| 64 MiB / 1 arquivo | Dinâmica | 24,244 | 0,527 | 8,712 | 22,779 |
| 256 B / 2.000 arquivos | CLI | 29,769 | 8,122 | 7,289 | 121,475 |
| 256 B / 2.000 arquivos | Estática | 22,370 | 2,009 | 4,070 | 160,208 |
| 256 B / 2.000 arquivos | Dinâmica | 22,479 | 2,051 | 4,124 | 163,565 |

Estática e dinâmica tiveram tempos próximos nas operações com muitos arquivos: diferença dinâmica/estática de aproximadamente +0,5% na criação, +2,1% na listagem, +1,3% no teste e +2,1% na extração. Com somente três amostras, diferenças pequenas não estabelecem superioridade nem uma estimativa confiável de penalidade causada pela linkagem. Nos arquivos pequenos, a extração nativa ficou aproximadamente 32% (estática) e 35% (dinâmica) acima do CLI. O caminho nativo também impõe suas verificações de destino e metadados; a diferença não isola o efeito do linker.

## Limites da interpretação

- Não inclui staging Swift, UI, sandbox, leitura comprimida com outros métodos, cache frio ou operação completa do Zforge. Ambos os nativos usam a mesma ponte; na estática ela é compilada no harness, na dinâmica vem da dylib do app.
- Os tempos de fase nativos começam depois da inicialização do processo e do loader. O CLI inclui a inicialização de um processo por comando e descarta o texto de listagem em `/dev/null`, sem medir o parser Swift antigo. Portanto a vantagem de listagem é uma comparação desse protocolo, não de linkagem isolada.
- `process_total_s` registra o processo inteiro dos harnesses nativos, incluindo loader e montagem de fontes. A primeira execução foi muito mais lenta (estática ~435 ms, dinâmica ~538 ms no dataset grande), enquanto as seguintes ficaram ~55–66 ms. Isso não é benchmark de lançamento do app nem prova do custo isolado da dylib. Não atribuir esses outliers somente à linkagem.
- RSS nativo é o pico acumulado do processo de quatro operações; RSS CLI é medido por processo/operação. Não representam consumo de memória do aplicativo completo.
- Tempos absolutos de criação/listagem dos arquivos pequenos variaram bastante em relação à rodada anterior. Estado do filesystem/cache e verificações de hash fora dos temporizadores podem alterar as condições das próximas fases; só comparar as três variantes desta rodada, sem inferir um ganho do código desde a medição anterior.
- Debug dinâmica: 108 testes aprovados, 0 falhas, 0 ignorados em `/private/tmp/ZforgeDynamicTests.xcresult`. Release dinâmica compilada; `otool` confirmou `@rpath/libSevenZipNative.dylib`, dylib arm64 com `minos 26.0`, e `codesign --verify --deep --strict` validou app e biblioteca com assinatura Apple Development. A versão estática tem os mesmos 108 testes e provas de Release na matriz de regressão. UI, runtime macOS 26.0 e distribuição pública continuam pendentes.
