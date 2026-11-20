# Passo a passo — o que fazer até a entrega (23/11)

Checklist completo, na ordem. Marque cada item conforme for fazendo.
Os prints vão para o documento final (Etapa 6).

> Pré-requisito: banco `gestec` criado e conectado no DBeaver (ver [COMO_RODAR.md](COMO_RODAR.md), passos 3 e 4).

---

## Etapa 1 — Tabelas e dados (Partes 1 e 2)

- [x] Rodar `scripts/01_create_tables.sql` (já feito)
- [ ] Rodar `scripts/02_inserts.sql` inteiro com **Alt+X**
  - 📸 **PRINT DML-1:** a tabela de contagem que aparece no final (registros por tabela)

> Sempre que quiser "zerar" os dados (por exemplo, depois dos testes da Etapa 3), é só rodar o `02_inserts.sql` de novo.

---

## Etapa 2 — Criar procedures, functions, triggers e views (Parte 3)

- [ ] No DBeaver, rode `scripts/03_programacao.sql` inteiro com **Alt+X**.

> Se aparecer o erro *"You do not have the SUPER privilege and binary logging is enabled"*, rode no terminal
> `sudo mariadb -e "SET GLOBAL log_bin_trust_function_creators = 1;"` e rode o script de novo.

---

## Etapa 3 — Testes e prints (Parte 3)

Abra `scripts/04_testes.sql` e rode **um bloco por vez, na ordem, sempre na mesma aba**
(selecione as linhas do bloco e aperte **Alt+X**). Cada bloco = **1 print**.

| Bloco | Print |
|---|---|
| F1 a F6 | 6 prints, um de cada function |
| V1 a V3 | 3 prints, um de cada view |
| P1, P3, P4, P2, P5, P6 | 6 prints, um de cada procedure (P1 cria a O.S. usada em P3, P4 e P2) |
| T3, T4, T5, T6 | 4 prints. T3, T5 e T6 mostram uma **mensagem de erro** — é o trigger bloqueando, então está certo |

**T1 e T2 não têm bloco próprio:** o print de P1 mostra o prazo (`data_limite_sla`) calculado pelo T1, e os prints de
P3 e P2 mostram `data_inicio` e `data_fim` preenchidas pelo T2.

No documento, para cada item: **problema** (é o comentário acima de cada objeto no `03_programacao.sql`),
**código** (copie do `03_programacao.sql`) e **print**.

Ao terminar, rode o `02_inserts.sql` de novo para voltar os dados ao normal.

---

## Etapa 4 — Dicionário de dados (Parte 4)

- [ ] Pronto em [`dicionario_de_dados.md`](dicionario_de_dados.md): todas as tabelas com campos, tipos, PK, FK,
  restrições (UNIQUE, CHECK, índices) e descrição.
- No documento final, cite o arquivo (o enunciado pede que fique em arquivo separado).

---

## Etapa 5 — Conexão da API com o banco (Parte 5)

**Funcionalidade escolhida:** US#2.7 — *registrar horas trabalhadas na O.S.* (antes ela só existia como
demonstração na tela; agora grava no banco).

| Camada | Arquivo | O que usa do banco |
|---|---|---|
| Banco | `03_programacao.sql` | procedure `sp_registrar_horas`, function `fn_total_horas_os`, trigger `trg_horas_bi_validacao` |
| API | `sgos-mysql/backend/src/repositories/repositoryApontamento.ts` | `CALL sp_registrar_horas(...)` e `SELECT fn_total_horas_os(...)` |
| API | `sgos-mysql/backend/src/services/serviceApontamento.ts`, `controllers/controllerApontamento.ts`, `routes/routeOrdemServico.ts` | rotas `GET` e `POST /ordens-servico/:id/horas` |
| Tela | `sgos-mysql/frontend/src/services/apontamento.ts`, `components/ordens/OrdemServicoDetalhesModal.tsx` | botão "Lançar horas" e aba "Horas registradas" |

**Como rodar e testar:**

