# 🎵 PlayArt - Cardápio Musical & Live Streaming Premium

![Build Status](https://img.shields.io/badge/Build-Passing-brightgreen)
![Version](https://img.shields.io/badge/Version-38-gold)
![Flutter](https://img.shields.io/badge/Made%20with-Flutter-blue)
![Firebase](https://img.shields.io/badge/Backend-Firebase-orange)
![LiveKit](https://img.shields.io/badge/Realtime-LiveKit-brightgreen)

> **A plataforma definitiva para Músicos Independentes: Cardápio Digital, Live Streaming e Monetização em um só lugar.**

O **PlayArt** é um ecossistema completo (PWA/Mobile) que transforma a performance musical. Deixe para trás os pedidos em papel e as lives sem engajamento. Ofereça ao seu público uma interface de luxo, interativa e com ferramentas de monetização integradas.

---

## ✨ Funcionalidades em Destaque

### 📺 Live Streaming Social (Inspirado no Instagram Live)
*   **Transmissão de Alta Performance:** Integração com **LiveKit** para áudio e vídeo de baixa latência.
*   **Interface Imersiva:** Design focado no artista com cabeçalhos compactos, selo de verificado e indicador de "AO VIVO".
*   **Engajamento em Tempo Real:** Chat interativo incorporado na transmissão.
*   **Multi-tarefa para o Público:** Espectadores podem abrir o cardápio, pedir músicas e enviar gorjetas **sem sair da live**. A transmissão continua rodando ao fundo em um modal elegante.
*   **Presença na Rede:** Anel de gradiente (Estilo Stories) no perfil do artista quando ele está online, permitindo acesso imediato à live pela rede social.

### 📱 Para o Público (Experiência do Cliente)
*   **Acesso Instantâneo:** Entrada via QR Code ou Link Direto (sem necessidade de app).
*   **Estética "Dark Gold":** Interface premium com tons de preto e dourado, animações suaves e glassmorphism.
*   **Busca Híbrida Inteligente:** Pesquisa no repertório do músico ou na base global da **Deezer** para encontrar qualquer música com capa oficial.
*   **Pedidos com Tip/Gorjeta:** Solicitação de música integrada a um fluxo de incentivo financeiro (Simulação de PIX).
*   **Animações de Sucesso:** Feedback visual com confetes e transições fluidas ao realizar um pedido.

### 🎸 Para o Músico (Painel Estratégico)
*   **Show Manager:** Dashboard intuitivo para gerenciar pedidos em fila, aceitar ou recusar solicitações.
*   **Gestão de Repertório Total:**
    *   CRUD completo de músicas.
    *   **Magic Cover Search:** Localização automática de capas de álbuns em alta definição.
    *   Importação via Planilha Excel (XLSX).
*   **Smart Lyrics & Chords:** Visualização de cifras/letras com suporte do **Cifra Club**, incluindo rolagem automática ajustável.
*   **Perfil Social Completo:** Bio, galeria de fotos, links sociais (Instagram/YouTube/Facebook) e contagem de seguidores.
*   **Centro de Notificações:** Alertas em tempo real para novos pedidos, doações, seguidores e interações.

---

## 🛠️ Stack Tecnológica

*   **Frontend:** [Flutter](https://flutter.dev) (Single Codebase para Web, iOS e Android).
*   **Realtime Media:** [LiveKit](https://livekit.io) para processamento de vídeo/áudio em tempo real.
*   **Backend & Cloud:** Firebase Suite (Auth, Firestore, Cloud Functions v2, Hosting, Storage).
*   **APIs Externas:**
    *   **Deezer API:** Metadados e arte de álbuns.
    *   **Cifra Club Scraper:** Busca de letras e cifras.
*   **Arquitetura:** Clean Architecture com BLoC/Cubit para gerenciamento de estado resiliente.

---

## 🚀 Guia Quick Start

### Instalação

```bash
# Clone e entre no projeto
git clone https://github.com/carlosdesenvolvedor/cardapio-musical.git
cd cardapio-musical/music_system

# Configure o ambiente
flutter pub get

# Execute em modo desenvolvimento
flutter run -d chrome --web-renderer canvaskit
```

### Build para Produção
```bash
# Web
flutter build web --release --web-renderer canvaskit
firebase deploy --only hosting
```

---

## � Roadmap & Status
**Versão Atual:** 38 (PWA Ready)
*   [x] Login/Cadastro Musician & Social Profile
*   [x] Streaming de Vídeo/Áudio Realtime (LiveKit)
*   [x] Cardápio Digital Interativo (Design Premium)
*   [x] Integração Global Deezer (Songs & Covers)
*   [x] Smart Lyrics (Busca Cifra Club + Auto-scroll)
*   [x] Sistema de Notificações Push & In-app
*   [x] Mobile Ready (Android/iOS Permissions)
*   [ ] Integração Real de Split de Pagamentos (Next Step)

---
Desenvolvido por **Carlos Desenvolvedor** & **Geomar Proj** | Elevando o nível da música ao vivo através da tecnologia. 🚀🎵
