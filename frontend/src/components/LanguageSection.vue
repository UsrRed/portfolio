<script setup lang="ts">
import { ref, reactive } from 'vue'
import { useAdmin } from '../composables/useAdmin'
import EditModal from './EditModal.vue'
import ImageUploadField from './ImageUploadField.vue'
import { ApiService } from '../services/api.service'

interface Language {
  id: number
  name: string
  image_url?: string
  level: string
  certification_url?: string
}

const props = defineProps<{ languages: Language[] }>()

const { adminMode } = useAdmin()
const saving = ref(false)
const localItems = ref<Language[]>([...props.languages])

// Upload du document de certification (PDF ou image)
const uploadingCert = ref(false)
const certInput = ref<HTMLInputElement>()

async function onCertFile(e: Event) {
  const file = (e.target as HTMLInputElement).files?.[0]
  if (!file) return
  uploadingCert.value = true
  try {
    form.certification_url = await ApiService.uploadImage(file)
  } catch {
    alert("Erreur lors de l'upload du document")
  } finally {
    uploadingCert.value = false
    if (certInput.value) certInput.value.value = ''
  }
}

type ModalMode = { type: 'add' } | { type: 'edit'; item: Language } | null
const modal = ref<ModalMode>(null)
const form = reactive<any>({})

function openAdd() {
  Object.assign(form, { name: '', level: '', image_url: '', certification_url: '' })
  modal.value = { type: 'add' }
}

function openEdit(item: Language) {
  Object.assign(form, { ...item })
  modal.value = { type: 'edit', item }
}

async function save() {
  if (!modal.value) return
  saving.value = true
  try {
    if (modal.value.type === 'add') {
      const created = await ApiService.createLanguage({ ...form })
      localItems.value.push(created)
    } else {
      const id = modal.value.item.id
      await ApiService.updateLanguage(id, { ...form })
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
    await ApiService.deleteLanguage(id)
    localItems.value = localItems.value.filter(i => i.id !== id)
    modal.value = null
  } catch {
    alert('Erreur lors de la suppression')
  } finally {
    saving.value = false
  }
}

const levelToPercent: Record<string, number> = {
  'Langue natale': 100,
  'Natif': 100,
  'C2': 95,
  'C1': 85,
  'B2': 72,
  'B1': 58,
  'Certification B1': 58,
  'A2': 40,
  'A1': 25,
  'Des notions': 20,
}

function getPercent(level: string): number {
  for (const [key, val] of Object.entries(levelToPercent)) {
    if (level.toLowerCase().includes(key.toLowerCase())) return val
  }
  return 50
}
</script>

<template>
  <section v-reveal.stagger class="section">
    <div class="container">
      <div class="section-header">
        <h2 class="section-title">Langues</h2>
        <div class="section-divider"></div>
        <button v-if="adminMode" class="btn-add" @click="openAdd">
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/>
          </svg>
          Ajouter
        </button>
      </div>

      <div class="langs-grid">
        <div v-for="lang in localItems" :key="lang.id" class="lang-card card stagger-item">
          <div class="lang-header">
            <img v-if="lang.image_url" :src="lang.image_url" :alt="'Drapeau ' + lang.name" class="lang-flag" width="44" height="32" loading="lazy" decoding="async" />
            <h3 class="lang-name">{{ lang.name }}</h3>
            <button v-if="adminMode" class="item-edit-btn" @click="openEdit(lang)" title="Modifier">
              <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/>
                <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/>
              </svg>
            </button>
          </div>
          <p class="lang-level">{{ lang.level }}</p>
          <div class="lang-bar-track">
            <div class="lang-bar-fill" :style="{ width: getPercent(lang.level) + '%' }"></div>
          </div>
          <a v-if="lang.certification_url" :href="lang.certification_url" class="lang-cert" target="_blank" rel="noopener noreferrer">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/>
            </svg>
            Voir la certification
          </a>
        </div>
      </div>
    </div>
  </section>

  <EditModal
    v-if="modal"
    :title="modal?.type === 'add' ? 'Ajouter une langue' : 'Modifier la langue'"
    :saving="saving"
    :delete-label="modal?.type === 'edit' ? 'Supprimer' : undefined"
    @close="modal = null"
    @save="save"
    @delete="deleteItem"
  >
    <div class="form-grid">
      <div class="form-field">
        <label class="field-label">Nom</label>
        <input class="field-input" v-model="form.name" placeholder="ex: Anglais" />
      </div>
      <div class="form-field">
        <label class="field-label">Niveau</label>
        <input class="field-input" v-model="form.level" placeholder="ex: B1, Langue natale, Des notions…" />
      </div>
      <div class="form-field">
        <label class="field-label">Certification (PDF ou lien)</label>
        <div class="cert-row">
          <input class="field-input cert-input" v-model="form.certification_url" placeholder="https://… ou upload d'un PDF" />
          <label class="cert-upload-btn" :class="{ loading: uploadingCert }">
            <input ref="certInput" type="file" accept="application/pdf,image/*" @change="onCertFile" style="display:none" />
            <svg v-if="!uploadingCert" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/>
              <polyline points="17 8 12 3 7 8"/><line x1="12" y1="3" x2="12" y2="15"/>
            </svg>
            <svg v-else class="spin" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <path d="M21 12a9 9 0 1 1-6.219-8.56"/>
            </svg>
            {{ uploadingCert ? '…' : 'Upload' }}
          </label>
        </div>
        <p class="cert-hint">Uploadez le document téléchargé (ex. certification Cambridge) : le lien sera rempli automatiquement.</p>
      </div>
      <ImageUploadField v-model="form.image_url" label="Drapeau / Image" :aspect="11 / 8" />
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

.langs-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
  gap: 1.25rem;
  max-width: 800px;
  margin: 0 auto;
}

