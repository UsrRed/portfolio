<script setup lang="ts">
interface Project {
  id: number
  title: string
  image_url: string
  period: string
  description: string
  skills_human?: string
  skills_tech?: string
  link_url: string
}

defineProps<{
  projects: Project[]
}>()

const getProjectId = (project: Project) => {
  return project.title ? project.title.replace(/\s+/g, '') : `project-${project.id}`
}
</script>

<template>
    <div class="text-break my-2 py-3" id="projet">
          <h1 id="Projets" class="text-center text-uppercase">Projets</h1>
          <div id="carouselIndicators" class="carousel slide mx-4 text-center border border-3" data-bs-ride="carousel">
            <div class="carousel-indicators">
                <button v-for="(project, index) in projects" :key="'ind-' + project.id" type="button" data-bs-target="#carouselIndicators" :data-bs-slide-to="index" :class="{ active: index === 0 }" :aria-current="index === 0 ? 'true' : 'false'" :aria-label="'Slide ' + index"></button>
            </div>
            <div class="carousel-inner">
                <div v-for="(project, index) in projects" :key="'slide-' + project.id" class="carousel-item" :class="{ active: index === 0 }" :id="getProjectId(project)">
                  <img class="carousel-img d-block w-100 rounded" :src="project.image_url" :alt="project.title" />
                  <div class="carousel-caption d-none d-md-block bg-secondary" style="opacity: 0.8;">
                    <h4>{{ project.title }}</h4>
                    <p class="text-sm m-0">{{ project.period }}</p>
                    <p>{{ project.description }}</p>
                    <h5 class="text-decoration-underline">Compétences associées</h5>
                    <p v-if="project.skills_human" class="fw-bold m-0">Humaine : {{ project.skills_human }}</p>
                    <p v-if="project.skills_tech" class="fw-bold m-0">Technique : {{ project.skills_tech }}</p>
                    <a class='btn btn-primary' :href="project.link_url" role='button' target='_blank'>En savoir plus</a>
                  </div>
                </div>
            </div>
            <button class="carousel-control-prev" type="button" data-bs-target="#carouselIndicators" data-bs-slide="prev">
                <span class="carousel-control-prev-icon" aria-hidden="true"></span>
                <span class="visually-hidden">Previous</span>
            </button>
            <button class="carousel-control-next" type="button" data-bs-target="#carouselIndicators" data-bs-slide="next">
                <span class="carousel-control-next-icon" aria-hidden="true"></span>
                <span class="visually-hidden">Next</span>
            </button>
          </div>
        <br>

        <div class="mx-auto d-flex flex-md-row flex-column justify-content-center text-center">
            <div v-for="project in projects" :key="'thumb-' + project.id" class="mx-auto mx-md-2 project-item">
              <a :href="'#' + getProjectId(project)" style="color: white; font-weight: bold;">
                <img :src="project.image_url" class="rounded" :alt="project.title"/>    
                <p>{{ project.title }}</p>
              </a>
              <a class='btn btn-info d-flex d-md-none text-center' :href="project.link_url" target='_blank'>En savoir plus</a><br/>
            </div>
        </div>

    </div>
</template>
