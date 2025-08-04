#!/usr/bin/env python3
"""
Script pour tester la question sur les documents nécessaires pour ouvrir un compte TrésorMoney.
"""

import asyncio
import sys
from pathlib import Path

# Ajouter le répertoire parent au path pour importer les modules de l'app
sys.path.append(str(Path(__file__).parent.parent))

from app.core.database import get_db
from app.services.chat_service import ChatService
from loguru import logger


async def test_tresormoney_question():
    """Teste la question sur les documents nécessaires pour ouvrir un compte TrésorMoney."""
    
    try:
        # Initialiser le service de chat
        chat_service = ChatService()
        
        # Question à tester
        question = "Quels sont les documents nécessaires pour ouvrir un compte TrésorMoney"
        
        logger.info(f"🤔 Question de test: {question}")
        
        # Obtenir une session de base de données
        async for db_session in get_db():
            # Traiter la question
            response = await chat_service.process_chat_message(
                message=question,
                session_id="test_tresormoney_session",
                user_id="test_user",
                db_session=db_session
            )
            
            logger.info("📝 Réponse du système:")
            logger.info("=" * 50)
            logger.info(response.get("response", "Aucune réponse"))
            logger.info("=" * 50)
            
            # Afficher les sources utilisées
            sources = response.get("sources", [])
            if sources:
                logger.info("📚 Sources utilisées:")
                for i, source in enumerate(sources, 1):
                    logger.info(f"   {i}. {source}")
            else:
                logger.info("📚 Aucune source utilisée")
            
            # Afficher les métriques
            metrics = response.get("metrics", {})
            if metrics:
                logger.info("📊 Métriques:")
                logger.info(f"   - Temps de réponse: {metrics.get('response_time_ms', 0)}ms")
                logger.info(f"   - Tokens utilisés: {metrics.get('tokens_used', 0)}")
                logger.info(f"   - Coût: ${metrics.get('cost', 0):.6f}")
                logger.info(f"   - Chunks récupérés: {metrics.get('chunks_retrieved', 0)}")
        
        return True
        
    except Exception as e:
        logger.error(f"❌ Erreur lors du test: {str(e)}")
        import traceback
        logger.error(traceback.format_exc())
        return False


if __name__ == "__main__":
    logger.info("🚀 Début du test de la question TrésorMoney...")
    
    success = asyncio.run(test_tresormoney_question())
    
    if success:
        logger.info("✅ Test terminé avec succès!")
    else:
        logger.error("❌ Échec du test")
        sys.exit(1) 