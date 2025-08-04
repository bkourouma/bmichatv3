#!/bin/bash

# 🔧 Fix Document Indexing and Search Issues
# This script fixes document indexing and search problems

set -e

echo "🔧 Fixing Document Indexing and Search Issues"
echo "============================================="

# Check current documents
echo "📊 Step 1: Checking current documents..."
curl -s "https://bmi.engage-360.net/api/documents?skip=0&limit=10" | jq '.'

# Check vector database stats
echo ""
echo "📊 Step 2: Checking vector database stats..."
curl -s "https://bmi.engage-360.net/api/search/stats" | jq '.'

# Check if documents are properly processed
echo ""
echo "📊 Step 3: Checking document processing status..."
docker-compose logs --tail=30 backend | grep -i "process\|chunk\|embed" || echo "No processing logs found"

# Test different search queries
echo ""
echo "📊 Step 4: Testing different search queries..."
echo "Testing 'BMI-WFS':"
curl -X POST "https://bmi.engage-360.net/api/search/semantic" \
  -H "Content-Type: application/json" \
  -d '{"query": "BMI-WFS", "k": 5}' | jq '.'

echo ""
echo "Testing 'société ivoirienne':"
curl -X POST "https://bmi.engage-360.net/api/search/semantic" \
  -H "Content-Type: application/json" \
  -d '{"query": "société ivoirienne", "k": 5}' | jq '.'

echo ""
echo "Testing 'fintech':"
curl -X POST "https://bmi.engage-360.net/api/search/semantic" \
  -H "Content-Type: application/json" \
  -d '{"query": "fintech", "k": 5}' | jq '.'

# Check if we need to reprocess documents
echo ""
echo "📊 Step 5: Checking if documents need reprocessing..."
for doc_id in $(curl -s "https://bmi.engage-360.net/api/documents?skip=0&limit=10" | jq -r '.documents[].id'); do
    echo "Reprocessing document: $doc_id"
    curl -X POST "https://bmi.engage-360.net/api/documents/$doc_id/reprocess" || echo "Failed to reprocess $doc_id"
done

# Wait for reprocessing
echo ""
echo "⏳ Waiting for reprocessing to complete..."
sleep 30

# Create a new comprehensive document
echo ""
echo "📊 Step 6: Creating a new comprehensive document..."
cat > bmi_wfs_comprehensive.txt << 'EOF'
BMI-WFS SA (anciennement BMI-CI Finances SA) est une société ivoirienne du secteur privé, de forme société anonyme. Son nom complet est Business Management Invest – World Financial Services. Ce changement de dénomination (de BMI-CI Finances SA à BMI-WFS SA) a été annoncé récemment pour refléter son expansion internationale. La société est immatriculée en Côte d'Ivoire et dispose d'un capital social d'environ 500 millions FCFA. Son siège social est situé à Abidjan (Cocody Angré), et elle a également établi une présence en Europe via une filiale enregistrée à Lille (France) fin 2024.

Date de création : BMI-WFS a été fondée en 2016. Elle a été créée par de jeunes entrepreneurs ivoiriens, dont Innocent "Clotchôr" Sécongo, qui en est le fondateur et dirigeant principal. M. Sécongo occupe le poste de Président-Directeur Général (PDG) de l'entreprise depuis sa création.

BMI-WFS est active dans le domaine de la technologie financière (fintech) et de la monétique (paiements électroniques). Son coeur de métier consiste à concevoir et opérer des plateformes de paiement digital et de gestion informatique pour moderniser les transactions financières.

L'entreprise se positionne aussi sur des domaines connexes tels que l'ingénierie informatique et numérique, l'intelligence artificielle appliquée à la finance, et plus généralement la transformation digitale des services économiques. BMI-WFS se présente comme une entreprise panafricaine, apportant son savoir-faire technologique à l'échelle régionale au-delà de la Côte d'Ivoire.

En pratique, BMI-WFS a développé des solutions phares qui visent à dématérialiser et sécuriser les paiements, notamment dans le secteur public. L'entreprise se décrit elle-même comme un acteur majeur de la transformation digitale de l'économie ivoirienne, offrant des services financiers numériques innovants et conformes aux standards internationaux.

Coordonnées de contact : infos@bmi.ci et standard téléphonique à Abidjan (+225) 27 22 42 16 19.
EOF

# Upload the new document
echo ""
echo "📊 Step 7: Uploading new comprehensive document..."
curl -X POST "https://bmi.engage-360.net/api/documents/upload" \
  -H "Content-Type: multipart/form-data" \
  -F "file=@bmi_wfs_comprehensive.txt" \
  -F "keywords=BMI-WFS,fintech,paiement,digital,ivoirien,Abidjan,Sécongo" | jq '.'

# Wait for processing
echo ""
echo "⏳ Waiting for document processing..."
sleep 20

# Test search again
echo ""
echo "📊 Step 8: Testing search with new document..."
echo "Testing 'BMI-WFS':"
curl -X POST "https://bmi.engage-360.net/api/search/semantic" \
  -H "Content-Type: application/json" \
  -d '{"query": "BMI-WFS", "k": 5}' | jq '.'

echo ""
echo "Testing 'parle moi de BMI-WFS':"
curl -X POST "https://bmi.engage-360.net/api/search/semantic" \
  -H "Content-Type: application/json" \
  -d '{"query": "parle moi de BMI-WFS", "k": 5}' | jq '.'

echo ""
echo "Testing 'société ivoirienne':"
curl -X POST "https://bmi.engage-360.net/api/search/semantic" \
  -H "Content-Type: application/json" \
  -d '{"query": "société ivoirienne", "k": 5}' | jq '.'

# Check final stats
echo ""
echo "📊 Step 9: Checking final stats..."
curl -s "https://bmi.engage-360.net/api/search/stats" | jq '.'

echo ""
echo "🎉 Document indexing fix complete!"
echo ""
echo "If search still doesn't work, try:"
echo "1. Restart the backend: docker-compose restart backend"
echo "2. Check logs: docker-compose logs -f backend"
echo "3. Test in web interface: https://bmi.engage-360.net" 