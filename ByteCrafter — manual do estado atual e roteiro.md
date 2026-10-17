# ByteCrafter — manual do estado atual e roteiro

**Snapshot:** 15 de outubro de 2026  
**Engine:** Godot 4.7.2 · GDScript · renderer Compatibility  
**Escopo deste pacote:** projeto-fonte com assets; não é uma versão final nem um executável exportado.

## 1. Resumo executivo

ByteCrafter já tem um protótipo 3D voxel jogável, com exploração de terreno procedural, blocos editáveis, controles em primeira e terceira pessoa, sobrevivência básica, inventário/crafting e uma base de multiplayer ENet para LAN. O menu e o carregamento usam as artes enviadas, e os rigs originais boy/girl já estão conectados aos clipes existentes.

A segunda remessa de modelos foi copiada para a pasta de assets do projeto. **Os novos personagens boy2/girl2, os monstros ET/zumbi, o slime 3D, o sistema de XP e os novos ícones ainda não estão integrados à jogabilidade nesta cópia.** O jogo ainda usa o slime 2D e o conjunto anterior de opções de personagem. As tarefas a seguir são o próximo corte de implementação, não recursos concluídos.

## 2. O que já está implementado

- **Mundo voxel:** terreno procedural por chunks, streaming ao redor do jogador, cavernas simples, árvores, seed reproduzível, mineração/colocação de blocos e persistência de seed/alterações.
- **Controles e câmera:** movimento WASD, pulo, corrida, câmera com mouse, alternância de primeira/terceira pessoa por `V` e pausa por `Esc`.
- **Sobrevivência inicial:** vida, fome e respawn; criaturas passivas; ciclo de dia/noite; inventário, barra rápida e receitas iniciais de crafting.
- **Personagens existentes:** rigs boy/girl selecionáveis e clipes de caminhada, corrida, salto, mineração e ataque. Idle é provisoriamente o primeiro quadro de caminhada; a animação de morte ainda não está ligada ao respawn.
- **Menu/carregamento:** fundo de menu enviado pelo usuário; tela inicial com controles e opções de jogo; shell Web com a arte de loading, progresso, tratamento de erro/retry e duração mínima configurada de 3 segundos.
- **Perfil local:** guarda avatar, inventário, vida, fome, posição, seed e drops no arquivo `user://bytecrafter_player.json`; o mundo usa `user://bytecrafter_world.json`.
- **Multiplayer LAN:** interface nativa para hospedar/entrar, porta UDP `24567`, sincronização ENet de pose/avatar/estado de animação e de alterações de blocos. O Preview Web desativa a LAN.
- **Validação existente:** `npm run check` passou em 15/10/2026. O teste atual confirma o núcleo já conectado; não significa que as features abaixo já foram feitas.

## 3. Assets incluídos no ZIP

Além dos assets usados pelo protótipo (atlas/texturas voxel, artes de menu/loading, rigs boy/girl e clipes), a pasta `assets/models/` inclui os arquivos selecionados da segunda remessa:

| Recurso | Arquivos do projeto | Estado nesta cópia |
| --- | --- | --- |
| Boy 2 | `assets/models/players/boy2/` — FBX e texturas | Copiado; ainda não aparece no seletor nem no jogo |
| Girl 2 | `assets/models/players/girl2/` — FBX e texturas | Copiado; ainda não aparece no seletor nem no jogo |
| ET | `assets/models/enemies/et/` — FBX e texturas | Copiado; ainda não instanciado como inimigo |
| Zumbi | `assets/models/enemies/zombie/` — FBX e texturas | Copiado; ainda não instanciado como inimigo |
| Slime 3D | `assets/models/enemies/slime/` — FBX e `shaded.png` | Copiado; ainda não substitui o sprite 2D |

O inventário completo e os nomes de origem estão em [`assets-enviados.md`](assets-enviados.md). O ZIP contém os assets que estão no diretório `assets/` deste projeto; não contém um executável nativo pronto.

## 4. Próxima implementação — prioridade imediata

1. **Rigs boy2/girl2:** adicionar os dois ao seletor, persistência do perfil e sincronização de avatar remota. Validar a hierarquia, materiais, escala e retarget dos clipes para os nomes de ossos CC; não presumir compatibilidade só porque os arquivos foram copiados.
2. **Monstros:** trocar o slime de sprite 2D para a malha FBX, com squash/stretch procedural. Instanciar ET e zumbi rigados como hostis, conectando navegação simples/perseguição, ataque, dano, animação de morte e recompensas.
3. **XP e níveis:** definir a progressão; conceder XP de mineração e por inimigo derrotado; exibir nível, barra e progresso do próximo nível; salvar XP/nível no perfil existente, mantendo compatibilidade com arquivos antigos sem esses campos.
4. **LAN para as novas features:** encaminhar os valores de XP de modo consistente para cada jogador e validar que derrotas/recompensas de inimigos não se dupliquem. Hoje poses e blocos sincronizam, mas a nova progressão e os novos inimigos ainda não estão sincronizados.
5. **HUD:** substituir swatches de cor da hotbar por recortes identificáveis do atlas, mostrar o nome do item selecionado e manter quantidades/atalhos legíveis.
6. **Regressão:** ampliar a suíte existente para cobrir os quatro avatares, os três tipos de inimigo, cálculo/ganho/salvamento de XP e ícones; rodar `npm run check` e conferir ao menos uma captura nativa com renderer real.

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

- `npm run check`: **passou** (`ok: true`).
- Os testes anteriores verificaram as rotinas centrais do protótipo; o teste de rede documentado foi entre duas instâncias nativas em localhost, não em dois dispositivos físicos.
- A saída atual da verificação marca a cobertura visual como **incompleta** e lista os modelos FBX como recursos cuja textura interna não é inspecionada automaticamente. Isso não prova defeito, mas exige inspeção visual após a integração.
- Não foram executados nesta etapa teste de exportação final, teste LAN em rede física, integração de XP, integração dos novos rigs/inimigos nem aceitação final do Preview Web.

## 8. Conteúdo e exclusões do arquivo ZIP

O ZIP inclui fontes, cenas, documentação, configuração e a pasta `assets/` do projeto. Foram deixados de fora caches/imports temporários do Godot, `.git`, dependências locais (`node_modules`) e exports locais; o Godot os recria quando necessário. Para uma entrega executável, ainda será preciso exportar o projeto com os templates/plataformas desejados.
