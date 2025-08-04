#!/usr/bin/env python3
"""
Script pour régénérer les embeddings du document BMI.
"""

import asyncio
import sys
from pathlib import Path

# Ajouter le répertoire parent au path pour importer les modules de l'app
sys.path.append(str(Path(__file__).parent.parent))

from app.core.database import get_db
from app.models import Document, DocumentChunk
from app.services.document_service import DocumentProcessor
from app.services.vector_service import VectorService
from app.services.embedding_service import EmbeddingService
from sqlalchemy import select
from loguru import logger


async def regenerate_bmi_embeddings():
    """Régénère les embeddings du document BMI."""
    
    try:
        # Initialiser les services
        vector_service = VectorService()
        embedding_service = EmbeddingService()
        document_processor = DocumentProcessor()
        
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
            
            logger.info(f"📦 Nombre de chunks à traiter: {len(chunks)}")
            
            # Supprimer les anciens embeddings de la base vectorielle
            logger.info("🗑️ Suppression des anciens embeddings...")
            try:
                results = vector_service.collection.get(
                    where={"document_id": document.id}
                )
                
                if results["ids"]:
                    vector_service.collection.delete(ids=results["ids"])
                    logger.info(f"✅ Supprimé {len(results['ids'])} anciens embeddings")
                else:
                    logger.info("ℹ️ Aucun ancien embedding à supprimer")
                    
            except Exception as e:
                logger.warning(f"⚠️ Erreur lors de la suppression: {str(e)}")
            
            # Régénérer les embeddings
            logger.info("🧠 Régénération des embeddings...")
            
            chunks_text = [chunk.content for chunk in chunks]
            embeddings = await embedding_service.generate_embeddings(chunks_text)
            
            if not embeddings:
                logger.error("❌ Échec de la génération des embeddings")
                return False
            
            logger.info(f"✅ {len(embeddings)} embeddings générés")
            
            # Préparer les métadonnées
            metadata_list = []
            for i, chunk in enumerate(chunks):
                metadata = {
                    "document_id": document.id,
                    "chunk_index": i,
                    "filename": document.original_filename,
                    "file_type": document.file_type.value,
                    "chunk_length": len(chunk.content),
                    "created_at": chunk.created_at.isoformat() if chunk.created_at else None,
                    "keywords": document.keywords or "",
                    "chunk_type": "regular",
                    "has_questions": False,
                    "has_answers": False,
                    "confidence_score": 1.0,
                    "word_count": len(chunk.content.split())
                }
                metadata_list.append(metadata)
            
            # Ajouter les nouveaux embeddings à la base vectorielle
            logger.info("💾 Ajout des nouveaux embeddings...")
            await vector_service.add_document_chunks(
                document_id=document.id,
                chunks=chunks_text,
                embeddings=embeddings,
                metadata=metadata_list
            )
            
            logger.info("✅ Embeddings ajoutés avec succès")
            
            # Vérifier que les embeddings sont bien stockés
            logger.info("🔍 Vérification des nouveaux embeddings...")
            results = vector_service.collection.get(
                where={"document_id": document.id}
            )
            
            if results["ids"]:
                logger.info(f"✅ {len(results['ids'])} embeddings trouvés")
                for i, (chunk_id, metadata) in enumerate(zip(results["ids"], results["metadatas"])):
                    logger.info(f"  {i+1}. ID: {chunk_id}")
                    logger.info(f"     Filename: {metadata.get('filename', 'Inconnu')}")
                    logger.info(f"     Chunk index: {metadata.get('chunk_index', 'Inconnu')}")
                    
                    # Vérifier l'embedding
                    if "embeddings" in results and results["embeddings"]:
                        embedding = results["embeddings"][i]
                        logger.info(f"     Embedding: {len(embedding)} dimensions")
                    else:
                        logger.warning(f"     ⚠️ Pas d'embedding")
            else:
                logger.warning("⚠️ Aucun embedding trouvé après ajout")
        
        return True
        
    except Exception as e:
        logger.error(f"❌ Erreur lors de la régénération: {str(e)}")
        import traceback
        logger.error(traceback.format_exc())
        return False


if __name__ == "__main__":
    logger.info("🚀 Régénération des embeddings BMI...")
    
    success = asyncio.run(regenerate_bmi_embeddings())
    
    if success:
        logger.info("✅ Régénération terminée")
    else:
        logger.error("❌ Échec de la régénération")
        sys.exit(1) 