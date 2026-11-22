# Nexora Bank — Employee Login + MySQL

Educational/demo banking management project. Use fictional data only; this is not a real banking system and must not be used to store real customer information or process real money.

## Login configured by default

- Work email: `admin44@gmail.com`
- Password: `admin444`

The admin account is created/updated by the setup command using the values in `backend/.env`.

## 1. Requirements

- Node.js (18 or newer)
- MySQL Server and MySQL Workbench

## 2. Prepare the database

If you already have the Nexora database and banking tables, do not run `database/nexora_bank.sql` again because that file drops and recreates the demo banking tables.

For an existing `nexora_bank` database, open MySQL Workbench and run:

```sql
USE nexora_bank;
```

Then run the contents of `database/employee_auth.sql` to create the employee users table if it does not exist. The backend also creates the users table automatically if it is missing.

For a brand-new database only, run `database/nexora_bank.sql` once.

## 3. Configure backend

1. Open the `backend` folder.
2. Copy `.env.example` and rename the copy to `.env`.
3. In `.env`, replace `DB_PASSWORD` with the password for your MySQL account `nexora_user` (not necessarily the MySQL `root` password).
4. Keep the admin email and password as shown above, or change them to your own private values.
5. Replace `JWT_SECRET` with a private random string of at least 32 characters.

Do not share `.env` or publish it to GitHub.

## 4. Install dependencies

Open a terminal in the project root:

```bash
npm install
```

Open a second terminal in `backend`:

```bash
npm install
npm run setup-admin
npm start
```

Keep the backend terminal running. Test it at:

`http://localhost:5000/api/health`

Expected response:

```json
{"ok":true,"database":"connected"}
```

## 5. Start frontend

Open a third terminal in the project root:

```bash
npm run dev
```

Open `http://localhost:5173` and sign in with the configured admin email and password.

The Vite development server proxies `/api` requests to the backend on port 5000, so the frontend and backend use the same browser origin for login cookies.

## 6. Daily startup

1. Start MySQL Server.
2. In `backend`: `npm start`.
3. In project root: `npm run dev`.
4. Open `http://localhost:5173`.

Do not close either terminal while using the app.
