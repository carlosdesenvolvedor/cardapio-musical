# 🧠 Master Information - Project context

Este documento consolida o conhecimento, arquitetura e estado atual do sistema, servindo como ponto único de referência para evitar erros em novas janelas de chat.

---

## 🏗️ Arquitetura Híbrida (Backend)

O projeto utiliza uma estratégia dual para otimizar custos e performance:

1.  **Metadados (Firestore):**
    *   **Perfis:** `users/{userId}` (Campos técnicos: `artistScore`, `professionalLevel`, `minSuggestedCache`, etc).
    *   **Serviços:** `users/{userId}/services/{serviceId}` (JSON completo do serviço).
2.  **Mídias e Documentos (C# Backend):**
    *   **Base URL:** `https://136.248.64.90.nip.io`
    *   **Função:** Armazena fotos de perfil, mídia de posts, PDFs e contratos.
    *   **CUIDADO:** Nunca tentar salvar binários (arquivos) diretamente no Firestore. Use sempre o `BackendStorageService`.

---

## 🛠️ Módulos Principais

### 1. `service_provider` (Prestação de Serviços)
*   **Dashboard:** Localizado em `lib/features/service_provider/presentation/pages/service_provider_dashboard_page.dart`.
*   **Novidade:** Interface tabbed (Serviços / Meu Cachê).
*   **Dica Técnica:** O `Scaffold` dentro do `BlocProvider` deve ser envolvido por um `Builder` para acessar o context do `ServiceDashboardBloc`.

### 2. `artist_quiz` e Selos Profissionais
*   **Cachê Sugerido:** Calculado via quiz de 30 itens (`ArtistQuizDialog`).
*   **Selos:** Bronze, Prata, Ouro e Diamante exibidos no perfil público baseados no `artistScore`.
*   **PDF:** Exportação de relatório de valor de mercado implementada na `ArtistCachePage`.

---

## 💡 Regras de Ouro para Desenvolvimento

1.  **Null Safety no Web:** Sempre use wrappers como `String.valueOf(data)` ao ler do Firestore para evitar crashes de `LegacyJavaScriptObject` no Chrome.
2.  **Navegação:** O acesso principal às ferramentas profissionais do artista está centralizado no **Drawer do MusicianDashboardPage**.
3.  **Estado:** Manter sincronia entre `AuthenticatedUser` e `UserProfile` (o `AuthBloc` gerencia ambos).

---

## 📍 Arquivos de Referência (Sessão Atual)
- [task.md](file:///c:/Users/user/.gemini/antigravity/brain/e7abc219-a7e8-490e-99fa-c6e6636b08d1/task.md)
- [walkthrough.md](file:///c:/Users/user/.gemini/antigravity/brain/e7abc219-a7e8-490e-99fa-c6e6636b08d1/walkthrough.md)
- [implementation_plan.md](file:///c:/Users/user/.gemini/antigravity/brain/e7abc219-a7e8-490e-99fa-c6e6636b08d1/implementation_plan.md)
