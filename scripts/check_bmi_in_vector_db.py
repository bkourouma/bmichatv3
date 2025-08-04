#!/usr/bin/env python3
"""
Script pour vérifier si les chunks BMI sont bien dans la base vectorielle.
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


async def check_bmi_in_vector_db():
    """Vérifie si les chunks BMI sont dans la base vectorielle."""
    
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
                        logger.info(f"  - Document name: {results['metadatas'][0].get('document_name', 'Inconnu')}")
                    else:
                        logger.warning(f"  ⚠️ Chunk NON trouvé dans la base vectorielle")
                        
                except Exception as e:
                    logger.error(f"  ❌ Erreur lors de la vérification: {str(e)}")
        
        return True
        
    except Exception as e:
        logger.error(f"❌ Erreur lors de la vérification: {str(e)}")
        import traceback
        logger.error(traceback.format_exc())
        return False


if __name__ == "__main__":
    logger.info("🚀 Vérification des chunks BMI dans la base vectorielle...")
    
    success = asyncio.run(check_bmi_in_vector_db())
    
    if success:
        logger.info("✅ Vérification terminée")
    else:
        logger.error("❌ Échec de la vérification")
        sys.exit(1) 