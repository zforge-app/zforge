# Selo Zforge — plano de debossing

Decisão de 2026-10-03: o usuário aprovou a forma do estudo `zforge-stamp-v3-original-mono.png`. O tratamento desejado passa de embossing para **debossing**, como material comprimido para dentro da pasta. A referência física é `reference-debossing-paper.png`. Esta decisão é planejada: o compositor atual ainda usa a forma simplificada e duas passadas de cor.

## Técnica atual e limitação

`ArchiveFolderIconComposer.compose` desenha a pasta nativa, depois uma cópia clara deslocada e uma cópia azul escura da forma vetorial. É um indício simples de relevo, com preenchimento e cores fixas. Não representa profundidade, bordas internas, oclusão nem continuidade da superfície; não usa o estudo v3 aprovado.

## Aperfeiçoamento proposto

1. Preservar o v3 como referência de forma. Derivar um desenho neutro de geometria/profundidade da prensa, Z e círculo, sem carregar os reflexos de aço nem pintar o material como metal. Uma simples silhueta opaca perderia detalhes internos do pistão e discos; manter contornos estruturais e níveis de profundidade.
2. Construir uma máscara da área prensada e um mapa de altura suave, com a superfície intacta em zero e a marca abaixo dela. Borda arredondada/chanfrada, fundo raso, profundidade coerente e anel também rebaixado. Representar a forma tridimensional da referência por níveis rasos na impressão, não por uma peça metálica aplicada.
3. Derivar a direção das superfícies a partir desse mapa e iluminá-las com luz compatível com a pasta, inicialmente superior esquerda. Para a cavidade, a borda interna superior/esquerda tende a escurecer e a inferior/direita a receber luz; isso depende do perfil local. Adicionar sombra interna suave/oclusão nos encontros e cantos, sem sombra externa de objeto flutuante.
4. Modular a luminosidade dos pixels originais da pasta em vez de cobri-los com azul fixo ou branco. Conservar o gradiente, a cor e a textura existentes; reduzir sutilmente a textura no fundo da marca para sugerir compressão. Todo o efeito é limitado à face frontal.
5. Parametrizar profundidade, largura de transição, intensidade e direção da luz. Ajustar em pontos/pixels do tamanho final: profundidade visual menor nos previews grandes; bordas mínimas legíveis em 16–32 pt e supressão de textura/faixas finas que causem ruído. Preservar a centralização compacta e as posições aprovadas.
6. Gerar primeiro uma única prévia grande da impressão na pasta e compará-la à referência física. Após refinamento, conferir os seis tamanhos e os três estados de pasta. Aplicar a mesma transformação de superfície ao selo na pasta aberta; a iluminação não deve ser uma imagem independente colada por cima.
7. Integrar a composição aprovada com cache por estado/faixa de tamanho/aparência. Verificar Core Image ou renderizador alternativo no app com sandbox, tema claro/escuro, quatro modos, seleção, previews e zoom. Não presumir que uma renderização isolada confirma esses fluxos.

## Critérios visuais

- A forma aprovada permanece reconhecível e não vira uma prensa genérica.
- O selo parece uma depressão no mesmo material da pasta.
- Sem placa cinza, brilho metálico independente, preenchimento azul chapado, halo ou sombra externa.
- Luz e sombra interna são visíveis, com profundidade moderada e sem destruir a legibilidade em 16 pt.
- Os estudos existentes permanecem preservados; os PNGs de revisão não exigem um arquivo por tamanho no produto.

## Evidência de estudo visual

A pedido do usuário, foi gerada a [prévia v4](folder-debossing-v4.png) da pasta grande. É uma referência visual obtida por ImageGen, sem integração nem implementação do renderizador proposto. A primeira geração foi refinada para que a prensa e o Z também fossem cavidades. Próximos passos dependem do refinamento visual desta referência; matriz de tamanhos/estados e validação do compositor continuam pendentes.

## Refinamento de direção — preferência por volume

Após comparar as prévias, o usuário preferiu a composição com maior volume interno, apesar de reconhecer a v4 como debossing mais literal. Para a continuação, preservar a fisicalidade, o azul e a cavidade circular da primeira prévia; não achatar o Z e os discos para impor debossing puro. O cilindro superior deve continuar até a borda interna superior do círculo. [Estudo v5](folder-pressed-relief-v5.png) criado com essa correção; ainda não integrado. A preferência visual mais recente prevalece onde conflitar com os critérios anteriores de rebaixamento de todas as formas.

Refinamento v6: recortar o cilindro pela abertura interna e desenhar o contorno circular completo sobre a prensa. O prolongamento não pode cobrir a faixa nem interromper a linha do círculo. Prévia `folder-pressed-relief-v6.png`; ainda sem integração.

## Implementação final autorizada

A v6 foi aprovada e integrada com máscaras neutras de luz e sombra derivadas de uma única referência raster aprovada. Essa técnica preserva sua iluminação e forma diretamente sobre a pasta nativa. O mapa de altura/normais e a iluminação dinâmica descritos acima permaneceram proposta; não são necessários para a composição fixa aprovada e não foram implementados. Regressões e limites em `REGRESSION-COVERAGE.md`, ZF-29 e OR-13.
