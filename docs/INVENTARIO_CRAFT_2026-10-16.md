# ByteCrafter — inventário e crafting (revisão)

## Implementado nesta revisão

- A grade 3×3 de crafting mantém nove células com ingredientes reais.
- Clique direito em um item do inventário move uma unidade para a primeira célula livre.
- Clique esquerdo numa célula ocupada devolve uma unidade ao inventário.
- O slot de resultado avalia receitas e, quando clicado, consome os ingredientes da grade e adiciona o produto.
- Receitas da grade: 1 tronco → 4 tábuas; 2 tábuas verticalmente adjacentes → 4 gravetos; padrão de picareta de madeira (três tábuas na linha superior e dois gravetos na coluna central abaixo) → 1 picareta.
- Os atalhos de crafting anteriores continuam disponíveis.
- A grade de ingredientes é salva junto ao perfil e validada ao carregar.
- Esc e o botão de fechar usam o mesmo caminho para fechar a interface e devolver ingredientes ao inventário.
- As três receitas implementadas estão declaradas em um catálogo central com ingredientes, saída, limite de pilha, estação declarada e regra de grade.
- Crafting rápido e pela grade recusam o resultado antes de consumir ingredientes quando a pilha de saída não comporta o produto.

## Limitações conhecidas

- A grade ainda usa inventário agregado por tipo de item, não pilhas independentes por slot.
- Não há arrastar-e-soltar com cursor, divisão de pilhas, distribuição em vários slots nem bancada colocável/interativa no mundo.
- A grade 3×3 está acessível pelo menu de inventário; não é bloqueada por uma bancada construída.
- As receitas da grade limitam-se a troncos, tábuas, gravetos e picareta de madeira; ferramentas de pedra, fornalha, baú e outras receitas ainda precisam ser implementadas.
- Itens especiais não possuem todos ícones de textura dedicados.

## Teste recomendado no Godot 4.7

1. Abra `project.godot` no Godot 4.7/4.7.2 e aguarde a importação terminar.
2. Execute a cena principal com F5 e entre no mundo.
3. Pressione E; use o botão direito sobre um tronco para colocá-lo na grade e confira que a quantidade do inventário diminui.
4. Clique no slot de resultado; confirme que são entregues quatro tábuas.
5. Coloque duas tábuas em células verticalmente adjacentes e fabrique gravetos.
6. Monte a receita da picareta na disposição indicada e confirme o produto.
7. Feche o menu com E e com Esc e confirme que os itens não desaparecem.
8. Salve, feche e reabra o projeto para verificar a persistência da grade e do inventário.
9. Confirme que o console não apresenta erros durante as operações.

## Validação executada nesta revisão (16/10/2026)

- Godot 4.7.2: importação limpa sem erros; a primeira importação emitiu 45 avisos não fatais do importador FBX, sem impedir a importação.
- Suíte headless `test/test_suite.tscn`: **105 verificações aprovadas**, incluindo receitas válidas/inválidas e proteção contra perda de ingredientes com saída cheia.
- Cena principal iniciada headless sem erros; auditoria estática verificou 100 referências `res://` e não encontrou caminhos ausentes.
- O wrapper `npm run check` requer `GAME_RUNTIME`, não configurado neste ambiente; os testes foram executados diretamente pelo Godot.
- Multiplayer em dois dispositivos físicos e aceitação manual de interface continuam pendentes.
