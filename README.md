# Portfolio

Code source de mon portfolio, en ligne sur **[yohann.denoyelle.eu](https://yohann.denoyelle.eu)**.

Le site présente mon parcours (compétences, expériences, formations, projets) et génère un CV imprimable directement depuis le navigateur. Le contenu est stocké en base et s'édite depuis une interface d'administration, désactivée en production.

## Stack

| Couche | Technologies |
|---|---|
| Frontend | Vue 3, TypeScript, Vite, servi par nginx |
| API | Go (`net/http`, `lib/pq`) |
| Base de données | PostgreSQL 16 |
| Infrastructure | Docker Compose, Traefik (HTTPS), serveur Scaleway |
| CI/CD | GitHub Actions : déploiement automatique à chaque push sur `prod` |

## Points de sécurité

- **Mutations refusées par défaut** : les routes d'écriture (CRUD, upload) n'existent que si `ENABLE_ADMIN=true`. En production, l'API n'expose que la lecture (`GET /api/get-data`).
- **Base de données isolée** : PostgreSQL n'est joignable que depuis le réseau Docker interne de l'API.
- **SSH invisible** : le port SSH du serveur est fermé à tous. La CI l'ouvre 30 secondes, pour sa seule adresse IP, grâce à un paquet [fwknop](https://www.cipherdyne.org/fwknop/) chiffré et signé (Single Packet Authorization).
- **HTTPS forcé** : redirection HTTP vers HTTPS via Traefik.

## Lancer en local

```bash
cp .env.model .env      # puis renseigner les variables POSTGRES_*, PORT…
./deploy.sh             # dev : interface d'admin activée, écoute sur 127.0.0.1:$PORT
```

| Script | Rôle |
|---|---|
| `deploy.sh [--prod\|--int]` | Construit et démarre la stack, puis applique les migrations |
| `migrate.sh` | Applique une seule fois chaque migration de `db/structure/` |
| `export.sh` / `import.sh` | Sauvegarde et restauration du contenu de la base |

## Organisation

```
frontend/   SPA Vue 3 (sections du portfolio, modales d'édition, CV imprimable)
backend/    API Go
db/         schéma initial et migrations
docs/       spécification et architecture
```

Le détail se trouve dans [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md).

## Licence

MIT
