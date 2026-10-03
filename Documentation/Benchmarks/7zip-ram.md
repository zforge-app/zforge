# RAM total: Zforge + motor 7-Zip

Execução final em **2026-10-03**, macOS 27.0.1 arm64. **36 launches independentes**: dois datasets × ZIP/7z × três integrações × três repetições. Todas as criações, listagens, testes e extrações concluíram; SHA-256 conferido em todos os arquivos. Cada execução teve exatamente uma janela de medição com o `ContentView` real, serviços de UI de fixture e motor `ArchiveServing` real. O app não carregou XCTest.

O total CLI inclui **Zforge + `7zz`** na mesma amostra. As variantes nativas incluem o processo inteiro do Zforge com motor incorporado ou dylib. O sampler/controlador ficam fora dessa família e não entram no total. Baseline e limpeza são medidos com o mesmo processo do app.

## Pico total de physical footprint (MiB)

Mediana de três execuções; entre parênteses, mínimo–máximo dos picos amostrados. `Physical footprint` é a memória atribuída à família de processos pelo macOS, não a RAM de todo o sistema.

| Carga | Formato | CLI | Estática | Dinâmica |
| --- | --- | ---: | ---: | ---: |
| 1 arquivo de 256 MiB | ZIP | 95.2 (95.1–95.3) | 94.1 (93.8–94.5) | 94.6 (94.1–94.7) |
| 1 arquivo de 256 MiB | 7Z | 737.2 (737.2–737.3) | 992.3 (991.9–992.4) | 992.5 (992.3–992.7) |
| 10.000 arquivos de 4 KiB | ZIP | 107.4 (107.4–108.4) | 153.6 (150.7–153.7) | 155.1 (154.6–157.2) |
| 10.000 arquivos de 4 KiB | 7Z | 492.2 (492.1–492.2) | 554.6 (554.0–555.1) | 555.1 (554.6–555.5) |

**Estática e dinâmica ficaram próximas**, sem diferença de RAM relevante demonstrada entre elas nesta amostra. Comparar com CLI depende da carga: ZIP com um arquivo grande ficou próximo; as integrações nativas usaram mais memória nas cargas de muitos arquivos e no pico acumulado do pipeline 7z grande. Não atribuir essas diferenças somente ao tipo de linkagem.

## Baseline e após fechar as sessões

Mediana de `physical footprint` durante os dois segundos de baseline e durante três segundos após fechar as sessões. Não é medição de vazamento nem de toda a vida útil do app.

| Carga / formato | Integração | Baseline (MiB) | Após limpeza (MiB) |
| --- | --- | ---: | ---: |
| 1 arquivo de 256 MiB / ZIP | CLI | 55.7 | 55.7 |
| 1 arquivo de 256 MiB / ZIP | Estática | 55.5 | 94.1 |
| 1 arquivo de 256 MiB / ZIP | Dinâmica | 56.1 | 94.6 |
| 1 arquivo de 256 MiB / 7Z | CLI | 55.7 | 55.8 |
| 1 arquivo de 256 MiB / 7Z | Estática | 55.9 | 992.3 |
| 1 arquivo de 256 MiB / 7Z | Dinâmica | 56.0 | 992.5 |
| 10.000 arquivos de 4 KiB / ZIP | CLI | 55.5 | 95.3 |
| 10.000 arquivos de 4 KiB / ZIP | Estática | 56.0 | 86.4 |
| 10.000 arquivos de 4 KiB / ZIP | Dinâmica | 55.8 | 87.8 |
| 10.000 arquivos de 4 KiB / 7Z | CLI | 55.9 | 83.0 |
| 10.000 arquivos de 4 KiB / 7Z | Estática | 56.1 | 85.8 |
| 10.000 arquivos de 4 KiB / 7Z | Dinâmica | 55.9 | 86.0 |

### Onde aparece a diferença no 7z grande

| Integração | Criar: pico | Testar: pico | Extrair: pico | Após limpeza |
| --- | ---: | ---: | ---: | ---: |
| CLI | 737.2 | 314.2 | 314.2 | 55.8 |
| Estática | 735.8 | 992.3 | 992.3 | 992.3 |
| Dinâmica | 736.2 | 992.5 | 992.5 | 992.5 |

