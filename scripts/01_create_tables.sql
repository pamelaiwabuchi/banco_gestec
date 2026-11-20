-- =====================================================================
-- SGOS - Sistema de Gestão de Ordens de Serviço (GesTec / ALTAVE)
-- 3ª Avaliação de Banco de Dados Relacional - Script 01: criação das tabelas (DDL)
-- SGBD: MySQL 8 (compatível com MariaDB 10.6+)
--
-- Como executar: selecionar o banco `gestec` e rodar o script inteiro
-- (no DBeaver: Alt+X - "Executar script").
-- O script pode ser executado novamente: ele apaga e recria as tabelas.
-- =====================================================================

USE gestec;

-- ---------------------------------------------------------------------
-- Remoção das tabelas (ordem inversa às dependências)
-- ---------------------------------------------------------------------
SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS apontamento_horas;
DROP TABLE IF EXISTS anexos;
DROP TABLE IF EXISTS auditoria;
DROP TABLE IF EXISTS auditoria_projetos;
DROP TABLE IF EXISTS equipes;
DROP TABLE IF EXISTS ordens_servico;
DROP TABLE IF EXISTS projetos_departamentos;
DROP TABLE IF EXISTS projetos;
DROP TABLE IF EXISTS locais_operacionais;
DROP TABLE IF EXISTS clientes;
DROP TABLE IF EXISTS funcionarios;
DROP TABLE IF EXISTS departamentos;
DROP TABLE IF EXISTS sla_config;
DROP TABLE IF EXISTS feriados;
DROP TABLE IF EXISTS travas;
SET FOREIGN_KEY_CHECKS = 1;

-- ---------------------------------------------------------------------
-- Tabelas de apoio (sem dependências)
-- ---------------------------------------------------------------------

