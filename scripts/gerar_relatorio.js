#!/usr/bin/env node
/*
 * Gera docs/RELATORIO.md puxando tudo de dentro do projeto:
 *   - código dos objetos        <- scripts/03_programacao.sql
 *   - consultas de teste        <- scripts/04_testes.sql
 *   - prints                    <- prints/<pasta>/<ID>.jpeg
 *   - modelos                   <- docs/modelos/modelo_conceitual.* e modelo_logico.*
 *   - trecho da API (Parte 5)   <- sgos-mysql/backend/src/repositories/repositoryApontamento.ts
 *
 * Como usar (na raiz do repositório):   node scripts/gerar_relatorio.js
 * Pode rodar quantas vezes quiser: ele sempre recria o docs/RELATORIO.md.
 */
const fs = require("fs");
const path = require("path");

// ======================= EDITE AQUI (capa) =======================
const CAPA = {
  alunos: "Marina Duque e Pamela Iwabuchi",
  turma: "2DSM",
  professor: "Juliana Pasquini",
  data: "23/11/2026",
};
// =================================================================

const RAIZ = path.join(__dirname, "..");
const F = "`".repeat(3);

const ITENS = [
  {
    "id": "F1",
    "tipo": "FUNCTION",
    "nome": "fn_calcular_data_sla",
    "pasta": "01_functions",
    "problema": "O prazo (SLA) das O.S. de manutenção é contado em dias úteis. A função calcula a data limite pulando sábados, domingos e feriados.",
    "conceitos": "Laço WHILE e subconsulta na tabela feriados."
  },
  {
    "id": "F2",
    "tipo": "FUNCTION",
    "nome": "fn_total_horas_os",
    "pasta": "01_functions",
    "problema": "Saber quantas horas já foram trabalhadas em uma O.S., somando os apontamentos.",
    "conceitos": "Função de grupo SUM."
  },
  {
    "id": "F3",
    "tipo": "FUNCTION",
    "nome": "fn_status_sla",
    "pasta": "01_functions",
    "problema": "Mostrar se a O.S. está no prazo, atrasada, concluída no prazo, concluída com atraso ou sem prazo definido.",
    "conceitos": "Estrutura IF / ELSEIF."
  },
  {
    "id": "F4",
    "tipo": "FUNCTION",
    "nome": "fn_qtd_os_abertas_funcionario",
    "pasta": "01_functions",
    "problema": "Medir a carga de trabalho de um técnico, contando as O.S. que ainda estão abertas com ele.",
    "conceitos": "Função de grupo COUNT."
  },
  {
    "id": "F5",
    "tipo": "FUNCTION",
    "nome": "fn_percentual_conclusao_projeto",
    "pasta": "01_functions",
    "problema": "Acompanhar o andamento de um projeto pelo percentual de O.S. concluídas.",
    "conceitos": "COUNT e subconsultas."
  },
  {
    "id": "F6",
    "tipo": "FUNCTION",
    "nome": "fn_tempo_medio_atendimento_dep",
    "pasta": "01_functions",
    "problema": "Comparar os departamentos pelo tempo médio, em dias, entre a abertura e a conclusão das O.S.",
    "conceitos": "INNER JOIN e função de grupo AVG."
  },
  {
    "id": "V1",
    "tipo": "VIEW",
    "nome": "vw_os_detalhada",
    "pasta": "02_views",
    "problema": "Nas O.S. aparecem apenas os IDs. A view mostra os nomes do departamento, do solicitante, do responsável e do cliente.",
    "conceitos": "INNER JOIN (departamento e solicitante sempre existem) e LEFT JOIN (responsável e cliente podem estar vazios)."
  },
  {
    "id": "V2",
    "tipo": "VIEW",
    "nome": "vw_horas_por_funcionario",
    "pasta": "02_views",
    "problema": "Ver o total de horas de cada funcionário, inclusive de quem ainda não lançou horas (aparece com 0).",
    "conceitos": "RIGHT JOIN, GROUP BY e funções de grupo (COUNT, SUM)."
  },
  {
    "id": "V3",
    "tipo": "VIEW",
    "nome": "vw_os_atrasadas",
    "pasta": "02_views",
    "problema": "Listar as O.S. ainda abertas cujo prazo já venceu.",
    "conceitos": "View construída sobre outra view (vw_os_detalhada)."
  },
  {
    "id": "P1",
    "tipo": "PROCEDURE",
    "nome": "sp_abrir_os",
    "pasta": "03_procedures",
    "problema": "Abrir uma O.S. garantindo que o solicitante seja gestor ou analista, e devolver o ID criado. O prazo (SLA) é calculado pelo trigger T1.",
    "conceitos": "SIGNAL (erro personalizado), subconsulta com EXISTS e parâmetro OUT."
  },
  {
    "id": "P2",
    "tipo": "PROCEDURE",
    "nome": "sp_alterar_status_os",
    "pasta": "03_procedures",
    "problema": "Mudar o status de uma O.S. respeitando as regras: O.S. concluída não muda mais e, para concluir, o parecer técnico é obrigatório.",
    "conceitos": "SIGNAL e IF."
  },
  {
    "id": "P3",
    "tipo": "PROCEDURE",
    "nome": "sp_atribuir_responsavel",
    "pasta": "03_procedures",
    "problema": "Atribuir um técnico a uma O.S. O técnico precisa ser do mesmo departamento da O.S. e passa a fazer parte da equipe.",
    "conceitos": "Subconsultas, SIGNAL e INSERT IGNORE."
  },
  {
    "id": "P4",
    "tipo": "PROCEDURE",
    "nome": "sp_registrar_horas",
    "pasta": "03_procedures",
    "problema": "O técnico registra as horas gastas em uma O.S. A O.S. não pode estar concluída e o funcionário precisa ser o responsável ou fazer parte da equipe. É a procedure usada na Parte 5 (conexão com a API).",
    "conceitos": "SIGNAL e subconsultas com EXISTS."
  },
  {
    "id": "P5",
    "tipo": "PROCEDURE",
    "nome": "sp_relatorio_cliente",
    "pasta": "03_procedures",
    "problema": "Gerar o relatório de um cliente com as suas O.S., as horas trabalhadas e a situação do prazo de cada uma.",
    "conceitos": "CURSOR (percorre as O.S. uma a uma), HANDLER, tabela temporária e uso das functions F2 e F3."
  },
  {
    "id": "P6",
    "tipo": "PROCEDURE",
    "nome": "sp_resumo_departamentos",
    "pasta": "03_procedures",
    "problema": "Ver, por departamento, quantas O.S. existem, quantas estão abertas e quantas foram concluídas.",
    "conceitos": "LEFT JOIN, GROUP BY e funções de grupo (COUNT, SUM)."
  },
  {
    "id": "T1",
    "tipo": "TRIGGER",
    "nome": "trg_os_bi_sla",
    "quando": "antes de inserir uma O.S.",
    "pasta": "04_triggers",
    "problema": "Toda O.S. de manutenção precisa nascer com o prazo calculado conforme a criticidade (tabela sla_config), sem depender de quem cadastra.",
    "conceitos": "BEFORE INSERT e uso da function F1."
  },
  {
    "id": "T2",
    "tipo": "TRIGGER",
    "nome": "trg_os_bu_datas",
    "quando": "antes de atualizar uma O.S.",
    "pasta": "04_triggers",
    "problema": "Preencher sozinho a data de início (quando a O.S. recebe um responsável) e a data de fim (quando é concluída).",
    "conceitos": "BEFORE UPDATE."
  },
  {
    "id": "T3",
    "tipo": "TRIGGER",
    "nome": "trg_clientes_bu_inativar",
    "quando": "antes de atualizar um cliente",
    "pasta": "04_triggers",
    "problema": "Não deixar inativar um cliente que ainda tem O.S. abertas.",
    "conceitos": "BEFORE UPDATE, subconsulta com EXISTS e SIGNAL. O retorno esperado é a mensagem de erro."
  },
  {
    "id": "T4",
    "tipo": "TRIGGER",
    "nome": "trg_projetos_bu_datas",
    "quando": "antes de atualizar um projeto",
    "pasta": "04_triggers",
    "problema": "Registrar sozinho as datas de início e fim do projeto quando o status muda para em_andamento ou concluido.",
    "conceitos": "BEFORE UPDATE."
  },
  {
    "id": "T5",
    "tipo": "TRIGGER",
    "nome": "trg_horas_bi_validacao",
    "quando": "antes de inserir horas",
    "pasta": "04_triggers",
    "problema": "Impedir o lançamento de horas em data futura e impedir mais de 24 horas no mesmo dia para o mesmo funcionário.",
    "conceitos": "BEFORE INSERT, subconsulta com SUM e SIGNAL. O retorno esperado é a mensagem de erro."
  },
  {
    "id": "T6",
    "tipo": "TRIGGER",
    "nome": "trg_anexos_bi_limite",
    "quando": "antes de inserir um anexo",
    "pasta": "04_triggers",
    "problema": "Limitar a 10 o número de anexos de cada O.S.",
    "conceitos": "BEFORE INSERT, subconsulta com COUNT e SIGNAL. O retorno esperado é a mensagem de erro."
  }
];

