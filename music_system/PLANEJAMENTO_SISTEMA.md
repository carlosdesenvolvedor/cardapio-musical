# Análise e Planejamento do Sistema Music System

[ignoring loop detection]

Este documento consolida a análise dos fluxogramas do Miro fornecidos e propõe um plano técnico para implementação das funcionalidades faltantes.

## 1. Status Atual vs. O Que Falta (Gap Analysis)

Com base nas imagens do Miro e na estrutura atual do projeto, identificamos os seguintes status:

### ✅ Módulos Concluídos (Cor Verde)
Estas áreas já possuem estrutura sólida no código e funcionalidades operacionais.
- **Feed de Postagens**: Implementado em `features/community`.
- **Stories (12h)**: Implementado (`story_upload_bloc.dart`).
- **Criação de Banda**: Implementado em `features/bands`.
- **Controle de Repertório/Letras**: Implementado em `features/smart_lyrics`.
- **Peça sua Música**: Implementado em `features/song_requests`.

### 🚧 Em Construção / A Fazer (Cor Amarela)
Estas são as áreas críticas que precisam de foco imediato para completar o ecossistema do Artista.

| Funcionalidade (Miro) | Estrutura no Código (`lib/features/`) | Status Técnico |
| :--- | :--- | :--- |
| **Chat Interativo** | `community` (parcial?) | **Prioridade Alta**. Essencial para negociações e engajamento. |
| **Carteira & Cachê** | `wallet` (existe mas parece vazio) | **Crítico**. Sem isso, a "Live Remunerada" e "Contratação" não funcionam. |
| **Agenda e Shows** | `calendar` / `bookings` | Precisa integrar com o recebimento de propostas. |
| **Live Remunerada** | `live` (com erros recentes) | Precisa primeiro estabilizar o vídeo (`Zego/SDK`) e depois adicionar a trava de pagamento. |
| **Dashboard IA** | `musician_dashboard` | Falta integrar lógica de dados reais e insights. |

---

## 2. Diagrama de Casos de Uso (Estudo de Caso)

Este diagrama ilustra como os Atores (Usuários) interagem com os módulos que **faltam** ser finalizados (em Amarelo).

```mermaid
useCaseDiagram
    actor "Artista / Músico" as Artista
    actor "Contratante / Fã" as Usuario

    package "Módulo: Negócios & Agenda" {
        usecase "Receber Proposta de Show" as UC_Proposta
        usecase "Gerenciar Agenda" as UC_Agenda
        usecase "Aceitar/Recusar Contrato" as UC_Contrato
    }

    package "Módulo: Financeiro (Carteira)" {
        usecase "Visualizar Saldo (Cachê)" as UC_Saldo
        usecase "Solicitar Saque" as UC_Saque
        usecase "Pagar por Live/Serviço" as UC_Pagamento
    }

    package "Módulo: Interação (Live & Chat)" {
        usecase "Realizar Live Remunerada" as UC_LiveVIP
        usecase "Conversar no Chat" as UC_Chat
        usecase "Assistir Live (Com Ticket)" as UC_Assistir
    }

    Artista --> UC_Agenda
    Artista --> UC_Proposta
    Artista --> UC_Contrato
    Artista --> UC_LiveVIP
    Artista --> UC_Saldo
    Artista --> UC_Chat

    Usuario --> UC_Pagamento
    Usuario --> UC_Proposta
    Usuario --> UC_Assistir
    Usuario --> UC_Chat

    %% Relações e Dependências
    UC_Proposta ..> UC_Agenda : "Verifica Disp."
    UC_Contrato ..> UC_Pagamento : "Gera Cobrança"
    UC_Assistir ..> UC_Pagamento : "Exige Ticket"
```

---

## 3. Roteiro de Implementação Sugerido

Para "montar isso" de forma lógica, recomendo a seguinte ordem, pois uns dependem dos outros:

### **Fase 1: Fundação Financeira (Wallet)**
Antes de receber por lives ou shows, o sistema precisa saber gerenciar saldo.
1.  Criar Entidades: `Wallet`, `Transaction`.
2.  Criar Tabela de Preços/Serviços.
3.  Implementar Tela de Extrato (`features/wallet`).

### **Fase 2: Negócios (Agenda & Bookings)**
1.  Refinar o `Calendar` para suportar "Bloqueios de Data".
2.  Criar fluxo de "Enviar Proposta" (do lado do fã/contratante).
3.  Criar fluxo de "Aceitar Proposta" (do lado do artista), gerando um registro na Agenda.

### **Fase 3: Live Remunerada (A Cereja do Bolo)**
1.  Corrigir os bugs de `LivePage` (estabilidade).
2.  Adicionar uma verificação: "Se for Live VIP, checar se Usuario pagou (Wallet)".
