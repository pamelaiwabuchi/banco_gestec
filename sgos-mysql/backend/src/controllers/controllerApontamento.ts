/**
 * controllers/controllerApontamento.ts
 *
 * US#2.7 — rotas de horas trabalhadas da O.S. Não possui regra de negócio.
 */
import type { Request, Response } from 'express';
import { usuarioAutenticado } from '../middlewares/authMiddleware';
import { serviceApontamento } from '../services/serviceApontamento';
import { lerId } from '../utils/validacao';

export class ControllerApontamento {
    /** GET /ordens-servico/:id/horas — apontamentos e total de horas da O.S. */
    public async listar(req: Request, resp: Response): Promise<Response> {
        const id = lerId(req.params.id);
        return resp.status(200).json(await serviceApontamento.listar(id));
    }

    /** POST /ordens-servico/:id/horas — lança horas do usuário logado na O.S. */
    public async registrar(req: Request, resp: Response): Promise<Response> {
        const usuario = usuarioAutenticado(req);
        const id = lerId(req.params.id);
        return resp.status(201).json(await serviceApontamento.registrar(id, req.body, usuario.id));
    }
}

export const controllerApontamento = new ControllerApontamento();
