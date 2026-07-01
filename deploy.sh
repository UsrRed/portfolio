#!/bin/bash

# Configuration pour arrêter le script au premier échec
set -e

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# Fonction pour afficher les erreurs
error_exit() {
    echo -e "\n${RED}✘ ERREUR à l'étape : $1${NC}"
    echo -e "${RED}Le déploiement a été stoppé.${NC}"
    exit 1
}

# Vérifie si un port est libre, propose de libérer sinon
check_port() {
    local port=$1
    local label=$2

    # ss -tlnp "sport = :PORT" filtre précisément sur le port en écoute
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

# 0. Vérification si Docker est installé
echo -e "${GREEN}[0/5] Vérification de l'environnement...${NC}"
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Erreur : Docker n'est pas installé sur votre système.${NC}"
    echo -e "Lancer : sudo apt update && sudo apt install docker.io docker-compose-v2"
    exit 1
fi

# 1. Nettoyage
echo -e "${GREEN}[1/5] Nettoyage des anciens conteneurs...${NC}"
docker compose $COMPOSE_FILES down --remove-orphans || error_exit "Nettoyage"

# 1.5 Vérification des ports (détectés automatiquement depuis la config compose)
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

# 2. Build de la DB
echo -e "${GREEN}[2/5] Préparation de la base de données...${NC}"
docker compose $COMPOSE_FILES build db || error_exit "Build DB"
docker compose $COMPOSE_FILES up -d db || error_exit "Lancement DB"

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
fi

# 5. État final
echo -e "\n${BLUE}=== État des services ===${NC}"
echo -e "\n${BLUE}=== État des services ===${NC}"
docker compose $COMPOSE_FILES ps || error_exit "Affichage statut"

echo -e "\n${GREEN}✔ Déploiement réussi !${NC}"
