<script setup lang="ts">
import { ref, reactive, onMounted, onUnmounted } from 'vue'
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

function printCv() {
  window.print()
}

// ── Effet machine à écrire sur le titre ──────────────────────────────────────

const typedTitle = ref('')
const typingDone = ref(false)
let typingTimer: ReturnType<typeof setInterval> | undefined

onMounted(() => {
  const full = props.person.title ?? ''
  if (!full || window.matchMedia('(prefers-reduced-motion: reduce)').matches) {
    typedTitle.value = full
    typingDone.value = true
    return
  }
  let i = 0
  typingTimer = setInterval(() => {
    i++
    typedTitle.value = full.slice(0, i)
    if (i >= full.length) {
      clearInterval(typingTimer)
      typingDone.value = true
    }
  }, 45)
})

onUnmounted(() => clearInterval(typingTimer))

// ── Tilt 3D du portrait au survol ────────────────────────────────────────────

const tilt = reactive({ x: 0, y: 0 })

function onPortraitMove(e: MouseEvent) {
  if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) return
  const rect = (e.currentTarget as HTMLElement).getBoundingClientRect()
  tilt.x = ((e.clientY - rect.top) / rect.height - 0.5) * -8
  tilt.y = ((e.clientX - rect.left) / rect.width - 0.5) * 8
}

function resetTilt() {
  tilt.x = 0
  tilt.y = 0
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
    <div class="hero-bg">
      <div class="hero-grid"></div>
      <div class="hero-glow"></div>
    </div>

    <div class="hero-content container">
      <div class="hero-text">
        <p class="hero-eyebrow">
          <span class="eyebrow-dot"></span>
          <span class="eyebrow-prompt">~$</span> whoami
        </p>

        <h1 class="hero-name">
          {{ person.first_name }}
          <span class="gradient-text">{{ person.last_name }}</span>
        </h1>

        <p v-if="person.title" class="hero-title">
          {{ typedTitle }}<span class="caret" :class="{ done: typingDone }"></span>
        </p>

        <p class="hero-description">{{ person.description }}</p>

        <div class="hero-facts">
          <span v-if="person.location" class="fact">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"/>
              <circle cx="12" cy="10" r="3"/>
            </svg>
            {{ person.location }}
          </span>
          <span v-if="person.driver_license" class="fact">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <rect x="1" y="3" width="15" height="13" rx="2"/>
              <path d="m16 8 2 2 4-4M22 16l-1.5-6H1.5L0 16"/>
              <circle cx="5.5" cy="18.5" r="2.5"/>
              <circle cx="18.5" cy="18.5" r="2.5"/>
            </svg>
            {{ person.driver_license }}
          </span>
          <span v-if="person.birth_date" class="fact">
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
          <a v-if="person.linkedin_url" :href="person.linkedin_url" class="btn btn-primary" target="_blank" rel="noopener noreferrer">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor">
              <path d="M16 8a6 6 0 0 1 6 6v7h-4v-7a2 2 0 0 0-2-2 2 2 0 0 0-2 2v7h-4v-7a6 6 0 0 1 6-6zM2 9h4v12H2z"/>
              <circle cx="4" cy="4" r="2"/>
            </svg>
            Me contacter
          </a>
          <button class="btn btn-outline" @click="printCv" title="Enregistrer le CV en PDF (Ctrl+P)">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/>
              <polyline points="7 10 12 15 17 10"/>
              <line x1="12" y1="15" x2="12" y2="3"/>
            </svg>
            Télécharger le CV
          </button>
          <a href="#competences" class="btn btn-ghost">
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

      <div class="hero-portrait" @mousemove="onPortraitMove" @mouseleave="resetTilt">
        <div
          class="portrait-frame"
          :style="{ transform: `perspective(900px) rotateX(${tilt.x}deg) rotateY(${tilt.y}deg)` }"
        >
          <div class="portrait-bar" aria-hidden="true">
            <span class="bar-dot bar-dot--red"></span>
            <span class="bar-dot bar-dot--yellow"></span>
            <span class="bar-dot bar-dot--green"></span>
            <span class="bar-file">{{ person.first_name.toLowerCase() }}.jpg</span>
          </div>
          <img
            :src="person.image_url"
            :alt="'Portrait de ' + person.first_name + ' ' + person.last_name"
            class="portrait-img"
            width="320"
            height="400"
            fetchpriority="high"
            decoding="async"
          />
        </div>
        <div class="portrait-accent"></div>
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
  justify-content: center;
  position: relative;
  overflow: hidden;
  padding: 8rem 0 5rem;
}

