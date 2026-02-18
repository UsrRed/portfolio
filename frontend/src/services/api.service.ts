export class ApiService {
    private static baseUrl = '/api'

    static async getData(): Promise<any> {
        try {
            const response = await fetch(`${this.baseUrl}/get-data`)
            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`)
            }
            return await response.json()
        } catch (error) {
            console.error('Error fetching data:', error)
            throw error
        }
    }
}
