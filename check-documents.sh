#!/bin/bash

# 🔧 Check Document Processing Status
# This script checks if documents are properly processed and indexed

set -e

echo "🔧 Checking Document Processing Status"
echo "===================================="

# Check if documents are in the database
echo "📊 Step 1: Checking documents in database..."
curl -s "https://bmi.engage-360.net/api/documents?skip=0&limit=10" | jq '.' || echo "Could not parse JSON response"

# Check vector database status
echo ""
echo "📊 Step 2: Checking vector database status..."
curl -s "https://bmi.engage-360.net/api/search/stats" | jq '.' || echo "Could not parse JSON response"

# Check if there are any documents in the upload directory
echo ""
echo "📊 Step 3: Checking upload directory..."
docker exec bmi-chat-backend ls -la /app/data/uploads/ 2>/dev/null || echo "Could not check upload directory"

# Check backend logs for document processing
echo ""
echo "📊 Step 4: Checking backend logs for document processing..."
docker-compose logs --tail=20 backend | grep -i "document\|upload\|process" || echo "No document processing logs found"

# Test document upload
echo ""
echo "📊 Step 5: Testing document upload..."
echo "Creating a test document..."
cat > test_bmi_document.txt << 'EOF'
BMI-WFS SA (anciennement BMI-CI Finances SA) est une société ivoirienne du secteur privé, de forme société anonyme. Son nom complet est Business Management Invest – World Financial Services. Ce changement de dénomination (de BMI-CI Finances SA à BMI-WFS SA) a été annoncé récemment pour refléter son expansion internationale. La société est immatriculée en Côte d'Ivoire et dispose d'un capital social d'environ 500 millions FCFA. Son siège social est situé à Abidjan (Cocody Angré), et elle a également établi une présence en Europe via une filiale enregistrée à Lille (France) fin 2024.

Date de création : BMI-WFS a été fondée en 2016. Elle a été créée par de jeunes entrepreneurs ivoiriens, dont Innocent "Clotchôr" Sécongo, qui en est le fondateur et dirigeant principal. M. Sécongo occupe le poste de Président-Directeur Général (PDG) de l'entreprise depuis sa création.

BMI-WFS est active dans le domaine de la technologie financière (fintech) et de la monétique (paiements électroniques). Son coeur de métier consiste à concevoir et opérer des plateformes de paiement digital et de gestion informatique pour moderniser les transactions financières.
EOF

echo "Test document created. You can upload this file through the web interface."

# Check if the document processing service is working
echo ""
echo "📊 Step 6: Testing document processing service..."
curl -X POST "https://bmi.engage-360.net/api/documents/upload" \
  -H "Content-Type: multipart/form-data" \
  -F "file=@test_bmi_document.txt" \
  -F "keywords=BMI-WFS,fintech,paiement,digital" || echo "Upload test failed"

# Check the documents again after upload
echo ""
echo "📊 Step 7: Checking documents after upload..."
sleep 5
curl -s "https://bmi.engage-360.net/api/documents?skip=0&limit=10" | jq '.' || echo "Could not parse JSON response"

# Test search functionality
echo ""
echo "📊 Step 8: Testing search functionality..."
curl -X POST "https://bmi.engage-360.net/api/search/semantic" \
  -H "Content-Type: application/json" \
  -d '{"query": "parle moi de BMI-WFS", "k": 5}' | jq '.' || echo "Search test failed"

echo ""
echo "🎉 Document processing check complete!"
echo ""
echo "If documents are not being processed, check:"
echo "1. Backend logs: docker-compose logs -f backend"
echo "2. Upload directory permissions"
echo "3. Vector database status"
echo "4. Document processing service" 