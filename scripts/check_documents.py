#!/usr/bin/env python3
"""
Script pour vérifier l'état des documents dans la base de données.
"""

import asyncio
import sys
from pathlib import Path

# Ajouter le répertoire parent au path pour importer les modules de l'app
sys.path.append(str(Path(__file__).parent.parent))

from app.core.database import get_db
from app.models import Document, DocumentStatus
from sqlalchemy import select
from loguru import logger


async def check_documents():
    """Vérifie l'état des documents dans la base de données."""
    
    try:
        async for db_session in get_db():
            # Récupérer tous les documents
            stmt = select(Document)
            result = await db_session.execute(stmt)
            documents = result.scalars().all()
            
            logger.info(f"📋 Nombre total de documents: {len(documents)}")
            
            if not documents:
                logger.warning("⚠️ Aucun document trouvé dans la base de données")
                return False
            
            # Afficher les détails de chaque document
            for i, doc in enumerate(documents, 1):
                logger.info(f"\n📄 Document {i}:")
                logger.info(f"  - ID: {doc.id}")
                logger.info(f"  - Nom: {doc.original_filename}")
                logger.info(f"  - Type: {doc.file_type}")
                logger.info(f"  - Statut: {doc.status}")
                logger.info(f"  - Taille: {doc.file_size} bytes")
                logger.info(f"  - Chunks: {doc.chunk_count}")
                logger.info(f"  - Vectors: {doc.vector_count}")
                logger.info(f"  - Créé: {doc.created_at}")
                
                # Vérifier si le document est traité
                if doc.status == DocumentStatus.PROCESSED:
                    logger.info("  ✅ Document traité avec succès")
                elif doc.status == DocumentStatus.PROCESSING:
                    logger.warning("  ⏳ Document en cours de traitement")
                elif doc.status == DocumentStatus.FAILED:
                    logger.error("  ❌ Document en erreur")
                else:
                    logger.warning(f"  ⚠️ Statut inconnu: {doc.status}")
            
            return True
            
    except Exception as e:
        logger.error(f"❌ Erreur lors de la vérification: {str(e)}")
        import traceback
        logger.error(traceback.format_exc())
        return False


if __name__ == "__main__":
    logger.info("🔍 Vérification des documents...")
    
    success = asyncio.run(check_documents())
    
    if success:
        logger.info("✅ Vérification terminée")
    else:
        logger.error("❌ Échec de la vérification")
        sys.exit(1) 