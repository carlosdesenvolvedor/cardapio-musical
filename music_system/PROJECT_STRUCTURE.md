# Estrutura de Diretórios do Projeto MUSICG

Este documento descreve a organização dos arquivos principais do projeto, destacando a arquitetura modular e limpa baseada em Clean Architecture.

```text
lib/
├── config/                  # Configurações Globais
│   ├── routes/              # Definição de rotas e navegação
│   └── theme/               # AppTheme (Cores, Gradientes e Estilos Visuais)
│
├── core/                    # Núcleo Reutilizável
│   ├── constants/           # Constantes (API Keys, ZegoConfig, Configurações Firebase)
│   ├── error/               # Tratamento de exceções e falhas
│   ├── services/            # Serviços (Cloudinary, Firebase Storage, Notificações, Deezer)
│   ├── usecases/            # Classe base para casos de uso
│   └── utils/               # Utilitários (Sanitizadores, Validadores, Extensões)
│
├── features/                # Módulos Funcionais (Clean Architecture)
│   │
│   ├── auth/                # AUTENTICAÇÃO E PERFIS
│   │   ├── domain/          # Entidades (UserProfile, UserEntity) e Repositórios
│   │   └── presentation/    # Login, Criação de Perfil, Edição de Avatar
│   │
│   ├── community/           # REDE SOCIAL (Core Engagement)
│   │   ├── domain/          # Lógica de Feed, Stories e Interações (Follow/Unfollow)
│   │   └── presentation/    # Galeria de Artistas, Stories com Edição Pro e Filtros
│   │
│   ├── musician_dashboard/  # PAINEL DO MÚSICO
│   │   ├── presentation/    # Gestão de Repertório (CRUD), Artist Insights
│   │   └── ...              # Dashboard de desempenho e fãs
│   │
│   ├── client_menu/         # MENU DIGITAL (Fã/Cliente)
│   │   ├── presentation/    # Visualização de Setlist via QR Code, Perfil do Artista
│   │   └── ...              # Interface otimizada para pedidos rápidos
│   │
│   ├── live/                # STREAMING (Zego UI Kit)
│   │   └── presentation/    # Transmissões em tempo real com baixa latência
│   │
│   ├── song_requests/       # INTERAÇÃO EM TEMPO REAL
│   │   └── ...              # Pedidos de música e Gorjetas (Tips) integrada
│   │
│   ├── bookings/            # GESTÃO DE CONTRATAÇÕES (Novo)
│   │   └── ...              # Fluxo de negociação e reserva de shows
│   │
│   ├── calendar/            # AGENDA DE SHOWS E TURNÊS
│   ├── smart_lyrics/        # LETRAS E CIFRAS INTELIGENTES
│   └── bands/               # GESTÃO DE GRUPOS E BANDAS
│
├── injection_container.dart # Injeção de Dependências (Service Locator / GetIt)
└── main.dart                # Ponto de entrada do Aplicativo (Setup Firebase/Zego)
```

## Tecnologias e Funcionalidades Principais

| Recurso | Descrição |
| :--- | :--- |
| **Stories Avançados** | Criação de stories com edição de imagem (filtros, texto, stickers) via `pro_image_editor`. |
| **Live Streaming** | Transmissões de vídeo integradas com `ZegoUIKit` para interação músico/fã. |
| **Escalabilidade Visual** | Design System baseado em Gold/Dark Aesthetics com Glassmorphism. |
| **Cloud Computing** | Mix de Firebase (Data/Auth) e Cloudinary (Media Optimization). |
| **Repertório Inteligente** | Gestão completa de músicas com integração de APIs de streaming. |
