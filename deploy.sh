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

# Gestion de l'environnement
IS_PROD=false
COMPOSE_FILES=""

if [[ "$1" == "--prod" ]]; then
    IS_PROD=true
    COMPOSE_FILES="-f docker-compose.yml -f docker-compose.prod.yml"
    echo -e "${BLUE}=== Démarrage du déploiement en PRODUCTION (HTTPS) ===${NC}\n"
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
