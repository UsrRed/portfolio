#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

error_exit() {
    echo -e "\n${RED}✘ ERREUR à l'étape : $1${NC}"
    echo -e "${RED}Le déploiement a été stoppé.${NC}"
    exit 1
}

check_port() {
    local port=$1
    local label=$2

    if [ -z "$(ss -tlnp "sport = :${port}" 2>/dev/null | tail -n +2)" ]; then
        return 0
    fi

    echo -e "${RED}⚠  Port ${port} (${label}) déjà occupé.${NC}"

    local container
    container=$(docker ps --filter "publish=${port}" --format "{{.Names}}" 2>/dev/null | head -1)

    if [ -n "$container" ]; then
        echo -e "   → Container Docker : ${container}"
        echo -ne "   Arrêter ce container ? [y/N] " >&2; read -r rep </dev/tty
        if [[ "$rep" =~ ^[Yy]$ ]]; then
            docker stop "$container"
            echo -e "${GREEN}   Container arrêté.${NC}"
        else
            error_exit "Port ${port} non libéré"
        fi
    else
        local pid
        pid=$(ss -tlnp "sport = :${port}" 2>/dev/null | tail -n +2 | grep -oP '(?<=pid=)\d+' | head -1)
        local proc=""
        [ -n "$pid" ] && proc=$(ps -p "$pid" -o comm= 2>/dev/null)
        echo -e "   → Processus : ${proc:-inconnu} (PID ${pid:-?})"
        echo -ne "   Tuer ce processus (kill) ? [y/N] " >&2; read -r rep </dev/tty
        if [[ "$rep" =~ ^[Yy]$ ]]; then
            [ -n "$pid" ] && kill "$pid" || error_exit "Impossible de tuer PID ${pid}"
            echo -e "${GREEN}   Processus arrêté.${NC}"
        else
            error_exit "Port ${port} non libéré"
        fi
    fi
}

# Gestion de l'environnement
IS_PROD=false
COMPOSE_FILES=""

if [[ "$1" == "--prod" ]]; then
    IS_PROD=true
    COMPOSE_FILES="-f docker-compose.yml -f docker-compose.prod.yml"
    echo -e "${BLUE}=== Démarrage du déploiement en PRODUCTION (HTTPS) ===${NC}\n"
elif [[ "$1" == "--int" ]]; then
    COMPOSE_FILES="-f docker-compose.yml -f docker-compose.int.yml"
    echo -e "${BLUE}=== Démarrage du déploiement en INTEGRATION ===${NC}\n"
else
    echo -e "${BLUE}=== Démarrage du déploiement (Dev) ===${NC}\n"
fi

# Chargement du .env (génère depuis .env.model si absent)
if [ ! -f .env ]; then
    cp .env.model .env
    echo -e "${BLUE}→ .env créé depuis .env.model${NC}"
fi

# Charge les variables .env dans le shell pour les utiliser dans ce script
set -a; source .env; set +a

# En production, vérifie la synchronisation git
if [ "$IS_PROD" = true ]; then
    echo -e "${BLUE}→ Vérification de la synchronisation git...${NC}"
    if ! git fetch --quiet 2>/dev/null; then
        echo -e "${YELLOW}   ⚠ Impossible de contacter le remote git (réseau ?). On continue.${NC}"
    else
        LOCAL=$(git rev-parse HEAD)
        REMOTE=$(git rev-parse '@{u}' 2>/dev/null || echo "")
        if [ -z "$REMOTE" ]; then
            echo -e "${YELLOW}   ⚠ Aucune branche upstream configurée — vérification ignorée.${NC}"
        elif [ "$LOCAL" != "$REMOTE" ]; then
            BEHIND=$(git rev-list --count HEAD..@{u})
            echo -e "${YELLOW}   ⚠ La branche locale est en retard de ${BEHIND} commit(s) par rapport au remote.${NC}"
            echo -ne "   ${YELLOW}Faire un git pull maintenant ?${NC} [y/N] " >&2; read -r rep </dev/tty
            if [[ "$rep" =~ ^[Yy]$ ]]; then
                git pull || error_exit "git pull"
                echo -e "${GREEN}   ✔ Dépôt mis à jour.${NC}"
            else
                echo -e "${YELLOW}   → Déploiement avec le code local (non à jour).${NC}"
            fi
        else
            echo -e "${GREEN}   ✔ Dépôt à jour.${NC}"
        fi
    fi
fi

