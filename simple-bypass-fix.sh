#!/bin/bash

echo "🔧 Applying simple bypass fix..."

# 1. Créer une sauvegarde
cp app/services/retrieval_service.py app/services/retrieval_service.py.bak.simple2

# 2. Trouver la méthode retrieve_relevant_chunks
echo "📋 Finding retrieve_relevant_chunks method..."
START_LINE=$(grep -n "async def retrieve_relevant_chunks" app/services/retrieval_service.py | cut -d: -f1)
echo "📊 Found method at line: $START_LINE"

if [ ! -z "$START_LINE" ]; then
    # Trouver la fin de la méthode
    END_LINE=$(grep -n "^    async def\|^class\|^$" app/services/retrieval_service.py | awk -v start="$START_LINE" '$1 > start {print $1}' | head -1)
    if [ -z "$END_LINE" ]; then
        END_LINE=$(wc -l < app/services/retrieval_service.py)
    fi
    
    echo "📊 Will replace from line $START_LINE to line $END_LINE"
    
    # Créer une nouvelle version simplifiée de la méthode
    cat > new_retrieval_method.py <<'EOF'
    async def retrieve_relevant_chunks(
        self,
        query: str,
        db_session: AsyncSession,
        k: int = 5,
        min_score: float = 0.3,
        use_reranking: bool = False
    ) -> List[Dict[str, Any]]:
        """SIMPLE BYPASS: Returns all chunks without filtering."""
        logger.warning("=== SIMPLE BYPASS ACTIVATED ===")
        
        try:
            # Get search results from vector service
            search_results = self.vector_service.search_similar_chunks(query, k=k)
            
            if not search_results or not search_results.get("chunks"):
                logger.warning("SIMPLE BYPASS: No chunks found")
                return []
            
            logger.info(f"SIMPLE BYPASS: Found {len(search_results['chunks'])} chunks")
            
            # Return all chunks without filtering
            enhanced_chunks = []
            for i, chunk_text in enumerate(search_results["chunks"]):
                score = search_results["scores"][i] if i < len(search_results["scores"]) else 0.0
                distance = search_results["distances"][i] if i < len(search_results["distances"]) else 1.0
                
                enhanced_chunk = {
                    "chunk_text": chunk_text,
                    "score": score,
                    "distance": distance,
                    "metadata": search_results.get("metadatas", [{}])[i] if search_results.get("metadatas") else {},
                    "document_id": search_results.get("metadatas", [{}])[i].get("document_id", "unknown") if search_results.get("metadatas") else "unknown"
                }
                enhanced_chunks.append(enhanced_chunk)
                logger.info(f"SIMPLE BYPASS: Added chunk {i+1} with score {score}")
            
            logger.info(f"SIMPLE BYPASS: Returning {len(enhanced_chunks)} chunks")
            return enhanced_chunks
            
        except Exception as e:
            logger.error(f"SIMPLE BYPASS: Error: {e}")
            return []
EOF
    
    # Remplacer la méthode
    head -n $((START_LINE - 1)) app/services/retrieval_service.py > temp_new_file.py
    cat new_retrieval_method.py >> temp_new_file.py
    tail -n +$((END_LINE + 1)) app/services/retrieval_service.py >> temp_new_file.py
    
    # Remplacer le fichier original
    mv temp_new_file.py app/services/retrieval_service.py
    
    echo "✅ Method replaced successfully"
else
    echo "❌ Could not find retrieve_relevant_chunks method"
    exit 1
fi

# Nettoyer
rm -f new_retrieval_method.py

# 3. Vérifier la syntaxe
echo "🔍 Checking Python syntax..."
python3 -m py_compile app/services/retrieval_service.py && echo "✅ Syntax is correct" || echo "❌ Syntax error"

# 4. Redémarrer le backend
echo "🔄 Restarting backend..."
docker-compose restart backend

# 5. Attendre que le backend soit prêt
echo "⏳ Waiting for backend to be ready..."
sleep 10

# 6. Tester la recherche
echo "🔍 Testing search with simple bypass..."
curl -X POST "https://bmi.engage-360.net/api/search/semantic" \
  -H "Content-Type: application/json" \
  -d '{"query": "BMI-WFS", "k": 5, "min_score": 0.0}' | jq '.'

echo "🎉 Simple bypass fix complete!" 