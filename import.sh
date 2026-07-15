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
    echo "Usage: $0 [archive.tar.gz] [--prod|--int]"
    echo "  archive  : fichier généré par export.sh"
    echo "             (défaut : dernière archive du dossier backups/)"
    echo "  --prod   : cible l'environnement production"
    echo "  --int    : cible l'environnement intégration"
    exit 1
}

ARCHIVE=""
COMPOSE_FILES=""
ENV_LABEL="dev"
ENV_FLAG=""
BACKUP_DIR="backups"

for arg in "$@"; do
    case "$arg" in
        --prod) COMPOSE_FILES="-f docker-compose.yml -f docker-compose.prod.yml"; ENV_LABEL="production"; ENV_FLAG="--prod" ;;
        --int)  COMPOSE_FILES="-f docker-compose.yml -f docker-compose.int.yml";  ENV_LABEL="intégration"; ENV_FLAG="--int" ;;
        -h|--help) usage ;;
        *.tar.gz) ARCHIVE="$arg" ;;
    esac
done

# Sans archive explicite : prend la plus récente du dossier backups/
if [ -z "$ARCHIVE" ]; then
    ARCHIVE=$(ls -1t "$BACKUP_DIR"/*.tar.gz 2>/dev/null | head -1 || true)
    if [ -z "$ARCHIVE" ]; then
        echo -e "${RED}✘ Aucune archive trouvée dans ${BACKUP_DIR}/${NC}"
        usage
    fi
    echo -e "${BLUE}→ Archive la plus récente sélectionnée : ${ARCHIVE}${NC}"
fi

[ ! -f "$ARCHIVE" ] && echo -e "${RED}✘ Fichier introuvable : $ARCHIVE${NC}" && exit 1

echo -e "${BLUE}=== Import des données (${ENV_LABEL}) ===${NC}"
echo -e "${YELLOW}⚠  Les données existantes seront écrasées.${NC}"
echo -ne "   Continuer ? [y/N] "; read -r confirm </dev/tty
[[ "$confirm" =~ ^[Yy]$ ]] || { echo "Annulé."; exit 0; }

# Temp dir dans le projet : docker installé via snap ne peut pas monter /tmp
TMP_DIR=$(mktemp -d "${SCRIPT_DIR}/.backup_tmp.XXXXXX")
trap "rm -rf '$TMP_DIR'" EXIT

# Extraction
echo -e "\n${GREEN}[0/2] Extraction de l'archive...${NC}"
tar xzf "$ARCHIVE" -C "$TMP_DIR"
[ ! -f "$TMP_DIR/db.sql" ]      && echo -e "${RED}✘ db.sql manquant dans l'archive${NC}"      && exit 1
[ ! -f "$TMP_DIR/uploads.tar" ] && echo -e "${RED}✘ uploads.tar manquant dans l'archive${NC}" && exit 1

# 1. DB restore
echo -e "${GREEN}[1/2] Restauration de la base de données...${NC}"
# Anciennes backups : neutralise les ALTER ... OWNER TO / GRANT référençant un
# rôle qui n'existe plus (ex: "superUser") — les nouvelles backups sont dumpées
# avec --no-owner --no-privileges.
sed -E -i -e '/^ALTER .* OWNER TO .*;$/d' -e '/^(GRANT|REVOKE) /d' "$TMP_DIR/db.sql"

if ! docker compose $COMPOSE_FILES exec -T db psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" \
        -v ON_ERROR_STOP=1 --single-transaction \
        < "$TMP_DIR/db.sql" > /dev/null; then
    echo -e "${RED}✘ Échec de la restauration BDD (voir l'erreur ci-dessus).${NC}"
    exit 1
fi
echo "    → Base de données restaurée"

# La backup peut dater d'un schéma plus ancien que le code : rattrapage
# des migrations, sinon l'API répond en erreur 500.
"$SCRIPT_DIR/migrate.sh" $ENV_FLAG

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
