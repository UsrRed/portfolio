<script setup lang="ts">
import { useDataController } from '../controllers/useDataController'
import PresentationSection from '../components/PresentationSection.vue'
import SkillSection from '../components/SkillSection.vue'
import LanguageSection from '../components/LanguageSection.vue'
import HobbySection from '../components/HobbySection.vue'
import SoftSkillSection from '../components/SoftSkillSection.vue'
import EducationSection from '../components/EducationSection.vue'
import ExperienceSection from '../components/ExperienceSection.vue'
import ProjectSection from '../components/ProjectSection.vue'

const { data, error, loading } = useDataController()
</script>

<template>
  <div v-if="loading" class="text-center mt-5">
    <div class="spinner-border text-light" role="status">
      <span class="visually-hidden">Loading...</span>
    </div>
  </div>

  <div v-else-if="error" class="alert alert-danger text-center m-5">
    {{ error }}
  </div>

  <div v-else-if="data" class="bg-dark text-white">
    <!-- Navbar (Simplified version for now, could be a separate component) -->
    <nav class="navbar navbar-expand-md navbar-dark bg-dark shadow sticky-top">
      <div class="container-fluid">
        <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarToggler" aria-controls="navbarToggler" aria-expanded="false" aria-label="Toggle navigation">
          <span class="navbar-toggler-icon"></span>
        </button>

        <div class="collapse navbar-collapse" id="navbarToggler">
          <ul class="navbar-nav me-auto mt-2 mt-lg-0">
            <li class="nav-item">
              <a class="nav-link" href="#Presentation">Présentation</a>
            </li>
            <li class="nav-item">
              <a class="nav-link" href="#Competences">Compétences</a>
            </li>
            <li class="nav-item">
              <a class="nav-link" href="#Formations">Formations</a>
            </li>
            <li class="nav-item">
              <a class="nav-link" href="#Experiences">Expériences</a>
            </li>
            <li class="nav-item">
              <a class="nav-link" href="#projet">Projets</a>
            </li>
          </ul>
        </div>
      </div>
    </nav>

    <PresentationSection :person="data.person" />
    
    <div class="container mx-auto px-0" id="Competences">
      <SkillSection title="Compétences" :domains="data.domains" />
      <div class="octagon-bottom"></div>
    </div>

    <LanguageSection :languages="data.languages" />
    
    <br/><br/>
    
    <HobbySection :hobbies="data.hobbies" />
    
    <br/><br/>
    
    <SoftSkillSection :softSkills="data.soft_skills" />
    
    <br/><br/><br/>

    <EducationSection :educations="data.educations" />
    
    <br/><br/><br/>
    
    <ExperienceSection :experiences="data.experiences" />
    
    <br/><br/><br/>
    
    <ProjectSection :projects="data.projects" />
    
    <br/><br/>
    
    <section class="text-center">
      <p>Cliquer ci-dessous pour me contacter</p>
      <a v-if="data.person.linkedin_url" :href="data.person.linkedin_url"><img width="100em" src="/images/LinkedIn.svg" alt="logo LinkedIn"/></a>
    </section>

    <br/><br/><br/><br/>

    <footer class="footer mt-auto py-3 bg-light text-center fixed-bottom bg-dark text-white border-top border-secondary">
      <div class="container">
        <span>Site web créé par {{ data.person.first_name }} {{ data.person.last_name }}<br/>Copyright {{ new Date().getFullYear() }} - Tout droits réservés</span>
      </div>
    </footer>
  </div>
</template>