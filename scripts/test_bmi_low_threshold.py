#!/usr/bin/env python3
"""
Script pour tester la question "C'est quoi BMI" avec un seuil de score très bas.
"""

import asyncio
import sys
from pathlib import Path

# Ajouter le répertoire parent au path pour importer les modules de l'app
sys.path.append(str(Path(__file__).parent.parent))

from app.core.database import get_db
from app.services.retrieval_service import RetrievalService
from loguru import logger


async def test_bmi_low_threshold():
    """Teste la question 'C'est quoi BMI' avec un seuil de score très bas."""
    
    try:
        # Initialiser le service de récupération
        retrieval_service = RetrievalService()
        
        # Question à tester
        question = "C'est quoi BMI"
        
        logger.info(f"🤔 Question de test: {question}")
        
        # Obtenir une session de base de données
        async for db_session in get_db():
            # Récupérer les chunks avec un seuil très bas
            chunks = await retrieval_service.retrieve_relevant_chunks(
                query=question,
                db_session=db_session,
                k=5,
                min_relevance_score=0.0,  # Seuil très bas
                use_reranking=False  # Désactiver le re-ranking pour simplifier
            )
            
            logger.info(f"📊 Nombre de chunks trouvés: {len(chunks)}")
            
            for i, chunk in enumerate(chunks, 1):
                logger.info(f"\n📄 Chunk {i}:")
                logger.info(f"  - Score: {chunk.get('score', 0):.4f}")
                logger.info(f"  - Distance: {chunk.get('distance', 0):.4f}")
                logger.info(f"  - Document: {chunk.get('document_info', {}).get('filename', 'Inconnu')}")
                logger.info(f"  - Contenu:")
                logger.info("=" * 50)
                logger.info(chunk.get('content', 'Contenu non disponible'))
                logger.info("=" * 50)
            
            return True
            
    except Exception as e:
        logger.error(f"❌ Erreur lors du test: {str(e)}")
        import traceback
        logger.error(traceback.format_exc())
        return False


if __name__ == "__main__":
    logger.info("🚀 Début du test avec seuil bas...")
    
    success = asyncio.run(test_bmi_low_threshold())
    
    if success:
        logger.info("✅ Test terminé avec succès!")
    else:
        logger.error("❌ Échec du test")
        sys.exit(1) 