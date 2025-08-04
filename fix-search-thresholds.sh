#!/bin/bash

echo "🔧 Fix Search Thresholds"
echo "======================="

# Step 1: Test with no threshold
echo "📊 Step 1: Testing with no threshold..."
curl -X POST "https://bmi.engage-360.net/api/search/semantic" \
  -H "Content-Type: application/json" \
  -d '{"query": "BMI-WFS", "k": 5}' | jq '.'

# Step 2: Test with very low threshold
echo ""
echo "📊 Step 2: Testing with very low threshold..."
curl -X POST "https://bmi.engage-360.net/api/search/semantic" \
  -H "Content-Type: application/json" \
  -d '{"query": "BMI-WFS", "k": 5, "threshold": 0.0}' | jq '.'

# Step 3: Test with negative threshold (to see all results)
echo ""
echo "📊 Step 3: Testing with negative threshold..."
curl -X POST "https://bmi.engage-360.net/api/search/semantic" \
  -H "Content-Type: application/json" \
  -d '{"query": "BMI-WFS", "k": 5, "threshold": -1.0}' | jq '.'

# Step 4: Test different queries with no threshold
echo ""
echo "📊 Step 4: Testing different queries..."
curl -X POST "https://bmi.engage-360.net/api/search/semantic" \
  -H "Content-Type: application/json" \
  -d '{"query": "société ivoirienne", "k": 5}' | jq '.'

curl -X POST "https://bmi.engage-360.net/api/search/semantic" \
  -H "Content-Type: application/json" \
  -d '{"query": "Business Management", "k": 5}' | jq '.'

# Step 5: Check the search service configuration
echo ""
echo "📊 Step 5: Checking search service configuration..."
docker exec bmi-chat-backend python -c "
import sys
sys.path.append('/app')

from app.services.vector_service import VectorService
from app.config import settings

try:
    vs = VectorService()
    print('✅ Vector service initialized')
    
    # Check default thresholds
    print(f'📊 Default similarity threshold: {getattr(vs, \"similarity_threshold\", \"Not set\")}')
    print(f'📊 Default reranking threshold: {getattr(vs, \"reranking_threshold\", \"Not set\")}')
    
except Exception as e:
    print(f'❌ Error: {e}')
"

# Step 6: Test direct similarity calculation
echo ""
echo "📊 Step 6: Testing direct similarity calculation..."
docker exec bmi-chat-backend python -c "
import chromadb
import numpy as np
from chromadb.config import Settings

try:
    client = chromadb.PersistentClient(
        path='/app/data/vectors',
        settings=chromadb.config.Settings(
            anonymized_telemetry=False,
            allow_reset=True
        )
    )
    
    collection = client.get_collection('bmi_documents')
    
    # Get all documents
    results = collection.get()
    
    print(f'📄 Testing similarity with {len(results[\"ids\"])} documents')
    
    # Test query
    query = 'BMI-WFS'
    print(f'🔍 Query: {query}')
    
    # Get query embedding
    query_results = collection.query(
        query_texts=[query],
        n_results=len(results['ids']),
        include=['distances', 'metadatas']
    )
    
    if query_results['distances'] and query_results['distances'][0]:
        distances = query_results['distances'][0]
        print(f'📊 Distances found: {len(distances)}')
        for i, distance in enumerate(distances):
            print(f'  {i+1}. Distance: {distance:.4f}')
            
        # Check if any distances are reasonable
        min_distance = min(distances) if distances else float('inf')
        print(f'📊 Minimum distance: {min_distance:.4f}')
        
        if min_distance < 1.0:
            print('✅ Some results should be returned')
        else:
            print('❌ All distances too high')
    else:
        print('❌ No distances found')
        
except Exception as e:
    print(f'❌ Error: {e}')
"

echo ""
echo "🎉 Search threshold testing complete!"
echo ""
echo "If results are found with no threshold, the issue is with threshold configuration." 