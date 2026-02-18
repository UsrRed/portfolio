<script setup lang="ts">
interface Language {
  id: number
  name: string
  image_url?: string
  level: string
  certification_url?: string
}

defineProps<{
  languages: Language[]
}>()
</script>

<template>
  <div class="container">
    <h1 class="text-center text-uppercase">Langues</h1>
 
    <div class="flex-wrap d-flex justify-content-around text-center m-3">
      
      <div v-for="lang in languages" :key="lang.id" class="card bg-dark shadow" style="width: 18rem;">
        <div class="card-body">       
          <h5 class="card-title">{{ lang.name }}</h5>  
          <img v-if="lang.image_url" :src="lang.image_url" :alt="'Drapeau ' + lang.name" class="img-thumbnail" />
          <p class="card-text mt-3">
              {{ lang.level }}<br/>
              <a v-if="lang.certification_url" class="card-text text-warning fw-bold text-decoration-none" :href="lang.certification_url" target="_blank">Certification</a>
          </p>
          <hr>	
        </div>   
      </div>
      
    </div>
  </div>
</template>
