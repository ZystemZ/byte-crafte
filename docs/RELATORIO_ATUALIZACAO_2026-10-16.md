# ByteCrafter — relatório da atualização de fontes

Data: 16/10/2026
Versão do projeto: 0.2.0
Base: `ByteCrafter_combate_controles_corrigidos.zip`

## Correções aplicadas

1. **Loop de jogo:** a rotina de jogo estava indentada dentro da condição que remove a tela inicial. Como a condição só é verdadeira uma vez, a lógica de simulação deixava de rodar depois da remoção do loading. O loop foi reorganizado para continuar executando a cada frame.
2. **Streaming/terreno:** cache limitado de altura por coordenada foi adicionado e é limpo quando o jogador troca de chunk central. O streaming continua gerando no máximo um chunk por frame.
3. **Persistência:** leitura de overrides do mundo com validação e limite de 250.000 registros; validação de inventário/posição do perfil e limite de drops restaurados; saves de mundo/perfil gravados em temporário e promovidos com backup do arquivo anterior.
4. **Crafting/inventário:** mensagens de retorno de crafting e limites máximos para pilhas coletadas.

## Verificações realizadas nesta sessão

- Integridade do ZIP original e extração dos arquivos.
- Conferência de referências `res://` em scripts/cenas/recursos: nenhuma referência ausente encontrada.
- Revisão estática das regiões alteradas e presença da cena principal.
- Não foi possível executar o projeto nem o `test/test_suite.tscn`, pois o executável Godot não estava instalado/disponível neste ambiente.

## Testes manuais recomendados no Godot 4.7.2

1. Importar `project.godot` e executar com F5.
2. Entrar no mundo e aguardar mais de 3 segundos; confirmar que o personagem continua se movendo, a câmera responde, o ciclo dia/noite avança e a mineração funciona.
3. Quebrar e colocar blocos perto da borda de chunks e caminhar em várias direções.
4. Abrir crafting com E; criar tábuas, gravetos e picareta; tentar receitas sem recursos e confirmar a mensagem.
5. Salvar com F5, fechar e abrir novamente; confirmar terreno, inventário, posição e drops.
6. Forçar fechamento durante o jogo apenas em cópia de teste e confirmar que o save anterior não é sobrescrito por um arquivo parcial.
7. Executar a suíte existente `test/test_suite.tscn` e testar LAN em dois computadores físicos.

## Limitações conhecidas

Esta atualização não adiciona ainda o conjunto completo de biomas, receitas, equipamentos, estruturas, IA, redstone/mecanismos ou conteúdo equivalente ao Minecraft 1.18. Também não declara multiplayer validado em dispositivos físicos. A auditoria de licenças dos assets permanece pendente, conforme indicado no README original.
