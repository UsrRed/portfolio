<script setup lang="ts">
import { ref, onMounted, onUnmounted } from 'vue'
import { useAdmin } from '../composables/useAdmin'

defineProps<{ name: string }>()

const menuOpen = ref(false)
const scrolled = ref(false)
const progress = ref(0)
const activeSection = ref('#presentation')
const { isAdminAvailable, adminMode, toggleAdminMode } = useAdmin()

const links = [
  { href: '#presentation', label: 'Présentation' },
  { href: '#competences', label: 'Compétences' },
  { href: '#formations', label: 'Formations' },
  { href: '#experiences', label: 'Expériences' },
  { href: '#projets', label: 'Projets' },
]

function onScroll() {
  scrolled.value = window.scrollY > 40

  const doc = document.documentElement
  const max = doc.scrollHeight - window.innerHeight
  progress.value = max > 0 ? Math.min(window.scrollY / max, 1) : 0

  let current = links[0]!.href
  for (const link of links) {
    const el = document.querySelector<HTMLElement>(link.href)
    if (el && el.getBoundingClientRect().top <= window.innerHeight * 0.35) {
      current = link.href
    }
  }
  activeSection.value = current
}

function printCv() {
  menuOpen.value = false
  window.print()
}

onMounted(() => {
  window.addEventListener('scroll', onScroll, { passive: true })
  onScroll()
})
onUnmounted(() => window.removeEventListener('scroll', onScroll))
</script>

<template>
  <nav :class="['navbar', { 'navbar--scrolled': scrolled }]">
    <div class="scroll-progress" :style="{ transform: `scaleX(${progress})` }"></div>
    <div class="navbar-inner container">
      <a class="navbar-brand" href="#presentation">
        <span class="brand-mark">{{ name.split(' ').map(w => w[0]).join('').slice(0, 2) }}</span>
        <span class="brand-name">{{ name }}</span>
      </a>

      <button
        class="hamburger"
        :class="{ open: menuOpen }"
        @click="menuOpen = !menuOpen"
        aria-label="Menu"
        :aria-expanded="menuOpen"
      >
        <span></span>
        <span></span>
        <span></span>
      </button>

      <ul class="navbar-links" :class="{ open: menuOpen }">
        <li v-for="(link, i) in links" :key="link.href">
          <a
            :href="link.href"
            :class="{ active: activeSection === link.href }"
            @click="menuOpen = false"
          ><span class="link-num">0{{ i }}.</span>{{ link.label }}</a>
        </li>
        <li>
          <button class="cv-btn" @click="printCv" title="Enregistrer le CV en PDF (Ctrl+P)">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/>
              <polyline points="7 10 12 15 17 10"/>
              <line x1="12" y1="15" x2="12" y2="3"/>
            </svg>
            CV (PDF)
          </button>
        </li>
        <li v-if="isAdminAvailable">
          <button
            class="admin-toggle"
            :class="{ active: adminMode }"
            @click="toggleAdminMode"
            :title="adminMode ? 'Quitter le mode admin' : 'Mode admin'"
          >
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <path d="M12 20h9"/><path d="M16.5 3.5a2.121 2.121 0 0 1 3 3L7 19l-4 1 1-4L16.5 3.5z"/>
            </svg>
            Admin
          </button>
        </li>
      </ul>
    </div>
  </nav>
</template>

<style scoped>
.navbar {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  z-index: 100;
  transition: all 0.3s ease;
  padding: 1.1rem 0;
}

.navbar--scrolled {
  background: rgba(6, 10, 8, 0.88);
  backdrop-filter: blur(20px);
  border-bottom: 1px solid var(--border);
  padding: 0.7rem 0;
  box-shadow: 0 4px 30px rgba(3, 8, 5, 0.45);
}

.scroll-progress {
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  height: 2px;
  background: var(--grad-accent);
  transform-origin: left;
  transform: scaleX(0);
  transition: transform 0.1s linear;
}

