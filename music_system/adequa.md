# Guia de Adequação CG Music 2026 (Lei Felca & LGPD)

Este documento detalha o "como" e o "porquê" das mudanças, servindo como bússola para a implementação e operação do sistema.

---

## 1. Ações Técnicas e de Produto

### Fase 0: A Base Legal
*   **Ação:** Atualizar Termos de Uso e Política de Privacidade.
*   **Por que:** Sem isso, qualquer coleta de dado biométrico (selfie) ou documento é ilegal perante a LGPD.

### Fase 1: Filtro de Entrada (Age Gate)
*   **Ação:** Implementar fluxo de nascimento e verificação híbrida.
*   **Por que:** Cumprir o fim da autodeclaração exigido pela Lei Felca.

### Fase 2: Gestão de Conteúdo (Dever de Cuidado)
*   **Ação:** Integração com APIs de Visão Computacional (IA) e criação da "Quarentena".
*   **Por que:** Evitar responsabilidade jurídica da plataforma por posts criminosos.

---

## 2. Experiência do Usuário (Como vai funcionar)

### Para o Fã (Usuário Comum)
1.  **Cadastro:** Insere data de nascimento.
2.  **Verificação:** Se menor de 16 anos, o app solicita o e-mail do pai/responsável.
3.  **Uso:** O fã "navega" normalmente, mas só pode dar like/comentar após o pai clicar no link de aprovação enviado por e-mail.

### Para o Artista (Monetização)
1.  **Upgrade:** Para ativar o Pix/Painel de Artista, o usuário deve clicar em "Verificar Identidade".
2.  **KYC:** O app redireciona para um fluxo Gov.br ou captura de documento real.
3.  **Status:** Recebe selo de "Identidade Verificada".

---

## 3. Dificuldades e Desafios (Onde o bicho pega)

| Dificuldade | Impacto |
| :--- | :--- |
| **Burocracia no Cadastro** | Usuários podem desistir se o processo for muito longo. |
| **Custo de APIs** | Verificação por IA e Moderação de Imagem têm custo por requisição. |
| **Falsificação Parental** | O menor pode usar um e-mail secundário dele como se fosse o "pai". |
| **Falsos Positivos da IA** | A IA pode bloquear um post de show por "violência" erroneamente. |

---

## 4. Como Contornar (Estratégias de Sucesso)

### Contra a Desistência (Fricção)
*   **Aposta:** Deixe o usuário entrar no app e ver o feed **antes** de pedir a verificação pesada. Ele só "trava" quando tenta interagir. O desejo de interagir vence a preguiça do cadastro.

### Contra o Custo Alto
*   **Aposta:** Não escanear 100% das fotos de todos os usuários novos imediatamente. Foque o escaneamento pesado em usuários com "baixa reputação" ou contas muito novas.

### Contra a "Falsa Aprovação" Parental
*   **Aposta:** O log de auditoria é sua defesa. Se o menor mentiu, o sistema agiu de boa fé enviando o e-mail. Juridicamente, você provou que tentou o "Consentimento Verificável".

### Contra Erros da IA (Quarentena)
*   **Aposta:** Se a IA bloquear, mostre ao usuário: *"Seu post está em análise manual por conter elementos sensíveis"*. Dê a ele um botão "Solicitar Revisão Humana". Isso acalma o usuário e cumpre o "Direito à Explicação".

---

## 5. Logs de Auditoria (Sua Armadura Jurídica)
Cada ação de moderação ou verificação será gravada no banco Hyperf com:
*   **Quem:** ID do Usuário.
*   **O que:** Ação realizada.
*   **Como:** Método (IA Google, Humano, Gov.br).
*   **Prova:** Arquivo de log/token gerado.

> [!TIP]
> **Dica Final:** Trate a conformidade não como uma "trave", mas como um selo de qualidade. Usuários se sentem mais seguros em plataformas que protegem crianças e combatem crimes.
