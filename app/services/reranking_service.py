"""
BMI Chat Application - Re-ranking Service

This module provides cross-encoder re-ranking for improving retrieval quality.
Uses sentence-transformers cross-encoders to re-rank retrieved chunks based on query relevance.
"""

import asyncio
from typing import List, Dict, Any, Tuple, Optional
from pathlib import Path
import torch

from loguru import logger
from sentence_transformers import CrossEncoder

from app.config import settings
from app.core.exceptions import ReRankingError


class ReRankingService:
    """
    Cross-encoder re-ranking service for improving retrieval quality.
    
    Uses pre-trained cross-encoder models to re-rank retrieved chunks
    based on query-document relevance scores.
    """
    
    def __init__(self):
        self.model = None
        self.model_name = "cross-encoder/ms-marco-MiniLM-L-6-v2"  # Multilingual support
        self.device = "cuda" if torch.cuda.is_available() else "cpu"
        self.max_length = 512  # Maximum sequence length for cross-encoder
        self.batch_size = 32   # Batch size for processing
        
    async def initialize(self) -> None:
        """
        Initialize the cross-encoder model.
        
        Raises:
            ReRankingError: If model initialization fails
        """
        try:
            logger.info(f"🔧 Initializing cross-encoder model: {self.model_name}")
            
            # Load model in a separate thread to avoid blocking
            loop = asyncio.get_event_loop()
            self.model = await loop.run_in_executor(
                None, 
                self._load_model
            )
            
            logger.info(f"✅ Cross-encoder model loaded on {self.device}")
            
        except Exception as e:
            logger.error(f"❌ Failed to initialize cross-encoder: {str(e)}")
            raise ReRankingError(f"Cross-encoder initialization failed: {str(e)}")
    
    def _load_model(self) -> CrossEncoder:
        """Load the cross-encoder model (runs in thread)."""
        return CrossEncoder(
            self.model_name,
            max_length=self.max_length,
            device=self.device
        )
    
    async def rerank_chunks(
        self,
        query: str,
        chunks: List[Dict[str, Any]],
        top_k: Optional[int] = None,
        min_score: float = 0.0
    ) -> List[Dict[str, Any]]:
        """
        Re-rank retrieved chunks using cross-encoder.
        
        Args:
            query: User query text
            chunks: List of retrieved chunks with content and metadata
            top_k: Number of top chunks to return (None = all)
            min_score: Minimum re-ranking score threshold
            
        Returns:
            List of re-ranked chunks with updated scores
        """
        if not chunks:
            return []
        
        if not self.model:
            await self.initialize()
        
        try:
            logger.info(f"🔄 Re-ranking {len(chunks)} chunks for query: {query[:50]}...")
            
            # Prepare query-document pairs
            pairs = []
            for chunk in chunks:
                content = chunk.get("content", "")
                # Truncate content if too long
                if len(content) > 1000:  # Rough character limit
                    content = content[:1000] + "..."
                pairs.append([query, content])
            
            # Get re-ranking scores
            rerank_scores = await self._compute_rerank_scores(pairs)
            
            # Update chunks with re-ranking scores
            reranked_chunks = []
            for i, chunk in enumerate(chunks):
                updated_chunk = chunk.copy()
                rerank_score = rerank_scores[i] if i < len(rerank_scores) else 0.0
                
                # Combine original similarity score with re-ranking score
                original_score = chunk.get("score", 0.0)
                combined_score = self._combine_scores(original_score, rerank_score)
                
                updated_chunk.update({
                    "rerank_score": float(rerank_score),
                    "original_score": original_score,
                    "combined_score": combined_score,
                    "score": combined_score  # Update main score
                })
                
                # Apply minimum score filter
                if combined_score >= min_score:
                    reranked_chunks.append(updated_chunk)
            
            # Sort by combined score
            reranked_chunks.sort(key=lambda x: x["combined_score"], reverse=True)
            
            # Apply top_k limit
            if top_k:
                reranked_chunks = reranked_chunks[:top_k]
            
            logger.info(f"✅ Re-ranked to {len(reranked_chunks)} chunks")
            return reranked_chunks
            
        except Exception as e:
            logger.error(f"❌ Re-ranking failed: {str(e)}")
            # Return original chunks if re-ranking fails
            logger.warning("Falling back to original chunk order")
            return chunks[:top_k] if top_k else chunks
    
    async def _compute_rerank_scores(self, pairs: List[List[str]]) -> List[float]:
        """Compute re-ranking scores for query-document pairs."""
        try:
            # Process in batches to manage memory
            all_scores = []
            
            for i in range(0, len(pairs), self.batch_size):
                batch_pairs = pairs[i:i + self.batch_size]
                
                # Run prediction in thread to avoid blocking
                loop = asyncio.get_event_loop()
                batch_scores = await loop.run_in_executor(
                    None,
                    self.model.predict,
                    batch_pairs
                )
                
                all_scores.extend(batch_scores.tolist())
            
            return all_scores
            
        except Exception as e:
            logger.error(f"❌ Score computation failed: {str(e)}")
            # Return neutral scores if computation fails
            return [0.5] * len(pairs)
    
    def _combine_scores(
        self,
        similarity_score: float,
        rerank_score: float,
        similarity_weight: float = 0.3,
        rerank_weight: float = 0.7
    ) -> float:
        """
        Combine similarity and re-ranking scores.
        
        Args:
            similarity_score: Original vector similarity score (0-1)
            rerank_score: Cross-encoder re-ranking score (can be negative)
            similarity_weight: Weight for similarity score
            rerank_weight: Weight for re-ranking score
            
        Returns:
            Combined score (0-1)
        """
        # Normalize re-ranking score to 0-1 range using sigmoid
        normalized_rerank = 1 / (1 + torch.exp(-torch.tensor(rerank_score)).item())
        
        # Weighted combination
        combined = (similarity_weight * similarity_score + 
                   rerank_weight * normalized_rerank)
        
        return max(0.0, min(1.0, combined))  # Clamp to [0, 1]
    
    async def evaluate_relevance(
        self,
        query: str,
        content: str,
        threshold: float = 0.5
    ) -> Tuple[bool, float]:
        """
        Evaluate if content is relevant to query.
        
        Args:
            query: User query
            content: Content to evaluate
            threshold: Relevance threshold
            
        Returns:
            Tuple of (is_relevant, relevance_score)
        """
        if not self.model:
            await self.initialize()
        
        try:
            # Truncate content if too long
            if len(content) > 1000:
                content = content[:1000] + "..."
            
            # Get relevance score
            loop = asyncio.get_event_loop()
            score = await loop.run_in_executor(
                None,
                self.model.predict,
                [[query, content]]
            )
            
            relevance_score = float(score[0])
            is_relevant = relevance_score >= threshold
            
            return is_relevant, relevance_score
            
        except Exception as e:
            logger.error(f"❌ Relevance evaluation failed: {str(e)}")
            return False, 0.0
    
    def get_model_info(self) -> Dict[str, Any]:
        """Get information about the loaded model."""
        return {
            "model_name": self.model_name,
            "device": self.device,
            "max_length": self.max_length,
            "batch_size": self.batch_size,
            "is_loaded": self.model is not None
        }
