import { ref } from 'vue'

const isAdminAvailable = import.meta.env.VITE_ENABLE_ADMIN === 'true'
const adminMode = ref(false)

export function useAdmin() {
  return {
    isAdminAvailable,
    adminMode,
    toggleAdminMode: () => {
      adminMode.value = !adminMode.value
    },
  }
}
