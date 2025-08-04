#!/bin/bash

echo "🔧 Verifying syntax and applying simplified bypass..."

# 1. Vérifier la syntaxe actuelle
echo "📋 Checking current syntax..."
python -m py_compile app/services/retrieval_service.py && echo "✅ Current syntax is correct" || echo "❌ Current syntax has errors"

# 2. Créer une version simplifiée du bypass
echo "🔧 Creating simplified bypass..."

# Créer une sauvegarde
cp app/services/retrieval_service.py app/services/retrieval_service.py.bak.simple

# Créer un fichier temporaire avec la méthode simplifiée
cat > temp_simple_bypass.py <<'EOF'
    async def _process_search_results(
        self,
        search_results: Dict[str, Any],
        query: str,
        db_session: AsyncSession,
        k: int,
        min_score: float
    ) -> List[Dict[str, Any]]:
        """SIMPLE BYPASS: Returns all results without filtering."""
        logger.warning("=== SIMPLE BYPASS ACTIVATED ===")
        
        if not search_results or not search_results.get("chunks"):
            logger.warning("SIMPLE BYPASS: No chunks to process")
            return []
        
        logger.info(f"SIMPLE BYPASS: Processing {len(search_results['chunks'])} chunks")
        
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
EOF

# 3. Remplacer la méthode
echo "🔧 Replacing method..."
# Trouver la ligne de début
START_LINE=$(grep -n "async def _process_search_results" app/services/retrieval_service.py | cut -d: -f1)
echo "📊 Found method at line: $START_LINE"

if [ ! -z "$START_LINE" ]; then
    # Supprimer l'ancienne méthode (jusqu'à la prochaine méthode ou fin de classe)
    END_LINE=$(grep -n "^    async def\|^class\|^$" app/services/retrieval_service.py | awk -v start="$START_LINE" '$1 > start {print $1}' | head -1)
    if [ -z "$END_LINE" ]; then
        END_LINE=$(wc -l < app/services/retrieval_service.py)
    fi
    
    echo "📊 Will replace from line $START_LINE to line $END_LINE"
    
    # Créer un nouveau fichier sans l'ancienne méthode
    head -n $((START_LINE - 1)) app/services/retrieval_service.py > temp_file.py
    cat temp_simple_bypass.py >> temp_file.py
    tail -n +$((END_LINE + 1)) app/services/retrieval_service.py >> temp_file.py
    
    # Remplacer le fichier original
    mv temp_file.py app/services/retrieval_service.py
    
    echo "✅ Method replaced"
else
    echo "❌ Could not find method start line"
fi

# Nettoyer
rm -f temp_simple_bypass.py

# 4. Vérifier la syntaxe
echo "🔍 Checking new syntax..."
python -m py_compile app/services/retrieval_service.py && echo "✅ New syntax is correct" || echo "❌ New syntax has errors"

# 5. Redémarrer et tester
echo "🔄 Restarting backend..."
docker-compose restart backend

echo "⏳ Waiting for backend to be ready..."
sleep 10

echo "🔍 Testing search with simple bypass..."
curl -X POST "https://bmi.engage-360.net/api/search/semantic" \
  -H "Content-Type: application/json" \
  -d '{"query": "BMI-WFS", "k": 5, "min_score": 0.0}' | jq '.'

echo "🎉 Simple bypass test complete!" 