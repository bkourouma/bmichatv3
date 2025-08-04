#!/usr/bin/env python3
"""
Script pour forcer le traitement du document "Information sur BMI".
"""

import asyncio
import sys
from pathlib import Path

# Ajouter le répertoire parent au path pour importer les modules de l'app
sys.path.append(str(Path(__file__).parent.parent))

from app.core.database import get_db
from app.models import Document, DocumentStatus
from app.services.document_service import DocumentProcessor
from sqlalchemy import select
from loguru import logger


async def force_process_bmi_document():
    """Force le traitement du document BMI."""
    
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
            
            # Forcer le traitement
            logger.info("🔄 Début du traitement forcé du document...")
            
            # Marquer comme en cours de traitement
            document.status = DocumentStatus.PROCESSING
            await db_session.commit()
            
            # Utiliser le DocumentProcessor directement
            processor = DocumentProcessor()
            
            # Traiter le document de manière synchrone
            try:
                # Extraire le texte
                text_content, metadata = await processor._extract_text(document)
                logger.info(f"📝 Texte extrait: {len(text_content)} caractères")
                
                # Créer les chunks
                chunks_with_metadata = await processor._create_chunks(document, text_content)
                logger.info(f"📦 Chunks créés: {len(chunks_with_metadata)}")
                
                # Générer les embeddings
                embeddings = await processor._generate_embeddings(chunks_with_metadata)
                logger.info(f"🧠 Embeddings générés: {len(embeddings)}")
                
                # Stocker les vectors
                await processor._store_vectors(document, chunks_with_metadata, embeddings)
                logger.info("💾 Vectors stockés")
                
                # Sauvegarder les chunks
                await processor._save_chunks(document, chunks_with_metadata, db_session)
                logger.info("💾 Chunks sauvegardés")
                
                # Marquer comme traité
                document.status = DocumentStatus.PROCESSED
                document.chunk_count = len(chunks_with_metadata)
                document.vector_count = len(embeddings)
                await db_session.commit()
                
                logger.info("✅ Document traité avec succès!")
                logger.info(f"📋 Nouveau statut: {document.status}")
                logger.info(f"📋 Nombre de chunks: {document.chunk_count}")
                logger.info(f"📋 Nombre de vectors: {document.vector_count}")
                
                return True
                
            except Exception as e:
                logger.error(f"❌ Erreur lors du traitement: {str(e)}")
                document.status = DocumentStatus.FAILED
                document.processing_error = str(e)
                await db_session.commit()
                return False
            
    except Exception as e:
        logger.error(f"❌ Erreur lors du traitement: {str(e)}")
        import traceback
        logger.error(traceback.format_exc())
        return False


if __name__ == "__main__":
    logger.info("🚀 Début du traitement forcé du document BMI...")
    
    success = asyncio.run(force_process_bmi_document())
    
    if success:
        logger.info("✅ Traitement forcé terminé avec succès!")
    else:
        logger.error("❌ Échec du traitement forcé")
        sys.exit(1) 