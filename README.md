# ByteCrafter

Protótipo de sandbox voxel 3D, aventura, construção e sobrevivência feito em Godot. Esta entrega inclui uma rodada de correções de estabilidade, persistência e desempenho. O alvo de longo prazo continua sendo uma experiência muito rica, próxima do escopo de Minecraft 1.18; esta versão é somente a primeira base jogável, não uma implementação completa desse conteúdo.

## Abrir no Godot

- Recomendado: Godot **4.7.2 standard** (GDScript; o projeto não requer Godot .NET nem SDK C#).
- Na tela Project Manager, escolha **Import** e selecione este `project.godot`; depois abra o projeto e pressione **F5** para executar a cena principal.
- Para a prévia gerenciada/Web, o projeto usa o contrato padrão `true` → `site/`; use o fluxo Webdev do projeto. A versão Web é de jogador único: partidas LAN exigem o build nativo do Godot.


## Atualização de fontes — 16/10/2026 (revisão de inventário/crafting)

- Corrigido o ciclo principal de `_process`: a simulação não fica mais presa à condição de remoção da tela inicial depois dos primeiros três segundos. Dia/noite, interação, mineração, sobrevivência e atualização da HUD voltam a ser processados durante a partida.
- Adicionado cache temporário de alturas do terreno, limpo quando o centro do streaming muda, para evitar chamadas repetidas de ruído ao montar os chunks próximos.
- O carregamento de alterações do mundo valida formato, coordenadas, altura e IDs de blocos, com limite de registros aceitos.
- Os saves de mundo e perfil passam a usar arquivo temporário e backup durante a substituição, reduzindo o risco de perder o save anterior se a gravação falhar.
- O perfil valida o tipo dos dados de inventário/posição e limita a quantidade de drops restaurados.
- Crafting informa sucesso ou falta de recursos e limita pilhas de itens coletados.
- A grade 3×3 armazena ingredientes reais: clique direito em um item para mover uma unidade à primeira célula livre; clique numa célula ocupada para devolver o ingrediente.
- A grade reconhece receitas de tronco para tábuas, duas tábuas verticais para gravetos e o padrão de picareta de madeira. Clique no slot de resultado para concluir a receita.
- O conteúdo da grade de crafting é salvo no perfil e restaurado ao carregar.
- Esc fecha o inventário pelo mesmo fluxo do botão de fechar, devolvendo os ingredientes da grade ao inventário.
- As três receitas existentes agora usam o catálogo central `scripts/game/crafting_recipe_book.gd`, com ingredientes, saída, limite de pilha, estação declarada e regra espacial.
- O crafting rápido e pela grade verificam o espaço da saída antes de consumir ingredientes; o limite da picareta também é aplicado.
- Os rigs CC de ET, zumbi e boss usam `scripts/game/rig_animation_controller.gd`: os clips padrão de caminhada, ataque e morte são retargetados do esqueleto Mixamo-fonte para o esqueleto CC. O slime permanece com o visual procedural existente.
- O mundo agora popula coelhos, vacas, ovelhas e porcos caçáveis. Coelhos fornecem carne; vacas, carne e couro; ovelhas, lã e carne; porcos, carne e banha. A tecla F/clique esquerdo usa o mesmo golpe do combate, com fuga e drops persistentes.
- A tecla T coloca uma mesa de craft física consumindo `mesa_craft`; a tecla E abre a interface de crafting. Foram adicionados receitas de mesa, tochas e preparação de carne com banha. Pedra exige picareta; blocos leves continuam mineráveis manualmente.
- A progressão da mesa inclui lingote de ferro, picareta, machado e espada de ferro. O ferro é obtido combinando pedra e banha na grade, e as ferramentas têm efeitos distintos: picareta acelera pedra, machado acelera madeira e espada aumenta o dano.
- Couro pode virar capacete, peitoral, calças e botas. As peças são reconhecidas automaticamente como proteção, com redução acumulável de 15% por peça até 60%, e a proteção é aplicada ao dano recebido antes do respawn.
- A exploração procedural agora classifica o terreno em planícies, campos de musgo, regiões congeladas, zonas vulcânicas e biomas de cristal. Cada um altera o bloco de superfície: musgo, gelo, basalto ou cristal. Ruínas/torres antigas aparecem de forma determinística pela seed fora do spawn, usando pedra antiga e minério brilhante.
- Blocos de cristal geram `Cristal` ao serem minerados; cristal + banha produzem a `Lanterna de cristal`, criando uma recompensa de exploração além dos recursos comuns.
- O tile de folhas do atlas foi corrigido para manter preenchimento opaco dentro do próprio bloco. A transparência vazada que permitia enxergar o terreno inteiro através de uma única camada de folhas foi removida, sem alterar os demais blocos.
- A correção posterior preserva a transparência visual lateral das folhas; somente as faces superior/inferior usam uma tampa opaca para não revelar o terreno abaixo. Troncos e folhas continuam quebráveis sem ferramenta.
- O zumbi foi reorientado para o eixo vertical correto, normalizado para 1,80 unidade (tamanho do jogador), teve o alcance reduzido e só causa dano com linha de visão desobstruída.

**Validação nativa desta revisão (Godot 4.7.2):** importação limpa sem erros, inicialização headless da cena principal sem erros e suíte de gameplay aprovada em **147 verificações**, incluindo clips de pulo/morte dos avatares, retarget de movimento/ataque/morte dos inimigos não-slime, barras de vida, escala/collider e ausência de squash/stretch. Os FBX novos de ET/zumbi permanecem copiados no projeto, mas os rigs originais foram restaurados na cena porque os novos clips Mixamo causaram regressão visual de escala. A primeira importação limpa reportou 45 avisos não fatais do importador FBX (`Non-node element connected to root`); `npm run check` requer um `GAME_RUNTIME` não presente neste ambiente; a suíte foi executada diretamente no Godot. Multiplayer em dois dispositivos físicos continua não validado.

## Controles
| Ação | Controle |
| --- | --- |
| Andar | W, A, S, D |
| Pular | Espaço |
| Correr | Shift |
| Olhar | Mouse (com o cursor capturado durante o jogo) |
| Minerar/atacar | Botão esquerdo do mouse |
| Posicionar o bloco selecionado | Botão direito do mouse |
| Alternar primeira/terceira pessoa | V |
| Inventário e crafting | E; clique direito coloca item na grade; clique esquerdo na célula devolve; clique no resultado fabrica |
| Selecionar atalho | Teclas 1–7 ou roda do mouse |
| Salvar agora | F5 |
| Pausar/voltar ao menu | Esc |

## Partida em LAN

No menu inicial, um jogador escolhe **Hospedar LAN** e os demais escolhem **Entrar na LAN**, informando o IP local do anfitrião. Os dispositivos precisam estar na mesma rede e liberar UDP na porta **24567** no firewall. A conexão não usa servidor público. O smoke test com duas instâncias nativas do Godot confirmou entrada na mesma seed e sincronização de alteração/coleta de blocos; ainda falta a aceitação em dois dispositivos físicos.

## O que existe nesta base

- Terreno voxel procedural em chunks, com streaming, cavernas simples, árvores e superfícies texturizadas.
- Quebrar/colocar blocos, recursos soltos coletáveis, barra rápida, crafting básico e picareta visível.
- Sobrevivência inicial (vida/fome), ciclo dia/noite, criaturas passivas e slime hostil.
- Dano letal entra em estado de morte, toca a animação `death`, bloqueia controles por 1,25 s e depois reaparece no spawn da seed.
- Câmeras em primeira e terceira pessoa, salvamento local e cooperação ENet para sessões LAN nativas.

A geração de mundo, combate, conteúdo, biomas, itens, criaturas, progressão e sistemas de aventura ainda precisam de muitas etapas para atingir a ambição completa do produto.

## Verificação

- `npm run check` executa a validação finita da cena, do spawn, do ciclo de blocos, dos controles e dos saves.
- `npm run check -- --pack` valida um checkpoint Godot já preparado.
- Os testes preservam e restauram os arquivos de save do usuário.

## Referências e licenças

As referências recebidas e as notas sobre o que foi adaptado estão em [`docs/referencias-tecnicas.md`](docs/referencias-tecnicas.md). O projeto usa referências/arquivos escolhidos pelo usuário, além de código GDScript próprio e trechos técnicos portados. As licenças de cada componente ainda precisam ser verificadas antes de redistribuição; o responsável pelo projeto cuidará de obter permissões adicionais ou substituir os itens que não puderem ser distribuídos. **Não distribua esta cópia antes de resolver essas obrigações.**

### Correção de cenário e colisões (16/10/2026)

O streaming agora gera imediatamente o chunk central ao mudar de região, valida a malha de colisão e adiciona colisões dedicadas aos troncos. A copa das árvores também foi engrossada. Consulte `docs/RELATORIO_AUDITORIA_E_ATUALIZACAO_2026-10-16.md`. Esta revisão ainda requer teste no editor Godot 4.7.
