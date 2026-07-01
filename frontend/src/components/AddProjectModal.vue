<script setup lang="ts">
import { ref, reactive } from 'vue'
import { ApiService, type ProjectPayload } from '../services/api.service'

const emit = defineEmits<{
  close: []
  created: [project: any]
}>()

const loading = ref(false)
const form = reactive<ProjectPayload>({
  title: '',
  image_url: '',
  period: '',
  description: '',
  skills_human: '',
  skills_tech: '',
  link_url: '',
})

async function submit() {
  if (!form.title.trim()) return
  loading.value = true
  try {
    const project = await ApiService.createProject({ ...form })
    emit('created', project)
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <div class="modal-overlay" @click.self="emit('close')">
    <div class="modal">
      <div class="modal-header">
        <h2 class="modal-title">Ajouter un projet</h2>
        <button class="modal-close" @click="emit('close')">✕</button>
      </div>

      <form @submit.prevent="submit">
        <div class="form-group">
          <label class="form-label">Titre *</label>
          <input v-model="form.title" class="form-input" placeholder="Ex: Site web catalogue" required />
        </div>

        <div class="form-group">
          <label class="form-label">URL de l'image</label>
          <input v-model="form.image_url" class="form-input" placeholder="/images/mon-projet.png" />
        </div>

        <div class="form-group">
          <label class="form-label">Période</label>
          <input v-model="form.period" class="form-input" placeholder="Ex: jan. - mars 2025" />
        </div>

        <div class="form-group">
          <label class="form-label">Description</label>
          <textarea v-model="form.description" class="form-textarea" placeholder="Décrivez votre projet..."></textarea>
        </div>

        <div class="form-group">
          <label class="form-label">Compétences humaines</label>
          <input v-model="form.skills_human" class="form-input" placeholder="Ex: Autonomie, Savoir convaincre" />
        </div>

        <div class="form-group">
          <label class="form-label">Compétences techniques</label>
          <input v-model="form.skills_tech" class="form-input" placeholder="Ex: Docker, SQL, Python" />
        </div>

        <div class="form-group">
          <label class="form-label">Lien</label>
          <input v-model="form.link_url" class="form-input" placeholder="https://..." type="url" />
        </div>

        <div class="modal-footer">
          <button type="button" class="btn btn-ghost" @click="emit('close')">Annuler</button>
          <button type="submit" class="btn btn-primary" :disabled="loading || !form.title.trim()">
            <svg v-if="loading" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="spin">
              <path d="M21 12a9 9 0 1 1-6.219-8.56"/>
            </svg>
            <svg v-else width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/>
            </svg>
            {{ loading ? 'Ajout en cours...' : 'Ajouter le projet' }}
          </button>
        </div>
      </form>
    </div>
  </div>
</template>

<style scoped>
.spin {
  animation: spin 1s linear infinite;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}

button:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}
</style>
