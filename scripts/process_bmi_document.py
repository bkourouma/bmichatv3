#!/usr/bin/env python3
"""
Script pour traiter le document "Information sur BMI" qui est encore au statut UPLOADED.
"""

import asyncio
import sys
from pathlib import Path

# Ajouter le répertoire parent au path pour importer les modules de l'app
sys.path.append(str(Path(__file__).parent.parent))

from app.core.database import get_db
from app.models import Document, DocumentStatus
from app.services.document_manager import DocumentManager
from sqlalchemy import select
from loguru import logger


async def process_bmi_document():
    """Traite le document BMI qui est encore au statut UPLOADED."""
    
    try:
        async for db_session in get_db():
            # Trouver le document BMI
            stmt = select(Document).where(Document.original_filename == "Information sur BMI.pdf")
            result = await db_session.execute(stmt)
            document = result.scalar_one_or_none()
            
            if not document:
                logger.error("❌ Document BMI non trouvé")
                return False
            
            logger.info(f"📄 Document trouvé: {document.original_filename}")
            logger.info(f"📋 ID: {document.id}")
            logger.info(f"📋 Statut actuel: {document.status}")
            
            if document.status == DocumentStatus.PROCESSED:
                logger.info("✅ Document déjà traité")
                return True
            
            # Traiter le document
            logger.info("🔄 Début du traitement du document...")
            
            document_manager = DocumentManager()
            
            # Reprocesser le document
            success = await document_manager.reprocess_document(
                document_id=document.id,
                db_session=db_session
            )
            
            if success:
                logger.info("✅ Document traité avec succès!")
                
                # Vérifier le nouveau statut
                await db_session.refresh(document)
                logger.info(f"📋 Nouveau statut: {document.status}")
                logger.info(f"📋 Nombre de chunks: {document.chunk_count}")
                logger.info(f"📋 Nombre de vectors: {document.vector_count}")
                
                return True
            else:
                logger.error("❌ Échec du traitement du document")
                return False
            
    except Exception as e:
        logger.error(f"❌ Erreur lors du traitement: {str(e)}")
        import traceback
        logger.error(traceback.format_exc())
        return False


if __name__ == "__main__":
    logger.info("🚀 Début du traitement du document BMI...")
    
    success = asyncio.run(process_bmi_document())
    
    if success:
        logger.info("✅ Traitement terminé avec succès!")
    else:
        logger.error("❌ Échec du traitement")
        sys.exit(1) 