1. Backend — no terminal:
   ```bash
   cd ~/Documents/pamela/banco_gestec/sgos-mysql/backend
   cp .env.example .env
   ```
   Edite o `.env` e troque nas 3 URLs `gestec:SENHA_URL_ENCODED` pela sua senha do usuário `gestec`, e o `JWT_SECRET`
   por qualquer texto com 32+ caracteres. Depois:
   ```bash
   npm install
   npx prisma generate
   npm run dev
   ```
2. Frontend — em **outro** terminal:
   ```bash
   cd ~/Documents/pamela/banco_gestec/sgos-mysql/frontend
   cp .env.example .env
   npm install
   npm run dev
   ```
3. Abra o endereço mostrado (geralmente `http://localhost:5173`) e entre com **`tecnico.bdr`** / **`Senha@123`**.
4. Descubra em quais O.S. o `tecnico.bdr` pode lançar horas — rode no DBeaver:
   ```sql
   SELECT o.id, o.titulo, o.status
     FROM ordens_servico o
     JOIN equipes e      ON e.os_id = o.id
     JOIN funcionarios f ON f.id = e.funcionario_id
    WHERE f.usuario = 'tecnico.bdr' AND o.status <> 'concluido' AND o.ativo = TRUE;
   ```
5. No sistema, abra uma dessas O.S. → **Lançar horas** → preencha → **Registrar**.
   - 📸 **PRINT API-1:** o formulário preenchido.
   - 📸 **PRINT API-2:** a aba **Horas registradas** com o lançamento e o **Tempo registrado** atualizado (total vindo de `fn_total_horas_os`).
6. Tente lançar **24 horas** no mesmo dia (passa do limite somando o que já existe).
   - 📸 **PRINT API-3:** a mensagem de erro na tela — ela vem do **trigger do banco**.
7. Confira no DBeaver que gravou de verdade:
   ```sql
   SELECT a.*, fn_total_horas_os(a.os_id) AS total_da_os
     FROM apontamento_horas a
    ORDER BY a.id DESC LIMIT 5;
   ```
   - 📸 **PRINT API-4:** o registro novo no banco.
8. Para o documento, copie também o trecho do `repositoryApontamento.ts` com o `CALL sp_registrar_horas` e o
   `SELECT fn_total_horas_os` (mostra a API chamando a procedure e a function).

---

## Etapa 6 — Documento final (para entregar no Teams)

Sugestão de estrutura:

1. **Capa** — nomes, turma, professor, data.
2. **Introdução** — o SGOS/GesTec em 1 parágrafo (pode usar o README de `sgos-mysql/`).
3. **Parte 1 — Modelos**
   - Modelo conceitual — ⚠️ o enunciado pede **BRModelo**. O de vocês está no Lucid (notação de Chen); confirme com o
     professor se pode ser do Lucid ou redesenhe no BRModelo.
   - Modelo lógico — exporte do Lucid ("GesTec – Modelo Lógico", já atualizado para MySQL) como imagem.
4. **Parte 2 — DML** — explique a carga (dados fictícios, 50+ por tabela, exceções: `sla_config`, `departamentos`,
   `travas`), cite o arquivo `02_inserts.sql` e coloque o PRINT DML-1.
5. **Parte 3 — Programação** — para cada item (6 functions, 6 procedures, 6 triggers e as 3 views): problema, código, print.
6. **Parte 4 — Dicionário de dados** — cite `dicionario_de_dados.md`.
7. **Parte 5 — Conexão com a API** — funcionalidade escolhida, tabela de arquivos da Etapa 5, trecho do código e PRINTS API-1 a API-4.
8. **Arquivos entregues** — `01_create_tables.sql`, `02_inserts.sql`, `03_programacao.sql`, `04_testes.sql`,
   `dicionario_de_dados.md`.

---

## Etapa 7 — Enviar para o GitHub (você faz)

```bash
cd ~/Documents/pamela/banco_gestec
git add .
git commit -m "Programação do banco, dicionário de dados e registro de horas (Parte 5)"
git push
```
