import asyncio
import sys
import os

# Add the app directory to the path
sys.path.append(os.path.join(os.path.dirname(__file__), 'app'))

from app.core.database import AsyncSessionLocal
from sqlalchemy import text

async def check_documents():
    async with AsyncSessionLocal() as session:
        # Get all documents
        result = await session.execute(
            text("SELECT id, original_filename, status, processing_error, created_at FROM documents ORDER BY created_at DESC LIMIT 10")
        )
        rows = result.fetchall()
        
        print("📋 Document Status:")
        print("=" * 80)
        
        for row in rows:
            doc_id, filename, status, error, created_at = row
            print(f"📄 {filename}")
            print(f"   ID: {doc_id}")
            print(f"   Status: {status}")
            print(f"   Error: {error or 'None'}")
            print(f"   Created: {created_at}")
            print("-" * 40)

if __name__ == "__main__":
    asyncio.run(check_documents()) 