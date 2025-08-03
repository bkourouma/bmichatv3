"""
BMI Chat Application - Metrics Router

This module provides endpoints for accessing RAG pipeline metrics and analytics.
Includes performance monitoring, quality assessment, and optimization recommendations.
"""

from typing import Dict, Any, Optional
from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession
from pydantic import BaseModel, Field
from loguru import logger

from app.core.database import get_db
from app.services.metrics_service import metrics_service


router = APIRouter()


class MetricsResponse(BaseModel):
    """Response model for metrics data."""
    timestamp: datetime
    period_hours: int
    performance: Dict[str, Any]
    quality: Dict[str, Any]
    database: Dict[str, Any]
    recommendations: list[str]


class PerformanceMetricsResponse(BaseModel):
    """Response model for performance metrics."""
    avg_retrieval_time_ms: float
    avg_reranking_time_ms: float
    avg_generation_time_ms: float
    total_requests: int
    success_rate: float
    strategy_distribution: Dict[str, int]


class QualityMetricsResponse(BaseModel):
    """Response model for quality metrics."""
    avg_confidence_score: float
    high_confidence_rate: float
    medium_confidence_rate: float
    low_confidence_rate: float
    no_answer_rate: float
    avg_sources_used: float


@router.get("/performance", response_model=PerformanceMetricsResponse)
async def get_performance_metrics(
    hours: int = Query(default=24, ge=1, le=168, description="Time period in hours")
):
    """
    Get performance metrics for the RAG pipeline.
    
    Args:
        hours: Time period to analyze (1-168 hours)
        
    Returns:
        Performance metrics including response times and success rates
    """
    try:
        logger.info(f"📊 Getting performance metrics for {hours} hours")
        
        metrics = metrics_service.get_performance_metrics(hours)
        
        return PerformanceMetricsResponse(
            avg_retrieval_time_ms=metrics.avg_retrieval_time_ms,
            avg_reranking_time_ms=metrics.avg_reranking_time_ms,
            avg_generation_time_ms=metrics.avg_generation_time_ms,
            total_requests=metrics.total_requests,
            success_rate=metrics.success_rate,
            strategy_distribution=metrics.strategy_distribution
        )
        
    except Exception as e:
        logger.error(f"❌ Failed to get performance metrics: {str(e)}")
        raise HTTPException(status_code=500, detail="Failed to retrieve performance metrics")


@router.get("/quality", response_model=QualityMetricsResponse)
async def get_quality_metrics(
    hours: int = Query(default=24, ge=1, le=168, description="Time period in hours")
):
    """
    Get quality metrics for the RAG pipeline.
    
    Args:
        hours: Time period to analyze (1-168 hours)
        
    Returns:
        Quality metrics including confidence scores and answer rates
    """
    try:
        logger.info(f"📊 Getting quality metrics for {hours} hours")
        
        metrics = metrics_service.get_quality_metrics(hours)
        
        return QualityMetricsResponse(
            avg_confidence_score=metrics.avg_confidence_score,
            high_confidence_rate=metrics.high_confidence_rate,
            medium_confidence_rate=metrics.medium_confidence_rate,
            low_confidence_rate=metrics.low_confidence_rate,
            no_answer_rate=metrics.no_answer_rate,
            avg_sources_used=metrics.avg_sources_used
        )
        
    except Exception as e:
        logger.error(f"❌ Failed to get quality metrics: {str(e)}")
        raise HTTPException(status_code=500, detail="Failed to retrieve quality metrics")


@router.get("/comprehensive", response_model=MetricsResponse)
async def get_comprehensive_metrics(
    hours: int = Query(default=24, ge=1, le=168, description="Time period in hours"),
    db_session: AsyncSession = Depends(get_db)
):
    """
    Get comprehensive metrics including performance, quality, and database stats.
    
    Args:
        hours: Time period to analyze (1-168 hours)
        db_session: Database session
        
    Returns:
        Comprehensive metrics with recommendations
    """
    try:
        logger.info(f"📊 Getting comprehensive metrics for {hours} hours")
        
        # Get all metrics
        performance_metrics = metrics_service.get_performance_metrics(hours)
        quality_metrics = metrics_service.get_quality_metrics(hours)
        database_metrics = await metrics_service.get_database_metrics(db_session)
        recommendations = metrics_service.get_optimization_recommendations()
        
        return MetricsResponse(
            timestamp=datetime.utcnow(),
            period_hours=hours,
            performance={
                "avg_retrieval_time_ms": performance_metrics.avg_retrieval_time_ms,
                "total_requests": performance_metrics.total_requests,
                "success_rate": performance_metrics.success_rate,
                "strategy_distribution": performance_metrics.strategy_distribution
            },
            quality={
                "avg_confidence_score": quality_metrics.avg_confidence_score,
                "high_confidence_rate": quality_metrics.high_confidence_rate,
                "medium_confidence_rate": quality_metrics.medium_confidence_rate,
                "low_confidence_rate": quality_metrics.low_confidence_rate,
                "no_answer_rate": quality_metrics.no_answer_rate,
                "avg_sources_used": quality_metrics.avg_sources_used
            },
            database=database_metrics,
            recommendations=recommendations
        )
        
    except Exception as e:
        logger.error(f"❌ Failed to get comprehensive metrics: {str(e)}")
        raise HTTPException(status_code=500, detail="Failed to retrieve comprehensive metrics")


@router.get("/recommendations")
async def get_optimization_recommendations():
    """
    Get optimization recommendations based on current metrics.
    
    Returns:
        List of optimization recommendations
    """
    try:
        logger.info("💡 Getting optimization recommendations")
        
        recommendations = metrics_service.get_optimization_recommendations()
        
        return {
            "timestamp": datetime.utcnow(),
            "recommendations": recommendations,
            "count": len(recommendations)
        }
        
    except Exception as e:
        logger.error(f"❌ Failed to get recommendations: {str(e)}")
        raise HTTPException(status_code=500, detail="Failed to retrieve recommendations")


@router.get("/export")
async def export_metrics(
    hours: int = Query(default=24, ge=1, le=168, description="Time period in hours"),
    format: str = Query(default="json", regex="^(json|csv)$", description="Export format")
):
    """
    Export metrics data for external analysis.
    
    Args:
        hours: Time period to analyze (1-168 hours)
        format: Export format (json or csv)
        
    Returns:
        Exported metrics data
    """
    try:
        logger.info(f"📤 Exporting metrics for {hours} hours in {format} format")
        
        metrics_data = metrics_service.export_metrics(hours)
        
        if format == "json":
            return metrics_data
        elif format == "csv":
            # TODO: Implement CSV export
            raise HTTPException(status_code=501, detail="CSV export not yet implemented")
        
    except Exception as e:
        logger.error(f"❌ Failed to export metrics: {str(e)}")
        raise HTTPException(status_code=500, detail="Failed to export metrics")


@router.post("/reset")
async def reset_metrics():
    """
    Reset metrics history (for testing purposes).
    
    Returns:
        Confirmation of reset
    """
    try:
        logger.info("🔄 Resetting metrics history")
        
        metrics_service.retrieval_history.clear()
        
        return {
            "message": "Metrics history reset successfully",
            "timestamp": datetime.utcnow()
        }
        
    except Exception as e:
        logger.error(f"❌ Failed to reset metrics: {str(e)}")
        raise HTTPException(status_code=500, detail="Failed to reset metrics")
