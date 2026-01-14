# 🎵 MusicRequest System - Project Context & Documentation

> **Versão Atual:** 16
> **Status:** Em Desenvolvimento Ativo (Fase de Polimento Visual & Integrações)
> **Última Atualização:** 14/01/2026

Este documento serve como a "memória de longo prazo" do projeto. Ele detalha o estado atual, a arquitetura implementada, as funcionalidades ativas e os pontos críticos para continuar o desenvolvimento.

---

## 1. Visão Geral do Sistema

O **MusicRequest** é uma plataforma híbrida (PWA/Mobile) que conecta Músicos a seus Públicos em tempo real.
*   **Para o Músico:** Gestão de repertório, recebimento de pedidos, visualização de cifras/letras, e insights de performance.
*   **Para o Cliente (Público):** Um cardápio musical digital premium, onde podem pedir músicas, oferecer gorjetas (simulation) e interagir com o artista.

---

## 2. Status Atual das Funcionalidades

### ✅ Implementado e Funcional
1.  **Autenticação (Auth):**
    *   Login/Cadastro com Email e Senha (Firebase Auth).
    *   Perfis distintos: Músico (Artist) e Contratante (Contractor).
    *   Recuperação de senha.
    *   **Profile Page:** Edição de dados, foto de perfil, chave PIX e nome artístico.

2.  **Gestão de Repertório (Musician Dashboard):**
    *   CRUD completo de músicas (Firestore).
    *   **Busca Híbrida Inteligente:**
        *   **Aba Cifra Club:** Busca letras e artistas para cadastro rápido.
        *   **Aba Deezer (Capas):** Busca músicas na API Deezer para obter capas oficiais de alta qualidade.
    *   **"Magic Cover":** Capacidade de editar uma música existente (ex: importada do Cifra Club) e "anexar" uma capa oficial da Deezer posteriormente.
    *   Importação em massa via Excel (.xlsx).

3.  **Rede Social (Artist Network):**
    *   Feed de postagens estilo Instagram.
    *   Sistema de Stories (com destaque para o usuário logado).
    *   Busca Global: Artistas (Firestore) e Músicas (Deezer API).

4.  **Menu do Cliente (Client Menu - Premium):**
    *   **Acesso:** Via ID do Músico (simulação de QR Code).
    *   **Design Premium:** Estilo "Dark Luxury" com tons de Dourado/Amarelo (`0xFFE5B80B`) e Preto.
    *   **Header Personalizado:** Exibe foto real do músico, nome e chave PIX.
    *   **Busca Global:** O cliente pode pedir músicas do repertório OU buscar qualquer música na Deezer.
    *   **Pedidos & Gorjetas:** Fluxo completo de pedido com sugestão de valores de gorjeta (R$ 5, 10, 20) e animação de confetes.

5.  **Serviços Externos:**
    *   **DeezerService:** Busca músicas, capas e previews.
        *   *Obs:* Implementa Proxy CORS (`corsproxy.io` e `allorigins`) para funcionar no Flutter Web.
    *   **LyricsRemoteDataSource:** Scraper/API para Cifra Club (Stubs funcionais).

### 🚧 Em Construção / Stubs
*   **Artist Insights:** Dashboard visual criado (`ArtistInsightsPage`), mas aguardando integração real com IA/Dados.
*   **Chat:** Interface básica implementada, backend de realtime messaging pendente.
*   **Pagamento Real:** Apenas simulação (exibição de chave PIX).

---

## 3. Arquitetura e Tech Stack

*   **Framework:** Flutter 3.x (Web & Mobile).
*   **Linguagem:** Dart.
*   **Padrão:** Clean Architecture (Domain, Data, Presentation) + BLoC.
*   **Injeção de Dependência:** `get_it`.
*   **Backend:** Firebase (Firestore, Auth, Hosting).

### Estrutura de Pastas Chave
```
lib/
├── core/                  # Utilitários, Erros, Serviços Globais
│   ├── services/          # DeezerService, etc.
│   └── constants/         # AppTheme, Assets, Version
├── features/
│   ├── auth/              # Login, Perfil
│   ├── client_menu/       # Visão do Cliente (QR Code, Pedidos)
│   ├── community/         # Artist Network (Feed, Stories)
│   ├── musician_dashboard/# Área do Artista (Repertório, Insights)
│   ├── smart_lyrics/      # Integração Cifra Club
│   └── song_requests/     # Gestão de Pedidos (socket/stream)
└── main.dart              # Entrypoint e Inicialização (DI, Firebase)
```

---

## 4. Detalhes de Implementação Críticos

### Integração Deezer (CORS Proxy)
Para evitar erros de `XMLHttpRequest error` ou `Failed to fetch` no Flutter Web, todas as chamadas à API da Deezer passam por um proxy.
*   **Arquivo:** `lib/core/services/deezer_service.dart`
*   **Lógica:**
    ```dart
    final targetUrl = 'https://api.deezer.com/search?q=$encodedQuery';
    final proxyUrl = 'https://corsproxy.io/?${Uri.encodeComponent(targetUrl)}';
    ```

### Design System (Luxo/Amarelo)
O app migrou de um verde Spotify para uma identidade própria.
*   **Cor Primária:** Ouro (`0xFFE5B80B`).
*   **Fundos:** Gradientes Preto -> Marrom/Dourado Escuro (`0xFF1A1600`).
*   **Fontes:** Google Fonts `Outfit` e `Inter`.

### Versão do Deploy
*   A versão é controlada manualmente em `lib/core/constants/app_version.dart`.
*   **Atual:** `const String APP_VERSION = '16';`

---

## 5. Como Continuar o Desenvolvimento (Instruction for Agents)

1.  **Ler este arquivo** antes de qualquer ação para entender o contexto.
2.  **Verificar Versão:** Sempre verifique `app_version.dart` antes de fazer deploy.
3.  **Manter Clean Arch:** Não misture lógica de UI com Regras de Negócio. Use os BLocs existentes.
4.  **Testar Web:** Lembre-se que o projeto roda primariamente na Web (Firebase Hosting). Evite pacotes que não tenham suporte Web ou demandem configurações nativas complexas sem fallback.
5.  **Cuidado com Imports:** Mantenha imports relativos ou absolutos consistentes.

---

## 6. Comandos Úteis

*   **Rodar Localmente:** `flutter run -d chrome`
*   **Analisar Código:** `flutter analyze`
*   **Build Web:** `flutter build web`
*   **Deploy:** `firebase deploy --only hosting`
