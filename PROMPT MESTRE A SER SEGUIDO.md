# BYTECRAFTER — PLANO MESTRE DE CORREÇÃO, DESENVOLVIMENTO E POLIMENTO

## 1. OBJETIVO GERAL

Você será o programador responsável por dar continuidade ao ByteCrafter, um jogo sandbox voxel 3D de mundo aberto, exploração, construção, crafting e sobrevivência, desenvolvido em Godot 4.7.

O objetivo é transformar o projeto atual em um jogo realmente funcional, divertido, visualmente atraente, com controles responsivos, animações, progressão e uma experiência de jogo completa.

O projeto já possui fontes, cenas, recursos e sistemas iniciais. NÃO crie outro jogo do zero. Trabalhe sobre os arquivos existentes, aproveitando tudo o que estiver funcionando.

A referência de experiência é Minecraft, mas o ByteCrafter deve desenvolver identidade visual própria, interface original, itens personalizados, biomas interessantes e efeitos modernos.

**Motor obrigatório:** Godot 4.7.

**Linguagem principal:** GDScript, mantendo C# somente se já existir uma dependência real dele no projeto.

**Plataforma prioritária:** Windows PC.

**Estilo:** sandbox voxel 3D, com possibilidade de jogar em primeira e terceira pessoa, se os sistemas existentes permitirem.

## 2. REGRAS OBRIGATÓRIAS

1. Faça uma cópia de segurança do projeto original antes de modificar qualquer arquivo.
2. Analise o projeto real antes de começar a programar.
3. Não presuma que uma funcionalidade funciona apenas porque existe um script ou botão.
4. Preserve as cenas, texturas, modelos, sons, configurações, controles e sistemas que já funcionam.
5. Não apague arquivos ou recursos sem comprovar que são desnecessários.
6. Não substitua sistemas completos por protótipos visuais, dados falsos ou funções vazias.
7. Não use pseudocódigo. Implemente código funcional e compatível com Godot 4.7.
8. Evite adicionar plugins e dependências desnecessárias.
9. Não altere indiscriminadamente arquivos de configuração, identificadores de recursos, caminhos `res://` ou UIDs.
10. Não entregue apenas exemplos de código ou instruções. Modifique o projeto, teste-o e entregue os fontes atualizados em ZIP.
11. Não declare testes como aprovados se não foram realmente executados.
12. Trabalhe em etapas, mantendo o projeto executável ao final de cada etapa.

## 3. FASE ZERO — AUDITORIA E CORREÇÃO DOS ERROS EXISTENTES

Antes de desenvolver funcionalidades novas, faça uma auditoria completa.

### 3.1. Importação do Godot

O projeto apresentou anteriormente 221 arquivos com falhas de importação. O editor utilizado é Godot 4.7.

Investigue a causa real desses erros.

- Abra e valide o arquivo `project.godot`.
- Verifique os caminhos e UIDs dos recursos.
- Identifique texturas, modelos, materiais, fontes, sons e outros recursos com problemas.
- Verifique os arquivos `.import` e os metadados gerados pelo editor.
- Identifique incompatibilidades de importação e configurações inválidas.
- Verifique recursos ausentes, arquivos corrompidos e referências quebradas.
- Execute uma reimportação limpa em uma cópia do projeto.
- Corrija os erros sem apagar recursos válidos para simplesmente reduzir o número de mensagens.

Produza um relatório com a quantidade de erros encontrados, as causas identificadas e as correções realizadas.

### 3.2. Scripts e cenas

Revise os scripts GDScript e as cenas principais.

Procure por:
- Erros de sintaxe e incompatibilidades com Godot 4.7.
- Referências a nós inexistentes.
- Sinais desconectados ou conectados incorretamente.
- Funções não implementadas.
- Erros de tipos e variáveis nulas.
- Conflitos entre interface, entrada do jogador e pausa.
- Erros de colisão e física.
- Problemas no carregamento e descarregamento dos chunks.
- Falhas no inventário, crafting, sobrevivência e salvamento.

Execute a cena principal com F5 e resolva os erros críticos antes de continuar.

## 4. FASE 1 — FUNDAMENTOS DO GAMEPLAY

O jogador deve conseguir iniciar uma partida e jogar sem depender do editor para executar operações normais.

### 4.1. Controles

Implemente ou corrija:

- WASD: movimentação.
- Mouse: câmera.
- Espaço: pular.
- Shift: correr.
- Botão esquerdo: atacar ou minerar.
- Botão direito: colocar bloco ou utilizar item.
- E: abrir inventário.
- Esc: fechar menus e abrir pausa, conforme o contexto.
- Teclas 1 a 9: selecionar a barra rápida.
- Roda do mouse: alternar item selecionado.
- F: utilizar ou interagir, se esse controle não estiver em conflito com outro sistema.

