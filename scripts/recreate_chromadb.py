#!/usr/bin/env python3
"""
Script pour recréer complètement la collection ChromaDB.
"""

import asyncio
import sys
from pathlib import Path

# Ajouter le répertoire parent au path pour importer les modules de l'app
sys.path.append(str(Path(__file__).parent.parent))

from app.services.vector_service import VectorService
from app.services.embedding_service import EmbeddingService
from app.core.database import get_db
from app.models import Document, DocumentChunk
from sqlalchemy import select
from loguru import logger


async def recreate_chromadb():
    """Recrée complètement la collection ChromaDB."""
    
    try:
        # Initialiser les services
        vector_service = VectorService()
        embedding_service = EmbeddingService()
        
        logger.info("🔄 Recréation complète de ChromaDB...")
        
        # 1. Supprimer la collection existante
        logger.info("\n🗑️ Suppression de la collection existante...")
        
        try:
            await vector_service.initialize()
            
            # Supprimer tous les documents
            all_results = vector_service.collection.get()
            if all_results["ids"]:
                vector_service.collection.delete(ids=all_results["ids"])
                logger.info(f"✅ Supprimé {len(all_results['ids'])} documents")
            
            # Supprimer la collection
            vector_service.client.delete_collection("bmi_documents")
            logger.info("✅ Collection supprimée")
            
        except Exception as e:
            logger.warning(f"⚠️ Erreur lors de la suppression: {str(e)}")
        
        # 2. Recréer la collection
        logger.info("\n🆕 Recréation de la collection...")
        
        try:
            vector_service.collection = vector_service.client.create_collection(
                name="bmi_documents",
                metadata={"description": "BMI Chat document embeddings"}
            )
            logger.info("✅ Collection recréée")
            
        except Exception as e:
            logger.error(f"❌ Erreur lors de la recréation: {str(e)}")
            return False
        
        # 3. Récupérer tous les documents de la base de données
        logger.info("\n📚 Récupération des documents...")
        
        documents_to_process = []
        
        async for db_session in get_db():
            # Récupérer tous les documents traités
            stmt = select(Document).where(Document.status == "PROCESSED")
            result = await db_session.execute(stmt)
            documents = result.scalars().all()
            
            logger.info(f"📄 {len(documents)} documents traités trouvés")
            
            for document in documents:
                # Récupérer les chunks du document
                stmt = select(DocumentChunk).where(DocumentChunk.document_id == document.id)
                result = await db_session.execute(stmt)
                chunks = result.scalars().all()
                
                if chunks:
                    documents_to_process.append({
                        "document": document,
                        "chunks": chunks
                    })
                    logger.info(f"  - {document.original_filename}: {len(chunks)} chunks")
        
        # 4. Traiter chaque document
        logger.info(f"\n🧠 Traitement de {len(documents_to_process)} documents...")
        
        for doc_info in documents_to_process:
            document = doc_info["document"]
            chunks = doc_info["chunks"]
            
            logger.info(f"\n📄 Traitement de {document.original_filename} ({len(chunks)} chunks)")
            
            # Extraire les contenus
            contents = [chunk.content for chunk in chunks]
            
            # Générer les embeddings
            logger.info("  🧠 Génération des embeddings...")
            embeddings = await embedding_service.generate_embeddings(contents)
            
            if not embeddings:
                logger.error(f"  ❌ Échec de la génération des embeddings pour {document.original_filename}")
                continue
            
            logger.info(f"  ✅ {len(embeddings)} embeddings générés")
            
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
            
            # Ajouter à ChromaDB
            try:
                await vector_service.add_document_chunks(
                    document_id=document.id,
                    chunks=contents,
                    embeddings=embeddings,
                    metadata=metadata_list
                )
                logger.info(f"  ✅ Embeddings ajoutés pour {document.original_filename}")
                
            except Exception as e:
                logger.error(f"  ❌ Erreur lors de l'ajout des embeddings: {str(e)}")
        
        # 5. Vérifier la nouvelle collection
        logger.info("\n🔍 Vérification de la nouvelle collection...")
        
        try:
            count = vector_service.collection.count()
            logger.info(f"📊 Nombre total de documents: {count}")
            
            # Vérifier spécifiquement les chunks BMI
            bmi_results = vector_service.collection.get(
                where={"document_id": "99eee4da-b44e-49dd-b553-a862b83c8ccd"}
            )
            
            if bmi_results["ids"]:
                logger.info(f"✅ {len(bmi_results['ids'])} chunks BMI trouvés")
                
                for i, chunk_id in enumerate(bmi_results["ids"]):
                    if "embeddings" in bmi_results and i < len(bmi_results["embeddings"]):
                        embedding = bmi_results["embeddings"][i]
                        if embedding is not None and len(embedding) > 0:
                            logger.info(f"  ✅ Chunk {chunk_id}: {len(embedding)} dimensions")
                        else:
                            logger.warning(f"  ⚠️ Chunk {chunk_id}: embedding invalide")
                    else:
                        logger.warning(f"  ⚠️ Chunk {chunk_id}: pas d'embedding")
            else:
                logger.warning("⚠️ Aucun chunk BMI trouvé")
                
        except Exception as e:
            logger.error(f"❌ Erreur lors de la vérification: {str(e)}")
        
        return True
        
    except Exception as e:
        logger.error(f"❌ Erreur lors de la recréation: {str(e)}")
        import traceback
        logger.error(traceback.format_exc())
        return False


if __name__ == "__main__":
    logger.info("🚀 Début de la recréation de ChromaDB...")
    
    success = asyncio.run(recreate_chromadb())
    
    if success:
        logger.info("✅ Recréation terminée")
    else:
        logger.error("❌ Échec de la recréation")
        sys.exit(1) 