-- =====================================================================
-- SGOS - 3ª Avaliação de BDR - Script 04: testes (um print para cada item)
--
-- Rode um bloco por vez, na ordem: selecione as linhas do bloco e aperte Alt+X.
-- Rode tudo na MESMA aba do DBeaver (o bloco P1 cria a variável @nova_os,
-- usada pelos blocos seguintes).
-- Para voltar os dados ao original no final: rode de novo o 02_inserts.sql.
-- =====================================================================

USE gestec;

-- ============================ FUNCTIONS ==============================

-- Problema que resolve: O prazo (SLA) das O.S. de manutenção é contado em dias úteis. A função calcula a data limite pulando sábados, domingos e feriados.
-- F1: prazo de 5 dias úteis a partir de 19/11/2026
-- (20/11 é feriado e 21-22/11 é fim de semana -> resultado 27/11)
SELECT fn_calcular_data_sla('2026-11-19 10:00:00', 5) AS prazo;

-- Problema que resolve: Saber quantas horas já foram trabalhadas em uma O.S., somando os apontamentos.
-- F2: total de horas das O.S.
SELECT id, titulo, fn_total_horas_os(id) AS total_horas
  FROM ordens_servico
 LIMIT 10;

-- Problema que resolve: Mostrar se a O.S. está no prazo, atrasada, concluída no prazo, concluída com atraso ou sem prazo.
-- F3: situação do prazo das O.S.
SELECT id, titulo, status, fn_status_sla(id) AS situacao
  FROM ordens_servico
 LIMIT 10;

-- Problema que resolve: Medir a carga de trabalho de um técnico, contando as O.S. abertas dele.
-- F4: quantidade de O.S. abertas de cada técnico
SELECT id, nome, fn_qtd_os_abertas_funcionario(id) AS os_abertas
  FROM funcionarios
 WHERE tipo = 'tecnico'
 LIMIT 10;

-- Problema que resolve: Acompanhar o andamento de um projeto pelo percentual de O.S. concluídas.
-- F5: percentual de conclusão dos projetos
SELECT id, nome, fn_percentual_conclusao_projeto(id) AS percentual
  FROM projetos
 LIMIT 10;

-- Problema que resolve: Comparar os departamentos pelo tempo médio, em dias, entre a abertura e a conclusão das O.S.
-- F6: tempo médio de atendimento (dias) por departamento
SELECT id, nome, fn_tempo_medio_atendimento_dep(id) AS media_dias
  FROM departamentos;

-- ============================== VIEWS ================================

-- Problema que resolve: Trocar os IDs pelos nomes de departamento, solicitante, responsável e cliente (INNER e LEFT JOIN).
-- V1 (mostra os nomes que vieram dos JOINs)
SELECT id, titulo, departamento, solicitante, responsavel, cliente
  FROM vw_os_detalhada
 LIMIT 10;

-- Problema que resolve: Total de horas de cada funcionário, incluindo quem ainda não lançou nada (RIGHT JOIN).
-- V2
SELECT * FROM vw_horas_por_funcionario LIMIT 10;

-- Problema que resolve: 	Listar as O.S. abertas cujo prazo já venceu.
-- V3
SELECT * FROM vw_os_atrasadas LIMIT 10;

-- ========================= STORED PROCEDURES =========================

-- Problema que resolve: Abrir uma O.S. garantindo que só gestor ou analista pode abrir, e devolver o ID criado.
-- P1: abre uma O.S. de manutenção (o trigger T1 calcula o prazo sozinho)
-- 63 = gestor.bdr | departamento 2 = Hardware | cliente 1
CALL sp_abrir_os(2, 1, 63, 'manutencao', 'alto', 'Teste BDR', 'O.S. aberta pela procedure', @nova_os);
SELECT id, titulo, tipo, criticidade, status, data_criacao, data_limite_sla
  FROM ordens_servico WHERE id = @nova_os;

-- Problema que resolve: Atribuir um técnico que seja do mesmo departamento da O.S. e incluí-lo na equipe.
-- P3: atribui o técnico 18 (Hardware) à O.S. (o trigger T2 preenche data_inicio)
CALL sp_atribuir_responsavel(@nova_os, 18);
SELECT id, titulo, responsavel_id, data_inicio FROM ordens_servico WHERE id = @nova_os;