.hero-bg {
  position: absolute;
  inset: 0;
  pointer-events: none;
}

.hero-grid {
  position: absolute;
  inset: 0;
  background-image:
    linear-gradient(rgba(148, 184, 163, 0.05) 1px, transparent 1px),
    linear-gradient(90deg, rgba(148, 184, 163, 0.05) 1px, transparent 1px);
  background-size: 56px 56px;
  mask-image: radial-gradient(ellipse 90% 70% at 50% 30%, black 30%, transparent 75%);
  -webkit-mask-image: radial-gradient(ellipse 90% 70% at 50% 30%, black 30%, transparent 75%);
}

.hero-glow {
  position: absolute;
  width: 800px;
  height: 500px;
  top: -180px;
  right: -160px;
  background: radial-gradient(ellipse, rgba(5, 150, 105, 0.16), transparent 65%);
  filter: blur(20px);
  animation: glowDrift 14s ease-in-out infinite alternate;
}

@keyframes glowDrift {
  from { transform: translate3d(0, 0, 0) scale(1); }
  to { transform: translate3d(-70px, 50px, 0) scale(1.12); }
}

/* Entrée en cascade des éléments du hero */
@keyframes heroIn {
  from { opacity: 0; transform: translateY(26px); }
  to { opacity: 1; transform: translateY(0); }
}

.hero-eyebrow { animation: heroIn 0.7s cubic-bezier(0.4, 0, 0.2, 1) 0.05s both; }
.hero-name { animation: heroIn 0.7s cubic-bezier(0.4, 0, 0.2, 1) 0.15s both; }
.hero-title { animation: heroIn 0.7s cubic-bezier(0.4, 0, 0.2, 1) 0.28s both; }
.hero-description { animation: heroIn 0.7s cubic-bezier(0.4, 0, 0.2, 1) 0.4s both; }
.hero-facts { animation: heroIn 0.7s cubic-bezier(0.4, 0, 0.2, 1) 0.52s both; }
.hero-actions { animation: heroIn 0.7s cubic-bezier(0.4, 0, 0.2, 1) 0.64s both; }
.hero-scroll { animation: heroIn 0.7s cubic-bezier(0.4, 0, 0.2, 1) 1s both; }

@keyframes portraitIn {
  from { opacity: 0; transform: scale(0.93) translateY(24px); }
  to { opacity: 1; transform: scale(1) translateY(0); }
}

.hero-portrait { animation: portraitIn 0.9s cubic-bezier(0.4, 0, 0.2, 1) 0.3s both; }

.hero-content {
  display: grid;
  grid-template-columns: minmax(0, 1.5fr) minmax(0, 1fr);
  align-items: center;
  gap: 4rem;
  position: relative;
  z-index: 1;
}

.hero-eyebrow {
  display: inline-flex;
  align-items: center;
  gap: 0.6rem;
  font-family: var(--font-mono);
  font-size: 0.82rem;
  font-weight: 500;
  color: var(--text-muted);
  letter-spacing: 0.02em;
  padding: 0.4rem 0.95rem;
  border: 1px solid var(--border);
  border-radius: var(--radius-sm);
  background: var(--surface);
  margin-bottom: 1.75rem;
}

.eyebrow-prompt {
  color: var(--primary);
  font-weight: 600;
}

.eyebrow-dot {
  width: 7px;
  height: 7px;
  border-radius: 50%;
  background: var(--success);
  box-shadow: 0 0 8px rgba(52, 211, 153, 0.7);
  animation: pulse 2.5s ease-in-out infinite;
}

.hero-name {
  font-size: clamp(2.6rem, 6.5vw, 4.5rem);
  font-weight: 700;
  line-height: 1.05;
  letter-spacing: -0.035em;
  color: var(--text);
}

.hero-name .gradient-text {
  display: block;
}

