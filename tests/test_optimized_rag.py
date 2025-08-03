"""
Test script for the optimized RAG pipeline with re-ranking.

This script tests the new adaptive retrieval pipeline with cross-encoder re-ranking.
"""

import asyncio
import sys
from pathlib import Path

# Add the app directory to the Python path
sys.path.insert(0, str(Path(__file__).parent.parent))

from app.config import settings
from app.core.database import AsyncSessionLocal
from app.services.reranking_service import ReRankingService
from app.services.retrieval_service import RetrievalService
from app.services.chat_service import ChatService
from loguru import logger


async def test_reranking_service():
    """Test the re-ranking service."""
    logger.info("🧪 Testing Re-ranking Service...")
    
    reranking_service = ReRankingService()
    await reranking_service.initialize()
    
    # Test data
    query = "Comment faire une réclamation d'assurance ?"
    
    mock_chunks = [
        {
            "content": "Pour faire une réclamation, vous devez remplir le formulaire de réclamation et l'envoyer avec les pièces justificatives.",
            "score": 0.7,
            "metadata": {"document_id": "doc1", "chunk_index": 1}
        },
        {
            "content": "Les horaires d'ouverture de BMI sont de 8h à 17h du lundi au vendredi.",
            "score": 0.6,
            "metadata": {"document_id": "doc2", "chunk_index": 2}
        },
        {
            "content": "La réclamation d'assurance doit être accompagnée d'un certificat médical et des factures originales.",
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
        logger.info(f"  {i}. Score: {chunk.get('combined_score', 0):.3f} | "
                   f"Rerank: {chunk.get('rerank_score', 0):.3f} | "
                   f"Content: {chunk['content'][:50]}...")
    
    return reranked_chunks


async def test_adaptive_retrieval():
    """Test the adaptive retrieval pipeline."""
    logger.info("🧪 Testing Adaptive Retrieval Pipeline...")
    
    retrieval_service = RetrievalService()
    
    # Test queries with different expected confidence levels
    test_queries = [
        "Comment faire une réclamation ?",  # Should find relevant info
        "Quels sont les horaires ?",        # Should find relevant info
        "Quelle est la couleur du ciel ?",  # Should not find relevant info
    ]
    
    async with AsyncSessionLocal() as db_session:
        for query in test_queries:
            logger.info(f"🔍 Testing query: {query}")
            
            try:
                chunks, strategy = await retrieval_service.retrieve_with_adaptive_pipeline(
                    query=query,
                    db_session=db_session,
                    k=3,
                    confidence_threshold=0.8,
                    fallback_threshold=0.3
                )
                
                logger.info(f"  Strategy: {strategy}")
                logger.info(f"  Chunks found: {len(chunks)}")
                
                if chunks:
                    top_score = chunks[0].get('combined_score', chunks[0].get('score', 0))
                    logger.info(f"  Top score: {top_score:.3f}")
                
            except Exception as e:
                logger.error(f"  Error: {str(e)}")
            
            logger.info("")


async def test_chat_service():
    """Test the enhanced chat service."""
    logger.info("🧪 Testing Enhanced Chat Service...")
    
    chat_service = ChatService()
    
    test_messages = [
        "Bonjour, comment faire une réclamation ?",
        "Quels sont vos horaires d'ouverture ?",
        "Pouvez-vous m'expliquer la procédure de remboursement ?",
    ]
    
    async with AsyncSessionLocal() as db_session:
        session_id = "test_session_optimized_rag"
        
        for message in test_messages:
            logger.info(f"💬 Testing message: {message}")
            
            try:
                response = await chat_service.process_chat_message(
                    message=message,
                    session_id=session_id,
                    db_session=db_session,
                    max_context_chunks=3
                )
                
                logger.info(f"  Strategy: {response.get('retrieval_strategy', 'unknown')}")
                logger.info(f"  Context used: {response.get('context_used', 0)}")
                logger.info(f"  Response: {response['message'][:100]}...")
                
                # Show source information
                sources = response.get('sources', [])
                if sources:
                    logger.info("  Sources:")
                    for source in sources[:2]:  # Show top 2 sources
                        logger.info(f"    - Score: {source.get('relevance_score', 0):.3f} | "
                                   f"Rerank: {source.get('rerank_score', 'N/A')} | "
                                   f"File: {source.get('filename', 'Unknown')}")
                
            except Exception as e:
                logger.error(f"  Error: {str(e)}")
            
            logger.info("")


async def test_model_info():
    """Test model information and configuration."""
    logger.info("🧪 Testing Model Configuration...")
    
    reranking_service = ReRankingService()
    await reranking_service.initialize()
    
    model_info = reranking_service.get_model_info()
    logger.info("📋 Re-ranking Model Info:")
    for key, value in model_info.items():
        logger.info(f"  {key}: {value}")
    
    logger.info("\n📋 Configuration Settings:")
    logger.info(f"  High confidence threshold: {settings.high_confidence_threshold}")
    logger.info(f"  Medium confidence threshold: {settings.medium_confidence_threshold}")
    logger.info(f"  Low confidence threshold: {settings.low_confidence_threshold}")
    logger.info(f"  Re-ranking enabled: {settings.enable_reranking}")
    logger.info(f"  Semantic weight: {settings.semantic_weight}")
    logger.info(f"  Keyword weight: {settings.keyword_weight}")


async def main():
    """Run all tests."""
    logger.info("🚀 Starting Optimized RAG Pipeline Tests...")
    logger.info("=" * 60)
    
    try:
        # Test 1: Re-ranking Service
        await test_reranking_service()
        logger.info("")
        
        # Test 2: Model Configuration
        await test_model_info()
        logger.info("")
        
        # Test 3: Adaptive Retrieval (commented out if no documents)
        # await test_adaptive_retrieval()
        # logger.info("")
        
        # Test 4: Enhanced Chat Service (commented out if no documents)
        # await test_chat_service()
        
        logger.info("✅ All tests completed successfully!")
        
    except Exception as e:
        logger.error(f"❌ Test failed: {str(e)}")
        raise


if __name__ == "__main__":
    asyncio.run(main())
