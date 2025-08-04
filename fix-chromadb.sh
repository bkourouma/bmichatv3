#!/bin/bash

# 🔧 Fix ChromaDB Issues
# This script diagnoses and fixes ChromaDB problems

set -e

echo "🔧 Fixing ChromaDB Issues"
echo "========================="

# Check ChromaDB status
echo "📊 Step 1: Checking ChromaDB status..."
docker exec bmi-chat-backend python -c "
import chromadb
from chromadb.config import Settings
try:
    client = chromadb.Client(Settings(
        chroma_db_impl='duckdb+parquet',
        persist_directory='/app/data/vectors'
    ))
    collections = client.list_collections()
    print(f'✅ ChromaDB connected. Collections: {len(collections)}')
    for col in collections:
        print(f'  - {col.name}: {col.count()} documents')
except Exception as e:
    print(f'❌ ChromaDB error: {e}')
"

# Check vector database files
echo ""
echo "📊 Step 2: Checking vector database files..."
docker exec bmi-chat-backend ls -la /app/data/vectors/ 2>/dev/null || echo "No vectors directory found"

# Check if ChromaDB is properly initialized
echo ""
echo "📊 Step 3: Checking ChromaDB initialization..."
docker exec bmi-chat-backend python -c "
import os
import chromadb
from chromadb.config import Settings

# Check if vectors directory exists
vectors_dir = '/app/data/vectors'
if not os.path.exists(vectors_dir):
    print(f'❌ Vectors directory not found: {vectors_dir}')
    os.makedirs(vectors_dir, exist_ok=True)
    print(f'✅ Created vectors directory: {vectors_dir}')

# Initialize ChromaDB
try:
    client = chromadb.Client(Settings(
        chroma_db_impl='duckdb+parquet',
        persist_directory=vectors_dir
    ))
    print('✅ ChromaDB client initialized')
    
    # Get or create collection
    collection = client.get_or_create_collection('bmi_documents')
    print(f'✅ Collection ready: {collection.name}')
    print(f'📊 Collection count: {collection.count()}')
    
    # List all collections
    collections = client.list_collections()
    print(f'📊 Total collections: {len(collections)}')
    
except Exception as e:
    print(f'❌ ChromaDB initialization error: {e}')
"

# Check document processing logs
echo ""
echo "📊 Step 4: Checking document processing logs..."
docker-compose logs --tail=50 backend | grep -i "chroma\|vector\|embed\|chunk" || echo "No ChromaDB processing logs found"

# Test document reprocessing
echo ""
echo "📊 Step 5: Testing document reprocessing..."
for doc_id in $(curl -s "https://bmi.engage-360.net/api/documents?skip=0&limit=10" | jq -r '.documents[].id'); do
    echo "Reprocessing document: $doc_id"
    curl -X POST "https://bmi.engage-360.net/api/documents/$doc_id/reprocess" || echo "Failed to reprocess $doc_id"
done

# Wait for reprocessing
echo ""
echo "⏳ Waiting for reprocessing to complete..."
sleep 30

# Check ChromaDB after reprocessing
echo ""
echo "📊 Step 6: Checking ChromaDB after reprocessing..."
docker exec bmi-chat-backend python -c "
import chromadb
from chromadb.config import Settings

try:
    client = chromadb.Client(Settings(
        chroma_db_impl='duckdb+parquet',
        persist_directory='/app/data/vectors'
    ))
    
    # Get collection
    collection = client.get_collection('bmi_documents')
    print(f'✅ Collection: {collection.name}')
    print(f'📊 Document count: {collection.count()}')
    
    # Get some documents
    results = collection.get(limit=5)
    if results['ids']:
        print(f'📄 Sample documents: {len(results[\"ids\"])}')
        for i, doc_id in enumerate(results['ids']):
            print(f'  {i+1}. {doc_id}')
    else:
        print('❌ No documents in collection')
        
except Exception as e:
    print(f'❌ ChromaDB error: {e}')
"

# Test search with ChromaDB directly
echo ""
echo "📊 Step 7: Testing search with ChromaDB directly..."
docker exec bmi-chat-backend python -c "
import chromadb
from chromadb.config import Settings
import openai
import os

try:
    # Initialize ChromaDB
    client = chromadb.Client(Settings(
        chroma_db_impl='duckdb+parquet',
        persist_directory='/app/data/vectors'
    ))
    
    collection = client.get_collection('bmi_documents')
    print(f'📊 Collection count: {collection.count()}')
    
    if collection.count() > 0:
        # Test query
        query = 'BMI-WFS'
        print(f'🔍 Testing query: {query}')
        
        # Search
        results = collection.query(
            query_texts=[query],
            n_results=5
        )
        
        if results['ids'] and results['ids'][0]:
            print(f'✅ Found {len(results[\"ids\"][0])} results')
            for i, doc_id in enumerate(results['ids'][0]):
                print(f'  {i+1}. {doc_id}')
                if results['documents'] and results['documents'][0]:
                    print(f'     Content: {results[\"documents\"][0][i][:100]}...')
        else:
            print('❌ No search results found')
    else:
        print('❌ No documents in collection to search')
        
except Exception as e:
    print(f'❌ Search error: {e}')
"

# Check if we need to recreate the vector database
echo ""
echo "📊 Step 8: Checking if we need to recreate vector database..."
docker exec bmi-chat-backend python -c "
import os
import shutil

vectors_dir = '/app/data/vectors'
if os.path.exists(vectors_dir):
    print(f'📁 Vectors directory exists: {vectors_dir}')
    files = os.listdir(vectors_dir)
    print(f'📄 Files in directory: {len(files)}')
    for file in files:
        print(f'  - {file}')
else:
    print(f'❌ Vectors directory not found: {vectors_dir}')
"

# Test API search again
echo ""
echo "📊 Step 9: Testing API search again..."
curl -X POST "https://bmi.engage-360.net/api/search/semantic" \
  -H "Content-Type: application/json" \
  -d '{"query": "BMI-WFS", "k": 5}' | jq '.'

echo ""
echo "🎉 ChromaDB diagnosis complete!"
echo ""
echo "If ChromaDB is empty or corrupted, try:"
echo "1. Recreate vector database: rm -rf /app/data/vectors && restart backend"
echo "2. Check document processing: docker-compose logs -f backend"
echo "3. Test with new documents" 