const avisos = { imagens: [], maiusculas: [], objetos: [], testes: [], modelos: [], api: false };

const ler = (rel) => {
  const p = path.join(RAIZ, rel);
  return fs.existsSync(p) ? fs.readFileSync(p, "utf8").replace(/\r\n/g, "\n") : null;
};

const sql03 = ler("scripts/03_programacao.sql");
const sql04 = ler("scripts/04_testes.sql") || "";
if (!sql03) {
  console.error("Não achei scripts/03_programacao.sql. Rode este script de dentro do repositório: node scripts/gerar_relatorio.js");
  process.exit(1);
}

// ---------- código dos objetos (puxado do 03_programacao.sql)
function extrairObjeto(tipo, nome) {
  const re = new RegExp("CREATE\\s+(?:OR\\s+REPLACE\\s+)?" + tipo + "\\s+`?" + nome + "`?\\b", "i");
  const m = re.exec(sql03);
  if (!m) return null;
  const ini = m.index;
  if (tipo === "VIEW") {
    const fim = sql03.indexOf(";", ini);
    return (fim < 0 ? sql03.slice(ini) : sql03.slice(ini, fim + 1)).trim();
  }
  let fim = sql03.indexOf("$$", ini);
  if (fim >= 0) return sql03.slice(ini, fim + 2).trim();
  fim = sql03.indexOf("\nDELIMITER", ini);
  return (fim < 0 ? sql03.slice(ini) : sql03.slice(ini, fim)).trim();
}

