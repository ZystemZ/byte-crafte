# ByteCrafter — manual do estado atual e roteiro

**Snapshot:** 16 de outubro de 2026 — visibilidade de inimigos e drops  
**Engine:** Godot 4.7.2 · GDScript · renderer Compatibility  
**Escopo deste pacote:** projeto-fonte com assets; não é uma versão final nem um executável exportado.

## 1. Resumo executivo

ByteCrafter já tem um protótipo 3D voxel jogável, com exploração de terreno procedural, blocos editáveis, controles em primeira e terceira pessoa, sobrevivência básica, inventário/crafting, XP local e uma base de multiplayer ENet para LAN. O menu e o carregamento usam as artes enviadas; os quatro avatares estão selecionáveis e os modelos enviados de inimigos já entram no mundo.

Nesta cópia, `boy2/girl2` usam retarget por override global a partir de uma fonte Mixamo oculta, preservando a pose CC e o controle do `CharacterBody3D`. Slime, ET e zumbi são inimigos 3D distintos. XP por mineração/combate, barra de nível persistente e ícones do atlas na hotbar foram integrados. Ainda não se deve interpretar isso como sincronização de inimigos em LAN ou validação em hardware físico.

## 2. O que já está implementado

- **Mundo voxel:** terreno procedural por chunks, streaming ao redor do jogador, cavernas simples, árvores, seed reproduzível, mineração/colocação de blocos e persistência de seed/alterações.
- **Texturas voxel:** as faces laterais agora invertem o eixo V do UV, mantendo a faixa de grama no topo e terra embaixo no bloco de grama.
- **Controles e câmera:** movimento WASD, pulo, corrida, câmera com mouse, alternância de primeira/terceira pessoa por `V` e pausa por `Esc`.
- **Sobrevivência inicial:** vida, fome e respawn; criaturas passivas; ciclo de dia/noite; inventário, barra rápida e receitas iniciais de crafting.
- **Personagens:** rigs boy, girl, boy2 e girl2 selecionáveis, persistentes e sincronizados nas poses LAN. Boy2/girl2 recebem os clipes Mixamo por retarget de pose; idle ainda congela o primeiro quadro de caminhada.
- **Inimigos e XP:** slime 3D com squash/stretch, ET e zumbi com atributos/recompensas próprios, reação de morte e queda visual. Mineração e derrotas concedem XP; o perfil salva XP total e nível mantendo compatibilidade com o perfil v1.
- **Escala e chão dos inimigos:** ET e zumbi são normalizados para 1,8 m — o mesmo envelope vertical do jogador — e o slime para 0,9 m. Os colliders são recriados conforme o tipo, com base no plano do chão e gravidade/floor snap ativos.
- **Encontros:** inimigos agora surgem próximos ao ponto inicial, exibem placas `SLIME`, `ET` e `ZUMBI`, e o dano tem breve invulnerabilidade para evitar morte/respawn instantâneo sem feedback visual.
- **Drops:** itens usam raycast no cenário e descem suavemente até a primeira superfície sólida, respeitando blocos construídos/quebrados e permanecendo acima do chão efetivo.
- **HUD:** a hotbar usa recortes do atlas voxel, mostra o nome/quantidade do item selecionado e tooltip nos demais slots; o painel inclui nível e progresso de XP.
- **Menu/carregamento:** fundo de menu enviado pelo usuário; tela inicial com controles e opções de jogo; shell Web com a arte de loading, progresso, tratamento de erro/retry e duração mínima configurada de 3 segundos.
- **Perfil local:** guarda avatar, inventário, vida, fome, posição, seed e drops no arquivo `user://bytecrafter_player.json`; o mundo usa `user://bytecrafter_world.json`.
- **Multiplayer LAN:** interface nativa para hospedar/entrar, porta UDP `24567`, sincronização ENet de pose/avatar/estado de animação e de alterações de blocos. O Preview Web desativa a LAN.
- **Validação existente:** `npm run check` passou em 15/10/2026. O teste atual confirma o núcleo já conectado; não significa que as features abaixo já foram feitas.

## 3. Assets incluídos no ZIP

Além dos assets usados pelo protótipo (atlas/texturas voxel, artes de menu/loading, rigs boy/girl e clipes), a pasta `assets/models/` inclui os arquivos selecionados da segunda remessa:

| Recurso | Arquivos do projeto | Estado nesta cópia |
| --- | --- | --- |
| Boy 2 | `assets/models/players/boy2/` — FBX e texturas | Selecionável como `boy2`, com retarget CC validado |
| Girl 2 | `assets/models/players/girl2/` — FBX e texturas | Selecionável como `girl2`, com retarget CC validado |
| ET | `assets/models/enemies/et/` — FBX e texturas | Inimigo 3D hostil, recompensa fruta e XP |
| Zumbi | `assets/models/enemies/zombie/` — FBX e texturas | Inimigo 3D hostil, recompensa tronco e XP |
| Slime 3D | `assets/models/enemies/slime/` — FBX e `shaded.png` | Inimigo 3D com squash/stretch e recompensa gelatina |

