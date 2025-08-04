"""
BMI Chat Application - Retrieval Service

This module provides high-level document retrieval operations for the chat system.
Combines embedding generation, vector search, and result optimization.
"""

from typing import List, Dict, Any, Optional, Tuple
from datetime import datetime

from loguru import logger
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_

from app.config import settings
from app.core.exceptions import VectorDatabaseError, OpenAIError
from app.models import Document, DocumentChunk, DocumentStatus
from app.services.embedding_service import EmbeddingService
from app.services.vector_service import VectorService
from app.services.reranking_service import ReRankingService


class RetrievalService:
    """
    High-level retrieval service for chat applications.
    
    Provides intelligent document retrieval with context optimization,
    relevance ranking, and result filtering.
    """
    
    def __init__(self):
        self.embedding_service = EmbeddingService()
        self.vector_service = VectorService()
        self.reranking_service = ReRankingService()
    
    async def retrieve_relevant_chunks(
        self,
        query: str,
        db_session: AsyncSession,
        k: int = None,
        keywords_filter: Optional[List[str]] = None,
        document_ids_filter: Optional[List[str]] = None,
        prefer_qa_pairs: bool = True,
        min_relevance_score: float = 0.0,
        use_reranking: bool = True
    ) -> List[Dict[str, Any]]:
        """
        Retrieve relevant document chunks for a query.

        Args:
            query: User query text
            db_session: Database session
            k: Number of chunks to retrieve
            keywords_filter: Filter by document keywords
            document_ids_filter: Filter by specific document IDs
            prefer_qa_pairs: Boost Q&A pairs in results
            min_relevance_score: Minimum relevance score threshold
            use_reranking: Whether to apply cross-encoder re-ranking

        Returns:
            List of relevant chunks with metadata
        """
        try:
            k = k or settings.default_retrieval_k
            logger.info(f"🔍 Retrieving relevant chunks for query: {query[:50]}...")
            
            # Generate optimized query embedding for French
            optimized_query = self.embedding_service.optimize_text_for_french(query)
            query_embedding = await self.embedding_service.generate_single_embedding(optimized_query)
            
            # Build metadata filter
            metadata_filter = {}
            if document_ids_filter:
                metadata_filter["document_id"] = {"$in": document_ids_filter}
            
            # Perform vector search - get more results for re-ranking
            search_k = k * 3 if use_reranking else k * 2
            search_results = await self.vector_service.search_similar_chunks(
                query_embedding=query_embedding,
                k=search_k,
                filter_metadata=metadata_filter,
                keywords_filter=keywords_filter,
                boost_qa_pairs=prefer_qa_pairs
            )

            # Process and enhance results
            enhanced_chunks = await self._process_search_results(
                search_results, query, db_session, search_k, min_relevance_score
            )

            # Apply re-ranking if enabled
            if use_reranking and enhanced_chunks:
                logger.info("🔄 Applying cross-encoder re-ranking...")
                enhanced_chunks = await self.reranking_service.rerank_chunks(
                    query=query,
                    chunks=enhanced_chunks,
                    top_k=k,
                    min_score=min_relevance_score
                )
            
            # Update retrieval statistics
            await self._update_retrieval_stats(enhanced_chunks, db_session)
            
            logger.info(f"✅ Retrieved {len(enhanced_chunks)} relevant chunks")
            return enhanced_chunks
            
        except Exception as e:
            logger.error(f"❌ Failed to retrieve relevant chunks: {str(e)}")
            raise VectorDatabaseError(f"Retrieval failed: {str(e)}")
    
    async def retrieve_by_keywords(
        self,
        keywords: List[str],
        db_session: AsyncSession,
        k: int = None,
        chunk_type_filter: Optional[str] = None
    ) -> List[Dict[str, Any]]:
        """
        Retrieve chunks by keywords without semantic similarity.
        
        Args:
            keywords: List of keywords to search for
            db_session: Database session
            k: Number of chunks to retrieve
            chunk_type_filter: Filter by chunk type
            
        Returns:
            List of matching chunks
        """
        try:
            k = k or settings.default_retrieval_k
            logger.info(f"🏷️ Retrieving chunks by keywords: {keywords}")
            
            # Perform keyword search
            search_results = await self.vector_service.search_by_keywords(
                keywords=keywords,
                k=k,
                chunk_type_filter=chunk_type_filter
            )
            
            # Process results
            enhanced_chunks = await self._process_search_results(
                search_results, f"keywords: {', '.join(keywords)}", db_session, k, 0.0
            )
            
            logger.info(f"✅ Retrieved {len(enhanced_chunks)} keyword-matched chunks")
            return enhanced_chunks
            
        except Exception as e:
            logger.error(f"❌ Failed to retrieve by keywords: {str(e)}")
            raise VectorDatabaseError(f"Keyword retrieval failed: {str(e)}")
    
    async def hybrid_retrieve(
        self,
        query: str,
        keywords: Optional[List[str]],
        db_session: AsyncSession,
        k: int = None,
        semantic_weight: float = 0.7,
        keyword_weight: float = 0.3
    ) -> List[Dict[str, Any]]:
        """
        Hybrid retrieval combining semantic and keyword search.
        
        Args:
            query: User query text
            keywords: Optional keywords for hybrid search
            db_session: Database session
            k: Number of chunks to retrieve
            semantic_weight: Weight for semantic similarity
            keyword_weight: Weight for keyword matching
            
        Returns:
            List of relevant chunks from hybrid search
        """
        try:
            k = k or settings.default_retrieval_k
            logger.info(f"🔄 Hybrid retrieval for query: {query[:50]}...")
            
            # Generate optimized query embedding for French
            optimized_query = self.embedding_service.optimize_text_for_french(query)
            query_embedding = await self.embedding_service.generate_single_embedding(optimized_query)
            
            # Perform hybrid search
            search_results = await self.vector_service.hybrid_search(
                query_embedding=query_embedding,
                keywords=keywords,
                k=k,
                semantic_weight=semantic_weight,
                keyword_weight=keyword_weight
            )
            
            # Process results
            enhanced_chunks = await self._process_search_results(
                search_results, query, db_session, k, 0.2
            )
            
            logger.info(f"✅ Hybrid retrieval returned {len(enhanced_chunks)} chunks")
            return enhanced_chunks
            
        except Exception as e:
            logger.error(f"❌ Failed to perform hybrid retrieval: {str(e)}")
            raise VectorDatabaseError(f"Hybrid retrieval failed: {str(e)}")

    async def retrieve_with_adaptive_pipeline(
        self,
        query: str,
        db_session: AsyncSession,
        k: int = None,
        keywords_filter: Optional[List[str]] = None,
        confidence_threshold: float = 0.8,
        fallback_threshold: float = 0.3,
        use_reranking: bool = True
    ) -> Tuple[List[Dict[str, Any]], str]:
        """
        Advanced retrieval with adaptive pipeline and confidence scoring.

        Pipeline:
        1. Initial retrieval with re-ranking
        2. Confidence evaluation
        3. Adaptive response strategy based on confidence

        Args:
            query: User query text
            db_session: Database session
            k: Number of chunks to retrieve
            keywords_filter: Optional keywords for filtering
            confidence_threshold: High confidence threshold for direct answers
            fallback_threshold: Minimum confidence for any response

        Returns:
            Tuple of (chunks, response_strategy)
            response_strategy: "direct", "rag", "fallback", or "no_answer"
        """
        try:
            k = k or settings.default_retrieval_k
            logger.info(f"🎯 Adaptive pipeline retrieval for: {query[:50]}...")

            # Step 1: Initial retrieval with re-ranking
            chunks = await self.retrieve_relevant_chunks(
                query=query,
                db_session=db_session,
                k=k * 2,  # Get more chunks for evaluation
                keywords_filter=keywords_filter,
                use_reranking=use_reranking,
                min_relevance_score=0.0  # Very low threshold for initial retrieval
            )

            if not chunks:
                return [], "no_answer"

            # Step 2: Evaluate top chunk confidence
            top_chunk = chunks[0]
            top_score = top_chunk.get("combined_score", top_chunk.get("score", 0.0))

            # Step 3: Determine response strategy
            if top_score >= confidence_threshold:
                # High confidence - return top chunk for direct answer
                strategy = "direct"
                result_chunks = [top_chunk]
                logger.info(f"✅ High confidence ({top_score:.3f}) - direct answer strategy")

            elif top_score >= fallback_threshold:
                # Medium confidence - use RAG with multiple chunks
                strategy = "rag"
                result_chunks = chunks[:k]
                logger.info(f"📚 Medium confidence ({top_score:.3f}) - RAG strategy with {len(result_chunks)} chunks")

            else:
                # Low confidence - fallback response
                strategy = "fallback"
                result_chunks = chunks[:2]  # Minimal context
                logger.info(f"⚠️ Low confidence ({top_score:.3f}) - fallback strategy")

            # Step 4: Additional quality checks
            result_chunks = await self._apply_quality_filters(result_chunks, query)

            return result_chunks, strategy

        except Exception as e:
            logger.error(f"❌ Adaptive pipeline failed: {str(e)}")
            # Fallback to basic retrieval
            try:
                basic_chunks = await self.retrieve_relevant_chunks(
                    query=query,
                    db_session=db_session,
                    k=k,
                    use_reranking=False
                )
                return basic_chunks, "fallback"
            except:
                return [], "no_answer"

    async def _process_search_results(
        self,
        search_results: Dict[str, Any],
        query: str,
        db_session: AsyncSession,
        k: int,
        min_score: float
    ) -> List[Dict[str, Any]]:
        """Process and enhance search results."""
        if not search_results["chunks"]:
            return []
        
        enhanced_chunks = []
        
        for i, chunk_text in enumerate(search_results["chunks"]):
            if i >= k:
                break
            
            # Get metadata and scores
            metadata = search_results["metadata"][i] if i < len(search_results["metadata"]) else {}
            score = search_results["scores"][i] if i < len(search_results["scores"]) else 0.0
            distance = search_results["distances"][i] if i < len(search_results["distances"]) else 1.0
            
            # Apply minimum score filter
            if score < min_score:
                continue
            
            # Get document information
            document_id = metadata.get("document_id")
            document_info = await self._get_document_info(document_id, db_session)
            
            # Create enhanced chunk
            enhanced_chunk = {
                "content": chunk_text,
                "score": score,
                "distance": distance,
                "metadata": metadata,
                "document_info": document_info,
                "chunk_type": metadata.get("chunk_type", "regular"),
                "has_questions": metadata.get("has_questions", False),
                "has_answers": metadata.get("has_answers", False),
                "keywords": metadata.get("keywords", ""),
                "relevance_explanation": self._generate_relevance_explanation(
                    chunk_text, query, score, metadata
                )
            }
            
            enhanced_chunks.append(enhanced_chunk)
        
        return enhanced_chunks

    async def _apply_quality_filters(
        self,
        chunks: List[Dict[str, Any]],
        query: str
    ) -> List[Dict[str, Any]]:
        """Apply additional quality filters to chunks."""
        if not chunks:
            return chunks

        filtered_chunks = []

        for chunk in chunks:
            content = chunk.get("content", "")

            # Filter out very short chunks (likely not informative)
            if len(content.strip()) < 50:
                continue

            # Filter out chunks that are mostly numbers/symbols
            text_ratio = sum(c.isalpha() or c.isspace() for c in content) / len(content)
            if text_ratio < 0.5:
                continue

            # Additional quality checks could be added here
            # - Language detection
            # - Content type validation
            # - Duplicate detection

            filtered_chunks.append(chunk)

        return filtered_chunks

    async def _get_document_info(
        self,
        document_id: str,
        db_session: AsyncSession
    ) -> Optional[Dict[str, Any]]:
        """Get document information from database."""
        if not document_id:
            return None
        
        try:
            document = await db_session.get(Document, document_id)
            if document:
                return {
                    "id": document.id,
                    "filename": document.original_filename,
                    "title": document.title,
                    "file_type": document.file_type.value,
                    "keywords": document.keywords,
                    "created_at": document.created_at.isoformat()
                }
        except Exception as e:
            logger.warning(f"Failed to get document info for {document_id}: {str(e)}")
        
        return None
    
    def _generate_relevance_explanation(
        self,
        chunk_text: str,
        query: str,
        score: float,
        metadata: Dict[str, Any]
    ) -> str:
        """Generate explanation for why this chunk is relevant."""
        explanations = []
        
        # Score-based explanation
        if score > 0.8:
            explanations.append("High semantic similarity")
        elif score > 0.6:
            explanations.append("Good semantic match")
        elif score > 0.4:
            explanations.append("Moderate relevance")
        else:
            explanations.append("Low relevance")
        
        # Chunk type explanation
        chunk_type = metadata.get("chunk_type", "regular")
        if chunk_type == "qa_pair":
            explanations.append("Complete Q&A pair")
        elif metadata.get("has_questions") and metadata.get("has_answers"):
            explanations.append("Contains questions and answers")
        elif metadata.get("has_questions"):
            explanations.append("Contains questions")
        
        # Keywords explanation
        keywords = metadata.get("keywords", "")
        if keywords:
            explanations.append(f"Keywords: {keywords}")
        
        return "; ".join(explanations)
    
    async def _update_retrieval_stats(
        self,
        chunks: List[Dict[str, Any]],
        db_session: AsyncSession
    ) -> None:
        """Update retrieval statistics for documents and chunks."""
        try:
            document_ids = set()
            chunk_ids = []
            
            for chunk in chunks:
                doc_id = chunk["metadata"].get("document_id")
                if doc_id:
                    document_ids.add(doc_id)
                
                chunk_id = chunk["metadata"].get("chunk_index")
                if chunk_id is not None:
                    chunk_ids.append((doc_id, chunk_id))
            
            # Update document query counts
            for doc_id in document_ids:
                document = await db_session.get(Document, doc_id)
                if document:
                    document.increment_query_count()
            
            # Update chunk retrieval counts
            for doc_id, chunk_index in chunk_ids:
                if doc_id:
                    chunk_query = select(DocumentChunk).where(
                        and_(
                            DocumentChunk.document_id == doc_id,
                            DocumentChunk.chunk_index == chunk_index
                        )
                    )
                    result = await db_session.execute(chunk_query)
                    chunk = result.scalar_one_or_none()
                    if chunk:
                        chunk.increment_retrieval_count()
            
            await db_session.commit()
            
        except Exception as e:
            logger.warning(f"Failed to update retrieval stats: {str(e)}")
    
    async def get_retrieval_analytics(
        self,
        db_session: AsyncSession,
        days: int = 30
    ) -> Dict[str, Any]:
        """
        Get retrieval analytics and statistics.
        
        Args:
            db_session: Database session
            days: Number of days to analyze
            
        Returns:
            Dict with retrieval analytics
        """
        try:
            # Get vector database stats
            vector_stats = await self.vector_service.get_collection_stats()
            
            # Get document retrieval stats
            # This would be enhanced with actual time-based queries
            analytics = {
                "vector_database": vector_stats,
                "retrieval_performance": {
                    "average_response_time_ms": 150,  # Placeholder
                    "success_rate": 0.95,  # Placeholder
                    "total_queries": 1000,  # Placeholder
                },
                "content_analysis": {
                    "most_retrieved_keywords": vector_stats.get("top_keywords", {}),
                    "qa_pair_usage": vector_stats.get("qa_coverage", 0),
                    "chunk_type_distribution": vector_stats.get("chunk_types", {})
                }
            }
            
            return analytics
            
        except Exception as e:
            logger.error(f"❌ Failed to get retrieval analytics: {str(e)}")
            return {}
