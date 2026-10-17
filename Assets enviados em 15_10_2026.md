# Assets enviados em 15/10/2026

## Origem e regra de uso

- Anexo recebido: `/home/ubuntu/upload/assets.zip`.
- Extração de inspeção: `/tmp/bytecrafter-assets-review/`.
- Os arquivos ativos foram copiados para `assets/ui/` e `assets/models/`; os originais do anexo não foram alterados.
- O usuário autorizou a reutilização pessoal dos materiais enviados e pediu para não gastar esforço em auditoria de licenças. Nenhuma licença foi declarada como verificada neste documento; a conferência e eventuais substituições para uma distribuição pública continuam sob responsabilidade do usuário.

## Artes de interface

- `LOADING.png` → `assets/ui/loading_initial.png` (1672 × 941). Usar no overlay nativo e no shell Web, com mínimo de 3 segundos no Web; manter progresso real, estado de erro e retry.
- O loader Web também está disponível antes do PCK em `/manus-storage/loading_initial_8a3705a5.png`; a arte local fica no projeto para o boot nativo.
- `Byte Craft_ Aventuras Sem Limites -Tela Inicial.png` → `assets/ui/menu_background.png` (1310 × 684). É o fundo aprovado para o menu principal. O arquivo não foi retocado; o título funcional do projeto continua sendo **ByteCrafter**.
- `Byte Craft_ Aventuras Sem Limites.png` é uma arte promocional alternativa mantida apenas como referência, não é o fundo do menu nem a capa de compartilhamento.
- As imagens mostram grafia/logos próprios do material fornecido; não remover nem editar essas marcas sem uma instrução explícita.

## Personagens e animações

Os dois arquivos rigados da primeira remessa passaram por importação no Godot 4.7.2; os dois foram renderizados em uma cena de teste com suas texturas `shaded.png`. Os clips importados têm trilhas Mixamo apontando para `Skeleton3D:mixamorig_*`, permitindo uso nos dois rigs compatíveis.

| Recurso | Origem do ZIP | Uso no jogo |
| --- | --- | --- |
| Boy rigado | `player_boy/RIGGED_PLAYER_BOY.fbx` + `player_boy/shaded.png` | Selecionável como `boy` |
| Girl rigada | `player_girl/RIGGED_GIRL1.fbx` + `player_girl/shaded.png` | Selecionável como `girl` |
| Caminhada | `player_animations/Walking (1).fbx` | `walk`; idle provisório congela o primeiro quadro até haver um clipe de idle dedicado |
| Corrida | `player_animations/Fast Run.fbx` | `run` |
| Salto | `player_animations/Jump.fbx` | `jump` |
| Mineração/ferramenta | `player_animations/Martelo 2.fbx` | `mine` |
| Ataque | `player_animations/Standing Melee Attack Downward.fbx` | `attack` |
| Morte | `player_animations/Dying.fbx` | `death`, importado; ainda não acionado porque o respawn atual é imediato |

Os seis clips selecionados foram extraídos para recursos leves `assets/models/animations/*.tres`; isso evita levar ao PCK as malhas/texturas duplicadas embutidas nos FBX de animação. Caminhada e corrida usam loop; salto e ações são de reprodução única. Caminhada, corrida, salto, mineração e ataque já são acionados pelos estados/ações atuais; a animação de morte aguarda uma futura integração com o respawn. A locomoção do jogo continua sob controle do `CharacterBody3D`; o rig anima a pose e não deve deslocar a raiz do player.

## Segunda remessa — rigs e slime

- `player_boy2/RIGGED_BOY2.fbx`, `shaded.png` e `textures/RIGGED_BOY2/RIGGED_BOY2/model/model/model_Glow.png` foram copiados para `assets/models/players/boy2/`.
- `player_girl2/RIGGED_GIRL2.fbx`, `shaded.png` e `textures/RIGGED_GIRL2/RIGGED_GIRL2/model/model/model_Glow.png` foram copiados para `assets/models/players/girl2/`.
- `ete/riged_ete.fbx` e suas texturas foram copiados para `assets/models/enemies/et/`.
- `zumbi/rigged_zumbi.fbx` e suas texturas foram copiados para `assets/models/enemies/zombie/`.
- `slime/base_basic_shaded.fbx` e `shaded.png` foram copiados para `assets/models/enemies/slime/`.

Os arquivos foram preservados com a capitalização e os caminhos de textura relativos da remessa. **Nesta cópia de estado, os novos modelos ainda não estão ligados à seleção de personagem nem à cena de inimigos**; a integração dos rigs, a validação de escala/animação e a animação procedural do slime permanecem como trabalho em aberto. O jogo continua usando os personagens boy/girl anteriores e o slime 2D.
