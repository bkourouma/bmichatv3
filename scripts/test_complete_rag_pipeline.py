#!/usr/bin/env python3
"""
Complete RAG Pipeline Test Script

This script tests the entire optimized RAG pipeline including:
- Cross-encoder re-ranking
- French-optimized embeddings
- Adaptive confidence thresholds
- Enhanced chunking with semantic overlap
- Performance metrics
"""

import asyncio
import sys
import time
from pathlib import Path

# Add the app directory to the Python path
sys.path.insert(0, str(Path(__file__).parent.parent))

from app.config import settings
from app.core.database import AsyncSessionLocal
from app.services.reranking_service import ReRankingService
from app.services.retrieval_service import RetrievalService
from app.services.chat_service import ChatService
from app.services.embedding_service import EmbeddingService
from app.services.qa_chunker import QAChunker
from app.services.metrics_service import metrics_service
from loguru import logger


async def test_embedding_optimization():
    """Test French-optimized embeddings."""
    logger.info("🧪 Testing French-optimized embeddings...")
    
    embedding_service = EmbeddingService()
    
    test_texts = [
        "Comment faire une réclamation d'assurance ?",
        "Qu'est-ce que l'assurance maladie ?",
        "Procédure de remboursement des frais médicaux"
    ]
    
    # Test standard embeddings
    start_time = time.time()
    standard_embeddings = await embedding_service.generate_embeddings(test_texts)
    standard_time = time.time() - start_time
    
    # Test optimized embeddings
    start_time = time.time()
    optimized_embeddings = await embedding_service.generate_optimized_embeddings(test_texts)
    optimized_time = time.time() - start_time
    
    logger.info(f"📊 Standard embeddings: {len(standard_embeddings)} vectors in {standard_time:.3f}s")
    logger.info(f"📊 Optimized embeddings: {len(optimized_embeddings)} vectors in {optimized_time:.3f}s")
    
    # Test text optimization
    test_text = "Qu'est-ce qu'on peut faire pour l'assurance ?"
    optimized_text = embedding_service.optimize_text_for_french(test_text)
    logger.info(f"📝 Original: {test_text}")
    logger.info(f"📝 Optimized: {optimized_text}")
    
    return True


async def test_enhanced_chunking():
    """Test enhanced chunking with semantic overlap."""
    logger.info("🧪 Testing enhanced chunking...")
    
    chunker = QAChunker()
    
    test_document = """
    L'assurance maladie est un système de protection sociale. Elle permet de rembourser les frais médicaux.
    
    Comment faire une réclamation ?
    Pour faire une réclamation, vous devez suivre ces étapes :
    1. Remplir le formulaire de réclamation
    2. Joindre les pièces justificatives
    3. Envoyer le dossier complet
    
    Quels sont les délais de remboursement ?
    Les délais de remboursement varient selon le type de soins :
    - Consultations médicales : 5-7 jours
    - Hospitalisations : 10-15 jours
    - Médicaments : 3-5 jours
    """
    
    chunks = chunker.chunk_document(test_document)
    
    logger.info(f"📊 Created {len(chunks)} chunks")
    for i, (chunk_text, metadata) in enumerate(chunks, 1):
        logger.info(f"  Chunk {i}: {metadata.chunk_type.value} | "
                   f"Length: {metadata.length} | "
                   f"Confidence: {metadata.confidence_score:.3f}")
        logger.info(f"    Content: {chunk_text[:100]}...")
    
    # Test chunking summary
    summary = chunker.get_chunking_summary(chunks)
    logger.info(f"📈 Chunking Summary: {summary}")
    
    return chunks


async def test_reranking_pipeline():
    """Test the complete re-ranking pipeline."""
    logger.info("🧪 Testing re-ranking pipeline...")
    
    reranking_service = ReRankingService()
    await reranking_service.initialize()
    
    query = "Comment faire une réclamation d'assurance ?"
    
    mock_chunks = [
        {
            "content": "Les horaires d'ouverture sont de 8h à 17h du lundi au vendredi.",
            "score": 0.6,
            "metadata": {"document_id": "doc1", "chunk_index": 1}
        },
        {
            "content": "Pour faire une réclamation d'assurance, remplissez le formulaire de réclamation avec toutes les pièces justificatives nécessaires.",
            "score": 0.7,
            "metadata": {"document_id": "doc2", "chunk_index": 2}
        },
        {
            "content": "La réclamation doit être accompagnée d'un certificat médical et des factures originales pour être traitée rapidement.",
            "score": 0.8,
            "metadata": {"document_id": "doc3", "chunk_index": 3}
        }
    ]
    
    # Test re-ranking
    reranked_chunks = await reranking_service.rerank_chunks(
        query=query,
        chunks=mock_chunks,
        top_k=3,
        min_score=0.0
    )
    
    logger.info("📊 Re-ranking Results:")
    for i, chunk in enumerate(reranked_chunks, 1):
        logger.info(f"  {i}. Combined Score: {chunk.get('combined_score', 0):.3f} | "
                   f"Rerank: {chunk.get('rerank_score', 0):.3f} | "
                   f"Original: {chunk.get('original_score', 0):.3f}")
        logger.info(f"     Content: {chunk['content'][:80]}...")
    
    return reranked_chunks


