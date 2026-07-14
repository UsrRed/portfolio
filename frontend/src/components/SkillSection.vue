<script setup lang="ts">
import { ref, reactive } from 'vue'
import { useAdmin } from '../composables/useAdmin'
import EditModal from './EditModal.vue'
import ImageUploadField from './ImageUploadField.vue'
import { ApiService } from '../services/api.service'

interface Skill {
  id: number
  domain_id: number
  name: string
  image_url: string
  details: string
}

interface Domain {
  id: number
  name: string
  skills: Skill[]
}

const props = defineProps<{ domains: Domain[] }>()

const { adminMode } = useAdmin()
const flipped = ref<number | null>(null)
const saving = ref(false)

const localDomains = ref<Domain[]>(props.domains.map(d => ({ ...d, skills: [...(d.skills ?? [])] })))

// ── Modal state ──────────────────────────────────────────────────────────────

type ModalMode =
  | { type: 'editDomain'; domain: Domain }
  | { type: 'addDomain' }
  | { type: 'editSkill'; skill: Skill }
  | { type: 'addSkill'; domainId: number }
  | null

const modal = ref<ModalMode>(null)
const form = reactive<any>({})

function openEditDomain(domain: Domain) {
  Object.assign(form, { name: domain.name })
  modal.value = { type: 'editDomain', domain }
}

function openAddDomain() {
  Object.assign(form, { name: '' })
  modal.value = { type: 'addDomain' }
}

function openEditSkill(skill: Skill) {
  Object.assign(form, { ...skill })
  modal.value = { type: 'editSkill', skill }
}

function openAddSkill(domainId: number) {
  Object.assign(form, { domain_id: domainId, name: '', image_url: '', details: '' })
  modal.value = { type: 'addSkill', domainId }
}

// ── Save handlers ────────────────────────────────────────────────────────────

async function save() {
  if (!modal.value) return
  saving.value = true
  try {
    const m = modal.value
    if (m.type === 'addDomain') {
      const created = await ApiService.createDomain({ name: form.name })
      localDomains.value.push({ ...created, skills: [] })
    } else if (m.type === 'editDomain') {
      await ApiService.updateDomain(m.domain.id, { name: form.name })
      const d = localDomains.value.find(d => d.id === m.domain.id)
      if (d) d.name = form.name
    } else if (m.type === 'addSkill') {
      const created = await ApiService.createSkill({ ...form })
      const d = localDomains.value.find(d => d.id === m.domainId)
      if (d) d.skills.push(created)
    } else if (m.type === 'editSkill') {
      await ApiService.updateSkill(m.skill.id, { ...form })
      const d = localDomains.value.find(d => d.id === form.domain_id)
      if (d) {
        const idx = d.skills.findIndex(s => s.id === m.skill.id)
        if (idx !== -1) d.skills[idx] = { ...form, id: m.skill.id }
      }
    }
    modal.value = null
  } catch {
    alert('Erreur lors de la sauvegarde')
  } finally {
    saving.value = false
  }
}

async function deleteItem() {
  if (!modal.value) return
  saving.value = true
  try {
    const m = modal.value
    if (m.type === 'editDomain') {
      await ApiService.deleteDomain(m.domain.id)
      const idx = localDomains.value.findIndex(d => d.id === m.domain.id)
      if (idx !== -1) localDomains.value.splice(idx, 1)
    } else if (m.type === 'editSkill') {
      await ApiService.deleteSkill(m.skill.id)
      for (const d of localDomains.value) {
        const idx = d.skills.findIndex(s => s.id === m.skill.id)
        if (idx !== -1) { d.skills.splice(idx, 1); break }
      }
    }
    modal.value = null
  } catch {
    alert('Erreur lors de la suppression')
  } finally {
    saving.value = false
  }
}

function toggle(id: number) {
  if (!adminMode.value) {
    flipped.value = flipped.value === id ? null : id
  }
}

