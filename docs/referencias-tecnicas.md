# Referências técnicas enviadas para ByteCrafter

O objetivo atual é um jogo **Godot 3D** de craft, sobrevivência e aventura em mundo aberto, jogável em primeira e terceira pessoa, com cooperativo por LAN. O escopo de referência é a riqueza de sistemas de Minecraft até a versão 1.18, implementada por etapas.

O projeto é para uso pessoal. O usuário autorizou aproveitar assets úteis e informou: “não precisa pesquisar licença, é só para meu uso pessoal”. Não pesquisar licenças nem executar outra auditoria de repositórios. A pesquisa comparativa em lote foi interrompida a pedido do usuário para economizar tokens; esta seleção prática usa apenas arquivos visuais, sem copiar um projeto inteiro.

| Referência | Uso sugerido pelo usuário |
| --- | --- |
| https://github.com/Godot-Templates/Godotcraft.git | Base/exemplo Godotcraft |
| https://github.com/z3dd4-de/Survival-Game.git | Survival game kit |
| https://github.com/SummerEngine/template-3d-city-kit.git | Kit de cidades 3D; possível utilidade |
| https://github.com/MiniDigger/Godotcraft.git | Exemplo Godotcraft |
| https://github.com/jonysuise/voxel-engine-godot-tutorial-jonysuise.git | Tutorial de engine voxel |
| https://github.com/KodeKhaos/Minecraft-like_Godot_CSharp.git | Exemplo Minecraft-like em Godot C# |
| https://github.com/jsoulier/gdcraft.git | Exemplo de jogo craft Godot |
| https://github.com/DINOZYAVIER/minecraft-clone.git | Clone de referência |
| https://github.com/Hylley/Minedot.git | Exemplo de jogo voxel |
| https://github.com/GuilhermeGSousa/game-base-2D.git | Base 2D, talvez útil para interface |
| https://github.com/gdquest-demos/godot-4-3d-third-person-controller.git | Controller Godot 4 em terceira pessoa; usuário acrescentou como possível recurso |
| https://github.com/Zylann/godot_voxel.git | Engine voxel para avaliar como base de uma futura build nativa |

## Compatibilidade das duas bases recentes (2026-10-15)

- `https://github.com/BeleuDev/GodotCraft.git` (HEAD observado `143960f`) declara Godot 4.5/C# no `project.godot` e contém `MinecraftDois.csproj` e scripts centrais C# (`WorldGen.cs`, `Chunk.cs`, `Player.cs`, `BlockSystem.cs`, `LightningSystem.cs`). No runtime atual há Godot padrão 4.7.2, mas não há `dotnet` nem executável Godot .NET.
- `https://github.com/Zylann/godot_voxel.git` descreve Voxel Tools como módulo/extensão C++ para Godot 4. O addon versionado declara mínimo 4.4.1, mas os binários indicados em `addons/zylann.voxel/bin` não estão na árvore-fonte examinada. A release pública consultada entrega bundles de editor/templates Godot próprios, não um addon drop-in C# ou um template Web para o projeto atual.
- ByteCrafter atualmente é Godot 4.7.2/GDScript com Preview/export Web gerenciado. Usar literalmente as duas bases requer outra toolchain e uma migração para build nativa; não cabe na configuração Web atual. Nenhuma revisão de licenças foi feita, conforme pedido do usuário.

Release consultada: `https://api.github.com/repos/Zylann/godot_voxel/releases/latest` (v1.7 na consulta).

Port compatível já aplicado: a criação de colisão por chunk mantém os triângulos do mesher e ativa `ConcavePolygonShape3D.backface_collision`, conforme a solução explícita em `Chunk.cs` do GodotCraft. Foi a correção que fez o raycast atingir a superfície superior e manteve o jogador no chão; não foi adicionada dependência C# ou binária externa.

## Assets incorporados ao protótipo

Os arquivos abaixo foram copiados para as pastas indicadas, sem importar ou renomear os projetos completos:

