#!/bin/bash

echo "🔧 Checking and fixing RetrievalService bypass..."

# 1. Vérifier si le bypass est présent
echo "📋 Checking if bypass is applied..."
if grep -q "BYPASSED: Returns all results without filtering" app/services/retrieval_service.py; then
    echo "✅ Bypass is present"
else
    echo "❌ Bypass is NOT present - applying it now..."
    
    # Créer une sauvegarde
    cp app/services/retrieval_service.py app/services/retrieval_service.py.bak.check
    
    # Trouver la ligne de début de la méthode
    START_LINE=$(grep -n "async def _process_search_results" app/services/retrieval_service.py | cut -d: -f1)
    echo "📊 Found method at line: $START_LINE"
    
    # Créer un fichier temporaire avec la nouvelle méthode
    cat > temp_bypass_method.py <<'EOF'
    async def _process_search_results(
        self,
        search_results: Dict[str, Any],
        query: str,
        db_session: AsyncSession,
        k: int,
        min_score: float
    ) -> List[Dict[str, Any]]:
        """BYPASSED: Returns all results without filtering."""
        logger.warning("=== BYPASS ACTIVATED ===")
        
        if not search_results or not search_results.get("chunks"):
            logger.warning("BYPASS: No chunks to process")
            return []
        
        logger.info(f"BYPASS: Processing {len(search_results['chunks'])} chunks")
        
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
            logger.info(f"BYPASS: Added chunk {i+1} with score {score}")
        
        logger.info(f"BYPASS: Returning {len(enhanced_chunks)} chunks")
        return enhanced_chunks
EOF
    
    # Remplacer la méthode dans le fichier
    if [ ! -z "$START_LINE" ]; then
        # Supprimer l'ancienne méthode et ajouter la nouvelle
        sed -i "${START_LINE},/^    return enhanced_chunks$/d" app/services/retrieval_service.py
        sed -i "${START_LINE}i\\$(cat temp_bypass_method.py)" app/services/retrieval_service.py
        
        echo "✅ Method replaced"
    else
        echo "❌ Could not find method start line"
    fi
    
    # Nettoyer
    rm -f temp_bypass_method.py
fi

# 2. Vérifier la syntaxe Python
echo "🔍 Checking Python syntax..."
python -m py_compile app/services/retrieval_service.py && echo "✅ Syntax is correct" || echo "❌ Syntax error"

# 3. Redémarrer le backend
echo "🔄 Restarting backend..."
docker-compose restart backend

# 4. Attendre que le backend soit prêt
echo "⏳ Waiting for backend to be ready..."
sleep 10

# 5. Tester la recherche
echo "🔍 Testing search with bypass..."
curl -X POST "https://bmi.engage-360.net/api/search/semantic" \
  -H "Content-Type: application/json" \
  -d '{"query": "BMI-WFS", "k": 5, "min_score": 0.0}' | jq '.'

echo "🎉 Check and fix complete!" 