.lang-card {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
  padding: 1.5rem;
}

.lang-header {
  display: flex;
  align-items: center;
  gap: 0.875rem;
}

.lang-flag {
  width: 44px;
  height: 32px;
  object-fit: cover;
  border-radius: 4px;
  border: 1px solid var(--border);
}

.lang-name {
  font-size: 1.1rem;
  font-weight: 700;
  color: var(--text);
  flex: 1;
}

.item-edit-btn {
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
  flex-shrink: 0;
  transition: var(--transition);
}

.item-edit-btn:hover { background: rgba(251, 191, 36, 0.2); }

.lang-level {
  font-size: 0.85rem;
  color: var(--text-muted);
  margin: 0;
}

.lang-bar-track {
  height: 5px;
  background: var(--border);
  border-radius: var(--radius-full);
  overflow: hidden;
}

.lang-bar-fill {
  height: 100%;
  background: var(--grad);
  border-radius: var(--radius-full);
  transform-origin: left;
  transition: transform 1.2s cubic-bezier(0.4, 0, 0.2, 1) 0.5s;
}

/* La barre se remplit quand la carte est révélée */
.lang-card.reveal .lang-bar-fill {
  transform: scaleX(0);
}

.lang-card.reveal.visible .lang-bar-fill {
  transform: scaleX(1);
}

.lang-cert {
  display: inline-flex;
  align-items: center;
  gap: 0.4rem;
  font-size: 0.82rem;
  font-weight: 600;
  color: var(--warning);
  text-decoration: none;
  transition: var(--transition);
}

.lang-cert:hover {
  color: var(--text);
  gap: 0.6rem;
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

.cert-row {
  display: flex;
  gap: 0.5rem;
}

.cert-input { flex: 1; }

.cert-upload-btn {
  display: inline-flex;
  align-items: center;
  gap: 0.35rem;
  padding: 0.5rem 0.875rem;
  background: var(--primary-dim);
  border: 1px solid rgba(var(--primary-rgb), 0.3);
  border-radius: var(--radius-sm);
  color: var(--primary);
  font-size: 0.82rem;
  font-weight: 600;
  cursor: pointer;
  white-space: nowrap;
  transition: var(--transition);
}

.cert-upload-btn:hover:not(.loading) {
  background: rgba(var(--primary-rgb), 0.2);
}

.cert-upload-btn.loading {
  opacity: 0.7;
  cursor: default;
}

.cert-hint {
  font-size: 0.75rem;
  color: var(--text-dim);
  margin: 0.35rem 0 0;
}

.spin { animation: spin 1s linear infinite; }

@keyframes spin {
  to { transform: rotate(360deg); }
}
</style>
