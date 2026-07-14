<script setup lang="ts">
import { useDataController } from '../controllers/useDataController'
import NavBar from '../components/NavBar.vue'
import PresentationSection from '../components/PresentationSection.vue'
import SkillSection from '../components/SkillSection.vue'
import LanguageSection from '../components/LanguageSection.vue'
import HobbySection from '../components/HobbySection.vue'
import SoftSkillSection from '../components/SoftSkillSection.vue'
import EducationSection from '../components/EducationSection.vue'
import ExperienceSection from '../components/ExperienceSection.vue'
import ProjectSection from '../components/ProjectSection.vue'
import CvPrint from '../components/CvPrint.vue'

const { data, error, loading } = useDataController()
</script>

<template>
  <!-- Loading -->
  <div v-if="loading" class="loading-screen">
    <div class="spinner"></div>
    <p style="color: var(--text-muted); font-size: 0.9rem;">Chargement du portfolio…</p>
  </div>

  <!-- Error -->
  <div v-else-if="error" class="error-screen">
    <div class="error-card">
      <svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="var(--danger)" stroke-width="1.5" style="margin-bottom:1rem">
        <circle cx="12" cy="12" r="10"/>
        <line x1="12" y1="8" x2="12" y2="12"/>
        <line x1="12" y1="16" x2="12.01" y2="16"/>
      </svg>
      <p style="color: var(--danger); font-weight: 600;">Erreur de chargement</p>
      <p style="color: var(--text-muted); font-size: 0.85rem; margin-top: 0.5rem;">{{ error }}</p>
    </div>
  </div>

  <!-- Main content -->
  <div v-else-if="data">
    <!-- CV imprimable : seul contenu rendu par Ctrl+P / window.print() -->
    <CvPrint :data="data" />

    <div class="site-screen">
    <NavBar :name="data.person.first_name + ' ' + data.person.last_name" />

    <main>
      <PresentationSection
        :person="data.person"
        @update:person="data.person = $event"
      />

      <div class="separator"></div>

      <SkillSection :domains="data.domains" />

      <div class="separator"></div>

      <LanguageSection :languages="data.languages" />

      <div class="separator"></div>

      <HobbySection :hobbies="data.hobbies" />

      <div class="separator"></div>

      <SoftSkillSection :soft-skills="data.soft_skills" />

      <div class="separator"></div>

      <EducationSection :educations="data.educations" />

      <div class="separator"></div>

      <ExperienceSection :experiences="data.experiences" />

      <div class="separator"></div>

      <ProjectSection :projects="data.projects" />
    </main>

    <!-- Footer -->
    <footer class="footer">
      <div class="container footer-inner">
        <a v-if="data.person.linkedin_url" :href="data.person.linkedin_url" class="footer-linkedin" target="_blank" rel="noopener noreferrer" aria-label="Profil LinkedIn">
          <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
            <path d="M16 8a6 6 0 0 1 6 6v7h-4v-7a2 2 0 0 0-2-2 2 2 0 0 0-2 2v7h-4v-7a6 6 0 0 1 6-6zM2 9h4v12H2z"/>
            <circle cx="4" cy="4" r="2"/>
          </svg>
          Me contacter sur LinkedIn
        </a>
        <p class="footer-copy">
          <span class="footer-prompt">~$</span> Site conçu et développé par
          <span class="gradient-text">{{ data.person.first_name }} {{ data.person.last_name }}</span>
          &mdash; &copy; {{ new Date().getFullYear() }}
        </p>
      </div>
    </footer>
    </div>
  </div>
</template>

<style scoped>
.separator {
  width: 100%;
  height: 1px;
  background: linear-gradient(to right, transparent, var(--border), transparent);
}

.footer {
  background: var(--bg-2, #0b1120);
  border-top: 1px solid var(--border);
  padding: 3rem 0;
  text-align: center;
}

.footer-inner {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 1.25rem;
}

.footer-linkedin {
  display: inline-flex;
  align-items: center;
  gap: 0.625rem;
  padding: 0.65rem 1.5rem;
  border: 1px solid var(--border);
  border-radius: var(--radius-full);
  color: var(--text-muted);
  text-decoration: none;
  font-size: 0.9rem;
  font-weight: 500;
  transition: var(--transition);
}

.footer-linkedin:hover {
  border-color: var(--primary);
  color: var(--primary);
  background: var(--primary-dim);
}

.footer-copy {
  font-family: var(--font-mono);
  font-size: 0.78rem;
  color: var(--text-dim);
}

.footer-prompt {
  color: var(--primary);
  font-weight: 600;
}
</style>
