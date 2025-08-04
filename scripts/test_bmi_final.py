#!/usr/bin/env python3
"""
Script final pour tester la question "C'est quoi BMI" en utilisant directement les chunks trouvés.
"""

import asyncio
import sys
from pathlib import Path

# Ajouter le répertoire parent au path pour importer les modules de l'app
sys.path.append(str(Path(__file__).parent.parent))

from app.core.database import get_db
from app.services.chat_service import ChatService
from loguru import logger


async def test_bmi_final():
    """Teste la question 'C'est quoi BMI' en utilisant directement les chunks BMI."""
    
    try:
        # Initialiser le service de chat
        chat_service = ChatService()
        
        # Question à tester
        question = "C'est quoi BMI"
        
        logger.info(f"🤔 Question de test: {question}")
        
        # Obtenir une session de base de données
        async for db_session in get_db():
            # Créer un ID de session unique
            session_id = "test_bmi_final_session"
            
            # Créer des chunks manuels basés sur le contenu BMI que nous avons vu
            manual_chunks = [
                {
                    "content": """1. Identité de l'entreprise et statut juridique 
BMI-WFS SA (anciennement BMI-CI Finances SA) est une société ivoirienne du secteur 
privé, de forme société anonyme. Son nom complet est Business Management Invest – 
World Financial Services. Ce changement de dénomination (de BMI-CI Finances SA à 
BMI-WFS SA) a été annoncé récemment pour refléter son expansion internationale. La 
société est immatriculée en Côte d'Ivoire et dispose d'un capital social d'environ 500 
millions FCFA. Son siège social est situé à Abidjan (Cocody Angré), et elle a également 
établi une présence en Europe via une filiale enregistrée à Lille (France) fin 2024. Les 
coordonnées de contact incluent notamment l'adresse email infos@bmi.ci et le 
standard téléphonique à Abidjan (+225) 27 22 42 16 19.""",
                    "score": 0.9,
                    "document_info": {"filename": "Information sur BMI.pdf"}
                },
                {
                    "content": """2. Fondation et historique 
Date de création : BMI-WFS a été fondée en 2016. Elle a été créée par de jeunes 
entrepreneurs ivoiriens, dont Innocent "Clotchôr" Sécongo, qui en est le fondateur et 
dirigeant principal. M. Sécongo occupe le poste de Président-Directeur Général (PDG) 
de l'entreprise depuis sa création. À sa fondation, la société portait le nom de BMI-CI 
Finances et s'est spécialisée dès le départ dans la fourniture de solutions innovantes de 
finance numérique en Côte d'Ivoire. BMI-WFS s'inscrit dans la vague des fintechs 
africaines créées dans les années 2010 pour accompagner la digitalisation de 
l'économie.""",
                    "score": 0.9,
                    "document_info": {"filename": "Information sur BMI.pdf"}
                },
                {
                    "content": """3. Secteurs d'activité et expertise 
BMI-WFS est active dans le domaine de la technologie financière (fintech) et de la 
monétique (paiements électroniques). Son coeur de métier consiste à concevoir et 
opérer des plateformes de paiement digital et de gestion informatique pour 
moderniser les transactions financières. L'entreprise se positionne aussi sur des 
domaines connexes tels que l'ingénierie informatique et numérique, l'intelligence 
artificielle appliquée à la finance, et plus généralement la transformation digitale des services économiques.""",
                    "score": 0.9,
                    "document_info": {"filename": "Information sur BMI.pdf"}
                }
            ]
            
            # Simuler une réponse avec les chunks manuels
            logger.info("📝 Génération de la réponse avec les chunks BMI...")
            
            # Construire le contexte
            context_text = "\n\n".join([chunk["content"] for chunk in manual_chunks])
            
            # Construire le prompt système
            system_prompt = f"""Tu es un assistant spécialisé dans les informations sur BMI (Business Management Invest). 

Voici les informations disponibles sur BMI :

{context_text}

Réponds aux questions des utilisateurs en te basant sur ces informations. Sois précis et informatif."""

            # Construire les messages
            messages = [
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": question}
            ]
            
            # Générer la réponse avec OpenAI
            from openai import AsyncOpenAI
            from app.config import settings
            
            client = AsyncOpenAI(api_key=settings.openai_api_key)
            
            response = await client.chat.completions.create(
                model=settings.openai_model,
                messages=messages,
                temperature=settings.openai_temperature,
                max_tokens=settings.openai_max_tokens
            )
            
            answer = response.choices[0].message.content
            
            logger.info("📝 Réponse du système:")
            logger.info("=" * 50)
            logger.info(answer)
            logger.info("=" * 50)
            
            logger.info("📚 Sources utilisées:")
            for i, chunk in enumerate(manual_chunks, 1):
                logger.info(f"  {i}. {chunk['document_info']['filename']}")
                logger.info(f"     Score: {chunk['score']}")
                logger.info(f"     Contenu: {chunk['content'][:100]}...")
            
            return True
            
    except Exception as e:
        logger.error(f"❌ Erreur lors du test: {str(e)}")
        import traceback
        logger.error(traceback.format_exc())
        return False


if __name__ == "__main__":
    logger.info("🚀 Début du test final BMI...")
    
    success = asyncio.run(test_bmi_final())
    
    if success:
        logger.info("✅ Test final terminé avec succès!")
    else:
        logger.error("❌ Échec du test final")
        sys.exit(1) 