

## Etapa P0 iniciada — confiabilidade voxel

Foi criado backup integral em `/home/ubuntu/ByteCrafter_work_backup_p0_20261016` antes desta etapa. A auditoria atual confirmou que cada chunk carregado cria um `ChunkCollision` com `ConcavePolygonShape3D` não vazio, que o chunk central é construído imediatamente e que a reconstrução nas bordas recompõe os dois chunks adjacentes após minerar um voxel de fronteira. Foram adicionadas regressões para essas condições; a suíte passou em **147 verificações**.

Ainda falta uma sessão prolongada em hardware físico para validar visualmente atravessamento de terreno, desempenho e comportamento de câmera em diferentes resoluções. Essa validação permanece explicitamente pendente.

## Interação P0 — colocação segura

A validação de colocação deixou de usar apenas distância até o centro do jogador. Agora consulta o espaço físico e usa as dimensões reais da cápsula `PlayerCollider` como fallback conservador. O preview e a ação definitiva compartilham a mesma regra, evitando colocar blocos dentro do corpo do jogador. A suíte passou em **147 verificações**.

## Correção de regressões — árvores, folhas e zumbi

Foi identificada uma regressão introduzida ao ajustar os assets: o rig Mixamo do zumbi estava orientado no eixo vertical incorreto. O modelo aparentava estar enorme/largo e o collider não correspondia à silhueta. O rig agora é rotacionado para o eixo vertical correto e normalizado para **1,80 unidade**, igual ao jogador. O ET usa a mesma orientação e escala; o alcance do zumbi foi reduzido para 1,05 unidade e o dano exige linha de visão livre até o jogador.

Troncos e folhas permanecem quebráveis sem ferramenta. A transparência lateral das folhas foi restaurada; faces superior e inferior usam um tile opaco de tampa, evitando enxergar o terreno profundo através de uma copa sem transformar toda a folha em bloco opaco. A suíte passou em **147 verificações**.
