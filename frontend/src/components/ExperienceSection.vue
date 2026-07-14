<script setup lang="ts">
import { ref, reactive } from 'vue'
import { useAdmin } from '../composables/useAdmin'
import EditModal from './EditModal.vue'
import { ApiService } from '../services/api.service'

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

const props = defineProps<{ experiences: Experience[] }>()

const { adminMode } = useAdmin()
const saving = ref(false)
const localItems = ref<Experience[]>([...props.experiences])

type ModalMode = { type: 'add' } | { type: 'edit'; item: Experience } | null
const modal = ref<ModalMode>(null)
const form = reactive<any>({})

function openAdd() {
  Object.assign(form, { company: '', company_url: '', role: '', details: '', start_date: '', duration: '', status: 'En cours' })
  modal.value = { type: 'add' }
}

function openEdit(item: Experience) {
  Object.assign(form, { ...item })
  modal.value = { type: 'edit', item }
}

async function save() {
  if (!modal.value) return
  saving.value = true
  try {
    if (modal.value.type === 'add') {
      const created = await ApiService.createExperience({ ...form })
      localItems.value.unshift(created)
    } else {
      const id = modal.value.item.id
      await ApiService.updateExperience(id, { ...form })
      const idx = localItems.value.findIndex(i => i.id === id)
      if (idx !== -1) localItems.value[idx] = { ...form, id }
    }
    modal.value = null
  } catch {
    alert('Erreur lors de la sauvegarde')
  } finally {
    saving.value = false
  }
}

async function deleteItem() {
  if (!modal.value || modal.value.type !== 'edit') return
  saving.value = true
  try {
    const id = modal.value.item.id
    await ApiService.deleteExperience(id)
    localItems.value = localItems.value.filter(i => i.id !== id)
    modal.value = null
  } catch {
    alert('Erreur lors de la suppression')
  } finally {
    saving.value = false
  }
}
</script>

<template>
  <section v-reveal.stagger class="section" id="experiences">
    <div class="container">
      <div class="section-header">
        <h2 class="section-title">Expériences</h2>
        <div class="section-divider"></div>
        <button v-if="adminMode" class="btn-add" @click="openAdd">
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/>
          </svg>
          Ajouter
        </button>
      </div>

      <div class="timeline">
        <div v-for="exp in localItems" :key="exp.id" class="timeline-item stagger-item">
          <div class="timeline-dot" :class="exp.status !== 'Terminé' ? 'dot-active' : ''"></div>
          <div class="timeline-card card">
            <div class="timeline-header">
              <div>
                <a v-if="exp.company_url" :href="exp.company_url" class="company-name" target="_blank" rel="noopener noreferrer">{{ exp.company }}</a>
                <span v-else class="company-name">{{ exp.company }}</span>
                <p class="role">{{ exp.role }}</p>
              </div>
              <div class="status-block">
                <span :class="['tag', exp.status === 'Terminé' ? 'tag-success' : 'tag-warning']">
                  <svg v-if="exp.status === 'Terminé'" width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                    <polyline points="20 6 9 17 4 12"/>
                  </svg>
                  <svg v-else width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" class="spin">
                    <path d="M21 12a9 9 0 1 1-6.219-8.56"/>
                  </svg>
                  {{ exp.status }}
                </span>
                <span class="date">{{ exp.start_date }}</span>
                <span v-if="exp.duration" class="duration">{{ exp.duration }}</span>
                <button v-if="adminMode" class="item-edit-btn" @click="openEdit(exp)" title="Modifier">
                  <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/>
                    <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/>
                  </svg>
                </button>
              </div>
            </div>
            <p v-if="exp.details" class="timeline-details">{{ exp.details }}</p>
          </div>
        </div>
      </div>
    </div>
  </section>

  <EditModal
    v-if="modal"
    :title="modal?.type === 'add' ? 'Ajouter une expérience' : 'Modifier l\'expérience'"
    :saving="saving"
    :delete-label="modal?.type === 'edit' ? 'Supprimer' : undefined"
    @close="modal = null"
    @save="save"
    @delete="deleteItem"
  >
    <div class="form-grid">
      <div class="form-field">
        <label class="field-label">Entreprise</label>
        <input class="field-input" v-model="form.company" placeholder="ex: Orange" />
      </div>
      <div class="form-field">
        <label class="field-label">URL de l'entreprise</label>
        <input class="field-input" v-model="form.company_url" placeholder="https://…" />
      </div>
      <div class="form-field">
        <label class="field-label">Rôle</label>
        <input class="field-input" v-model="form.role" placeholder="ex: Apprenti technicien réseau" />
      </div>
      <div class="form-field">
        <label class="field-label">Détails</label>
        <textarea class="field-input field-textarea" v-model="form.details" rows="3"></textarea>
      </div>
      <div class="form-row">
        <div class="form-field">
          <label class="field-label">Période</label>
          <input class="field-input" v-model="form.start_date" placeholder="ex: 2023" />
        </div>
        <div class="form-field">
          <label class="field-label">Durée</label>
          <input class="field-input" v-model="form.duration" placeholder="ex: 2 mois" />
        </div>
      </div>
      <div class="form-field">
        <label class="field-label">Statut</label>
        <select class="field-input" v-model="form.status">
          <option value="En cours">En cours</option>
          <option value="Terminé">Terminé</option>
        </select>
      </div>
    </div>
  </EditModal>
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

