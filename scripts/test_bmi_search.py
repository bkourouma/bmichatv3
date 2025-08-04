#!/usr/bin/env python3
"""
Script pour tester directement la recherche avec les chunks BMI.
"""

import asyncio
import sys
from pathlib import Path

# Ajouter le répertoire parent au path pour importer les modules de l'app
sys.path.append(str(Path(__file__).parent.parent))

from app.services.vector_service import VectorService
from app.services.embedding_service import EmbeddingService
from loguru import logger


async def test_bmi_search():
    """Teste directement la recherche avec les chunks BMI."""
    
    try:
        # Initialiser les services
        vector_service = VectorService()
        embedding_service = EmbeddingService()
        
        # Question de test
        query = "C'est quoi BMI"
        
        logger.info(f"🔍 Test de recherche directe pour: {query}")
        
        # Générer l'embedding de la question
        logger.info("🧠 Génération de l'embedding de la question...")
        query_embedding = await embedding_service.generate_embeddings([query])
        
        if not query_embedding:
            logger.error("❌ Échec de la génération de l'embedding")
            return False
        
        logger.info(f"✅ Embedding généré: {len(query_embedding[0])} dimensions")
        
        # Initialiser la base vectorielle
        await vector_service.initialize()
        
        # Rechercher avec un k plus élevé pour voir plus de résultats
        logger.info("🔍 Recherche de chunks similaires avec k=20...")
        results = await vector_service.search_similar_chunks(
            query_embedding[0],
            k=20,
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
                    'chunk': chunk,
                    'metadata': metadata,
                    'score': results['scores'][i] if i < len(results['scores']) else 0.0
                })
        
        logger.info(f"📄 Chunks BMI trouvés: {len(bmi_chunks_found)}")
        
        for chunk_info in bmi_chunks_found:
            logger.info(f"\n📄 Chunk BMI #{chunk_info['index']+1}:")
            logger.info(f"  - Score: {chunk_info['score']:.4f}")
            logger.info(f"  - Document ID: {chunk_info['metadata'].get('document_id', 'Inconnu')}")
            logger.info(f"  - Filename: {chunk_info['metadata'].get('filename', 'Inconnu')}")
            logger.info(f"  - Contenu (100 premiers caractères): {chunk_info['chunk'][:100]}...")
        
        # Si aucun chunk BMI n'est trouvé, vérifier tous les chunks
        if not bmi_chunks_found:
            logger.warning("⚠️ Aucun chunk BMI trouvé dans les résultats")
            logger.info("📋 Tous les chunks trouvés:")
            for i, (chunk, metadata) in enumerate(zip(results['chunks'], results.get('metadata', []))):
                logger.info(f"  {i+1}. Document ID: {metadata.get('document_id', 'Inconnu')}")
                logger.info(f"     Filename: {metadata.get('filename', 'Inconnu')}")
                logger.info(f"     Score: {results['scores'][i] if i < len(results['scores']) else 0.0:.4f}")
                logger.info(f"     Contenu: {chunk[:50]}...")
        
        return True
        
    except Exception as e:
        logger.error(f"❌ Erreur lors du test: {str(e)}")
        import traceback
        logger.error(traceback.format_exc())
        return False


if __name__ == "__main__":
    logger.info("🚀 Début du test de recherche BMI...")
    
    success = asyncio.run(test_bmi_search())
    
    if success:
        logger.info("✅ Test terminé")
    else:
        logger.error("❌ Échec du test")
        sys.exit(1) 