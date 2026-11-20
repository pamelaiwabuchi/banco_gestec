-- =====================================================================
-- SGOS - Sistema de Gestão de Ordens de Serviço (GesTec / ALTAVE)
-- 3ª Avaliação de Banco de Dados Relacional - Script 03: programação em banco
-- SGBD: MySQL 8 (compatível com MariaDB)
--
-- Conteúdo: 6 functions, 3 views, 6 stored procedures e 6 triggers.
-- Pré-requisito: 01_create_tables.sql e 02_inserts.sql já executados.
-- Como executar no DBeaver: rodar o script inteiro com Alt+X.
-- =====================================================================

USE gestec;

-- Apaga os objetos, caso o script seja executado de novo
DROP TRIGGER IF EXISTS trg_os_bi_sla;
DROP TRIGGER IF EXISTS trg_os_bu_datas;
DROP TRIGGER IF EXISTS trg_clientes_bu_inativar;
DROP TRIGGER IF EXISTS trg_projetos_bu_datas;
DROP TRIGGER IF EXISTS trg_horas_bi_validacao;
DROP TRIGGER IF EXISTS trg_anexos_bi_limite;
DROP VIEW IF EXISTS vw_os_atrasadas;
DROP VIEW IF EXISTS vw_horas_por_funcionario;
DROP VIEW IF EXISTS vw_os_detalhada;
DROP PROCEDURE IF EXISTS sp_abrir_os;
DROP PROCEDURE IF EXISTS sp_alterar_status_os;
DROP PROCEDURE IF EXISTS sp_atribuir_responsavel;
DROP PROCEDURE IF EXISTS sp_registrar_horas;
DROP PROCEDURE IF EXISTS sp_relatorio_cliente;
DROP PROCEDURE IF EXISTS sp_resumo_departamentos;
DROP FUNCTION IF EXISTS fn_calcular_data_sla;
DROP FUNCTION IF EXISTS fn_total_horas_os;
DROP FUNCTION IF EXISTS fn_status_sla;
DROP FUNCTION IF EXISTS fn_qtd_os_abertas_funcionario;
DROP FUNCTION IF EXISTS fn_percentual_conclusao_projeto;
DROP FUNCTION IF EXISTS fn_tempo_medio_atendimento_dep;

DELIMITER $$

-- =====================================================================
-- FUNCTIONS
-- =====================================================================

-- F1. fn_calcular_data_sla
-- Problema: o prazo (SLA) de uma O.S. de manutenção é contado em DIAS ÚTEIS,
-- pulando sábados, domingos e feriados.
-- Conceitos: laço WHILE e subconsulta na tabela feriados.
CREATE FUNCTION fn_calcular_data_sla(p_abertura DATETIME, p_dias INT)
RETURNS DATETIME
READS SQL DATA
BEGIN
    DECLARE v_data DATE;
    SET v_data = DATE(p_abertura);

    WHILE p_dias > 0 DO
        SET v_data = DATE_ADD(v_data, INTERVAL 1 DAY);
        -- conta o dia só se não for sábado/domingo (1 = domingo, 7 = sábado) nem feriado
        IF DAYOFWEEK(v_data) NOT IN (1, 7)
           AND v_data NOT IN (SELECT data FROM feriados) THEN
            SET p_dias = p_dias - 1;
        END IF;
    END WHILE;

    RETURN TIMESTAMP(v_data, '23:59:59');
END$$

-- F2. fn_total_horas_os
-- Problema: saber o total de horas já trabalhadas em uma O.S.
-- Conceitos: função de grupo SUM.
CREATE FUNCTION fn_total_horas_os(p_os_id INT)
RETURNS DECIMAL(10,2)
READS SQL DATA
BEGIN
    DECLARE v_minutos INT;

    SELECT COALESCE(SUM(duracao_minutos), 0) INTO v_minutos
      FROM apontamento_horas
     WHERE os_id = p_os_id;

    RETURN v_minutos / 60;
END$$

