<script setup lang="ts">
import { computed, onMounted, onUnmounted } from 'vue'

// CV imprimable : rendu uniquement via Ctrl+P / window.print()
// (masqué à l'écran par la règle globale @media screen de style.css).
const props = defineProps<{ data: any }>()

// Seul Chromium honore `@page { size: A4; margin: 0 }`. Safari et Firefox
// imposent leurs marges d'impression : les 210×296mm du CV ne tiennent plus
// dans la zone imprimable et débordent sur une 2e page. Pour ces moteurs,
// on réduit l'ensemble du CV (zoom) à l'impression — cadre blanc autour,
// mais une seule page partout. iOS Chrome (CriOS) imprime via WebKit :
// il n'est volontairement pas reconnu comme Chromium ici.
const isChromium = typeof navigator !== 'undefined' && /chrome|chromium|edg\//i.test(navigator.userAgent)
const fitPage = !isChromium

// Le nom du PDF proposé par le navigateur reprend document.title :
// on le remplace pendant l'impression puis on restaure le titre du site.
const PDF_TITLE = 'Yohann Denoyelle CV'
let siteTitle = ''
const onBeforePrint = () => {
  siteTitle = document.title
  document.title = PDF_TITLE
}
const onAfterPrint = () => {
  document.title = siteTitle
}
onMounted(() => {
  window.addEventListener('beforeprint', onBeforePrint)
  window.addEventListener('afterprint', onAfterPrint)
})
onUnmounted(() => {
  window.removeEventListener('beforeprint', onBeforePrint)
  window.removeEventListener('afterprint', onAfterPrint)
})

// Plafonds par section pour garantir un CV sur une seule page A4.
const MAX_EXPERIENCES = 4
const MAX_EDUCATIONS = 3
const MAX_PROJECTS = 3

// Les dates sont en texte libre ("2022-2023", "mars - juin 2024") :
// on trie sur l'année la plus récente trouvée, les items "En cours" en tête.
function recency(period?: string, status?: string): number {
  const ongoing = status && /cours/i.test(status) ? 10000 : 0
  const years = (period?.match(/\d{4}/g) ?? []).map(Number)
  return ongoing + (years.length ? Math.max(...years) : 0)
}

function sortRecent(items: any[] | undefined, key: (i: any) => [string?, string?], max: number): any[] {
  return [...(items ?? [])]
    .sort((a, b) => recency(...key(b)) - recency(...key(a)))
    .slice(0, max)
}

const experiences = computed(() => sortRecent(props.data.experiences, (e) => [e.start_date, e.status], MAX_EXPERIENCES))
const educations = computed(() => sortRecent(props.data.educations, (e) => [e.start_date, e.status], MAX_EDUCATIONS))
const projects = computed(() =>
  sortRecent(props.data.projects?.filter((p: any) => !p.hidden), (p) => [p.period], MAX_PROJECTS)
)

