"""
BMI Chat Application - Metrics Service

This module provides comprehensive metrics and analytics for the RAG pipeline.
Tracks performance, quality, and usage statistics for continuous optimization.
"""

import time
from datetime import datetime, timedelta
from typing import Dict, List, Any, Optional, Tuple
from dataclasses import dataclass, asdict
from collections import defaultdict, deque
import json

from loguru import logger
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, and_

from app.models import ChatMessage, ChatSession, Document, DocumentChunk


@dataclass
class RetrievalMetrics:
    """Metrics for a single retrieval operation."""
    query: str
    strategy: str
    chunks_retrieved: int
    top_score: float
    avg_score: float
    response_time_ms: float
    reranking_enabled: bool
    timestamp: datetime


@dataclass
class PerformanceMetrics:
    """Performance metrics for the RAG pipeline."""
    avg_retrieval_time_ms: float
    avg_reranking_time_ms: float
    avg_generation_time_ms: float
    total_requests: int
    success_rate: float
    strategy_distribution: Dict[str, int]


@dataclass
class QualityMetrics:
    """Quality metrics for responses."""
    avg_confidence_score: float
    high_confidence_rate: float
    medium_confidence_rate: float
    low_confidence_rate: float
    no_answer_rate: float
    avg_sources_used: float