-- F3. fn_status_sla
-- Problema: mostrar se a O.S. está dentro ou fora do prazo.
-- Conceitos: IF / ELSEIF.
CREATE FUNCTION fn_status_sla(p_os_id INT)
RETURNS VARCHAR(30)
READS SQL DATA
BEGIN
    DECLARE v_status VARCHAR(30);
    DECLARE v_limite DATETIME;
    DECLARE v_fim    DATETIME;

    SELECT status, data_limite_sla, data_fim INTO v_status, v_limite, v_fim
      FROM ordens_servico
     WHERE id = p_os_id;

    IF v_limite IS NULL THEN
        RETURN 'SEM PRAZO';
    ELSEIF v_status = 'concluido' AND v_fim <= v_limite THEN
        RETURN 'CONCLUIDA NO PRAZO';
    ELSEIF v_status = 'concluido' THEN
        RETURN 'CONCLUIDA COM ATRASO';
    ELSEIF NOW() > v_limite THEN
        RETURN 'ATRASADA';
    ELSE
        RETURN 'NO PRAZO';
    END IF;
END$$

-- F4. fn_qtd_os_abertas_funcionario
-- Problema: saber quantas O.S. ainda abertas estão com um técnico (carga de trabalho).
-- Conceitos: função de grupo COUNT.
CREATE FUNCTION fn_qtd_os_abertas_funcionario(p_funcionario_id INT)
RETURNS INT
READS SQL DATA
BEGIN
    DECLARE v_qtd INT;

    SELECT COUNT(*) INTO v_qtd
      FROM ordens_servico
     WHERE responsavel_id = p_funcionario_id
       AND status <> 'concluido'
       AND ativo = TRUE;

    RETURN v_qtd;
END$$

-- F5. fn_percentual_conclusao_projeto
-- Problema: acompanhar o andamento de um projeto pelo % de O.S. concluídas.
-- Conceitos: COUNT e subconsultas.
CREATE FUNCTION fn_percentual_conclusao_projeto(p_projeto_id INT)
RETURNS DECIMAL(5,2)
READS SQL DATA
BEGIN
    DECLARE v_total      INT;
    DECLARE v_concluidas INT;

    SET v_total      = (SELECT COUNT(*) FROM ordens_servico WHERE projeto_id = p_projeto_id);
    SET v_concluidas = (SELECT COUNT(*) FROM ordens_servico WHERE projeto_id = p_projeto_id
                                                              AND status = 'concluido');
    IF v_total = 0 THEN
        RETURN 0;
    END IF;

    RETURN v_concluidas * 100 / v_total;
END$$

-- F6. fn_tempo_medio_atendimento_dep
-- Problema: comparar os departamentos pelo tempo médio (em dias) entre a
-- abertura e a conclusão das O.S.
-- Conceitos: INNER JOIN e função de grupo AVG.
CREATE FUNCTION fn_tempo_medio_atendimento_dep(p_departamento_id INT)
RETURNS DECIMAL(10,2)
READS SQL DATA
BEGIN
    DECLARE v_media DECIMAL(10,2);

    SELECT AVG(DATEDIFF(os.data_fim, os.data_criacao)) INTO v_media
      FROM ordens_servico os
     INNER JOIN departamentos d ON d.id = os.departamento_id
     WHERE d.id = p_departamento_id
       AND os.status = 'concluido';

    RETURN v_media;
END$$

DELIMITER ;

-- =====================================================================
-- VIEWS
-- =====================================================================

-- V1. vw_os_detalhada
-- O.S. com os nomes do departamento, solicitante, responsável e cliente.
-- INNER JOIN: departamento e solicitante sempre existem.
-- LEFT JOIN: responsável e cliente podem estar vazios.
CREATE VIEW vw_os_detalhada AS
SELECT os.id,
       os.titulo,
       os.status,
       os.criticidade,
       os.data_limite_sla,
       d.nome    AS departamento,
       sol.nome  AS solicitante,
       resp.nome AS responsavel,
       c.nome    AS cliente
  FROM ordens_servico os
 INNER JOIN departamentos d   ON d.id   = os.departamento_id
 INNER JOIN funcionarios  sol ON sol.id = os.solicitante_id
  LEFT JOIN funcionarios  resp ON resp.id = os.responsavel_id
  LEFT JOIN clientes      c   ON c.id   = os.cliente_id;