.hero-title {
  font-family: var(--font-mono);
  font-size: 1.05rem;
  color: var(--secondary);
  font-weight: 500;
  margin-top: 1rem;
  min-height: 1.75em;
}

.caret {
  display: inline-block;
  width: 2px;
  height: 1.1em;
  margin-left: 3px;
  background: var(--secondary);
  vertical-align: text-bottom;
  animation: caretBlink 0.9s step-end infinite;
}

.caret.done {
  animation: none;
  opacity: 0;
  transition: opacity 0.4s ease 0.9s;
}

@keyframes caretBlink {
  0%, 100% { opacity: 1; }
  50% { opacity: 0; }
}

.hero-description {
  max-width: 560px;
  color: var(--text-muted);
  font-size: 1.02rem;
  line-height: 1.75;
  margin-top: 1.25rem;
}

.hero-facts {
  display: flex;
  flex-wrap: wrap;
  gap: 1.35rem;
  margin-top: 1.75rem;
  padding-top: 1.5rem;
  border-top: 1px solid var(--border);
  max-width: 560px;
}

.fact {
  display: inline-flex;
  align-items: center;
  gap: 0.45rem;
  font-size: 0.86rem;
  font-weight: 500;
  color: var(--text-muted);
}

.fact svg {
  color: var(--primary);
  flex-shrink: 0;
}

.hero-actions {
  display: flex;
  gap: 0.85rem;
  flex-wrap: wrap;
  margin-top: 2.25rem;
}

.btn-admin {
  display: inline-flex;
  align-items: center;
  gap: 0.4rem;
  padding: 0.55rem 1.1rem;
  background: rgba(251, 191, 36, 0.1);
  border: 1px solid rgba(251, 191, 36, 0.3);
  border-radius: 10px;
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

.hero-portrait {
  position: relative;
  justify-self: center;
}

.portrait-frame {
  position: relative;
  display: flex;
  flex-direction: column;
  width: min(320px, 70vw);
  border-radius: var(--radius-lg);
  overflow: hidden;
  border: 1px solid var(--border);
  background: var(--bg-elevated);
  box-shadow: var(--shadow-lg);
  z-index: 1;
  transition: transform 0.25s ease-out;
  will-change: transform;
}

/* Barre de fenêtre façon terminal */
.portrait-bar {
  display: flex;
  align-items: center;
  gap: 0.45rem;
  padding: 0.6rem 0.9rem;
  background: rgba(148, 184, 163, 0.06);
  border-bottom: 1px solid var(--border);
}

.bar-dot {
  width: 10px;
  height: 10px;
  border-radius: 50%;
}

.bar-dot--red { background: #f87171; }
.bar-dot--yellow { background: #fbbf24; }
.bar-dot--green { background: #34d399; }

.bar-file {
  margin-left: auto;
  font-family: var(--font-mono);
  font-size: 0.68rem;
  color: var(--text-dim);
}

.portrait-img {
  width: 100%;
  height: auto;
  aspect-ratio: 4 / 5;
  object-fit: cover;
  display: block;
}

.portrait-accent {
  position: absolute;
  inset: 1.25rem -1.25rem -1.25rem 1.25rem;
  border: 1px solid rgba(var(--primary-rgb), 0.35);
  border-radius: var(--radius-lg);
  z-index: 0;
  animation: accentFloat 6s ease-in-out infinite;
}

@keyframes accentFloat {
  0%, 100% { transform: translate(0, 0); }
  50% { transform: translate(6px, -8px); }
}

.hero-scroll {
  position: absolute;
  bottom: 2rem;
  left: 50%;
  transform: translateX(-50%);
}

.scroll-indicator {
  width: 22px;
  height: 38px;
  border: 2px solid var(--border);
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

@media (max-width: 900px) {
  .hero-content {
    grid-template-columns: 1fr;
    gap: 3rem;
    text-align: center;
  }

  .hero-portrait {
    order: -1;
  }

  .portrait-frame {
    width: min(220px, 60vw);
  }

  .portrait-accent {
    inset: 1rem -1rem -1rem 1rem;
  }

  .hero-description,
  .hero-facts {
    margin-left: auto;
    margin-right: auto;
  }

  .hero-facts {
    justify-content: center;
  }

  .hero-actions {
    justify-content: center;
  }
}

@media (max-width: 640px) {
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
