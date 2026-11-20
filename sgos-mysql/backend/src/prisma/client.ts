/**
 * prisma/client.ts
 *
 * Instância única do Prisma Client, conectada ao MySQL/MariaDB pelo driver adapter `mariadb`.
 * Todo acesso ao banco deve importar `prisma` daqui — nunca criar outro `new PrismaClient()`.
 */
import "dotenv/config";
import { PrismaMariaDb } from "@prisma/adapter-mariadb";
import { PrismaClient } from "./generated/client";

const connectionString = process.env.DATABASE_URL?.trim();
if (!connectionString) {
    throw new Error(
        'Variável de ambiente obrigatória ausente: DATABASE_URL. ' +
            'Confira o arquivo backend/.env (o modelo está em backend/.env.example).',
    );
}

// O adapter aceita a URL no formato mysql://usuario:senha@host:3306/banco
const adapter = new PrismaMariaDb(connectionString);

export const prisma = new PrismaClient({ adapter });
