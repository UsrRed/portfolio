<script setup lang="ts">
import { ref, reactive } from 'vue'
import { useAdmin } from '../composables/useAdmin'
import EditModal from './EditModal.vue'
import ImageUploadField from './ImageUploadField.vue'
import { ApiService } from '../services/api.service'

interface SoftSkill {
  id: number
  name: string
  image_url: string
}

const props = defineProps<{ softSkills: SoftSkill[] }>()

const { adminMode } = useAdmin()
const saving = ref(false)
const localItems = ref<SoftSkill[]>([...props.softSkills])

type ModalMode = { type: 'add' } | { type: 'edit'; item: SoftSkill } | null
const modal = ref<ModalMode>(null)
const form = reactive<any>({})

function openAdd() {
  Object.assign(form, { name: '', image_url: '' })
  modal.value = { type: 'add' }
}

function openEdit(item: SoftSkill) {
  Object.assign(form, { ...item })
  modal.value = { type: 'edit', item }
}

async function save() {
  if (!modal.value) return
  saving.value = true
  try {
    if (modal.value.type === 'add') {
      const created = await ApiService.createSoftSkill({ ...form })
      localItems.value.push(created)
    } else {
      const id = modal.value.item.id
      await ApiService.updateSoftSkill(id, { ...form })
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
    await ApiService.deleteSoftSkill(id)
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
  <section v-reveal class="section">
    <div class="container">
      <div class="section-header">
        <h2 class="section-title">Soft Skills</h2>
        <div class="section-divider"></div>
        <button v-if="adminMode" class="btn-add" @click="openAdd">
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/>
          </svg>
          Ajouter
        </button>
      </div>

      <div class="softskills-grid">
        <div v-for="skill in localItems" :key="skill.id" class="soft-card card">
          <div class="soft-img-wrap">
            <img :src="skill.image_url" :alt="skill.name" class="soft-img" />
          </div>
          <p class="soft-name">{{ skill.name }}</p>
          <button v-if="adminMode" class="item-edit-btn" @click="openEdit(skill)" title="Modifier">
            <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/>
              <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/>
            </svg>
          </button>
        </div>
      </div>
    </div>
  </section>

  <EditModal
    v-if="modal"
    :title="modal?.type === 'add' ? 'Ajouter un soft skill' : 'Modifier le soft skill'"
    :saving="saving"
    :delete-label="modal?.type === 'edit' ? 'Supprimer' : undefined"
    @close="modal = null"
    @save="save"
    @delete="deleteItem"
  >
    <div class="form-grid">
      <div class="form-field">
        <label class="field-label">Nom</label>
        <input class="field-input" v-model="form.name" placeholder="ex: Calme" />
      </div>
      <ImageUploadField v-model="form.image_url" label="Image" />
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

.softskills-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 1.25rem;
  max-width: 900px;
  margin: 0 auto;
}

.soft-card {
  display: flex;
  align-items: center;
  gap: 1.25rem;
  padding: 1.25rem 1.5rem;
  position: relative;
}

.soft-img-wrap {
  width: 56px;
  height: 56px;
  border-radius: 50%;
  background: linear-gradient(135deg, var(--primary-dim), rgba(56, 189, 248, 0.1));
  display: flex;
  align-items: center;
  justify-content: center;
  overflow: hidden;
  flex-shrink: 0;
  transition: var(--transition);
}

.soft-card:hover .soft-img-wrap {
  transform: scale(1.08);
  box-shadow: var(--glow);
}

.soft-img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.soft-name {
  font-size: 1rem;
  font-weight: 600;
  color: var(--text);
  margin: 0;
  flex: 1;
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
  flex-shrink: 0;
  transition: var(--transition);
}

.item-edit-btn:hover { background: rgba(251, 191, 36, 0.2); }

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
</style>
