-- Drop tables if they exist to ensure clean state for this major update (in dev)
-- In production, we would use migrations, but here we want to match the provided HTML exactly.
DROP TABLE IF EXISTS project CASCADE;
DROP TABLE IF EXISTS education CASCADE;
DROP TABLE IF EXISTS experience CASCADE;
DROP TABLE IF EXISTS certification CASCADE;
DROP TABLE IF EXISTS skill CASCADE;
DROP TABLE IF EXISTS domain CASCADE;
DROP TABLE IF EXISTS language CASCADE;
DROP TABLE IF EXISTS hobby CASCADE;
DROP TABLE IF EXISTS soft_skill CASCADE;
DROP TABLE IF EXISTS person CASCADE;

-- Create Person table
CREATE TABLE person (
    id SERIAL PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    birth_date DATE,
    driver_license VARCHAR(100),
    location VARCHAR(100),
    title VARCHAR(255),
    description TEXT,
    linkedin_url VARCHAR(255),
    image_url VARCHAR(255)
);

-- Create Domain table (Categories for skills)
CREATE TABLE domain (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE
);

-- Create Skill table
CREATE TABLE skill (
    id SERIAL PRIMARY KEY,
    domain_id INTEGER REFERENCES domain(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    image_url VARCHAR(255),
    details TEXT
);

-- Create Language table
CREATE TABLE language (
    id SERIAL PRIMARY KEY,
    person_id INTEGER REFERENCES person(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    level VARCHAR(100),
    image_url VARCHAR(255),
    certification_url VARCHAR(255)
);

-- Create Hobby table (Passions)
CREATE TABLE hobby (
    id SERIAL PRIMARY KEY,
    person_id INTEGER REFERENCES person(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    image_url VARCHAR(255)
);

-- Create Soft Skill table
CREATE TABLE soft_skill (
    id SERIAL PRIMARY KEY,
    person_id INTEGER REFERENCES person(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    image_url VARCHAR(255)
);

-- Create Education table
CREATE TABLE education (
    id SERIAL PRIMARY KEY,
    person_id INTEGER REFERENCES person(id) ON DELETE CASCADE,
    school VARCHAR(255) NOT NULL,
    school_url VARCHAR(255),
    degree VARCHAR(255) NOT NULL,
    details TEXT,
    start_date VARCHAR(50), -- Using string to match "2018-2021" format flexibility
    status VARCHAR(50) -- "Obtenu", "En cours"
);

-- Create Experience table
CREATE TABLE experience (
    id SERIAL PRIMARY KEY,
    person_id INTEGER REFERENCES person(id) ON DELETE CASCADE,
    company VARCHAR(255) NOT NULL,
    company_url VARCHAR(255),
    role VARCHAR(255) NOT NULL,
    details TEXT,
    start_date VARCHAR(50), -- "2022-2023"
    duration VARCHAR(50), -- "1 an"
    status VARCHAR(50) -- "Terminé", "En cours"
);

-- Create Project table
CREATE TABLE project (
    id SERIAL PRIMARY KEY,
    person_id INTEGER REFERENCES person(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    image_url VARCHAR(255),
    period VARCHAR(100),
    description TEXT,
    skills_human TEXT, -- "Autonomie, Savoir convaincre..."
    skills_tech TEXT, -- "Gestion de projet, Serveur..."
    link_url VARCHAR(255),
    hidden BOOLEAN NOT NULL DEFAULT FALSE -- masqué : exclu du rendu public
);


-- DATA INSERTION

-- Person
INSERT INTO person (first_name, last_name, birth_date, driver_license, location, title, description, linkedin_url, image_url) VALUES 
('Yohann', 'DENOYELLE', '2003-07-01', 'Permis B et véhicule', 'Blois', 
 'Étudiant à l''IUT de Blois', 
 'Étudiant à l''IUT de Blois pour un BUT Réseaux et Télécommunications orienté cybersécurité. Stagiaire chez Senior Aerospace Ermeto. En recherche d''un apprentissage pour 2024/2027 avec l''école d''ingénieur EPITA.',
 'https://fr.linkedin.com/in/yohann-denoyelle', '/images/Yohann.jpeg');

-- Domains
INSERT INTO domain (name) VALUES
('Compétences développement'),
('Compétences réseaux'),
('Marques utilisées');

-- Skills: Développement
INSERT INTO skill (domain_id, name, image_url, details) VALUES 
((SELECT id FROM domain WHERE name='Compétences développement'), 'Python', '/images/Python.png', 'Développement de plusieurs programmes utilitaires. Obtention d''une certification Udemy'),
((SELECT id FROM domain WHERE name='Compétences développement'), 'HTML-CSS', '/images/HTMLCSS.png', 'Développement de plusieurs projets, souvent dans le cadre scolaire'),
((SELECT id FROM domain WHERE name='Compétences développement'), 'C', '/images/C.png', 'Entraînement dans le cadre universitaire'),
((SELECT id FROM domain WHERE name='Compétences développement'), 'SQL', '/images/SQL.png', 'Mise en place et gestion de bases de données. Utilisé dans le projet de site web'),
((SELECT id FROM domain WHERE name='Compétences développement'), 'Bash', '/images/BASH.png', 'Programmation sur Linux étudiée en cours'),
((SELECT id FROM domain WHERE name='Compétences développement'), 'PHP', '/images/PHP.png', 'Mise en place de programme permettant de rendre un site dynamique, interagissant avec les données d''un serveur'),
((SELECT id FROM domain WHERE name='Compétences développement'), 'Java', '/images/Java.png', 'Création d''une application de chat chiffré avec des sockets et des threads'),
((SELECT id FROM domain WHERE name='Compétences développement'), 'Javascript', '/images/javascript.png', 'Création de graphiques de statistiques réalisé chez Senior Aerospace Ermeto et utilisé dans divers projets'),
((SELECT id FROM domain WHERE name='Compétences développement'), 'Docker', '/images/docker.png', 'Création d''un site web avec une supervision PLG et syslog-ng avec un réseau Docker');

-- Skills: Compétences réseaux
INSERT INTO skill (domain_id, name, image_url, details) VALUES
((SELECT id FROM domain WHERE name='Compétences réseaux'), 'Gestion des identités et des accès', '/images/active_directory.png', 'Administration d''utilisateurs avec Microsoft Entra ID et Active Directory, réalisée lors de travaux pratiques et de la mise en place des badges multifonctions'),
((SELECT id FROM domain WHERE name='Compétences réseaux'), 'Conception de réseaux sécurisés', '/images/Cisco-Packet-Tracer.webp', 'Réalisation de plusieurs projets de réseaux sécurisés avec Cisco Packet Tracer'),
((SELECT id FROM domain WHERE name='Compétences réseaux'), 'Administration Linux', '/images/linux.png', 'Bonnes bases de bash, distributions étudiées : Ubuntu, CentOS, Debian et Kali'),
((SELECT id FROM domain WHERE name='Compétences réseaux'), 'Administration Windows', '/images/windows.png', 'Administration de serveurs sur Windows / configuration de clés de registre et de l''authentification durant la mise en place des badges'),
((SELECT id FROM domain WHERE name='Compétences réseaux'), 'Configuration de téléphonie', '/images/telephone.png', 'Configuration de téléphone analogique et VoIP'),
((SELECT id FROM domain WHERE name='Compétences réseaux'), 'Supervision de réseaux', '/images/Centreon.png', 'Supervision de réseaux via Centreon et Nagios'),
((SELECT id FROM domain WHERE name='Compétences réseaux'), 'Configuration d''un EDR', '/images/Wazuh.png', 'Étude du fonctionnement de Wazuh et mise en place sur différents équipements'),
((SELECT id FROM domain WHERE name='Compétences réseaux'), 'Analyse de trames réseaux', '/images/Wireshark.png', 'Utilisation de Wireshark afin d''analyser des paquets réseaux'),
((SELECT id FROM domain WHERE name='Compétences réseaux'), 'Virtualisation', '/images/VirtualBox.png', 'Utilisation de VirtualBox pour la création de machines virtuelles, notamment pour des serveurs et expérimentation d''outils');

-- Skills: Marques utilisées
INSERT INTO skill (domain_id, name, image_url, details) VALUES 
((SELECT id FROM domain WHERE name='Marques utilisées'), 'Cisco', '/images/Cisco.png', 'Configuration de Routeur, Switch et Firewall'),
((SELECT id FROM domain WHERE name='Marques utilisées'), 'Ubiquiti', '/images/Ubiquiti.png', 'Configuration de Routeur, Switch et Firewall en entreprise'),
((SELECT id FROM domain WHERE name='Marques utilisées'), 'TP-Link', '/images/TP-Link.png', 'Paramétrage de routeur et switch dans le cadre scolaire et en entreprise'),
((SELECT id FROM domain WHERE name='Marques utilisées'), 'Linksys', '/images/Linksys.png', 'Configuration de routeurs'),
((SELECT id FROM domain WHERE name='Marques utilisées'), 'Netgear', '/images/Netgear.png', 'Utilisation et paramétrage de switchs et routeurs');

-- Languages
INSERT INTO language (person_id, name, level, image_url, certification_url) VALUES 
(1, 'Français', 'Langue natale', '/images/drapeau_francais.jpeg', NULL),
(1, 'Anglais', 'Certification B1', '/images/drapeau_anglais.jpeg', '/docs/certification_cambridge.pdf'),
(1, 'Espagnol', 'Des notions', '/images/drapeau_espagnol.jpeg', NULL);

-- Hobbies
INSERT INTO hobby (person_id, name, image_url) VALUES 
(1, 'Jeux vidéos', '/images/Jeux.webp'),
(1, 'Programmation', '/images/Programmation.webp'),
(1, 'Cybersécurité', '/images/Cybersecurity.webp'),
(1, 'Ping-Pong', '/images/ping-pong.webp');

-- Soft Skills
INSERT INTO soft_skill (person_id, name, image_url) VALUES 
(1, 'Calme', '/images/Calme.webp'),
(1, 'Sérieux', '/images/Serieux.webp'),
(1, 'Investi', '/images/Investis.webp');

-- Education
INSERT INTO education (person_id, school, school_url, degree, details, start_date, status) VALUES 
(1, 'Lycée Ronsard', 'https://www.lyceeronsard.eu/', 'BAC général', 'Mention Assez bien. Spécialités: Mathématiques, LLCE Anglais. Arrêté: Physique-Chimie', '2018-2021', 'Obtenu'),
(1, 'IUT de Blois', 'https://iut-blois.univ-tours.fr/', 'BUT Réseaux et Télécommunications', 'Les réseaux informatiques et leurs interconnexions. Les outils de télécommunications modernes. L''informatique et l''ordinateur. L''électronique et la chaîne de transmission d''un signal.', 'Débuté en 2021', 'En cours');

-- Experience
INSERT INTO experience (person_id, company, company_url, role, details, start_date, duration, status) VALUES 
(1, 'Orange', 'https://www.orange.fr', 'Apprenti chargé d''affaires', 'Professionnalisation. Déploiement de supports réseaux. Spécialisé dans le réseau FTTO. Relation aux clients.', '2022-2023', '1 an', 'Terminé'),
(1, 'E-kipeo', 'https://www.e-kipeo.com/', 'Apprenti technicien réseau', 'Support téléphonique. Gestion et supervision de réseaux. Relation aux clients.', '2023', '2 mois - Fermeture de site', 'Terminé'),
(1, 'Ermeto', 'https://senior-ermeto.fr/', 'Stagiaire technicien informatique', 'Gestion de projets. Mise en place de badges multifonctions. Création d''un site web catalogue. Mise en conformité et rédaction de la procédure de gestion de l''Active Directory.', '2024', '3 mois', 'En cours');

-- Projects
INSERT INTO project (person_id, title, image_url, period, description, skills_human, skills_tech, link_url) VALUES 
(1, 'Badges multifonctions', '/images/Badge_technologies.jpeg', 'mars - juin 2024', 'Étude des besoins, technologies et fournisseurs existant pour la mise en place de badges multifonctions chez Senior Aerospace Ermeto. Par la suite, accompagnement du projet dans les différentes phases du déploiement.', 'Autonomie, Savoir convaincre, Force de proposition', 'Gestion de projet, Serveur de certification, Éditeur du Registre Windows, GPO (Group Policy Objects), Connexion Windows', NULL),
(1, 'Site web catalogue', '/images/Catalogue.png', 'avril - juin 2024', 'Catalogue référençant l''ensemble des produits de Senior Aerospace Ermeto avec leurs prix, schémas, et autres mesures.', 'Autonomie', 'Développement, Gestion de projet. Langages: HTML, CSS (Bootstrap), PHP, SQL, Javascript, Dockerfile', NULL),
(1, 'Site Web de comparaison de page Wikipedia', '/images/SAE501-502.png', '2023-2024', 'Application WEB de comparaison de page Wikipedia avec l''API MediaWiki', NULL, 'Langages: HTML, CSS (Bootstrap), PHP, SQL, Javascript. Conteneurisation Podman: Nginx/Haproxy/PHP/MySQL/Syslog-ng/Grafana/Portainer/NetData. Travail en équipe (Git)', NULL),
(1, 'Raccordement de fibre optique', '/images/Orange-schema-securisation.png', '2022-2023', 'Exemple de raccordement de fibre optique (FTTO) dans une entreprise', 'Relation client, autonomie', 'Planification, Gestions de projets, Bureautique, Étude d''une infrastructure réseau. Connaissance des réseaux FTTO', NULL),
(1, 'Chat chiffré en java', '/images/SAE302.png', '2022-2023', 'Création d''un chat en java avec un serveur et des clients, permettant de communiquer entre eux sur différents salons', NULL, 'Langages: Java, SQL. Compréhension des sockets. Compréhension des threads. Travail en équipe', NULL),
(1, 'Site Web des écoles de Blois', '/images/SAE23.png', '2021-2022', 'Site permettant aux utilisateurs de voir les différentes écoles de Blois et leurs formations, ceci avec des statistiques sur chaque école. Possibilité de créer un compte afin d''envoyer des tickets aux développeurs pour de possibles améliorations.', NULL, 'Langages: HTML, CSS(Bootstrap), PHP, SQL. Travail en équipe', NULL);
