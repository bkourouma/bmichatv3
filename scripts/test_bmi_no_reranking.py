#!/usr/bin/env python3
"""
Script pour tester la question BMI sans re-ranking.
"""

import asyncio
import sys
from pathlib import Path

# Ajouter le répertoire parent au path pour importer les modules de l'app
sys.path.append(str(Path(__file__).parent.parent))

from app.core.database import get_db
from app.services.retrieval_service import RetrievalService
from loguru import logger


async def test_bmi_no_reranking():
    """Teste la question BMI sans re-ranking."""
    
    try:
        # Initialiser le service de récupération
        retrieval_service = RetrievalService()
        
        # Question de test
        question = "C'est quoi BMI"
        
        logger.info(f"🤔 Question de test: {question}")
        
        # Obtenir une session de base de données
        async for db_session in get_db():
            # Récupérer les chunks sans re-ranking
            chunks = await retrieval_service.retrieve_relevant_chunks(
                query=question,
                db_session=db_session,
                k=5,
                use_reranking=False,  # Désactiver le re-ranking
                min_relevance_score=0.0  # Seuil très bas
            )
            
            logger.info(f"📊 Nombre de chunks trouvés: {len(chunks)}")
            
            if chunks:
                logger.info("📝 Chunks trouvés:")
                for i, chunk in enumerate(chunks, 1):
                    logger.info(f"\n📄 Chunk {i}:")
                    logger.info(f"  - Score: {chunk.get('score', 0):.4f}")
                    logger.info(f"  - Document: {chunk.get('document_info', {}).get('filename', 'Inconnu')}")
                    logger.info(f"  - Contenu (200 premiers caractères): {chunk.get('content', '')[:200]}...")
                    
                    # Vérifier si c'est un chunk BMI
                    doc_id = chunk.get('metadata', {}).get('document_id', '')
                    if '99eee4da-b44e-49dd-b553-a862b83c8ccd' in doc_id:
                        logger.info("  ✅ C'est un chunk BMI!")
                    else:
                        logger.info("  ❌ Ce n'est pas un chunk BMI")
            else:
                logger.warning("⚠️ Aucun chunk trouvé")
        
        return True
        
    except Exception as e:
        logger.error(f"❌ Erreur lors du test: {str(e)}")
        import traceback
        logger.error(traceback.format_exc())
        return False


if __name__ == "__main__":
    logger.info("🚀 Début du test sans re-ranking...")
    
    success = asyncio.run(test_bmi_no_reranking())
    
    if success:
        logger.info("✅ Test terminé")
    else:
        logger.error("❌ Échec du test")
        sys.exit(1) 