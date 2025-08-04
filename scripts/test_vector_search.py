#!/usr/bin/env python3
"""
Script pour tester directement la recherche vectorielle avec la question "C'est quoi BMI".
"""

import asyncio
import sys
from pathlib import Path

# Ajouter le répertoire parent au path pour importer les modules de l'app
sys.path.append(str(Path(__file__).parent.parent))

from app.services.vector_service import VectorService
from app.services.embedding_service import EmbeddingService
from loguru import logger


async def test_vector_search():
    """Teste directement la recherche vectorielle."""
    
    try:
        # Initialiser les services
        vector_service = VectorService()
        embedding_service = EmbeddingService()
        
        # Question de test
        query = "C'est quoi BMI"
        
        logger.info(f"🔍 Test de recherche vectorielle pour: {query}")
        
        # Générer l'embedding de la question
        logger.info("🧠 Génération de l'embedding de la question...")
        query_embedding = await embedding_service.generate_embeddings([query])
        
        if not query_embedding:
            logger.error("❌ Échec de la génération de l'embedding")
            return False
        
        logger.info(f"✅ Embedding généré: {len(query_embedding[0])} dimensions")
        
        # Initialiser la base vectorielle
        await vector_service.initialize()
        
        # Rechercher des chunks similaires
        logger.info("🔍 Recherche de chunks similaires...")
        results = await vector_service.search_similar_chunks(
            query_embedding[0],
            k=5,
            filter_metadata=None
        )
        
        logger.info(f"📊 Structure des résultats: {list(results.keys())}")
        
        # Afficher les chunks
        if 'chunks' in results and results['chunks']:
            logger.info(f"📄 Nombre de chunks trouvés: {len(results['chunks'])}")
            
            for i, (chunk, metadata, score) in enumerate(zip(results['chunks'], results.get('metadata', []), results.get('scores', [])), 1):
                logger.info(f"\n📄 Chunk {i}:")
                logger.info(f"  - Score: {score:.4f}")
                logger.info(f"  - Document: {metadata.get('document_name', 'Inconnu')}")
                logger.info(f"  - Chunk ID: {metadata.get('chunk_id', 'Inconnu')}")
                logger.info(f"  - Contenu:")
                logger.info("=" * 50)
                logger.info(chunk)
                logger.info("=" * 50)
        else:
            logger.warning("⚠️ Aucun chunk trouvé")
        
        return True
        
    except Exception as e:
        logger.error(f"❌ Erreur lors du test: {str(e)}")
        import traceback
        logger.error(traceback.format_exc())
        return False


if __name__ == "__main__":
    logger.info("🚀 Début du test de recherche vectorielle...")
    
    success = asyncio.run(test_vector_search())
    
    if success:
        logger.info("✅ Test terminé avec succès!")
    else:
        logger.error("❌ Échec du test")
        sys.exit(1) 