function modalTitle(): string {
  if (!modal.value) return ''
  switch (modal.value.type) {
    case 'addDomain': return 'Ajouter un domaine'
    case 'editDomain': return 'Modifier le domaine'
    case 'addSkill': return 'Ajouter une compétence'
    case 'editSkill': return 'Modifier la compétence'
  }
}

function deleteLabel(): string | undefined {
  if (!modal.value) return undefined
  if (modal.value.type === 'editDomain') return 'Supprimer le domaine'
  if (modal.value.type === 'editSkill') return 'Supprimer'
  return undefined
}
</script>

<template>
  <section v-reveal.stagger class="section" id="competences">
    <div class="container">
      <div class="section-header">
        <h2 class="section-title">Compétences</h2>
        <div class="section-divider"></div>
        <button v-if="adminMode" class="btn-add" @click="openAddDomain">
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/>
          </svg>
          Domaine
        </button>
      </div>

      <div class="domains">
        <div v-for="domain in localDomains.filter(d => d.skills?.length || adminMode)" :key="domain.id" class="domain-block">
          <div class="domain-name-row">
            <h3 class="domain-name">{{ domain.name }}</h3>
            <div v-if="adminMode" class="domain-actions">
              <button class="icon-btn" @click="openAddSkill(domain.id)" title="Ajouter une compétence">
                <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/>
                </svg>
              </button>
              <button class="icon-btn" @click="openEditDomain(domain)" title="Modifier le domaine">
                <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/>
                  <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/>
                </svg>
              </button>
            </div>
          </div>
          <div class="skills-grid">
            <div
              v-for="skill in domain.skills"
              :key="skill.id"
              class="skill-card stagger-item"
              :class="{ flipped: !adminMode && flipped === skill.id }"
              role="button"
              tabindex="0"
              :aria-expanded="flipped === skill.id"
              @click="toggle(skill.id)"
              @keydown.enter.prevent="toggle(skill.id)"
              @keydown.space.prevent="toggle(skill.id)"
              :title="adminMode ? '' : (flipped === skill.id ? 'Cliquer pour fermer' : 'Cliquer pour voir les détails')"
            >
              <div class="skill-inner">
                <div class="skill-front">
                  <img
                    :src="skill.image_url"
                    :alt="'Logo ' + skill.name"
                    class="skill-img"
                    width="52"
                    height="52"
                    loading="lazy"
                    decoding="async"
                    @error="($event.target as HTMLImageElement).style.display='none'"
                  />
                  <p class="skill-name">{{ skill.name }}</p>
                  <button v-if="adminMode" class="skill-edit-btn" @click.stop="openEditSkill(skill)" title="Modifier">
                    <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                      <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/>
                      <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/>
                    </svg>
                  </button>
                </div>
                <div class="skill-back">
                  <p class="skill-details">{{ skill.details || 'Aucun détail disponible.' }}</p>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </section>

  <EditModal
    v-if="modal"
    :title="modalTitle()"
    :saving="saving"
    :delete-label="deleteLabel()"
    @close="modal = null"
    @save="save"
    @delete="deleteItem"
  >
    <div class="form-grid">
      <!-- Domain forms -->
      <template v-if="modal?.type === 'addDomain' || modal?.type === 'editDomain'">
        <div class="form-field">
          <label class="field-label">Nom du domaine</label>
          <input class="field-input" v-model="form.name" placeholder="ex: Compétences développement" />
        </div>
      </template>

      <!-- Skill forms -->
      <template v-else>
        <div class="form-field">
          <label class="field-label">Nom</label>
          <input class="field-input" v-model="form.name" placeholder="ex: Python" />
        </div>
        <div class="form-field">
          <label class="field-label">Domaine</label>
          <select class="field-input" v-model="form.domain_id">
            <option v-for="d in localDomains" :key="d.id" :value="d.id">{{ d.name }}</option>
          </select>
        </div>
        <div class="form-field">
          <label class="field-label">Détails</label>
          <textarea class="field-input field-textarea" v-model="form.details" rows="3" placeholder="Description de la compétence…"></textarea>
        </div>
        <ImageUploadField v-model="form.image_url" label="Image" :search-query="form.name" />
      </template>
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

