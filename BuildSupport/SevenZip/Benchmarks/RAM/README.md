# RAM total do Zforge e seus processos de motor

Este teste compila três cópias temporárias Release: CLI anterior (`05d1720`), branch estática e branch dinâmica. Injeta `driver.swift` somente nessas cópias para iniciar as mesmas chamadas `ArchiveServing` dentro do aplicativo, incluindo staging e limpeza. Nenhuma instrumentação é acrescentada ao app distribuído nas branches. Normaliza arquitetura arm64 e mínimo macOS 26.0 no baseline CLI.

A instrumentação cria uma janela de 1100 × 720 com o `ContentView` real e os serviços de UI de fixture já existentes, para manter o estado visual inicial igual e evitar consultas variáveis a Spotlight. As operações medidas usam o motor real de cada variante, não `UIFixtureArchiveEngine`. O Launch Services inicia o app; `AppDelegate` cria a janela de medição em uma build assinada, sem XCTest e sem harness separado para o motor. Não mede gestos, menu, preview ou todo o catálogo de estados da interface.

## Cargas e amostragem

- Um arquivo de 256 MiB: bloco determinístico de 512 KiB pseudoaleatórios (xorshift64, seed 42) + 512 KiB de zeros, repetido 256 vezes.
- 10.000 arquivos de 4 KiB: metade pseudoaleatória, metade zeros, xorshift64 com seed 42.
- ZIP Deflate nível 5, bytes rápidos 32, duas threads; 7z LZMA2 nível 5, dicionário de 64 MiB, bytes rápidos 32, sólido, duas threads. Opções passam pelos contratos do próprio app.
- Preparação e leitura de hashes usam pools de autorelease; há uma espera para drenagem antes da baseline. Três repetições com um processo novo do app para cada carga/formato/variante: 36 launches. Ordem de variantes rotacionada por repetição. Não descarrega cache do sistema.
- Janela inicializada antes da baseline; baseline de 2 s, criar, abrir/listar, testar, extrair, fechar sessões e observar mais 3 s. Hashes SHA-256 e contagem de todos os arquivos extraídos são conferidos após a saída do app, fora dos intervalos medidos.
- `sampler.c` roda fora do processo do app. A cada 5 ms consulta `proc_pid_rusage` para RSS e `physical footprint`, percorrendo todos os descendentes de forma recursiva. Totais são somados dentro da mesma amostra, em vez de somar máximos de momentos diferentes. Na variante CLI, exige observar pelo menos app + processo filho.
- Registra o uso do processo principal separadamente do total, baseline, picos por fase, pico entre baseline e fim da observação pós-limpeza e memória após limpeza. Preparação, hashing e inicialização/loader ficam fora desse pico. Grava intervalos efetivos e número de amostras. Fases sem amostras são marcadas explicitamente; não se atribui a elas um pico inexistente.

## Executar

Requer macOS, Xcode, Python 3.9+, assinatura local configurada no projeto e leitura de métricas dos processos. O próprio app cria uma pasta descartável no seu tmp, gera e confere as cargas para manter acesso pelo App Sandbox, e apaga somente essa pasta ao terminar. O controlador externo não lê nem escreve o container. O runner e sampler não entram no bundle e seu próprio uso não é somado ao total do app.

```sh
python3 BuildSupport/SevenZip/Benchmarks/RAM/run.py \
  --output-dir /private/tmp/ZforgeRAMRun
```

Para separar build de execução: acrescentar `--build-only` na primeira chamada, depois `--reuse-builds` com o mesmo diretório. `--repetitions` e `--interval-ms` permitem variar a duração e frequência. `results.json` registra as fases e eventos; os CSVs preservam toda a série temporal. Logs de build e launch ficam no diretório de saída.

## Limites

RSS somado pode contar páginas compartilhadas em mais de um processo. O somatório de `physical footprint` representa a memória atribuída à família de processos e é apresentado separadamente; não é toda a RAM do sistema nem inclui indiscriminadamente o cache global de filesystem. Sampling discreto pode perder picos mais curtos que seu intervalo; a frequência efetiva e cobertura devem acompanhar as conclusões. Retenção após limpeza inclui caches/allocator do app e do motor. Não implica vazamento sem crescimento em execuções repetidas no mesmo processo; este teste usa processos novos para comparação independente.

A leitura externa usa `CLOCK_MONOTONIC` também no controlador; o Python 3.9 do macOS usa outra origem em `time.monotonic`, que não pode ser misturada aos timestamps do sampler. `proc_listchildpids` retorna número de PIDs, não bytes; isso foi verificado com uma prova de fork/filho antes da matriz final. O runner exige observar o processo chamado `7zz` na variante CLI.

O teste encontrou e levou à correção D-21: a extração nativa precisa partir da raiz autorizada. As comparações finais usam as revisões corrigidas, registradas em `metadata.refs`; os resultados anteriores do microbenchmark permanecem históricos.
