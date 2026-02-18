<script setup lang="ts">
interface Hobby {
  id: number
  name: string
  image_url: string
}

defineProps<{
  hobbies: Hobby[]
}>()
</script>

<template>
  <div class="container">
    <h1 class="text-center text-uppercase">Passions</h1>
    <div class="d-flex flex-column flex-md-row justify-content-md-around mx-4">
      <div v-for="hobby in hobbies" :key="hobby.id" class="d-flex flex-column align-items-center">
        <img :src="hobby.image_url" :alt="hobby.name" class="m-3 rounded-circle" width="200em" />
        <p class="text-center">{{ hobby.name }}</p>
      </div>
    </div>
  </div>
</template>
