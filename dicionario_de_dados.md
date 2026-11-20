# Dicionário de Dados — Banco `gestec` (SGOS / GesTec)

3ª Avaliação de Banco de Dados Relacional — SGBD: **MySQL 8** (compatível com MariaDB 10.6+).

Charset de todas as tabelas: `utf8mb4` / collation `utf8mb4_unicode_ci`. Engine: `InnoDB`.

**Legenda:** PK = chave primária · FK = chave estrangeira · UQ = valor único · NN = obrigatório (NOT NULL) · AI = AUTO_INCREMENT

## Sumário

1. [clientes](#clientes) — Empresas atendidas pela ALTAVE (base de clientes).
2. [locais_operacionais](#locais_operacionais) — Ativos/locais operacionais de cada cliente onde os serviços são executados (plataforma offshore, base terrestre ou site).
3. [departamentos](#departamentos) — Setores da empresa que executam as O.S. (Hardware, Compras, SST etc.).
4. [funcionarios](#funcionarios) — Colaboradores que acessam o sistema, com perfil de gestor, analista ou técnico.
5. [projetos](#projetos) — Projetos de implantação de um cliente; agrupam as O.S. relacionadas.
6. [projetos_departamentos](#projetos_departamentos) — Associativa (N:N): departamentos envolvidos em cada projeto.
7. [sla_config](#sla_config) — Prazo padrão de SLA, em dias úteis, para cada combinação de tipo de O.S. e criticidade.
8. [feriados](#feriados) — Feriados desconsiderados na contagem de dias úteis do SLA.
9. [ordens_servico](#ordens_servico) — Ordens de serviço (O.S.): solicitações de instalação ou manutenção e todo o seu ciclo de vida.
10. [equipes](#equipes) — Associativa (N:N): funcionários que compõem a equipe de cada O.S.
11. [apontamento_horas](#apontamento_horas) — Horas trabalhadas por funcionário em cada O.S. (US#2.7).
12. [anexos](#anexos) — Metadados dos arquivos (fotos, laudos, documentos) anexados às O.S.; o arquivo fica no storage.
13. [auditoria](#auditoria) — Histórico de alterações das O.S. (quem alterou, o quê, valor antigo e novo).
14. [auditoria_projetos](#auditoria_projetos) — Histórico de alterações dos projetos.
15. [travas](#travas) — Tabela técnica usada pela API como trava (lock) de concorrência dentro de transações.

---

## 1. clientes

Empresas atendidas pela ALTAVE (base de clientes).

| Campo | Tipo | Chave | NN | Padrão | Descrição |
|---|---|---|---|---|---|
| id | `INT` | PK AI | Sim |  | Identificador do cliente. |
| nome | `VARCHAR(191)` | UQ | Sim |  | Nome fantasia do cliente. |
| razao_social | `VARCHAR(191)` | UQ | Sim |  | Razão social (nome jurídico). |
| ramo_atuacao | `VARCHAR(191)` |  | Sim |  | Ramo de atuação (ex.: Óleo e Gás, Mineração). |
| ativo | `BOOLEAN` |  | Sim | TRUE | Indica se o cliente está ativo (exclusão lógica). |

Registros no script de carga (`02_inserts.sql`): **50**

---

## 2. locais_operacionais

Ativos/locais operacionais de cada cliente onde os serviços são executados (plataforma offshore, base terrestre ou site).

| Campo | Tipo | Chave | NN | Padrão | Descrição |
|---|---|---|---|---|---|
| id | `INT` | PK AI | Sim |  | Identificador do local. |
| cliente_id | `INT` | FK → clientes(id) | Sim |  | Cliente dono do local. |
| descricao | `TEXT` |  | Sim |  | Descrição/identificação do local. |
| tipo | `enum('offshore','terrestre','site')` |  | Sim |  | Tipo do local: offshore, terrestre ou site. |

Registros no script de carga (`02_inserts.sql`): **66**

---

## 3. departamentos

Setores da empresa que executam as O.S. (Hardware, Compras, SST etc.).

| Campo | Tipo | Chave | NN | Padrão | Descrição |
|---|---|---|---|---|---|
| id | `INT` | PK AI | Sim |  | Identificador do departamento. |
| responsavel_id | `INT` | FK → funcionarios(id) | Não | NULL | Funcionário líder do departamento. |
| nome | `VARCHAR(191)` |  | Sim |  | Nome do departamento. |

Registros no script de carga (`02_inserts.sql`): **15**

---

## 4. funcionarios

Colaboradores que acessam o sistema, com perfil de gestor, analista ou técnico.

| Campo | Tipo | Chave | NN | Padrão | Descrição |
|---|---|---|---|---|---|
| id | `INT` | PK AI | Sim |  | Identificador do funcionário. |
| departamento_id | `INT` | FK → departamentos(id) | Sim |  | Departamento em que o funcionário está lotado. |
| usuario | `VARCHAR(191)` | UQ | Sim |  | Login de acesso ao sistema. |
| senha_hash | `VARCHAR(191)` |  | Sim |  | Senha criptografada (hash bcrypt). |
| nome | `VARCHAR(191)` |  | Sim |  | Nome completo. |
| tipo | `enum('gestor','analista','tecnico')` |  | Sim | tecnico | Perfil de acesso: gestor, analista ou tecnico. |
| ativo | `BOOLEAN` |  | Sim | TRUE | Indica se o funcionário está ativo (exclusão lógica). |

Registros no script de carga (`02_inserts.sql`): **64**

---

## 5. projetos

Projetos de implantação de um cliente; agrupam as O.S. relacionadas.

| Campo | Tipo | Chave | NN | Padrão | Descrição |
|---|---|---|---|---|---|
| id | `INT` | PK AI | Sim |  | Identificador do projeto. |
| cliente_id | `INT` | FK → clientes(id) | Sim |  | Cliente do projeto. |
| data_fim | `DATETIME(6)` |  | Não | NULL | Data de término do projeto. |
| data_inicio | `DATETIME(6)` |  | Não | NULL | Data de início da execução. |
| status | `enum('em_planejamento','em_andamento','pausado','concluido')` |  | Sim | em_planejamento | Situação: em_planejamento, em_andamento, pausado ou concluido. |
| nome | `VARCHAR(191)` |  | Sim |  | Nome do projeto. |
| ativo | `BOOLEAN` |  | Sim | TRUE | Indica se o projeto está ativo (exclusão lógica). |

Registros no script de carga (`02_inserts.sql`): **50**

---

## 6. projetos_departamentos

Associativa (N:N): departamentos envolvidos em cada projeto.

| Campo | Tipo | Chave | NN | Padrão | Descrição |
|---|---|---|---|---|---|
| projeto_id | `INT` | PK FK → projetos(id) | Sim |  | Projeto. |
| departamento_id | `INT` | PK FK → departamentos(id) | Sim |  | Departamento envolvido no projeto. |

Registros no script de carga (`02_inserts.sql`): **117**

---

## 7. sla_config

Prazo padrão de SLA, em dias úteis, para cada combinação de tipo de O.S. e criticidade.

| Campo | Tipo | Chave | NN | Padrão | Descrição |
|---|---|---|---|---|---|
| id | `INT` | PK AI | Sim |  | Identificador da configuração. |
| tipo | `enum('instalacao','manutencao')` |  | Sim |  | Tipo de O.S.: instalacao ou manutencao. |
| criticidade | `enum('baixo','medio','alto','muito_alto','urgente')` |  | Sim |  | Criticidade: baixo, medio, alto, muito_alto ou urgente. |
| prazo_dias_uteis | `INT` |  | Não | NULL | Prazo padrão em dias úteis (NULL = sem prazo padrão, definido manualmente). |

**Restrições e índices adicionais:**

- **UNIQUE** `config_unica` (tipo, criticidade)
- **CHECK** `prazo_valido`: `prazo_dias_uteis is null or prazo_dias_uteis > 0`

Registros no script de carga (`02_inserts.sql`): **10**

---

## 8. feriados

Feriados desconsiderados na contagem de dias úteis do SLA.

| Campo | Tipo | Chave | NN | Padrão | Descrição |
|---|---|---|---|---|---|
| id | `INT` | PK AI | Sim |  | Identificador do feriado. |
| data | `DATE` | UQ | Sim |  | Data do feriado. |
| descricao | `VARCHAR(191)` |  | Sim |  | Nome do feriado. |
| nacional | `BOOLEAN` |  | Sim | FALSE | TRUE se nacional; FALSE se estadual/municipal. |

Registros no script de carga (`02_inserts.sql`): **60**

---

## 9. ordens_servico

Ordens de serviço (O.S.): solicitações de instalação ou manutenção e todo o seu ciclo de vida.

| Campo | Tipo | Chave | NN | Padrão | Descrição |
|---|---|---|---|---|---|
| id | `INT` | PK AI | Sim |  | Identificador (número) da O.S. |
| departamento_id | `INT` | FK → departamentos(id) | Sim |  | Departamento que executa a O.S. |
| cliente_id | `INT` | FK → clientes(id) | Não | NULL | Cliente atendido. |
| solicitante_id | `INT` | FK → funcionarios(id) | Sim |  | Funcionário que abriu a O.S. |
| responsavel_id | `INT` | FK → funcionarios(id) | Não | NULL | Técnico responsável pela execução. |
| projeto_id | `INT` | FK → projetos(id) | Não | NULL | Projeto ao qual a O.S. pertence. |
| anterior_id | `INT` | FK → ordens_servico(id) | Não | NULL | O.S. anterior em caso de reincidência (autorrelacionamento). |
| ativo_id | `INT` | FK → locais_operacionais(id) | Não | NULL | Local operacional atendido. |
| sla_config_id | `INT` | FK → sla_config(id) | Não | NULL | Configuração de SLA aplicada (quando automática). |
| titulo | `VARCHAR(191)` |  | Sim |  | Título resumido da solicitação. |
| descricao | `TEXT` |  | Sim |  | Descrição detalhada do problema/serviço. |
| parecer_tecnico | `TEXT` |  | Não | NULL | Parecer técnico registrado pelo responsável. |
| tipo | `enum('instalacao','manutencao')` |  | Sim | instalacao | Tipo: instalacao ou manutencao. |
| criticidade | `enum('baixo','medio','alto','muito_alto','urgente')` |  | Sim | medio | Criticidade: baixo, medio, alto, muito_alto ou urgente. |
| status | `enum('em_andamento','aguardando','validacao_testes','bloqueado','concluido')` |  | Sim | em_andamento | Situação: em_andamento, aguardando, validacao_testes, bloqueado ou concluido. |
| data_criacao | `DATETIME(6)` |  | Sim | CURRENT_TIMESTAMP(6) | Data/hora de abertura. |
| data_inicio | `DATETIME(6)` |  | Não | NULL | Data/hora em que a execução começou (preenchida por trigger). |
| data_fim | `DATETIME(6)` |  | Não | NULL | Data/hora de conclusão (preenchida por trigger). |
| data_limite_sla | `DATETIME(6)` |  | Não | NULL | Prazo final de atendimento (SLA). |
| prazo_dias_uteis | `INT` |  | Não | NULL | Prazo em dias úteis usado no cálculo do SLA. |
| sla_manual | `BOOLEAN` |  | Sim | FALSE | TRUE quando o prazo foi definido manualmente. |
| justificativa_sla_manual | `TEXT` |  | Não | NULL | Justificativa obrigatória quando o SLA é manual. |
| ativo | `BOOLEAN` |  | Sim | TRUE | Indica se a O.S. está ativa (exclusão lógica). |

**Restrições e índices adicionais:**

- **CHECK** `prazo_dias_uteis_valido`: `prazo_dias_uteis is null or prazo_dias_uteis > 0`
- **CHECK** `justificativa_sla_manual_obrigatoria`: `sla_manual = 0 or justificativa_sla_manual is not null and char_length(trim(justificativa_sla_manual)) > 0`
- **Índice** `idx_os_criticidade_limite` (criticidade, data_limite_sla)
- **Índice** `idx_os_departamento_status` (departamento_id, status)
- **Índice** `idx_os_projeto` (projeto_id)
- **Índice** `idx_os_responsavel_status` (responsavel_id, status)

Registros no script de carga (`02_inserts.sql`): **120**

---

## 10. equipes

Associativa (N:N): funcionários que compõem a equipe de cada O.S.

| Campo | Tipo | Chave | NN | Padrão | Descrição |
|---|---|---|---|---|---|
| funcionario_id | `INT` | PK FK → funcionarios(id) | Sim |  | Funcionário membro da equipe. |
| os_id | `INT` | PK FK → ordens_servico(id) | Sim |  | O.S. atendida pela equipe. |

Registros no script de carga (`02_inserts.sql`): **209**

---

## 11. apontamento_horas

Horas trabalhadas por funcionário em cada O.S. (US#2.7).

| Campo | Tipo | Chave | NN | Padrão | Descrição |
|---|---|---|---|---|---|
| id | `INT` | PK AI | Sim |  | Identificador do lançamento. |
| funcionario_id | `INT` | FK → funcionarios(id) | Sim |  | Funcionário que trabalhou. |
| os_id | `INT` | FK → ordens_servico(id) | Sim |  | O.S. trabalhada. |
| data_trabalho | `DATE` |  | Sim |  | Dia em que o trabalho foi realizado. |
| duracao_minutos | `INT` |  | Sim |  | Tempo trabalhado, em minutos. |
| descricao | `TEXT` |  | Não | NULL | Atividade realizada. |
| data_criacao | `DATETIME(6)` |  | Sim | CURRENT_TIMESTAMP(6) | Data/hora do lançamento no sistema. |

**Restrições e índices adicionais:**

- **CHECK** `duracao_apontamento_positiva`: `duracao_minutos > 0`
- **Índice** `idx_apontamentos_funcionario_data` (funcionario_id, data_trabalho)

Registros no script de carga (`02_inserts.sql`): **260**

---

## 12. anexos

Metadados dos arquivos (fotos, laudos, documentos) anexados às O.S.; o arquivo fica no storage.

| Campo | Tipo | Chave | NN | Padrão | Descrição |
|---|---|---|---|---|---|
| id | `INT` | PK AI | Sim |  | Identificador do anexo. |
| os_id | `INT` | FK → ordens_servico(id) | Sim |  | O.S. à qual o arquivo pertence. |
| funcionario_id | `INT` | FK → funcionarios(id) | Sim |  | Funcionário que enviou o arquivo. |
| nome | `VARCHAR(255)` |  | Sim |  | Nome original do arquivo. |
| tamanho_bytes | `BIGINT` |  | Sim |  | Tamanho do arquivo em bytes (máx. 50 MB). |
| caminho | `VARCHAR(500)` | UQ | Sim |  | Caminho do arquivo no storage. |
| tipo | `VARCHAR(100)` |  | Sim |  | Tipo MIME (image/png, image/jpeg, image/webp, application/pdf). |
| relato | `VARCHAR(2000)` |  | Não | NULL | Comentário sobre o anexo (até 2000 caracteres). |
| data_upload | `DATETIME(6)` |  | Sim | CURRENT_TIMESTAMP(6) | Data/hora do envio. |

**Restrições e índices adicionais:**

- **CHECK** `tamanho_valido`: `tamanho_bytes >= 0`
- **CHECK** `anexos_tamanho_maximo`: `tamanho_bytes <= 52428800`
- **CHECK** `anexos_relato_tamanho`: `relato is null or char_length(relato) <= 2000`
- **Índice** `idx_anexos_os_data` (os_id, data_upload)

Registros no script de carga (`02_inserts.sql`): **60**

---

## 13. auditoria

Histórico de alterações das O.S. (quem alterou, o quê, valor antigo e novo).

| Campo | Tipo | Chave | NN | Padrão | Descrição |
|---|---|---|---|---|---|
| id | `INT` | PK AI | Sim |  | Identificador do registro. |
| os_id | `INT` | FK → ordens_servico(id) | Sim |  | O.S. alterada. |
| funcionario_id | `INT` | FK → funcionarios(id) | Sim |  | Funcionário que fez a alteração. |
| data_modificacao | `DATETIME(6)` |  | Sim | CURRENT_TIMESTAMP(6) | Data/hora da alteração. |
| acao | `enum('insercao','atualizacao','exclusao')` |  | Sim |  | Ação: insercao, atualizacao ou exclusao. |
| tipo_entidade | `VARCHAR(191)` |  | Sim | ordem_servico | Entidade auditada (padrão 'ordem_servico'). |
| campo_alterado | `VARCHAR(191)` |  | Não | NULL | Nome do campo alterado. |
| dado_antigo | `TEXT` |  | Não | NULL | Valor antes da alteração. |
| dado_novo | `TEXT` |  | Não | NULL | Valor depois da alteração. |
| justificativa | `TEXT` |  | Não | NULL | Motivo/observação da alteração. |

**Restrições e índices adicionais:**

- **Índice** `idx_auditoria_os_data` (os_id, data_modificacao)

Registros no script de carga (`02_inserts.sql`): **277**

---

## 14. auditoria_projetos

Histórico de alterações dos projetos.

| Campo | Tipo | Chave | NN | Padrão | Descrição |
|---|---|---|---|---|---|
| id | `INT` | PK AI | Sim |  | Identificador do registro. |
| projeto_id | `INT` | FK → projetos(id) | Sim |  | Projeto alterado. |
| funcionario_id | `INT` | FK → funcionarios(id) | Sim |  | Funcionário que fez a alteração. |
| data_modificacao | `DATETIME(6)` |  | Sim | CURRENT_TIMESTAMP(6) | Data/hora da alteração. |
| acao | `enum('insercao','atualizacao','exclusao')` |  | Sim |  | Ação: insercao, atualizacao ou exclusao. |
| campo_alterado | `VARCHAR(191)` |  | Não | NULL | Nome do campo alterado. |
| dado_antigo | `TEXT` |  | Não | NULL | Valor antes da alteração. |
| dado_novo | `TEXT` |  | Não | NULL | Valor depois da alteração. |
| justificativa | `TEXT` |  | Não | NULL | Motivo/observação da alteração. |

**Restrições e índices adicionais:**

- **Índice** `idx_auditoria_projetos_data` (projeto_id, data_modificacao)

Registros no script de carga (`02_inserts.sql`): **114**

---

## 15. travas

Tabela técnica usada pela API como trava (lock) de concorrência dentro de transações.

| Campo | Tipo | Chave | NN | Padrão | Descrição |
|---|---|---|---|---|---|
| chave | `VARCHAR(100)` | PK | Sim |  | Nome da trava (ex.: 'gestores'). |

Registros no script de carga (`02_inserts.sql`): **0**

---

## Objetos programados (script `03_programacao.sql`)

| Tipo | Nome | Finalidade |
|---|---|---|
| Function | fn_calcular_data_sla | Data limite do prazo em dias úteis (pula fins de semana e feriados) |
| Function | fn_total_horas_os | Total de horas lançadas em uma O.S. |
| Function | fn_status_sla | Situação do prazo: NO PRAZO, ATRASADA, CONCLUIDA NO PRAZO, CONCLUIDA COM ATRASO, SEM PRAZO |
| Function | fn_qtd_os_abertas_funcionario | Quantidade de O.S. abertas de um técnico |
| Function | fn_percentual_conclusao_projeto | % de O.S. concluídas de um projeto |
| Function | fn_tempo_medio_atendimento_dep | Tempo médio (dias) entre abertura e conclusão das O.S. de um departamento |
| View | vw_os_detalhada | O.S. com nomes de departamento, solicitante, responsável e cliente |
| View | vw_horas_por_funcionario | Total de horas por funcionário |
| View | vw_os_atrasadas | O.S. abertas com prazo vencido |
| Procedure | sp_abrir_os | Abre uma O.S. (só gestor ou analista) |
| Procedure | sp_alterar_status_os | Altera o status (concluída não muda; parecer obrigatório para concluir) |
| Procedure | sp_atribuir_responsavel | Atribui técnico do mesmo departamento à O.S. |
| Procedure | sp_registrar_horas | Lança horas na O.S. (usada pela API — Parte 5) |
| Procedure | sp_relatorio_cliente | Relatório das O.S. de um cliente (usa cursor) |
| Procedure | sp_resumo_departamentos | Total de O.S., abertas e concluídas por departamento |
| Trigger | trg_os_bi_sla | Antes de inserir O.S.: calcula o prazo das O.S. de manutenção |
| Trigger | trg_os_bu_datas | Antes de atualizar O.S.: preenche data_inicio e data_fim |
| Trigger | trg_clientes_bu_inativar | Antes de atualizar cliente: impede inativar cliente com O.S. abertas |
| Trigger | trg_projetos_bu_datas | Antes de atualizar projeto: preenche data_inicio e data_fim |
| Trigger | trg_horas_bi_validacao | Antes de inserir horas: bloqueia data futura e mais de 24h/dia |
| Trigger | trg_anexos_bi_limite | Antes de inserir anexo: máximo de 10 anexos por O.S. |
