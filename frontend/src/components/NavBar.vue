<script setup lang="ts">
import { ref, onMounted, onUnmounted } from 'vue'
import { useAdmin } from '../composables/useAdmin'

defineProps<{ name: string }>()

const menuOpen = ref(false)
const scrolled = ref(false)
const { isAdminAvailable, adminMode, toggleAdminMode } = useAdmin()

function onScroll() {
  scrolled.value = window.scrollY > 40
}

onMounted(() => window.addEventListener('scroll', onScroll))
onUnmounted(() => window.removeEventListener('scroll', onScroll))

const links = [
  { href: '#presentation', label: 'Présentation' },
  { href: '#competences', label: 'Compétences' },
  { href: '#formations', label: 'Formations' },
  { href: '#experiences', label: 'Expériences' },
  { href: '#projets', label: 'Projets' },
]
</script>

<template>
  <nav :class="['navbar', { 'navbar--scrolled': scrolled }]">
    <div class="navbar-inner container">
      <a class="navbar-brand" href="#presentation">
        <span class="brand-dot"></span>
        {{ name }}
      </a>

      <button
        class="hamburger"
        :class="{ open: menuOpen }"
        @click="menuOpen = !menuOpen"
        aria-label="Menu"
      >
        <span></span>
        <span></span>
        <span></span>
      </button>

      <ul class="navbar-links" :class="{ open: menuOpen }">
        <li v-for="link in links" :key="link.href">
          <a :href="link.href" @click="menuOpen = false">{{ link.label }}</a>
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
  padding: 1.25rem 0;
}

.navbar--scrolled {
  background: rgba(7, 7, 26, 0.85);
  backdrop-filter: blur(20px);
  border-bottom: 1px solid rgba(255, 255, 255, 0.06);
  padding: 0.75rem 0;
  box-shadow: 0 4px 30px rgba(0, 0, 0, 0.4);
}

.navbar-inner {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.navbar-brand {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  font-weight: 800;
  font-size: 1.1rem;
  color: var(--text);
  text-decoration: none;
  letter-spacing: -0.02em;
}

.brand-dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: var(--grad);
  box-shadow: 0 0 10px rgba(99, 102, 241, 0.6);
}

.navbar-links {
  display: flex;
  align-items: center;
  gap: 0.25rem;
  list-style: none;
}

.navbar-links a {
  display: block;
  padding: 0.5rem 0.875rem;
  color: var(--text-muted);
  text-decoration: none;
  font-size: 0.9rem;
  font-weight: 500;
  border-radius: var(--radius-full);
  transition: var(--transition);
}

.navbar-links a:hover {
  color: var(--text);
  background: var(--surface);
}

.admin-toggle {
  display: inline-flex;
  align-items: center;
  gap: 0.35rem;
  padding: 0.4rem 0.875rem;
  background: none;
  border: 1px solid rgba(99, 102, 241, 0.3);
  border-radius: var(--radius-full);
  color: var(--text-muted);
  font-size: 0.82rem;
  font-weight: 600;
  cursor: pointer;
  transition: var(--transition);
}

.admin-toggle:hover {
  border-color: var(--primary);
  color: var(--primary);
  background: var(--primary-dim);
}

.admin-toggle.active {
  background: var(--primary-dim);
  border-color: var(--primary);
  color: var(--primary);
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

@media (max-width: 768px) {
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
    background: rgba(13, 13, 36, 0.97);
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
}
</style>
