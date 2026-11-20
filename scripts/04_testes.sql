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

-- F1: prazo de 5 dias úteis a partir de 19/11/2026
-- (20/11 é feriado e 21-22/11 é fim de semana -> resultado 27/11)
SELECT fn_calcular_data_sla('2026-11-19 10:00:00', 5) AS prazo;

-- F2: total de horas das O.S.
SELECT id, titulo, fn_total_horas_os(id) AS total_horas
  FROM ordens_servico
 LIMIT 10;

-- F3: situação do prazo das O.S.
SELECT id, titulo, status, fn_status_sla(id) AS situacao
  FROM ordens_servico
 LIMIT 10;

-- F4: quantidade de O.S. abertas de cada técnico
SELECT id, nome, fn_qtd_os_abertas_funcionario(id) AS os_abertas
  FROM funcionarios
 WHERE tipo = 'tecnico'
 LIMIT 10;

-- F5: percentual de conclusão dos projetos
SELECT id, nome, fn_percentual_conclusao_projeto(id) AS percentual
  FROM projetos
 LIMIT 10;

-- F6: tempo médio de atendimento (dias) por departamento
SELECT id, nome, fn_tempo_medio_atendimento_dep(id) AS media_dias
  FROM departamentos;

-- ============================== VIEWS ================================

-- V1 (mostra os nomes que vieram dos JOINs)
SELECT id, titulo, departamento, solicitante, responsavel, cliente
  FROM vw_os_detalhada
 LIMIT 10;

-- V2
SELECT * FROM vw_horas_por_funcionario LIMIT 10;

-- V3
SELECT * FROM vw_os_atrasadas LIMIT 10;

-- ========================= STORED PROCEDURES =========================

-- P1: abre uma O.S. de manutenção (o trigger T1 calcula o prazo sozinho)
-- 63 = gestor.bdr | departamento 2 = Hardware | cliente 1
CALL sp_abrir_os(2, 1, 63, 'manutencao', 'alto', 'Teste BDR', 'O.S. aberta pela procedure', @nova_os);
SELECT id, titulo, tipo, criticidade, status, data_criacao, data_limite_sla
  FROM ordens_servico WHERE id = @nova_os;

-- P3: atribui o técnico 18 (Hardware) à O.S. (o trigger T2 preenche data_inicio)
CALL sp_atribuir_responsavel(@nova_os, 18);
SELECT id, titulo, responsavel_id, data_inicio FROM ordens_servico WHERE id = @nova_os;

-- P4: o técnico 18 lança 2 horas na O.S.
CALL sp_registrar_horas(18, @nova_os, CURDATE(), 120, 'Diagnóstico do problema');
SELECT * FROM apontamento_horas WHERE os_id = @nova_os;

-- P2: conclui a O.S. com parecer (o trigger T2 preenche data_fim)
CALL sp_alterar_status_os(@nova_os, 'concluido', 'Câmera substituída e testada.');
SELECT id, status, parecer_tecnico, data_fim FROM ordens_servico WHERE id = @nova_os;

-- P5: relatório do cliente 1 (usa CURSOR)
CALL sp_relatorio_cliente(1);

-- P6: resumo de O.S. por departamento
CALL sp_resumo_departamentos();

-- ============================= TRIGGERS ==============================
-- T1 e T2 já aparecem nos prints de P1, P3 e P2 acima.
-- Os triggers abaixo bloqueiam operações erradas: o print é a mensagem de erro.

-- T3: tenta inativar um cliente que tem O.S. abertas -> erro
UPDATE clientes SET ativo = FALSE
 WHERE id = (SELECT cliente_id FROM ordens_servico WHERE status <> 'concluido' AND ativo = TRUE LIMIT 1);

-- T4: conclui o projeto 2 (que está em andamento) -> data_fim é preenchida sozinha
UPDATE projetos SET status = 'concluido' WHERE id = 2;
SELECT id, nome, status, data_fim FROM projetos WHERE id = 2;

-- T5: tenta lançar horas com data de amanhã -> erro
INSERT INTO apontamento_horas (funcionario_id, os_id, data_trabalho, duracao_minutos)
VALUES (18, @nova_os, CURDATE() + INTERVAL 1 DAY, 60);

-- T6: tenta colocar 11 anexos na mesma O.S. -> erro
INSERT INTO anexos (os_id, funcionario_id, nome, tamanho_bytes, caminho, tipo)
SELECT @nova_os, 18, CONCAT('foto', n, '.jpg'), 1000, CONCAT('teste/foto', n, '.jpg'), 'image/jpeg'
  FROM (SELECT 1 n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6
        UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10 UNION SELECT 11) AS numeros;
