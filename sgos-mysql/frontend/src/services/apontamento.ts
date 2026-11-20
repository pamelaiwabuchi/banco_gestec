import { apiRequest } from "./api";

/** Um lançamento de horas (tabela apontamento_horas). */
export interface ApontamentoHoras {
    id: number;
    os_id: number;
    data_trabalho: string;
    duracao_minutos: number;
    descricao: string | null;
    data_criacao: string;
    funcionarios: { id: number; nome: string };
}

/** Resposta de GET/POST /ordens-servico/:id/horas. */
export interface HorasDaOrdem {
    os_id: number;
    /** Calculado no banco pela function fn_total_horas_os. */
    total_horas: number;
    apontamentos: ApontamentoHoras[];
}

export interface NovoApontamento {
    /** AAAA-MM-DD */
    data_trabalho: string;
    duracao_minutos: number;
    descricao?: string;
}

/** US#2.7 — horas trabalhadas na O.S. (procedure sp_registrar_horas no banco). */
export const apontamentoService = {
    listar(osId: number): Promise<HorasDaOrdem> {
        return apiRequest<HorasDaOrdem>(`/ordens-servico/${osId}/horas`);
    },

    registrar(osId: number, dados: NovoApontamento): Promise<HorasDaOrdem> {
        return apiRequest<HorasDaOrdem>(`/ordens-servico/${osId}/horas`, {
            method: "POST",
            body: JSON.stringify(dados),
        });
    },
};