O cursor deve ser liberado nos menus e capturado ao retornar à jogabilidade. Não permita que os controles de movimentação acionem botões da interface ou que o personagem continue andando enquanto um menu modal estiver aberto.

### 4.2. Movimentação e câmera

- Corrigir colisões com o terreno e objetos.
- Impedir que o personagem atravesse blocos.
- Corrigir saltos, gravidade e detecção de chão.
- Melhorar a aceleração e desaceleração.
- Implementar câmera suave, sem tremores ou movimentos bruscos.
- Corrigir a câmera de terceira pessoa para evitar atravessar paredes.
- Evitar que a câmera fique presa em geometria.
- Sincronizar corretamente o corpo do personagem e a direção do movimento.

### 4.3. Mineração e construção

O jogador precisa conseguir:

- Mirar em um bloco usando raycast.
- Visualizar qual bloco está selecionado.
- Quebrar o bloco com tempo de mineração apropriado.
- Receber o recurso correto ao quebrá-lo.
- Colocar blocos na posição adjacente correta.
- Impedir colocações inválidas.
- Não colocar blocos dentro do corpo do jogador.
- Atualizar colisões e malhas após alterações.
- Exibir efeitos visuais e sonoros de quebra e colocação.
- Preservar as alterações quando o mundo for salvo.

Implemente ferramentas com velocidades diferentes, caso a arquitetura existente permita.

## 5. FASE 2 — MUNDO PROCEDURAL E DESEMPENHO

O mundo precisa ser explorável e consistente.

### 5.1. Chunks

- Verifique a geração procedural e o algoritmo de terreno existente.
- Carregue e descarregue chunks conforme a posição do jogador.
- Evite gerar o mesmo chunk repetidamente.
- Não bloqueie a thread principal com operações pesadas.
- Utilize geração assíncrona quando for seguro.
- Evite colisões e malhas desnecessárias.
- Reconstrua apenas os chunks afetados por mudanças.
- Corrija as bordas entre chunks para evitar fendas.
- Preserve alterações feitas pelo jogador.
- Permita configurar a distância de renderização.

### 5.2. Otimização

- Use malhas combinadas por chunk quando compatível com a arquitetura.
- Elimine faces internas desnecessárias.
- Evite criar um nó independente para cada bloco quando isso prejudicar o desempenho.
- Controle a quantidade de entidades e partículas.
- Libere recursos que deixaram de ser utilizados.
- Utilize cache com limites de memória.
- Meça FPS, tempo de geração e consumo de memória.

Não faça uma reescrita completa do sistema de chunks sem comparar a implementação existente e comprovar que a nova solução é melhor.

### 5.3. Biomas e exploração

Melhore progressivamente o mundo com:

- Planícies e florestas.
- Praias, rios e lagos.
- Montanhas e regiões rochosas.
- Cavernas e depósitos minerais.
- Árvores e vegetação variadas.
- Diferentes tipos de solo.
- Variações de altura e distribuição de recursos.
- Estruturas naturais e pontos de interesse.

As regiões devem ser determinadas pela seed e permanecer consistentes quando o jogador retornar.

## 6. FASE 3 — INVENTÁRIO E CRAFTING COMPLETOS

Esta fase é prioritária e deve transformar o menu de itens em um sistema real, inspirado na experiência de Minecraft.

### 6.1. Interface do inventário

Ao pressionar E, abra uma interface centralizada, com fundo escurecido e visual voxel próprio.

A interface deve apresentar:

- Modelo animado do personagem.
- Slots de armadura, caso implementados.
- Grade principal de inventário.
- Barra rápida com nove slots.
- Quantidades de itens.
- Destaque do item selecionado.
- Descrição e nome do item.
- Área de crafting.
- Resultado da receita.
- Botão para pegar metade de uma pilha, quando aplicável.
- Botão para dividir e distribuir itens.
- Tooltips com informações do item.

A interface deve manter o estilo visual do ByteCrafter, com painéis bem organizados, bordas, ícones legíveis, animações discretas e bom contraste.

Não utilize emojis como substitutos definitivos das imagens dos itens. Utilize as texturas e modelos existentes ou crie ícones consistentes com o estilo do jogo.

### 6.2. Mesa de crafting integrada ao inventário

Ao abrir o inventário, o jogador deve visualizar uma área de crafting com grade 2×2, semelhante à interface básica de Minecraft.

