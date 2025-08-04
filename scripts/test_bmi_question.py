#!/usr/bin/env python3
"""
Script pour tester la question "C'est quoi BMI" avec le système de chat.
"""

import asyncio
import sys
from pathlib import Path

# Ajouter le répertoire parent au path pour importer les modules de l'app
sys.path.append(str(Path(__file__).parent.parent))

from app.core.database import get_db
from app.services.chat_service import ChatService
from loguru import logger


async def test_bmi_question():
    """Teste la question 'C'est quoi BMI' avec le système de chat."""
    
    try:
        # Initialiser le service de chat
        chat_service = ChatService()
        
        # Question à tester
        question = "C'est quoi BMI"
        
        logger.info(f"🤔 Question de test: {question}")
        
        # Obtenir une session de base de données
        async for db_session in get_db():
            # Créer un ID de session unique
            session_id = "test_bmi_session"
            
            # Traiter le message
            response = await chat_service.process_chat_message(
                message=question,
                session_id=session_id,
                db_session=db_session,
                use_history=False  # Pas d'historique pour ce test
            )
            
            logger.info("📝 Réponse du système:")
            logger.info("=" * 50)
            logger.info(response.get('answer', 'Aucune réponse'))
            logger.info("=" * 50)
            
            # Afficher les métadonnées
            if 'metadata' in response:
                metadata = response['metadata']
                logger.info("📊 Métadonnées:")
                logger.info(f"  - Temps de traitement: {metadata.get('processing_time', 0):.2f}s")
                logger.info(f" - Tokens utilisés: {metadata.get('total_tokens', 0)}")
                logger.info(f" - Coût estimé: ${metadata.get('estimated_cost', 0):.4f}")
                logger.info(f" - Stratégie de récupération: {metadata.get('retrieval_strategy', 'N/A')}")
            
            # Afficher les sources utilisées
            if 'sources' in response:
                logger.info("📚 Sources utilisées:")
                for i, source in enumerate(response['sources'], 1):
                    logger.info(f"  {i}. {source.get('document_name', 'Document inconnu')}")
                    logger.info(f"     Chunk: {source.get('chunk_text', '')[:100]}...")
            
            return True
            
    except Exception as e:
        logger.error(f"❌ Erreur lors du test: {str(e)}")
        import traceback
        logger.error(traceback.format_exc())
        return False


if __name__ == "__main__":
    logger.info("🚀 Début du test de la question BMI...")
    
    success = asyncio.run(test_bmi_question())
    
    if success:
        logger.info("✅ Test terminé avec succès!")
    else:
        logger.error("❌ Échec du test")
        sys.exit(1) 