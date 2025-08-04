#!/bin/bash

echo "🔍 Debugging file content..."

# 1. Vérifier le contenu actuel du fichier
echo "📋 Current content around _process_search_results method:"
grep -n -A 10 -B 5 "_process_search_results" app/services/retrieval_service.py

echo ""
echo "📋 Checking for bypass messages in the file:"
grep -n "BYPASS\|FINAL BYPASS\|SIMPLE BYPASS" app/services/retrieval_service.py

echo ""
echo "📋 Checking method signature:"
grep -n "async def _process_search_results" app/services/retrieval_service.py

# 2. Vérifier la syntaxe avec python3
echo ""
echo "🔍 Checking Python syntax with python3..."
python3 -m py_compile app/services/retrieval_service.py && echo "✅ Syntax is correct" || echo "❌ Syntax error"

# 3. Vérifier les logs du backend
echo ""
echo "🔍 Checking backend logs..."
docker-compose logs --tail=30 backend | grep -A 10 -B 5 "BYPASS\|WARNING\|ERROR\|search\|chunk"

# 4. Tester la recherche et voir les logs en temps réel
echo ""
echo "🔍 Testing search with real-time logs..."
docker-compose logs -f backend | grep -E "(BYPASS|WARNING|ERROR|search|chunk)" &
LOG_PID=$!

sleep 2

curl -X POST "https://bmi.engage-360.net/api/search/semantic" \
  -H "Content-Type: application/json" \
  -d '{"query": "BMI-WFS", "k": 5, "min_score": 0.0}' | jq '.'

sleep 3
kill $LOG_PID 2>/dev/null

echo "�� Debug complete!" 