A área deve apresentar:

- Quatro células de entrada.
- Um indicador visual de resultado.
- Uma seta ou animação de processamento.
- Um botão ou slot de saída.
- Atualização imediata das receitas conforme os itens colocados.

A mesa de crafting colocada no mundo deve abrir uma interface específica com grade 3×3, permitindo receitas maiores.

A interface de crafting deve funcionar de verdade: os itens colocados nas células precisam corresponder aos ingredientes das receitas, e não apenas preencher uma representação visual.

### 6.3. Manipulação de itens

Implemente:

- Arrastar e soltar itens.
- Pegar uma pilha inteira.
- Pegar metade da pilha.
- Distribuir itens entre slots.
- Combinar pilhas do mesmo item.
- Respeitar o limite de cada pilha.
- Trocar itens entre slots.
- Retornar o item ao inventário quando uma operação for cancelada.
- Impedir perda ou duplicação de itens.
- Permitir mover itens entre inventário e barra rápida.

Quando o inventário fechar, os itens não podem desaparecer. Se ainda houver um item na mão do cursor, ele deve retornar a um slot válido.

### 6.4. Sistema de receitas

Crie um sistema centralizado de receitas, evitando espalhar regras de crafting pela interface.

Cada receita deve definir:

- Identificador.
- Ingredientes.
- Quantidades.
- Disposição dos ingredientes, quando relevante.
- Item produzido.
- Quantidade produzida.
- Estação de trabalho necessária.
- Requisitos adicionais, se existirem.

Implemente receitas iniciais:

- Tronco para tábuas.
- Tábuas para gravetos.
- Tábuas para bancada de crafting.
- Gravetos e tábuas para ferramentas de madeira.
- Ferramentas de pedra.
- Tochas.
- Baús.
- Fornalha.
- Ferramentas metálicas, se os materiais necessários já existirem.

A lista é um conjunto mínimo. Adapte as receitas ao catálogo real de itens do projeto.

### 6.5. Consumo correto dos ingredientes

Ao clicar no resultado:

1. Verifique se a receita é válida.
2. Confirme se o jogador possui os ingredientes.
3. Verifique se existe espaço para o produto.
4. Consuma somente os ingredientes necessários.
5. Entregue o produto.
6. Atualize o inventário e a interface.
7. Permita fabricar novamente enquanto houver materiais.

Se o inventário estiver cheio, não consuma os ingredientes sem conseguir entregar o resultado.

### 6.6. Ferramentas e itens

Implemente uma definição centralizada de itens contendo, quando aplicável:

- ID único.
- Nome.
- Ícone.
- Tipo.
- Quantidade máxima por pilha.
- Resistência.
- Dano.
- Velocidade de mineração.
- Material.
- Descrição.

A interface, o crafting, a mineração e o salvamento devem utilizar o mesmo identificador de item, evitando divergências entre sistemas.

## 7. FASE 4 — SOBREVIVÊNCIA

Complemente os sistemas de sobrevivência existentes.

### 7.1. Vida e dano

- Barra de vida.
- Recebimento de dano.
- Tempo curto de invulnerabilidade após ser atingido.
- Efeito visual e sonoro de dano.
- Morte e reaparecimento.
- Regras configuráveis para manter ou perder itens.
- Recuperação de vida por alimentos ou outros meios existentes.

### 7.2. Fome e alimentação

Se o sistema de fome já existir, finalize-o.

- Barra de fome.
- Redução gradual conforme o tempo e as ações.
- Alimentos com valores diferentes.
- Consumo de alimentos pelo inventário.
- Recuperação de fome.
- Regras claras para consequências da fome.

Não deixe a fome tornar a experiência inicial excessivamente punitiva.

### 7.3. Dia e noite

- Ciclo completo de dia e noite.
- Alteração gradual da iluminação.
- Mudança nas cores do céu.
- Luzes artificiais com comportamento consistente.
- Sons ambientes diferentes conforme o horário.
- Aparição de inimigos em condições apropriadas.

O ciclo não deve causar saltos abruptos de iluminação nem penalizar o jogador antes que ele aprenda as mecânicas básicas.

## 8. FASE 5 — ANIMAÇÕES E SENSAÇÃO DE JOGO

O ByteCrafter deve parecer um jogo vivo, não um cenário estático.

### 8.1. Animações do personagem

Implemente ou corrija as animações compatíveis com o modelo disponível:

- Parado.
- Caminhando.
- Correndo.
- Pulando.
- Caindo.
- Aterrissando.
- Minerando.
- Atacando.
- Utilizando itens.
- Recebendo dano.
- Morrendo e reaparecendo.