.navbar-inner {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.navbar-brand {
  display: flex;
  align-items: center;
  gap: 0.65rem;
  font-family: var(--font-display);
  font-weight: 700;
  font-size: 1rem;
  color: var(--text);
  text-decoration: none;
  letter-spacing: -0.01em;
}

.brand-mark {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 32px;
  height: 32px;
  border-radius: var(--radius-sm);
  background: var(--grad);
  color: #04140d;
  font-family: var(--font-mono);
  font-size: 0.78rem;
  font-weight: 700;
  letter-spacing: 0.02em;
  box-shadow: 0 2px 12px rgba(var(--primary-rgb), 0.35);
}

.navbar-links {
  display: flex;
  align-items: center;
  gap: 0.25rem;
  list-style: none;
}

.navbar-links a {
  display: block;
  position: relative;
  padding: 0.5rem 0.8rem;
  color: var(--text-muted);
  text-decoration: none;
  font-size: 0.88rem;
  font-weight: 500;
  border-radius: var(--radius-sm);
  transition: var(--transition);
}

.link-num {
  font-family: var(--font-mono);
  font-size: 0.72rem;
  font-weight: 500;
  color: var(--primary);
  margin-right: 0.4rem;
}

.navbar-links a::after {
  content: '';
  position: absolute;
  left: 0.8rem;
  bottom: 2px;
  width: calc(100% - 1.6rem);
  height: 2px;
  border-radius: var(--radius-full);
  background: var(--primary);
  transform: scaleX(0);
  transform-origin: left;
  transition: transform 0.3s cubic-bezier(0.4, 0, 0.2, 1);
}

.navbar-links a:hover {
  color: var(--text);
  background: var(--surface);
}

.navbar-links a.active {
  color: var(--text);
}

.navbar-links a.active::after {
  transform: scaleX(1);
}

.cv-btn {
  display: inline-flex;
  align-items: center;
  gap: 0.45rem;
  padding: 0.48rem 1.05rem;
  margin-left: 0.5rem;
  background: var(--primary);
  border: none;
  border-radius: var(--radius-sm);
  color: #04140d;
  font-size: 0.84rem;
  font-weight: 600;
  font-family: inherit;
  cursor: pointer;
  transition: var(--transition);
  box-shadow: 0 2px 12px rgba(var(--primary-rgb), 0.3);
}

.cv-btn:hover {
  background: var(--secondary);
  transform: translateY(-1px);
}

.admin-toggle {
  display: inline-flex;
  align-items: center;
  gap: 0.35rem;
  padding: 0.45rem 0.875rem;
  margin-left: 0.25rem;
  background: none;
  border: 1px solid rgba(251, 191, 36, 0.3);
  border-radius: var(--radius-sm);
  color: var(--text-muted);
  font-size: 0.82rem;
  font-weight: 600;
  cursor: pointer;
  transition: var(--transition);
}

.admin-toggle:hover {
  border-color: var(--warning);
  color: var(--warning);
  background: rgba(251, 191, 36, 0.08);
}

.admin-toggle.active {
  background: rgba(251, 191, 36, 0.12);
  border-color: var(--warning);
  color: var(--warning);
}

.hamburger {
  display: none;
  flex-direction: column;
  gap: 5px;
  background: none;
  border: none;
  cursor: pointer;
  padding: 4px;
}

.hamburger span {
  display: block;
  width: 24px;
  height: 2px;
  background: var(--text);
  border-radius: 2px;
  transition: var(--transition);
}

.hamburger.open span:nth-child(1) {
  transform: translateY(7px) rotate(45deg);
}
.hamburger.open span:nth-child(2) {
  opacity: 0;
}
.hamburger.open span:nth-child(3) {
  transform: translateY(-7px) rotate(-45deg);
}

@media (max-width: 900px) {
  .brand-name {
    display: none;
  }
}

@media (max-width: 768px) {
  .brand-name {
    display: inline;
  }

  .hamburger {
    display: flex;
  }

  .navbar-links {
    display: none;
    position: absolute;
    top: 100%;
    left: 0;
    right: 0;
    flex-direction: column;
    align-items: stretch;
    background: rgba(10, 17, 13, 0.97);
    backdrop-filter: blur(20px);
    border-bottom: 1px solid var(--border);
    padding: 1rem 1.5rem;
    gap: 0.25rem;
  }

  .navbar-links.open {
    display: flex;
  }

  .navbar-links a {
    padding: 0.75rem 1rem;
    font-size: 1rem;
  }

  .cv-btn,
  .admin-toggle {
    width: 100%;
    justify-content: center;
    margin: 0.25rem 0 0;
  }
}
</style>
