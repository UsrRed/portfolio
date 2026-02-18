<script setup lang="ts">


interface Skill {
  id: number
  name: string
  image_url: string
  details: string
}

interface Domain {
  id: number
  name: string
  skills: Skill[]
}

defineProps<{
  title: string
  domains: Domain[]
}>()

// Helper to handle collapse state if needed, though Bootstrap JS might handle it via data-attributes.
// We will rely on Bootstrap's data-bs-toggle for now as in the original HTML.
</script>

<template>
  <div v-for="domain in domains" :key="domain.id" class="skill-domain-section mb-5">
    <h1 class="text-center text-uppercase">{{ domain.name }}</h1>
    <div class="octagon mx-1">
        <div class="octagon-top">
            <br><h1 class="text-center text-uppercase text-white my-0 mx-5">{{ domain.name }}</h1>
            <p class="text-sm text-center mx-2 text-warning fw-bold">Cliquer sur un logo afin de voir la description</p>
        </div>
        <div class ="row bg-dark text-white d-flex justify-content-around octagon-center mx-0">
            <div v-for="skill in domain.skills" :key="skill.id" class="col-sm-4 col-md-3 col-lg-2 my-1 mx-3">
              <div class="container d-flex flex-column px-0">
                <div class="row d-inline-flex flex-wrap">
                  <div class="d-flex justify-content-center align-self-center octagon-container">
                    <img class="rounded m-1 clickable size over-relief-style collapsed" :src="skill.image_url" :alt="'Logo ' + skill.name" data-bs-toggle="collapse" :data-bs-target="'#collapse-' + skill.id" aria-expanded="false" :aria-controls="'collapse-' + skill.id"/>
                  </div>
                  <div class="flex-row text-center text-break p-0">
                    <h2 class="clickable collapsed" data-bs-toggle="collapse" :data-bs-target="'#collapse-' + skill.id" aria-expanded="false" :aria-controls="'collapse-' + skill.id">{{ skill.name }}</h2>
                    <div :id="'collapse-' + skill.id" class="w-75 mx-auto collapse">
                      <p>{{ skill.details }}</p>
                    </div>
                  </div>
                </div>
              </div>
            </div>
        </div>
        <div class="octagon-bottom"></div>
    </div>
  </div>
</template>

<style scoped>
/* Add any specific styles here if not in global css */
</style>
