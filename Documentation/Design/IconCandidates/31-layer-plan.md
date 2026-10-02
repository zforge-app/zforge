# Separação em camadas do candidato 30

Este plano registra a tentativa anterior de separar o PNG do candidato 30. O usuário exportou depois [zforge_icon.icon](../../../Zforge/zforge_icon.icon/icon.json) com camadas próprias, já selecionado como ícone do app.

Fonte: [`30-simplified-press-z-distant.png`](30-simplified-press-z-distant.png), PNG transparente de 1254 × 1254 px.

## Ordem de empilhamento

1. **Base inferior — fundo.** Disco circular de aço; sua face superior recebe a sombra e o contato da peça. A parede cilíndrica continua até a borda inferior.
2. **Z metálico — meio.** Uma única peça contínua, com relevo e brilho laranja concentrado nas linhas de contato superior e inferior. Ela precisa preservar a escala e a posição da composição de origem.
3. **Cabeçote da prensa — frente.** Cilindro amarelo e preto, pistão e disco móvel de aço; o cilindro segue até a borda superior. O disco deve ocultar o encontro com a face superior do Z.

Cada camada deve ser um PNG RGBA com o mesmo canvas de 1254 × 1254 px e origem comum em (0, 0). O fundo colorido e o recorte arredondado vistos na prévia do Icon Composer não integram nenhuma das três camadas.

## Estado da extração

As tentativas de isolar as peças com ImageGen alteraram a escala e a posição delas, mesmo usando o candidato 30 como referência. Essas saídas não foram registradas como camadas utilizáveis. Falta extrair as peças preservando os pixels e conferir a sobreposição antes de entregar os PNGs.