-- V2. vw_horas_por_funcionario
-- Total de horas de cada funcionário. RIGHT JOIN para mostrar também quem
-- ainda não lançou horas (aparece com 0).
CREATE VIEW vw_horas_por_funcionario AS
SELECT f.id   AS funcionario_id,
       f.nome AS funcionario,
       COUNT(a.id)                                AS qtd_lancamentos,
       COALESCE(SUM(a.duracao_minutos), 0) / 60   AS total_horas
  FROM apontamento_horas a
 RIGHT JOIN funcionarios f ON f.id = a.funcionario_id
 GROUP BY f.id, f.nome;

-- V3. vw_os_atrasadas
-- O.S. ainda abertas cujo prazo já passou (usa a view V1).
CREATE VIEW vw_os_atrasadas AS
SELECT *
  FROM vw_os_detalhada
 WHERE status <> 'concluido'
   AND data_limite_sla < NOW();

DELIMITER $$

-- =====================================================================
-- STORED PROCEDURES
-- =====================================================================

-- P1. sp_abrir_os
-- Problema: abrir uma O.S. garantindo que o solicitante é gestor ou analista.
-- O prazo (SLA) é calculado pelo trigger trg_os_bi_sla.
-- Conceitos: SIGNAL (erro personalizado), subconsulta com EXISTS, parâmetro OUT.
CREATE PROCEDURE sp_abrir_os(
    IN  p_departamento_id INT,
    IN  p_cliente_id      INT,
    IN  p_solicitante_id  INT,
    IN  p_tipo            VARCHAR(20),
    IN  p_criticidade     VARCHAR(20),
    IN  p_titulo          VARCHAR(191),
    IN  p_descricao       TEXT,
    OUT p_os_id           INT
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM funcionarios
                    WHERE id = p_solicitante_id AND tipo IN ('gestor', 'analista')) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Somente gestor ou analista pode abrir O.S.';
    END IF;

    INSERT INTO ordens_servico
        (departamento_id, cliente_id, solicitante_id, tipo, criticidade, titulo, descricao, status)
    VALUES
        (p_departamento_id, p_cliente_id, p_solicitante_id, p_tipo, p_criticidade, p_titulo, p_descricao, 'aguardando');

    SET p_os_id = LAST_INSERT_ID();
END$$

-- P2. sp_alterar_status_os
-- Problema: mudar o status de uma O.S. seguindo as regras:
-- O.S. concluída não muda mais e, para concluir, o parecer técnico é obrigatório.
-- Conceitos: SIGNAL e IF.
CREATE PROCEDURE sp_alterar_status_os(
    IN p_os_id       INT,
    IN p_novo_status VARCHAR(30),
    IN p_parecer     TEXT
)
BEGIN
    DECLARE v_status_atual VARCHAR(30);

    SELECT status INTO v_status_atual FROM ordens_servico WHERE id = p_os_id;

    IF v_status_atual = 'concluido' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'O.S. já concluída não pode mudar de status';
    END IF;

    IF p_novo_status = 'concluido' AND (p_parecer IS NULL OR p_parecer = '') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Informe o parecer técnico para concluir a O.S.';
    END IF;

    UPDATE ordens_servico
       SET status = p_novo_status,
           parecer_tecnico = COALESCE(p_parecer, parecer_tecnico)
     WHERE id = p_os_id;
END$$

