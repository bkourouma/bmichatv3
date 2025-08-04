#!/usr/bin/env python3
"""
Script pour diagnostiquer ChromaDB et identifier les problèmes avec le stockage des embeddings.
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


async def debug_chromadb():
    """Diagnostique complet de ChromaDB."""
    
    try:
        # Initialiser le service vectoriel
        vector_service = VectorService()
        await vector_service.initialize()
        
        logger.info("🔍 Diagnostic complet de ChromaDB...")
        
        # 1. Informations générales sur la collection
        logger.info("\n📊 Informations de la collection:")
        try:
            count = vector_service.collection.count()
            logger.info(f"  - Nombre total de documents: {count}")
            
            # Obtenir tous les documents
            all_results = vector_service.collection.get()
            
            if all_results["ids"]:
                logger.info(f"  - Nombre d'IDs: {len(all_results['ids'])}")
                logger.info(f"  - Nombre de métadonnées: {len(all_results['metadatas'])}")
                logger.info(f"  - Nombre d'embeddings: {len(all_results.get('embeddings', []))}")
                logger.info(f"  - Nombre de documents: {len(all_results.get('documents', []))}")
                
                # Analyser les métadonnées
                logger.info("\n📋 Analyse des métadonnées:")
                document_ids = set()
                filenames = set()
                
                for metadata in all_results["metadatas"]:
                    if metadata:
                        doc_id = metadata.get("document_id", "Inconnu")
                        filename = metadata.get("filename", "Inconnu")
                        document_ids.add(doc_id)
                        filenames.add(filename)
                
                logger.info(f"  - Documents uniques: {len(document_ids)}")
                logger.info(f"  - Fichiers uniques: {len(filenames)}")
                
                for filename in filenames:
                    logger.info(f"    * {filename}")
                
            else:
                logger.warning("⚠️ Aucun document trouvé dans la collection")
                
        except Exception as e:
            logger.error(f"❌ Erreur lors de l'analyse de la collection: {str(e)}")
        
        # 2. Vérifier spécifiquement les chunks BMI
        logger.info("\n🔍 Vérification spécifique des chunks BMI:")
        
        async for db_session in get_db():
            stmt = select(Document).where(Document.original_filename == "Information sur BMI.pdf")
            result = await db_session.execute(stmt)
            document = result.scalar_one_or_none()
            
            if not document:
                logger.error("❌ Document BMI non trouvé dans la base de données")
                return False
            
            logger.info(f"📄 Document BMI trouvé: {document.id}")
            
            # Rechercher par document_id
            try:
                bmi_results = vector_service.collection.get(
                    where={"document_id": document.id}
                )
                
                if bmi_results["ids"]:
                    logger.info(f"✅ {len(bmi_results['ids'])} chunks BMI trouvés dans ChromaDB")
                    
                    for i, (chunk_id, metadata) in enumerate(zip(bmi_results["ids"], bmi_results["metadatas"])):
                        logger.info(f"\n📄 Chunk BMI {i+1}:")
                        logger.info(f"  - ID: {chunk_id}")
                        logger.info(f"  - Document ID: {metadata.get('document_id', 'Inconnu')}")
                        logger.info(f"  - Filename: {metadata.get('filename', 'Inconnu')}")
                        logger.info(f"  - Chunk index: {metadata.get('chunk_index', 'Inconnu')}")
                        logger.info(f"  - Chunk length: {metadata.get('chunk_length', 'Inconnu')}")
                        
                        # Vérifier l'embedding
                        if "embeddings" in bmi_results and i < len(bmi_results["embeddings"]):
                            embedding = bmi_results["embeddings"][i]
                            logger.info(f"  - Embedding: {len(embedding)} dimensions")
                            logger.info(f"  - Premiers 5 valeurs: {embedding[:5]}")
                        else:
                            logger.warning(f"  ⚠️ Pas d'embedding pour ce chunk")
                        
                        # Vérifier le contenu
                        if "documents" in bmi_results and i < len(bmi_results["documents"]):
                            content = bmi_results["documents"][i]
                            logger.info(f"  - Contenu (100 premiers caractères): {content[:100]}...")
                        else:
                            logger.warning(f"  ⚠️ Pas de contenu pour ce chunk")
                            
                else:
                    logger.warning("⚠️ Aucun chunk BMI trouvé dans ChromaDB")
                    
            except Exception as e:
                logger.error(f"❌ Erreur lors de la recherche des chunks BMI: {str(e)}")
        
        # 3. Test de recherche vectorielle directe
        logger.info("\n🔍 Test de recherche vectorielle directe:")
        
        try:
            # Créer un embedding de test simple
            test_embedding = [0.1] * 1536  # Embedding de test
            
            # Rechercher avec cet embedding
            search_results = vector_service.collection.query(
                query_embeddings=[test_embedding],
                n_results=10
            )
            
            if search_results["ids"] and search_results["ids"][0]:
                logger.info(f"✅ Recherche vectorielle fonctionne")
                logger.info(f"  - Nombre de résultats: {len(search_results['ids'][0])}")
                
                # Vérifier si les chunks BMI sont dans les résultats
                bmi_found = False
                for i, chunk_id in enumerate(search_results["ids"][0]):
                    if "99eee4da-b44e-49dd-b553-a862b83c8ccd" in chunk_id:
                        bmi_found = True
                        logger.info(f"  - Chunk BMI trouvé à la position {i+1}")
                        break
                
                if not bmi_found:
                    logger.warning("⚠️ Aucun chunk BMI dans les résultats de recherche")
                    
            else:
                logger.warning("⚠️ Aucun résultat de recherche")
                
        except Exception as e:
            logger.error(f"❌ Erreur lors de la recherche vectorielle: {str(e)}")
        
        # 4. Vérifier la configuration ChromaDB
        logger.info("\n⚙️ Configuration ChromaDB:")
        try:
            # Informations sur le client
            client_info = vector_service.client.get_version()
            logger.info(f"  - Version ChromaDB: {client_info}")
            
            # Informations sur la collection
            collection_info = vector_service.collection.metadata
            logger.info(f"  - Métadonnées de la collection: {collection_info}")
            
        except Exception as e:
            logger.error(f"❌ Erreur lors de la vérification de la configuration: {str(e)}")
        
        return True
        
    except Exception as e:
        logger.error(f"❌ Erreur lors du diagnostic: {str(e)}")
        import traceback
        logger.error(traceback.format_exc())
        return False


if __name__ == "__main__":
    logger.info("🚀 Début du diagnostic ChromaDB...")
    
    success = asyncio.run(debug_chromadb())
    
    if success:
        logger.info("✅ Diagnostic terminé")
    else:
        logger.error("❌ Échec du diagnostic")
        sys.exit(1) 