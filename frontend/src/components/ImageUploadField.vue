<script setup lang="ts">
import { ref } from 'vue'
import { ApiService } from '../services/api.service'

const props = defineProps<{ modelValue: string; label?: string }>()
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
  border: 1px solid rgba(59, 130, 246, 0.3);
  border-radius: var(--radius-sm);
  color: var(--primary);
  font-size: 0.82rem;
  font-weight: 600;
  cursor: pointer;
  white-space: nowrap;
  transition: var(--transition);
}

.upload-btn:hover:not(.loading) {
  background: rgba(59, 130, 246, 0.2);
}

.upload-btn.loading {
  opacity: 0.7;
  cursor: default;
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