# En production, détecte et injecte SERVER_IP automatiquement
if [ "$IS_PROD" = true ]; then
    DETECTED_IP=$(curl -s --max-time 5 https://api.ipify.org 2>/dev/null \
        || curl -s --max-time 5 https://ifconfig.me 2>/dev/null \
        || hostname -I | awk '{print $1}')
    if [ -z "$DETECTED_IP" ]; then
        error_exit "Impossible de détecter l'IP publique du serveur (SERVER_IP)"
    fi
    export SERVER_IP="$DETECTED_IP"
    if grep -q "^SERVER_IP=" .env; then
        sed -i "s/^SERVER_IP=.*/SERVER_IP=${DETECTED_IP}/" .env
    else
        echo "SERVER_IP=${DETECTED_IP}" >> .env
    fi
    echo -e "${BLUE}→ SERVER_IP détecté : ${DETECTED_IP}${NC}"

    # Validation des variables requises pour le certificat SSL
    if [ -z "${DOMAIN}" ]; then
        echo -e "${RED}Erreur : DOMAIN doit être défini dans .env (ex: DOMAIN=monportfolio.com)${NC}"
        echo -e "${RED}Le domaine doit pointer vers l'IP ${DETECTED_IP} avant de déployer.${NC}"
        exit 1
    fi
fi

# 0. Vérification si Docker est installé
echo -e "${GREEN}[0/5] Vérification de l'environnement...${NC}"
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Erreur : Docker n'est pas installé sur votre système.${NC}"
    echo -e "Lancer : sudo apt update && sudo apt install docker.io docker-compose-v2"
    exit 1
fi

# 1. Nettoyage
echo -e "${GREEN}[1/5] Nettoyage des anciens conteneurs...${NC}"

EXTRA_DOWN_FLAGS="--remove-orphans"
RESTORE_ARCHIVE=""
BACKUP_DIR="./backups"

