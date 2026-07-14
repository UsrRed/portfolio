<script setup lang="ts">
import { ref, reactive, computed } from 'vue'
import { useAdmin } from '../composables/useAdmin'
import EditModal from './EditModal.vue'
import ImageUploadField from './ImageUploadField.vue'
import { ApiService } from '../services/api.service'

const canAddProject = import.meta.env.VITE_ENABLE_ADD_PROJECT === 'true'

interface Project {
  id: number
  title: string
  image_url: string
  period: string
  description: string
  skills_human?: string
  skills_tech?: string
  link_url: string
  hidden?: boolean
}

const props = defineProps<{ projects: Project[] }>()

const { adminMode } = useAdmin()
const saving = ref(false)
const localProjects = ref<Project[]>([...props.projects])

// En mode admin on voit tout (les masqués repérés par un badge) ;
// sinon on filtre — en prod l'API ne les renvoie de toute façon pas.
const visibleProjects = computed(() =>
  adminMode.value ? localProjects.value : localProjects.value.filter(p => !p.hidden)
)

const toast = ref<{ msg: string; type: 'success' | 'error' } | null>(null)

function showToast(msg: string, type: 'success' | 'error') {
  toast.value = { msg, type }
  setTimeout(() => (toast.value = null), 3000)
}

type ModalMode = { type: 'add' } | { type: 'edit'; item: Project } | null
const modal = ref<ModalMode>(null)
const form = reactive<any>({})

function openAdd() {
  Object.assign(form, { title: '', image_url: '', period: '', description: '', skills_human: '', skills_tech: '', link_url: '', hidden: false })
  modal.value = { type: 'add' }
}

function openEdit(item: Project) {
  Object.assign(form, { ...item })
  modal.value = { type: 'edit', item }
}

async function save() {
  if (!modal.value) return
  saving.value = true
  try {
    if (modal.value.type === 'add') {
      const created = await ApiService.createProject({ ...form })
      localProjects.value.push(created)
      showToast('Projet ajouté avec succès !', 'success')
    } else {
      const id = modal.value.item.id
      const updated = await ApiService.updateProject(id, { ...form })
      const idx = localProjects.value.findIndex(p => p.id === id)
      if (idx !== -1) localProjects.value[idx] = { ...updated, id }
      showToast('Projet mis à jour !', 'success')
    }
    modal.value = null
  } catch {
    showToast('Erreur lors de la sauvegarde', 'error')
  } finally {
    saving.value = false
  }
}

async function deleteItem() {
  if (!modal.value || modal.value.type !== 'edit') return
  saving.value = true
  try {
    const id = modal.value.item.id
    await ApiService.deleteProject(id)
    localProjects.value = localProjects.value.filter(p => p.id !== id)
    modal.value = null
    showToast('Projet supprimé', 'success')
  } catch {
    showToast('Erreur lors de la suppression', 'error')
  } finally {
    saving.value = false
  }
}
</script>

