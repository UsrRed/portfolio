# INTERFACES

## API HTTP (backend :3000, JSON, CORS * )
- `GET /api/get-data` (toujours) → `PortfolioData { person: Person, domains: Domain[] (avec skills[]), languages, hobbies, soft_skills, educations, experiences, projects }`.
- Si `ENABLE_ADD_PROJECT=true` ou `ENABLE_ADMIN=true` : `/api/projects` et `/api/projects/{id}` (CRUD).
- Si `ENABLE_ADMIN=true` :
  - `POST /api/upload` multipart champ `image` (≤10 Mo) → `{url: "/user-uploads/<nanos>.<ext>"}`
  - `GET /api/image-search?q=` → `{results: [{image, thumbnail, title}]}` (400 si q vide, 502 si échec)
  - `POST /api/image-import` `{url}` → `{url}`
  - `PUT /api/person`
  - CRUD `/api/{domains,skills,languages,hobbies,soft-skills,educations,experiences}` et `/{id}` (POST/PUT/DELETE, id dans le chemin)
- Méthode non supportée → 405 ; OPTIONS → 200.

## Types (JSON)
- Person: id, first_name, last_name, driver_license, location, title, description, linkedin_url, github_url, image_url, email, phone
- Domain: id, name, skills[]; Skill: id, domain_id, name, image_url, details
- Language: id, name, level, image_url, certification_url
- Hobby / SoftSkill: id, name, image_url
- Education: id, school, school_url, degree, details, start_date, status
- Experience: id, company, company_url, role, details, start_date, duration, status
- Project: id, title, image_url, period, description, skills_human, skills_tech, link_url, hidden

## Frontend
- `ApiService` (statique, baseUrl `/api`): getData, uploadImage(file)→url, searchImages(q)→ImageSearchResult[], importImage(url)→url, updatePerson, createDomain, … (CRUD par entité).
- `ProjectPayload { title, image_url, period, description, skills_human, skills_tech, link_url, hidden? }`
- `useDataController()` → { data, loading, error, fetchData }; `useAdmin()` → { isAdminAvailable, adminMode, toggleAdminMode }.
- Env build : VITE_ENABLE_ADMIN, VITE_ENABLE_ADD_PROJECT.

## Env backend
POSTGRES_USER, POSTGRES_PASSWORD, POSTGRES_DB, ENABLE_ADMIN, ENABLE_ADD_PROJECT.