// URL LinkedIn affichée en clair (sans protocole ni sous-domaine) : les
// parseurs ATS détectent le profil par l'URL visible, pas par la cible du
// lien. Affichée sur une seule ligne : une césure au tiret du pseudo
// corromprait l'URL extraite du PDF (dé-hyphénisation des parseurs).
const linkedinLabel = computed(() =>
  (props.data.person.linkedin_url ?? '')
    .replace(/^https?:\/\//, '')
    .replace(/^([a-z]{2,3}\.)?(www\.)?(?=linkedin\.)/, '')
    .replace(/\/$/, '')
)

const githubLabel = computed(() =>
  (props.data.person.github_url ?? '').replace(/^https?:\/\/(www\.)?/, '').replace(/\/$/, '')
)

// Lien tel: sans espaces ni points pour être cliquable partout.
const phoneHref = computed(() => 'tel:' + (props.data.person.phone ?? '').replace(/[^+\d]/g, ''))

</script>

<template>
  <div class="cv-print" :class="{ 'cv-fit-page': fitPage }">
    <!-- Colonne principale : première dans le DOM pour que le flux texte
         du PDF commence par nom → titre → expériences (ordre attendu par
         les parseurs ATS). La position visuelle est gérée par la grille. -->
    <main class="cv-main">
      <header class="cv-header">
        <h1 class="cv-name">{{ data.person.first_name }} <span class="cv-lastname">{{ data.person.last_name }}</span></h1>
        <p v-if="data.person.title" class="cv-headline">{{ data.person.title }}</p>
        <p v-if="data.person.description" class="cv-profile">{{ data.person.description }}</p>
      </header>

      <section v-if="experiences.length" class="cv-section">
        <h2 class="cv-section-title">Expériences professionnelles</h2>
        <article v-for="exp in experiences" :key="exp.id" class="cv-item">
          <div class="cv-item-head">
            <h3 class="cv-item-title">{{ exp.role }}</h3>
            <span class="cv-item-date">{{ exp.start_date }}<template v-if="exp.duration"> · {{ exp.duration }}</template></span>
          </div>
          <p class="cv-item-sub">{{ exp.company }}</p>
          <p v-if="exp.details" class="cv-item-details">{{ exp.details }}</p>
        </article>
      </section>

      <section v-if="educations.length" class="cv-section">
        <h2 class="cv-section-title">Formations</h2>
        <article v-for="edu in educations" :key="edu.id" class="cv-item">
          <div class="cv-item-head">
            <h3 class="cv-item-title">{{ edu.degree }}</h3>
            <span class="cv-item-date">{{ edu.start_date }}<template v-if="edu.status"> · {{ edu.status }}</template></span>
          </div>
          <p class="cv-item-sub">{{ edu.school }}</p>
          <p v-if="edu.details" class="cv-item-details">{{ edu.details }}</p>
        </article>
      </section>

      <section v-if="projects.length" class="cv-section">
        <h2 class="cv-section-title">Projets récents</h2>
        <article v-for="proj in projects" :key="proj.id" class="cv-item">
          <div class="cv-item-head">
            <h3 class="cv-item-title">{{ proj.title }}</h3>
            <span class="cv-item-date">{{ proj.period }}</span>
          </div>
          <p v-if="proj.description" class="cv-item-details">{{ proj.description }}</p>
          <p v-if="proj.skills_tech" class="cv-item-tech">{{ proj.skills_tech }}</p>
        </article>
      </section>
    </main>

    <!-- Colonne latérale -->
    <aside class="cv-side">
      <img v-if="data.person.image_url" :src="data.person.image_url" alt="" class="cv-photo" />

      <section class="cv-side-section">
        <h2 class="cv-side-title">Contact</h2>
        <ul class="cv-contact">
          <li v-if="data.person.email">
            <svg class="cv-ico" viewBox="0 0 24 24" aria-hidden="true"><path d="M20 4H4c-1.1 0-1.99.9-1.99 2L2 18c0 1.1.9 2 2 2h16c1.1 0 2-.9 2-2V6c0-1.1-.9-2-2-2zm0 4-8 5-8-5V6l8 5 8-5v2z" /></svg>
            <a class="cv-contact-link" :href="'mailto:' + data.person.email">{{ data.person.email }}</a>
          </li>
          <li v-if="data.person.phone">
            <svg class="cv-ico" viewBox="0 0 24 24" aria-hidden="true"><path d="M6.62 10.79c1.44 2.83 3.76 5.14 6.59 6.59l2.2-2.2c.27-.27.67-.36 1.02-.24 1.12.37 2.33.57 3.57.57.55 0 1 .45 1 1V20c0 .55-.45 1-1 1-9.39 0-17-7.61-17-17 0-.55.45-1 1-1h3.5c.55 0 1 .45 1 1 0 1.25.2 2.45.57 3.57.11.35.03.74-.25 1.02l-2.2 2.2z" /></svg>
            <a class="cv-contact-link" :href="phoneHref">{{ data.person.phone }}</a>
          </li>
          <li v-if="data.person.location">
            <svg class="cv-ico" viewBox="0 0 24 24" aria-hidden="true"><path d="M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7zm0 9.5a2.5 2.5 0 1 1 0-5 2.5 2.5 0 0 1 0 5z" /></svg>
            <span>{{ data.person.location }}</span>
          </li>
          <li v-if="data.person.linkedin_url">
            <svg class="cv-ico" viewBox="0 0 24 24" aria-hidden="true"><path d="M20.45 20.45h-3.55v-5.57c0-1.33-.03-3.04-1.85-3.04-1.86 0-2.14 1.45-2.14 2.94v5.67H9.35V9h3.41v1.56h.05c.47-.9 1.63-1.85 3.36-1.85 3.6 0 4.27 2.37 4.27 5.46v6.28zM5.34 7.43a2.06 2.06 0 1 1 0-4.12 2.06 2.06 0 0 1 0 4.12zM7.12 20.45H3.56V9h3.56v11.45z" /></svg>
            <a class="cv-contact-link cv-contact-link--url" :href="data.person.linkedin_url">{{ linkedinLabel }}</a>
          </li>
          <li v-if="data.person.github_url">
            <svg class="cv-ico" viewBox="0 0 24 24" aria-hidden="true"><path d="M12 .5C5.65.5.5 5.65.5 12a11.5 11.5 0 0 0 7.86 10.92c.58.1.79-.25.79-.56v-2c-3.2.7-3.87-1.37-3.87-1.37-.52-1.33-1.28-1.69-1.28-1.69-1.04-.71.08-.7.08-.7 1.15.08 1.76 1.19 1.76 1.19 1.03 1.76 2.69 1.25 3.35.96.1-.75.4-1.25.73-1.54-2.55-.29-5.24-1.28-5.24-5.68 0-1.26.45-2.28 1.19-3.09-.12-.29-.52-1.46.11-3.05 0 0 .97-.31 3.17 1.18a11 11 0 0 1 5.77 0c2.2-1.49 3.17-1.18 3.17-1.18.63 1.59.23 2.76.11 3.05.74.81 1.19 1.83 1.19 3.09 0 4.41-2.69 5.39-5.25 5.67.41.36.78 1.06.78 2.14v3.17c0 .31.21.67.8.56A11.5 11.5 0 0 0 23.5 12C23.5 5.65 18.35.5 12 .5z" /></svg>
            <a class="cv-contact-link cv-contact-link--url" :href="data.person.github_url">{{ githubLabel }}</a>
          </li>
          <li v-if="data.person.driver_license">
            <svg class="cv-ico" viewBox="0 0 24 24" aria-hidden="true"><path d="M18.92 6.01C18.72 5.42 18.16 5 17.5 5h-11c-.66 0-1.21.42-1.42 1.01L3 12v8c0 .55.45 1 1 1h1c.55 0 1-.45 1-1v-1h12v1c0 .55.45 1 1 1h1c.55 0 1-.45 1-1v-8l-2.08-5.99zM6.5 16c-.83 0-1.5-.67-1.5-1.5S5.67 13 6.5 13s1.5.67 1.5 1.5S7.33 16 6.5 16zm11 0c-.83 0-1.5-.67-1.5-1.5s.67-1.5 1.5-1.5 1.5.67 1.5 1.5-.67 1.5-1.5 1.5zM5 11l1.5-4.5h11L19 11H5z" /></svg>
            <span>{{ data.person.driver_license }}</span>
          </li>
        </ul>
      </section>

      <section v-if="data.domains?.some((d: any) => d.skills?.length)" class="cv-side-section">
        <h2 class="cv-side-title">Compétences</h2>
        <div v-for="domain in data.domains.filter((d: any) => d.skills?.length)" :key="domain.id" class="cv-domain">
          <h3 class="cv-domain-name">{{ domain.name }}</h3>
          <p class="cv-side-text">{{ domain.skills.map((s: any) => s.name).join(' · ') }}</p>
        </div>
      </section>

      <section v-if="data.languages?.length" class="cv-side-section">
        <h2 class="cv-side-title">Langues</h2>
        <ul class="cv-lang-list">
          <li v-for="lang in data.languages" :key="lang.id">
            <span class="cv-lang-name">{{ lang.name }}</span>
            <span v-if="lang.level" class="cv-lang-level">{{ lang.level }}</span>
          </li>
        </ul>
      </section>

      <section v-if="data.soft_skills?.length" class="cv-side-section">
        <h2 class="cv-side-title">Savoir-être</h2>
        <p class="cv-side-text">{{ data.soft_skills.map((s: any) => s.name).join(' · ') }}</p>
      </section>

      <section v-if="data.hobbies?.length" class="cv-side-section">
        <h2 class="cv-side-title">Centres d'intérêt</h2>
        <p class="cv-side-text">{{ data.hobbies.map((h: any) => h.name).join(' · ') }}</p>
      </section>
    </aside>
  </div>
</template>

<style scoped>
/* display géré par style.css : none à l'écran, grid !important en print.
   Ne pas déclarer display ici, la spécificité du style scopé écraserait
   la règle screen et le CV s'afficherait par-dessus le site. */
.cv-print {
  grid-template-columns: 60mm 1fr;
  width: 210mm;
  height: 296mm;
  overflow: hidden;
  font-family: 'Inter', -apple-system, sans-serif;
  color: #1f2937;
  /* Le fond sombre couvre toute la hauteur de la colonne latérale,
     même si son contenu s'arrête avant. */
  background: linear-gradient(to right, #0f172a 60mm, #ffffff 60mm);
  font-size: 9pt;
  line-height: 1.4;
  /* Les ligatures (fi, ffi…) sont encodées en glyphes spéciaux dans le PDF
     et cassent l'extraction de texte de certains parseurs ATS. */
  font-variant-ligatures: none;
}

/* Safari / Firefox : marges d'impression imposées par le navigateur.
   Réduction globale pour tenir la zone imprimable d'une page A4 ou Letter,
   quelles que soient les marges (~13mm max par côté). */
@media print {
  .cv-print.cv-fit-page {
    zoom: 0.88;
  }
}

/* ── Colonne latérale ──
   Placée après <main> dans le DOM (ordre de lecture ATS) mais affichée
   à gauche via un placement de grille explicite. */
.cv-side {
  grid-column: 1;
  grid-row: 1;
  padding: 12mm 7mm 10mm;
  color: #cbd5e1;
}

.cv-photo {
  display: block;
  width: 34mm;
  height: 34mm;
  object-fit: cover;
  border-radius: 50%;
  margin: 0 auto 7mm;
  border: 1.5pt solid #10b981;
}

.cv-side-section {
  margin-bottom: 6mm;
}

.cv-side-title {
  font-size: 8.5pt;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.12em;
  color: #34d399;
  margin: 0 0 2mm;
  padding-bottom: 1mm;
  border-bottom: 0.5pt solid rgba(148, 163, 184, 0.35);
}

.cv-contact {
  list-style: none;
  margin: 0;
  padding: 0;
  font-size: 8pt;
}

.cv-contact li {
  display: flex;
  align-items: flex-start;
  gap: 1.8mm;
  margin-bottom: 1.4mm;
  word-break: break-word;
}

/* Icônes discrètes : teinte atténuée, alignées sur la 1re ligne de texte. */
.cv-ico {
  width: 2.8mm;
  height: 2.8mm;
  flex-shrink: 0;
  margin-top: 0.45mm;
  fill: #94a3b8;
}

/* Lien cliquable dans le PDF, sans style de lien visible. */
.cv-contact-link {
  color: inherit;
  text-decoration: none;
}

/* URL sur une seule ligne : une coupure au tiret fausse l'extraction ATS. */
.cv-contact-link--url {
  white-space: nowrap;
  font-size: 7.2pt;
}

.cv-domain {
  margin-bottom: 2.5mm;
}

.cv-domain-name {
  font-size: 8pt;
  font-weight: 700;
  color: #f1f5f9;
  margin: 0 0 0.5mm;
}

.cv-side-text {
  font-size: 8pt;
  color: #cbd5e1;
  margin: 0;
}

.cv-lang-list {
  list-style: none;
  margin: 0;
  padding: 0;
  font-size: 8pt;
}

.cv-lang-list li {
  display: flex;
  justify-content: space-between;
  gap: 2mm;
  margin-bottom: 1mm;
}

.cv-lang-name {
  font-weight: 700;
  color: #f1f5f9;
}

.cv-lang-level {
  color: #94a3b8;
  text-align: right;
}

/* ── Colonne principale ── */
.cv-main {
  grid-column: 2;
  grid-row: 1;
  padding: 12mm 10mm 10mm 9mm;
  min-width: 0;
}

.cv-header {
  margin-bottom: 6mm;
}

.cv-name {
  font-size: 22pt;
  font-weight: 300;
  letter-spacing: -0.01em;
  color: #0f172a;
  margin: 0;
  text-transform: uppercase;
}

.cv-lastname {
  font-weight: 700;
}

.cv-headline {
  font-size: 11pt;
  font-weight: 600;
  color: #1d4ed8;
  margin: 1mm 0 0;
}

.cv-profile {
  font-size: 8.8pt;
  color: #4b5563;
  margin: 2.5mm 0 0;
  padding-top: 2.5mm;
  border-top: 0.5pt solid #e5e7eb;
}

.cv-section {
  margin-bottom: 5mm;
}

.cv-section-title {
  display: flex;
  align-items: center;
  gap: 2.5mm;
  font-size: 10pt;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.08em;
  color: #0f172a;
  margin: 0 0 3mm;
}

.cv-section-title::before {
  content: '';
  width: 5mm;
  height: 1.2mm;
  background: #1d4ed8;
  flex-shrink: 0;
}

.cv-section-title::after {
  content: '';
  flex: 1;
  height: 0.4pt;
  background: #e5e7eb;
}

/* ── Items (expériences, formations, projets) ── */
.cv-item {
  margin-bottom: 3.2mm;
  padding-left: 4mm;
  border-left: 0.75pt solid #dbeafe;
}

.cv-item-head {
  display: flex;
  justify-content: space-between;
  align-items: baseline;
  gap: 4mm;
}

.cv-item-title {
  font-size: 9.5pt;
  font-weight: 700;
  color: #0f172a;
  margin: 0;
}

.cv-item-date {
  font-size: 7.5pt;
  font-weight: 600;
  color: #1d4ed8;
  white-space: nowrap;
  flex-shrink: 0;
}

.cv-item-sub {
  font-size: 8.5pt;
  font-weight: 600;
  color: #6b7280;
  margin: 0.3mm 0 0;
}

.cv-item-details {
  font-size: 8.3pt;
  color: #4b5563;
  margin: 0.8mm 0 0;
  display: -webkit-box;
  -webkit-line-clamp: 3;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

.cv-item-tech {
  font-size: 7.5pt;
  color: #6b7280;
  margin: 0.8mm 0 0;
  font-style: italic;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}
</style>