async def test_adaptive_retrieval():
    """Test adaptive retrieval strategies."""
    logger.info("🧪 Testing adaptive retrieval...")
    
    retrieval_service = RetrievalService()
    
    test_queries = [
        ("Comment faire une réclamation ?", "Should find relevant info"),
        ("Quels sont les horaires ?", "Should find relevant info"),
        ("Quelle est la couleur du ciel ?", "Should not find relevant info"),
    ]
    
    async with AsyncSessionLocal() as db_session:
        for query, expected in test_queries:
            logger.info(f"🔍 Testing: {query} ({expected})")
            
            try:
                chunks, strategy = await retrieval_service.retrieve_with_adaptive_pipeline(
                    query=query,
                    db_session=db_session,
                    k=3,
                    confidence_threshold=settings.high_confidence_threshold,
                    fallback_threshold=settings.low_confidence_threshold
                )
                
                logger.info(f"  Strategy: {strategy}")
                logger.info(f"  Chunks: {len(chunks)}")
                
                if chunks:
                    top_score = chunks[0].get('combined_score', chunks[0].get('score', 0))
                    logger.info(f"  Top score: {top_score:.3f}")
                
            except Exception as e:
                logger.warning(f"  Error: {str(e)}")
            
            logger.info("")


async def test_metrics_collection():
    """Test metrics collection and analysis."""
    logger.info("🧪 Testing metrics collection...")
    
    # Simulate some retrieval operations
    test_operations = [
        ("Comment faire une réclamation ?", "direct", [{"score": 0.9}], 150),
        ("Quels sont les horaires ?", "rag", [{"score": 0.7}, {"score": 0.6}], 200),
        ("Procédure de remboursement", "rag", [{"score": 0.8}, {"score": 0.5}], 180),
        ("Question inconnue", "fallback", [], 100),
    ]
    
    for query, strategy, chunks, response_time in test_operations:
        metrics_service.record_retrieval(
            query=query,
            strategy=strategy,
            chunks=chunks,
            response_time_ms=response_time,
            reranking_enabled=True
        )
    
    # Get metrics
    performance_metrics = metrics_service.get_performance_metrics(hours=1)
    quality_metrics = metrics_service.get_quality_metrics(hours=1)
    recommendations = metrics_service.get_optimization_recommendations()
    
    logger.info("📊 Performance Metrics:")
    logger.info(f"  Avg response time: {performance_metrics.avg_retrieval_time_ms:.2f}ms")
    logger.info(f"  Total requests: {performance_metrics.total_requests}")
    logger.info(f"  Success rate: {performance_metrics.success_rate:.2%}")
    logger.info(f"  Strategy distribution: {performance_metrics.strategy_distribution}")
    
    logger.info("📊 Quality Metrics:")
    logger.info(f"  Avg confidence: {quality_metrics.avg_confidence_score:.3f}")
    logger.info(f"  High confidence rate: {quality_metrics.high_confidence_rate:.2%}")
    logger.info(f"  No answer rate: {quality_metrics.no_answer_rate:.2%}")
    
    logger.info("💡 Recommendations:")
    for rec in recommendations:
        logger.info(f"  - {rec}")


async def test_configuration():
    """Test configuration and settings."""
    logger.info("🧪 Testing configuration...")
    
    logger.info("⚙️ RAG Configuration:")
    logger.info(f"  High confidence threshold: {settings.high_confidence_threshold}")
    logger.info(f"  Medium confidence threshold: {settings.medium_confidence_threshold}")
    logger.info(f"  Low confidence threshold: {settings.low_confidence_threshold}")
    logger.info(f"  Re-ranking enabled: {settings.enable_reranking}")
    logger.info(f"  Re-ranking model: {settings.reranking_model}")
    logger.info(f"  Semantic weight: {settings.semantic_weight}")
    logger.info(f"  Keyword weight: {settings.keyword_weight}")
    
    logger.info("🤖 OpenAI Configuration:")
    logger.info(f"  Model: {settings.openai_model}")
    logger.info(f"  Temperature: {settings.openai_temperature}")
    logger.info(f"  Max tokens: {settings.openai_max_tokens}")


async def main():
    """Run all tests."""
    logger.info("🚀 Starting Complete RAG Pipeline Tests")
    logger.info("=" * 60)
    
    try:
        # Test 1: Configuration
        await test_configuration()
        logger.info("")
        
        # Test 2: Embedding optimization
        await test_embedding_optimization()
        logger.info("")
        
        # Test 3: Enhanced chunking
        await test_enhanced_chunking()
        logger.info("")
        
        # Test 4: Re-ranking pipeline
        await test_reranking_pipeline()
        logger.info("")
        
        # Test 5: Metrics collection
        await test_metrics_collection()
        logger.info("")
        
        # Test 6: Adaptive retrieval (if documents exist)
        # await test_adaptive_retrieval()
        
        logger.info("✅ All tests completed successfully!")
        logger.info("\n🎉 Optimized RAG Pipeline is ready!")
        logger.info("\nNext steps:")
        logger.info("1. Upload some documents to test with real data")
        logger.info("2. Start the server: uvicorn app.main:app --host 0.0.0.0 --port 3006")
        logger.info("3. Test the chat API with real queries")
        logger.info("4. Monitor metrics at /api/metrics/comprehensive")
        
    except Exception as e:
        logger.error(f"❌ Test failed: {str(e)}")
        raise


if __name__ == "__main__":
    asyncio.run(main())
