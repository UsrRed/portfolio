<script setup lang="ts">
import { ref, reactive } from 'vue'
import { useAdmin } from '../composables/useAdmin'
import EditModal from './EditModal.vue'
import ImageUploadField from './ImageUploadField.vue'
import { ApiService } from '../services/api.service'

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

const props = defineProps<{ person: Person }>()
const emit = defineEmits<{ 'update:person': [Person] }>()

const { adminMode } = useAdmin()

const showModal = ref(false)
const saving = ref(false)
const form = reactive<Person>({ ...props.person })

function openEdit() {
  Object.assign(form, props.person)
  showModal.value = true
}

async function save() {
  saving.value = true
  try {
    const updated = await ApiService.updatePerson(form)
    emit('update:person', updated)
    showModal.value = false
  } catch {
    alert('Erreur lors de la sauvegarde')
  } finally {
    saving.value = false
  }
}
</script>

<template>
  <section class="hero" id="presentation">
    <div class="hero-blobs">
      <div class="blob blob-1"></div>
      <div class="blob blob-2"></div>
      <div class="blob blob-3"></div>
    </div>

    <div class="hero-content container">
      <div class="hero-avatar-wrap">
        <div class="hero-avatar-ring"></div>
        <img
          :src="person.image_url"
          :alt="person.first_name + ' ' + person.last_name"
          class="hero-avatar"
        />
      </div>

      <div class="hero-text">
        <p class="hero-greeting">Bonjour, je suis</p>
        <h1 class="hero-name">
          {{ person.first_name }}<br />
          <span class="gradient-text">{{ person.last_name }}</span>
        </h1>

        <p v-if="person.title" class="hero-title">{{ person.title }}</p>

        <p class="hero-description">{{ person.description }}</p>

        <div class="hero-tags">
          <span v-if="person.location" class="tag">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"/>
              <circle cx="12" cy="10" r="3"/>
            </svg>
            {{ person.location }}
          </span>
          <span v-if="person.driver_license" class="tag">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <rect x="1" y="3" width="15" height="13" rx="2"/>
              <path d="m16 8 2 2 4-4M22 16l-1.5-6H1.5L0 16"/>
              <circle cx="5.5" cy="18.5" r="2.5"/>
              <circle cx="18.5" cy="18.5" r="2.5"/>
            </svg>
            {{ person.driver_license }}
          </span>
          <span v-if="person.birth_date" class="tag">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <rect x="3" y="4" width="18" height="18" rx="2" ry="2"/>
              <line x1="16" y1="2" x2="16" y2="6"/>
              <line x1="8" y1="2" x2="8" y2="6"/>
              <line x1="3" y1="10" x2="21" y2="10"/>
            </svg>
            Né le {{ person.birth_date }}
          </span>
        </div>

        <div class="hero-actions">
          <a v-if="person.linkedin_url" :href="person.linkedin_url" class="btn btn-primary" target="_blank">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor">
              <path d="M16 8a6 6 0 0 1 6 6v7h-4v-7a2 2 0 0 0-2-2 2 2 0 0 0-2 2v7h-4v-7a6 6 0 0 1 6-6zM2 9h4v12H2z"/>
              <circle cx="4" cy="4" r="2"/>
            </svg>
            LinkedIn
          </a>
          <a href="#competences" class="btn btn-outline">
            Voir mes compétences
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <line x1="5" y1="12" x2="19" y2="12"/>
              <polyline points="12 5 19 12 12 19"/>
            </svg>
          </a>
          <button v-if="adminMode" class="btn btn-admin" @click="openEdit">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/>
              <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/>
            </svg>
            Modifier la présentation
          </button>
        </div>
      </div>
    </div>

    <div class="hero-scroll">
      <div class="scroll-indicator"></div>
    </div>
  </section>

  <EditModal
    v-if="showModal"
    title="Modifier la présentation"
    :saving="saving"
    @close="showModal = false"
    @save="save"
  >
    <div class="form-grid">
      <div class="form-row">
        <div class="form-field">
          <label class="field-label">Prénom</label>
          <input class="field-input" v-model="form.first_name" />
        </div>
        <div class="form-field">
          <label class="field-label">Nom</label>
          <input class="field-input" v-model="form.last_name" />
        </div>
      </div>
      <div class="form-field">
        <label class="field-label">Titre</label>
        <input class="field-input" v-model="form.title" placeholder="ex: Étudiant en BUT R&T" />
      </div>
      <div class="form-field">
        <label class="field-label">Description</label>
        <textarea class="field-input field-textarea" v-model="form.description" rows="4"></textarea>
      </div>
      <div class="form-row">
        <div class="form-field">
          <label class="field-label">Lieu</label>
          <input class="field-input" v-model="form.location" />
        </div>
        <div class="form-field">
          <label class="field-label">Permis</label>
          <input class="field-input" v-model="form.driver_license" />
        </div>
      </div>
      <div class="form-field">
        <label class="field-label">LinkedIn URL</label>
        <input class="field-input" v-model="form.linkedin_url" />
      </div>
      <ImageUploadField v-model="form.image_url" label="Photo de profil" />
    </div>
  </EditModal>
</template>

<style scoped>
.hero {
  min-height: 100vh;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  position: relative;
  overflow: hidden;
  padding: 7rem 0 4rem;
}

.hero-blobs {
  position: absolute;
  inset: 0;
  overflow: hidden;
  pointer-events: none;
}

