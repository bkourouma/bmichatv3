#!/usr/bin/env python3
"""
Script pour diagnostiquer le problème de re-ranking.
"""

import asyncio
import sys
from pathlib import Path

# Ajouter le répertoire parent au path pour importer les modules de l'app
sys.path.append(str(Path(__file__).parent.parent))

from app.services.vector_service import VectorService
from app.services.embedding_service import EmbeddingService
from app.services.reranking_service import ReRankingService
from loguru import logger


async def debug_reranking():
    """Diagnostique le problème de re-ranking."""
    
    try:
        # Initialiser les services
        vector_service = VectorService()
        embedding_service = EmbeddingService()
        reranking_service = ReRankingService()
        
        # Question de test
        query = "C'est quoi BMI"
        
        logger.info(f"🔍 Diagnostic du re-ranking pour: {query}")
        
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
        
        logger.info(f"📊 Nombre de chunks trouvés: {len(results['chunks'])}")
        
        # Préparer les chunks pour le re-ranking
        chunks_for_reranking = []
        for i, (chunk, score, metadata) in enumerate(zip(
            results['chunks'], 
            results.get('scores', []), 
            results.get('metadata', [])
        )):
            chunk_data = {
                "content": chunk,
                "score": score,
                "metadata": metadata,
                "id": results['ids'][i] if i < len(results['ids']) else f"chunk_{i}"
            }
            chunks_for_reranking.append(chunk_data)
            logger.info(f"📄 Chunk {i+1}: Score vectoriel = {score:.4f}")
        
        # Tester le re-ranking
        logger.info("🔄 Test du re-ranking...")
        reranked_chunks = await reranking_service.rerank_chunks(
            query=query,
            chunks=chunks_for_reranking,
            top_k=5,
            min_score=0.0  # Seuil très bas pour voir tous les résultats
        )
        
        logger.info(f"📊 Nombre de chunks après re-ranking: {len(reranked_chunks)}")
        
        for i, chunk in enumerate(reranked_chunks, 1):
            logger.info(f"\n📄 Chunk re-ranké {i}:")
            logger.info(f"  - Score original: {chunk.get('original_score', 0):.4f}")
            logger.info(f"  - Score re-ranking: {chunk.get('rerank_score', 0):.4f}")
            logger.info(f"  - Score combiné: {chunk.get('combined_score', 0):.4f}")
            logger.info(f"  - Contenu (100 premiers caractères): {chunk.get('content', '')[:100]}...")
        
        return True
        
    except Exception as e:
        logger.error(f"❌ Erreur lors du diagnostic: {str(e)}")
        import traceback
        logger.error(traceback.format_exc())
        return False


if __name__ == "__main__":
    logger.info("🚀 Début du diagnostic du re-ranking...")
    
    success = asyncio.run(debug_reranking())
    
    if success:
        logger.info("✅ Diagnostic terminé")
    else:
        logger.error("❌ Échec du diagnostic")
        sys.exit(1) 