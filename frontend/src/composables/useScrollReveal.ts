import { ref, onMounted } from 'vue'

export function useScrollReveal(threshold = 0.12) {
  const elementRef = ref<HTMLElement | null>(null)
  const isVisible = ref(false)

  onMounted(() => {
    const el = elementRef.value
    if (!el) {
      isVisible.value = true
      return
    }

    const observer = new IntersectionObserver(
      (entries) => {
        const entry = entries[0]
        if (entry && entry.isIntersecting) {
          isVisible.value = true
          observer.disconnect()
        }
      },
      { threshold }
    )
    observer.observe(el)
  })

  return { elementRef, isVisible }
}
