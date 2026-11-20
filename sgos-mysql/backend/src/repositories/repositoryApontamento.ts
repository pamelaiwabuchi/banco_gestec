/**
 * repositories/repositoryApontamento.ts
 *
 * US#2.7 — registro de horas trabalhadas nas O.S. (Parte 5 da avaliação de BDR).
 *
 * Esta funcionalidade usa programação no banco MySQL em vez de regras no Node:
 *  - stored procedure `sp_registrar_horas`: valida e grava o apontamento
 *    (O.S. não concluída; funcionário responsável ou da equipe da O.S.);
 *  - trigger `trg_horas_bi_validacao`: barra data futura e mais de 24h por dia
 *    (disparado automaticamente pelo INSERT da procedure);
 *  - function `fn_total_horas_os`: soma as horas já lançadas na O.S.
 *
 * Erros de regra disparados no banco com SIGNAL SQLSTATE '45000' (código MySQL 1644)
 * viram AppError 400 com a mesma mensagem escrita na procedure/trigger.
 */
import { prisma } from '../prisma/client';
import { Prisma } from '../prisma/generated/client';
import { AppError } from '../errors/AppError';

/** Código de erro do MySQL/MariaDB para SIGNAL SQLSTATE '45000' (erro definido pelo usuário). */
const ERRO_REGRA_DO_BANCO = '1644';

export interface ApontamentoHoras {
    id: number;
    os_id: number;
    data_trabalho: Date;
    duracao_minutos: number;
    descricao: string | null;
    data_criacao: Date;
    funcionarios: { id: number; nome: string };
}

/**
 * Converte o erro de SIGNAL vindo do banco em AppError 400.
 * Com driver adapter, o Prisma embala o erro do MySQL numa mensagem do tipo
 * "Raw query failed. Code: `1644`. Message: `<texto do SIGNAL>`".
 */
function traduzirErroDoBanco(erro: unknown): unknown {
    if (!(erro instanceof Prisma.PrismaClientKnownRequestError)) return erro;

    const texto = erro.message;
    const codigo = /Code: `(\d+)`/.exec(texto)?.[1];
    if (codigo !== ERRO_REGRA_DO_BANCO) return erro;

    const mensagem = /Message: `([^`]*)`/.exec(texto)?.[1];
    return AppError.requisicaoInvalida(mensagem ?? 'Operação recusada pelas regras do banco de dados');
}

export class RepositoryApontamento {
    /** Chama a stored procedure sp_registrar_horas (o trigger de validação dispara junto). */
    async registrar(
        funcionarioId: number,
        osId: number,
        dataTrabalho: string,
        minutos: number,
        descricao: string | null,
    ): Promise<void> {
        try {
            await prisma.$executeRaw`CALL sp_registrar_horas(${funcionarioId}, ${osId}, ${dataTrabalho}, ${minutos}, ${descricao})`;
        } catch (erro) {
            throw traduzirErroDoBanco(erro);
        }
    }

    /** Chama a function fn_total_horas_os: total de horas lançadas na O.S. */
    async totalHoras(osId: number): Promise<number> {
        const [linha] = await prisma.$queryRaw<Array<{ total: unknown }>>`SELECT fn_total_horas_os(${osId}) AS total`;
        return Number(linha?.total ?? 0);
    }

    /** Lista os apontamentos da O.S. com o nome de quem lançou, mais recentes primeiro. */
    async listarPorOrdem(osId: number): Promise<ApontamentoHoras[]> {
        return prisma.apontamento_horas.findMany({
            where: { os_id: osId },
            select: {
                id: true,
                os_id: true,
                data_trabalho: true,
                duracao_minutos: true,
                descricao: true,
                data_criacao: true,
                funcionarios: { select: { id: true, nome: true } },
            },
            orderBy: [{ data_trabalho: 'desc' }, { id: 'desc' }],
        });
    }

    /** Confere se a O.S. existe (para responder 404 em vez de lista vazia). */
    async ordemExiste(osId: number): Promise<boolean> {
        const os = await prisma.ordens_servico.findUnique({ where: { id: osId }, select: { id: true } });
        return os !== null;
    }
}

export const repositoryApontamento = new RepositoryApontamento();
