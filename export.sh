#!/bin/bash
set -e

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
    echo -e "${BLUE}=== Export (production) ===${NC}"
elif [[ "$1" == "--int" ]]; then
    COMPOSE_FILES="-f docker-compose.yml -f docker-compose.int.yml"
    echo -e "${BLUE}=== Export (intégration) ===${NC}"
else
    echo -e "${BLUE}=== Export (dev) ===${NC}"
fi

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
ARCHIVE="data_export_${TIMESTAMP}.tar.gz"
TMP_DIR=$(mktemp -d)
trap "rm -rf '$TMP_DIR'" EXIT

# 1. DB dump
echo -e "${GREEN}[1/2] Dump de la base de données...${NC}"
if ! docker compose $COMPOSE_FILES exec -T db \
        pg_dump --clean --if-exists -U "$POSTGRES_USER" "$POSTGRES_DB" > "$TMP_DIR/db.sql"; then
    echo -e "${RED}✘ Impossible de joindre le container db. Les services sont-ils démarrés ?${NC}"
    exit 1
fi
echo "    → $(wc -l < "$TMP_DIR/db.sql") lignes exportées"

# 2. Uploads
echo -e "${GREEN}[2/2] Export des fichiers uploadés...${NC}"
API_CONTAINER=$(docker compose $COMPOSE_FILES ps -q api 2>/dev/null | head -1)
UPLOADS_VOLUME=""
if [ -n "$API_CONTAINER" ]; then
    UPLOADS_VOLUME=$(docker inspect "$API_CONTAINER" \
        --format '{{range .Mounts}}{{if eq .Destination "/uploads"}}{{.Name}}{{end}}{{end}}' 2>/dev/null || true)
fi

if [ -n "$UPLOADS_VOLUME" ]; then
    docker run --rm \
        -v "${UPLOADS_VOLUME}:/uploads:ro" \
        -v "${TMP_DIR}:/export" \
        alpine sh -c "tar cf /export/uploads.tar -C /uploads . 2>/dev/null; true"
    FILE_COUNT=$(docker run --rm -v "${UPLOADS_VOLUME}:/uploads:ro" alpine sh -c "find /uploads -type f | wc -l" 2>/dev/null || echo "?")
    echo "    → ${FILE_COUNT} fichier(s) exporté(s)"
else
    echo "    → volume uploads non trouvé, archive vide créée"
    tar cf "$TMP_DIR/uploads.tar" --files-from /dev/null 2>/dev/null || true
fi

# 3. Archive finale
tar czf "$ARCHIVE" -C "$TMP_DIR" db.sql uploads.tar
echo -e "\n${GREEN}✔ Export terminé : ${ARCHIVE} ($(du -sh "$ARCHIVE" | cut -f1))${NC}"
