# Regras Globais de Engenharia, Observabilidade e Guardrails de IA

## 1. Guardrails de Versionamento (Human-in-the-Loop)
- Após concluir a escrita do código ou refatoração, execute `git diff` e apresente um resumo conciso das alterações.
- NUNCA execute `git commit`, `git push` ou `git checkout` sem antes perguntar explicitamente ao usuário, na conversa, se pode prosseguir.
- Só execute esses comandos depois da aprovação explícita do usuário na conversa. O Claude Code ainda vai exibir sua própria confirmação nativa antes de rodar esses comandos (`.claude/settings.json`); trate essa confirmação como a etapa final de segurança, não como algo a ser contornado.
- Qualquer alteração de infraestrutura fora desses três comandos continua proibida de forma autônoma — sempre peça para o usuário executar manualmente.
- Antes de implementar, proponha trabalhar numa branch de feature/fix (não direto na branch principal), a menos que o usuário peça o contrário.
- Depois do push, pergunte separadamente se deve abrir um Pull Request (`gh pr create`) — não assuma que "sim" pro push implica "sim" pro PR.

## 2. Uso Racional de Tokens & Eficiência (Roteamento de Contexto)
- Respostas concisas e diretas ao ponto. Elimine saudações ou explicações prolixas do que foi pedido.
- Não leia diretórios inteiros sem necessidade. Use ferramentas de busca focada (`grep`, `find`) para carregar apenas arquivos relevantes.
- NUNCA reescreva arquivos inteiros para alterar poucas linhas. Use edições cirúrgicas no estilo patch ou substituição de blocos.

## 3. Diretrizes de Desenvolvimento Fullstack (Software)
- **Princípios:** Aplique SOLID, DRY e Arquitetura Limpa / Hexagonal. Separe estritamente Domínio, Aplicação e Infraestrutura.
- **Frontend (React/Angular):** Tipagem estrita em TypeScript (proibido usar `any`). Interfaces mobile-first, acessíveis (WCAG AA) e focadas nos Core Web Vitals.
- **Backend (Node/Python):** Regras de negócio isoladas dos controllers/frameworks. Consultas de banco otimizadas evitando o problema N+1.
- **Bancos de Dados (SQL/NoSQL):** Transações atômicas para dados críticos. Consultas paginadas por padrão para preservar memória e tempo de resposta.

## 4. Padrão de Observabilidade & Telemetria (Dados)
- Toda rota pública de API, worker ou manipulador de eventos DEVE emitir logs estruturados em JSON.
- Todo log deve incluir obrigatoriamente: `timestamp`, `level`, `trace_id` (para correlação), `event_name` e `duration_ms`.
- NUNCA registre dados sensíveis (PII, senhas, tokens, dados bancários) nos logs da aplicação.

## 5. Visão de Produto & Pragmatismo
- **Regra 80/20 (KISS):** Prefira soluções simples que resolvem a dor do negócio antes de sugerir superengenharia ou microserviços prematuros.
- Nenhuma feature é considerada concluída (Definition of Done) sem testes automatizados válidos (unitários/integração) e garantia de zero regressão.

## 6. Evidência Sobre Afirmação (Anti-Alucinação)
- NUNCA declare que um teste passou, um build funcionou, ou uma migração foi aplicada sem ter executado o comando de verdade e estar relatando a saída real dele. "Deveria funcionar" não é uma verificação.
- Ao citar um arquivo, função ou comportamento existente, baseie-se no que foi lido/executado nesta sessão — não em suposição de como o código "provavelmente" está.
- Cada agente tem um limite de `maxTurns` (`.claude/agents/*.md`). Se você atingir esse limite no meio de uma tarefa, sua saída retorna marcada como parcial — isso é esperado e seguro, não tente forçar mais trabalho além do limite para "terminar a qualquer custo".
- Regra de prompt é reforço comportamental, não garantia técnica. Onde existe um hook configurado (`.claude/hooks/`, ver `CONTEXT.md` §6), ele roda no runtime do Claude Code e pode bloquear a ação de verdade (ex: `git commit` com testes falhando) — trate isso como a checagem real, não como algo redundante ou contornável.