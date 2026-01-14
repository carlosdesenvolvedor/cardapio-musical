# 🎵 Cardápio Musical & Gestão de Pedidos

![Build Status](https://img.shields.io/badge/Build-Passing-brightgreen)
![Version](https://img.shields.io/badge/Version-16-gold)
![Flutter](https://img.shields.io/badge/Made%20with-Flutter-blue)
![Firebase](https://img.shields.io/badge/Backend-Firebase-orange)

> **Cardápio Musical Digital Premium conectando Músicos e Público em tempo real.**

Este projeto é uma plataforma PWA (Progressive Web App) e Mobile que moderniza a experiência de pedir músicas em bares, restaurantes e eventos. Substitui o antigo "papelzinho" por uma interface digital luxuosa, integrada a APIs de música e sistemas de gorjeta.

---

## ✨ Funcionalidades Principais

### 📱 Para o Público (Cliente)
*   **Acesso Instantâneo:** Leitura de QR Code ou Link direto (sem login obrigatório).
*   **Experiência Premium:** Interface "Dark Luxury" com tons de Dourado e animações fluidas.
*   **Busca Global (Deezer):** Procura músicas no repertório do artista OU em toda a base da Deezer (capas oficiais).
*   **Pedidos Interativos:** Solicitação de música com sugestão de gorjeta (Simulação PIX).
*   **Feedback Visual:** Animações de confete ao enviar um pedido.

### 🎸 Para o Músico (Admin)
*   **Dashboard Completo:** Gestão de perfil, foto, nome artístico e chave PIX.
*   **Gestão de Repertório:**
    *   Adicionar/Editar/Remover músicas.
    *   **Magic Cover:** Busca automágica de capas de alta resolução na API da Deezer.
    *   Importação em massa (Excel).
*   **Smart Lyrics:** Visualização de cifras/letras (Integração Cifra Club - Stub).
*   **Rede Social:** Feed de postagens e Stories para engajar o público.

---

## 🛠️ Tecnologias Utilizadas

*   **Frontend:** [Flutter](https://flutter.dev) (Web & Mobile).
*   **Arquitetura:** Clean Architecture + BLoC Pattern.
*   **Backend:** Firebase (Auth, Firestore, Hosting, Storage).
*   **Integrações:**
    *   **Deezer API:** Busca de metadados e capas de álbuns.
    *   **CorsProxy:** Solução para requisições HTTP em Web.
*   **Design System:** Google Fonts (Outfit/Inter), Flutter Animate, Glassmorphism.

---

## 🚀 Como Rodar o Projeto

### Pré-requisitos
*   Flutter SDK instalado.
*   Conta no Firebase configurada.

### Instalação

```bash
# Clone o repositório
git clone https://github.com/carlosdesenvolvedor/cardapio-musical.git

# Entre na pasta do projeto
cd cardapio-musical/music_system

# Instale as dependências
flutter pub get

# Rode o projeto (Web)
flutter run -d chrome
```

### Build & Deploy
```bash
# Gerar versão Web
flutter build web

# Deploy no Firebase Hosting
firebase deploy --only hosting
```

---

## 📸 Screenshots

| Tela de Scan QR | Cardápio Premium | Dashboard Músico |
|:---:|:---:|:---:|
| *Entrada luxuosa para o cliente* | *Busca integrada com Deezer* | *Gestão total do show* |

---

## 📝 Status do Projeto
**Versão Atual:** 16
*   [x] Login e Perfil de Músico
*   [x] Integração Deezer (Search & Covers)
*   [x] Cardápio do Cliente (Design Final)
*   [ ] Integração Real de Pagamentos (Em Breve)
*   [ ] Chat em Tempo Real (Em Breve)

---
Desenvolvido com ❤️ e muita música.
