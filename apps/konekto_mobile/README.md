# konekto_mobile

App Flutter do hospede da Sevvn.

## Runtime

O caminho oficial de piloto/producao agora e API-first por padrao.

- Padrao: `APP_RUNTIME_MODE=api`
- Fallback explicito de demo/dev: `APP_RUNTIME_MODE=asset`
- Alias legado ainda aceito temporariamente: `USE_API=true|false`

Se nada for informado no build, o app usa:

- `API_BASE_URL=https://sevvn-api.vercel.app`
- `APP_RUNTIME_MODE=api`

## Exemplos

Rodar contra a API oficial:

```bash
flutter run --dart-define=APP_RUNTIME_MODE=api --dart-define=API_BASE_URL=https://sevvn-api.vercel.app
```

Rodar contra API local:

```bash
flutter run --dart-define=APP_RUNTIME_MODE=api --dart-define=API_BASE_URL=http://localhost:3000
```

Rodar em modo asset local:

```bash
flutter run --dart-define=APP_RUNTIME_MODE=asset
```

## Observacao

O modo `asset` existe para fallback controlado de desenvolvimento e demonstracao.
Ele nao deve ser tratado como validacao suficiente de piloto, porque nao exercita:

- claim real de hospede
- isolamento multi-tenant real
- regras de backend
- persistencia operacional
