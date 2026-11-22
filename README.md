# Banco GesTec — 3ª Avaliação de Banco de Dados Relacional (MySQL)

Trabalho da disciplina de BDR (FATEC), usando o tema do projeto API **SGOS / GesTec**
(Sistema de Gestão de Ordens de Serviço). Não faz parte do repositório oficial da equipe.

👉 **Relatório completo do trabalho: [docs/RELATORIO.md](docs/RELATORIO.md).**
👉 **Para rodar na sua máquina, siga o guia [COMO_RODAR.md](COMO_RODAR.md).**
👉 **Checklist completo do trabalho (o que rodar e quais prints tirar): [PASSO_A_PASSO.md](PASSO_A_PASSO.md).**

## Estrutura

| Caminho | O que é |
|---|---|
| `BDR-22-10-2026 - 3a. avaliação 1.pdf` | Enunciado da avaliação |
| `scripts/01_create_tables.sql` | Criação das 15 tabelas (DDL) |
| `scripts/02_inserts.sql` | Dados fictícios: 50+ registros por tabela (DML) |
| `scripts/03_programacao.sql` | 6 functions, 6 procedures, 6 triggers e 3 views |
| `scripts/04_testes.sql` | Chamadas de teste de cada objeto (para os prints) |
| `dicionario_de_dados.md` | Dicionário de dados (Parte 4) |
| `sgos-mysql/` | Sistema SGOS adaptado para MySQL — Parte 5: registro de horas (US#2.7) usando `sp_registrar_horas` e `fn_total_horas_os` |
| `COMO_RODAR.md` | Passo a passo para montar o banco e rodar o sistema |
| `PASSO_A_PASSO.md` | Checklist do trabalho e lista de prints |
| `docs/RELATORIO.md` | Relatório completo: problema, código e print de cada item |

## Modelos

- Modelo lógico e conceitual: no Lucidchart ("GesTec – Modelo Lógico" e "GesTec – Modelo Conceitual (Chen)").

## Tabelas com menos de 50 registros (exceções permitidas)

| Tabela | Registros | Motivo |
|---|---|---|
| `sla_config` | 10 | Só existem 10 combinações possíveis (2 tipos × 5 criticidades) |
| `departamentos` | 15 | Tabela de domínio da estrutura organizacional |
| `travas` | 0 | Tabela técnica, preenchida pela própria API em tempo de execução |

## Usuários de teste do sistema

Todos os funcionários cadastrados têm a senha **`Senha@123`**. Para testar:

- `gestor.bdr` — perfil gestor
- `tecnico.bdr` — perfil técnico