<template>
  <section v-reveal.stagger class="section" id="projets">
    <div class="container">
      <div class="section-header">
        <h2 class="section-title">Projets</h2>
        <div class="section-divider"></div>
        <button v-if="adminMode || canAddProject" class="btn-add" @click="openAdd">
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/>
          </svg>
          Ajouter
        </button>
      </div>

      <div class="projects-grid">
        <article v-for="project in visibleProjects" :key="project.id" class="project-card stagger-item" :class="{ 'project-hidden': project.hidden }">
          <span v-if="adminMode && project.hidden" class="project-hidden-badge">Masqué</span>
          <button v-if="adminMode" class="project-edit-btn" @click="openEdit(project)" title="Modifier">
            <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/>
              <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/>
            </svg>
          </button>

          <div v-if="project.image_url" class="project-img-wrap">
            <img :src="project.image_url" :alt="'Aperçu du projet ' + project.title" class="project-img" width="640" height="360" loading="lazy" decoding="async" />
            <div class="project-overlay">
              <p v-if="project.description" class="project-desc">{{ project.description }}</p>
              <a v-if="project.link_url" :href="project.link_url" class="btn btn-primary project-link" target="_blank" rel="noopener noreferrer">
                En savoir plus
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <path d="M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h6"/>
                  <polyline points="15 3 21 3 21 9"/><line x1="10" y1="14" x2="21" y2="3"/>
                </svg>
              </a>
            </div>
          </div>
          <div v-else class="project-no-img">
            <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" opacity="0.3">
              <rect x="3" y="3" width="18" height="18" rx="2"/>
              <circle cx="8.5" cy="8.5" r="1.5"/>
              <polyline points="21 15 16 10 5 21"/>
            </svg>
          </div>
          <div class="project-body">
            <h3 class="project-title">{{ project.title }}</h3>
            <span v-if="project.period" class="tag project-period">{{ project.period }}</span>
            <div v-if="project.skills_tech || project.skills_human" class="project-skills">
              <p v-if="project.skills_tech" class="project-skills-text tech">{{ project.skills_tech }}</p>
              <p v-if="project.skills_human" class="project-skills-text human">{{ project.skills_human }}</p>
            </div>
          </div>
        </article>
      </div>
    </div>

    <EditModal
      v-if="modal"
      :title="modal?.type === 'add' ? 'Ajouter un projet' : 'Modifier le projet'"
      :saving="saving"
      :delete-label="modal?.type === 'edit' ? 'Supprimer le projet' : undefined"
      @close="modal = null"
      @save="save"
      @delete="deleteItem"
    >
      <div class="form-grid">
        <div class="form-field">
          <label class="field-label">Titre</label>
          <input class="field-input" v-model="form.title" placeholder="ex: Site web catalogue" />
        </div>
        <div class="form-field">
          <label class="field-label">Période</label>
          <input class="field-input" v-model="form.period" placeholder="ex: avril - juin 2024" />
        </div>
        <div class="form-field">
          <label class="field-label">Description</label>
          <textarea class="field-input field-textarea" v-model="form.description" rows="3"></textarea>
        </div>
        <div class="form-field">
          <label class="field-label">Compétences techniques</label>
          <textarea class="field-input field-textarea" v-model="form.skills_tech" rows="2" placeholder="Langages, outils…"></textarea>
        </div>
        <div class="form-field">
          <label class="field-label">Compétences humaines</label>
          <input class="field-input" v-model="form.skills_human" placeholder="Autonomie, Travail en équipe…" />
        </div>
        <div class="form-field">
          <label class="field-label">Lien</label>
          <input class="field-input" v-model="form.link_url" placeholder="https://…" />
        </div>
        <ImageUploadField v-model="form.image_url" label="Image du projet" />
        <label class="field-checkbox">
          <input type="checkbox" v-model="form.hidden" />
          Masquer ce projet (il n'apparaîtra pas sur le site en production)
        </label>
      </div>
    </EditModal>

    <Teleport to="body">
      <div v-if="toast" :class="['toast', `toast-${toast.type}`]">
        {{ toast.msg }}
      </div>
    </Teleport>
  </section>
</template>

<style scoped>
.section-header {
  display: flex;
  align-items: center;
  gap: 1rem;
  margin-bottom: 3rem;
}

.section-divider {
  flex: 1;
  height: 1px;
  width: auto;
  margin: 0;
  border-radius: 0;
  background: var(--border);
}

.btn-add {
  display: inline-flex;
  align-items: center;
  gap: 0.35rem;
  padding: 0.4rem 0.875rem;
  background: rgba(251, 191, 36, 0.1);
  border: 1px dashed rgba(251, 191, 36, 0.4);
  border-radius: var(--radius-sm);
  color: #fbbf24;
  font-size: 0.8rem;
  font-weight: 600;
  cursor: pointer;
  white-space: nowrap;
  transition: var(--transition);
}

.btn-add:hover { background: rgba(251, 191, 36, 0.18); }

.projects-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(320px, 1fr));
  gap: 1.5rem;
}

