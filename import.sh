#!/bin/bash
set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

[ -f .env ] && set -a && source .env && set +a

usage() {
    echo "Usage: $0 <archive.tar.gz> [--prod|--int]"
    echo "  archive  : fichier généré par export.sh"
    echo "  --prod   : cible l'environnement production"
    echo "  --int    : cible l'environnement intégration"
    exit 1
}

ARCHIVE=""
COMPOSE_FILES=""
ENV_LABEL="dev"

for arg in "$@"; do
    case "$arg" in
        --prod) COMPOSE_FILES="-f docker-compose.yml -f docker-compose.prod.yml"; ENV_LABEL="production" ;;
        --int)  COMPOSE_FILES="-f docker-compose.yml -f docker-compose.int.yml";  ENV_LABEL="intégration" ;;
        *.tar.gz) ARCHIVE="$arg" ;;
    esac
done

[ -z "$ARCHIVE" ] && usage
[ ! -f "$ARCHIVE" ] && echo -e "${RED}✘ Fichier introuvable : $ARCHIVE${NC}" && exit 1

echo -e "${BLUE}=== Import des données (${ENV_LABEL}) ===${NC}"
echo -e "${YELLOW}⚠  Les données existantes seront écrasées.${NC}"
echo -ne "   Continuer ? [y/N] "; read -r confirm </dev/tty
[[ "$confirm" =~ ^[Yy]$ ]] || { echo "Annulé."; exit 0; }

TMP_DIR=$(mktemp -d)
trap "rm -rf '$TMP_DIR'" EXIT

# Extraction
echo -e "\n${GREEN}[0/2] Extraction de l'archive...${NC}"
tar xzf "$ARCHIVE" -C "$TMP_DIR"
[ ! -f "$TMP_DIR/db.sql" ]      && echo -e "${RED}✘ db.sql manquant dans l'archive${NC}"      && exit 1
[ ! -f "$TMP_DIR/uploads.tar" ] && echo -e "${RED}✘ uploads.tar manquant dans l'archive${NC}" && exit 1

# 1. DB restore
echo -e "${GREEN}[1/2] Restauration de la base de données...${NC}"
if ! docker compose $COMPOSE_FILES exec -T db psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" \
        < "$TMP_DIR/db.sql" > /dev/null 2>&1; then
    echo -e "${RED}✘ Échec de la restauration BDD. Les services sont-ils démarrés ?${NC}"
    exit 1
fi
echo "    → Base de données restaurée"

# 2. Uploads restore
echo -e "${GREEN}[2/2] Restauration des fichiers uploadés...${NC}"
API_CONTAINER=$(docker compose $COMPOSE_FILES ps -q api 2>/dev/null | head -1)
UPLOADS_VOLUME=""
if [ -n "$API_CONTAINER" ]; then
    UPLOADS_VOLUME=$(docker inspect "$API_CONTAINER" \
        --format '{{range .Mounts}}{{if eq .Destination "/uploads"}}{{.Name}}{{end}}{{end}}' 2>/dev/null || true)
fi

if [ -n "$UPLOADS_VOLUME" ]; then
    docker run --rm \
        -v "${UPLOADS_VOLUME}:/uploads" \
        -v "${TMP_DIR}:/import" \
        alpine sh -c "rm -rf /uploads/* /uploads/.[!.]* 2>/dev/null; tar xf /import/uploads.tar -C /uploads"
    FILE_COUNT=$(docker run --rm -v "${UPLOADS_VOLUME}:/uploads:ro" alpine sh -c "find /uploads -type f | wc -l" 2>/dev/null || echo "?")
    echo "    → ${FILE_COUNT} fichier(s) restauré(s)"
else
    echo -e "${YELLOW}    ⚠  Volume uploads non trouvé, fichiers ignorés${NC}"
fi

echo -e "\n${GREEN}✔ Import terminé !${NC}"
