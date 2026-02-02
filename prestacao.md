# Planejamento de UI/UX - Módulo Prestador de Serviço
**Projeto:** CG Vitrine - App de Gestão de Eventos

Este documento define as diretrizes visuais e os prompts de referência para a criação das telas de cadastro e gestão de serviços. O objetivo é criar uma interface "High-Fidelity" com estética Dark Mode Premium.

---

## 1. Design System (Global)

Para todas as telas geradas, seguir estritamente esta paleta:

* **Tema:** Dark Mode (Noturno/Profissional).
* **Cor de Fundo (Background):** `Deep Matte Charcoal Black` (#101010).
* **Cor Primária/Acento (Action Colors):** `Glowing Neon Amber Yellow` (#FFC107).
* **Tipografia:** Sans-serif, Branca (Clean e Legível).
* **Estilo dos Componentes:**
    * Cards com bordas sutis.
    * Elementos ativos possuem um "Glow" (brilho) suave na cor Âmbar.
    * Visual minimalista e focado em "Card-based layout".

---

## 2. Prompt Mestre (Definição de Estilo)

Utilizar este prompt para gerar a identidade visual base ou configurar o contexto geral do design.

> **Prompt Base:**
> High-fidelity UI/UX design mockup of a professional event service registration web portal. Dark mode aesthetic. The background is deep matte charcoal black (#101010). The primary accent color for buttons, active states, and highlights is glowing neon amber yellow (#FFC107). All text is clean, legible white sans-serif font. The design is sleek, modern, card-based, with subtle glowing borders around active elements. It looks professional, suitable for large-scale event logistics.

---

## 3. Detalhamento das Telas e Prompts

### Tela 01: Dashboard do Prestador
**Objetivo:** Visão geral dos serviços que o usuário oferece e sua agenda.
**Componentes Chave:** Lista de cards, Botão de Ação (FAB ou Wide Button), Sidebar ou Bottom Nav.

> **Prompt de Geração:**
> High-fidelity UI/UX dashboard mockup for an event service provider portal. Dark mode, matte black background. White text, glowing amber yellow buttons and progress bars. The screen shows a main dashboard displaying a summary of registered services. There is a large "Novo Cadastro de Serviço" button in prominent amber color. Below it, a card-based grid listing existing services like "Banda de Rock (Ativo)" and "Equipe de Segurança (Pendente)". A sidebar navigation on the left with icons highlighted in amber. The overall feel is premium and organized.

### Tela 02: Seleção de Categoria (Branching)
**Objetivo:** O primeiro passo do cadastro. O usuário define o "tipo" de serviço, o que alterará o formulário seguinte.
**Componentes Chave:** Grid de botões grandes (Cards selecionáveis) com ícones e texto. Efeito de hover/seleção em Âmbar.

> **Prompt de Geração:**
> UI/UX design screenshot of a service category selection screen in a dark mode web app. Deep black background with white typography. The title says "Qual tipo de serviço você oferece?". Below are large, clickable rectangular cards with glowing amber borders and icons. Card 1: Microphone icon with text "Artístico & Talento". Card 2: Speaker/Truss icon with text "Técnica & Estrutura". Card 3: Cloche plate icon with text "Alimentação & Bebidas". Card 4: Shield icon with text "Segurança & Logística". When a card is hovered, it emits an amber glow. Clean, high contrast interface.

### Tela 03: Formulário Dinâmico (Detalhes Técnicos)
**Objetivo:** Formulário complexo que muda conforme a categoria. Exemplo focado em Músicos.
**Componentes Chave:** Inputs de texto, Upload de arquivos (Drag & Drop), Dropdowns, Botão de avanço.

> **Prompt de Geração:**
> UI design mockup of a complex registration form for a "Musician/Band" service. Dark mode black background, white text, amber accents. The screen title is "Cadastro Artístico: Detalhes Técnicos". The form is long and divided into sections. Section 1 "Informações Básicas" has standard input fields. Section 2 "Logística Técnica" highlights dynamic fields: A drag-and-drop area with an amber dashed border for "Upload de Mapa de Palco (PDF)", a dropdown selector for "Voltagem dos Equipamentos", and a multi-line text box for "Repertório/Setlist". At the bottom, a large glowing amber button says "Próxima Etapa: Precificação".

---

## 4. Estratégia de Implementação (Frontend)

Ao codificar estas telas (Flutter/Web), considerar:

1.  **Polimorfismo na UI:** Criar um `WidgetBuilder` que receba o `ServiceType` e retorne o formulário correto (ex: `MusicianForm`, `SecurityForm`).
2.  **Estado Global:** Utilizar gerenciamento de estado para persistir os dados enquanto o usuário navega entre as etapas (Stepper).
3.  **Feedback Visual:** Utilizar a cor `#FFC107` para feedbacks de validação e foco nos inputs.
Planejamento de UI/UX - Módulo Prestador de Serviço
**Projeto:** CG Vitrine - App de Gestão de Eventos

Este documento define as diretrizes visuais e os prompts de referência para a criação das telas de cadastro e gestão de serviços. O objetivo é criar uma interface "High-Fidelity" com estética Dark Mode Premium.

---

## 1. Design System (Global)

Para todas as telas geradas, seguir estritamente esta paleta:

* **Tema:** Dark Mode (Noturno/Profissional).
* **Cor de Fundo (Background):** `Deep Matte Charcoal Black` (#101010).
* **Cor Primária/Acento (Action Colors):** `Glowing Neon Amber Yellow` (#FFC107).
* **Tipografia:** Sans-serif, Branca (Clean e Legível).
* **Estilo dos Componentes:**
    * Cards com bordas sutis.
    * Elementos ativos possuem um "Glow" (brilho) suave na cor Âmbar.
    * Visual minimalista e focado em "Card-based layout".

---

## 2. Prompt Mestre (Definição de Estilo)

> **Prompt Base:**
> High-fidelity UI/UX design mockup of a professional event service registration web portal. Dark mode aesthetic. The background is deep matte charcoal black (#101010). The primary accent color for buttons, active states, and highlights is glowing neon amber yellow (#FFC107). All text is clean, legible white sans-serif font. The design is sleek, modern, card-based, with subtle glowing borders around active elements. It looks professional, suitable for large-scale event logistics.

---

## 3. Telas de Navegação (Fluxo Base)

### Tela 01: Dashboard do Prestador
> **Prompt:**
> High-fidelity UI/UX dashboard mockup for an event service provider portal. Dark mode, matte black background. White text, glowing amber yellow buttons and progress bars. The screen shows a main dashboard displaying a summary of registered services. There is a large "Novo Cadastro de Serviço" button in prominent amber color. Below it, a card-based grid listing existing services like "Banda de Rock (Ativo)" and "Equipe de Segurança (Pendente)". A sidebar navigation on the left with icons highlighted in amber. The overall feel is premium and organized.

### Tela 02: Seleção de Categoria (Branching)
> **Prompt:**
> UI/UX design screenshot of a service category selection screen in a dark mode web app. Deep black background with white typography. The title says "Qual tipo de serviço você oferece?". Below are large, clickable rectangular cards with glowing amber borders and icons. Card 1: Microphone icon "Artístico". Card 2: Speaker icon "Técnica/Estrutura". Card 3: Cloche icon "Gastronomia". Card 4: Shield icon "Segurança". Card 5: Camera icon "Mídia/Foto". When a card is hovered, it emits an amber glow.

---

## 4. Variações de Formulários por Setor (Expansão)

Aqui estão os prompts para gerar as telas específicas de cada nicho, garantindo que o sistema atenda eventos gigantes.

### Variação A: Infraestrutura e Técnica (Som, Luz, Geradores)
*Foco: Potência elétrica, dimensões e logística de carga.*
> **Prompt:**
> UI design mockup of a technical specification form for "Stage & Sound Structure". Dark mode black background, amber accents. The screen allows heavy data input. Sections include: "Requisitos de Energia" with toggles for 110v/220v/380v (Three-phase), inputs for KVA power. A section for "Logística de Montagem" showing a truck icon and fields for "Vehicle Height Clearance" and "Load-in Time". An upload area for "Mapa de Implementação (DWG/PDF)". The interface looks like a professional engineering tool but with consumer-friendly UX.

### Variação B: Gastronomia e Buffet (Comida e Bebida)
*Foco: Menu visual, restrições alimentares e degustação.*
> **Prompt:**
> UI design mockup of a catering service registration form. Dark mode, amber highlights. The focus is on visual menu selection. A section "Cardápio Visual" allows uploading photos of dishes in a grid. Checkbox tags for "Vegano", "Sem Glúten", "Kosher". A specific section for "Estrutura de Cozinha" asking if they need an on-site stove or bring ready-made food. At the bottom, a "Agendar Degustação" calendar widget. Elegant and appetizing interface.

### Variação C: Segurança e Staff (Recursos Humanos)
*Foco: Certificações legais, turnos e uniformes.*
> **Prompt:**
> UI design mockup of a security and staff registration form. Dark mode, amber accents. The interface focuses on compliance and roster management. A section for "Certificações" with upload buttons for legal permits (Police Check, Firefighter Training). A toggle switch for "Segurança Armada" (Warns about legal requirements). A "Uniforme" section showing icons of Suit (Formal) vs Tactical Vest (Heavy Event). Inputs for "Tamanho da Equipe por Turno". Very clean, serious, and trustworthy look.

### Variação D: Mídia e Registro (Foto, Vídeo, Drone)
*Foco: Portfólio visual e equipamentos.*
> **Prompt:**
> UI design mockup of a photographer/videographer registration form. Dark mode, amber accents. The screen is highly visual. A "Portfólio" section with a masonry grid layout for image uploads. A "Equipamentos" checklist section listing "Drones", "4K Cameras", "Live Streaming Unit". A field for "Prazo de Entrega (Dias)". The design feels like a creative studio interface.

---

## 5. Lógica de Negócios para o Desenvolvedor (Backend)

Para suportar essa complexidade no banco de dados:

1.  **Entidade Genérica:** `Servico` (ID, Nome, Preço Base).
2.  **Entidade Específica (JSONB):** `DetalhesTecnicos`.
    * Se for **Banda:** Salva `mapa_palco`, `repertorio`.
    * Se for **Gerador:** Salva `kva_potencia`, `tipo_combustivel`.
    * Se for **Segurança:** Salva `registro_policia_federal`, `tem_arma`.
3.  **Validação Dinâmica:** O frontend deve carregar o esquema de validação baseado no `tipo_servico` escolhido na Tela 02.
O que mudou com essa atualização?
Infraestrutura Pesada: Agora você cobre empresas de geradores e palcos (essencial para shows grandes e igrejas com eventos externos).

Compliance (Segurança): Adicionei campos de "Certificações" e "Arma", que são obrigatórios para eventos grandes legais.

Logística: O campo de "Carga/Descarga" e "Voltagem" evita que um caminhão fique entalado no portão ou que o som queime a tomada da casa do cliente.