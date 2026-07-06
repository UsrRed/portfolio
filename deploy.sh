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
echo -ne "   ${YELLOW}Supprimer aussi les volumes Docker (DB réinitialisée depuis zéro) ?${NC} [y/N] " >&2; read -r rep </dev/tty
if [[ "$rep" =~ ^[Yy]$ ]]; then
    EXTRA_DOWN_FLAGS="$EXTRA_DOWN_FLAGS --volumes"
    echo -e "${GREEN}   → Volumes inclus dans le nettoyage.${NC}"
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

# En mode prod : proposition de restaurer un backup DB
if [ "$IS_PROD" = true ]; then
    BACKUP_DIR="./backups"
    BACKUP_FILES=()

    if [ -d "$BACKUP_DIR" ]; then
        while IFS= read -r -d '' f; do
            BACKUP_FILES+=("$f")
        done < <(find "$BACKUP_DIR" -maxdepth 1 \( -name "*.sql" -o -name "*.dump" -o -name "*.pgdump" \) -print0 2>/dev/null | sort -z)
    fi

    if [ ${#BACKUP_FILES[@]} -gt 0 ]; then
        echo -e "\n${YELLOW}→ Backups DB disponibles dans ${BACKUP_DIR}/ :${NC}"
        for i in "${!BACKUP_FILES[@]}"; do
            SIZE=$(du -sh "${BACKUP_FILES[$i]}" 2>/dev/null | cut -f1)
            echo "   [$((i+1))] $(basename "${BACKUP_FILES[$i]}")  (${SIZE})"
        done
        echo -e "   [N] Ignorer — utiliser l'initialisation depuis init.sql"
        echo -ne "\n   ${YELLOW}Restaurer un backup ?${NC} [1-${#BACKUP_FILES[@]}/N] " >&2; read -r rep </dev/tty

        if [[ "$rep" =~ ^[0-9]+$ ]] && [ "$rep" -ge 1 ] && [ "$rep" -le "${#BACKUP_FILES[@]}" ]; then
            SELECTED="${BACKUP_FILES[$((rep-1))]}"
            echo -e "${BLUE}   → Restauration de $(basename "$SELECTED")...${NC}"

            case "$SELECTED" in
                *.sql)
                    docker compose $COMPOSE_FILES exec -T db psql \
                        -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" \
                        < "$SELECTED" || error_exit "Restauration backup SQL"
                    ;;
                *.dump|*.pgdump)
                    docker compose $COMPOSE_FILES exec -T db pg_restore \
                        -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" \
                        --clean --if-exists \
                        < "$SELECTED" || error_exit "Restauration backup dump"
                    ;;
            esac

            echo -e "${GREEN}   ✔ Backup restauré avec succès.${NC}"
        else
            echo -e "${BLUE}   → Initialisation depuis init.sql (par défaut).${NC}"
        fi
    else
        echo -e "${BLUE}   → Aucun backup trouvé dans ${BACKUP_DIR}/ — initialisation depuis init.sql.${NC}"
    fi
fi

# 3. Build Backend Go
echo -e "${GREEN}[3/5] Construction de l'API Backend (Go)...${NC}"
docker compose $COMPOSE_FILES build api || error_exit "Build API"
docker compose $COMPOSE_FILES up -d api || error_exit "Lancement API"

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