.blob {
  position: absolute;
  border-radius: 50%;
  filter: blur(80px);
  opacity: 0.12;
}

.blob-1 {
  width: 700px;
  height: 700px;
  background: radial-gradient(circle, #6366f1, #a855f7);
  top: -200px;
  right: -100px;
  animation: blobFloat 12s ease-in-out infinite;
}

.blob-2 {
  width: 500px;
  height: 500px;
  background: radial-gradient(circle, #22d3ee, #6366f1);
  bottom: -100px;
  left: -100px;
  animation: blobFloat 10s ease-in-out infinite reverse;
}

.blob-3 {
  width: 350px;
  height: 350px;
  background: radial-gradient(circle, #a855f7, #22d3ee);
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  animation: blobFloat 14s ease-in-out infinite 2s;
}

.hero-content {
  display: flex;
  flex-direction: column;
  align-items: center;
  text-align: center;
  gap: 2.5rem;
  position: relative;
  z-index: 1;
}

.hero-avatar-wrap {
  position: relative;
  display: inline-block;
}

.hero-avatar-ring {
  position: absolute;
  inset: -4px;
  border-radius: 50%;
  background: var(--grad);
  animation: spin 6s linear infinite;
  mask: radial-gradient(farthest-side, transparent calc(100% - 3px), black calc(100% - 3px));
  -webkit-mask: radial-gradient(farthest-side, transparent calc(100% - 3px), black calc(100% - 3px));
}

@keyframes spin {
  to { transform: rotate(360deg); }
}

.hero-avatar {
  width: 160px;
  height: 160px;
  border-radius: 50%;
  object-fit: cover;
  display: block;
  border: 4px solid var(--bg);
  box-shadow: 0 0 40px rgba(99, 102, 241, 0.3);
}

.hero-greeting {
  font-size: 1rem;
  color: var(--text-muted);
  font-weight: 500;
  letter-spacing: 0.05em;
  text-transform: uppercase;
  margin-bottom: -1rem;
}

.hero-name {
  font-size: clamp(2.75rem, 8vw, 5.5rem);
  font-weight: 900;
  line-height: 1.05;
  letter-spacing: -0.03em;
  color: var(--text);
}

.hero-title {
  font-size: 1.1rem;
  color: var(--accent);
  font-weight: 600;
  margin-top: -0.5rem;
}

.hero-description {
  max-width: 620px;
  color: var(--text-muted);
  font-size: 1rem;
  line-height: 1.7;
}

.hero-tags {
  display: flex;
  flex-wrap: wrap;
  gap: 0.6rem;
  justify-content: center;
}

.hero-actions {
  display: flex;
  gap: 1rem;
  flex-wrap: wrap;
  justify-content: center;
}

.btn-admin {
  display: inline-flex;
  align-items: center;
  gap: 0.4rem;
  padding: 0.55rem 1.1rem;
  background: rgba(251, 191, 36, 0.1);
  border: 1px solid rgba(251, 191, 36, 0.3);
  border-radius: var(--radius-full);
  color: #fbbf24;
  font-size: 0.85rem;
  font-weight: 600;
  cursor: pointer;
  transition: var(--transition);
}

.btn-admin:hover {
  background: rgba(251, 191, 36, 0.18);
  border-color: rgba(251, 191, 36, 0.5);
}

.hero-scroll {
  position: absolute;
  bottom: 2rem;
  left: 50%;
  transform: translateX(-50%);
}

.scroll-indicator {
  width: 24px;
  height: 40px;
  border: 2px solid rgba(255, 255, 255, 0.2);
  border-radius: 12px;
  position: relative;
}

.scroll-indicator::before {
  content: '';
  position: absolute;
  top: 6px;
  left: 50%;
  transform: translateX(-50%);
  width: 4px;
  height: 8px;
  background: var(--primary);
  border-radius: 2px;
  animation: scrollBounce 1.5s ease-in-out infinite;
}

@keyframes scrollBounce {
  0%, 100% { transform: translateX(-50%) translateY(0); opacity: 1; }
  50% { transform: translateX(-50%) translateY(10px); opacity: 0.3; }
}

.form-grid {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.form-row {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 0.75rem;
}

.form-field {
  display: flex;
  flex-direction: column;
  gap: 0.4rem;
}

.field-label {
  font-size: 0.8rem;
  font-weight: 600;
  color: var(--text-muted);
  text-transform: uppercase;
  letter-spacing: 0.05em;
}

.field-input {
  background: var(--bg);
  border: 1px solid var(--border);
  border-radius: var(--radius-sm);
  color: var(--text);
  font-size: 0.9rem;
  padding: 0.5rem 0.75rem;
  font-family: inherit;
  transition: border-color 0.2s;
}

.field-input:focus {
  outline: none;
  border-color: var(--primary);
}

.field-textarea {
  resize: vertical;
  min-height: 80px;
}

@keyframes blobFloat {
  0%, 100% { transform: translate(0, 0) scale(1); }
  33% { transform: translate(30px, -30px) scale(1.05); }
  66% { transform: translate(-20px, 20px) scale(0.95); }
}

@media (max-width: 768px) {
  .hero-avatar {
    width: 120px;
    height: 120px;
  }

  .hero-actions {
    flex-direction: column;
    width: 100%;
  }

  .hero-actions .btn,
  .hero-actions .btn-admin {
    justify-content: center;
  }

  .form-row {
    grid-template-columns: 1fr;
  }
}
</style>
