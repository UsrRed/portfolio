export interface ProjectPayload {
  title: string
  image_url: string
  period: string
  description: string
  skills_human: string
  skills_tech: string
  link_url: string
  hidden?: boolean
}

export interface ImageSearchResult {
  image: string
  thumbnail: string
  title: string
}

export class ApiService {
  private static baseUrl = '/api'

  static async getData(): Promise<any> {
    const response = await fetch(`${this.baseUrl}/get-data`)
    if (!response.ok) throw new Error(`HTTP ${response.status}`)
    return response.json()
  }

  // ── Image upload ──────────────────────────────────────────────────────────

  static async uploadImage(file: File): Promise<string> {
    const form = new FormData()
    form.append('image', file)
    const response = await fetch(`${this.baseUrl}/upload`, { method: 'POST', body: form })
    if (!response.ok) throw new Error(`HTTP ${response.status}`)
    const data = await response.json()
    return data.url
  }

  // ── Image search ──────────────────────────────────────────────────────────

  static async searchImages(query: string): Promise<ImageSearchResult[]> {
    const response = await fetch(`${this.baseUrl}/image-search?q=${encodeURIComponent(query)}`)
    if (!response.ok) throw new Error(`HTTP ${response.status}`)
    const data = await response.json()
    return data.results ?? []
  }