-- P3. sp_atribuir_responsavel
-- Problema: atribuir um técnico a uma O.S.; ele precisa ser do mesmo
-- departamento da O.S. e passa a fazer parte da equipe.
-- Conceitos: subconsultas, SIGNAL, INSERT IGNORE.
CREATE PROCEDURE sp_atribuir_responsavel(
    IN p_os_id      INT,
    IN p_tecnico_id INT
)
BEGIN
    IF (SELECT departamento_id FROM funcionarios WHERE id = p_tecnico_id)
       <> (SELECT departamento_id FROM ordens_servico WHERE id = p_os_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'O técnico precisa ser do mesmo departamento da O.S.';
    END IF;

    UPDATE ordens_servico SET responsavel_id = p_tecnico_id WHERE id = p_os_id;

    -- INSERT IGNORE: se ele já estiver na equipe, não dá erro
    INSERT IGNORE INTO equipes (funcionario_id, os_id) VALUES (p_tecnico_id, p_os_id);
END$$

-- P4. sp_registrar_horas   (usada pela API - Parte 5)
-- Problema: o técnico registra as horas gastas em uma O.S.
-- Regras: a O.S. não pode estar concluída e o funcionário precisa ser o
-- responsável ou fazer parte da equipe da O.S.
-- Conceitos: SIGNAL e subconsultas com EXISTS.
CREATE PROCEDURE sp_registrar_horas(
    IN p_funcionario_id INT,
    IN p_os_id          INT,
    IN p_data           DATE,
    IN p_minutos        INT,
    IN p_descricao      TEXT
)
BEGIN
    IF (SELECT status FROM ordens_servico WHERE id = p_os_id) = 'concluido' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Não é possível lançar horas em O.S. concluída';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM ordens_servico WHERE id = p_os_id AND responsavel_id = p_funcionario_id)
       AND NOT EXISTS (SELECT 1 FROM equipes WHERE os_id = p_os_id AND funcionario_id = p_funcionario_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Somente o responsável ou a equipe da O.S. pode lançar horas';
    END IF;

    INSERT INTO apontamento_horas (funcionario_id, os_id, data_trabalho, duracao_minutos, descricao)
    VALUES (p_funcionario_id, p_os_id, p_data, p_minutos, p_descricao);
END$$

-- P5. sp_relatorio_cliente
-- Problema: gerar o relatório de um cliente com as suas O.S., as horas
-- trabalhadas e a situação do prazo de cada uma.
-- Conceitos: CURSOR (percorre as O.S. uma a uma) e tabela temporária.
CREATE PROCEDURE sp_relatorio_cliente(IN p_cliente_id INT)
BEGIN
    DECLARE v_fim    INT DEFAULT 0;
    DECLARE v_id     INT;
    DECLARE v_titulo VARCHAR(191);
    DECLARE v_status VARCHAR(30);

    DECLARE cur_os CURSOR FOR
        SELECT id, titulo, status FROM ordens_servico WHERE cliente_id = p_cliente_id;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_fim = 1;

    DROP TEMPORARY TABLE IF EXISTS tmp_relatorio;
    CREATE TEMPORARY TABLE tmp_relatorio (
        os_id    INT,
        titulo   VARCHAR(191),
        status   VARCHAR(30),
        horas    DECIMAL(10,2),
        situacao VARCHAR(30)
    );

    OPEN cur_os;
    leitura: LOOP
        FETCH cur_os INTO v_id, v_titulo, v_status;
        IF v_fim = 1 THEN
            LEAVE leitura;
        END IF;
        INSERT INTO tmp_relatorio
        VALUES (v_id, v_titulo, v_status, fn_total_horas_os(v_id), fn_status_sla(v_id));
    END LOOP;
    CLOSE cur_os;

    SELECT * FROM tmp_relatorio;
END$$

-- P6. sp_resumo_departamentos
-- Problema: ver, por departamento, quantas O.S. existem, quantas estão
-- abertas e quantas foram concluídas.
-- Conceitos: LEFT JOIN, GROUP BY e funções de grupo (COUNT, SUM).
CREATE PROCEDURE sp_resumo_departamentos()
BEGIN
    SELECT d.nome                                     AS departamento,
           COUNT(os.id)                               AS total_os,
           COALESCE(SUM(os.status <> 'concluido'), 0) AS abertas,
           COALESCE(SUM(os.status = 'concluido'), 0)  AS concluidas
      FROM departamentos d
      LEFT JOIN ordens_servico os ON os.departamento_id = d.id
     GROUP BY d.nome
     ORDER BY total_os DESC;
END$$

-- =====================================================================
-- TRIGGERS
-- =====================================================================

-- T1. trg_os_bi_sla (antes de inserir uma O.S.)
-- Problema: toda O.S. de manutenção precisa nascer com o prazo calculado
-- conforme a criticidade (tabela sla_config). Usa a function F1.
CREATE TRIGGER trg_os_bi_sla
BEFORE INSERT ON ordens_servico
FOR EACH ROW
BEGIN
    DECLARE v_prazo INT;

    IF NEW.tipo = 'manutencao' AND NEW.data_limite_sla IS NULL THEN
        SELECT prazo_dias_uteis INTO v_prazo
          FROM sla_config
         WHERE tipo = 'manutencao' AND criticidade = NEW.criticidade;

        SET NEW.prazo_dias_uteis = v_prazo;
        SET NEW.data_limite_sla  = fn_calcular_data_sla(NOW(), v_prazo);
    END IF;
END$$

-- T2. trg_os_bu_datas (antes de atualizar uma O.S.)
-- Problema: preencher sozinho a data de início (quando recebe um responsável)
-- e a data de fim (quando é concluída).
CREATE TRIGGER trg_os_bu_datas
BEFORE UPDATE ON ordens_servico
FOR EACH ROW
BEGIN
    IF NEW.responsavel_id IS NOT NULL AND NEW.data_inicio IS NULL THEN
        SET NEW.data_inicio = NOW();
    END IF;

    IF NEW.status = 'concluido' AND NEW.data_fim IS NULL THEN
        SET NEW.data_fim = NOW();
    END IF;
END$$

-- T3. trg_clientes_bu_inativar (antes de atualizar um cliente)
-- Problema: não deixar inativar um cliente que ainda tem O.S. abertas.
-- Conceitos: subconsulta com EXISTS.
CREATE TRIGGER trg_clientes_bu_inativar
BEFORE UPDATE ON clientes
FOR EACH ROW
BEGIN
    IF OLD.ativo = TRUE AND NEW.ativo = FALSE
       AND EXISTS (SELECT 1 FROM ordens_servico
                    WHERE cliente_id = NEW.id AND status <> 'concluido' AND ativo = TRUE) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cliente possui O.S. abertas e não pode ser inativado';
    END IF;
END$$

-- T4. trg_projetos_bu_datas (antes de atualizar um projeto)
-- Problema: registrar sozinho as datas de início e fim do projeto quando o
-- status muda para em_andamento ou concluido.
CREATE TRIGGER trg_projetos_bu_datas
BEFORE UPDATE ON projetos
FOR EACH ROW
BEGIN
    IF NEW.status = 'em_andamento' AND NEW.data_inicio IS NULL THEN
        SET NEW.data_inicio = NOW();
    END IF;

    IF NEW.status = 'concluido' AND NEW.data_fim IS NULL THEN
        SET NEW.data_fim = NOW();
    END IF;
END$$

-- T5. trg_horas_bi_validacao (antes de inserir horas)
-- Problema: impedir lançamento de horas em data futura ou mais de 24 horas
-- no mesmo dia para o mesmo funcionário.
-- Conceitos: subconsulta com SUM.
CREATE TRIGGER trg_horas_bi_validacao
BEFORE INSERT ON apontamento_horas
FOR EACH ROW
BEGIN
    IF NEW.data_trabalho > CURDATE() THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Não é permitido lançar horas em data futura';
    END IF;

    IF (SELECT COALESCE(SUM(duracao_minutos), 0) FROM apontamento_horas
         WHERE funcionario_id = NEW.funcionario_id AND data_trabalho = NEW.data_trabalho)
       + NEW.duracao_minutos > 1440 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Limite de 24 horas por dia excedido';
    END IF;
END$$

-- T6. trg_anexos_bi_limite (antes de inserir um anexo)
-- Problema: cada O.S. pode ter no máximo 10 anexos.
-- Conceitos: subconsulta com COUNT.
CREATE TRIGGER trg_anexos_bi_limite
BEFORE INSERT ON anexos
FOR EACH ROW
BEGIN
    IF (SELECT COUNT(*) FROM anexos WHERE os_id = NEW.os_id) >= 10 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Limite de 10 anexos por O.S. atingido';
    END IF;
END$$

DELIMITER ;
