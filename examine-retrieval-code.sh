#!/bin/bash

echo "🔍 Examining RetrievalService code..."

# 1. Vérifier le contenu actuel du fichier
echo "📋 Current content of retrieval_service.py:"
echo "=== START OF FILE ==="
head -20 app/services/retrieval_service.py
echo "=== END OF FILE ==="

echo ""
echo "📋 Looking for _process_search_results method:"
grep -n -A 20 -B 5 "_process_search_results" app/services/retrieval_service.py

echo ""
echo "📋 Looking for retrieve_relevant_chunks method:"
grep -n -A 20 -B 5 "retrieve_relevant_chunks" app/services/retrieval_service.py

echo ""
echo "📋 Looking for bypass messages:"
grep -n "BYPASS\|FINAL BYPASS\|SIMPLE BYPASS" app/services/retrieval_service.py

# 2. Vérifier la syntaxe
echo ""
echo "🔍 Checking Python syntax..."
python3 -m py_compile app/services/retrieval_service.py && echo "✅ Syntax is correct" || echo "❌ Syntax error"

# 3. Créer un test direct dans le conteneur
echo ""
echo "🔍 Testing RetrievalService directly in container..."
docker exec bmi-chat-backend python -c "
import sys
sys.path.append('/app')

from app.services.retrieval_service import RetrievalService
from app.services.vector_service import VectorService

# Test direct
print('Testing RetrievalService...')
rs = RetrievalService()
vs = VectorService()

# Test search
results = vs.search_similar_chunks('BMI-WFS', k=5)
print(f'VectorService found: {len(results.get(\"chunks\", []))} chunks')

# Test retrieval
try:
    chunks = rs.retrieve_relevant_chunks('BMI-WFS', None, k=5, min_score=0.0)
    print(f'RetrievalService returned: {len(chunks)} chunks')
except Exception as e:
    print(f'Error in RetrievalService: {e}')
    import traceback
    traceback.print_exc()
"

echo ""
echo "🎉 Examination complete!" 