class MetricsService:
    """
    Service for collecting and analyzing RAG pipeline metrics.
    
    Provides real-time monitoring and historical analysis of:
    - Retrieval performance
    - Response quality
    - User satisfaction
    - System efficiency
    """
    
    def __init__(self, max_history_size: int = 1000):
        self.retrieval_history = deque(maxlen=max_history_size)
        self.performance_cache = {}
        self.cache_ttl = 300  # 5 minutes
        
    def record_retrieval(
        self,
        query: str,
        strategy: str,
        chunks: List[Dict[str, Any]],
        response_time_ms: float,
        reranking_enabled: bool = False
    ) -> None:
        """Record a retrieval operation for metrics."""
        try:
            scores = [chunk.get('combined_score', chunk.get('score', 0.0)) for chunk in chunks]
            
            metrics = RetrievalMetrics(
                query=query[:100],  # Truncate for privacy
                strategy=strategy,
                chunks_retrieved=len(chunks),
                top_score=max(scores) if scores else 0.0,
                avg_score=sum(scores) / len(scores) if scores else 0.0,
                response_time_ms=response_time_ms,
                reranking_enabled=reranking_enabled,
                timestamp=datetime.utcnow()
            )
            
            self.retrieval_history.append(metrics)
            logger.debug(f"📊 Recorded retrieval metrics: {strategy} strategy, {len(chunks)} chunks")
            
        except Exception as e:
            logger.warning(f"Failed to record retrieval metrics: {str(e)}")
    
    def get_performance_metrics(self, hours: int = 24) -> PerformanceMetrics:
        """Get performance metrics for the specified time period."""
        try:
            cutoff_time = datetime.utcnow() - timedelta(hours=hours)
            recent_metrics = [m for m in self.retrieval_history if m.timestamp >= cutoff_time]
            
            if not recent_metrics:
                return PerformanceMetrics(
                    avg_retrieval_time_ms=0.0,
                    avg_reranking_time_ms=0.0,
                    avg_generation_time_ms=0.0,
                    total_requests=0,
                    success_rate=0.0,
                    strategy_distribution={}
                )
            
            # Calculate averages
            avg_retrieval_time = sum(m.response_time_ms for m in recent_metrics) / len(recent_metrics)
            
            # Strategy distribution
            strategy_counts = defaultdict(int)
            for m in recent_metrics:
                strategy_counts[m.strategy] += 1
            
            # Success rate (chunks retrieved > 0)
            successful_requests = sum(1 for m in recent_metrics if m.chunks_retrieved > 0)
            success_rate = successful_requests / len(recent_metrics) if recent_metrics else 0.0
            
            return PerformanceMetrics(
                avg_retrieval_time_ms=avg_retrieval_time,
                avg_reranking_time_ms=0.0,  # TODO: Track separately
                avg_generation_time_ms=0.0,  # TODO: Track separately
                total_requests=len(recent_metrics),
                success_rate=success_rate,
                strategy_distribution=dict(strategy_counts)
            )
            
        except Exception as e:
            logger.error(f"Failed to calculate performance metrics: {str(e)}")
            return PerformanceMetrics(0.0, 0.0, 0.0, 0, 0.0, {})
    
    def get_quality_metrics(self, hours: int = 24) -> QualityMetrics:
        """Get quality metrics for the specified time period."""
        try:
            cutoff_time = datetime.utcnow() - timedelta(hours=hours)
            recent_metrics = [m for m in self.retrieval_history if m.timestamp >= cutoff_time]
            
            if not recent_metrics:
                return QualityMetrics(0.0, 0.0, 0.0, 0.0, 0.0, 0.0)
            
            # Confidence score analysis
            scores = [m.top_score for m in recent_metrics]
            avg_confidence = sum(scores) / len(scores) if scores else 0.0
            
            # Confidence rate distribution
            high_confidence = sum(1 for s in scores if s >= 0.8)
            medium_confidence = sum(1 for s in scores if 0.5 <= s < 0.8)
            low_confidence = sum(1 for s in scores if 0.3 <= s < 0.5)
            no_answer = sum(1 for s in scores if s < 0.3)
            
            total = len(scores)
            
            # Average sources used
            avg_sources = sum(m.chunks_retrieved for m in recent_metrics) / len(recent_metrics)
            
            return QualityMetrics(
                avg_confidence_score=avg_confidence,
                high_confidence_rate=high_confidence / total if total > 0 else 0.0,
                medium_confidence_rate=medium_confidence / total if total > 0 else 0.0,
                low_confidence_rate=low_confidence / total if total > 0 else 0.0,
                no_answer_rate=no_answer / total if total > 0 else 0.0,
                avg_sources_used=avg_sources
            )
            
        except Exception as e:
            logger.error(f"Failed to calculate quality metrics: {str(e)}")
            return QualityMetrics(0.0, 0.0, 0.0, 0.0, 0.0, 0.0)
    
    async def get_database_metrics(self, db_session: AsyncSession) -> Dict[str, Any]:
        """Get metrics from the database."""
        try:
            # Chat session metrics
            session_count = await db_session.scalar(select(func.count(ChatSession.id)))
            
            # Message metrics
            message_count = await db_session.scalar(select(func.count(ChatMessage.id)))
            
            # Document metrics
            document_count = await db_session.scalar(select(func.count(Document.id)))
            
            # Recent activity (last 24 hours)
            cutoff_time = datetime.utcnow() - timedelta(hours=24)
            recent_sessions = await db_session.scalar(
                select(func.count(ChatSession.id)).where(ChatSession.created_at >= cutoff_time)
            )
            
            recent_messages = await db_session.scalar(
                select(func.count(ChatMessage.id)).where(ChatMessage.timestamp >= cutoff_time)
            )
            
            return {
                "total_sessions": session_count or 0,
                "total_messages": message_count or 0,
                "total_documents": document_count or 0,
                "recent_sessions_24h": recent_sessions or 0,
                "recent_messages_24h": recent_messages or 0,
                "avg_messages_per_session": (message_count / session_count) if session_count else 0
            }
            
        except Exception as e:
            logger.error(f"Failed to get database metrics: {str(e)}")
            return {}
    
    def get_optimization_recommendations(self) -> List[str]:
        """Get optimization recommendations based on current metrics."""
        recommendations = []
        
        try:
            perf_metrics = self.get_performance_metrics()
            quality_metrics = self.get_quality_metrics()
            
            # Performance recommendations
            if perf_metrics.avg_retrieval_time_ms > 1000:
                recommendations.append("Consider reducing chunk size or retrieval count for faster responses")
            
            if perf_metrics.success_rate < 0.8:
                recommendations.append("Low success rate detected - consider improving document coverage")
            
            # Quality recommendations
            if quality_metrics.no_answer_rate > 0.3:
                recommendations.append("High no-answer rate - consider lowering confidence thresholds")
            
            if quality_metrics.avg_sources_used < 2:
                recommendations.append("Consider increasing retrieval count for better context")
            
            if quality_metrics.high_confidence_rate < 0.3:
                recommendations.append("Low confidence scores - consider improving document quality or chunking strategy")
            
            # Strategy recommendations
            strategy_dist = perf_metrics.strategy_distribution
            if strategy_dist.get('fallback', 0) > strategy_dist.get('direct', 0):
                recommendations.append("High fallback usage - consider improving embedding quality or document coverage")
            
        except Exception as e:
            logger.error(f"Failed to generate recommendations: {str(e)}")
        
        return recommendations
    
    def export_metrics(self, hours: int = 24) -> Dict[str, Any]:
        """Export comprehensive metrics for analysis."""
        try:
            return {
                "timestamp": datetime.utcnow().isoformat(),
                "period_hours": hours,
                "performance": asdict(self.get_performance_metrics(hours)),
                "quality": asdict(self.get_quality_metrics(hours)),
                "recommendations": self.get_optimization_recommendations(),
                "raw_data": [asdict(m) for m in list(self.retrieval_history)[-100:]]  # Last 100 entries
            }
        except Exception as e:
            logger.error(f"Failed to export metrics: {str(e)}")
            return {}


# Global metrics service instance
metrics_service = MetricsService()