// ---------- consultas de teste (puxadas do 04_testes.sql)
function lerTestes(sql) {
  const blocos = [];
  let atual = null;
  for (const linha of sql.split("\n")) {
    const m = /^--\s*([FVPT]\d+)\b/.exec(linha);
    if (m) { atual = { id: m[1], linhas: [] }; blocos.push(atual); continue; }
    if (/^--\s*=+/.test(linha)) { atual = null; continue; }
    if (atual && !/^\s*--/.test(linha)) atual.linhas.push(linha);
  }
  const mapa = {};
  for (const b of blocos) {
    const txt = b.linhas.join("\n").trim();
    if (txt && !mapa[b.id]) mapa[b.id] = txt;
  }
  return mapa;
}
const testes = lerTestes(sql04);

// ---------- imagens (confere se existem e se o nome bate com maiúsculas/minúsculas)
function achaImagem(pasta, id) {
  const dir = path.join(RAIZ, "prints", pasta);
  const lista = fs.existsSync(dir) ? fs.readdirSync(dir) : [];
  for (const ext of ["jpeg", "jpg", "png"]) {
    const nome = `${id}.${ext}`;
    if (lista.includes(nome)) return `../prints/${pasta}/${nome}`;
    const achado = lista.find((f) => f.toLowerCase() === nome.toLowerCase());
    if (achado) {
      avisos.maiusculas.push(`prints/${pasta}/${achado}  (deveria ser ${nome})`);
      return `../prints/${pasta}/${achado}`;
    }
  }
  avisos.imagens.push(`prints/${pasta}/${id}.jpeg`);
  return `../prints/${pasta}/${id}.jpeg`;
}

function achaModelo(nome) {
  for (const ext of ["png", "jpg", "jpeg"]) {
    if (fs.existsSync(path.join(RAIZ, "docs", "modelos", `${nome}.${ext}`))) return `modelos/${nome}.${ext}`;
  }
  avisos.modelos.push(`docs/modelos/${nome}.png`);
  return null;
}