.project-card {
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: var(--radius);
  overflow: hidden;
  transition: var(--transition);
  display: flex;
  flex-direction: column;
  position: relative;
}

.project-card:hover {
  border-color: var(--border-glow);
  box-shadow: var(--glow);
  transform: translateY(-4px);
}

.project-edit-btn {
  position: absolute;
  top: 8px;
  right: 8px;
  z-index: 10;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 30px;
  height: 30px;
  background: rgba(251, 191, 36, 0.15);
  border: 1px solid rgba(251, 191, 36, 0.35);
  border-radius: var(--radius-sm);
  color: #fbbf24;
  cursor: pointer;
  opacity: 0;
  transition: opacity 0.2s, background 0.2s;
}

.project-card:hover .project-edit-btn {
  opacity: 1;
}

.project-edit-btn:hover {
  background: rgba(251, 191, 36, 0.25);
}

.project-img-wrap {
  position: relative;
  aspect-ratio: 16 / 9;
  overflow: hidden;
  background: var(--bg-elevated);
}

.project-img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  transition: transform 0.5s ease;
}

.project-card:hover .project-img {
  transform: scale(1.05);
}

.project-overlay {
  position: absolute;
  inset: 0;
  background: linear-gradient(to top, rgba(4, 10, 7, 0.96) 0%, rgba(4, 10, 7, 0.7) 60%, transparent 100%);
  display: flex;
  flex-direction: column;
  justify-content: flex-end;
  padding: 1.25rem;
  opacity: 0;
  transition: opacity 0.4s ease;
}

.project-card:hover .project-overlay {
  opacity: 1;
}

.project-desc {
  font-size: 0.82rem;
  color: rgba(226, 232, 240, 0.85);
  line-height: 1.5;
  margin-bottom: 0.75rem;
  display: -webkit-box;
  -webkit-line-clamp: 4;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

.project-link {
  align-self: flex-start;
  padding: 0.5rem 1.1rem;
  font-size: 0.85rem;
}

.project-body {
  padding: 1.25rem;
  display: flex;
  flex-direction: column;
  gap: 0.6rem;
  flex: 1;
}

.project-title {
  font-size: 1rem;
  font-weight: 700;
  color: var(--text);
  line-height: 1.3;
}

.project-period { align-self: flex-start; }

.project-skills {
  display: flex;
  flex-direction: column;
  gap: 0.35rem;
  margin-top: auto;
}

.project-skills-text {
  font-size: 0.75rem;
  line-height: 1.45;
  margin: 0;
  padding: 0.3rem 0.75rem;
  border-radius: var(--radius-sm);
}

.project-skills-text.tech {
  background: var(--primary-dim);
  border: 1px solid rgba(var(--primary-rgb), 0.25);
  color: #6ee7b7;
}

.project-skills-text.human {
  background: var(--surface);
  border: 1px solid var(--border);
  color: var(--text-muted);
}

.project-no-img {
  aspect-ratio: 16 / 9;
  background: var(--surface);
  border-bottom: 1px solid var(--border);
  display: flex;
  align-items: center;
  justify-content: center;
  color: var(--text-dim);
}

.form-grid { display: flex; flex-direction: column; gap: 1rem; }
.form-field { display: flex; flex-direction: column; gap: 0.4rem; }

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
}

.field-input:focus { outline: none; border-color: var(--primary); }
.field-textarea { resize: vertical; min-height: 70px; }

.field-checkbox {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  font-size: 0.85rem;
  color: var(--text-muted);
  cursor: pointer;
}

.project-hidden { opacity: 0.45; }

.project-hidden-badge {
  position: absolute;
  top: 8px;
  left: 8px;
  z-index: 10;
  padding: 0.2rem 0.6rem;
  background: rgba(239, 68, 68, 0.15);
  border: 1px solid rgba(239, 68, 68, 0.4);
  border-radius: var(--radius-sm);
  color: #f87171;
  font-size: 0.7rem;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.05em;
}

@media (max-width: 640px) {
  .projects-grid { grid-template-columns: 1fr; }
}
</style>
