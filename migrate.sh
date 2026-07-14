#!/bin/bash
set -e

# Applique les migrations de schéma (db/structure/migration_*.sql) sur la BDD
# en cours d'exécution. Chaque migration n'est appliquée qu'une seule fois :
# le suivi est stocké dans la table schema_migrations.
# Appelé automatiquement par ./deploy.sh et ./import.sh, utilisable seul :
#   ./migrate.sh [--prod|--int]

GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

[ -f .env ] && set -a && source .env && set +a

COMPOSE_FILES=""
if [[ "$1" == "--prod" ]]; then
    COMPOSE_FILES="-f docker-compose.yml -f docker-compose.prod.yml"
elif [[ "$1" == "--int" ]]; then
    COMPOSE_FILES="-f docker-compose.yml -f docker-compose.int.yml"
fi

PSQL() {
    docker compose $COMPOSE_FILES exec -T db psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" "$@"
}

if ! PSQL -q -c "SELECT 1" >/dev/null 2>&1; then
    echo -e "${RED}✘ Impossible de joindre la BDD. Les services sont-ils démarrés ?${NC}"
    exit 1
fi

# Table de suivi (créée au besoin : BDD anciennes ou restaurées depuis une
# backup antérieure à ce mécanisme).
PSQL -q -v ON_ERROR_STOP=1 -c \
    "CREATE TABLE IF NOT EXISTS schema_migrations (
        filename   TEXT PRIMARY KEY,
        applied_at TIMESTAMPTZ NOT NULL DEFAULT now()
    );" >/dev/null

APPLIED=0
SKIPPED=0
for mig in db/structure/migration_*.sql; do
    [ -e "$mig" ] || continue
    name=$(basename "$mig")
    found=$(PSQL -tA -c "SELECT 1 FROM schema_migrations WHERE filename = '$name'")
    if [ "$found" = "1" ]; then
        SKIPPED=$((SKIPPED + 1))
        continue
    fi
    echo -e "${BLUE}   → Migration ${name}...${NC}"
    if ! PSQL -q -v ON_ERROR_STOP=1 < "$mig" >/dev/null; then
        echo -e "${RED}✘ Échec de la migration ${name}${NC}"
        exit 1
    fi
    PSQL -q -v ON_ERROR_STOP=1 -c \
        "INSERT INTO schema_migrations (filename) VALUES ('$name');" >/dev/null
    APPLIED=$((APPLIED + 1))
done

echo -e "${GREEN}   ✔ Migrations : ${APPLIED} appliquée(s), ${SKIPPED} déjà en place.${NC}"
