import type { Directive } from 'vue'

export const vReveal: Directive<HTMLElement> = {
  mounted(el) {
    el.classList.add('reveal')
    const observer = new IntersectionObserver(
      (entries) => {
        const entry = entries[0]
        if (entry && entry.isIntersecting) {
          el.classList.add('visible')
          observer.disconnect()
        }
      },
      { threshold: 0.1 }
    )
    observer.observe(el)
  },
}
