# Regras Globais de Engenharia, Observabilidade e Guardrails de IA

## 1. Guardrails de Versionamento (Human-in-the-Loop)
- `git commit`, `git push`, `git checkout`, `git merge`, `git rebase` e `gh pr create`/`pr merge`/`release create` estão bloqueados por `deny` no `.claude/settings.json` — pra **todo agente**, sem exceção, em qualquer modo de permissão. Não é "pergunte antes": é "não tem como executar, ponto". Não tente rodar esses comandos, nem peça pra outro agente rodar.
- **Por que `deny` e não `ask`:** já tentamos "pergunte e depois execute" (um agente pergunta, espera aprovação, outro agente executa) e falhou na prática — um subagente delegado não consegue de fato pausar e esperar uma resposta ao vivo do usuário; ele roda até o fim e devolve um resultado só. Isso vale mesmo quando o usuário menciona o agente explicitamente (`@orchestrator-architect`) no meio de uma sessão — continua sendo uma invocação de subagente, não uma sessão principal capaz de pausar. Só `deny` garante isso de forma mecânica, independente de como o agente foi chamado.
- Depois de concluir o código, execute `git diff` (leitura, sem risco) e apresente um resumo conciso das alterações, junto com uma mensagem de commit sugerida (Conventional Commits) e os comandos exatos — prontos pra copiar e colar — que o usuário deve rodar ele mesmo, no terminal dele.
- Estratégia de branch (feature/fix + PR vs. direto na main) é uma decisão permanente de projeto, não uma escolha por request — segue o padrão do §7: pergunte uma única vez, grave a resposta em `CONTEXT.md` §6, e siga essa resposta silenciosamente daí em diante.
- Se o usuário pedir ajuda com um conflito de merge/rebase, edite os arquivos conflitantes — nunca finalize (`git add`/`commit`/`--continue`) você mesmo.
- Qualquer outra alteração de infraestrutura continua proibida de forma autônoma — sempre peça para o usuário executar manualmente.

## 2. Uso Racional de Tokens & Eficiência (Roteamento de Contexto)
- Respostas concisas e diretas ao ponto. Elimine saudações ou explicações prolixas do que foi pedido.
- Não leia diretórios inteiros sem necessidade. Use ferramentas de busca focada (`grep`, `find`) para carregar apenas arquivos relevantes.
- NUNCA reescreva arquivos inteiros para alterar poucas linhas. Use edições cirúrgicas no estilo patch ou substituição de blocos.
- **Saída de comando enxuta entre agentes:** ao repassar o resultado de um comando (`test`, `build`, `lint`) para outro agente — por exemplo `product-qa-reviewer` devolvendo uma falha pro `orchestrator-architect` repassar ao especialista responsável — extraia só as linhas relevantes (mensagens de falha, stack trace do erro específico), nunca o log verboso inteiro. Isso vale mesmo dentro do limite de tentativas do "Rejection loop, capped": aquele limite controla a *quantidade* de retentativas, este aqui controla o *tamanho* de cada uma — sem os dois, um agente preso em 1-2 retentativas ainda pode reprocessar milhares de linhas de log repetidas vezes.

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
- Nenhuma feature é considerada concluída (Definition of Done) sem testes automatizados válidos (unitários, integração e, quando a jornada for crítica, E2E) e garantia de zero regressão.
- Para lógica de negócio crítica (pagamentos, permissões, cálculos financeiros), a suíte de testes deve ser boa o suficiente pra ser validada por teste de mutação, não só ter cobertura de linha — cobertura alta com testes fracos passa despercebida sem isso.
- Este template não cria nem gerencia pipeline de CI/CD — assume que uma já existe (ou deveria existir) no projeto. O papel dos agentes é garantir que o código novo passa nos testes localmente e é compatível com o que a pipeline já valida, não substituí-la.

## 6. Evidência Sobre Afirmação (Anti-Alucinação)
- NUNCA declare que um teste passou, um build funcionou, ou uma migração foi aplicada sem ter executado o comando de verdade e estar relatando a saída real dele. "Deveria funcionar" não é uma verificação.
- Ao citar um arquivo, função ou comportamento existente, baseie-se no que foi lido/executado nesta sessão — não em suposição de como o código "provavelmente" está.
- Cada agente tem um limite de `maxTurns` (`.claude/agents/*.md`). Se você atingir esse limite no meio de uma tarefa, sua saída retorna marcada como parcial — isso é esperado e seguro, não tente forçar mais trabalho além do limite para "terminar a qualquer custo".
- Regra de prompt é reforço comportamental, não garantia técnica. Onde existe um hook configurado (`.claude/hooks/`, ver `CONTEXT.md` §6), ele roda no runtime do Claude Code e pode bloquear a ação de verdade (ex: `git commit`/`git push` com testes falhando) — trate isso como a checagem real, não como algo redundante ou contornável.

## 7. Decisões Permanentes de Projeto (Pergunte Uma Única Vez)
- Toda decisão de projeto que não muda de request pra request (onde está a pipeline de CI, se o hook local está habilitado, estratégia de release/rollback/feature flag, estratégia de branch, onde alertas são visualizados e quem é notificado) segue o mesmo padrão: se a seção correspondente do `CONTEXT.md` ainda não tem resposta, pergunte ao usuário **uma única vez**, grave a resposta lá, e nunca mais pergunte.
- Respeite a resposta mesmo que você, agente, ache que outra escolha seria melhor prática — não é sua decisão insistir.
- Cada agente que tem uma dessas perguntas sob sua responsabilidade (`orchestrator-architect` para estratégia de branch, `devops-secops-engineer` para CI/hook/release/storage, `backend-architect` para convenções de banco de dados, `data-telemetry-architect` para observabilidade) referencia este princípio em vez de reexplicá-lo.