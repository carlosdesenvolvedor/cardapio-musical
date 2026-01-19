# Relatório de Progresso - Transferência de Contexto

## Objetivo
Implementar a funcionalidade de **Live Streaming** usando o pacote `zego_uikit_prebuilt_live_streaming`, com foco crítico em **qualidade de áudio para músicos**.

## Estado Atual

### 1. Dependências
Adicionadas ao `pubspec.yaml`:
- `zego_uikit_prebuilt_live_streaming`
- `zego_uikit_signaling_plugin`

### 2. Arquivos de Configuração
- **Web:** Adicionado script do Zego no `web/index.html`.
- **Segredos:** Criado `lib/core/secrets/zego_secrets.dart` com as credenciais (AppID: 1166253932, AppSign, etc.).

### 3. Implementação da UI
- Arquivo: `lib/features/live/presentation/pages/live_page.dart`
- **Status:** A página básica foi criada, configurando Host vs Audience.
- **Problema Pendente:** O código para configuração de áudio "Musician Mode" (desativar ANS e AGC) foi comentado porque a propriedade `audioConfig` não foi encontrada diretamente na versão atual do pacote prebuilt.

## O Que Precisa Ser Feito (Próximos Passos)

1. **Corrigir Configuração de Áudio:**
   - É necessário acessar o motor nativo (`ZegoExpressEngine`) para desabilitar o processamento de voz padrão (ANS/AGC) que distorce instrumentos musicais.
   - Isso geralmente é feito inicializando o motor antes ou usando configurações avançadas do Prebuilt.

2. **Finalizar Integração:**
   - Garantir que a `LivePage` esteja usando as constantes de `ZegoSecrets`.
   - Criar a rota ou botão de navegação para acessar essa tela.

## Snippets de Código Relevantes

### Credenciais (Recuperar de `lib/core/secrets/zego_secrets.dart`)
- AppID: `1166253932`
- ServerUrl (Web): `wss://webliveroom1166253932-api.coolzcloud.com/ws`

### Trecho com Erro (`live_page.dart`)
```dart
    // TODO: A propriedade 'audioConfig' não existe no ZegoUIKitPrebuiltLiveStreamingConfig atual.
    // Para desativar ANS e AGC, consulte a documentação sobre 'advanceConfigs' ou use o ZegoExpressEngine.
    // config.audioConfig = ZegoLiveStreamingAudioConfig(
    //   enableANS: false,
    //   enableAGC: false,
    //   enableAEC: true,
    // );
```
