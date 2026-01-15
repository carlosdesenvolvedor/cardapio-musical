# Atualização de Tarefas (Versão 20)

## ✅ Concluído Recentemente

### 1. Refatoração e Melhorias no Perfil
- **Refatoração do ArtistFeedCard:** Widget extraído para arquivo próprio e código limpo.
- **Aba "Posts" no Perfil:** Implementada listagem de posts do usuário.
- **Scroll Infinito no Perfil:**
  - Substituição de `Column` por `NestedScrollView` para garantir que o cabeçalho do perfil role junto com as abas ("Sobre", "Posts", etc.), melhorando a experiência de uso.
- **Correção de Crash (Firestore Index):**
  - Implementada ordenação em memória para evitar erros de índice ausente no Firestore ao filtrar posts por usuário.

### 2. Sistema de Notificações Completo
- **Backend:**
  - Implementado `NotificationRepository` com suporte a listeners do Firestore.
  - Injeção de dependências configurada para disparar notificações automaticamente em:
    - Likes (`PostRepository`)
    - Comentários (`PostRepository`)
    - Follows (`SocialGraphRepository`)
    - Mensagens (`ChatRepository`)
- **Frontend:**
  - **Indicador Visual:** Ponto vermelho na AppBar quando há novas notificações.
  - **Lista de Atividades:** Design otimizado com destaque (fundo + bolinha amarela) para itens não lidos.
  - **Navegação Inteligente:**
    - Clicar em "Seguiu você" -> Vai para o perfil do usuário.
    - Clicar em "Curtiu/Comentou" -> Vai para `PostDetailPage` (nova página criada).
    - Clicar em "Mensagem" -> Vai para o chat.
  - **Mark as Read:** Notificações são marcadas como lidas automaticamente ao clicar.

### 3. Smart Lyrics (Correções Críticas)
- **Crash Fix:** Resolvido erro de `Assertion failed` no `ScrollController` quando a tela de letras era fechada durante a rolagem automática.
- **Scraping Melhorado:** O algoritmo de busca de cifras agora é "resiliente".

## 🚧 Próximos Passos (Sugestões)

1. **Pagamentos:**
   - Integração com API de PIX real para recebimento de gorjetas e pagamentos de couvert.
2. **Otimização Mobile:**
   - Verificar comportamento do scraping e player de vídeo em dispositivos móveis nativos (Android/iOS).
3. **Testes:**
   - Realizar testes de carga no chat em tempo real.

---
*Última atualização: Versão 20*