if [ "$IS_PROD" = true ]; then
    # En prod : proposition de supprimer complètement la BDD
    # et de recharger la dernière backup du dossier backups/ (hors git).
    LATEST_BACKUP=$(ls -1t "$BACKUP_DIR"/*.tar.gz 2>/dev/null | head -1 || true)

    if [ -n "$LATEST_BACKUP" ]; then
        SIZE=$(du -sh "$LATEST_BACKUP" 2>/dev/null | cut -f1)
        echo -e "   ${BLUE}Dernière backup disponible : $(basename "$LATEST_BACKUP") (${SIZE})${NC}"
        echo -ne "   ${YELLOW}Supprimer complètement la BDD et recharger cette backup ?${NC} [y/N] " >&2; read -r rep </dev/tty
        if [[ "$rep" =~ ^[Yy]$ ]]; then
            EXTRA_DOWN_FLAGS="$EXTRA_DOWN_FLAGS --volumes"
            RESTORE_ARCHIVE="$LATEST_BACKUP"
            echo -e "${GREEN}   → La BDD sera réinitialisée puis restaurée depuis la backup.${NC}"
        else
            echo -e "${BLUE}   → Données actuelles conservées.${NC}"
        fi
    else
        echo -e "   ${BLUE}Aucune backup dans ${BACKUP_DIR}/ (générer avec ./export.sh --prod).${NC}"
        echo -ne "   ${YELLOW}Supprimer quand même les volumes (BDD réinitialisée depuis init.sql) ?${NC} [y/N] " >&2; read -r rep </dev/tty
        if [[ "$rep" =~ ^[Yy]$ ]]; then
            EXTRA_DOWN_FLAGS="$EXTRA_DOWN_FLAGS --volumes"
            echo -e "${GREEN}   → Volumes inclus dans le nettoyage.${NC}"
        fi
    fi
else
    echo -ne "   ${YELLOW}Supprimer aussi les volumes Docker (DB réinitialisée depuis zéro) ?${NC} [y/N] " >&2; read -r rep </dev/tty
    if [[ "$rep" =~ ^[Yy]$ ]]; then
        EXTRA_DOWN_FLAGS="$EXTRA_DOWN_FLAGS --volumes"
        echo -e "${GREEN}   → Volumes inclus dans le nettoyage.${NC}"
    fi
fi

docker compose $COMPOSE_FILES down $EXTRA_DOWN_FLAGS || error_exit "Nettoyage"

# 1.5 Vérification des ports
echo -e "${GREEN}[1.5/5] Vérification des ports...${NC}"
while IFS=' ' read -r svc port; do
    check_port "$port" "$svc"
done < <(
    docker compose $COMPOSE_FILES config 2>/dev/null \
    | awk '
        /^  [a-z][a-z0-9_-]*:/ { svc = substr($0, 3); sub(/:$/, "", svc) }
        /published:/            { port = $2; gsub(/[^0-9]/, "", port); if (port != "") print svc, port }
    '
)

# 2. Build et lancement de la DB
echo -e "${GREEN}[2/5] Préparation de la base de données...${NC}"
docker compose $COMPOSE_FILES build db || error_exit "Build DB"
docker compose $COMPOSE_FILES up -d db || error_exit "Lancement DB"

# Attente que la DB soit prête
echo -n "   Attente de la DB"
until docker compose $COMPOSE_FILES exec -T db pg_isready -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" &>/dev/null; do
    echo -n "."
    sleep 1
done
echo -e " ${GREEN}prête.${NC}"

# Restauration de la BDD depuis la backup sélectionnée (archive export.sh)
RESTORE_TMP=""
if [ -n "$RESTORE_ARCHIVE" ]; then
    echo -e "${BLUE}   → Restauration de la BDD depuis $(basename "$RESTORE_ARCHIVE")...${NC}"
    # Temp dir dans le projet (chemin absolu requis pour le montage docker) :
    # docker installé via snap ne peut pas monter /tmp
    RESTORE_TMP=$(mktemp -d "$(pwd)/.backup_tmp.XXXXXX")
    trap '[ -n "$RESTORE_TMP" ] && rm -rf "$RESTORE_TMP"' EXIT

    tar xzf "$RESTORE_ARCHIVE" -C "$RESTORE_TMP" || error_exit "Extraction de la backup"
    [ -f "$RESTORE_TMP/db.sql" ] || error_exit "db.sql absent de la backup"

    docker compose $COMPOSE_FILES exec -T db psql \
        -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" \
        < "$RESTORE_TMP/db.sql" > /dev/null || error_exit "Restauration BDD"
    echo -e "${GREEN}   ✔ Base de données restaurée.${NC}"
fi

# 3. Build Backend Go
echo -e "${GREEN}[3/5] Construction de l'API Backend (Go)...${NC}"
docker compose $COMPOSE_FILES build api || error_exit "Build API"
docker compose $COMPOSE_FILES up -d api || error_exit "Lancement API"

# Restauration des fichiers uploadés depuis la backup (le volume uploads
# est disponible une fois le container api démarré)
if [ -n "$RESTORE_ARCHIVE" ] && [ -f "$RESTORE_TMP/uploads.tar" ]; then
    echo -e "${BLUE}   → Restauration des fichiers uploadés...${NC}"
    API_CONTAINER=$(docker compose $COMPOSE_FILES ps -q api 2>/dev/null | head -1)
    UPLOADS_VOLUME=""
    if [ -n "$API_CONTAINER" ]; then
        UPLOADS_VOLUME=$(docker inspect "$API_CONTAINER" \
            --format '{{range .Mounts}}{{if eq .Destination "/uploads"}}{{.Name}}{{end}}{{end}}' 2>/dev/null || true)
    fi

    if [ -n "$UPLOADS_VOLUME" ]; then
        docker run --rm \
            -v "${UPLOADS_VOLUME}:/uploads" \
            -v "${RESTORE_TMP}:/import:ro" \
            alpine sh -c "rm -rf /uploads/* /uploads/.[!.]* 2>/dev/null; tar xf /import/uploads.tar -C /uploads" \
            || error_exit "Restauration des uploads"
        echo -e "${GREEN}   ✔ Fichiers uploadés restaurés.${NC}"
    else
        echo -e "${YELLOW}   ⚠ Volume uploads non trouvé — fichiers ignorés.${NC}"
    fi
fi

# 4. Build Frontend Vue
echo -e "${GREEN}[4/5] Construction du Frontend (Vue.js)...${NC}"
docker compose $COMPOSE_FILES build frontend || error_exit "Build Frontend"
docker compose $COMPOSE_FILES up -d frontend || error_exit "Lancement Frontend"

if [ "$IS_PROD" = true ]; then
    echo -e "${GREEN}[+] Lancement du Proxy Traefik...${NC}"
    docker compose $COMPOSE_FILES up -d proxy || error_exit "Lancement Proxy"
    echo -e "${BLUE}   → Certificat SSL (Let's Encrypt) émis et renouvelé automatiquement par Traefik.${NC}"
fi

# 5. État final
echo -e "\n${BLUE}=== État des services ===${NC}"
docker compose $COMPOSE_FILES ps || error_exit "Affichage statut"

echo -e "\n${GREEN}✔ Déploiement réussi !${NC}"
