import { ref, onMounted } from 'vue'
import { ApiService } from '../services/api.service'

export function useDataController() {
    const data = ref<any>(null)
    const loading = ref(true)
    const error = ref<any>(null)

    const fetchData = async () => {
        loading.value = true
        try {
            data.value = await ApiService.getData()
        } catch (e) {
            error.value = e
        } finally {
            loading.value = false
        }
    }

    onMounted(() => {
        fetchData()
    })

    return {
        data,
        loading,
        error,
        fetchData
    }
}
