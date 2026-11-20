-- CreateTable
CREATE TABLE `anexos` (
    `id` INTEGER NOT NULL AUTO_INCREMENT,
    `os_id` INTEGER NOT NULL,
    `funcionario_id` INTEGER NOT NULL,
    `nome` VARCHAR(255) NOT NULL,
    `tamanho_bytes` BIGINT NOT NULL,
    `caminho` VARCHAR(500) NOT NULL,
    `data_upload` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    `tipo` VARCHAR(100) NOT NULL,
    `relato` VARCHAR(2000) NULL,

    UNIQUE INDEX `anexos_caminho_key`(`caminho`),
    INDEX `idx_anexos_os_data`(`os_id`, `data_upload`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `auditoria` (
    `id` INTEGER NOT NULL AUTO_INCREMENT,
    `os_id` INTEGER NOT NULL,
    `funcionario_id` INTEGER NOT NULL,
    `data_modificacao` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    `acao` ENUM('insercao', 'atualizacao', 'exclusao') NOT NULL,
    `campo_alterado` VARCHAR(191) NULL,
    `dado_antigo` TEXT NULL,
    `dado_novo` TEXT NULL,
    `justificativa` TEXT NULL,
    `tipo_entidade` VARCHAR(191) NOT NULL DEFAULT 'ordem_servico',

    INDEX `idx_auditoria_os_data`(`os_id`, `data_modificacao`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `clientes` (
    `id` INTEGER NOT NULL AUTO_INCREMENT,
    `nome` VARCHAR(191) NOT NULL,
    `razao_social` VARCHAR(191) NOT NULL,
    `ramo_atuacao` VARCHAR(191) NOT NULL,
    `ativo` BOOLEAN NOT NULL DEFAULT true,

    UNIQUE INDEX `clientes_nome_key`(`nome`),
    UNIQUE INDEX `clientes_razao_social_key`(`razao_social`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `departamentos` (
    `id` INTEGER NOT NULL AUTO_INCREMENT,
    `responsavel_id` INTEGER NULL,
    `nome` VARCHAR(191) NOT NULL,

    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `equipes` (
    `funcionario_id` INTEGER NOT NULL,
    `os_id` INTEGER NOT NULL,

    PRIMARY KEY (`funcionario_id`, `os_id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `funcionarios` (
    `id` INTEGER NOT NULL AUTO_INCREMENT,
    `departamento_id` INTEGER NOT NULL,
    `usuario` VARCHAR(191) NOT NULL,
    `senha_hash` VARCHAR(191) NOT NULL,
    `nome` VARCHAR(191) NOT NULL,
    `tipo` ENUM('gestor', 'analista', 'tecnico') NOT NULL DEFAULT 'tecnico',
    `ativo` BOOLEAN NOT NULL DEFAULT true,

    UNIQUE INDEX `funcionarios_usuario_key`(`usuario`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `locais_operacionais` (
    `id` INTEGER NOT NULL AUTO_INCREMENT,
    `cliente_id` INTEGER NOT NULL,
    `descricao` TEXT NOT NULL,
    `tipo` ENUM('offshore', 'terrestre', 'site') NOT NULL,

    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `ordens_servico` (
    `id` INTEGER NOT NULL AUTO_INCREMENT,
    `departamento_id` INTEGER NOT NULL,
    `cliente_id` INTEGER NULL,
    `solicitante_id` INTEGER NOT NULL,
    `responsavel_id` INTEGER NULL,
    `projeto_id` INTEGER NULL,
    `anterior_id` INTEGER NULL,
    `parecer_tecnico` TEXT NULL,
    `tipo` ENUM('instalacao', 'manutencao') NOT NULL DEFAULT 'instalacao',
    `criticidade` ENUM('baixo', 'medio', 'alto', 'muito_alto', 'urgente') NOT NULL DEFAULT 'medio',
    `descricao` TEXT NOT NULL,
    `status` ENUM('em_andamento', 'aguardando', 'validacao_testes', 'bloqueado', 'concluido') NOT NULL DEFAULT 'em_andamento',
    `data_criacao` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    `ativo_id` INTEGER NULL,
    `data_fim` DATETIME(6) NULL,
    `data_inicio` DATETIME(6) NULL,
    `data_limite_sla` DATETIME(6) NULL,
    `justificativa_sla_manual` TEXT NULL,
    `prazo_dias_uteis` INTEGER NULL,
    `sla_config_id` INTEGER NULL,
    `sla_manual` BOOLEAN NOT NULL DEFAULT false,
    `titulo` VARCHAR(191) NOT NULL,
    `ativo` BOOLEAN NOT NULL DEFAULT true,

    INDEX `idx_os_criticidade_limite`(`criticidade`, `data_limite_sla`),
    INDEX `idx_os_departamento_status`(`departamento_id`, `status`),
    INDEX `idx_os_projeto`(`projeto_id`),
    INDEX `idx_os_responsavel_status`(`responsavel_id`, `status`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `projetos` (
    `id` INTEGER NOT NULL AUTO_INCREMENT,
    `cliente_id` INTEGER NOT NULL,
    `data_fim` DATETIME(6) NULL,
    `data_inicio` DATETIME(6) NULL,
    `status` ENUM('em_planejamento', 'em_andamento', 'pausado', 'concluido') NOT NULL DEFAULT 'em_planejamento',
    `nome` VARCHAR(191) NOT NULL,
    `ativo` BOOLEAN NOT NULL DEFAULT true,

    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `auditoria_projetos` (
    `id` INTEGER NOT NULL AUTO_INCREMENT,
    `projeto_id` INTEGER NOT NULL,
    `funcionario_id` INTEGER NOT NULL,
    `data_modificacao` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    `acao` ENUM('insercao', 'atualizacao', 'exclusao') NOT NULL,
    `campo_alterado` VARCHAR(191) NULL,
    `dado_antigo` TEXT NULL,
    `dado_novo` TEXT NULL,
    `justificativa` TEXT NULL,

    INDEX `idx_auditoria_projetos_data`(`projeto_id`, `data_modificacao`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `projetos_departamentos` (
    `projeto_id` INTEGER NOT NULL,
    `departamento_id` INTEGER NOT NULL,

    PRIMARY KEY (`projeto_id`, `departamento_id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `apontamento_horas` (
    `id` INTEGER NOT NULL AUTO_INCREMENT,
    `funcionario_id` INTEGER NOT NULL,
    `os_id` INTEGER NOT NULL,
    `data_trabalho` DATE NOT NULL,
    `duracao_minutos` INTEGER NOT NULL,
    `descricao` TEXT NULL,
    `data_criacao` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),

    INDEX `idx_apontamentos_funcionario_data`(`funcionario_id`, `data_trabalho`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `travas` (
    `chave` VARCHAR(100) NOT NULL,

    PRIMARY KEY (`chave`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `feriados` (
    `id` INTEGER NOT NULL AUTO_INCREMENT,
    `data` DATE NOT NULL,
    `descricao` VARCHAR(191) NOT NULL,
    `nacional` BOOLEAN NOT NULL DEFAULT false,

    UNIQUE INDEX `feriados_data_key`(`data`),
    INDEX `idx_feriados_data`(`data`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `sla_config` (
    `id` INTEGER NOT NULL AUTO_INCREMENT,
    `tipo` ENUM('instalacao', 'manutencao') NOT NULL,
    `criticidade` ENUM('baixo', 'medio', 'alto', 'muito_alto', 'urgente') NOT NULL,
    `prazo_dias_uteis` INTEGER NULL,

    UNIQUE INDEX `config_unica`(`tipo`, `criticidade`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- AddForeignKey
ALTER TABLE `anexos` ADD CONSTRAINT `anexos_funcionario_id_fkey` FOREIGN KEY (`funcionario_id`) REFERENCES `funcionarios`(`id`) ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE `anexos` ADD CONSTRAINT `anexos_os_id_fkey` FOREIGN KEY (`os_id`) REFERENCES `ordens_servico`(`id`) ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE `auditoria` ADD CONSTRAINT `auditoria_funcionario_id_fkey` FOREIGN KEY (`funcionario_id`) REFERENCES `funcionarios`(`id`) ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE `auditoria` ADD CONSTRAINT `auditoria_os_id_fkey` FOREIGN KEY (`os_id`) REFERENCES `ordens_servico`(`id`) ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE `departamentos` ADD CONSTRAINT `responsavel_fk` FOREIGN KEY (`responsavel_id`) REFERENCES `funcionarios`(`id`) ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE `equipes` ADD CONSTRAINT `equipes_funcionario_id_fkey` FOREIGN KEY (`funcionario_id`) REFERENCES `funcionarios`(`id`) ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE `equipes` ADD CONSTRAINT `equipes_os_id_fkey` FOREIGN KEY (`os_id`) REFERENCES `ordens_servico`(`id`) ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE `funcionarios` ADD CONSTRAINT `funcionarios_departamento_id_fkey` FOREIGN KEY (`departamento_id`) REFERENCES `departamentos`(`id`) ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE `locais_operacionais` ADD CONSTRAINT `locais_operacionais_cliente_id_fkey` FOREIGN KEY (`cliente_id`) REFERENCES `clientes`(`id`) ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE `ordens_servico` ADD CONSTRAINT `ordens_servico_anterior_id_fkey` FOREIGN KEY (`anterior_id`) REFERENCES `ordens_servico`(`id`) ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE `ordens_servico` ADD CONSTRAINT `ordens_servico_ativo_id_fkey` FOREIGN KEY (`ativo_id`) REFERENCES `locais_operacionais`(`id`) ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE `ordens_servico` ADD CONSTRAINT `ordens_servico_cliente_id_fkey` FOREIGN KEY (`cliente_id`) REFERENCES `clientes`(`id`) ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE `ordens_servico` ADD CONSTRAINT `ordens_servico_departamento_id_fkey` FOREIGN KEY (`departamento_id`) REFERENCES `departamentos`(`id`) ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE `ordens_servico` ADD CONSTRAINT `ordens_servico_projeto_id_fkey` FOREIGN KEY (`projeto_id`) REFERENCES `projetos`(`id`) ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE `ordens_servico` ADD CONSTRAINT `ordens_servico_responsavel_id_fkey` FOREIGN KEY (`responsavel_id`) REFERENCES `funcionarios`(`id`) ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE `ordens_servico` ADD CONSTRAINT `ordens_servico_sla_config_id_fkey` FOREIGN KEY (`sla_config_id`) REFERENCES `sla_config`(`id`) ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE `ordens_servico` ADD CONSTRAINT `ordens_servico_solicitante_id_fkey` FOREIGN KEY (`solicitante_id`) REFERENCES `funcionarios`(`id`) ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE `projetos` ADD CONSTRAINT `projetos_cliente_id_fkey` FOREIGN KEY (`cliente_id`) REFERENCES `clientes`(`id`) ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE `auditoria_projetos` ADD CONSTRAINT `auditoria_projetos_funcionario_id_fkey` FOREIGN KEY (`funcionario_id`) REFERENCES `funcionarios`(`id`) ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE `auditoria_projetos` ADD CONSTRAINT `auditoria_projetos_projeto_id_fkey` FOREIGN KEY (`projeto_id`) REFERENCES `projetos`(`id`) ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE `projetos_departamentos` ADD CONSTRAINT `projetos_departamentos_departamento_id_fkey` FOREIGN KEY (`departamento_id`) REFERENCES `departamentos`(`id`) ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE `projetos_departamentos` ADD CONSTRAINT `projetos_departamentos_projeto_id_fkey` FOREIGN KEY (`projeto_id`) REFERENCES `projetos`(`id`) ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE `apontamento_horas` ADD CONSTRAINT `apontamento_horas_funcionario_id_fkey` FOREIGN KEY (`funcionario_id`) REFERENCES `funcionarios`(`id`) ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE `apontamento_horas` ADD CONSTRAINT `apontamento_horas_os_id_fkey` FOREIGN KEY (`os_id`) REFERENCES `ordens_servico`(`id`) ON DELETE NO ACTION ON UPDATE NO ACTION;


-- CHECK constraints (equivalentes às que existiam nas migrations PostgreSQL)
ALTER TABLE `anexos` ADD CONSTRAINT `tamanho_valido` CHECK (`tamanho_bytes` >= 0);
ALTER TABLE `anexos` ADD CONSTRAINT `anexos_tamanho_maximo` CHECK (`tamanho_bytes` <= 52428800);
ALTER TABLE `anexos` ADD CONSTRAINT `anexos_relato_tamanho` CHECK (`relato` IS NULL OR CHAR_LENGTH(`relato`) <= 2000);
ALTER TABLE `apontamento_horas` ADD CONSTRAINT `duracao_apontamento_positiva` CHECK (`duracao_minutos` > 0);
ALTER TABLE `ordens_servico` ADD CONSTRAINT `justificativa_sla_manual_obrigatoria` CHECK (`sla_manual` = 0 OR (`justificativa_sla_manual` IS NOT NULL AND CHAR_LENGTH(TRIM(`justificativa_sla_manual`)) > 0));
ALTER TABLE `ordens_servico` ADD CONSTRAINT `prazo_dias_uteis_valido` CHECK (`prazo_dias_uteis` IS NULL OR `prazo_dias_uteis` > 0);
ALTER TABLE `sla_config` ADD CONSTRAINT `prazo_valido` CHECK (`prazo_dias_uteis` IS NULL OR `prazo_dias_uteis` > 0);