Se o personagem utilizar um modelo sem esqueleto, implemente animações adequadas à arquitetura atual. Não presuma que existam animações prontas.

A transição entre estados deve ser suave, e a velocidade da animação deve acompanhar a velocidade do movimento.

### 8.2. Animações de interface

- Abertura e fechamento suaves do inventário.
- Destaque animado do slot selecionado.
- Efeito ao coletar um item.
- Animação ao fabricar um objeto.
- Indicador visual de receita indisponível.
- Barra de progresso de mineração.
- Mensagens temporárias de coleta e fabricação.

Evite efeitos exagerados que atrapalhem a leitura da interface.

### 8.3. Efeitos visuais

Adicione efeitos leves e consistentes:

- Partículas ao quebrar blocos.
- Pequenos fragmentos correspondentes ao material.
- Animação de colocação.
- Efeito de impacto.
- Poeira ao aterrissar.
- Efeitos de água, se houver sistema de água.
- Iluminação e sombras coerentes.
- Distância de renderização ajustável.

Os efeitos devem ser otimizados para não comprometer o desempenho em computadores modestos.

### 8.4. Áudio

Implemente ou organize:

- Sons de passos por material.
- Sons de mineração.
- Sons de colocação.
- Sons de coleta.
- Sons de interface.
- Sons de crafting.
- Sons ambientais.
- Música opcional.

Inclua controles de volume e respeite as licenças dos recursos utilizados.

## 9. FASE 6 — PROGRESSÃO E DIVERSÃO

O jogador precisa ter motivos para explorar e continuar jogando.

Implemente progressivamente:

- Coleta de madeira, pedra e minérios.
- Fabricação de ferramentas melhores.
- Descoberta de novos recursos.
- Exploração de cavernas.
- Construção de abrigos.
- Baús e organização de recursos.
- Fornalhas e processamento de materiais.
- Agricultura e alimentos, conforme a estrutura existente.
- Animais e criaturas com comportamentos distintos.
- Inimigos com perseguição, ataque, dano e morte.
- Estruturas e locais de interesse.
- Recompensas por exploração.
- Pequenos objetivos ou desafios opcionais.

A progressão deve começar simples e ensinar as mecânicas naturalmente. Não adicione dezenas de sistemas incompletos: priorize poucos sistemas completos e interligados.

## 10. FASE 7 — SALVAMENTO E PERSISTÊNCIA

O jogador deve poder fechar o jogo e continuar depois sem perder o progresso.

Salve, conforme aplicável:

- Seed e configurações do mundo.
- Alterações nos blocos.
- Posição e orientação do jogador.
- Inventário e barra rápida.
- Vida e fome.
- Equipamentos.
- Baús e estações.
- Estado de estruturas e entidades persistentes.
- Progresso e configurações da partida.

Implemente validação dos dados, tratamento de arquivos corrompidos, versão do formato de salvamento e cópias de segurança.

Evite salvar todos os dados pesados a cada quadro. Utilize gravação incremental e momentos de salvamento apropriados.

Teste obrigatoriamente a sequência: criar mundo, coletar itens, construir, salvar, fechar o jogo, reabrir e confirmar que tudo continua correto.

## 11. FASE 8 — MENU E EXPERIÊNCIA DO JOGADOR

Melhore a apresentação do jogo.

Implemente ou aperfeiçoe:

- Tela inicial.
- Novo mundo.
- Lista de mundos salvos.
- Carregar mundo.
- Excluir mundo com confirmação.
- Configurações de vídeo e áudio.
- Sensibilidade do mouse.
- Distância de renderização.
- Pausa.
- Retorno ao jogo.
- Tela de morte e reaparecimento.
- Tutorial inicial curto.
- Indicações de controles.
- Mensagens claras para erros e ações indisponíveis.

O visual deve ser original e coerente com o ByteCrafter, evitando reproduzir diretamente logotipos ou elementos gráficos proprietários de Minecraft.

## 12. FASE 9 — MULTIPLAYER

Somente após o modo individual estar estável, revise o multiplayer LAN existente.

Verifique:

- Criação e entrada em uma partida.
- Sincronização dos jogadores.
- Sincronização de blocos modificados.
- Sincronização de itens e entidades.
- Controle de autoridade sobre o mundo.
- Prevenção de duplicação de itens.
- Desconexões e reconexões.
- Salvamento consistente.

Teste com pelo menos dois computadores reais. Se não for possível realizar esse teste, registre explicitamente que o multiplayer permanece não validado.