.timeline {
  position: relative;
  padding-left: 2rem;
  max-width: 780px;
  margin: 0 auto;
}

.timeline::before {
  content: '';
  position: absolute;
  left: 0;
  top: 10px;
  bottom: 10px;
  width: 2px;
  background: linear-gradient(to bottom, var(--secondary), var(--accent), transparent);
  transform-origin: top;
  transition: transform 1.4s cubic-bezier(0.4, 0, 0.2, 1) 0.2s;
}

/* La ligne se dessine quand la section est révélée */
.section.reveal .timeline::before {
  transform: scaleY(0);
}

.section.reveal.visible .timeline::before {
  transform: scaleY(1);
}

.timeline-item {
  position: relative;
  padding-left: 2rem;
  padding-bottom: 2.5rem;
}

.timeline-item:last-child { padding-bottom: 0; }

.timeline-dot {
  position: absolute;
  left: -6px;
  top: 16px;
  width: 14px;
  height: 14px;
  border-radius: 50%;
  background: var(--grad-accent);
  border: 3px solid var(--bg);
  box-shadow: 0 0 12px rgba(var(--accent-rgb), 0.5);
  z-index: 1;
}

.dot-active { animation: dotPulse 2s ease-in-out infinite; }

@keyframes dotPulse {
  0%, 100% { box-shadow: 0 0 12px rgba(45, 212, 191, 0.5); }
  50% { box-shadow: 0 0 20px rgba(45, 212, 191, 0.9), 0 0 0 6px rgba(45, 212, 191, 0.1); }
}

.timeline-card { padding: 1.5rem; }

.timeline-header {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 1rem;
  margin-bottom: 0.75rem;
}

.company-name {
  font-size: 1.05rem;
  font-weight: 700;
  color: var(--text);
  text-decoration: none;
  transition: var(--transition);
  display: block;
  margin-bottom: 0.25rem;
}

.company-name:hover { color: var(--accent); }

.role {
  font-size: 0.9rem;
  color: var(--text-muted);
  margin: 0;
}

.status-block {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  gap: 0.4rem;
  flex-shrink: 0;
}

.date, .duration {
  font-size: 0.78rem;
  color: var(--text-dim);
  white-space: nowrap;
}

.timeline-details {
  font-size: 0.88rem;
  color: var(--text-muted);
  line-height: 1.65;
  margin: 0;
  border-top: 1px solid var(--border);
  padding-top: 0.75rem;
}

.item-edit-btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 26px;
  height: 26px;
  background: rgba(251, 191, 36, 0.1);
  border: 1px solid rgba(251, 191, 36, 0.25);
  border-radius: var(--radius-sm);
  color: #fbbf24;
  cursor: pointer;
  transition: var(--transition);
}

.item-edit-btn:hover { background: rgba(251, 191, 36, 0.2); }

.spin { animation: spin 1.5s linear infinite; }
@keyframes spin { to { transform: rotate(360deg); } }

.form-grid { display: flex; flex-direction: column; gap: 1rem; }
.form-row { display: grid; grid-template-columns: 1fr 1fr; gap: 0.75rem; }
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

@media (max-width: 640px) {
  .timeline-header { flex-direction: column; }
  .status-block { align-items: flex-start; }
  .form-row { grid-template-columns: 1fr; }
}
</style>
