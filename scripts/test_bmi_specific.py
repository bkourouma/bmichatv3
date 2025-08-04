#!/usr/bin/env python3
"""
Script pour tester avec des questions plus spécifiques sur BMI.
"""

import asyncio
import sys
from pathlib import Path

# Ajouter le répertoire parent au path pour importer les modules de l'app
sys.path.append(str(Path(__file__).parent.parent))

from app.services.vector_service import VectorService
from app.services.embedding_service import EmbeddingService
from loguru import logger


async def test_bmi_specific():
    """Teste avec des questions plus spécifiques sur BMI."""
    
    try:
        # Initialiser les services
        vector_service = VectorService()
        embedding_service = EmbeddingService()
        
        # Questions de test plus spécifiques
        test_questions = [
            "C'est quoi BMI",
            "Qu'est-ce que BMI-WFS",
            "Business Management Invest",
            "BMI-CI Finances SA",
            "société ivoirienne du secteur privé",
            "créée en 2016",
            "Innocent Sécongo",
            "fintech africaine"
        ]
        
        await vector_service.initialize()
        
        for question in test_questions:
            logger.info(f"\n🔍 Test avec la question: {question}")
            
            # Générer l'embedding de la question
            query_embedding = await embedding_service.generate_embeddings([question])
            
            if not query_embedding:
                logger.error("❌ Échec de la génération de l'embedding")
                continue
            
            # Rechercher des chunks similaires
            results = await vector_service.search_similar_chunks(
                query_embedding[0],
                k=10,
                filter_metadata=None
            )
            
            logger.info(f"📊 Nombre de chunks trouvés: {len(results['chunks'])}")
            
            # Chercher spécifiquement les chunks BMI
            bmi_chunks_found = []
            for i, (chunk, metadata) in enumerate(zip(results['chunks'], results.get('metadata', []))):
                document_id = metadata.get('document_id', '')
                if '99eee4da-b44e-49dd-b553-a862b83c8ccd' in document_id:
                    bmi_chunks_found.append({
                        'index': i,
                        'score': results['scores'][i] if i < len(results['scores']) else 0.0,
                        'content': chunk[:100] + "..." if len(chunk) > 100 else chunk
                    })
            
            if bmi_chunks_found:
                logger.info(f"✅ {len(bmi_chunks_found)} chunks BMI trouvés!")
                for chunk_info in bmi_chunks_found:
                    logger.info(f"  - Score: {chunk_info['score']:.4f}")
                    logger.info(f"  - Contenu: {chunk_info['content']}")
            else:
                logger.warning("❌ Aucun chunk BMI trouvé")
        
        return True
        
    except Exception as e:
        logger.error(f"❌ Erreur lors du test: {str(e)}")
        import traceback
        logger.error(traceback.format_exc())
        return False


if __name__ == "__main__":
    logger.info("🚀 Début du test avec des questions spécifiques...")
    
    success = asyncio.run(test_bmi_specific())
    
    if success:
        logger.info("✅ Test terminé")
    else:
        logger.error("❌ Échec du test")
        sys.exit(1) 