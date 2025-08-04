#!/usr/bin/env python3
"""
Script pour ajouter le document "Tresormoney.pdf" au système.
"""

import asyncio
import sys
from pathlib import Path

# Ajouter le répertoire parent au path pour importer les modules de l'app
sys.path.append(str(Path(__file__).parent.parent))

from app.core.database import get_db
from app.services.document_manager import DocumentManager
from app.models import Document
from sqlalchemy import select
from loguru import logger


async def add_tresormoney_document():
    """Ajoute le document PDF 'Tresormoney.pdf' au système."""
    
    # Chemin vers le document PDF
    pdf_path = Path(__file__).parent.parent / "docs" / "Tresormoney.pdf"
    
    if not pdf_path.exists():
        logger.error(f"❌ Document PDF non trouvé: {pdf_path}")
        logger.info("📋 Fichiers disponibles dans docs/:")
        docs_dir = Path(__file__).parent.parent / "docs"
        for file in docs_dir.glob("*.pdf"):
            logger.info(f"  - {file.name}")
        return False
    
    logger.info(f"📄 Document trouvé: {pdf_path}")
    logger.info(f"📊 Taille du fichier: {pdf_path.stat().st_size / 1024:.1f} KB")
    
    try:
        # Initialiser le gestionnaire de documents
        document_manager = DocumentManager()
        
        # Obtenir une session de base de données
        async for db_session in get_db():
            # Vérifier si le document existe déjà en cherchant par nom de fichier
            stmt = select(Document).where(Document.original_filename == "Tresormoney.pdf")
            result = await db_session.execute(stmt)
            existing_doc = result.scalar_one_or_none()
            
            if existing_doc:
                logger.info(f"📋 Document déjà présent dans la base de données:")
                logger.info(f"  - ID: {existing_doc.id}")
                logger.info(f"  - Statut: {existing_doc.status}")
                logger.info(f"  - Chunks: {existing_doc.chunk_count}")
                logger.info(f"  - Vectors: {existing_doc.vector_count}")
                
                if existing_doc.status == "PROCESSED":
                    logger.info("✅ Document déjà traité avec succès")
                    return True
                else:
                    logger.info("🔄 Document en cours de traitement ou en erreur")
                    return False
            
            # Ajouter le document
            logger.info("📤 Ajout du document au système...")
            
            # Lire le contenu du fichier
            with open(pdf_path, 'rb') as f:
                file_content = f.read()
            
            document = await document_manager.upload_document(
                file_content=file_content,
                filename="Tresormoney.pdf",
                db_session=db_session,
                keywords="TrésorMoney, FAQ, questions, réponses, paiements, services financiers"
            )
            
            logger.info(f"✅ Document ajouté avec succès:")
            logger.info(f"  - ID: {document.id}")
            logger.info(f"  - Statut: {document.status}")
            logger.info(f"  - Taille: {document.file_size} bytes")
            
            # Le document est automatiquement traité lors de l'upload
            logger.info("🔄 Document en cours de traitement automatique...")
            
            # Vérifier le statut final
            await db_session.refresh(document)
            
            logger.info(f"✅ Traitement terminé:")
            logger.info(f"  - Statut final: {document.status}")
            logger.info(f"  - Chunks créés: {document.chunk_count}")
            logger.info(f"  - Vectors générés: {document.vector_count}")
            
            if document.status == "PROCESSED":
                logger.info("🎉 Document traité avec succès!")
                return True
            else:
                logger.error(f"❌ Erreur lors du traitement: {document.processing_error}")
                return False
        
    except Exception as e:
        logger.error(f"❌ Erreur lors de l'ajout du document: {str(e)}")
        import traceback
        logger.error(traceback.format_exc())
        return False


if __name__ == "__main__":
    logger.info("🚀 Début de l'ajout du document Tresormoney...")
    
    success = asyncio.run(add_tresormoney_document())
    
    if success:
        logger.info("✅ Document ajouté avec succès")
    else:
        logger.error("❌ Échec de l'ajout du document")
        sys.exit(1) 