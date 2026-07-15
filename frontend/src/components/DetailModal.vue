<script setup lang="ts">
import { onMounted, onUnmounted } from 'vue'

defineProps<{ title?: string }>()

const emit = defineEmits<{ close: [] }>()

function onKeydown(e: KeyboardEvent) {
  if (e.key === 'Escape') emit('close')
}

// Bloque le scroll de la page tant que la popup est ouverte
onMounted(() => {
  window.addEventListener('keydown', onKeydown)
  document.body.style.overflow = 'hidden'
})

onUnmounted(() => {
  window.removeEventListener('keydown', onKeydown)
  document.body.style.overflow = ''
})
</script>

<template>
  <Teleport to="body">
    <div class="detail-overlay" @click.self="emit('close')">
      <div class="detail-card" role="dialog" aria-modal="true" :aria-label="title">
        <button class="detail-close" @click="emit('close')" aria-label="Fermer">
          <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/>
          </svg>
        </button>
        <div class="detail-body">
          <slot />
        </div>
      </div>
    </div>
  </Teleport>
</template>

<style scoped>
.detail-overlay {
  position: fixed;
  inset: 0;
  background: rgba(3, 8, 5, 0.82);
  -webkit-backdrop-filter: blur(5px); /* Safari */
  backdrop-filter: blur(5px);
  z-index: 1000;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 1rem;
  animation: overlayIn 0.25s ease both;
}

@keyframes overlayIn {
  from { opacity: 0; }
  to { opacity: 1; }
}

.detail-card {
  position: relative;
  background: var(--bg-elevated);
  border: 1px solid var(--border-glow);
  border-radius: var(--radius-lg);
  width: 100%;
  max-width: 620px;
  max-height: 88vh;
  display: flex;
  flex-direction: column;
  box-shadow: var(--shadow-lg), var(--glow);
  animation: cardIn 0.3s cubic-bezier(0.4, 0, 0.2, 1) both;
}

@keyframes cardIn {
  from { opacity: 0; transform: translateY(18px) scale(0.97); }
  to { opacity: 1; transform: translateY(0) scale(1); }
}

.detail-close {
  position: absolute;
  top: 0.75rem;
  right: 0.75rem;
  z-index: 2;
  display: flex;
  align-items: center;
  justify-content: center;
  width: 34px;
  height: 34px;
  background: rgba(3, 8, 5, 0.6);
  border: 1px solid var(--border);
  border-radius: var(--radius-full);
  color: var(--text-muted);
  cursor: pointer;
  transition: var(--transition);
}

.detail-close:hover {
  color: var(--text);
  border-color: var(--border-glow);
  background: rgba(3, 8, 5, 0.85);
}

.detail-body {
  overflow-y: auto;
  border-radius: inherit;
}

@media (prefers-reduced-motion: reduce) {
  .detail-overlay,
  .detail-card {
    animation: none;
  }
}
</style>
