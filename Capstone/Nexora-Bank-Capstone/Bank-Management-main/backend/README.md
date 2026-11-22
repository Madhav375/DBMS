# Nexora Bank Backend

Copy `.env.example` to `.env` and enter the MySQL password for `nexora_user` plus a private JWT secret.

```bash
npm install
npm run setup-admin
npm start
```

Health check: `http://localhost:5000/api/health`

Default demo admin configured in `.env.example`: `admin44@gmail.com` / `admin444`.
