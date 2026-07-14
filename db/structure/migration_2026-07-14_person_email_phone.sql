-- Migration : ajoute email et téléphone à la personne.
-- Champs de contact indispensables aux parseurs ATS des recruteurs
-- (extraits en priorité sur le PDF du CV). Valeurs à renseigner via l'admin.
-- Application sur la base en cours d'exécution :
--   docker compose exec -T db psql -U $POSTGRES_USER -d $POSTGRES_DB < db/structure/migration_2026-07-14_person_email_phone.sql

BEGIN;

ALTER TABLE person ADD COLUMN IF NOT EXISTS email VARCHAR(255);
ALTER TABLE person ADD COLUMN IF NOT EXISTS phone VARCHAR(50);

COMMIT;
