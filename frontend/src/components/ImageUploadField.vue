<script setup lang="ts">
import { ref, watch } from 'vue'
import { ApiService, type ImageSearchResult } from '../services/api.service'

const props = defineProps<{ modelValue: string; label?: string; searchQuery?: string }>()
const emit = defineEmits<{ 'update:modelValue': [string] }>()

const uploading = ref(false)
const fileInput = ref<HTMLInputElement>()

async function onFile(e: Event) {
  const file = (e.target as HTMLInputElement).files?.[0]
  if (!file) return
  uploading.value = true
  try {
    const url = await ApiService.uploadImage(file)
    emit('update:modelValue', url)
  } catch {
    alert('Erreur lors de l\'upload')
  } finally {
    uploading.value = false
    if (fileInput.value) fileInput.value.value = ''
  }
}

// ── Recherche d'images en ligne ──────────────────────────────────────────────

const searchOpen = ref(false)
const searchInput = ref('')
const searching = ref(false)
const searchError = ref('')
const results = ref<ImageSearchResult[]>([])
const importingUrl = ref<string | null>(null)

watch(() => props.searchQuery, q => {
  if (!searchOpen.value && q) searchInput.value = `${q} png`
})

function toggleSearch() {
  searchOpen.value = !searchOpen.value
  if (searchOpen.value) {
    if (!searchInput.value && props.searchQuery) searchInput.value = `${props.searchQuery} png`
    if (searchInput.value && !results.value.length) search()
  }
}

async function search() {
  const q = searchInput.value.trim()
  if (!q || searching.value) return
  searching.value = true
  searchError.value = ''
  results.value = []
  try {
    results.value = await ApiService.searchImages(q)
    if (!results.value.length) searchError.value = 'Aucun résultat'
  } catch {
    searchError.value = 'Erreur lors de la recherche'
  } finally {
    searching.value = false
  }
}

async function pick(result: ImageSearchResult) {
  if (importingUrl.value) return
  importingUrl.value = result.image
  try {
    const url = await ApiService.importImage(result.image)
    emit('update:modelValue', url)
    searchOpen.value = false
  } catch {
    alert('Erreur lors du téléchargement de l\'image')
  } finally {
    importingUrl.value = null
  }
}
</script>

<template>
  <div class="img-field">
    <label class="field-label">{{ label ?? 'Image' }}</label>
    <div class="img-row">
      <input
        type="text"
        class="field-input"
        :value="modelValue"
        placeholder="/images/example.png"
        @input="emit('update:modelValue', ($event.target as HTMLInputElement).value)"
      />
      <label class="upload-btn" :class="{ loading: uploading }">
        <input ref="fileInput" type="file" accept="image/*" @change="onFile" style="display:none" />
        <svg v-if="!uploading" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/>
          <polyline points="17 8 12 3 7 8"/><line x1="12" y1="3" x2="12" y2="15"/>
        </svg>
        <svg v-else class="spin" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <path d="M21 12a9 9 0 1 1-6.219-8.56"/>
        </svg>
        {{ uploading ? '…' : 'Upload' }}
      </label>
      <button
        v-if="searchQuery !== undefined"
        type="button"
        class="upload-btn"
        :class="{ active: searchOpen }"
        @click="toggleSearch"
        title="Rechercher une image en ligne"
      >
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/>
        </svg>
        Web
      </button>
    </div>

    <div v-if="searchOpen" class="search-panel">
      <div class="img-row">
        <input
          type="text"
          class="field-input"
          v-model="searchInput"
          placeholder="ex: cpp png"
          @keydown.enter.prevent="search"
        />
        <button type="button" class="upload-btn" :class="{ loading: searching }" @click="search">
          {{ searching ? '…' : 'Rechercher' }}
        </button>
      </div>
      <p v-if="searchError" class="search-error">{{ searchError }}</p>
      <div v-if="results.length" class="search-grid">
        <button
          v-for="r in results"
          :key="r.image"
          type="button"
          class="search-item"
          :class="{ importing: importingUrl === r.image }"
          :title="r.title"
          @click="pick(r)"
        >
          <img :src="r.thumbnail" :alt="r.title" loading="lazy" />
          <svg v-if="importingUrl === r.image" class="spin item-spinner" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path d="M21 12a9 9 0 1 1-6.219-8.56"/>
          </svg>
        </button>
      </div>
    </div>

    <div v-if="modelValue" class="img-preview">
      <img :src="modelValue" alt="preview" @error="($event.target as HTMLImageElement).style.display='none'" />
    </div>
  </div>
</template>

<style scoped>
.img-field {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.img-row {
  display: flex;
  gap: 0.5rem;
}

.field-input {
  flex: 1;
  background: var(--bg);
  border: 1px solid var(--border);
  border-radius: var(--radius-sm);
  color: var(--text);
  font-size: 0.85rem;
  padding: 0.5rem 0.75rem;
}

.field-input:focus {
  outline: none;
  border-color: var(--primary);
}

.upload-btn {
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

.upload-btn:hover:not(.loading) {
  background: rgba(var(--primary-rgb), 0.2);
}

.upload-btn.loading {
  opacity: 0.7;
  cursor: default;
}

.upload-btn.active {
  background: rgba(var(--primary-rgb), 0.25);
}

.search-panel {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
  padding: 0.6rem;
  background: var(--bg);
  border: 1px solid var(--border);
  border-radius: var(--radius-sm);
}

.search-error {
  font-size: 0.8rem;
  color: var(--text-muted);
  margin: 0;
}

.search-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(64px, 1fr));
  gap: 0.5rem;
  max-height: 220px;
  overflow-y: auto;
}

.search-item {
  position: relative;
  display: flex;
  align-items: center;
  justify-content: center;
  aspect-ratio: 1;
  padding: 0.35rem;
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: var(--radius-sm);
  cursor: pointer;
  transition: var(--transition);
}

.search-item:hover {
  border-color: var(--primary);
}

.search-item.importing {
  opacity: 0.6;
}

.search-item img {
  max-width: 100%;
  max-height: 100%;
  object-fit: contain;
}

.item-spinner {
  position: absolute;
  color: var(--primary);
}

.img-preview {
  margin-top: 0.25rem;
  height: 60px;
  display: flex;
  align-items: center;
}

.img-preview img {
  max-height: 60px;
  max-width: 120px;
  object-fit: contain;
  border-radius: var(--radius-sm);
  border: 1px solid var(--border);
}

.field-label {
  font-size: 0.8rem;
  font-weight: 600;
  color: var(--text-muted);
  text-transform: uppercase;
  letter-spacing: 0.05em;
}

.spin {
  animation: spin 1s linear infinite;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}
</style>
