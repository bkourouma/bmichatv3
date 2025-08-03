"""
BMI Chat Application - QA-Aware Chunking Service

This module provides intelligent chunking that recognizes Q&A format content
and preserves complete question-answer pairs as single chunks.
"""

import re
from typing import List, Dict, Any, Tuple, Optional
from dataclasses import dataclass
from enum import Enum

from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain.schema import Document as LangChainDocument
from loguru import logger

from app.config import settings


class ChunkType(str, Enum):
    """Chunk type enumeration."""
    QA_PAIR = "qa_pair"
    REGULAR = "regular"
    HEADER = "header"
    LIST_ITEM = "list_item"


@dataclass
class ChunkMetadata:
    """Metadata for a text chunk."""
    chunk_type: ChunkType
    length: int
    word_count: int
    has_questions: bool
    has_answers: bool
    language_detected: str = "fr"
    confidence_score: float = 1.0


class QAChunker:
    """
    Intelligent chunker that recognizes Q&A format content.
    
    Features:
    - QA Format Detection: Recognizes `---QA---` delimited content
    - Smart Chunking: Complete Q&A pairs preserved as single chunks
    - Fallback: RecursiveCharacterTextSplitter for regular documents
    - Metadata Enrichment: Adds chunk type, length, content analysis
    """
    
    def __init__(self):
        self.qa_delimiter = "---QA---"
        self.question_patterns = [
            r'^Q\s*[:.]?\s*(.+?)$',  # Q: or Q.
            r'^Question\s*[:.]?\s*(.+?)$',  # Question:
            r'^(\d+)\.\s*(.+?\?)$',  # 1. What is...?
            r'^(.+?\?)$',  # Direct questions ending with ?
            r'^Comment\s+(.+?\?)$',  # Comment faire...?
            r'^Que\s+(.+?\?)$',  # Que faire...?
            r'^Pourquoi\s+(.+?\?)$',  # Pourquoi...?
        ]
        
        self.answer_patterns = [
            r'^R\s*[:.]?\s*(.+?)$',  # R: or R.
            r'^A\s*[:.]?\s*(.+?)$',  # A: or A.
            r'^Answer\s*[:.]?\s*(.+?)$',  # Answer:
            r'^Réponse\s*[:.]?\s*(.+?)$',  # Réponse:
        ]
        
        # Enhanced separators for better French text chunking
        self.french_separators = [
            "\n\n",  # Paragraph breaks
            "\n",    # Line breaks
            ". ",    # Sentence endings
            "! ",    # Exclamation sentences
            "? ",    # Question sentences
            "; ",    # Semicolons
            ", ",    # Commas
            " ",     # Spaces
            ""       # Character level
        ]

        self.fallback_splitter = RecursiveCharacterTextSplitter(
            chunk_size=settings.chunk_size,
            chunk_overlap=settings.chunk_overlap,
            length_function=len,
            separators=self.french_separators
        )

        # Enhanced chunking settings
        self.semantic_overlap_ratio = 0.15  # 15% semantic overlap
        self.min_chunk_size = 100  # Minimum chunk size
        self.max_chunk_size = settings.chunk_size * 1.5  # Allow larger chunks for complete thoughts
    
    def chunk_document(
        self,
        text_content: str,
        document_metadata: Dict[str, Any] = None
    ) -> List[Tuple[str, ChunkMetadata]]:
        """
        Chunk document with QA-aware processing.
        
        Args:
            text_content: Raw text content
            document_metadata: Document metadata
            
        Returns:
            List of (chunk_text, metadata) tuples
        """
        if not text_content.strip():
            return []
        
        logger.info("📝 Starting QA-aware chunking")
        
        # Check if document contains QA format
        if self._has_qa_format(text_content):
            logger.info("🔍 QA format detected, using specialized chunking")
            return self._chunk_qa_content(text_content, document_metadata)
        else:
            logger.info("📄 Regular document detected, using enhanced semantic chunking")
            return self._chunk_regular_content_enhanced(text_content, document_metadata)
    
    def _has_qa_format(self, text: str) -> bool:
        """Check if text contains QA format indicators."""
        # Check for explicit QA delimiter
        if self.qa_delimiter in text:
            return True
        
        # Check for Q&A patterns
        lines = text.split('\n')
        question_count = 0
        answer_count = 0
        
        for line in lines:
            line = line.strip()
            if not line:
                continue
            
            # Check for question patterns
            for pattern in self.question_patterns:
                if re.match(pattern, line, re.IGNORECASE):
                    question_count += 1
                    break
            
            # Check for answer patterns
            for pattern in self.answer_patterns:
                if re.match(pattern, line, re.IGNORECASE):
                    answer_count += 1
                    break
        
        # Consider it QA format if we have multiple Q&A pairs
        return question_count >= 2 and answer_count >= 2
    
    def _chunk_qa_content(
        self,
        text: str,
        document_metadata: Dict[str, Any] = None
    ) -> List[Tuple[str, ChunkMetadata]]:
        """Chunk QA-formatted content preserving Q&A pairs."""
        chunks = []
        
        # Split by QA delimiter if present
        if self.qa_delimiter in text:
            sections = text.split(self.qa_delimiter)
            for i, section in enumerate(sections):
                if section.strip():
                    if i == 0:
                        # First section might be introduction
                        chunks.extend(self._process_intro_section(section.strip()))
                    else:
                        # QA sections
                        chunks.extend(self._process_qa_section(section.strip()))
        else:
            # Process as continuous QA content
            chunks.extend(self._extract_qa_pairs(text))
        
        logger.info(f"✅ Created {len(chunks)} QA-aware chunks")
        return chunks
    
    def _process_intro_section(self, text: str) -> List[Tuple[str, ChunkMetadata]]:
        """Process introduction/header section."""
        if len(text) <= settings.chunk_size:
            metadata = ChunkMetadata(
                chunk_type=ChunkType.HEADER,
                length=len(text),
                word_count=len(text.split()),
                has_questions=self._has_questions(text),
                has_answers=self._has_answers(text)
            )
            return [(text, metadata)]
        else:
            # Split large intro sections
            return self._chunk_regular_content(text)
    
    def _process_qa_section(self, text: str) -> List[Tuple[str, ChunkMetadata]]:
        """Process a QA section."""
        return self._extract_qa_pairs(text)
    
    def _extract_qa_pairs(self, text: str) -> List[Tuple[str, ChunkMetadata]]:
        """Extract Q&A pairs from text."""
        chunks = []
        lines = text.split('\n')
        current_qa = []
        current_question = None
        current_answer = []
        
        for line in lines:
            line = line.strip()
            if not line:
                continue
            
            # Check if this is a question
            is_question = self._is_question_line(line)
            is_answer = self._is_answer_line(line)
            
            if is_question:
                # Save previous Q&A pair if exists
                if current_question and current_answer:
                    qa_text = f"{current_question}\n{' '.join(current_answer)}"
                    chunks.append(self._create_qa_chunk(qa_text))
                
                # Start new Q&A pair
                current_question = line
                current_answer = []
            elif is_answer:
                # Start answer section
                current_answer = [line]
            elif current_question and not is_question:
                # Continue answer section
                current_answer.append(line)
            else:
                # Standalone content
                if len(line) > 50:  # Only chunk substantial content
                    metadata = ChunkMetadata(
                        chunk_type=ChunkType.REGULAR,
                        length=len(line),
                        word_count=len(line.split()),
                        has_questions=self._has_questions(line),
                        has_answers=self._has_answers(line)
                    )
                    chunks.append((line, metadata))
        
        # Don't forget the last Q&A pair
        if current_question and current_answer:
            qa_text = f"{current_question}\n{' '.join(current_answer)}"
            chunks.append(self._create_qa_chunk(qa_text))
        
        return chunks
    
    def _create_qa_chunk(self, qa_text: str) -> Tuple[str, ChunkMetadata]:
        """Create a Q&A chunk with metadata."""
        metadata = ChunkMetadata(
            chunk_type=ChunkType.QA_PAIR,
            length=len(qa_text),
            word_count=len(qa_text.split()),
            has_questions=True,
            has_answers=True,
            confidence_score=0.9
        )
        return (qa_text, metadata)
    
    def _is_question_line(self, line: str) -> bool:
        """Check if line is a question."""
        for pattern in self.question_patterns:
            if re.match(pattern, line, re.IGNORECASE):
                return True
        return False
    
    def _is_answer_line(self, line: str) -> bool:
        """Check if line is an answer."""
        for pattern in self.answer_patterns:
            if re.match(pattern, line, re.IGNORECASE):
                return True
        return False
    
    def _has_questions(self, text: str) -> bool:
        """Check if text contains questions."""
        return '?' in text or any(
            re.search(pattern, text, re.IGNORECASE) 
            for pattern in self.question_patterns
        )
    
    def _has_answers(self, text: str) -> bool:
        """Check if text contains answer indicators."""
        return any(
            re.search(pattern, text, re.IGNORECASE) 
            for pattern in self.answer_patterns
        )
    
    def _chunk_regular_content(
        self,
        text: str,
        document_metadata: Dict[str, Any] = None
    ) -> List[Tuple[str, ChunkMetadata]]:
        """Fallback chunking for regular content."""
        # Create LangChain document
        langchain_doc = LangChainDocument(
            page_content=text,
            metadata=document_metadata or {}
        )
        
        # Split using RecursiveCharacterTextSplitter
        chunks = self.fallback_splitter.split_documents([langchain_doc])
        
        # Convert to our format with metadata
        result = []
        for chunk in chunks:
            metadata = ChunkMetadata(
                chunk_type=ChunkType.REGULAR,
                length=len(chunk.page_content),
                word_count=len(chunk.page_content.split()),
                has_questions=self._has_questions(chunk.page_content),
                has_answers=self._has_answers(chunk.page_content)
            )
            result.append((chunk.page_content, metadata))
        
        return result
    
    def get_chunk_summary(self, chunks: List[Tuple[str, ChunkMetadata]]) -> Dict[str, Any]:
        """Get summary statistics for chunks."""
        if not chunks:
            return {}
        
        total_chunks = len(chunks)
        qa_chunks = sum(1 for _, meta in chunks if meta.chunk_type == ChunkType.QA_PAIR)
        regular_chunks = sum(1 for _, meta in chunks if meta.chunk_type == ChunkType.REGULAR)
        header_chunks = sum(1 for _, meta in chunks if meta.chunk_type == ChunkType.HEADER)
        
        total_length = sum(meta.length for _, meta in chunks)
        avg_length = total_length / total_chunks if total_chunks > 0 else 0
        
        chunks_with_questions = sum(1 for _, meta in chunks if meta.has_questions)
        chunks_with_answers = sum(1 for _, meta in chunks if meta.has_answers)
        
        return {
            "total_chunks": total_chunks,
            "qa_pairs": qa_chunks,
            "regular_chunks": regular_chunks,
            "header_chunks": header_chunks,
            "total_length": total_length,
            "average_length": round(avg_length, 2),
            "chunks_with_questions": chunks_with_questions,
            "chunks_with_answers": chunks_with_answers,
            "qa_coverage": round((qa_chunks / total_chunks) * 100, 2) if total_chunks > 0 else 0
        }

    def _chunk_regular_content_enhanced(
        self,
        text_content: str,
        document_metadata: Dict[str, Any] = None
    ) -> List[Tuple[str, ChunkMetadata]]:
        """
        Enhanced chunking for regular content with semantic overlap.

        Args:
            text_content: Raw text content
            document_metadata: Document metadata

        Returns:
            List of (chunk_text, metadata) tuples with enhanced overlap
        """
        chunks_with_metadata = []

        # First pass: Use standard recursive splitter
        langchain_docs = self.fallback_splitter.split_text(text_content)

        # Second pass: Apply semantic overlap and optimization
        optimized_chunks = self._apply_semantic_overlap(langchain_docs)

        # Third pass: Create metadata for each chunk
        for i, chunk_text in enumerate(optimized_chunks):
            if len(chunk_text.strip()) < self.min_chunk_size:
                continue  # Skip very small chunks

            metadata = self._create_enhanced_metadata(
                chunk_text, ChunkType.REGULAR, i, document_metadata
            )
            chunks_with_metadata.append((chunk_text, metadata))

        logger.info(f"📊 Enhanced chunking: {len(chunks_with_metadata)} chunks created")
        return chunks_with_metadata

    def _apply_semantic_overlap(self, chunks: List[str]) -> List[str]:
        """
        Apply semantic overlap between chunks for better context preservation.

        Args:
            chunks: List of text chunks

        Returns:
            List of chunks with semantic overlap applied
        """
        if len(chunks) <= 1:
            return chunks

        overlapped_chunks = []

        for i, chunk in enumerate(chunks):
            enhanced_chunk = chunk

            # Add overlap from previous chunk
            if i > 0:
                prev_chunk = chunks[i - 1]
                overlap_size = int(len(prev_chunk) * self.semantic_overlap_ratio)
                if overlap_size > 0:
                    prev_overlap = prev_chunk[-overlap_size:]
                    # Find sentence boundary for clean overlap
                    sentence_end = prev_overlap.rfind('. ')
                    if sentence_end > overlap_size // 2:
                        prev_overlap = prev_overlap[sentence_end + 2:]
                    enhanced_chunk = prev_overlap + " " + enhanced_chunk

            # Add overlap from next chunk
            if i < len(chunks) - 1:
                next_chunk = chunks[i + 1]
                overlap_size = int(len(next_chunk) * self.semantic_overlap_ratio)
                if overlap_size > 0:
                    next_overlap = next_chunk[:overlap_size]
                    # Find sentence boundary for clean overlap
                    sentence_end = next_overlap.find('. ')
                    if sentence_end > 0 and sentence_end < overlap_size // 2:
                        next_overlap = next_overlap[:sentence_end + 1]
                    enhanced_chunk = enhanced_chunk + " " + next_overlap

            # Ensure chunk doesn't exceed max size
            if len(enhanced_chunk) > self.max_chunk_size:
                enhanced_chunk = enhanced_chunk[:int(self.max_chunk_size)]
                # Try to end at sentence boundary
                last_sentence = enhanced_chunk.rfind('. ')
                if last_sentence > self.max_chunk_size * 0.8:
                    enhanced_chunk = enhanced_chunk[:last_sentence + 1]

            overlapped_chunks.append(enhanced_chunk.strip())

        return overlapped_chunks

    def _create_enhanced_metadata(
        self,
        chunk_text: str,
        chunk_type: ChunkType,
        chunk_index: int,
        document_metadata: Dict[str, Any] = None
    ) -> ChunkMetadata:
        """
        Create enhanced metadata with additional analysis.

        Args:
            chunk_text: Text content of the chunk
            chunk_type: Type of the chunk
            chunk_index: Index of the chunk
            document_metadata: Document metadata

        Returns:
            Enhanced ChunkMetadata object
        """
        # Basic metrics
        length = len(chunk_text)
        word_count = len(chunk_text.split())

        # Content analysis
        has_questions = self._has_questions(chunk_text)
        has_answers = self._has_answers(chunk_text)

        # Language detection (simple heuristic for French)
        french_indicators = ['le ', 'la ', 'les ', 'de ', 'du ', 'des ', 'et ', 'ou ', 'que ', 'qui ']
        french_score = sum(1 for indicator in french_indicators if indicator in chunk_text.lower())
        language_detected = "fr" if french_score > 2 else "unknown"

        # Confidence score based on content quality
        confidence_score = self._calculate_content_confidence(chunk_text, has_questions, has_answers)

        return ChunkMetadata(
            chunk_type=chunk_type,
            length=length,
            word_count=word_count,
            has_questions=has_questions,
            has_answers=has_answers,
            language_detected=language_detected,
            confidence_score=confidence_score
        )

    def _calculate_content_confidence(
        self,
        chunk_text: str,
        has_questions: bool,
        has_answers: bool
    ) -> float:
        """
        Calculate confidence score for chunk content quality.

        Args:
            chunk_text: Text content
            has_questions: Whether chunk contains questions
            has_answers: Whether chunk contains answers

        Returns:
            Confidence score between 0.0 and 1.0
        """
        score = 0.5  # Base score

        # Length-based scoring
        if len(chunk_text) > self.min_chunk_size * 2:
            score += 0.2
        elif len(chunk_text) < self.min_chunk_size:
            score -= 0.3

        # Content type scoring
        if has_questions and has_answers:
            score += 0.3  # Complete Q&A is valuable
        elif has_questions or has_answers:
            score += 0.1  # Partial Q&A is somewhat valuable

        # Text quality indicators
        if '. ' in chunk_text:  # Has complete sentences
            score += 0.1
        if chunk_text.count('\n') > 1:  # Has structure
            score += 0.1

        # Penalize very short or very repetitive content
        words = chunk_text.split()
        if len(set(words)) < len(words) * 0.5:  # High repetition
            score -= 0.2

        return max(0.0, min(1.0, score))
