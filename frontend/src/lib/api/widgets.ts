import type { WidgetConfig, WidgetChatRequest, WidgetChatResponse } from '@/types'

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000'

/**
 * Widget API Service
 * Handles all widget-related API calls
 */
export class WidgetApiService {
  private baseUrl: string

  constructor(baseUrl: string = API_BASE_URL) {
    this.baseUrl = baseUrl
  }

  /**
   * Get widget configuration
   */
  async getWidgetConfig(): Promise<WidgetConfig> {
    const response = await fetch(`${this.baseUrl}/widget/config`, {
      method: 'GET',
      headers: {
        'Content-Type': 'application/json',
      },
    })

    if (!response.ok) {
      throw new Error(`Failed to get widget config: ${response.statusText}`)
    }

    return response.json()
  }

  /**
   * Send chat message from widget
   */
  async sendWidgetMessage(request: WidgetChatRequest): Promise<WidgetChatResponse> {
    const response = await fetch(`${this.baseUrl}/widget/chat`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(request),
    })

    if (!response.ok) {
      throw new Error(`Failed to send widget message: ${response.statusText}`)
    }

    return response.json()
  }

  /**
   * Get widget health status
   */
  async getWidgetHealth(): Promise<{ status: string; timestamp: string }> {
    const response = await fetch(`${this.baseUrl}/widget/health`, {
      method: 'GET',
      headers: {
        'Content-Type': 'application/json',
      },
    })

    if (!response.ok) {
      throw new Error(`Failed to get widget health: ${response.statusText}`)
    }

    return response.json()
  }

  /**
   * Get widget status
   */
  async getWidgetStatus(): Promise<{
    status: string
    timestamp: string
    documents_available: number
    last_updated: string
    version: string
  }> {
    const response = await fetch(`${this.baseUrl}/widget/status`, {
      method: 'GET',
      headers: {
        'Content-Type': 'application/json',
      },
    })

    if (!response.ok) {
      throw new Error(`Failed to get widget status: ${response.statusText}`)
    }

    return response.json()
  }

  /**
   * Create a new widget
   */
  async createWidget(widgetData: {
    name: string
    description: string
    config: WidgetConfig
  }): Promise<{ id: string; embed_code: string }> {
    const response = await fetch(`${this.baseUrl}/api/widgets`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        // TODO: Add authentication header
      },
      body: JSON.stringify(widgetData),
    })

    if (!response.ok) {
      throw new Error(`Failed to create widget: ${response.statusText}`)
    }

    return response.json()
  }

  /**
   * Get all widgets for the current user
   */
  async getWidgets(): Promise<Array<{
    id: string
    name: string
    description: string
    config: WidgetConfig
    embed_code: string
    created_at: string
    is_active: boolean
  }>> {
    const response = await fetch(`${this.baseUrl}/api/widgets`, {
      method: 'GET',
      headers: {
        'Content-Type': 'application/json',
        // TODO: Add authentication header
      },
    })

    if (!response.ok) {
      throw new Error(`Failed to get widgets: ${response.statusText}`)
    }

    return response.json()
  }

  /**
   * Update a widget
   */
  async updateWidget(
    widgetId: string,
    widgetData: {
      name: string
      description: string
      config: WidgetConfig
    }
  ): Promise<{ id: string; embed_code: string }> {
    const response = await fetch(`${this.baseUrl}/api/widgets/${widgetId}`, {
      method: 'PUT',
      headers: {
        'Content-Type': 'application/json',
        // TODO: Add authentication header
      },
      body: JSON.stringify(widgetData),
    })

    if (!response.ok) {
      throw new Error(`Failed to update widget: ${response.statusText}`)
    }

    return response.json()
  }

  /**
   * Delete a widget
   */
  async deleteWidget(widgetId: string): Promise<void> {
    const response = await fetch(`${this.baseUrl}/api/widgets/${widgetId}`, {
      method: 'DELETE',
      headers: {
        'Content-Type': 'application/json',
        // TODO: Add authentication header
      },
    })

    if (!response.ok) {
      throw new Error(`Failed to delete widget: ${response.statusText}`)
    }
  }

  /**
   * Generate embed code for a widget
   */
  generateEmbedCode(widgetConfig: WidgetConfig): string {
    return `<script src="http://localhost:3006/widget/chat-widget.js"></script>
<script>
  BMIWidget.init({
    position: '${widgetConfig.position}',
    accentColor: '${widgetConfig.accent_color}',
    companyName: '${widgetConfig.company_name}',
    assistantName: '${widgetConfig.assistant_name}',
    welcomeMessage: '${widgetConfig.welcome_message}'
  });
</script>`
  }
}

// Export singleton instance
export const widgetApi = new WidgetApiService() 