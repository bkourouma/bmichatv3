"""
BMI Chat Application - Widget Router

This module provides widget-specific endpoints for the embeddable chat widget.
Handles widget configuration, chat requests, and static file serving.
"""

from typing import Dict, Any, Optional

from fastapi import APIRouter, HTTPException, status, Depends, Response
from fastapi.responses import FileResponse
from pydantic import BaseModel, Field
from sqlalchemy.ext.asyncio import AsyncSession
from loguru import logger
import os

from app.config import settings
from app.core.exceptions import ValidationError
from app.services.chat_service import ChatService
from app.core.database import get_db


router = APIRouter()

# Initialize chat service
chat_service = ChatService()


class WidgetChatRequest(BaseModel):
    """Widget chat request model."""
    message: str = Field(..., min_length=1, max_length=2000, description="User message")
    session_id: Optional[str] = Field(None, description="Widget session ID")
    widget_key: Optional[str] = Field(None, description="Widget authentication key")


class WidgetChatResponse(BaseModel):
    """Widget chat response model."""
    message: str = Field(..., description="Assistant response")
    session_id: str = Field(..., description="Widget session ID")
    timestamp: str = Field(..., description="Response timestamp")


class WidgetConfig(BaseModel):
    """Widget configuration model."""
    position: str = Field(..., description="Widget position (left/right)")
    accent_color: str = Field(..., description="Widget accent color")
    company_name: str = Field(..., description="Company name")
    assistant_name: str = Field(..., description="Assistant name")
    welcome_message: str = Field(..., description="Welcome message")
    enabled: bool = Field(..., description="Widget enabled status")


@router.post("/chat", response_model=WidgetChatResponse, summary="Widget chat")
async def widget_chat(
    request: WidgetChatRequest,
    db: AsyncSession = Depends(get_db)
) -> WidgetChatResponse:
    """
    Process chat message from embedded widget.
    
    Args:
        request: Widget chat request
        
    Returns:
        WidgetChatResponse with AI response
        
    Raises:
        HTTPException: If chat processing fails
    """
    try:
        logger.info(f"🔧 Widget chat message: {request.message[:50]}...")

        # Validate request
        if not request.message.strip():
            raise ValidationError("Message cannot be empty")

        # Generate session ID if not provided
        from uuid import uuid4
        session_id = request.session_id or str(uuid4())

        # Process chat message using chat service
        response_data = await chat_service.process_chat_message(
            message=request.message,
            session_id=session_id,
            db_session=db,
            user_id=None,  # Anonymous widget users
            keywords_filter=None,  # No keyword filtering for widget
            use_history=True,
            max_context_chunks=3  # Limit context for widget responses
        )

        # Convert to widget response format
        response = WidgetChatResponse(
            message=response_data["message"],
            session_id=response_data["session_id"],
            timestamp=response_data["timestamp"]
        )

        logger.info(f"✅ Widget chat response generated for session {session_id}")
        return response
        
    except ValidationError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid request"
        )
    except Exception as e:
        logger.error(f"❌ Widget chat processing failed: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Chat processing failed"
        )


@router.get("/config", response_model=WidgetConfig, summary="Get widget configuration")
async def get_widget_config() -> WidgetConfig:
    """
    Get widget configuration settings.
    
    Returns:
        WidgetConfig with current settings
    """
    try:
        logger.info("⚙️ Getting widget configuration")
        
        config = WidgetConfig(
            position=settings.widget_default_position,
            accent_color=settings.widget_default_accent_color,
            company_name=settings.widget_default_company_name,
            assistant_name=settings.widget_default_assistant_name,
            welcome_message=settings.widget_default_welcome_message,
            enabled=True
        )
        
        return config
        
    except Exception as e:
        logger.error(f"❌ Failed to get widget configuration: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to get widget configuration"
        )


@router.get("/health", summary="Widget health check")
async def widget_health() -> Dict[str, Any]:
    """
    Widget-specific health check.
    
    Returns:
        Dict with widget status
    """
    try:
        from datetime import datetime
        
        return {
            "status": "healthy",
            "timestamp": datetime.utcnow().isoformat(),
            "widget_enabled": True,
            "assistant_name": settings.widget_default_assistant_name,
            "company_name": settings.widget_default_company_name
        }
        
    except Exception as e:
        logger.error(f"❌ Widget health check failed: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Widget health check failed"
        )


@router.get("/status", summary="Widget status")
async def widget_status() -> Dict[str, Any]:
    """
    Get widget operational status.
    
    Returns:
        Dict with widget operational information
    """
    try:
        from datetime import datetime
        
        # TODO: Add actual status checks (document count, etc.)
        
        return {
            "status": "operational",
            "timestamp": datetime.utcnow().isoformat(),
            "documents_available": 0,  # TODO: Get actual count
            "last_updated": datetime.utcnow().isoformat(),
            "version": settings.app_version
        }
        
    except Exception as e:
        logger.error(f"❌ Failed to get widget status: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to get widget status"
        )


@router.get("/chat-widget.js", summary="Serve widget JavaScript")
async def serve_widget_js() -> Response:
    """
    Serve the widget JavaScript file.
    
    Returns:
        JavaScript file content
    """
    try:
        # Path to the widget JavaScript file
        widget_path = os.path.join(os.path.dirname(__file__), "..", "..", "widget", "dist", "chat-widget.js")
        
        # Fallback to source file if dist doesn't exist
        if not os.path.exists(widget_path):
            widget_path = os.path.join(os.path.dirname(__file__), "..", "..", "widget", "src", "chat-widget.js")
        
        if os.path.exists(widget_path):
            return FileResponse(
                widget_path,
                media_type="application/javascript",
                headers={"Cache-Control": "public, max-age=3600"}
            )
        else:
            # Return a basic widget if file doesn't exist
            basic_widget = '''
// BMI Chat Widget - Basic Version
(function() {
    'use strict';
    
    window.BMIWidget = {
        init: function(options) {
            console.log('BMI Chat Widget initialized with options:', options);
            // Basic widget implementation
            const button = document.createElement('div');
            button.style.cssText = `
                position: fixed;
                right: 20px;
                bottom: 20px;
                width: 60px;
                height: 60px;
                background: ${options.accentColor || '#3b82f6'};
                border-radius: 50%;
                display: flex;
                align-items: center;
                justify-content: center;
                cursor: pointer;
                z-index: 9999;
                box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
            `;
            button.innerHTML = '<svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="2"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/></svg>';
            button.onclick = function() {
                alert('BMI Chat Widget - Version de démonstration\\n\\nFonctionnalités complètes disponibles dans la version finale.');
            };
            document.body.appendChild(button);
        }
    };
})();
'''
            return Response(
                content=basic_widget,
                media_type="application/javascript",
                headers={"Cache-Control": "public, max-age=3600"}
            )
            
    except Exception as e:
        logger.error(f"❌ Failed to serve widget JavaScript: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to serve widget JavaScript"
        )