| Fonte | Arquivos usados no projeto |
| --- | --- |
| https://github.com/KodeKhaos/Minecraft-like_Godot_CSharp | `assets/textures/blocks/` (grama, terra, pedra, madeira, folhas e cobblestone); atlas do terreno montado a partir dessas texturas |
| https://github.com/Godot-Templates/Godotcraft | `assets/textures/blocks/sand.png` |
| https://github.com/BeleuDev/GodotCraft | `assets/textures/clouds.png`; `assets/models/player/model.glb` e `model_0.png` |
| https://github.com/z3dd4-de/Survival-Game | `assets/textures/enemies/slime.png` para inimigo 3D billboarding |

`godot_voxel` permanece como candidato para uma variante nativa; não foi adicionado à build de prévia atual.

## Diagnóstico de controles e renderização (2026-10-15)

- A HUD cobrindo a tela fazia o handler de mouse em `_unhandled_input` perder eventos antes do olhar; o controller agora trata o movimento em `_input`, mantendo o mouse do mundo acessível.
- A/D continua deslocando lateralmente; o avatar em terceira pessoa gira suavemente para a direção do movimento. O mouse horizontal gira corpo/câmera e o vertical altera o pitch.
- A `SpringArm3D` agora exclui o RID do próprio `CharacterBody3D`; captura nativa confirma extensão aproximada de 4,2 m em área livre, em vez de recolher para dentro do jogador.
- As faces superiores que pareciam ausentes eram descartadas pelo backface culling do material voxel, não por tiles incompletos. O material agora desabilita esse descarte; captura no renderer nativo mostra terreno superior preenchido. A colisão bilateral do chunk continua habilitada separadamente.
- O atlas original permanece na orientação já validada no renderer. No atlas atual, tábuas usam o tile 8 (madeira) e o tile 9 é cobblestone; manter esse mapeamento e não reintroduzir as inversões experimentais de linha UV.
- Verificação nativa de input enviou D e movimento físico do mouse: body yaw chegou a aproximadamente -1,57 rad com D, root yaw a -0,576 rad e pitch a -0,216 rad após os eventos de mouse.
- A atmosfera diurna foi ajustada para céu azul com cúpula de nuvens; `clouds.png` é uma textura branca com alpha, portanto o shader usa seu alpha em vez de tratar o RGB como máscara escura.

O repositório `game-base-2D` continua registrado como referência complementar de interface; não altera a decisão de manter o mundo principal em 3D/Godot.


## Integração dos assets enviados (2026-10-15)

- O fundo `assets/ui/menu_background.png` aparece no menu com os botões de mundo e LAN em um painel contrastante; captura nativa 1280×720 foi conferida.
- `assets/ui/loading_initial.png` é usado no overlay nativo por pelo menos 3 segundos. O shell Web usa a mesma arte de `/manus-storage/loading_initial_8a3705a5.png`, conserva a barra ligada ao progresso, estado de erro e retry, e aguarda no mínimo 3000 ms antes de ocultar o loader.
- `ByteCrafterAvatar` substitui o boneco procedural com os rigs boy/girl e suas texturas. Seleção salva em `user://bytecrafter_player.json`; a pose remota LAN transmite identificador do rig e estado de animação.
- `walk`, `run`, `jump`, `mine` e `attack` estão conectados à locomoção/ações existentes. O clip `death` também foi importado, mas segue sem ser disparado enquanto o fluxo de respawn for imediato; idle continua usando provisoriamente o primeiro quadro da caminhada por não haver clip dedicado no ZIP.
- `player_boy2/`, `player_girl2/`, `ete/` e `zumbi/` permanecem apenas reservados no registro do ZIP; não entram no jogo até receber os rigs preparados pelo usuário.
- Captura nativa posterior à redução de escala/opacidade da cúpula mostrou o céu mais limpo; `npm run check` e a build de Preview Web passaram nesta rodada.
