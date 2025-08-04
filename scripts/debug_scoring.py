#!/usr/bin/env python3
"""
Script pour diagnostiquer le problème de scoring dans le système vectoriel.
"""

import asyncio
import sys
from pathlib import Path

# Ajouter le répertoire parent au path pour importer les modules de l'app
sys.path.append(str(Path(__file__).parent.parent))

from app.services.vector_service import VectorService
from app.services.embedding_service import EmbeddingService
from loguru import logger


async def debug_scoring():
    """Diagnostique le problème de scoring."""
    
    try:
        # Initialiser les services
        vector_service = VectorService()
        embedding_service = EmbeddingService()
        
        # Question de test
        query = "C'est quoi BMI"
        
        logger.info(f"🔍 Diagnostic du scoring pour: {query}")
        
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
        
        # Analyser les résultats bruts
        if 'chunks' in results and results['chunks']:
            logger.info(f"📄 Nombre de chunks trouvés: {len(results['chunks'])}")
            
            for i, (chunk, distance, metadata, score) in enumerate(zip(
                results['chunks'], 
                results.get('distances', []), 
                results.get('metadata', []), 
                results.get('scores', [])
            ), 1):
                logger.info(f"\n📄 Chunk {i}:")
                logger.info(f"  - Distance brute: {distance:.4f}")
                logger.info(f"  - Score final: {score:.4f}")
                logger.info(f"  - Similarité calculée: {1.0 - distance:.4f}")
                logger.info(f"  - Document: {metadata.get('document_name', 'Inconnu')}")
                logger.info(f"  - Chunk type: {metadata.get('chunk_type', 'regular')}")
                logger.info(f"  - Has questions: {metadata.get('has_questions', False)}")
                logger.info(f"  - Has answers: {metadata.get('has_answers', False)}")
                logger.info(f"  - Confidence: {metadata.get('confidence_score', 1.0)}")
                logger.info(f"  - Contenu (100 premiers caractères): {chunk[:100]}...")
                
                # Calculer manuellement le score
                similarity_score = 1.0 - distance
                ranking_factors = vector_service._calculate_ranking_factors(
                    chunk, metadata, similarity_score, True
                )
                final_score = vector_service._calculate_final_score(similarity_score, ranking_factors)
                
                logger.info(f"  - Score calculé manuellement: {final_score:.4f}")
                logger.info(f"  - Facteurs de ranking: {ranking_factors}")
                
                # Vérifier si le score correspond
                if abs(score - final_score) > 0.001:
                    logger.warning(f"  ⚠️ Différence de score détectée!")
                    logger.warning(f"     Score retourné: {score:.4f}")
                    logger.warning(f"     Score calculé: {final_score:.4f}")
                else:
                    logger.info(f"  ✅ Score cohérent")
        else:
            logger.warning("⚠️ Aucun chunk trouvé")
        
        return True
        
    except Exception as e:
        logger.error(f"❌ Erreur lors du diagnostic: {str(e)}")
        import traceback
        logger.error(traceback.format_exc())
        return False


if __name__ == "__main__":
    logger.info("🚀 Début du diagnostic du scoring...")
    
    success = asyncio.run(debug_scoring())
    
    if success:
        logger.info("✅ Diagnostic terminé")
    else:
        logger.error("❌ Échec du diagnostic")
        sys.exit(1) 