# ByteCrafter — auditoria técnica inicial e registro de execução

**Data:** 17/10/2026  
**Projeto-base:** ZIP recebido nesta conversa  
**Engine declarada:** Godot 4.7.2, GDScript, renderer Compatibility  
**Etapa:** 0 — auditoria estática + primeira correção de integridade de save

## 1. Integridade do pacote e escopo

- Foi criado um backup integral do ZIP original antes de qualquer alteração: `ByteCrafter_backup_original_2026-10-17.zip`.
- A auditoria cobre os arquivos de entrada indicados no prompt, o manual do estado atual, o TODO, o catálogo de receitas, o mundo voxel, jogador, perfil e suíte de testes.
- Esta entrega é uma consolidação inicial, não uma declaração de que ByteCrafter 1.0 está pronto.
- O ambiente de trabalho desta sessão não possui executável `godot`/`godot4` disponível no PATH. Portanto, não foi possível compilar/importar cenas, executar a suíte GDScript, abrir o jogo ou realizar testes visuais/físicos nesta sessão. Isso está explicitamente separado de verificações estáticas.

## 2. Inventário técnico observado

### Mundo voxel (`scripts/game/voxel_world.gd`)

**Já implementado no código:**
- Geração procedural por seed e chunks com streaming.
- Consulta centralizada de voxels via `get_block_at`, incluindo overrides, árvores, estruturas e terreno-base.
- Mineração/colocação via `set_block_at`.
- Reconstrução do chunk alterado e vizinhos quando a alteração está na borda.
- Malha visual por faces expostas e geração de colisão trimesh por chunk.
- Colisores de caixa adicionais para troncos.
- Persistência do seed e overrides em arquivo temporário com backup/rollback.
- A malha percorre a altura de jogo completa para incluir copas que excedam a altura local do terreno.

**Riscos e pontos que ainda precisam de validação real:**
- A construção de malha e colisão percorre todo o volume vertical de cada coluna; o custo precisa ser medido antes de mexer na arquitetura.
- A substituição de chunks usa `queue_free()` no corpo anterior antes de o novo corpo entrar na árvore. A atualização é diferida pelo Godot; é necessário teste físico dirigido para confirmar que isso não cria uma janela perceptível sem colisão.
- A colisão de folhas é derivada da malha trimesh geral. Isso torna o comportamento dependente das faces geradas; é necessário testar copas, mineração de folhas e bordas de chunks em build nativa.
- O algoritmo de bordas deve ser testado nas quatro direções e em coordenadas negativas, inclusive quando uma estrutura/árvore atravessa a fronteira.
- A existência de testes de dados/colisão não substitui a sessão manual de caminhada, pulo, queda e aterrissagem.

### Jogador e interação (`scripts/game/bytecrafter_player.gd`, `scripts/game/bytecrafter.gd`)

**Já implementado no código:**
- `CharacterBody3D`, movimento, pulo, corrida e controle de câmera.
- Alternância entre primeira e terceira pessoa por `V`.
- Raycast para seleção de alvos, indicação visual de bloco e prévia de colocação.
- Inventário agregado por identificador e quantidade, hotbar visual, grade de crafting e receitas.
- Vida, fome, XP/nível, drops, cultivo básico, ciclo dia/noite e inimigos.
- Perfil do jogador com arquivo temporário e backup/rollback.
- Base ENet para hospedar/entrar, sincronizar poses de jogadores e encaminhar alterações de blocos.

**Diferenças em relação à meta do prompt:**
- O inventário principal ainda é um `Dictionary` agregado por item; a interface de slots não equivale a um inventário de slots persistidos com pilhas independentes. Arrastar e soltar ainda é voltado principalmente à grade de crafting, e não cobre integralmente mover/dividir/metade/combinar pilhas entre inventário, hotbar, baús e estações.
- A grade de crafting é persistida como identificadores individuais, mas o sistema ainda não representa todas as regras de estação/receita como uma transação unificada de slots.
- A lista de receitas existente é útil e centralizada, mas não cobre toda a progressão pedida (por exemplo, há receitas que usam fogueira/mesa de craft, enquanto a validação de proximidade/estação precisa ser confirmada por testes).
- A entrada atual documentada usa `G` para mineração contínua, `F` para ataque contextual, `E` para crafting, `T` para colocar bancada, `P` para agricultura, `V` para câmera, `Esc` para pausa/fechar e `1`–`7` para seleção direta. O prompt propõe outras convenções; elas não devem ser remapeadas sem conferir conflitos e atualizar a ajuda da interface.
- O multiplayer documentado não sincroniza ainda o conjunto completo de inimigos, dano, drops e recompensas entre clientes. Não está validado em dois dispositivos físicos.

