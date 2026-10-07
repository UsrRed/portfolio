# ARCHITECTURE (carte du dépôt)

```
backend/                 API Go (stdlib net/http + lib/pq), go 1.24
  src/main.go            (~1280 lignes) tout le backend: modèles, routes, handlers CRUD, images, fetchPortfolioData
  Dockerfile, go.mod
frontend/                SPA Vue 3 + Vite + TS (deps: vue, vue-router)
  index.html, vite.config.ts, nginx.conf, Dockerfile
  public/                images, docs/certification_cambridge.pdf, robots.txt, sitemap.xml
  src/main.ts, App.vue, style.css
  src/router/index.ts    route unique '/' -> HomeView
  src/views/HomeView.vue assemble les sections
  src/components/        NavBar, PresentationSection, SkillSection, LanguageSection, SoftSkillSection,
                         EducationSection, ExperienceSection, HobbySection, ProjectSection,
                         DetailModal, EditModal, AddProjectModal, ImageCropModal, ImageUploadField, CvPrint
  src/controllers/useDataController.ts  charge les données (data/loading/error/fetchData)
  src/composables/       useAdmin.ts (VITE_ENABLE_ADMIN, adminMode), useScrollReveal.ts
  src/directives/vReveal.ts
  src/services/api.service.ts  classe statique ApiService (fetch vers /api)
db/structure/            init.sql (tables) + migration_2026-07-14_*.sql
docker-compose.yml       services frontend (nginx), api, db (postgres:16-alpine), volumes db_data/uploads
docker-compose.override.yml  dev: port 127.0.0.1:${PORT}:80, admin activé
docker-compose.prod.yml  prod: Traefik labels, réseau externe site-portfolio, admin off
docker-compose.int.yml   variante intégration
deploy.sh migrate.sh import.sh export.sh  scripts d'exploitation
.env.model               modèle de variables (POSTGRES_*, DOMAIN, PORT, SERVER_IP)
.github/workflows/deploy.yml  CI/CD
docs/PROGRESS.md
```

## Flux
Navigateur → nginx (frontend) → statique SPA ; `/api/*` proxifié vers api:3000 → PostgreSQL (db). `/user-uploads/*` servi par nginx depuis le volume `uploads` (écrit par l'API sur `/uploads`).
Au chargement : HomeView → useDataController → ApiService.getData → GET /api/get-data → fetchPortfolioData (agrège toutes les tables, skills imbriqués dans domains).
Mode admin : composants → ApiService (POST/PUT/DELETE) → handlers CRUD.

## Tables (init.sql)
schema_migrations, person, domain, skill (FK domain), language, hobby, soft_skill, education, experience, project (hidden).

## Dépendances
Go : github.com/lib/pq. Front : vue ^3.5, vue-router ^4, vite ^7, vue-tsc, typescript ~5.9.