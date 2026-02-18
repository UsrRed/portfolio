<script setup lang="ts">
interface Education {
  id: number
  school: string
  school_url?: string
  status: string
  degree: string
  details: string
  start_date: string
}

defineProps<{
  educations: Education[]
}>()
</script>

<template>
  <div class="container" id="Formations">
    <h1 class="text-center text-uppercase">Formations</h1>
    <div class="flex-wrap d-flex justify-content-around text-center m-3">
      
      <div v-for="edu in educations" :key="edu.id" class="card my-1 bg-dark shadow" style="width: 18rem;">
        <div class="card-body">       
          <h5 class="card-title">
            <a class="text-white" :href="edu.school_url || '#'" target="_blank">{{ edu.school }}</a>
          </h5>       
          <div class="d-inline-flex align-items-center">
            <p v-if="edu.status === 'Obtenu'" class="card-text text-success mt-2">Obtenu&emsp;</p>
            <p v-else class="card-text text-info mt-2">En cours&emsp;</p>
            <div v-if="edu.status !== 'Obtenu'" class="spinner-border text-info"></div>
            <svg v-if="edu.status === 'Obtenu'" xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" class="bi bi-check-circle-fill text-success" viewBox="0 0 16 16">
              <path d="M16 8A8 8 0 1 1 0 8a8 8 0 0 1 16 0zm-3.97-3.03a.75.75 0 0 0-1.08.022L7.477 9.417 5.384 7.323a.75.75 0 0 0-1.06 1.06L6.97 11.03a.75.75 0 0 0 1.079-.02l3.992-4.99a.75.75 0 0 0-.01-1.05z"></path>
            </svg>
          </div><hr>	
          <p class="card-text">{{ edu.degree }}</p><hr>		 
          <p class="card-text">{{ edu.details }}</p>  
          <hr>
          <p class="card-text">{{ edu.start_date }}</p>
        </div>   
      </div>

    </div>
  </div>
</template>
