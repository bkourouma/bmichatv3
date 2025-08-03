/**
 * BMI Chat Widget - Embeddable Chat Interface
 * Version: 1.0.0
 * 
 * This widget provides an embeddable chat interface that can be integrated
 * into any website to allow visitors to chat with the BMI AI assistant.
 */

(function() {
  'use strict';

  // Widget configuration
  let config = {
    position: 'right',
    accentColor: '#3b82f6',
    companyName: 'BMI',
    assistantName: 'Akissi',
    welcomeMessage: 'Bonjour ! Je suis Akissi, votre assistante BMI. Comment puis-je vous aider ?',
    apiUrl: window.location.origin + '/widget', // Use current domain
    isOpen: false,
    sessionId: null
  };

  // Widget state
  let state = {
    messages: [],
    isLoading: false,
    isInitialized: false
  };

  // DOM elements
  let elements = {
    container: null,
    button: null,
    chatWindow: null,
    header: null,
    messagesContainer: null,
    inputContainer: null,
    input: null,
    sendButton: null,
    closeButton: null
  };

  /**
   * Initialize the widget
   * @param {Object} options - Configuration options
   */
  function init(options = {}) {
    // Merge configuration
    config = { ...config, ...options };
    
    // Generate session ID
    config.sessionId = generateSessionId();
    
    // Create widget elements
    createWidgetElements();
    
    // Add event listeners
    addEventListeners();
    
    // Show welcome message
    addMessage('assistant', config.welcomeMessage);
    
    state.isInitialized = true;
    
    console.log('BMI Chat Widget initialized');
  }

  /**
   * Create widget DOM elements
   */
  function createWidgetElements() {
    // Create main container
    elements.container = document.createElement('div');
    elements.container.id = 'bmi-chat-widget';
    elements.container.style.cssText = `
      position: fixed;
      ${config.position}: 20px;
      bottom: 20px;
      z-index: 9999;
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
    `;

    // Create chat button
    elements.button = document.createElement('div');
    elements.button.id = 'bmi-chat-button';
    elements.button.innerHTML = `
      <div style="
        width: 60px;
        height: 60px;
        border-radius: 50%;
        background: ${config.accentColor};
        display: flex;
        align-items: center;
        justify-content: center;
        cursor: pointer;
        box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
        transition: all 0.3s ease;
      ">
        <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="2">
          <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/>
        </svg>
      </div>
    `;

    // Create chat window
    elements.chatWindow = document.createElement('div');
    elements.chatWindow.id = 'bmi-chat-window';
    elements.chatWindow.style.cssText = `
      position: absolute;
      bottom: 80px;
      ${config.position}: 0;
      width: 350px;
      height: 500px;
      background: white;
      border-radius: 12px;
      box-shadow: 0 8px 32px rgba(0, 0, 0, 0.12);
      display: none;
      flex-direction: column;
      overflow: hidden;
    `;

    // Create header
    elements.header = document.createElement('div');
    elements.header.style.cssText = `
      background: ${config.accentColor};
      color: white;
      padding: 16px;
      display: flex;
      align-items: center;
      justify-content: space-between;
    `;
    elements.header.innerHTML = `
      <div>
        <div style="font-weight: 600; font-size: 16px;">${config.assistantName}</div>
        <div style="font-size: 12px; opacity: 0.9;">${config.companyName}</div>
      </div>
      <div id="bmi-chat-close" style="cursor: pointer; padding: 4px;">
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <line x1="18" y1="6" x2="6" y2="18"></line>
          <line x1="6" y1="6" x2="18" y2="18"></line>
        </svg>
      </div>
    `;

    // Create messages container
    elements.messagesContainer = document.createElement('div');
    elements.messagesContainer.id = 'bmi-chat-messages';
    elements.messagesContainer.style.cssText = `
      flex: 1;
      padding: 16px;
      overflow-y: auto;
      background: #f8fafc;
    `;

    // Create input container
    elements.inputContainer = document.createElement('div');
    elements.inputContainer.style.cssText = `
      padding: 16px;
      border-top: 1px solid #e2e8f0;
      background: white;
    `;

    // Create input field
    elements.input = document.createElement('input');
    elements.input.type = 'text';
    elements.input.placeholder = 'Tapez votre message...';
    elements.input.style.cssText = `
      width: 100%;
      padding: 12px;
      border: 1px solid #e2e8f0;
      border-radius: 8px;
      font-size: 14px;
      outline: none;
      box-sizing: border-box;
    `;

    // Create send button
    elements.sendButton = document.createElement('button');
    elements.sendButton.innerHTML = `
      <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <line x1="22" y1="2" x2="11" y2="13"></line>
        <polygon points="22,2 15,22 11,13 2,9"></polygon>
      </svg>
    `;
    elements.sendButton.style.cssText = `
      position: absolute;
      right: 8px;
      top: 50%;
      transform: translateY(-50%);
      background: ${config.accentColor};
      color: white;
      border: none;
      border-radius: 6px;
      width: 32px;
      height: 32px;
      cursor: pointer;
      display: flex;
      align-items: center;
      justify-content: center;
    `;

    // Assemble the widget
    elements.inputContainer.appendChild(elements.input);
    elements.inputContainer.appendChild(elements.sendButton);
    elements.chatWindow.appendChild(elements.header);
    elements.chatWindow.appendChild(elements.messagesContainer);
    elements.chatWindow.appendChild(elements.inputContainer);
    elements.container.appendChild(elements.button);
    elements.container.appendChild(elements.chatWindow);

    // Add to page
    document.body.appendChild(elements.container);
  }

  /**
   * Add event listeners
   */
  function addEventListeners() {
    // Toggle chat window
    elements.button.addEventListener('click', toggleChat);
    
    // Close button
    elements.header.querySelector('#bmi-chat-close').addEventListener('click', closeChat);
    
    // Send message on Enter
    elements.input.addEventListener('keypress', function(e) {
      if (e.key === 'Enter' && !e.shiftKey) {
        e.preventDefault();
        sendMessage();
      }
    });
    
    // Send button click
    elements.sendButton.addEventListener('click', sendMessage);
    
    // Close on escape
    document.addEventListener('keydown', function(e) {
      if (e.key === 'Escape' && config.isOpen) {
        closeChat();
      }
    });
  }

  /**
   * Toggle chat window
   */
  function toggleChat() {
    if (config.isOpen) {
      closeChat();
    } else {
      openChat();
    }
  }

  /**
   * Open chat window
   */
  function openChat() {
    config.isOpen = true;
    elements.chatWindow.style.display = 'flex';
    elements.button.style.transform = 'scale(0.9)';
    elements.input.focus();
  }

  /**
   * Close chat window
   */
  function closeChat() {
    config.isOpen = false;
    elements.chatWindow.style.display = 'none';
    elements.button.style.transform = 'scale(1)';
  }

  /**
   * Send message
   */
  async function sendMessage() {
    const message = elements.input.value.trim();
    if (!message || state.isLoading) return;

    // Add user message
    addMessage('user', message);
    elements.input.value = '';

    // Show loading
    state.isLoading = true;
    showLoading();

    try {
      // Send to API
      const response = await fetch(`${config.apiUrl}/chat`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          message: message,
          session_id: config.sessionId,
          widget_key: config.widgetKey
        })
      });

      if (!response.ok) {
        throw new Error('Network response was not ok');
      }

      const data = await response.json();
      
      // Add assistant response
      addMessage('assistant', data.message);
      
    } catch (error) {
      console.error('Error sending message:', error);
      addMessage('assistant', 'Désolé, je rencontre des difficultés techniques. Veuillez réessayer plus tard.');
    } finally {
      state.isLoading = false;
      hideLoading();
    }
  }

  /**
   * Add message to chat
   */
  function addMessage(sender, text) {
    const messageDiv = document.createElement('div');
    messageDiv.style.cssText = `
      margin-bottom: 12px;
      display: flex;
      ${sender === 'user' ? 'justify-content: flex-end' : 'justify-content: flex-start'}
    `;

    const messageBubble = document.createElement('div');
    messageBubble.style.cssText = `
      max-width: 80%;
      padding: 12px 16px;
      border-radius: 18px;
      font-size: 14px;
      line-height: 1.4;
      ${sender === 'user' 
        ? `background: ${config.accentColor}; color: white;` 
        : 'background: white; color: #374151; border: 1px solid #e2e8f0;'
      }
    `;
    messageBubble.textContent = text;

    messageDiv.appendChild(messageBubble);
    elements.messagesContainer.appendChild(messageDiv);
    
    // Scroll to bottom
    elements.messagesContainer.scrollTop = elements.messagesContainer.scrollHeight;
    
    // Store message
    state.messages.push({ sender, text, timestamp: new Date() });
  }

  /**
   * Show loading indicator
   */
  function showLoading() {
    const loadingDiv = document.createElement('div');
    loadingDiv.id = 'bmi-chat-loading';
    loadingDiv.style.cssText = `
      margin-bottom: 12px;
      display: flex;
      justify-content: flex-start;
    `;
    
    const loadingBubble = document.createElement('div');
    loadingBubble.style.cssText = `
      padding: 12px 16px;
      border-radius: 18px;
      background: white;
      border: 1px solid #e2e8f0;
    `;
    loadingBubble.innerHTML = `
      <div style="display: flex; align-items: center; gap: 4px;">
        <div style="width: 12px; height: 12px; border: 2px solid #e2e8f0; border-top: 2px solid ${config.accentColor}; border-radius: 50%; animation: spin 1s linear infinite;"></div>
        <span style="font-size: 14px; color: #6b7280;">${config.assistantName} tape...</span>
      </div>
    `;
    
    loadingDiv.appendChild(loadingBubble);
    elements.messagesContainer.appendChild(loadingDiv);
    elements.messagesContainer.scrollTop = elements.messagesContainer.scrollHeight;
  }

  /**
   * Hide loading indicator
   */
  function hideLoading() {
    const loadingElement = document.getElementById('bmi-chat-loading');
    if (loadingElement) {
      loadingElement.remove();
    }
  }

  /**
   * Generate session ID
   */
  function generateSessionId() {
    return 'session_' + Math.random().toString(36).substr(2, 9);
  }

  /**
   * Add CSS animations
   */
  function addStyles() {
    const style = document.createElement('style');
    style.textContent = `
      @keyframes spin {
        0% { transform: rotate(0deg); }
        100% { transform: rotate(360deg); }
      }
      
      #bmi-chat-widget {
        animation: fadeIn 0.3s ease-in-out;
      }
      
      @keyframes fadeIn {
        from { opacity: 0; transform: translateY(20px); }
        to { opacity: 1; transform: translateY(0); }
      }
      
      #bmi-chat-button:hover {
        transform: scale(1.1) !important;
      }
    `;
    document.head.appendChild(style);
  }

  // Add styles when script loads
  addStyles();

  // Expose public API
  window.BMIWidget = {
    init: init,
    open: openChat,
    close: closeChat,
    sendMessage: sendMessage
  };

})(); 