function trechoApi() {
  const rel = "sgos-mysql/backend/src/repositories/repositoryApontamento.ts";
  const src = ler(rel);
  if (!src) { avisos.api = true; return null; }
  const linhas = src.split("\n");
  if (linhas.length <= 120) return { rel, texto: src.trim() };
  const idx = new Set();
  linhas.forEach((l, i) => {
    if (/sp_registrar_horas|fn_total_horas_os/.test(l))
      for (let k = Math.max(0, i - 8); k <= Math.min(linhas.length - 1, i + 8); k++) idx.add(k);
  });
  const ord = [...idx].sort((a, b) => a - b);
  const out = [];
  let prev = -2;
  for (const i of ord) { if (i !== prev + 1) out.push("// ..."); out.push(linhas[i]); prev = i; }
  return { rel, texto: out.join("\n") };
}

// ---------- montagem do markdown
const md = [];
const add = (...x) => md.push(...x);

function blocoItem(it) {
  const titulo = it.quando ? `${it.id} — ${it.nome} (${it.quando})` : `${it.id} — ${it.nome}`;
  add(`#### ${titulo}`, "");
  add(`**Problema:** ${it.problema}`, "");
  add(`**Conceitos:** ${it.conceitos}`, "");
  const codigo = extrairObjeto(it.tipo, it.nome);
  add("**Código SQL** (de [`scripts/03_programacao.sql`](../scripts/03_programacao.sql)):", "");
  if (codigo) add(F + "sql", codigo, F, "");
  else { avisos.objetos.push(`${it.id} ${it.nome}`); add(`> ⚠️ Não encontrei \`${it.nome}\` no 03_programacao.sql.`, ""); }
  if (testes[it.id]) {
    add("**Consulta de teste** (de [`scripts/04_testes.sql`](../scripts/04_testes.sql)):", "");
    add(F + "sql", testes[it.id], F, "");
  } else avisos.testes.push(it.id);
  add("**Retorno obtido:**", "");
  add(`![${it.id}](${achaImagem(it.pasta, it.id)})`, "");
}

const TABELAS = [
  ["feriados", "Feriados desconsiderados na contagem de dias úteis do SLA", "—", 60],
  ["sla_config", "Prazo padrão de SLA (dias úteis) por tipo e criticidade", "—", 10],
  ["departamentos", "Setores da empresa que executam as O.S.", "responsavel_id → funcionarios", 15],
  ["funcionarios", "Colaboradores (gestor, analista ou técnico)", "departamento_id → departamentos", 64],
  ["clientes", "Empresas atendidas", "—", 50],
  ["locais_operacionais", "Locais/ativos dos clientes (offshore, terrestre, site)", "cliente_id → clientes", 66],
  ["projetos", "Projetos de implantação de um cliente", "cliente_id → clientes", 50],
  ["projetos_departamentos", "Associativa N:N entre projetos e departamentos", "projeto_id, departamento_id", 117],
  ["ordens_servico", "Ordens de serviço de instalação e manutenção", "departamento, cliente, solicitante, responsável, projeto, anterior, ativo, sla_config", 120],
  ["equipes", "Associativa N:N entre funcionários e O.S.", "funcionario_id, os_id", 209],
  ["apontamento_horas", "Horas trabalhadas por funcionário em cada O.S.", "funcionario_id, os_id", 260],
  ["anexos", "Metadados dos arquivos anexados às O.S.", "os_id, funcionario_id", 60],
  ["auditoria", "Histórico de alterações das O.S.", "os_id, funcionario_id", 277],
  ["auditoria_projetos", "Histórico de alterações dos projetos", "projeto_id, funcionario_id", 114],
  ["travas", "Tabela técnica de trava (lock) usada pela API", "—", 0],
];

