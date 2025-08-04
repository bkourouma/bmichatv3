#!/usr/bin/env python3
"""
Script pour ajouter le document "Information sur BMI" au système de traitement des documents.
"""

import asyncio
import sys
from pathlib import Path

# Ajouter le répertoire parent au path pour importer les modules de l'app
sys.path.append(str(Path(__file__).parent.parent))

from app.core.database import get_db
from app.services.document_manager import DocumentManager
from loguru import logger


async def add_bmi_document():
    """Ajoute le document PDF 'Information sur BMI' au système."""
    
    # Chemin vers le document PDF
    pdf_path = Path(__file__).parent.parent / "docs" / "Information sur BMI.pdf"
    
    if not pdf_path.exists():
        logger.error(f"❌ Document PDF non trouvé: {pdf_path}")
        return False
    
    try:
        # Lire le contenu du fichier
        with open(pdf_path, 'rb') as f:
            file_content = f.read()
        
        logger.info(f"📄 Lecture du document: {pdf_path}")
        logger.info(f"📊 Taille du fichier: {len(file_content)} bytes")
        
        # Initialiser le gestionnaire de documents
        document_manager = DocumentManager()
        
        # Obtenir une session de base de données
        async for db_session in get_db():
            # Upload et traitement du document
            document = await document_manager.upload_document(
                file_content=file_content,
                filename="Information sur BMI.pdf",
                db_session=db_session,
                keywords="BMI, entreprise, services, informations"
            )
            
            logger.info(f"✅ Document ajouté avec succès!")
            logger.info(f"📋 ID du document: {document.id}")
            logger.info(f"📋 Nom du fichier: {document.original_filename}")
            logger.info(f"📋 Statut: {document.status}")
            logger.info(f"📋 Type: {document.file_type}")
            
            return True
            
    except Exception as e:
        logger.error(f"❌ Erreur lors de l'ajout du document: {str(e)}")
        return False


if __name__ == "__main__":
    logger.info("🚀 Début de l'ajout du document BMI...")
    
    success = asyncio.run(add_bmi_document())
    
    if success:
        logger.info("✅ Document BMI ajouté avec succès!")
    else:
        logger.error("❌ Échec de l'ajout du document BMI")
        sys.exit(1) 