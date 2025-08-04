#!/bin/bash

echo "🔧 Fix ChromaDB Embeddings Issue"
echo "================================="

# Step 1: Check if embeddings are None
echo "📊 Step 1: Checking embeddings in ChromaDB..."
docker exec bmi-chat-backend python -c "
import chromadb
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
    print(f'📊 Collection count: {collection.count()}')
    
    # Get all embeddings
    results = collection.get(include=['embeddings'])
    
    if results['embeddings']:
        print(f'📄 Checking {len(results[\"embeddings\"])} embeddings...')
        none_count = 0
        valid_count = 0
        
        for i, embedding in enumerate(results['embeddings']):
            if embedding is None:
                none_count += 1
                print(f'  ❌ Document {i+1}: None embedding')
            else:
                valid_count += 1
                print(f'  ✅ Document {i+1}: Valid embedding ({len(embedding)} dimensions)')
        
        print(f'\\n📊 Summary:')
        print(f'  ✅ Valid embeddings: {valid_count}')
        print(f'  ❌ None embeddings: {none_count}')
        
        if none_count > 0:
            print('\\n🚨 PROBLEM FOUND: Some embeddings are None!')
        else:
            print('\\n✅ All embeddings are valid')
    else:
        print('❌ No embeddings found')
        
except Exception as e:
    print(f'❌ Error: {e}')
"

# Step 2: Completely remove and recreate ChromaDB
echo ""
echo "📊 Step 2: Removing ChromaDB data..."
docker exec bmi-chat-backend rm -rf /app/data/vectors

# Step 3: Restart backend to reinitialize ChromaDB
echo ""
echo "📊 Step 3: Restarting backend..."
docker-compose restart backend

# Step 4: Wait for backend to be ready
echo ""
echo "⏳ Step 4: Waiting for backend to be ready..."
sleep 30

# Step 5: Reprocess all documents
echo ""
echo "📊 Step 5: Reprocessing all documents..."
DOCUMENTS=$(curl -s "https://bmi.engage-360.net/api/documents?skip=0&limit=10" | jq -r '.documents[].id')

for doc_id in $DOCUMENTS; do
    echo "🔄 Reprocessing document: $doc_id"
    curl -X POST "https://bmi.engage-360.net/api/documents/$doc_id/reprocess"
done

# Step 6: Wait for processing
echo ""
echo "⏳ Step 6: Waiting for document processing..."
sleep 60

# Step 7: Verify embeddings are valid
echo ""
echo "📊 Step 7: Verifying embeddings..."
docker exec bmi-chat-backend python -c "
import chromadb
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
    print(f'📊 Collection count: {collection.count()}')
    
    # Get all embeddings
    results = collection.get(include=['embeddings'])
    
    if results['embeddings']:
        print(f'📄 Checking {len(results[\"embeddings\"])} embeddings...')
        none_count = 0
        valid_count = 0
        
        for i, embedding in enumerate(results['embeddings']):
            if embedding is None:
                none_count += 1
                print(f'  ❌ Document {i+1}: None embedding')
            else:
                valid_count += 1
                print(f'  ✅ Document {i+1}: Valid embedding ({len(embedding)} dimensions)')
        
        print(f'\\n📊 Summary:')
        print(f'  ✅ Valid embeddings: {valid_count}')
        print(f'  ❌ None embeddings: {none_count}')
        
        if none_count == 0:
            print('\\n✅ All embeddings are now valid!')
        else:
            print('\\n❌ Still have None embeddings')
    else:
        print('❌ No embeddings found')
        
except Exception as e:
    print(f'❌ Error: {e}')
"

# Step 8: Test search with low threshold
echo ""
echo "📊 Step 8: Testing search with low threshold..."
curl -X POST "https://bmi.engage-360.net/api/search/semantic" \
  -H "Content-Type: application/json" \
  -d '{"query": "BMI-WFS", "k": 5, "threshold": 0.01}' | jq '.'

# Step 9: Test with other queries
echo ""
echo "📊 Step 9: Testing other queries..."
curl -X POST "https://bmi.engage-360.net/api/search/semantic" \
  -H "Content-Type: application/json" \
  -d '{"query": "société ivoirienne", "k": 5, "threshold": 0.01}' | jq '.'

echo ""
echo "🎉 ChromaDB embeddings fix complete!"
echo ""
echo "Test the web interface at: https://bmi.engage-360.net" 