const CHAVES = [
  ["feriados", "id", "—"], ["sla_config", "id", "—"], ["travas", "chave", "—"],
  ["departamentos", "id", "responsavel_id → funcionarios"],
  ["funcionarios", "id", "departamento_id → departamentos"],
  ["clientes", "id", "—"],
  ["locais_operacionais", "id", "cliente_id → clientes"],
  ["projetos", "id", "cliente_id → clientes"],
  ["projetos_departamentos", "projeto_id + departamento_id", "projeto_id → projetos; departamento_id → departamentos"],
  ["ordens_servico", "id", "departamento_id, cliente_id, solicitante_id, responsavel_id, projeto_id, anterior_id (autorrelacionamento), ativo_id, sla_config_id"],
  ["equipes", "funcionario_id + os_id", "funcionario_id → funcionarios; os_id → ordens_servico"],
  ["apontamento_horas", "id", "funcionario_id → funcionarios; os_id → ordens_servico"],
  ["anexos", "id", "os_id → ordens_servico; funcionario_id → funcionarios"],
  ["auditoria", "id", "os_id → ordens_servico; funcionario_id → funcionarios"],
  ["auditoria_projetos", "id", "projeto_id → projetos; funcionario_id → funcionarios"],
];

// Capa
add("# 3ª Avaliação de Banco de Dados Relacional", "");
add("**FATEC — Banco de Dados Relacional — 2º Semestre de 2026**", "");
add("**Projeto SGOS / GesTec** — Sistema de Gestão de Ordens de Serviço (banco de dados em MySQL)", "");
add(`- **Alunos:** ${CAPA.alunos}`, `- **Turma:** ${CAPA.turma}`, `- **Professor:** ${CAPA.professor}`,
    `- **Data de entrega:** ${CAPA.data}`, "- **Repositório:** https://github.com/pamelaiwabuchi/banco_gestec", "", "---", "");

// 1 Introdução
add("## 1. Introdução", "");
add("Este trabalho apresenta a modelagem, a implementação e a programação do banco de dados relacional do SGOS/GesTec (Sistema de Gestão de Ordens de Serviço), tema do projeto API da disciplina.", "");
add("O sistema controla ordens de serviço (O.S.) de instalação e de manutenção abertas para clientes. Ele reúne departamentos, funcionários com perfil de gestor, analista ou técnico, projetos, equipes, apontamento de horas, anexos, prazos de SLA contados em dias úteis e a auditoria das alterações.", "");
add("O banco foi implementado em MySQL (banco `gestec`) e os testes foram executados no MySQL Workbench. Para cada item de programação (functions, views, stored procedures e triggers), este documento mostra o problema que ele resolve, o código SQL e o retorno obtido.", "");
add("### 1.1 Arquivos entregues", "");
add("O script de criação das tabelas, o script de inserção de dados e o dicionário de dados são entregues em arquivos separados:", "");
add("| Arquivo | Conteúdo |", "|---|---|",
  "| [`scripts/01_create_tables.sql`](../scripts/01_create_tables.sql) | Criação das 15 tabelas (DDL) |",
  "| [`scripts/02_inserts.sql`](../scripts/02_inserts.sql) | Inserção de dados fictícios (DML) |",
  "| [`scripts/03_programacao.sql`](../scripts/03_programacao.sql) | 6 functions, 3 views, 6 stored procedures e 6 triggers |",
  "| [`scripts/04_testes.sql`](../scripts/04_testes.sql) | Chamadas de teste de cada objeto, usadas nos prints |",
  "| [`dicionario_de_dados.md`](../dicionario_de_dados.md) | Dicionário de dados (Parte 4) |",
  "| [`docs/PRINTS.md`](PRINTS.md) e `prints/` | Prints dos testes, organizados por tipo de objeto |",
  "| [`sgos-mysql/`](../sgos-mysql) | Sistema SGOS adaptado para MySQL (Parte 5) |", "");

// 2 Parte 1
add("## 2. Parte 1 — Modelos de banco de dados", "");
add("### 2.1 Modelo conceitual", "");
add("O modelo conceitual representa as entidades do SGOS, seus atributos e os relacionamentos entre elas.", "");
const mc = achaModelo("modelo_conceitual");
add(mc ? `![Modelo conceitual](${mc})` : "> ⚠️ Adicione a imagem em `docs/modelos/modelo_conceitual.png`.", "");
add("### 2.2 Modelo lógico", "");
add("O modelo lógico traduz o modelo conceitual para tabelas, com chaves primárias, chaves estrangeiras e os tipos de dados do MySQL.", "");
const ml = achaModelo("modelo_logico");
add(ml ? `![Modelo lógico](${ml})` : "> ⚠️ Adicione a imagem em `docs/modelos/modelo_logico.png`.", "");