.btn-add:hover {
  background: rgba(251, 191, 36, 0.18);
}

.domains {
  display: flex;
  flex-direction: column;
  gap: 3.5rem;
}

.domain-name-row {
  display: flex;
  align-items: center;
  gap: 1rem;
  margin-bottom: 1.5rem;
}

.domain-name {
  font-size: 1.1rem;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.08em;
  color: var(--text-muted);
  display: flex;
  align-items: center;
  gap: 0.75rem;
  flex: 1;
  margin: 0;
}

.domain-name::after {
  content: '';
  flex: 1;
  height: 1px;
  background: var(--border);
}

.domain-actions {
  display: flex;
  gap: 0.35rem;
  flex-shrink: 0;
}

.icon-btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 28px;
  height: 28px;
  background: rgba(251, 191, 36, 0.1);
  border: 1px solid rgba(251, 191, 36, 0.25);
  border-radius: var(--radius-sm);
  color: #fbbf24;
  cursor: pointer;
  transition: var(--transition);
}

.icon-btn:hover {
  background: rgba(251, 191, 36, 0.2);
}

.skills-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(140px, 1fr));
  gap: 1rem;
}

.skill-card {
  perspective: 1000px;
  cursor: pointer;
  height: 150px;
  position: relative;
}

.skill-inner {
  position: relative;
  width: 100%;
  height: 100%;
  transition: transform 0.55s cubic-bezier(0.4, 0, 0.2, 1);
  transform-style: preserve-3d;
}

.skill-card.flipped .skill-inner {
  transform: rotateY(180deg);
}

.skill-front,
.skill-back {
  position: absolute;
  inset: 0;
  border-radius: var(--radius);
  backface-visibility: hidden;
  -webkit-backface-visibility: hidden;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 0.6rem;
  background: var(--surface);
  border: 1px solid var(--border);
  transition: border-color 0.3s;
  padding: 0.75rem;
}

.skill-card:hover .skill-front,
.skill-card:hover .skill-back {
  border-color: var(--border-glow);
}

.skill-back {
  transform: rotateY(180deg);
  background: linear-gradient(135deg, rgba(var(--primary-rgb), 0.12), rgba(var(--accent-rgb), 0.06));
  border-color: rgba(var(--primary-rgb), 0.3);
  padding: 1rem;
}

.skill-img {
  width: 52px;
  height: 52px;
  object-fit: contain;
  transition: transform 0.3s;
}

.skill-card:hover .skill-img {
  transform: scale(1.08);
}

.skill-name {
  font-size: 0.8rem;
  font-weight: 600;
  color: var(--text-muted);
  text-align: center;
  margin: 0;
  line-height: 1.3;
}

.skill-details {
  font-size: 0.78rem;
  color: var(--text-muted);
  text-align: center;
  line-height: 1.5;
  margin: 0;
  overflow: hidden;
  display: -webkit-box;
  -webkit-line-clamp: 6;
  -webkit-box-orient: vertical;
}

.skill-edit-btn {
  position: absolute;
  top: 6px;
  right: 6px;
  width: 22px;
  height: 22px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: rgba(251, 191, 36, 0.15);
  border: 1px solid rgba(251, 191, 36, 0.3);
  border-radius: 4px;
  color: #fbbf24;
  cursor: pointer;
  opacity: 0;
  transition: opacity 0.2s;
  z-index: 2;
}

.skill-card:hover .skill-edit-btn {
  opacity: 1;
}

.form-grid {
  display: flex;
  flex-direction: column;
  gap: 1rem;
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
}

.field-input:focus {
  outline: none;
  border-color: var(--primary);
}

.field-textarea {
  resize: vertical;
  min-height: 70px;
}

@media (max-width: 768px) {
  .skills-grid {
    grid-template-columns: repeat(auto-fill, minmax(110px, 1fr));
  }
}
</style>