-- Problema que resolve: Lançar horas só se a O.S. não estiver concluída e o funcionário for o responsável ou da equipe. É a procedure usada na Parte 5.
-- P4: o técnico 18 lança 2 horas na O.S.
CALL sp_registrar_horas(18, @nova_os, CURDATE(), 120, 'Diagnóstico do problema');
SELECT * FROM apontamento_horas WHERE os_id = @nova_os;

-- Problema que resolve: Mudar o status respeitando as regras: O.S. concluída não muda mais, e concluir exige parecer técnico.
-- P2: conclui a O.S. com parecer (o trigger T2 preenche data_fim)
CALL sp_alterar_status_os(@nova_os, 'concluido', 'Câmera substituída e testada.');
SELECT id, status, parecer_tecnico, data_fim FROM ordens_servico WHERE id = @nova_os;

-- Problema que resolve: Gerar o relatório das O.S. de um cliente, com horas e situação do prazo (usa cursor).
-- P5: relatório do cliente 1 (usa CURSOR)
CALL sp_relatorio_cliente(1);

-- Problema que resolve: Ver por departamento o total de O.S., quantas estão abertas e quantas concluídas (LEFT JOIN, GROUP BY).
-- P6: resumo de O.S. por departamento
CALL sp_resumo_departamentos();

-- ============================= TRIGGERS ==============================

-- Problema que resolve: Toda O.S. de manutenção nasce com o prazo calculado pela criticidade, sem depender de quem cadastra.
-- T1: insere O.S. de manutenção SEM prazo -> o trigger calcula sozinho
INSERT INTO ordens_servico (departamento_id, cliente_id, solicitante_id, tipo, criticidade, titulo, descricao, status)
VALUES (2, 1, 63, 'manutencao', 'urgente', 'Teste T1', 'Teste direto do trigger de SLA', 'aguardando');
SELECT id, titulo, criticidade, prazo_dias_uteis, data_criacao, data_limite_sla
  FROM ordens_servico WHERE id = LAST_INSERT_ID();

-- Problema que resolve: Preencher sozinho data_inicio (ao receber responsável) e data_fim (ao concluir).
-- T2: atribui responsável (preenche data_inicio) e conclui (preenche data_fim)
SELECT id, status, responsavel_id, data_inicio, data_fim FROM ordens_servico WHERE id = 32;
UPDATE ordens_servico SET responsavel_id = 30 WHERE id = 32;
UPDATE ordens_servico SET status = 'concluido', parecer_tecnico = 'Teste T2' WHERE id = 32;
SELECT id, status, responsavel_id, data_inicio, data_fim FROM ordens_servico WHERE id = 32;

-- Problema que resolve: Impedir a inativação de um cliente que ainda tem O.S. abertas.
-- T3: tenta inativar um cliente que tem O.S. abertas -> erro
UPDATE clientes SET ativo = FALSE
 WHERE id = (SELECT cliente_id FROM ordens_servico WHERE status <> 'concluido' AND ativo = TRUE LIMIT 1);

-- Problema que resolve: Registrar sozinho as datas de início e fim do projeto quando o status muda.
-- T4: conclui o projeto 2 (que está em andamento) -> data_fim é preenchida sozinha
UPDATE projetos SET status = 'concluido' WHERE id = 2;
SELECT id, nome, status, data_fim FROM projetos WHERE id = 2;

-- Problema que resolve: Bloquear lançamento de horas em data futura ou acima de 24h por dia para o mesmo funcionário.
-- T5: tenta lançar horas com data de amanhã -> erro
INSERT INTO apontamento_horas (funcionario_id, os_id, data_trabalho, duracao_minutos)
VALUES (18, @nova_os, CURDATE() + INTERVAL 1 DAY, 60);

-- Problema que resolve: Limitar a 10 anexos por O.S.
-- T6: tenta colocar 11 anexos na mesma O.S. -> erro
INSERT INTO anexos (os_id, funcionario_id, nome, tamanho_bytes, caminho, tipo)
SELECT @nova_os, 18, CONCAT('foto', n, '.jpg'), 1000, CONCAT('teste/foto', n, '.jpg'), 'image/jpeg'
  FROM (SELECT 1 n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6
        UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10 UNION SELECT 11) AS numeros;
