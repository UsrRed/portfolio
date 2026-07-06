import type { Directive } from 'vue'

const REVEAL_DURATION = 700
const STAGGER_STEP = 80

function prefersReducedMotion(): boolean {
  return window.matchMedia('(prefers-reduced-motion: reduce)').matches
}

/**
 * v-reveal          → révèle l'élément à l'entrée dans le viewport
 * v-reveal.stagger  → révèle aussi ses descendants `.stagger-item` en cascade
 *
 * Les classes et delays sont retirés une fois l'animation terminée pour ne
 * pas retarder les transitions de hover (les cartes transitionnent `all`).
 */
export const vReveal: Directive<HTMLElement> = {
  mounted(el, binding) {
    if (prefersReducedMotion()) return

    const items = binding.modifiers.stagger
      ? Array.from(el.querySelectorAll<HTMLElement>('.stagger-item'))
      : []

    el.classList.add('reveal')
    items.forEach((item, i) => {
      item.classList.add('reveal')
      item.style.setProperty('--reveal-delay', `${(i + 1) * STAGGER_STEP}ms`)
    })

    const observer = new IntersectionObserver(
      (entries) => {
        const entry = entries[0]
        if (!entry || !entry.isIntersecting) return
        observer.disconnect()

        el.classList.add('visible')
        items.forEach((item) => item.classList.add('visible'))

        const total = REVEAL_DURATION + items.length * STAGGER_STEP
        setTimeout(() => {
          for (const node of [el, ...items]) {
            node.classList.remove('reveal', 'visible')
            node.style.removeProperty('--reveal-delay')
          }
        }, total)
      },
      { threshold: 0.1, rootMargin: '0px 0px -40px 0px' }
    )
    observer.observe(el)
  },
}