A criação isolada atingiu praticamente o mesmo pico nas três variantes. A diferença no pipeline nativo aparece na etapa de teste e permanece após extração/fechamento: cerca de **992 MiB**, versus **56 MiB** no CLI após seus filhos terminarem. Esse é um achado de retenção de memória a investigar (OR-11). O teste não identifica sua causa: caches, allocator, ownership de objetos ou outras hipóteses exigem profiling. Não prova vazamento, crescimento ilimitado nem desempenho de várias operações dentro do mesmo processo.

## Pico total de RSS (MiB)

RSS somado pode contar páginas compartilhadas em mais de um processo; é mantido separado do footprint.

| Carga | Formato | CLI | Estática | Dinâmica |
| --- | --- | ---: | ---: | ---: |
| 1 arquivo de 256 MiB | ZIP | 161.8 | 160.4 | 160.7 |
| 1 arquivo de 256 MiB | 7Z | 803.7 | 1058.5 | 1058.3 |
| 10.000 arquivos de 4 KiB | ZIP | 190.9 | 236.6 | 238.0 |
| 10.000 arquivos de 4 KiB | 7Z | 575.4 | 637.5 | 637.5 |

## Protocolo, evidências e reprodução

- [Runner, driver temporário e sampler](../../BuildSupport/SevenZip/Benchmarks/RAM/README.md).
- [Resultados individuais, eventos, fases e resumos](7zip-ram/results.json). [Séries completas comprimidas](7zip-ram/samples) preservam RSS, footprint, contagem de processos, métricas do pai e presença de `7zz`; o diretório contém um CSV.gz por caso.
- Carga grande: 256 MiB, bloco de 512 KiB xorshift64/seed 42 + 512 KiB de zeros repetido 256 vezes. Carga pequena: 10.000 arquivos de 4 KiB, metade pseudoaleatória, metade zeros. ZIP Deflate nível 5/duas threads/32 bytes rápidos; 7z LZMA2 nível 5/64 MiB de dicionário/duas threads/32 bytes rápidos/sólido.
- Refs finais: CLI `05d1720`; estática `3586384`; dinâmica `d0848d1`. Snapshots temporários apenas normalizam a plataforma antiga e injetam a automação; o runner confere os arquivos de implementação contra as refs. Fontes upstream 26.02 são comuns. Os hashes do driver/sampler estão no JSON.
- Artifacts locais: `/private/tmp/ZforgeFullRAM3`; log final `/private/tmp/zforge-full-ram-run.log`. Builds temporárias Release assinadas, App Sandbox preservado, arm64/macOS mínimo 26.0; esta execução não é prova de runtime macOS 26.0 ou distribuição pública.
- O teste encontrou D-21: a caminhada nativa pelos ancestrais desde `/` falhava no caminho do container. A correção abre a raiz de destino autorizada e caminha somente pelos descendentes com `openat`/`O_NOFOLLOW`. O caso real passou, e ambas as variantes tiveram **109 testes aprovados, zero falhas/ignorados** (`/private/tmp/ZforgeOutputRootStaticTests.xcresult` e `/private/tmp/ZforgeOutputRootTestsFixed.xcresult`). As tentativas anteriores com falhas de instrumentação/extração não entram nas 36 medições finais.

## Limites

- Intervalo solicitado: 5 ms. Mediana dos intervalos medianos efetivos: **7,60 ms**; maior gap: **22,70 ms**. Todas as criações/testes/extrações tiveram amostras; algumas listagens do archive com um arquivo e a maioria das limpezas foram mais rápidas que a amostragem e estão marcadas sem pico isolado. Picos menores que o intervalo podem escapar.
- Não somamos máximos de processos em instantes diferentes: cada total vem da mesma rodada de consulta. As consultas aos PIDs são sequenciais, portanto o total é uma aproximação contemporânea, não uma captura atômica de toda a família.
- Janela de medição é criada explicitamente com `ContentView` porque o ambiente suprimia a abertura automática. Os serviços visuais de fixture fixam o estado inicial; a listagem não é publicada como milhares de linhas na UI. As operações usam o motor real, com staging, sessões e cleanup. Não mede menus, gestos, thumbnails de 10.000 itens nem todos os estados visuais do produto.
- Preparação/hash dos dados e inicialização/loader ficam fora do pico baseline→pós-limpeza. Autorelease pools drenam os buffers de preparação. Cache do filesystem não é esvaziado; os datasets são regenerados em cada processo, e a ordem das variantes roda entre repetições.
- Não mede todo o consumo do sistema, da WindowServer, dos serviços compartilhados ou do cache global de filesystem. Três repetições permitem caracterizar esta carga, sem estabelecer significância estatística universal.
