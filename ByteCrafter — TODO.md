# ByteCrafter — TODO

Escopo de referência: jogo 3D Godot em português brasileiro, com alvo de riqueza de sistemas equivalente à era Minecraft 1.18. A implementação começa por um protótipo jogável e cresce por etapas; esse primeiro corte não reduz a ambição final.

## Mundo aberto voxel e construção — em andamento

- [ ] Atender ao pedido: “Quero um jogo tipo mine craft, só que chamaremos de ByteCrafter”; “o jogo é mundo aberto”.
- [ ] Criar mundo voxel aberto e expansível, com exploração, geração de terreno, biomas, áreas subterrâneas e streaming de chunks.
- [ ] Permitir explorar, minerar e coletar recursos, quebrar e posicionar blocos e construir livremente.
- [ ] Crescer por etapas, sem reduzir a meta declarada: “tudo q for possível pra ficar um jogo tão bom quanto o minecraft (ao menos 1.18, com tudo q ele tem pra jogar e usar)”.
- [x] Protótipo inicial: terreno procedural por chunks, blocos editáveis, cavernas simples, árvores e salvamento local do seed/alterações.

## Sobrevivência, aventura, inventário e progressão — em andamento

- [ ] Implementar inventário e atalhos da barra rápida, coleta, receitas de crafting, ferramentas/equipamentos, recursos e progressão.
- [ ] Incluir sistemas de sobrevivência, exploração, cavernas, biomas, criaturas e ciclo de dia/noite; expandir atividades e conteúdo conforme o projeto avança.
- [ ] Criar uma experiência de aventura/craft/survival coerente com a ambição de “o melhor jogo craft survival de aventura possível”.
- [ ] Criar XP por mineração e combate, exibir nível e progresso para o próximo nível e persistir o XP no perfil individual do jogador.
- [ ] Trocar os swatches de cor da barra rápida por ícones de itens distinguíveis, com nome legível do item selecionado e dicas para os demais.
- [x] Protótipo inicial: vida, fome, respawn, criaturas passivas, crafting básico de tábuas/gravetos/picareta e ciclo de dia/noite.
- [ ] Completar feedback visual de recursos coletáveis, itens e ferramentas equipadas.

## Personagens e monstros enviados — em andamento

- [ ] Adicionar os rigs `boy2`/`girl2` como opções de personagem além do boy/girl já existentes, usando clipes compatíveis.
- [ ] Colocar o ET e o zumbi rigados como monstros do mundo, com combate, estado de morte e recompensas.
- [ ] Substituir o sprite 2D do slime pelo modelo 3D enviado sem rig, animando-o por squash/stretch procedural.

## Perspectiva, personagem e controles — em andamento

- [ ] Entregar jogo em terceira pessoa e alternância funcional para primeira pessoa, conforme “(1ª e 3ª pessoa)”.
- [ ] Suportar movimento, pulo, corrida, interação de mineração/colocação, câmera e controles explicados em português brasileiro.
- [x] Corrigir o look horizontal: mouse gira câmera e corpo; A/D mantém deslocamento lateral e orienta o avatar para o sentido do movimento em terceira pessoa.
- [x] Manter a câmera de terceira pessoa atrás do personagem, sem colisão com o collider do próprio jogador.
- [x] Protótipo inicial: controle WASD, pulo, corrida, troca de câmera por V e jogador visível em terceira pessoa.
- [ ] Completar ferramentas/equipamentos visíveis e indicadores 3D de alvo/mineração/posicionamento.

## Cooperação multiplayer por LAN — em andamento

- [ ] Atender a “possibilidade de multiplayer via lan” e ao plano aprovado: hospedar ou entrar em sessão cooperativa na rede local, sem depender de servidor público de internet.
- [ ] Sincronizar jogadores e alterações de blocos e manter mensagens claras ao hospedar, entrar, falhar ou desconectar.
- [ ] Verificar partida entre pelo menos dois clientes numa build nativa antes de declarar LAN validado.
- [x] Protótipo inicial: UI para hospedar/entrar e sincronização ENet de posições/blocos no código; a prévia Web desativa LAN porque esse caminho requer build nativa.

## Identidade, idioma, persistência e entrega — em andamento