## 13. TESTES OBRIGATÓRIOS

Crie uma lista de testes reproduzíveis e execute o máximo possível.

### Testes técnicos

- Projeto abre no Godot 4.7.
- Importação concluída sem erros críticos.
- Cena principal inicia.
- Não existem referências essenciais ausentes.
- Não há erros críticos recorrentes no console.
- Menus não bloqueiam a entrada do jogador indevidamente.
- Recursos são liberados corretamente.

### Testes de gameplay

- Criar mundo novo.
- Caminhar, correr, pular e cair.
- Quebrar e colocar blocos.
- Coletar e empilhar itens.
- Abrir e fechar o inventário.
- Arrastar itens entre slots.
- Fabricar uma receita válida.
- Tentar fabricar sem recursos.
- Tentar fabricar com inventário cheio.
- Usar ferramentas.
- Receber dano e reaparecer.
- Salvar e carregar o mundo.
- Explorar regiões diferentes sem perder alterações.

### Teste de sessão prolongada

Jogue durante pelo menos 30 minutos, quando o ambiente permitir.

Observe:

- Travamentos.
- Quedas de FPS.
- Vazamentos aparentes de memória.
- Falhas na geração de chunks.
- Itens duplicados ou perdidos.
- Problemas de salvamento.
- Erros de interface.
- Comportamentos que impedem continuar a partida.

Registre os resultados. Não marque como aprovado um teste que não foi executado.

## 14. CRITÉRIOS DE ACEITAÇÃO

A versão inicial aprimorada será considerada pronta para avaliação quando:

1. O projeto importar e abrir no Godot 4.7.
2. A cena principal puder ser executada.
3. O jogador conseguir explorar e construir.
4. A mineração e a coleta funcionarem.
5. O inventário aceitar movimentação real de itens.
6. O crafting produzir itens corretamente.
7. As quantidades dos ingredientes forem respeitadas.
8. A sobrevivência funcionar sem estados inconsistentes.
9. O salvamento preservar o progresso.
10. As animações principais estiverem integradas.
11. Não houver erros críticos conhecidos que impeçam o jogo.
12. Os testes executados estiverem documentados.

O desempenho deve ser medido em hardware real. Não invente resultados de FPS nem prometa compatibilidade universal.

## 15. ORDEM DE EXECUÇÃO

Execute o desenvolvimento nesta ordem:

**Etapa A:** auditoria do projeto, importação e correção dos erros críticos.

**Etapa B:** controles, movimentação, câmera, mineração, construção e estabilidade do mundo.

**Etapa C:** inventário funcional, arrastar e soltar, receitas, grade 2×2 e mesa de crafting 3×3.

**Etapa D:** sobrevivência, ferramentas, persistência e progressão inicial.

**Etapa E:** animações, partículas, sons, interface e melhorias visuais.

**Etapa F:** biomas, exploração, criaturas, estruturas e conteúdo.

**Etapa G:** testes prolongados, otimização e multiplayer.

Ao concluir cada etapa, gere um relatório e preserve uma versão funcional antes de avançar.

Se uma etapa encontrar um bloqueio, corrija-o antes de adicionar dependências sobre o sistema defeituoso.

## 16. ENTREGA FINAL

Entregue:

1. O projeto Godot completo e atualizado em ZIP.
2. Todos os scripts, cenas, recursos e configurações necessários.
3. Um README com instruções para abrir e executar.
4. Um relatório de auditoria e correções.
5. Uma lista de funcionalidades implementadas.
6. Uma lista de testes executados e seus resultados.
7. Uma lista explícita dos problemas ainda conhecidos.
8. Uma relação de recursos externos e respectivas licenças, quando aplicável.

O ZIP deve conter a estrutura completa do projeto, incluindo `project.godot`, sem caminhos quebrados. Não inclua arquivos temporários ou caches gerados pelo editor sem necessidade.

**Não entregue apenas um relatório afirmando que o trabalho foi feito. Modifique os arquivos reais do projeto. Não declare o jogo completo se os critérios de aceitação ainda não tiverem sido cumpridos.**

## RESULTADO ESPERADO

Transformar o ByteCrafter em um sandbox voxel 3D funcional, com controles responsivos, mundo explorável, mineração, construção, inventário com movimentação real de itens, crafting funcional, sobrevivência, salvamento persistente e animações que tornem a experiência mais agradável.

Priorize estabilidade e diversão. É melhor entregar uma versão menor, consistente e realmente jogável do que um projeto enorme com várias funcionalidades apenas visuais.