// 3 Parte 2
add("## 3. Parte 2 — Criação das tabelas e inserção de dados", "");
add("### 3.1 Criação das tabelas (DDL)", "");
add("O script [`scripts/01_create_tables.sql`](../scripts/01_create_tables.sql) cria as 15 tabelas do banco com chaves primárias, chaves estrangeiras, restrições UNIQUE e CHECK e índices de consulta. Todas as tabelas usam o motor InnoDB e o conjunto de caracteres utf8mb4.", "");
add("As tabelas `departamentos` e `funcionarios` dependem uma da outra (o departamento tem um funcionário responsável e o funcionário pertence a um departamento). Para resolver essa dependência circular, a chave estrangeira do responsável é criada com `ALTER TABLE` depois que `funcionarios` existe.", "");
add("O script pode ser executado novamente: ele apaga e recria as tabelas.", "");
add("### 3.2 Inserção de dados (DML)", "");
add("O script [`scripts/02_inserts.sql`](../scripts/02_inserts.sql) insere dados fictícios (empresas e pessoas inventadas) em todas as tabelas. Todos os funcionários cadastrados têm a senha `Senha@123` (armazenada como hash bcrypt).", "");
add("| Tabela | Finalidade | Chaves estrangeiras | Registros |", "|---|---|---|--:|");
TABELAS.forEach((t) => add(`| \`${t[0]}\` | ${t[1]} | ${t[2]} | ${t[3]} |`));
add("", "**Exceções à regra de 50 registros por tabela:**", "",
  "- `sla_config` (10 registros): só existem 10 combinações possíveis (2 tipos de O.S. × 5 criticidades).",
  "- `departamentos` (15 registros): tabela de domínio da estrutura organizacional.",
  "- `travas` (0 registros): tabela técnica preenchida pela própria API em tempo de execução.", "");
add("**Contagem de registros por tabela (DML1):**", "");
add(`![DML1](${achaImagem("00_dml", "DML1")})`, "");

// 4 Parte 3
add("## 4. Parte 3 — Programação em banco de dados", "");
add("Os objetos abaixo estão em [`scripts/03_programacao.sql`](../scripts/03_programacao.sql): 6 functions, 3 views, 6 stored procedures e 6 triggers. As chamadas de teste estão em [`scripts/04_testes.sql`](../scripts/04_testes.sql). Os prints foram tirados no MySQL Workbench.", "");
add("Os testes devem ser executados na ordem do arquivo e na mesma aba, porque a procedure P1 cria a variável `@nova_os` usada pelas procedures seguintes e pelos triggers T5 e T6. Os triggers T1 e T2 também aparecem nos prints de P1, P3 e P2.", "");
const secoes = [
  ["4.1 Functions", "function"], ["4.2 Views", "view"], ["4.3 Stored procedures", "procedure"], ["4.4 Triggers", "trigger"],
];
for (const [titulo, tipo] of secoes) {
  add(`### ${titulo}`, "");
  if (tipo === "trigger")
    add("Os triggers T3, T5 e T6 bloqueiam operações incorretas. Nesses casos, o retorno obtido é a mensagem de erro, que é o resultado esperado.", "");
  ITENS.filter((i) => i.tipo.toLowerCase() === tipo).forEach(blocoItem);
}

// 5 Parte 4
add("## 5. Parte 4 — Documentação do banco de dados (dicionário de dados)", "");
add("O dicionário de dados completo está no arquivo separado [`dicionario_de_dados.md`](../dicionario_de_dados.md). Para cada uma das 15 tabelas ele traz a descrição, os campos, os tipos de dados, as chaves primárias e estrangeiras, as restrições (UNIQUE, CHECK e índices) e a quantidade de registros do script de carga. Ele também lista as functions, views, procedures e triggers criados.", "");
add("Resumo das chaves do banco:", "");
add("| Tabela | Chave primária | Chaves estrangeiras |", "|---|---|---|");
CHAVES.forEach((c) => add(`| \`${c[0]}\` | ${c[1]} | ${c[2]} |`));
add("");

