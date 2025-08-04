#!/usr/bin/env python3
"""
Script pour vérifier les embeddings des chunks BMI.
"""

import asyncio
import sys
from pathlib import Path

# Ajouter le répertoire parent au path pour importer les modules de l'app
sys.path.append(str(Path(__file__).parent.parent))

from app.services.vector_service import VectorService
from app.core.database import get_db
from app.models import Document, DocumentChunk
from sqlalchemy import select
from loguru import logger


async def check_bmi_embeddings():
    """Vérifie les embeddings des chunks BMI."""
    
    try:
        # Initialiser le service vectoriel
        vector_service = VectorService()
        await vector_service.initialize()
        
        # Trouver le document BMI
        async for db_session in get_db():
            stmt = select(Document).where(Document.original_filename == "Information sur BMI.pdf")
            result = await db_session.execute(stmt)
            document = result.scalar_one_or_none()
            
            if not document:
                logger.error("❌ Document BMI non trouvé")
                return False
            
            logger.info(f"📄 Document BMI trouvé: {document.id}")
            
            # Récupérer les chunks du document
            stmt = select(DocumentChunk).where(DocumentChunk.document_id == document.id)
            result = await db_session.execute(stmt)
            chunks = result.scalars().all()
            
            logger.info(f"📦 Nombre de chunks dans la DB: {len(chunks)}")
            
            # Vérifier chaque chunk dans la base vectorielle
            for i, chunk in enumerate(chunks):
                logger.info(f"\n📄 Chunk {i+1}:")
                logger.info(f"  - Vector ID: {chunk.vector_id}")
                logger.info(f"  - Contenu (100 premiers caractères): {chunk.content[:100]}...")
                
                # Vérifier si le chunk est dans la base vectorielle
                try:
                    results = vector_service.collection.get(
                        ids=[chunk.vector_id]
                    )
                    
                    if results["ids"]:
                        logger.info(f"  ✅ Chunk trouvé dans la base vectorielle")
                        logger.info(f"  - Document ID: {results['metadatas'][0].get('document_id', 'Inconnu')}")
                        logger.info(f"  - Filename: {results['metadatas'][0].get('filename', 'Inconnu')}")
                        
                        # Vérifier si l'embedding existe
                        if "embeddings" in results and results["embeddings"]:
                            embedding = results["embeddings"][0]
                            logger.info(f"  - Embedding: {len(embedding)} dimensions")
                            logger.info(f"  - Premiers 5 valeurs: {embedding[:5]}")
                        else:
                            logger.warning(f"  ⚠️ Pas d'embedding trouvé")
                            
                    else:
                        logger.warning(f"  ⚠️ Chunk NON trouvé dans la base vectorielle")
                        
                except Exception as e:
                    logger.error(f"  ❌ Erreur lors de la vérification: {str(e)}")
            
            # Tester une recherche directe par document_id
            logger.info(f"\n🔍 Test de recherche par document_id...")
            try:
                results = vector_service.collection.get(
                    where={"document_id": document.id}
                )
                
                if results["ids"]:
                    logger.info(f"✅ {len(results['ids'])} chunks trouvés par document_id")
                    for i, (chunk_id, metadata) in enumerate(zip(results["ids"], results["metadatas"])):
                        logger.info(f"  {i+1}. ID: {chunk_id}")
                        logger.info(f"     Filename: {metadata.get('filename', 'Inconnu')}")
                        logger.info(f"     Chunk index: {metadata.get('chunk_index', 'Inconnu')}")
                else:
                    logger.warning("⚠️ Aucun chunk trouvé par document_id")
                    
            except Exception as e:
                logger.error(f"❌ Erreur lors de la recherche par document_id: {str(e)}")
        
        return True
        
    except Exception as e:
        logger.error(f"❌ Erreur lors de la vérification: {str(e)}")
        import traceback
        logger.error(traceback.format_exc())
        return False


if __name__ == "__main__":
    logger.info("🚀 Vérification des embeddings BMI...")
    
    success = asyncio.run(check_bmi_embeddings())
    
    if success:
        logger.info("✅ Vérification terminée")
    else:
        logger.error("❌ Échec de la vérification")
        sys.exit(1) 