# Feature Specification: Módulo de Bandas e Agenda (Booking)

## 1. Contexto e Objetivo
Implementar uma nova entidade no sistema chamada "Banda" (`Band`), que permite o agrupamento de músicos (`Users`) para contratação unificada. Este módulo introduz um modelo de monetização (Paywall para criação/manutenção da banda) e um sistema de gestão de agenda compartilhado.

## 2. Regras de Negócio (Business Rules)

### 2.1. Criação e Planos ("Existir ou Ser Vista")
- **Restrição de Criação:** A criação de uma banda é bloqueada por um Paywall.
- **Planos Disponíveis:**
  1.  **Plano Básico ("Existir"):** Permite criar o perfil, adicionar membros e usar a agenda.
  2.  **Plano Pro ("Ser Vista"):** Inclui os itens do Básico + Boost no algoritmo de busca (campo `isPromoted: true`) + Badge de Verificação.
- **Inadimplência:** Se o plano expirar, a banda entra em status `inactive` (perfil oculto nas buscas, mas dados preservados).

### 2.2. Gestão de Membros
- **Papéis:**
  - `Leader`: O criador da banda. Pode editar perfil, agenda e remover membros.
  - `Member`: Músico convidado. Aparece no perfil da banda.
- **Fluxo de Convite:**
  - Líder envia convite via ID do usuário.
  - Usuário recebe notificação e deve aceitar (`accepted`) ou recusar (`rejected`).
  - Ao aceitar, cria-se uma referência bidirecional: Banda aparece no perfil do Usuário e Usuário aparece no perfil da Banda.

### 2.3. Perfil da Banda vs. Usuário
- O perfil de Banda deve possuir campos exclusivos de "Venda":
  - `biography`: Texto rico (Markdown) contando a história.
  - `mediaKit`: Array de links de vídeos (YouTube/Vimeo) para destaque.
  - `techRider`: PDF ou texto técnico de som.

### 2.4. Calendário e Agendamento
- **Disponibilidade:** A agenda da banda deve cruzar dados com a agenda pessoal dos músicos (opcional na v1, mas desejável).
- **Visão do Contratante:** Ao solicitar orçamento, datas bloqueadas (`blocked`) ou com eventos confirmados (`booked`) ficam indisponíveis para seleção.
- **Visão do Líder:** Pode bloquear datas manualmente (ex: "Férias" ou "Show Externo").

---

## 3. Estrutura de Dados Sugerida (Schema)

### Coleção `bands`
```json
{
  "id": "uuid",
  "name": "Nome da Banda",
  "slug": "nome-da-banda", // para url amigável
  "leaderId": "user_uid",
  "subscription": {
    "planId": "basic_monthly", // ou "pro_monthly"
    "status": "active", // active, past_due, canceled
    "expiresAt": "timestamp"
  },
  "profile": {
    "description": "Texto longo...",
    "genres": ["Rock", "Pop"],
    "mediaLinks": ["url1", "url2"]
  },
  "settings": {
    "isPromoted": false // Controlado pelo plano PRO
  },
  "createdAt": "timestamp"
}
Sub-coleção bands/{bandId}/members
JSON

{
  "userId": "user_uid",
  "role": "member", // ou leader
  "status": "active", // active, pending_invite
  "instrument": "Guitarra" // Sobrescreve o principal do user se necessário
}
Coleção bookings (Global ou Raiz)
JSON

{
  "targetId": "band_uuid", // ID da Banda
  "targetType": "band",
  "contractorId": "user_uuid", // Quem contrata
  "date": "2025-12-25",
  "status": "pending_approval", // pending_approval, confirmed, completed, cancelled
  "price": 1500.00
}
4. Plano de Implementação (Implementation Plan)
Fase 1: Backend & Dados (Priority: High)
Criar os modelos de dados (Firestore/Supabase) baseados no schema acima.

Criar Cloud Functions/API Endpoints para:

createBand(data): Validar pagamento antes de criar.

inviteMember(bandId, userId): Enviar notificação.

respondToInvite(inviteId, status): Atualizar status do membro.

Fase 2: Frontend - Gestão (Priority: High)
Criar tela "Minhas Bandas" no painel do usuário.

Criar fluxo de "Nova Banda" com integração ao Gateway de Pagamento (Mockar pagamento por enquanto).

Implementar Dashboard da Banda (Abas: Visão Geral, Agenda, Membros).

Fase 3: Frontend - Perfil Público (Priority: Medium)
Criar página pública /band/:slug.

Implementar visualização diferenciada (Hero image grande, seção de História).

Listar Cards dos Músicos (clicáveis para perfil individual).

Fase 4: Agenda & Contratação (Priority: Medium)
Implementar componente de Calendário na visão da Banda (bloqueio de datas).

Implementar Modal de "Solicitar Orçamento" na visão do Contratante (seleção de datas livres).

5. Instruções para o Agente (Agent Instructions)
Estilo de Código: Siga os padrões existentes no repositório (Clean Architecture/MVC).

Componentização: Reutilize os widgets de UserProfile onde possível, mas crie novos para BandProfile onde a UI divergir significativamente.

Segurança: Garanta que apenas o leaderId possa editar as configurações da banda nas Security Rules.