-- Feriados considerados no cálculo de prazo de SLA em dias úteis
CREATE TABLE feriados (
    id         INT          NOT NULL AUTO_INCREMENT,
    data       DATE         NOT NULL,
    descricao  VARCHAR(191) NOT NULL,
    nacional   BOOLEAN      NOT NULL DEFAULT FALSE,
    CONSTRAINT pk_feriados PRIMARY KEY (id),
    CONSTRAINT feriados_data_key UNIQUE (data)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- Prazo padrão de SLA (em dias úteis) para cada combinação tipo x criticidade
CREATE TABLE sla_config (
    id               INT NOT NULL AUTO_INCREMENT,
    tipo             ENUM('instalacao','manutencao') NOT NULL,
    criticidade      ENUM('baixo','medio','alto','muito_alto','urgente') NOT NULL,
    prazo_dias_uteis INT NULL,
    CONSTRAINT pk_sla_config PRIMARY KEY (id),
    CONSTRAINT config_unica UNIQUE (tipo, criticidade),
    CONSTRAINT prazo_valido CHECK (prazo_dias_uteis IS NULL OR prazo_dias_uteis > 0)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- Tabela técnica usada pela API como trava (lock) de concorrência em transações
CREATE TABLE travas (
    chave VARCHAR(100) NOT NULL,
    CONSTRAINT pk_travas PRIMARY KEY (chave)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------
-- Estrutura organizacional
-- ---------------------------------------------------------------------

-- Departamentos (Hardware, Compras, SST...). O responsável é um funcionário:
-- a FK responsavel_fk é criada depois de `funcionarios` (dependência circular).
CREATE TABLE departamentos (
    id             INT          NOT NULL AUTO_INCREMENT,
    responsavel_id INT          NULL,
    nome           VARCHAR(191) NOT NULL,
    CONSTRAINT pk_departamentos PRIMARY KEY (id)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- Colaboradores que acessam o sistema (gestor, analista ou técnico)
CREATE TABLE funcionarios (
    id              INT          NOT NULL AUTO_INCREMENT,
    departamento_id INT          NOT NULL,
    usuario         VARCHAR(191) NOT NULL,
    senha_hash      VARCHAR(191) NOT NULL,
    nome            VARCHAR(191) NOT NULL,
    tipo            ENUM('gestor','analista','tecnico') NOT NULL DEFAULT 'tecnico',
    ativo           BOOLEAN      NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_funcionarios PRIMARY KEY (id),
    CONSTRAINT funcionarios_usuario_key UNIQUE (usuario),
    CONSTRAINT funcionarios_departamento_id_fkey FOREIGN KEY (departamento_id)
        REFERENCES departamentos (id)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

ALTER TABLE departamentos
    ADD CONSTRAINT responsavel_fk FOREIGN KEY (responsavel_id) REFERENCES funcionarios (id);

-- ---------------------------------------------------------------------
-- Clientes e projetos
-- ---------------------------------------------------------------------

CREATE TABLE clientes (
    id           INT          NOT NULL AUTO_INCREMENT,
    nome         VARCHAR(191) NOT NULL,
    razao_social VARCHAR(191) NOT NULL,
    ramo_atuacao VARCHAR(191) NOT NULL,
    ativo        BOOLEAN      NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_clientes PRIMARY KEY (id),
    CONSTRAINT clientes_nome_key UNIQUE (nome),
    CONSTRAINT clientes_razao_social_key UNIQUE (razao_social)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- Ativos / locais operacionais do cliente (plataforma offshore, base terrestre, site)
CREATE TABLE locais_operacionais (
    id         INT  NOT NULL AUTO_INCREMENT,
    cliente_id INT  NOT NULL,
    descricao  TEXT NOT NULL,
    tipo       ENUM('offshore','terrestre','site') NOT NULL,
    CONSTRAINT pk_locais_operacionais PRIMARY KEY (id),
    CONSTRAINT locais_operacionais_cliente_id_fkey FOREIGN KEY (cliente_id)
        REFERENCES clientes (id)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- Projetos de implantação: agrupam as O.S. de um cliente
CREATE TABLE projetos (
    id          INT          NOT NULL AUTO_INCREMENT,
    cliente_id  INT          NOT NULL,
    data_fim    DATETIME(6)  NULL,
    data_inicio DATETIME(6)  NULL,
    status      ENUM('em_planejamento','em_andamento','pausado','concluido')
                             NOT NULL DEFAULT 'em_planejamento',
    nome        VARCHAR(191) NOT NULL,
    ativo       BOOLEAN      NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_projetos PRIMARY KEY (id),
    CONSTRAINT projetos_cliente_id_fkey FOREIGN KEY (cliente_id) REFERENCES clientes (id)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- Departamentos envolvidos em cada projeto (N:N)
CREATE TABLE projetos_departamentos (
    projeto_id      INT NOT NULL,
    departamento_id INT NOT NULL,
    CONSTRAINT pk_projetos_departamentos PRIMARY KEY (projeto_id, departamento_id),
    CONSTRAINT projetos_departamentos_projeto_id_fkey FOREIGN KEY (projeto_id)
        REFERENCES projetos (id),
    CONSTRAINT projetos_departamentos_departamento_id_fkey FOREIGN KEY (departamento_id)
        REFERENCES departamentos (id)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------
-- Ordens de serviço
-- ---------------------------------------------------------------------

CREATE TABLE ordens_servico (
    id                       INT          NOT NULL AUTO_INCREMENT,
    departamento_id          INT          NOT NULL,
    cliente_id               INT          NULL,
    solicitante_id           INT          NOT NULL,
    responsavel_id           INT          NULL,
    projeto_id               INT          NULL,
    anterior_id              INT          NULL,      -- O.S. anterior (reincidência)
    ativo_id                 INT          NULL,      -- local operacional atendido
    sla_config_id            INT          NULL,
    titulo                   VARCHAR(191) NOT NULL,
    descricao                TEXT         NOT NULL,
    parecer_tecnico          TEXT         NULL,
    tipo                     ENUM('instalacao','manutencao') NOT NULL DEFAULT 'instalacao',
    criticidade              ENUM('baixo','medio','alto','muito_alto','urgente')
                                          NOT NULL DEFAULT 'medio',
    status                   ENUM('em_andamento','aguardando','validacao_testes','bloqueado','concluido')
                                          NOT NULL DEFAULT 'em_andamento',
    data_criacao             DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    data_inicio              DATETIME(6)  NULL,
    data_fim                 DATETIME(6)  NULL,
    data_limite_sla          DATETIME(6)  NULL,
    prazo_dias_uteis         INT          NULL,
    sla_manual               BOOLEAN      NOT NULL DEFAULT FALSE,
    justificativa_sla_manual TEXT         NULL,
    ativo                    BOOLEAN      NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_ordens_servico PRIMARY KEY (id),
    CONSTRAINT ordens_servico_departamento_id_fkey FOREIGN KEY (departamento_id) REFERENCES departamentos (id),
    CONSTRAINT ordens_servico_cliente_id_fkey      FOREIGN KEY (cliente_id)      REFERENCES clientes (id),
    CONSTRAINT ordens_servico_solicitante_id_fkey  FOREIGN KEY (solicitante_id)  REFERENCES funcionarios (id),
    CONSTRAINT ordens_servico_responsavel_id_fkey  FOREIGN KEY (responsavel_id)  REFERENCES funcionarios (id),
    CONSTRAINT ordens_servico_projeto_id_fkey      FOREIGN KEY (projeto_id)      REFERENCES projetos (id),
    CONSTRAINT ordens_servico_anterior_id_fkey     FOREIGN KEY (anterior_id)     REFERENCES ordens_servico (id),
    CONSTRAINT ordens_servico_ativo_id_fkey        FOREIGN KEY (ativo_id)        REFERENCES locais_operacionais (id),
    CONSTRAINT ordens_servico_sla_config_id_fkey   FOREIGN KEY (sla_config_id)   REFERENCES sla_config (id),
    CONSTRAINT prazo_dias_uteis_valido CHECK (prazo_dias_uteis IS NULL OR prazo_dias_uteis > 0),
    CONSTRAINT justificativa_sla_manual_obrigatoria CHECK (
        sla_manual = 0
        OR (justificativa_sla_manual IS NOT NULL AND CHAR_LENGTH(TRIM(justificativa_sla_manual)) > 0)
    )
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

CREATE INDEX idx_os_criticidade_limite  ON ordens_servico (criticidade, data_limite_sla);
CREATE INDEX idx_os_departamento_status ON ordens_servico (departamento_id, status);
CREATE INDEX idx_os_responsavel_status  ON ordens_servico (responsavel_id, status);
CREATE INDEX idx_os_projeto             ON ordens_servico (projeto_id);

-- Funcionários que compõem a equipe de cada O.S. (N:N)
CREATE TABLE equipes (
    funcionario_id INT NOT NULL,
    os_id          INT NOT NULL,
    CONSTRAINT pk_equipes PRIMARY KEY (funcionario_id, os_id),
    CONSTRAINT equipes_funcionario_id_fkey FOREIGN KEY (funcionario_id) REFERENCES funcionarios (id),
    CONSTRAINT equipes_os_id_fkey          FOREIGN KEY (os_id)          REFERENCES ordens_servico (id)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- Horas trabalhadas por funcionário em cada O.S.
CREATE TABLE apontamento_horas (
    id              INT         NOT NULL AUTO_INCREMENT,
    funcionario_id  INT         NOT NULL,
    os_id           INT         NOT NULL,
    data_trabalho   DATE        NOT NULL,
    duracao_minutos INT         NOT NULL,
    descricao       TEXT        NULL,
    data_criacao    DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    CONSTRAINT pk_apontamento_horas PRIMARY KEY (id),
    CONSTRAINT apontamento_horas_funcionario_id_fkey FOREIGN KEY (funcionario_id) REFERENCES funcionarios (id),
    CONSTRAINT apontamento_horas_os_id_fkey          FOREIGN KEY (os_id)          REFERENCES ordens_servico (id),
    CONSTRAINT duracao_apontamento_positiva CHECK (duracao_minutos > 0)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

CREATE INDEX idx_apontamentos_funcionario_data ON apontamento_horas (funcionario_id, data_trabalho);

-- Metadados dos arquivos anexados às O.S. (o arquivo fica no storage)
CREATE TABLE anexos (
    id             INT           NOT NULL AUTO_INCREMENT,
    os_id          INT           NOT NULL,
    funcionario_id INT           NOT NULL,
    nome           VARCHAR(255)  NOT NULL,
    tamanho_bytes  BIGINT        NOT NULL,
    caminho        VARCHAR(500)  NOT NULL,
    tipo           VARCHAR(100)  NOT NULL,
    relato         VARCHAR(2000) NULL,
    data_upload    DATETIME(6)   NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    CONSTRAINT pk_anexos PRIMARY KEY (id),
    CONSTRAINT anexos_caminho_key UNIQUE (caminho),
    CONSTRAINT anexos_os_id_fkey          FOREIGN KEY (os_id)          REFERENCES ordens_servico (id),
    CONSTRAINT anexos_funcionario_id_fkey FOREIGN KEY (funcionario_id) REFERENCES funcionarios (id),
    CONSTRAINT tamanho_valido        CHECK (tamanho_bytes >= 0),
    CONSTRAINT anexos_tamanho_maximo CHECK (tamanho_bytes <= 52428800),   -- 50 MB
    CONSTRAINT anexos_relato_tamanho CHECK (relato IS NULL OR CHAR_LENGTH(relato) <= 2000)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

CREATE INDEX idx_anexos_os_data ON anexos (os_id, data_upload);

-- ---------------------------------------------------------------------
-- Auditoria (histórico de alterações)
-- ---------------------------------------------------------------------

CREATE TABLE auditoria (
    id               INT          NOT NULL AUTO_INCREMENT,
    os_id            INT          NOT NULL,
    funcionario_id   INT          NOT NULL,
    data_modificacao DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    acao             ENUM('insercao','atualizacao','exclusao') NOT NULL,
    tipo_entidade    VARCHAR(191) NOT NULL DEFAULT 'ordem_servico',
    campo_alterado   VARCHAR(191) NULL,
    dado_antigo      TEXT         NULL,
    dado_novo        TEXT         NULL,
    justificativa    TEXT         NULL,
    CONSTRAINT pk_auditoria PRIMARY KEY (id),
    CONSTRAINT auditoria_os_id_fkey          FOREIGN KEY (os_id)          REFERENCES ordens_servico (id),
    CONSTRAINT auditoria_funcionario_id_fkey FOREIGN KEY (funcionario_id) REFERENCES funcionarios (id)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

CREATE INDEX idx_auditoria_os_data ON auditoria (os_id, data_modificacao);

CREATE TABLE auditoria_projetos (
    id               INT          NOT NULL AUTO_INCREMENT,
    projeto_id       INT          NOT NULL,
    funcionario_id   INT          NOT NULL,
    data_modificacao DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    acao             ENUM('insercao','atualizacao','exclusao') NOT NULL,
    campo_alterado   VARCHAR(191) NULL,
    dado_antigo      TEXT         NULL,
    dado_novo        TEXT         NULL,
    justificativa    TEXT         NULL,
    CONSTRAINT pk_auditoria_projetos PRIMARY KEY (id),
    CONSTRAINT auditoria_projetos_projeto_id_fkey     FOREIGN KEY (projeto_id)     REFERENCES projetos (id),
    CONSTRAINT auditoria_projetos_funcionario_id_fkey FOREIGN KEY (funcionario_id) REFERENCES funcionarios (id)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

CREATE INDEX idx_auditoria_projetos_data ON auditoria_projetos (projeto_id, data_modificacao);
