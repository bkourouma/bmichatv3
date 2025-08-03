import React, { useState, useEffect } from 'react'
import {
  ClipboardDocumentIcon,
  EyeIcon,
  PencilIcon,
  TrashIcon,
  PlusIcon,
  GlobeAltIcon,
  ChatBubbleLeftRightIcon,
} from '@heroicons/react/24/outline'
import toast from 'react-hot-toast'
import type { WidgetConfig } from '@/types'

interface Widget {
  id: string
  name: string
  description: string
  config: WidgetConfig
  embedCode: string
  createdAt: string
  isActive: boolean
}

const Widgets: React.FC = () => {
  const [widgets, setWidgets] = useState<Widget[]>([])
  const [showCreateForm, setShowCreateForm] = useState(false)
  const [editingWidget, setEditingWidget] = useState<Widget | null>(null)
  const [previewWidget, setPreviewWidget] = useState<Widget | null>(null)
  const [testingWidget, setTestingWidget] = useState<Widget | null>(null)
  
  const [formData, setFormData] = useState({
    name: '',
    description: '',
    position: 'right' as 'left' | 'right',
    accentColor: '#3b82f6',
    companyName: 'BMI',
    assistantName: 'Akissi',
    welcomeMessage: 'Bonjour ! Je suis Akissi, votre assistante BMI. Comment puis-je vous aider ?',
    enabled: true,
  })

  // Load existing widgets
  useEffect(() => {
    // TODO: Load widgets from API
    const mockWidgets: Widget[] = [
      {
        id: '1',
        name: 'Widget Principal BMI',
        description: 'Widget principal pour le site web BMI',
        config: {
          position: 'right',
          accent_color: '#3b82f6',
          company_name: 'BMI',
          assistant_name: 'Akissi',
          welcome_message: 'Bonjour ! Je suis Akissi, votre assistante BMI. Comment puis-je vous aider ?',
          enabled: true,
        },
        embedCode: `<script src="http://localhost:3006/widget/chat-widget.js"></script>
<script>
  BMIWidget.init({
    position: 'right',
    accentColor: '#3b82f6',
    companyName: 'BMI',
    assistantName: 'Akissi',
    welcomeMessage: 'Bonjour ! Je suis Akissi, votre assistante BMI. Comment puis-je vous aider ?'
  });
</script>`,
        createdAt: '2024-01-15T10:30:00Z',
        isActive: true,
      },
    ]
    setWidgets(mockWidgets)
  }, [])

  const generateEmbedCode = (widget: Widget): string => {
    return `<script src="http://localhost:3006/widget/chat-widget.js"></script>
<script>
  BMIWidget.init({
    position: '${widget.config.position}',
    accentColor: '${widget.config.accent_color}',
    companyName: '${widget.config.company_name}',
    assistantName: '${widget.config.assistant_name}',
    welcomeMessage: '${widget.config.welcome_message}'
  });
</script>`
  }

  const handleCreateWidget = () => {
    if (!formData.name.trim()) {
      toast.error('Le nom du widget est requis')
      return
    }

    const newWidget: Widget = {
      id: Date.now().toString(),
      name: formData.name,
      description: formData.description,
      config: {
        position: formData.position,
        accent_color: formData.accentColor,
        company_name: formData.companyName,
        assistant_name: formData.assistantName,
        welcome_message: formData.welcomeMessage,
        enabled: formData.enabled,
      },
      embedCode: '',
      createdAt: new Date().toISOString(),
      isActive: true,
    }

    newWidget.embedCode = generateEmbedCode(newWidget)
    setWidgets([...widgets, newWidget])
    setShowCreateForm(false)
    resetForm()
    toast.success('Widget créé avec succès')
  }

  const handleUpdateWidget = () => {
    if (!editingWidget) return

    const updatedWidget: Widget = {
      ...editingWidget,
      name: formData.name,
      description: formData.description,
      config: {
        position: formData.position,
        accent_color: formData.accentColor,
        company_name: formData.companyName,
        assistant_name: formData.assistantName,
        welcome_message: formData.welcomeMessage,
        enabled: formData.enabled,
      },
    }

    updatedWidget.embedCode = generateEmbedCode(updatedWidget)
    
    setWidgets(widgets.map(w => w.id === editingWidget.id ? updatedWidget : w))
    setEditingWidget(null)
    resetForm()
    toast.success('Widget mis à jour avec succès')
  }

  const handleDeleteWidget = (widgetId: string) => {
    if (confirm('Êtes-vous sûr de vouloir supprimer ce widget ?')) {
      setWidgets(widgets.filter(w => w.id !== widgetId))
      toast.success('Widget supprimé')
    }
  }

  const handleEditWidget = (widget: Widget) => {
    setEditingWidget(widget)
    setFormData({
      name: widget.name,
      description: widget.description,
      position: widget.config.position,
      accentColor: widget.config.accent_color,
      companyName: widget.config.company_name,
      assistantName: widget.config.assistant_name,
      welcomeMessage: widget.config.welcome_message,
      enabled: widget.config.enabled,
    })
  }

  const handlePreviewWidget = (widget: Widget) => {
    setPreviewWidget(widget)
  }

  const handleTestWidget = (widget: Widget) => {
    setTestingWidget(widget)
  }

  const resetForm = () => {
    setFormData({
      name: '',
      description: '',
      position: 'right',
      accentColor: '#3b82f6',
      companyName: 'BMI',
      assistantName: 'Akissi',
      welcomeMessage: 'Bonjour ! Je suis Akissi, votre assistante BMI. Comment puis-je vous aider ?',
      enabled: true,
    })
  }

  const copyToClipboard = (text: string) => {
    navigator.clipboard.writeText(text)
    toast.success('Code copié dans le presse-papiers')
  }

  return (
    <div className="space-y-8">
      {/* Header */}
      <div className="bg-gradient-to-r from-blue-600 to-purple-600 rounded-xl p-8 text-white">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-3xl font-bold mb-2">
              Widgets de chat
            </h1>
            <p className="text-blue-100 text-lg">
              Créez et gérez vos widgets de chat intégrables
            </p>
          </div>
          <div className="hidden md:flex items-center space-x-4">
            <a
              href="/widget-test-demo.html"
              target="_blank"
              rel="noopener noreferrer"
              className="bg-white/10 hover:bg-white/20 text-white px-4 py-2 rounded-lg transition-colors flex items-center space-x-2"
            >
              <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14" />
              </svg>
              <span>Démo Widget</span>
            </a>
            <div className="w-24 h-24 bg-white/10 rounded-full flex items-center justify-center">
              <GlobeAltIcon className="w-12 h-12 text-white" />
            </div>
          </div>
        </div>
      </div>

      {/* Create Widget Button */}
      <div className="flex justify-between items-center">
        <h2 className="text-xl font-semibold text-gray-900">
          Mes widgets ({widgets.length})
        </h2>
        <button
          onClick={() => setShowCreateForm(true)}
          className="btn-primary flex items-center space-x-2"
        >
          <PlusIcon className="w-5 h-5" />
          <span>Créer un widget</span>
        </button>
      </div>

      {/* Widgets List */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {widgets.map((widget) => (
          <div key={widget.id} className="card p-6 hover:shadow-lg transition-shadow">
            <div className="flex items-start justify-between mb-4">
              <div>
                <h3 className="text-lg font-semibold text-gray-900">{widget.name}</h3>
                <p className="text-sm text-gray-600 mt-1">{widget.description}</p>
              </div>
              <div className="flex items-center space-x-2">
                <span className={`px-2 py-1 text-xs rounded-full ${
                  widget.isActive 
                    ? 'bg-green-100 text-green-800' 
                    : 'bg-gray-100 text-gray-800'
                }`}>
                  {widget.isActive ? 'Actif' : 'Inactif'}
                </span>
              </div>
            </div>

            <div className="space-y-3 mb-4">
              <div className="flex items-center text-sm text-gray-600">
                <ChatBubbleLeftRightIcon className="w-4 h-4 mr-2" />
                <span>{widget.config.assistant_name}</span>
              </div>
              <div className="flex items-center text-sm text-gray-600">
                <div 
                  className="w-4 h-4 rounded mr-2 border border-gray-300"
                  style={{ backgroundColor: widget.config.accent_color }}
                />
                <span>Position: {widget.config.position === 'right' ? 'Droite' : 'Gauche'}</span>
              </div>
            </div>

            <div className="space-y-3 pt-4 border-t border-gray-200">
              <div className="flex items-center justify-between">
                <div className="flex space-x-2">
                  <button
                    onClick={() => handlePreviewWidget(widget)}
                    className="p-2 text-gray-600 hover:text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"
                    title="Aperçu"
                  >
                    <EyeIcon className="w-4 h-4" />
                  </button>
                  <button
                    onClick={() => handleEditWidget(widget)}
                    className="p-2 text-gray-600 hover:text-green-600 hover:bg-green-50 rounded-lg transition-colors"
                    title="Modifier"
                  >
                    <PencilIcon className="w-4 h-4" />
                  </button>
                  <button
                    onClick={() => copyToClipboard(widget.embedCode)}
                    className="p-2 text-gray-600 hover:text-purple-600 hover:bg-purple-50 rounded-lg transition-colors"
                    title="Copier le code"
                  >
                    <ClipboardDocumentIcon className="w-4 h-4" />
                  </button>
                </div>
                <button
                  onClick={() => handleDeleteWidget(widget.id)}
                  className="p-2 text-gray-600 hover:text-red-600 hover:bg-red-50 rounded-lg transition-colors"
                  title="Supprimer"
                >
                  <TrashIcon className="w-4 h-4" />
                </button>
              </div>

              {/* Test Chat Button */}
              <button
                onClick={() => handleTestWidget(widget)}
                className="w-full bg-gradient-to-r from-blue-500 to-blue-600 hover:from-blue-600 hover:to-blue-700 text-white font-medium py-2.5 px-4 rounded-lg transition-all duration-200 flex items-center justify-center space-x-2 shadow-sm hover:shadow-md"
              >
                <ChatBubbleLeftRightIcon className="w-4 h-4" />
                <span>Tester le Chat</span>
              </button>
            </div>
          </div>
        ))}
      </div>

      {/* Create/Edit Widget Modal */}
      {(showCreateForm || editingWidget) && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-xl p-8 max-w-2xl w-full mx-4 max-h-[90vh] overflow-y-auto">
            <div className="flex items-center justify-between mb-6">
              <h2 className="text-2xl font-bold text-gray-900">
                {editingWidget ? 'Modifier le widget' : 'Créer un nouveau widget'}
              </h2>
              <button
                onClick={() => {
                  setShowCreateForm(false)
                  setEditingWidget(null)
                  resetForm()
                }}
                className="text-gray-400 hover:text-gray-600"
              >
                ✕
              </button>
            </div>

            <div className="space-y-6">
              {/* Basic Information */}
              <div>
                <h3 className="text-lg font-semibold text-gray-900 mb-4">
                  Informations de base
                </h3>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      Nom du widget *
                    </label>
                    <input
                      type="text"
                      value={formData.name}
                      onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                      className="input w-full"
                      placeholder="ex: Widget Principal BMI"
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      Description
                    </label>
                    <input
                      type="text"
                      value={formData.description}
                      onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                      className="input w-full"
                      placeholder="Description du widget"
                    />
                  </div>
                </div>
              </div>

              {/* Appearance Settings */}
              <div>
                <h3 className="text-lg font-semibold text-gray-900 mb-4">
                  Apparence
                </h3>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      Position
                    </label>
                    <select
                      value={formData.position}
                      onChange={(e) => setFormData({ ...formData, position: e.target.value as 'left' | 'right' })}
                      className="input w-full"
                    >
                      <option value="left">Gauche</option>
                      <option value="right">Droite</option>
                    </select>
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      Couleur d'accent
                    </label>
                    <input
                      type="color"
                      value={formData.accentColor}
                      onChange={(e) => setFormData({ ...formData, accentColor: e.target.value })}
                      className="h-10 w-full border border-gray-300 rounded-lg"
                    />
                  </div>
                </div>
              </div>

              {/* Chat Configuration */}
              <div>
                <h3 className="text-lg font-semibold text-gray-900 mb-4">
                  Configuration du chat
                </h3>
                <div className="space-y-4">
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-2">
                        Nom de l'entreprise
                      </label>
                      <input
                        type="text"
                        value={formData.companyName}
                        onChange={(e) => setFormData({ ...formData, companyName: e.target.value })}
                        className="input w-full"
                        placeholder="BMI"
                      />
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-2">
                        Nom de l'assistant
                      </label>
                      <input
                        type="text"
                        value={formData.assistantName}
                        onChange={(e) => setFormData({ ...formData, assistantName: e.target.value })}
                        className="input w-full"
                        placeholder="Akissi"
                      />
                    </div>
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      Message de bienvenue
                    </label>
                    <textarea
                      value={formData.welcomeMessage}
                      onChange={(e) => setFormData({ ...formData, welcomeMessage: e.target.value })}
                      className="input w-full"
                      rows={3}
                      placeholder="Message de bienvenue personnalisé"
                    />
                  </div>
                </div>
              </div>

              {/* Status */}
              <div>
                <div className="flex items-center">
                  <input
                    type="checkbox"
                    id="enabled"
                    checked={formData.enabled}
                    onChange={(e) => setFormData({ ...formData, enabled: e.target.checked })}
                    className="h-4 w-4 text-primary-600 focus:ring-primary-500 border-gray-300 rounded"
                  />
                  <label htmlFor="enabled" className="ml-2 block text-sm text-gray-900">
                    Activer le widget
                  </label>
                </div>
              </div>
            </div>

            {/* Actions */}
            <div className="flex justify-end space-x-4 mt-8 pt-6 border-t border-gray-200">
              <button
                onClick={() => {
                  setShowCreateForm(false)
                  setEditingWidget(null)
                  resetForm()
                }}
                className="btn-outline"
              >
                Annuler
              </button>
              <button
                onClick={editingWidget ? handleUpdateWidget : handleCreateWidget}
                className="btn-primary"
              >
                {editingWidget ? 'Mettre à jour' : 'Créer le widget'}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Preview Modal */}
      {previewWidget && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-xl p-8 max-w-4xl w-full mx-4 max-h-[90vh] overflow-y-auto">
            <div className="flex items-center justify-between mb-6">
              <h2 className="text-2xl font-bold text-gray-900">
                Aperçu du widget
              </h2>
              <button
                onClick={() => setPreviewWidget(null)}
                className="text-gray-400 hover:text-gray-600"
              >
                ✕
              </button>
            </div>

            <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
              {/* Preview */}
              <div>
                <h3 className="text-lg font-semibold text-gray-900 mb-4">
                  Aperçu
                </h3>
                <div className="border border-gray-200 rounded-lg p-4 bg-gray-50 min-h-[400px]">
                  <div className="text-center text-gray-500 py-8">
                    <ChatBubbleLeftRightIcon className="w-12 h-12 mx-auto mb-4 text-gray-400" />
                    <p>Aperçu du widget</p>
                    <p className="text-sm mt-2">
                      Le widget apparaîtra en position {previewWidget.config.position === 'right' ? 'droite' : 'gauche'}
                    </p>
                  </div>
                </div>
              </div>

              {/* Embed Code */}
              <div>
                <h3 className="text-lg font-semibold text-gray-900 mb-4">
                  Code d'intégration
                </h3>
                <div className="bg-gray-900 rounded-lg p-4">
                  <div className="flex justify-between items-center mb-2">
                    <span className="text-sm text-gray-400">Code à intégrer</span>
                    <button
                      onClick={() => copyToClipboard(previewWidget.embedCode)}
                      className="text-blue-400 hover:text-blue-300 text-sm"
                    >
                      Copier
                    </button>
                  </div>
                  <pre className="text-green-400 text-sm overflow-x-auto">
                    <code>{previewWidget.embedCode}</code>
                  </pre>
                </div>
                
                <div className="mt-4 p-4 bg-blue-50 rounded-lg">
                  <h4 className="font-semibold text-blue-900 mb-2">Instructions</h4>
                  <ol className="text-sm text-blue-800 space-y-1">
                    <li>1. Copiez le code ci-dessus</li>
                    <li>2. Collez-le dans le &lt;head&gt; de votre page HTML</li>
                    <li>3. Le widget apparaîtra automatiquement sur votre site</li>
                  </ol>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Empty State */}
      {widgets.length === 0 && !showCreateForm && (
        <div className="text-center py-12">
          <GlobeAltIcon className="w-16 h-16 text-gray-400 mx-auto mb-4" />
          <h3 className="text-lg font-semibold text-gray-900 mb-2">
            Aucun widget créé
          </h3>
          <p className="text-gray-600 mb-6">
            Créez votre premier widget de chat pour l'intégrer sur votre site web.
          </p>
          <div className="space-y-3">
            <button
              onClick={() => setShowCreateForm(true)}
              className="btn-primary"
            >
              Créer votre premier widget
            </button>
            <div className="text-center">
              <a
                href="/widget-test-demo.html"
                target="_blank"
                rel="noopener noreferrer"
                className="inline-flex items-center space-x-2 text-blue-600 hover:text-blue-700 transition-colors"
              >
                <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14" />
                </svg>
                <span>Voir la démo du widget</span>
              </a>
            </div>
          </div>
        </div>
      )}

      {/* Widget Test Modal */}
      {testingWidget && (
        <WidgetTestModal
          widget={testingWidget}
          onClose={() => setTestingWidget(null)}
        />
      )}
    </div>
  )
}

// Widget Test Modal Component
interface WidgetTestModalProps {
  widget: Widget
  onClose: () => void
}

const WidgetTestModal: React.FC<WidgetTestModalProps> = ({ widget, onClose }) => {
  const [messages, setMessages] = useState<Array<{role: 'user' | 'assistant', content: string, timestamp: Date}>>([
    {
      role: 'assistant',
      content: widget.config.welcome_message,
      timestamp: new Date()
    }
  ])
  const [inputMessage, setInputMessage] = useState('')
  const [isLoading, setIsLoading] = useState(false)

  const sendMessage = async () => {
    if (!inputMessage.trim() || isLoading) return

    const userMessage = {
      role: 'user' as const,
      content: inputMessage.trim(),
      timestamp: new Date()
    }

    setMessages(prev => [...prev, userMessage])
    setInputMessage('')
    setIsLoading(true)

    try {
      // Simulate API call to widget chat endpoint
      const response = await fetch('/api/chat', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          message: userMessage.content,
          session_id: `test_${Date.now()}`,
        }),
      })

      if (response.ok) {
        const data = await response.json()
        const assistantMessage = {
          role: 'assistant' as const,
          content: data.message || 'Désolée, je n\'ai pas pu traiter votre demande.',
          timestamp: new Date()
        }
        setMessages(prev => [...prev, assistantMessage])
      } else {
        throw new Error('Erreur de communication')
      }
    } catch (error) {
      const errorMessage = {
        role: 'assistant' as const,
        content: 'Désolée, une erreur s\'est produite. Veuillez réessayer.',
        timestamp: new Date()
      }
      setMessages(prev => [...prev, errorMessage])
    } finally {
      setIsLoading(false)
    }
  }

  const handleKeyPress = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault()
      sendMessage()
    }
  }

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <div className="bg-white rounded-xl shadow-2xl w-full max-w-md mx-4 h-[600px] flex flex-col">
        {/* Header */}
        <div
          className="flex items-center justify-between p-4 border-b border-gray-200 rounded-t-xl"
          style={{ backgroundColor: widget.config.accent_color }}
        >
          <div className="flex items-center space-x-3">
            <div className="w-8 h-8 bg-white/20 rounded-full flex items-center justify-center">
              <ChatBubbleLeftRightIcon className="w-5 h-5 text-white" />
            </div>
            <div>
              <h3 className="font-semibold text-white">{widget.config.assistant_name}</h3>
              <p className="text-xs text-white/80">{widget.config.company_name}</p>
            </div>
          </div>
          <button
            onClick={onClose}
            className="text-white/80 hover:text-white transition-colors"
          >
            <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>

        {/* Messages */}
        <div className="flex-1 overflow-y-auto p-4 space-y-4">
          {messages.map((message, index) => (
            <div
              key={index}
              className={`flex ${message.role === 'user' ? 'justify-end' : 'justify-start'}`}
            >
              <div
                className={`max-w-[80%] p-3 rounded-lg ${
                  message.role === 'user'
                    ? 'bg-blue-500 text-white rounded-br-sm'
                    : 'bg-gray-100 text-gray-900 rounded-bl-sm'
                }`}
              >
                <p className="text-sm">{message.content}</p>
                <p className={`text-xs mt-1 ${
                  message.role === 'user' ? 'text-blue-100' : 'text-gray-500'
                }`}>
                  {message.timestamp.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                </p>
              </div>
            </div>
          ))}

          {isLoading && (
            <div className="flex justify-start">
              <div className="bg-gray-100 text-gray-900 rounded-lg rounded-bl-sm p-3">
                <div className="flex space-x-1">
                  <div className="w-2 h-2 bg-gray-400 rounded-full animate-bounce"></div>
                  <div className="w-2 h-2 bg-gray-400 rounded-full animate-bounce" style={{ animationDelay: '0.1s' }}></div>
                  <div className="w-2 h-2 bg-gray-400 rounded-full animate-bounce" style={{ animationDelay: '0.2s' }}></div>
                </div>
              </div>
            </div>
          )}
        </div>

        {/* Input */}
        <div className="p-4 border-t border-gray-200">
          <div className="flex space-x-2">
            <input
              type="text"
              value={inputMessage}
              onChange={(e) => setInputMessage(e.target.value)}
              onKeyPress={handleKeyPress}
              placeholder="Tapez votre message..."
              className="flex-1 px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              disabled={isLoading}
            />
            <button
              onClick={sendMessage}
              disabled={!inputMessage.trim() || isLoading}
              className="px-4 py-2 bg-blue-500 text-white rounded-lg hover:bg-blue-600 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
            >
              <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 19l9 2-9-18-9 18 9-2zm0 0v-8" />
              </svg>
            </button>
          </div>
        </div>
      </div>
    </div>
  )
}

export default Widgets