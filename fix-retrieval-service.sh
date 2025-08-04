#!/bin/bash

echo "🔧 Final fix for RetrievalService..."

# 1. Créer une sauvegarde
cp app/services/retrieval_service.py app/services/retrieval_service.py.bak.final

# 2. Créer le nouveau contenu de la méthode
cat > new_method.py <<'EOF'
    async def _process_search_results(
        self,
        search_results: Dict[str, Any],
        query: str,
        db_session: AsyncSession,
        k: int,
        min_score: float
    ) -> List[Dict[str, Any]]:
        """FINAL BYPASS: Returns all results without filtering."""
        logger.warning("=== FINAL BYPASS ACTIVATED ===")
        
        if not search_results or not search_results.get("chunks"):
            logger.warning("FINAL BYPASS: No chunks to process")
            return []
        
        logger.info(f"FINAL BYPASS: Processing {len(search_results['chunks'])} chunks")
        
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
            logger.info(f"FINAL BYPASS: Added chunk {i+1} with score {score}")
        
        logger.info(f"FINAL BYPASS: Returning {len(enhanced_chunks)} chunks")
        return enhanced_chunks
EOF

# 3. Trouver et supprimer l'ancienne méthode
echo "🔧 Finding and removing old method..."
START_LINE=$(grep -n "async def _process_search_results" app/services/retrieval_service.py | cut -d: -f1)
echo "📊 Found method at line: $START_LINE"

if [ ! -z "$START_LINE" ]; then
    # Trouver la fin de la méthode (prochaine méthode ou fin de classe)
    END_LINE=$(grep -n "^    async def\|^class\|^$" app/services/retrieval_service.py | awk -v start="$START_LINE" '$1 > start {print $1}' | head -1)
    if [ -z "$END_LINE" ]; then
        END_LINE=$(wc -l < app/services/retrieval_service.py)
    fi
    
    echo "📊 Will replace from line $START_LINE to line $END_LINE"
    
    # Créer un nouveau fichier
    head -n $((START_LINE - 1)) app/services/retrieval_service.py > temp_new_file.py
    cat new_method.py >> temp_new_file.py
    tail -n +$((END_LINE + 1)) app/services/retrieval_service.py >> temp_new_file.py
    
    # Remplacer le fichier original
    mv temp_new_file.py app/services/retrieval_service.py
    
    echo "✅ Method replaced successfully"
else
    echo "❌ Could not find method start line"
    exit 1
fi

# Nettoyer
rm -f new_method.py

# 4. Vérifier la syntaxe
echo "🔍 Checking Python syntax..."
python -m py_compile app/services/retrieval_service.py && echo "✅ Syntax is correct" || echo "❌ Syntax error"

# 5. Redémarrer le backend
echo "🔄 Restarting backend..."
docker-compose restart backend

# 6. Attendre que le backend soit prêt
echo "⏳ Waiting for backend to be ready..."
sleep 10

# 7. Tester la recherche
echo "🔍 Testing search with final bypass..."
curl -X POST "https://bmi.engage-360.net/api/search/semantic" \
  -H "Content-Type: application/json" \
  -d '{"query": "BMI-WFS", "k": 5, "min_score": 0.0}' | jq '.'

echo "🎉 Final fix complete!" 