<script setup lang="ts">
// CV imprimable : rendu uniquement via Ctrl+P / window.print()
// (masqué à l'écran par la règle globale @media screen de style.css).
defineProps<{ data: any }>()
</script>

<template>
  <div class="cv-print">
    <!-- En-tête identité -->
    <header class="cv-header">
      <div class="cv-identity">
        <h1 class="cv-name">{{ data.person.first_name }} {{ data.person.last_name }}</h1>
        <p v-if="data.person.title" class="cv-headline">{{ data.person.title }}</p>
      </div>
      <ul class="cv-contact">
        <li v-if="data.person.location">{{ data.person.location }}</li>
        <li v-if="data.person.driver_license">{{ data.person.driver_license }}</li>
        <li v-if="data.person.birth_date">Né le {{ data.person.birth_date }}</li>
        <li v-if="data.person.linkedin_url">{{ data.person.linkedin_url }}</li>
      </ul>
    </header>

    <!-- Profil -->
    <section v-if="data.person.description" class="cv-profile">
      <p>{{ data.person.description }}</p>
    </section>

    <div class="cv-body">
      <!-- Colonne principale -->
      <main class="cv-main">
        <section v-if="data.experiences?.length" class="cv-section">
          <h2 class="cv-section-title">Expériences professionnelles</h2>
          <article v-for="exp in data.experiences" :key="exp.id" class="cv-item">
            <div class="cv-item-head">
              <h3 class="cv-item-title">{{ exp.role }}</h3>
              <span class="cv-item-date">{{ exp.start_date }}<template v-if="exp.duration"> · {{ exp.duration }}</template></span>
            </div>
            <p class="cv-item-sub">{{ exp.company }}</p>
            <p v-if="exp.details" class="cv-item-details">{{ exp.details }}</p>
          </article>
        </section>

        <section v-if="data.educations?.length" class="cv-section">
          <h2 class="cv-section-title">Formations</h2>
          <article v-for="edu in data.educations" :key="edu.id" class="cv-item">
            <div class="cv-item-head">
              <h3 class="cv-item-title">{{ edu.degree }}</h3>
              <span class="cv-item-date">{{ edu.start_date }}<template v-if="edu.status"> · {{ edu.status }}</template></span>
            </div>
            <p class="cv-item-sub">{{ edu.school }}</p>
            <p v-if="edu.details" class="cv-item-details">{{ edu.details }}</p>
          </article>
        </section>

        <section v-if="data.projects?.length" class="cv-section">
          <h2 class="cv-section-title">Projets</h2>
          <article v-for="proj in data.projects" :key="proj.id" class="cv-item">
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
        <section v-if="data.domains?.length" class="cv-section">
          <h2 class="cv-section-title">Compétences</h2>
          <div v-for="domain in data.domains.filter((d: any) => d.skills?.length)" :key="domain.id" class="cv-domain">
            <h3 class="cv-domain-name">{{ domain.name }}</h3>
            <p class="cv-skill-list">{{ domain.skills.map((s: any) => s.name).join(' · ') }}</p>
          </div>
        </section>

        <section v-if="data.languages?.length" class="cv-section">
          <h2 class="cv-section-title">Langues</h2>
          <ul class="cv-list">
            <li v-for="lang in data.languages" :key="lang.id">
              <strong>{{ lang.name }}</strong><template v-if="lang.level"> — {{ lang.level }}</template>
            </li>
          </ul>
        </section>

        <section v-if="data.soft_skills?.length" class="cv-section">
          <h2 class="cv-section-title">Savoir-être</h2>
          <p class="cv-skill-list">{{ data.soft_skills.map((s: any) => s.name).join(' · ') }}</p>
        </section>

        <section v-if="data.hobbies?.length" class="cv-section">
          <h2 class="cv-section-title">Centres d'intérêt</h2>
          <p class="cv-skill-list">{{ data.hobbies.map((h: any) => h.name).join(' · ') }}</p>
        </section>
      </aside>
    </div>
  </div>
</template>

<style scoped>
.cv-print {
  font-family: 'Inter', -apple-system, sans-serif;
  color: #111827;
  background: #ffffff;
  font-size: 9.5pt;
  line-height: 1.45;
}

/* ── En-tête ── */
.cv-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-end;
  gap: 8mm;
  padding-bottom: 4mm;
  border-bottom: 2pt solid #1d4ed8;
}

.cv-name {
  font-size: 20pt;
  font-weight: 800;
  letter-spacing: -0.02em;
  color: #0f172a;
  margin: 0;
}

.cv-headline {
  font-size: 11pt;
  font-weight: 600;
  color: #1d4ed8;
  margin: 1mm 0 0;
}

.cv-contact {
  list-style: none;
  margin: 0;
  padding: 0;
  text-align: right;
  font-size: 8.5pt;
  color: #374151;
}

.cv-contact li {
  white-space: nowrap;
}

/* ── Profil ── */
.cv-profile {
  margin: 4mm 0 0;
  font-size: 9pt;
  color: #374151;
}

.cv-profile p {
  margin: 0;
}

/* ── Corps deux colonnes ── */
.cv-body {
  display: grid;
  grid-template-columns: 1fr 54mm;
  gap: 8mm;
  margin-top: 5mm;
}

.cv-section {
  margin-bottom: 5mm;
}

.cv-section-title {
  font-size: 10.5pt;
  font-weight: 800;
  text-transform: uppercase;
  letter-spacing: 0.08em;
  color: #1d4ed8;
  margin: 0 0 2.5mm;
  padding-bottom: 1mm;
  border-bottom: 0.5pt solid #cbd5e1;
}

/* ── Items (expériences, formations, projets) ── */
.cv-item {
  margin-bottom: 3.5mm;
  break-inside: avoid;
  page-break-inside: avoid;
}

.cv-item-head {
  display: flex;
  justify-content: space-between;
  align-items: baseline;
  gap: 4mm;
}

.cv-item-title {
  font-size: 10pt;
  font-weight: 700;
  color: #0f172a;
  margin: 0;
}

.cv-item-date {
  font-size: 8pt;
  color: #6b7280;
  white-space: nowrap;
  flex-shrink: 0;
}

.cv-item-sub {
  font-size: 9pt;
  font-weight: 600;
  color: #1d4ed8;
  margin: 0.5mm 0 0;
}

.cv-item-details {
  font-size: 8.8pt;
  color: #374151;
  margin: 1mm 0 0;
}

.cv-item-tech {
  font-size: 8pt;
  color: #6b7280;
  margin: 1mm 0 0;
  font-style: italic;
}

/* ── Colonne latérale ── */
.cv-domain {
  margin-bottom: 2.5mm;
  break-inside: avoid;
  page-break-inside: avoid;
}

.cv-domain-name {
  font-size: 8.5pt;
  font-weight: 700;
  color: #0f172a;
  margin: 0 0 0.5mm;
}

.cv-skill-list {
  font-size: 8.5pt;
  color: #374151;
  margin: 0;
}

.cv-list {
  list-style: none;
  margin: 0;
  padding: 0;
  font-size: 8.8pt;
  color: #374151;
}

.cv-list li {
  margin-bottom: 1mm;
}
</style>