- [ ] Usar o nome ByteCrafter em título, menu, carregamento e metadados; experiência do jogador em português brasileiro.
- [ ] Preservar localmente mundo, seed, alterações, posição, inventário e estado essencial do jogador.
- [ ] Antes de distribuir qualquer código ou asset de uma referência, resolver licença/permite e obrigações aplicáveis; o usuário informou que cuidará da licença adicional ou da substituição de assets não abertos.
- [x] Protótipo inicial: tela de título/HUD em pt-BR, loader e favicon próprios, salvamento de mundo/jogador e primeiro teste automatizado.
- [ ] Gerar a arte de compartilhamento exigida pela preparação final do Game Godot e validar a build/pacote atual.

## Referências fornecidas

A lista completa e as notas estão em [`docs/referencias-tecnicas.md`](docs/referencias-tecnicas.md). Foram incorporadas algumas texturas/modelos selecionados, mas nenhum projeto inteiro foi copiado. O usuário autorizou tratar as licenças por conta própria e pediu para não gastar mais tempo/token com auditoria; a pesquisa comparativa em lote foi interrompida e não deve ser retomada sem necessidade.

## Assets enviados em 15/10 — em andamento

- [x] Usar a imagem “Tela Inicial” enviada como fundo do menu principal, mantendo os controles LAN e de mundo legíveis.
- [x] Usar `LOADING.png` como tela inicial nativa e arte do shell Web; manter a arte por no mínimo 3 segundos e preservar progresso real, falha recuperável e retry na Web.
- [x] Importar os rigs boy/girl e integrar caminhada, corrida, salto, mineração/ferramenta e ataque; usar a caminhada congelada como idle provisório porque o ZIP não tem clip de idle.
- [ ] Ligar o clip `death` importado ao fluxo de respawn, que ainda é imediato.
- [x] No primeiro ZIP, manter `player_boy2/`, `player_girl2/`, `ete/` e `zumbi/` fora da cena enquanto os rigs faltavam; a segunda remessa foi recebida e os modelos/texturas selecionados foram copiados para `assets/models/`.
- [ ] Integrar `boy2`, `girl2`, ET e zumbi à cena/seleção; substituir o slime 2D pelo modelo 3D e confirmar importação, materiais, escala e animação no Godot.
- [x] Inventariar o ZIP; identificar as artes, os rigs e animações selecionados; preservar os originais do anexo.

## Pacote de estado atual

- O pacote fonte entregue junto com `docs/manual-estado-atual.md` inclui a pasta `assets/` completa deste projeto, inclusive os modelos da segunda remessa já copiados.
- O manual diferencia o protótipo já funcional das integrações ainda abertas; não tratar o ZIP como build final nem como cobertura completa do alvo Minecraft 1.18.
- [x] `npm run check` passou nesta cópia em 15/10/2026; isso confirma o fluxo automatizado existente, não as funcionalidades de XP/monstros/ícones ainda pendentes.

## Evidência de rede local

- Teste em duas instâncias nativas do Godot 4.7.2 (host e cliente ENet em localhost): ambos entraram no mesmo seed; o cliente quebrou um bloco e coletou o pickup; o anfitrião confirmou a alteração do bloco e que o pickup foi removido. Passou.
- Ainda falta validar o pacote executável distribuível em dois dispositivos físicos na mesma LAN; por isso a entrega LAN continua em andamento.

## Correções e verificações recentes

- [x] Corrigir a colisão do terreno: o collider bilateral (`ConcavePolygonShape3D.backface_collision = true`), portado do `Chunk.cs` de GodotCraft, faz o jogador parar no topo do bloco em vez de atravessar o mesh.
- [x] Seed de regressão `120303788`: após escolher um ponto plano e sem árvores, captura nativa no Godot 4.7.2 mostra `is_on_floor=true`; coordenadas do spawn agora são determinadas pela seed, sem alterar as alturas do terreno existentes.
- [x] `npm run check` passou: import/boot, spawn, chão, movimento, mineração/colocação, interação e testes da cena.
- [x] Input real no renderer nativo confirmou que mouse horizontal/vertical altera yaw/pitch, D desloca e vira o avatar, e a câmera de terceira pessoa fica a aproximadamente 4,2 m sem colidir com o próprio jogador.
- [x] Superfícies superiores dos blocos voltaram a renderizar após desabilitar o descarte de backfaces no material voxel; a inspeção nativa confirmou que o defeito era culling, não UV incompleto.
- A captura visual real em primeira e terceira pessoa foi conferida; a build nativa em dois dispositivos LAN e a aceitação final da prévia Web ainda precisam ser feitas pelo usuário.
- O Zylann Voxel Tools não foi adicionado diretamente porque esta opção mantém Godot 4.7/Web; as partes úteis devem ser portadas em GDScript, sem baixar uma nova toolchain.
