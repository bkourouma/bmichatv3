#!/usr/bin/env python3
"""
Script pour vérifier le contenu des chunks du document BMI.
"""

import asyncio
import sys
from pathlib import Path

# Ajouter le répertoire parent au path pour importer les modules de l'app
sys.path.append(str(Path(__file__).parent.parent))

from app.core.database import get_db
from app.models import Document, DocumentChunk
from sqlalchemy import select
from loguru import logger


async def check_bmi_chunks():
    """Vérifie le contenu des chunks du document BMI."""
    
    try:
        async for db_session in get_db():
            # Trouver le document BMI
            stmt = select(Document).where(Document.original_filename == "Information sur BMI.pdf")
            result = await db_session.execute(stmt)
            document = result.scalar_one_or_none()
            
            if not document:
                logger.error("❌ Document BMI non trouvé")
                return False
            
            logger.info(f"📄 Document: {document.original_filename}")
            logger.info(f"📋 Statut: {document.status}")
            logger.info(f"📋 Chunks: {document.chunk_count}")
            logger.info(f"📋 Vectors: {document.vector_count}")
            
            # Récupérer les chunks
            stmt = select(DocumentChunk).where(DocumentChunk.document_id == document.id)
            result = await db_session.execute(stmt)
            chunks = result.scalars().all()
            
            logger.info(f"📦 Nombre de chunks trouvés: {len(chunks)}")
            
            for i, chunk in enumerate(chunks, 1):
                logger.info(f"\n📄 Chunk {i}:")
                logger.info(f"  - Index: {chunk.chunk_index}")
                logger.info(f"  - Longueur: {chunk.content_length} caractères")
                logger.info(f"  - Vector ID: {chunk.vector_id}")
                logger.info(f"  - Contenu:")
                logger.info("=" * 50)
                logger.info(chunk.content)
                logger.info("=" * 50)
            
            return True
            
    except Exception as e:
        logger.error(f"❌ Erreur lors de la vérification: {str(e)}")
        import traceback
        logger.error(traceback.format_exc())
        return False


if __name__ == "__main__":
    logger.info("🔍 Vérification des chunks BMI...")
    
    success = asyncio.run(check_bmi_chunks())
    
    if success:
        logger.info("✅ Vérification terminée")
    else:
        logger.error("❌ Échec de la vérification")
        sys.exit(1) 