<script setup lang="ts">
interface Person {
  image_url: string
  first_name: string
  last_name: string
  birth_date?: string
  driver_license?: string
  location?: string
  title?: string
  description: string
  linkedin_url?: string
}

defineProps<{
  person: Person
}>()
</script>

<template>
  <div class="text-center" id="Presentation">
    <img class="rounded-circle m-2" width="20%" :src="person.image_url" alt="Photo de profil"/>
  </div>
  <section class="text-center">
    <h1>{{ person.first_name }} {{ person.last_name }}</h1>
    <section>
      <p v-if="person.birth_date">Né le {{ person.birth_date }}</p>
      <p v-if="person.driver_license">{{ person.driver_license }}</p>
      <p v-if="person.location">Habite à {{ person.location }}</p>
      <h3 v-if="person.title">Actuellement</h3>
      <p>{{ person.description }}</p>
      <br/><br/>
    </section>
  </section>
</template>