O inventário completo e os nomes de origem estão em [`assets-enviados.md`](assets-enviados.md). O ZIP contém os assets que estão no diretório `assets/` deste projeto; não contém um executável nativo pronto.

## 4. Próxima implementação — prioridade imediata

1. **LAN para as novas features:** a autoridade de blocos encaminha XP de mineração ao ator; inimigos/recompensas de combate ainda são host-side e precisam de sincronização explícita antes de prometer cooperação completa.
2. **Combate e morte:** ligar o clipe de morte do jogador ao respawn e ampliar variações de comportamento/animação dos inimigos.
3. **Regressão e entrega:** testar host/cliente em dois dispositivos físicos, exportar uma build nativa e validar visualmente o pacote final.

## 5. Roteiro posterior

O alvo declarado pelo usuário é uma aventura craft/survival de mundo aberto tão rica quanto Minecraft até a era 1.18, ampliada gradualmente. Esse alvo é bem maior que o protótipo atual. Depois do corte imediato acima, as frentes recomendadas são:

- Expandir geração e exploração: biomas, cavernas mais variadas, estruturas, recursos e streaming/performance em mundos maiores.
- Completar sistemas de survival/crafting: receitas, ferramentas, armaduras, armazenamento, comida, progressão e interface de inventário.
- Expandir fauna, hostis, combate, drops e ciclos de comportamento; introduzir conteúdo em etapas.
- Evoluir construção e sistemas de jogo (por exemplo, agricultura, automação/redstone-like, aldeias/estruturas e novas áreas) conforme prioridade e capacidade técnica.
- Fortalecer salvamento por mundo, reconexão e autoridade/sincronização multiplayer, e testar duas builds nativas em dispositivos diferentes na mesma LAN.
- Fazer export Web/nativo e otimização com evidência de desempenho; a LAN atual é recurso nativo e não está disponível no Preview Web.
- Antes de distribuição pública, o usuário ainda precisa resolver licenças e obrigações dos assets/referências, conforme sua orientação original.

Os itens acima são um roteiro, não uma alegação de que Minecraft 1.18 ou todos os seus sistemas já estejam presentes.

## 6. Como abrir e testar

1. Extraia o ZIP em uma pasta local.
2. Abra `project.godot` no **Godot 4.7.2** e execute o projeto. Se necessário, abra `scenes/main.tscn` como cena principal.
3. Para o teste automatizado, com Node/npm e o runtime de jogo configurado, execute na raiz do projeto:

   ```bash
   npm run check
   ```

4. No jogo: `W/S` avançar/recuar, `A/D` deslocar, mouse olhar, `Espaço` pular, `Shift` correr, clique para minerar/colocar, `1–7` escolher bloco, `E` inventário/crafting, `V` alternar câmera e `Esc` pausar.
5. Para LAN, use uma build nativa. O anfitrião seleciona **Hospedar LAN**; o outro jogador digita o IP local do anfitrião e seleciona **Entrar**. Ambos precisam estar na mesma rede e permitir tráfego UDP na porta `24567`. O caminho LAN não funciona no Preview Web.

## 7. Limites da verificação deste snapshot

- `npm run check`: **passou** (`ok: true`) em 16/10/2026, cobrindo quatro avatares, retarget CC, os três tipos de inimigo, XP/persistência e ícones da hotbar.
- A correção de UV lateral também passou pelo mesmo `npm run check`; a confirmação visual local deve ser feita no Godot após extrair o ZIP.
- A correção de escala/collider passou pelo `npm run check` e por captura no renderer Compatibility; ainda é recomendável confirmar a sensação de distância no hardware local.
- A correção de proximidade/identificação dos inimigos, invulnerabilidade curta e acomodação dos drops passou pelo `npm run check`; LAN física continua não validada.
- Os testes anteriores verificaram as rotinas centrais do protótipo; o teste de rede documentado foi entre duas instâncias nativas em localhost, não em dois dispositivos físicos.
- A saída atual da verificação marca a cobertura visual como **incompleta** e lista os modelos FBX como recursos cuja textura interna não é inspecionada automaticamente. Isso não prova defeito, mas exige inspeção visual após a integração.
- Capturas no renderer Compatibility validaram escala/orientação/material dos quatro avatares, caminhada retargetada de boy2/girl2, HUD com ícones/XP e os modelos ET/zumbi. O teste LAN em dois dispositivos físicos, exportação final, sincronização de inimigos/recompensas em LAN e aceitação final do Preview Web continuam pendentes.

## 8. Conteúdo e exclusões do arquivo ZIP

O ZIP inclui fontes, cenas, documentação, configuração e a pasta `assets/` do projeto. Foram deixados de fora caches/imports temporários do Godot, `.git`, dependências locais (`node_modules`) e exports locais; o Godot os recria quando necessário. Para uma entrega executável, ainda será preciso exportar o projeto com os templates/plataformas desejados.