// 6 Parte 5
add("## 6. Parte 5 — Conexão do projeto API ao banco de dados", "");
add("### 6.1 Funcionalidade escolhida", "");
add("A funcionalidade escolhida foi o registro de horas trabalhadas na O.S. (US#2.7). Antes, ela existia apenas como demonstração na tela. Agora ela grava no banco, usando uma procedure, uma function e um trigger do banco desenvolvido nesta avaliação.", "");
add("| Objeto do banco | Papel na funcionalidade |", "|---|---|",
  "| `sp_registrar_horas` (procedure) | Grava o lançamento de horas, validando se a O.S. está aberta e se o funcionário é o responsável ou da equipe |",
  "| `fn_total_horas_os` (function) | Calcula o total de horas da O.S., exibido na tela como tempo registrado |",
  "| `trg_horas_bi_validacao` (trigger) | Bloqueia lançamento em data futura e mais de 24 horas por dia |", "");
add("### 6.2 Arquivos envolvidos", "");
add("| Camada | Arquivo | O que usa do banco |", "|---|---|---|",
  "| Banco | `scripts/03_programacao.sql` | `sp_registrar_horas`, `fn_total_horas_os` e `trg_horas_bi_validacao` |",
  "| API | `sgos-mysql/backend/src/repositories/repositoryApontamento.ts` | `CALL sp_registrar_horas(...)` e `SELECT fn_total_horas_os(...)` |",
  "| API | `services/serviceApontamento.ts`, `controllers/controllerApontamento.ts` e `routes/routeOrdemServico.ts` | Rotas `GET` e `POST /ordens-servico/:id/horas` |",
  "| Tela | `frontend/src/services/apontamento.ts` e `components/ordens/OrdemServicoDetalhesModal.tsx` | Botão Lançar horas e aba Horas registradas |", "");
add("### 6.3 Fluxo da funcionalidade", "");
add("1. O técnico abre a O.S. na tela e clica em **Lançar horas**.",
    "2. A tela envia a requisição para a rota `POST /ordens-servico/:id/horas` da API.",
    "3. O repositório da API executa `CALL sp_registrar_horas(...)` no banco.",
    "4. A procedure valida as regras e insere o lançamento; o trigger valida a data e o limite de 24 horas por dia.",
    "5. A aba **Horas registradas** lista os lançamentos e mostra o total calculado por `fn_total_horas_os`.", "");
const api = trechoApi();
add("**Trecho do código da API que chama a procedure e a function:**", "");
if (api) add(`Arquivo: \`${api.rel}\``, "", F + "ts", api.texto, F, "");
else add("> ⚠️ Não encontrei `repositoryApontamento.ts` no projeto.", "");
add("### 6.4 Testes da funcionalidade", "");
const prints5 = [
  ["API-1", "Formulário **Lançar horas** preenchido."],
  ["API-2", "Aba **Horas registradas** com o lançamento e o tempo registrado atualizado (total vindo de `fn_total_horas_os`)."],
  ["API-3", "Mensagem de erro na tela ao ultrapassar 24 horas no mesmo dia (vem do trigger do banco)."],
  ["API-4", "Registro gravado no banco (consulta no MySQL Workbench)."],
];
for (const [id, legenda] of prints5) add(`**${id}:** ${legenda}`, "", `![${id}](${achaImagem("05_api", id)})`, "");

// escreve
fs.mkdirSync(path.join(RAIZ, "docs"), { recursive: true });
fs.writeFileSync(path.join(RAIZ, "docs", "RELATORIO.md"), md.join("\n") + "\n", "utf8");

// resumo
console.log("OK: docs/RELATORIO.md gerado.");
const lista = (titulo, arr) => { if (arr.length) { console.log("\n" + titulo); arr.forEach((x) => console.log("  - " + x)); } };
lista("Prints que ainda NÃO existem (o relatório mostra imagem quebrada até você colocar):", avisos.imagens);
lista("Prints com maiúscula/minúscula diferente (o GitHub não acha; renomeie):", avisos.maiusculas);
lista("Modelos ainda não adicionados:", avisos.modelos);
lista("Objetos não encontrados no 03_programacao.sql:", avisos.objetos);
lista("Itens sem consulta de teste no 04_testes.sql (ok se o teste for indireto, como T1 e T2 antigos):", avisos.testes);
if (avisos.api) console.log("\nNão achei sgos-mysql/backend/src/repositories/repositoryApontamento.ts");
