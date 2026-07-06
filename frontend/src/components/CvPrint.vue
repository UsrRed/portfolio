<script setup lang="ts">
import { computed } from 'vue'

// CV imprimable : rendu uniquement via Ctrl+P / window.print()
// (masqué à l'écran par la règle globale @media screen de style.css).
const props = defineProps<{ data: any }>()

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
const projects = computed(() => sortRecent(props.data.projects, (p) => [p.period], MAX_PROJECTS))

const linkedinDisplay = computed(() =>
  props.data.person.linkedin_url?.replace(/^https?:\/\/(www\.)?/, '').replace(/\/$/, '')
)
</script>

<template>
  <div class="cv-print">
    <!-- Colonne latérale -->
    <aside class="cv-side">
      <img v-if="data.person.image_url" :src="data.person.image_url" alt="" class="cv-photo" />

      <section class="cv-side-section">
        <h2 class="cv-side-title">Contact</h2>
        <ul class="cv-contact">
          <li v-if="data.person.location">{{ data.person.location }}</li>
          <li v-if="linkedinDisplay">{{ linkedinDisplay }}</li>
          <li v-if="data.person.driver_license">{{ data.person.driver_license }}</li>
          <li v-if="data.person.birth_date">Né le {{ data.person.birth_date }}</li>
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

    <!-- Colonne principale -->
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
}

/* ── Colonne latérale ── */
.cv-side {
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
  border: 1.5pt solid #3b82f6;
}

.cv-side-section {
  margin-bottom: 6mm;
}

.cv-side-title {
  font-size: 8.5pt;
  font-weight: 800;
  text-transform: uppercase;
  letter-spacing: 0.12em;
  color: #60a5fa;
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
  margin-bottom: 1.2mm;
  word-break: break-word;
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
  font-weight: 800;
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
  font-weight: 800;
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
