/**
 * utils/travaTransacional.ts
 *
 * Substitui o `pg_advisory_xact_lock` do PostgreSQL no MySQL/MariaDB.
 *
 * Grava (ou reaproveita) uma linha da tabela `travas` com a chave informada. O INSERT ... ON
 * DUPLICATE KEY UPDATE adquire um lock exclusivo dessa linha, que o InnoDB só libera no COMMIT
 * ou ROLLBACK — o mesmo comportamento do advisory lock transacional. Deve ser chamado dentro de
 * `prisma.$transaction`.
 */
import type { Prisma } from '../prisma/generated/client';

/** Trava global que serializa alterações no conjunto de Gestores ativos e atribuições. */
export const TRAVA_GESTORES = 'gestores';

export async function adquirirTrava(conexao: Prisma.TransactionClient, chave: string): Promise<void> {
    await conexao.$executeRaw`
        INSERT INTO travas (chave) VALUES (${chave})
        ON DUPLICATE KEY UPDATE chave = chave
    `;
}
