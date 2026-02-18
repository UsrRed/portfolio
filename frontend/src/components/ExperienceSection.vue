<script setup lang="ts">
interface Experience {
  id: number
  company: string
  company_url?: string
  status: string
  role: string
  details: string
  start_date: string
  duration: string
}

defineProps<{
  experiences: Experience[]
}>()
</script>

<template>
  <div class="container" id="Experiences">
    <h1 class="text-center text-uppercase">Expériences professionnelles</h1>
    <div class="flex-wrap d-flex justify-content-around text-center m-3">

      <div v-for="exp in experiences" :key="exp.id" class="card my-1 bg-dark shadow" style="width: 18rem;">
        <div class="card-body">       
          <h5 class="card-title">
            <a class="text-white" :href="exp.company_url || '#'" target="_blank">{{ exp.company }}</a>
          </h5>       
          <div class="d-inline-flex align-items-center">
            <p v-if="exp.status === 'Terminé'" class="card-text text-success mt-2">Terminé</p>
            <p v-else class="card-text text-info mt-2">En cours&emsp;</p>
            <div v-if="exp.status !== 'Terminé'" class="spinner-border text-info"></div>
          </div><hr>
          <p class="card-text">{{ exp.role }}</p><hr>		
          <p class="card-text">{{ exp.details }}</p>
          <hr>
          <p class="card-text">{{ exp.start_date }}</p>
          <p class="card-text">{{ exp.duration }}</p>
        </div>   
      </div> 

    </div>
  </div>
</template>
