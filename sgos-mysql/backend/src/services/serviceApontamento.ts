/**
 * services/serviceApontamento.ts
 *
 * US#2.7 — registro de horas nas O.S. Valida o formato da entrada; as regras de
 * negócio (quem pode lançar, O.S. concluída, data futura, limite de 24h/dia)
 * ficam no banco: procedure sp_registrar_horas + trigger trg_horas_bi_validacao.
 */
import { AppError } from '../errors/AppError';
import { repositoryApontamento, type ApontamentoHoras } from '../repositories/repositoryApontamento';

const TAMANHO_MAXIMO_DESCRICAO = 2000;
const DATA_ISO = /^\d{4}-\d{2}-\d{2}$/;

export interface HorasDaOrdem {
    os_id: number;
    /** Calculado pela function fn_total_horas_os. */
    total_horas: number;
    apontamentos: ApontamentoHoras[];
}

function lerEntrada(corpo: unknown): { data: string; minutos: number; descricao: string | null } {
    const dados = (typeof corpo === 'object' && corpo !== null ? corpo : {}) as Record<string, unknown>;

    const data = dados.data_trabalho;
    if (typeof data !== 'string' || !DATA_ISO.test(data) || Number.isNaN(Date.parse(`${data}T00:00:00Z`))) {
        throw AppError.requisicaoInvalida('data_trabalho deve estar no formato AAAA-MM-DD');
    }

    const minutos = dados.duracao_minutos;
    if (typeof minutos !== 'number' || !Number.isInteger(minutos) || minutos <= 0) {
        throw AppError.requisicaoInvalida('duracao_minutos deve ser um número inteiro maior que zero');
    }

    let descricao: string | null = null;
    if (dados.descricao !== undefined && dados.descricao !== null) {
        if (typeof dados.descricao !== 'string') {
            throw AppError.requisicaoInvalida('descricao deve ser um texto');
        }
        descricao = dados.descricao.trim() || null;
        if (descricao && descricao.length > TAMANHO_MAXIMO_DESCRICAO) {
            throw AppError.requisicaoInvalida(`descricao deve ter no máximo ${TAMANHO_MAXIMO_DESCRICAO} caracteres`);
        }
    }

    return { data, minutos, descricao };
}

export class ServiceApontamento {
    async listar(osId: number): Promise<HorasDaOrdem> {
        if (!(await repositoryApontamento.ordemExiste(osId))) {
            throw AppError.naoEncontrado('Ordem de serviço não encontrada');
        }
        const [apontamentos, total] = await Promise.all([
            repositoryApontamento.listarPorOrdem(osId),
            repositoryApontamento.totalHoras(osId),
        ]);
        return { os_id: osId, total_horas: total, apontamentos };
    }

    async registrar(osId: number, corpo: unknown, funcionarioId: number): Promise<HorasDaOrdem> {
        const { data, minutos, descricao } = lerEntrada(corpo);
        await repositoryApontamento.registrar(funcionarioId, osId, data, minutos, descricao);
        return this.listar(osId);
    }
}

export const serviceApontamento = new ServiceApontamento();
