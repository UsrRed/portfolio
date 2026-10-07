# SPEC (reconstruite) — Portfolio personnel

## Objectif
Site vitrine mono-page d'un portfolio/CV personnel (profil, compétences, formations, expériences, langues, centres d'intérêt, soft skills, projets), avec en environnement de développement un mode d'administration permettant d'éditer le contenu en base de données. En production le site est en lecture seule.

## Fonctionnalités observées
- **F1 – Affichage du portfolio** : une page unique (`/`) charge `GET /api/get-data` et affiche les sections Présentation, Compétences (par domaine), Langues, Soft skills, Formations, Expériences, Centres d'intérêt, Projets. Critère : toutes les sections se rendent à partir d'un seul appel JSON.
- **F2 – Navigation** : barre de navigation (NavBar), animations de révélation au scroll (directive `v-reveal`, `useScrollReveal`).
- **F3 – Détail** : modale de détail (DetailModal) pour les éléments (compétence, projet, etc.).
- **F4 – CV imprimable** : composant `CvPrint` pour une version impression/CV.
- **F5 – Projets masqués** : un projet a un flag `hidden` ; exclu de `/api/get-data` quand l'admin est désactivé.
- **F6 – Ajout de projet** (`ENABLE_ADD_PROJECT`/`VITE_ENABLE_ADD_PROJECT`) : modale AddProjectModal, endpoints `/api/projects`.
- **F7 – Mode admin** (`ENABLE_ADMIN`/`VITE_ENABLE_ADMIN`, dev uniquement) : bascule adminMode, édition CRUD de person, domains, skills, languages, hobbies, soft-skills, educations, experiences, projects via EditModal.
- **F8 – Images** : upload (multipart, ≤10 Mo, JPEG/PNG redimensionnés à 1600px max, stockés dans `/uploads`, servis sous `/user-uploads/`), recadrage (ImageCropModal, ImageUploadField), recherche d'images DuckDuckGo (`/api/image-search`) et import par URL (`/api/image-import`).
- **F9 – Déploiement** : scripts deploy.sh (dev/--prod), migrate.sh, import.sh/export.sh (données), CI GitHub Actions (deploy.yml), Traefik partagé externe (HTTPS Let's Encrypt) en prod.

## Contraintes techniques
- Default-deny : endpoints de mutation seulement si les variables d'env valent exactement "true".
- PostgreSQL 16 ; init.sql joué à la création du volume ; migrations SQL via `migrate.sh` (table schema_migrations). Le backend ajoute `project.hidden` au démarrage (ALTER IF NOT EXISTS).
- Nginx : CSP stricte, en-têtes de sécurité, proxy `/api/` vers api:3000, upload max 20 Mo.
- Backend se connecte à l'hôte `db:5432` avec POSTGRES_USER/PASSWORD/DB.
- Aucun test automatisé.

## Hors périmètre
Authentification (l'admin est protégé uniquement par désactivation des endpoints), multi-utilisateur, i18n, tests automatisés, back-office en production.