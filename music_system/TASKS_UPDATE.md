# Atualização de Tarefas (Versão 19)

## ✅ Concluído Recentemente

### 1. Sistema de Notificações Completo
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

### 2. Smart Lyrics (Correções Críticas)
- **Crash Fix:** Resolvido erro de `Assertion failed` no `ScrollController` quando a tela de letras era fechada durante a rolagem automática.
- **Scraping Melhorado:** O algoritmo de busca de cifras agora é "resiliente". Se não encontrar a cifra nos seletores padrão do Cifra Club, ele varre todos os blocos de texto (`<pre>`) da página para tentar encontrar o conteúdo, corrigindo falhas em músicas com layout diferente (ex: Roberto Carlos).

### 3. Deploy e Infraestrutura
- **Firebase Deploy:** Resolvido problema de permissões no Storage e deploy realizado com sucesso.
- **Versão:** Atualizada para **19**.

## 🚧 Próximos Passos (Sugestões)

1. **Pagamentos:**
   - Integração com API de PIX real para recebimento de gorjetas e pagamentos de couvert.
2. **Otimização Mobile:**
   - Verificar comportamento do scraping e player de vídeo em dispositivos móveis nativos (Android/iOS).
3. **Testes:**
   - Realizar testes de carga no chat em tempo real.

---
*Última atualização: Versão 19*
