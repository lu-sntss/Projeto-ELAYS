# Elarys — Contexto do Projeto para Claude Code

## Visão Geral
RPG de Ação Sistêmico / Immersive Sim em primeira pessoa.
Visual Retro 3D / Dark Fantasy: modelos low-poly com texturas pixel art.
Inspirações: Daggerfall (atmosfera), Ocarina of Time (ritmo), Breath of the Wild (exploração), Deus Ex / Dishonored (sistêmica).

## Stack Técnica
- **Engine:** Godot 4.x
- **Linguagem principal:** GDScript
- **Futuro:** GDExtension em C++ para sistemas pesados
- **Renderização:** Viewport de baixa resolução escalada (filtro Nearest) para efeito pixel art
- **Filosofia:** Alta eficiência. Sem hyperscaling. Otimização na raiz do código.

## Estrutura de Pastas (manter consistente)
```
/scenes         → cenas Godot (.tscn), organizadas por área/sistema
/scripts        → GDScript (.gd), espelha estrutura de /scenes
/scripts/systems  → sistemas globais (inventário, atributos, combate, etc.)
/scripts/entities → jogador, NPCs, inimigos
/scripts/world    → interações de ambiente, objetos, triggers
/assets         → texturas pixel art, sprites, modelos low-poly
/assets/ui      → sprites de HUD, mãos, itens na tela
/data           → recursos de dados (.tres / .res): itens, magias, fichas
/shaders        → shaders de pós-processamento (vignette, fog, etc.)
```

## Convenções de Código
- **Nomenclatura:** snake_case para variáveis, funções e arquivos; PascalCase para nomes de nó e classes
- **Comentários:** em português
- **Singletons/Autoload:** prefixo em maiúscula (ex: `GameState`, `PlayerData`). **Nunca usar `class_name` em scripts de autoload** — o nome do autoload já cria um símbolo global; adicionar `class_name` com o mesmo nome gera "hides an autoload singleton" no parser do Godot 4.
- **Sinais:** prefixo `on_` nos handlers (ex: `on_player_died`)
- Evitar `_process()` desnecessário — preferir sinais e timers
- Sem `print()` em código final; usar `push_warning()` / `push_error()`

## Pilares de Design — NÃO QUEBRAR
### 1. Resolução Sistêmica (sem flags)
O ambiente reage a **propriedades**, não a roteiros. Exemplo:
```gdscript
# ERRADO — flag engessada
if player_killed_dragon:
    door.open()

# CERTO — sistêmico
if player.inventory.has_item("chave_torre") or door.lock_level <= player.lockpick_skill:
    door.unlock()
```
Obstáculos têm parâmetros (vida, nível de tranca, resistência mágica).
Podem ser superados por múltiplos caminhos: magia, ladinagem, força, itens.

### 2. Soft Gating
Progresso bloqueado naturalmente por inimigos letais ou geografia — nunca por invisible walls ou flags booleanas.

### 3. Narrativa Emergente
Sem logs de missão genéricos. Informação via rumores de taverna e elementos visuais do cenário. O Farol (aura dourada no horizonte) é a única bússola do jogador.

### 4. Otimização de Memória e Processamento
- Carregamento inteligente de cenas (load sob demanda, não tudo na cena principal)
- Controle estrito de texturas: pixel art em baixa res, escalonada pelo Viewport
- Iluminação dramática mas eficiente — evitar muitas luzes dinâmicas simultâneas

## Sistemas Centrais (referência rápida)

### Ficha do Jogador
Atributos clássicos de RPG + proficiências. Exemplo de estrutura esperada:
- `strength`, `dexterity`, `intelligence`, `endurance`
- Proficiências: `lockpick_skill`, `magic_proficiency`, `combat_skill`
- XP e level-up com efeitos sistêmicos (novas rotas se abrem organicamente)

### Sistema de Inventário
Itens com campos: `id`, `nome`, `peso`, `tipo` (arma / consumível / chave / ferramenta).
Ferramentas (bumerangue, magias) desbloqueiam rotas alternativas em áreas antigas.

### Sistema de Combate
Ação em primeira pessoa. Proficiência afeta dano e acesso a habilidades.
Inimigos têm parâmetros de dificuldade real — jogador deve recuar e preparar se não estiver pronto.

### O Farol
Efeito visual no shader/pós-processamento: aura dourada permanente no horizonte na direção da princesa.
Não é geometria 3D pesada — é renderizado como pós-efeito de tela.

### Horizonte Convexo (Curvatura de Mundo)
O horizonte do jogo deve ter aparência de lente convexa — como se o chão fosse curvo e o jogador pudesse ver longe em todas as direções ao mesmo tempo (referência visual: imagem de primeira pessoa com tocha e espada olhando para vale com castelo distante).
- Implementado como distorção barrel/fisheye **vertical** no shader de pós-processamento do SubViewportContainer
- Parâmetros expostos: `curve_strength` (intensidade da curvatura) e `vertical_offset` (onde senta o equador da distorção)
- Aplicado **após** o upscale pixel art, sobre a textura já renderizada — custo de processamento mínimo
- O efeito não deve distorcer o HUD (mãos, sprites de item) — aplicar apenas na camada 3D do viewport

## Quando Criar Novos Arquivos
- Um `.gd` por responsabilidade (não misturar lógica de sistema com lógica de entidade)
- Cenas reutilizáveis em `/scenes/components/`
- Dados de jogo como Resources do Godot (`.tres`), não hardcoded

## O que Evitar
- Invisible walls ou portas trancadas por flag booleana
- `_process()` rodando lógica pesada todo frame
- Texturas grandes (manter pixel art em resolução base baixa)
- Missões com marker/waypoint/log — tudo deve ser diegético
- God objects — dividir responsabilidade entre scripts pequenos e focados