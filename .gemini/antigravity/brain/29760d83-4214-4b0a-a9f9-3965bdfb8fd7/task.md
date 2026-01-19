# Roteiro de Reformulação da Rede Social (Artist Network)

## Fase 1: Arquitetura de Dados e Performance (Fundação) - CONCLUÍDA
- [x] **Arquitetura de Seguidores (Graph)**
    - [x] Criar subcoleções `followers` e `following`
    - [x] Implementar contadores desnormalizados (`followersCount`, `followingCount`) no documento do User
- [x] **Repositórios e Casos de Uso**
    - [x] Implementar `SocialGraphRepository` e `PostRepository` com paginação
    - [x] Criar UseCases para Follow/Unfollow e Feed
- [x] **Performance de Imagens**
    - [x] Criar widget `AppNetworkImage` com Shimmer e Cache
    - [x] Padronizar tratamento de `PostEntity` e `PostModel`

## Fase 2: Experiência do Usuário e Engajamento - CONCLUÍDA
- [x] **Feed Visual e Interação**
    - [x] Implementar Paginação Infinita (Infinite Scroll)
    - [x] Substituir spinners por Shimmer no feed (Via AppNetworkImage)
    - [x] Like Otimista (Optimistic UI) e Debounce no BLoC
- [x] **Diferencial MusicRequest**
    - [x] Badge "Tocando Agora" (Anel Dourado pulsante no Avatar)
- [x] **Atividade do Usuário**
    - [x] Campo `lastActiveAt` e `isLive` na entidade UserProfile

## Fase 3: Stories Profissionais - CONCLUÍDA
- [x] **Gestão de Stories**
    - [x] Filtro de Expiração Automática (24h)
    - [x] Criação de Stories (Upload de Imagem)
- [x] **Player de Stories**
    - [x] Barra de progresso e navegação por toque
    - [x] Anel de Stories (Gradiente) no Avatar

## Fase 4: Chat e Notificações (Retenção) - PRÓXIMOS PASSOS
- [ ] **Backend de Chat**
    - [ ] Lógica de Salas de Chat (Chat Rooms)
    - [ ] Mensagens Realtime (Stream)
- [ ] **Notificações**
    - [ ] Tela de "Coração" (Activity Feed)
    - [ ] Push Notifications (FCM)
