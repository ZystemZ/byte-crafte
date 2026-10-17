# ByteCrafter 1.0 — Auditoria (Etapa Zero) e plano priorizado

Data: 2026-10-17 · Base auditada: commit `3f4d1cb` (branch `main`).
Backup integral do original: `byte-crafte-original-2026-10-17.tar.gz` (feito antes de qualquer edição, fora do repositório).

## 0. Limites desta auditoria (leia primeiro)

- **Godot 4.7.2 não estava disponível** no ambiente de trabalho (sem binário, sem acesso à página de releases). Portanto **nenhum teste foi executado**: nem `test/test_suite.tscn`, nem verificação visual, nem desempenho, nem LAN. Tudo abaixo vem de **leitura estática do código**; as alterações feitas **não foram compiladas nem rodadas**.
- Antes de aceitar este commit: abrir o projeto no Godot 4.7.2 e executar `test/test_suite.tscn` (ver seção 5).

## 1. Inventário técnico (estado real, por leitura de código)

| Sistema | Estado | Evidência / observação |
|---|---|---|
| Geração procedural (seed, biomas, árvores, estruturas simples) | Completo, básico | `voxel_world.gd`: 5 biomas por ruído, blocos 0–13, sem água, sem minérios, sem cavernas além de ruído 3D simples |
| Malha/colisão por chunk | Funcional, com defeitos (ver §2) | Trimesh por chunk + caixas para troncos |
| Streaming | Funcional | raio 2, 1 chunk/frame, chunk central síncrono |
| Salvamento (mundo/perfil) | Parcial-bom | JSON, `.tmp` + `.bak`; mesas de craft, baús e plantações **não** são restauradas |
| Jogador | Funcional | Velocidade instantânea; usa `Input.is_key_pressed`; só ações `move_*` no InputMap |
| Interação (mineração/colocação/raycast) | Funcional | Mineração por `_mine_held`; colocação valida sobreposição com o jogador |
| Inventário | **Agregado (Dictionary)**, não por slots | Hotbar de 9 entradas fixas em `QUICKBAR_IDS` |
| Crafting | Parcial | Grade no menu E sem exigir bancada; `station` declarado nas receitas e **não aplicado** |
| Bancada | Parcial | Objeto físico com colisão (tecla T), mas não persistida, posição não alinhada à grade, E funciona sem bancada |
| Ferramentas/durabilidade | Parcial | Velocidade por ferramenta presente; durabilidade não implementada |
| Combate/inimigos/animais | Parcial | Máquinas de estado básicas; inimigos/XP não sincronizados em LAN |
| Agricultura | Parcial | Plantio/colheita (tecla P); `_restore_profile_crops` existe e **nunca é chamada** |
| Água, luz de blocos, cavernas, minérios | Inexistentes | — |
| Dia/noite | Parcial | Presente; regras de spawn/iluminação artificial a validar |
| LAN (ENet) | Experimental | `request_world_block` rejeita ids > 7 → blocos de bioma (8–13) não podem ser minerados/colocados em rede |
| Herança de template 2D (maze/runner/tuning px/s) | Resíduo | Convive com o jogo 3D; `scripts/main.gd` referencia ação `pause` inexistente |

## 2. Defeitos confirmados por leitura (P0)

1. **Troca de chunk com janela de colisão duplicada/ausente** — `_build_chunk` liberava o corpo antigo (`queue_free`, adiado) antes de o novo existir. → **Corrigido** (corpo novo montado primeiro; antigo removido da árvore imediatamente; falha de colisão mantém o corpo anterior em vez de abrir buraco).
2. **Custo de reconstrução** — ~73 mil chamadas a `get_block_at` por chunk (cada uma com ruído 2D/3D) a cada geração **e a cada bloco minerado**. → **Mitigado** com snapshot único de 18×42×18 células (≈13,6 mil chamadas), sem trocar o motor. *Ganho não medido (sem Godot).*
3. **Copas substituindo terreno sólido** em encostas (prioridade de `_tree_blocks` sobre o terreno). → **Corrigido** (folha só ocupa células de ar).
4. **Hotbar tem 9 slots mas as teclas só alcançavam 1–7.** → **Corrigido** (1–9).
5. **F só atacava**; sem interação contextual. → **Corrigido**: ataca se houver alvo; senão abre o crafting se houver mesa a ≤3,2 m.
6. **Movimento com velocidade instantânea.** → **Corrigido**: aceleração/desaceleração no chão e controle reduzido no ar.

## 3. Defeitos conhecidos ainda NÃO corrigidos (por prioridade)

- **P0** Inventário por slots transacional (arrastar/dividir/combinar, baús) — não iniciado.
- **P0** Crafting 2×2 / 3×3 com bancada obrigatória; persistir mesas; alinhar à grade.
- **P0** Itens fantasmas: receitas usam `"ferro"` e `"carne_cozida"`; verificar presença em `_inventory_item_ids`/inventário padrão e nos drops.
- **P0** `_restore_profile_crops` nunca chamada → plantações somem ao recarregar.
- **P1** Ação `pause` ausente no InputMap (`main.gd`); migrar teclas para InputMap.
- **P1** `request_world_block` limitado a ids ≤ 7 (LAN).
- **P1** Durabilidade de ferramentas, fornalha, baús, água, minérios/cavernas/estruturas, combate/animações, áudio, conquistas, chefe final, LAN entre dispositivos.
- **P2** `tools/verify_exported_pack.gd` com premissas possivelmente defasadas (ex.: número de criaturas 3 vs 5 na suíte).

## 4. Arquivos modificados neste commit

- `scripts/game/voxel_world.gd` — snapshot, troca de chunk sem lacuna, copas sem sobrescrever terreno.
- `scripts/game/bytecrafter.gd` — teclas 1–9, `_interact_contextual()` (F).
- `scripts/game/bytecrafter_player.gd` — aceleração/desaceleração.
- `test/test_suite.gd` — novos testes: `_test_voxel_integrity()` (malha == faces implícitas nos dados de bloco, colisão == malha, colisores de tronco, ausência de corpos obsoletos, copas × terreno, edição na borda de chunk) e verificação das teclas 1–9 e do F sem alvo.
- `docs/AUDITORIA_BYTECRAFTER_1.0.md` — este relatório.

## 5. Como validar (pendente)

1. Abrir o projeto no Godot 4.7.2.
2. Executar `test/test_suite.tscn` (`godot --headless --path . res://test/test_suite.tscn`); esperado: `[bytecrafter-tests] PASS`. O número de checks passará dos 147 documentados.
3. Jogar: cruzar bordas de chunk, minerar/recolocar na borda, subir em troncos, pular sobre copas, teclas 1–9 e F perto de uma mesa.
4. Medir tempo de `_build_chunk` antes/depois (profiler) para confirmar o ganho do snapshot.

## 6. Plano seguinte (ordem do Prompt Mestre)

Etapa 3 (restante): InputMap completo e indicador visual de alvo → Etapa 4: inventário por slots + crafting com estações + persistência de bancadas/baús → Etapa 5: durabilidade/progressão → 6: sobrevivência/combate → 7: água/biomas/cavernas/estruturas → 8–12 conforme o prompt. Nenhuma etapa será marcada como concluída sem execução real dos testes.
