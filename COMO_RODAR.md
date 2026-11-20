# Como rodar o projeto na sua máquina

Guia passo a passo para montar o banco **gestec** em MySQL e (opcionalmente) rodar o sistema SGOS ligado a ele.

> Resumo: **1)** baixar o repositório → **2)** instalar MySQL e DBeaver → **3)** criar o banco e o usuário →
> **4)** conectar no DBeaver → **5)** rodar os scripts SQL na ordem → **6)** (Parte 5) rodar o sistema.

---

## 1. Baixar o repositório

```bash
git clone https://github.com/pamelaiwabuchi/banco_gestec.git
cd banco_gestec
```

Sem git? No GitHub, clique em **Code → Download ZIP** e extraia a pasta.

---

## 2. Instalar o que precisa

| Programa | Para quê | Onde baixar |
|---|---|---|
| **MySQL 8** (ou MariaDB 10.6+) | Servidor do banco | Windows: [MySQL Installer](https://dev.mysql.com/downloads/installer/) |
| **DBeaver Community** | Tela para ver e rodar SQL | [dbeaver.io/download](https://dbeaver.io/download/) |
| **Node.js 22+** | Só para a Parte 5 (rodar o sistema) | [nodejs.org](https://nodejs.org/) (versão LTS) |

**Windows:** no MySQL Installer, escolha **"Server only"** (ou "Developer Default"). Durante a instalação ele pede
uma **senha para o usuário `root`** — anote, ela é usada no passo 3. Deixe a porta padrão **3306**.

**Linux (Arch/Manjaro):** `sudo pacman -S mariadb` e depois
`sudo mariadb-install-db --user=mysql --basedir=/usr --datadir=/var/lib/mysql && sudo systemctl enable --now mariadb`.
**Linux (Ubuntu/Debian):** `sudo apt install mysql-server`.

---

## 3. Criar o banco e o usuário (uma vez só)

Você precisa entrar como administrador (`root`) e rodar o SQL abaixo. Troque `SUA_SENHA` por uma senha à sua escolha
para o usuário do banco.

```sql
CREATE DATABASE gestec CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'gestec'@'localhost' IDENTIFIED BY 'SUA_SENHA';
GRANT ALL PRIVILEGES ON gestec.* TO 'gestec'@'localhost';
SET GLOBAL log_bin_trust_function_creators = 1;
```

Onde rodar isso:

- **Windows:** abra o DBeaver, crie uma conexão MySQL com usuário **`root`** e a senha da instalação (mesmo passo a
  passo do item 4, mas deixando o campo "Banco de dados" vazio), abra um editor SQL nela, cole o SQL acima e rode com
  **`Alt+X`**.
- **Linux:** no terminal, `sudo mariadb` (ou `sudo mysql`), cole o SQL e pressione Enter.

> ⚠️ `SET GLOBAL log_bin_trust_function_creators = 1` libera a criação de functions e triggers, mas **é perdido quando
> o computador reinicia**. Se aparecer erro *"You do not have the SUPER privilege and binary logging is enabled"* ao
> rodar o script 03, rode essa linha de novo como `root`.

---

## 4. Conectar o DBeaver ao banco

1. Clique em **Nova Conexão** (ícone de tomada com `+`) → escolha **MySQL** → **Avançar**.
2. Preencha:
   - **Host:** `localhost`
   - **Porta:** `3306`
   - **Banco de dados:** `gestec`
   - **Usuário:** `gestec`
   - **Senha:** a que você definiu no passo 3
3. Clique em **Testar conexão** (se pedir para baixar o driver, aceite) → **Concluir**.

> Se der erro *"Public Key Retrieval is not allowed"* (comum no MySQL 8): na mesma tela, aba **Propriedades do driver**,
> mude `allowPublicKeyRetrieval` para `true`.

---

## 5. Rodar os scripts SQL — nesta ordem

Para cada arquivo: clique na conexão `gestec` → **Editor SQL → Novo script** (ou `Ctrl+]`) → cole o conteúdo do
arquivo → rode o script **inteiro** com **`Alt+X`** (não use `Ctrl+Enter`, que roda só uma linha).

| Ordem | Arquivo | O que faz |
|---|---|---|
| 1 | `scripts/01_create_tables.sql` | Cria as 15 tabelas, chaves e restrições |
| 2 | `scripts/02_inserts.sql` | Insere os dados (no final mostra a contagem por tabela) |
| 3 | `scripts/03_programacao.sql` | Procedures, functions, triggers e views |
| 4 | `scripts/04_testes.sql` | Um teste por item — rode **um bloco por vez** (ver [PASSO_A_PASSO.md](PASSO_A_PASSO.md)) |

Depois clique com o botão direito na conexão → **Atualizar** (`F5`) para ver as tabelas.

Os scripts podem ser rodados de novo sem problema: o 01 apaga e recria as tabelas e o 02 esvazia antes de inserir.

---

## 6. (Parte 5) Rodar o sistema SGOS ligado ao banco

Precisa do Node.js 22+ e dos passos 3 a 5 já feitos.

### 6.1 Backend (API)

```bash
cd sgos-mysql/backend
npm install
```

Copie o arquivo de configuração:

- Windows (PowerShell): `Copy-Item .env.example .env`
- Linux/macOS: `cp .env.example .env`

Abra o `.env` e ajuste **somente** estas linhas (troque `SUA_SENHA` pela senha do usuário `gestec`):

```env
DATABASE_URL="mysql://gestec:SUA_SENHA@localhost:3306/gestec"
DIRECT_URL="mysql://gestec:SUA_SENHA@localhost:3306/gestec"
SHADOW_DATABASE_URL="mysql://gestec:SUA_SENHA@localhost:3306/gestec_shadow"
JWT_SECRET=qualquer_texto_aleatorio_com_pelo_menos_32_caracteres_aqui
```

> Se a senha tiver caracteres especiais (`@ : / # %`), eles precisam ser codificados na URL (ex.: `@` vira `%40`).

Gere o cliente do banco e suba a API:

```bash
npx prisma generate
npm run dev
```

A API fica em `http://localhost:3000`.

> ❌ **Não rode** `npx prisma migrate` nem `npm run db:seed`: as tabelas e os dados já foram criados pelos scripts SQL.

### 6.2 Frontend (tela do sistema) — em outro terminal

```bash
cd sgos-mysql/frontend
npm install
```

Copie `.env.example` para `.env` (o valor padrão `VITE_API_URL=http://localhost:3000` já funciona) e rode:

```bash
npm run dev
```

Abra o endereço que aparecer (normalmente `http://localhost:5173`) e entre com:

- usuário **`gestor.bdr`**, senha **`Senha@123`** (ou `tecnico.bdr`)

> Upload de anexos usa um serviço externo (Supabase Storage) que não está configurado aqui — essas telas podem
> responder erro 503. Isso é esperado e não afeta o trabalho de banco de dados.

---

## Problemas comuns

| Erro | Solução |
|---|---|
| `Access denied for user 'gestec'@'localhost'` | Senha errada no DBeaver ou no `.env`. Confira a senha do passo 3. |
| `Unknown database 'gestec'` | O passo 3 não foi feito (ou foi feito em outro servidor/porta). |
| `Can't connect to MySQL server on 'localhost'` | O MySQL não está rodando. Windows: abra **Serviços** e inicie "MySQL80". Linux: `sudo systemctl start mariadb`. |
| `Table 'gestec.xxx' doesn't exist` | Rode os scripts na ordem: primeiro o 01, depois o 02. |
| `You do not have the SUPER privilege and binary logging is enabled` | Rode `SET GLOBAL log_bin_trust_function_creators = 1;` como `root` (ver passo 3). |
| `Cannot find module './generated/client'` | Faltou rodar `npx prisma generate` no `sgos-mysql/backend` (com o `.env` já preenchido). |
