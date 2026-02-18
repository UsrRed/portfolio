<script setup lang="ts">
interface SoftSkill {
  id: number
  name: string
  image_url: string
}

defineProps<{
  softSkills: SoftSkill[]
}>()
</script>

<template>
  <div class="container">
    <h1 class="text-center text-uppercase">Compétences comportementales</h1>
    <div class="d-flex flex-column flex-md-row justify-content-md-around mx-4">
      <div v-for="skill in softSkills" :key="skill.id" class="d-flex flex-column align-items-center">
        <img :src="skill.image_url" :alt="skill.name" class="m-3 rounded-circle" width="200em" />
        <p class="text-center">{{ skill.name }}</p>
      </div>
    </div>
  </div>
</template>
