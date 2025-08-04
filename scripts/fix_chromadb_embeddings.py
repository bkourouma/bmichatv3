#!/usr/bin/env python3
"""
Script pour corriger le problème des embeddings None dans ChromaDB.
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


async def fix_chromadb_embeddings():
    """Corrige le problème des embeddings None dans ChromaDB."""
    
    try:
        # Initialiser les services
        vector_service = VectorService()
        embedding_service = EmbeddingService()
        
        await vector_service.initialize()
        
        logger.info("🔧 Correction des embeddings dans ChromaDB...")
        
        # 1. Identifier tous les documents avec des embeddings None
        logger.info("\n📊 Analyse des embeddings...")
        
        try:
            all_results = vector_service.collection.get()
            
            if not all_results["ids"]:
                logger.warning("⚠️ Aucun document dans la collection")
                return False
            
            # Identifier les documents avec des embeddings None
            documents_without_embeddings = []
            
            for i, chunk_id in enumerate(all_results["ids"]):
                metadata = all_results["metadatas"][i] if i < len(all_results["metadatas"]) else {}
                
                # Vérifier si l'embedding existe et n'est pas None
                has_embedding = False
                if "embeddings" in all_results and all_results["embeddings"]:
                    embedding = all_results["embeddings"][i] if i < len(all_results["embeddings"]) else None
                    if embedding is not None and len(embedding) > 0:
                        has_embedding = True
                
                if not has_embedding:
                    documents_without_embeddings.append({
                        "id": chunk_id,
                        "metadata": metadata,
                        "content": all_results["documents"][i] if "documents" in all_results and i < len(all_results["documents"]) else ""
                    })
            
            logger.info(f"📋 {len(documents_without_embeddings)} documents sans embeddings trouvés")
            
            if not documents_without_embeddings:
                logger.info("✅ Tous les documents ont des embeddings valides")
                return True
            
            # 2. Supprimer les documents sans embeddings
            logger.info("\n🗑️ Suppression des documents sans embeddings...")
            
            ids_to_delete = [doc["id"] for doc in documents_without_embeddings]
            vector_service.collection.delete(ids=ids_to_delete)
            
            logger.info(f"✅ Supprimé {len(ids_to_delete)} documents sans embeddings")
            
            # 3. Régénérer les embeddings pour les documents supprimés
            logger.info("\n🧠 Régénération des embeddings...")
            
            # Grouper par document_id
            documents_by_id = {}
            for doc in documents_without_embeddings:
                doc_id = doc["metadata"].get("document_id")
                if doc_id not in documents_by_id:
                    documents_by_id[doc_id] = []
                documents_by_id[doc_id].append(doc)
            
            # Régénérer les embeddings pour chaque document
            for doc_id, chunks in documents_by_id.items():
                logger.info(f"📄 Traitement du document {doc_id} ({len(chunks)} chunks)")
                
                # Extraire les contenus
                contents = [chunk["content"] for chunk in chunks]
                
                # Générer les embeddings
                embeddings = await embedding_service.generate_embeddings(contents)
                
                if not embeddings:
                    logger.error(f"❌ Échec de la génération des embeddings pour {doc_id}")
                    continue
                
                # Préparer les métadonnées
                metadata_list = []
                for i, chunk in enumerate(chunks):
                    metadata = chunk["metadata"].copy()
                    metadata["chunk_index"] = i  # Réindexer
                    metadata_list.append(metadata)
                
                # Ajouter à ChromaDB
                try:
                    await vector_service.add_document_chunks(
                        document_id=doc_id,
                        chunks=contents,
                        embeddings=embeddings,
                        metadata=metadata_list
                    )
                    logger.info(f"✅ Embeddings ajoutés pour {doc_id}")
                    
                except Exception as e:
                    logger.error(f"❌ Erreur lors de l'ajout des embeddings pour {doc_id}: {str(e)}")
            
            # 4. Vérifier que les embeddings sont maintenant valides
            logger.info("\n🔍 Vérification des embeddings corrigés...")
            
            final_results = vector_service.collection.get()
            
            if final_results["ids"]:
                valid_embeddings = 0
                for i, chunk_id in enumerate(final_results["ids"]):
                    if "embeddings" in final_results and final_results["embeddings"]:
                        embedding = final_results["embeddings"][i] if i < len(final_results["embeddings"]) else None
                        if embedding is not None and len(embedding) > 0:
                            valid_embeddings += 1
                
                logger.info(f"✅ {valid_embeddings}/{len(final_results['ids'])} documents ont des embeddings valides")
                
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
                    logger.warning("⚠️ Aucun chunk BMI trouvé après correction")
            
        except Exception as e:
            logger.error(f"❌ Erreur lors de la correction: {str(e)}")
            import traceback
            logger.error(traceback.format_exc())
            return False
        
        return True
        
    except Exception as e:
        logger.error(f"❌ Erreur lors de la correction: {str(e)}")
        import traceback
        logger.error(traceback.format_exc())
        return False


if __name__ == "__main__":
    logger.info("🚀 Début de la correction des embeddings...")
    
    success = asyncio.run(fix_chromadb_embeddings())
    
    if success:
        logger.info("✅ Correction terminée")
    else:
        logger.error("❌ Échec de la correction")
        sys.exit(1) 