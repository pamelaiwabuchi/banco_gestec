# Banco GesTec — 3ª Avaliação de Banco de Dados Relacional (MySQL)

Trabalho da disciplina de BDR (FATEC), usando o tema do projeto API **SGOS / GesTec**
(Sistema de Gestão de Ordens de Serviço). Não faz parte do repositório oficial da equipe.

👉 **Para rodar na sua máquina, siga o guia [COMO_RODAR.md](COMO_RODAR.md).**

## Estrutura

| Caminho | O que é |
|---|---|
| `BDR-22-10-2026 - 3a. avaliação 1.pdf` | Enunciado da avaliação |
| `scripts/01_create_tables.sql` | Criação das 15 tabelas (DDL) |
| `scripts/02_inserts.sql` | Dados fictícios: 50+ registros por tabela (DML) |
| `scripts/03_programacao.sql` | *(em andamento)* Procedures, functions, triggers e views |
| `sgos-mysql/` | Sistema SGOS adaptado para MySQL — Parte 5 (conexão da API ao banco) |
| `COMO_RODAR.md` | Passo a passo para montar o banco e rodar o sistema |

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