### Saves (`autoload/save_store.gd`, mundo e perfil)

O save do mundo e o perfil do jogador já usam arquivo temporário e tentativa de backup/rollback. O `SaveStore` global, porém, removia o arquivo primário antes de renomear o temporário e não tentava recuperar um backup após interrupção. Isso criava risco evitável de perder o arquivo anterior caso a substituição falhasse.

**Correção aplicada nesta entrega:** `SaveStore` agora preserva o arquivo anterior em `.bak` durante a troca, restaura-o em falha de commit e tenta carregar o backup válido se o arquivo primário estiver ausente ou inválido. O formato de dados e as versões aceitas (v1/v2) foram mantidos. A correção foi revisada estaticamente; ainda precisa ser exercitada no Godot com testes de interrupção/falha de arquivo.

### Testes e documentação

- Existe `test/test_suite.tscn` e uma suíte extensa em `test/test_suite.gd`, incluindo receitas, seed, voxels, colisões e um loop jogável.
- Existe `test/tuning_bridge_contract.gd` para o contrato de tuning.
- `docs/manual-estado-atual.md` e `TODO.md` registram que o projeto ainda é um protótipo e que LAN, conteúdo e sistemas completos estão em andamento.
- O `TODO.md` continua amplo e não é uma lista de aceitação suficiente para lançamento; deve ser complementado por critérios verificáveis por etapa.

## 3. Prioridades recomendadas

### P0 — antes de ampliar conteúdo
1. Executar a suíte atual em Godot 4.7.2 e registrar saída completa.
2. Criar testes dirigidos para colisão de folhas, árvores nas bordas, coordenadas negativas, atualização de colisão após quebrar/recolocar, spawn seguro e streaming sobre o jogador.
3. Fazer testes de save: arquivo válido, arquivo primário inválido com backup válido, arquivo ausente, falha de escrita e preservação byte a byte do último save bom.
4. Confirmar que o jogador não pode colocar blocos dentro do próprio collider e que a prévia coincide com o voxel efetivamente colocado.
5. Medir tempo de reconstrução de chunk e colisão antes de otimizar. Não reescrever o gerador sem evidência.
6. Documentar e testar todos os controles atuais antes de alterar mapeamentos.

### P1 — ciclo de jogo consistente
1. Migrar o inventário agregado para slots reais com operações transacionais e migração de perfil.
2. Centralizar definições de itens, limites de pilha, ferramentas, durabilidade e receitas.
3. Validar estações por proximidade e estado real do mundo; não aceitar receitas apenas pela interface.
4. Completar armazenamento/baús/fornalha e salvar o conteúdo de cada recipiente.
5. Fechar lacunas de combate, drops, IA e persistência.
6. Definir protocolo de autoridade do host e sincronização multiplayer de entidades e recompensas.

### P2 — conteúdo, polimento e lançamento
1. Biomas/água/estruturas com geração determinística.
2. Progressão e objetivo final.
3. Áudio, feedback, menus, acessibilidade e opções gráficas.
4. Perfil de desempenho medido em hardware especificado.
5. Sessão nativa de 30 minutos, multiplayer LAN entre dispositivos físicos e exportação Windows limpa.

## 4. Arquivos alterados nesta etapa

- `autoload/save_store.gd`
  - adicionada recuperação por backup;
  - substituição do save passa a manter backup até o commit do temporário;
  - rollback em falha de commit;
  - mantidas as versões de dados existentes.
- `docs/RELATORIO_AUDITORIA_2026-10-17.md`
  - relatório desta auditoria, riscos e prioridades.

## 5. Validação executada nesta sessão

| Verificação | Resultado |
|---|---|
| ZIP de entrada abriu e foi listado | Aprovado |
| Backup integral criado antes de alterar arquivos | Aprovado |
| Arquivos de referência encontrados | Aprovado |
| Revisão estática de mundo, jogador, crafting, saves e testes | Concluída |
| Godot 4.7.2 disponível no PATH | Não disponível |
| `npm run check` | Não executado: wrapper exige `GAME_RUNTIME` (runtime do jogo não configurado nesta sessão) |
| Execução da suíte GDScript | Não executada: falta executável Godot |
| Teste visual/físico do terreno e colisões | Não executado |
| Sessão nativa de 30 minutos | Não executada |
| Teste LAN em dois dispositivos físicos | Não executado |
| Perfil de desempenho com hardware identificado | Não executado |

**Conclusão:** o pacote contém uma base jogável e recursos reaproveitáveis. O próximo passo correto é executar e fortalecer os testes P0 no Godot 4.7.2, corrigindo os defeitos demonstrados antes de expandir conteúdo. A única correção de código nesta etapa é a proteção adicional do save global; ela não é declarada testada em runtime nesta sessão.