  static async importImage(url: string): Promise<string> {
    const response = await fetch(`${this.baseUrl}/image-import`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ url }),
    })
    if (!response.ok) throw new Error(`HTTP ${response.status}`)
    const data = await response.json()
    return data.url
  }

  // ── Person ────────────────────────────────────────────────────────────────

  static async updatePerson(payload: any): Promise<any> {
    const response = await fetch(`${this.baseUrl}/person`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
    })
    if (!response.ok) throw new Error(`HTTP ${response.status}`)
    return response.json()
  }

  // ── Domains ───────────────────────────────────────────────────────────────

  static async createDomain(payload: { name: string }): Promise<any> {
    const response = await fetch(`${this.baseUrl}/domains`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
    })
    if (!response.ok) throw new Error(`HTTP ${response.status}`)
    return response.json()
  }

  static async updateDomain(id: number, payload: { name: string }): Promise<any> {
    const response = await fetch(`${this.baseUrl}/domains/${id}`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
    })
    if (!response.ok) throw new Error(`HTTP ${response.status}`)
    return response.json()
  }

  static async deleteDomain(id: number): Promise<void> {
    const response = await fetch(`${this.baseUrl}/domains/${id}`, { method: 'DELETE' })
    if (!response.ok) throw new Error(`HTTP ${response.status}`)
  }

  // ── Skills ────────────────────────────────────────────────────────────────

  static async createSkill(payload: any): Promise<any> {
    const response = await fetch(`${this.baseUrl}/skills`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
    })
    if (!response.ok) throw new Error(`HTTP ${response.status}`)
    return response.json()
  }

  static async updateSkill(id: number, payload: any): Promise<any> {
    const response = await fetch(`${this.baseUrl}/skills/${id}`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
    })
    if (!response.ok) throw new Error(`HTTP ${response.status}`)
    return response.json()
  }

  static async deleteSkill(id: number): Promise<void> {
    const response = await fetch(`${this.baseUrl}/skills/${id}`, { method: 'DELETE' })
    if (!response.ok) throw new Error(`HTTP ${response.status}`)
  }

  // ── Languages ─────────────────────────────────────────────────────────────

  static async createLanguage(payload: any): Promise<any> {
    const response = await fetch(`${this.baseUrl}/languages`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
    })
    if (!response.ok) throw new Error(`HTTP ${response.status}`)
    return response.json()
  }

  static async updateLanguage(id: number, payload: any): Promise<any> {
    const response = await fetch(`${this.baseUrl}/languages/${id}`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
    })
    if (!response.ok) throw new Error(`HTTP ${response.status}`)
    return response.json()
  }

  static async deleteLanguage(id: number): Promise<void> {
    const response = await fetch(`${this.baseUrl}/languages/${id}`, { method: 'DELETE' })
    if (!response.ok) throw new Error(`HTTP ${response.status}`)
  }

  // ── Hobbies ───────────────────────────────────────────────────────────────

  static async createHobby(payload: any): Promise<any> {
    const response = await fetch(`${this.baseUrl}/hobbies`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
    })
    if (!response.ok) throw new Error(`HTTP ${response.status}`)
    return response.json()
  }

  static async updateHobby(id: number, payload: any): Promise<any> {
    const response = await fetch(`${this.baseUrl}/hobbies/${id}`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
    })
    if (!response.ok) throw new Error(`HTTP ${response.status}`)
    return response.json()
  }

  static async deleteHobby(id: number): Promise<void> {
    const response = await fetch(`${this.baseUrl}/hobbies/${id}`, { method: 'DELETE' })
    if (!response.ok) throw new Error(`HTTP ${response.status}`)
  }

  // ── Soft skills ───────────────────────────────────────────────────────────

  static async createSoftSkill(payload: any): Promise<any> {
    const response = await fetch(`${this.baseUrl}/soft-skills`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
    })
    if (!response.ok) throw new Error(`HTTP ${response.status}`)
    return response.json()
  }

  static async updateSoftSkill(id: number, payload: any): Promise<any> {
    const response = await fetch(`${this.baseUrl}/soft-skills/${id}`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
    })
    if (!response.ok) throw new Error(`HTTP ${response.status}`)
    return response.json()
  }

  static async deleteSoftSkill(id: number): Promise<void> {
    const response = await fetch(`${this.baseUrl}/soft-skills/${id}`, { method: 'DELETE' })
    if (!response.ok) throw new Error(`HTTP ${response.status}`)
  }

  // ── Educations ────────────────────────────────────────────────────────────

  static async createEducation(payload: any): Promise<any> {
    const response = await fetch(`${this.baseUrl}/educations`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
    })
    if (!response.ok) throw new Error(`HTTP ${response.status}`)
    return response.json()
  }

  static async updateEducation(id: number, payload: any): Promise<any> {
    const response = await fetch(`${this.baseUrl}/educations/${id}`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
    })
    if (!response.ok) throw new Error(`HTTP ${response.status}`)
    return response.json()
  }

  static async deleteEducation(id: number): Promise<void> {
    const response = await fetch(`${this.baseUrl}/educations/${id}`, { method: 'DELETE' })
    if (!response.ok) throw new Error(`HTTP ${response.status}`)
  }

  // ── Experiences ───────────────────────────────────────────────────────────

  static async createExperience(payload: any): Promise<any> {
    const response = await fetch(`${this.baseUrl}/experiences`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
    })
    if (!response.ok) throw new Error(`HTTP ${response.status}`)
    return response.json()
  }

  static async updateExperience(id: number, payload: any): Promise<any> {
    const response = await fetch(`${this.baseUrl}/experiences/${id}`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
    })
    if (!response.ok) throw new Error(`HTTP ${response.status}`)
    return response.json()
  }

  static async deleteExperience(id: number): Promise<void> {
    const response = await fetch(`${this.baseUrl}/experiences/${id}`, { method: 'DELETE' })
    if (!response.ok) throw new Error(`HTTP ${response.status}`)
  }

  // ── Projects ──────────────────────────────────────────────────────────────

  static async createProject(payload: ProjectPayload): Promise<any> {
    const response = await fetch(`${this.baseUrl}/projects`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
    })
    if (!response.ok) throw new Error(`HTTP ${response.status}`)
    return response.json()
  }

  static async updateProject(id: number, payload: ProjectPayload): Promise<any> {
    const response = await fetch(`${this.baseUrl}/projects/${id}`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
    })
    if (!response.ok) throw new Error(`HTTP ${response.status}`)
    return response.json()
  }

  static async deleteProject(id: number): Promise<void> {
    const response = await fetch(`${this.baseUrl}/projects/${id}`, { method: 'DELETE' })
    if (!response.ok) throw new Error(`HTTP ${response.status}`)
  }
}
