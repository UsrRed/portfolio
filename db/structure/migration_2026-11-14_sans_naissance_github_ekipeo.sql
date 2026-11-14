-- Migration : plus de date de naissance, lien GitHub, mention « relation client » chez E-kipeo.
-- - birth_date supprimée : donnée personnelle inutile sur un site public (usurpation
--   d'identité, ingénierie sociale) ; elle n'est plus ni stockée ni exposée par l'API.
-- - github_url ajoutée à la personne (affichée sur le site et le CV).
-- Appliquée automatiquement par ./migrate.sh (appelé par ./deploy.sh).

BEGIN;

ALTER TABLE person DROP COLUMN IF EXISTS birth_date;
ALTER TABLE person ADD COLUMN IF NOT EXISTS github_url VARCHAR(255);
UPDATE person SET github_url = 'https://github.com/UsrRed' WHERE id = 1 AND COALESCE(github_url, '') = '';

UPDATE experience
   SET details = 'Relation client et support téléphonique. Gestion et supervision de réseaux.'
 WHERE company = 'E-kipeo'
   AND details = 'Support téléphonique. Gestion et supervision de réseaux. Relation aux clients.';

COMMIT;
