-- Migration : transforme les "Outils réseaux" en compétences
-- et supprime la section "Outils réseaux".
-- Application sur la base en cours d'exécution :
--   docker compose exec -T db psql -U $POSTGRES_USER -d $POSTGRES_DB < db/structure/migration_2026-07-14_outils_vers_competences.sql

BEGIN;

-- Domaine cible (au cas où il n'existerait plus)
INSERT INTO domain (name) VALUES ('Compétences réseaux') ON CONFLICT (name) DO NOTHING;

-- Reformulation des outils en compétences
UPDATE skill SET name = 'Gestion des identités et des accès',
    details = 'Administration d''utilisateurs avec Microsoft Entra ID et Active Directory, réalisée lors de travaux pratiques et de la mise en place des badges multifonctions'
    WHERE name = 'Microsoft Entra ID - Active Directory';
UPDATE skill SET name = 'Conception de réseaux sécurisés',
    details = 'Réalisation de plusieurs projets de réseaux sécurisés avec Cisco Packet Tracer'
    WHERE name = 'Cisco Packet Tracer';
UPDATE skill SET name = 'Administration Linux'
    WHERE name = 'Linux';
UPDATE skill SET name = 'Administration Windows'
    WHERE name = 'Windows';
UPDATE skill SET name = 'Configuration de téléphonie'
    WHERE name = 'Téléphonie';
UPDATE skill SET name = 'Supervision de réseaux'
    WHERE name = 'Centreon';
UPDATE skill SET name = 'Configuration d''un EDR',
    details = 'Étude du fonctionnement de Wazuh et mise en place sur différents équipements'
    WHERE name = 'Wazuh';
UPDATE skill SET name = 'Analyse de trames réseaux'
    WHERE name = 'Wireshark';
UPDATE skill SET name = 'Virtualisation'
    WHERE name = 'VirtualBox';

-- Rattachement de toutes les compétences restantes au domaine "Compétences réseaux"
UPDATE skill SET domain_id = (SELECT id FROM domain WHERE name = 'Compétences réseaux')
    WHERE domain_id = (SELECT id FROM domain WHERE name = 'Outils réseaux');

-- Suppression de la section "Outils réseaux"
DELETE FROM domain WHERE name = 'Outils réseaux';

COMMIT;
