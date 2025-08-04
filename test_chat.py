#!/usr/bin/env python3
"""
Simple test script to query the BMI Chat API
"""

import requests
import json
import time

def test_chat_api():
    """Test the chat API endpoint"""
    
    # API endpoint - updated to include /api prefix
    url = "http://localhost:3006/api/chat"
    
    # Request payload
    payload = {
        "message": "BMI-WFS",
        "session_id": "test-session-123",
        "use_history": True
    }
    
    # Headers
    headers = {
        "Content-Type": "application/json"
    }
    
    try:
        print("🔍 Testing BMI Chat API...")
        print(f"📡 URL: {url}")
        print(f"📝 Message: {payload['message']}")
        print()
        
        # Make the request
        response = requests.post(url, json=payload, headers=headers, timeout=30)
        
        print(f"📊 Status Code: {response.status_code}")
        print(f"📋 Response Headers: {dict(response.headers)}")
        print()
        
        if response.status_code == 200:
            data = response.json()
            print("✅ Success! Response:")
            print(json.dumps(data, indent=2, ensure_ascii=False))
        else:
            print(f"❌ Error: {response.status_code}")
            print(f"📄 Response: {response.text}")
            
    except requests.exceptions.ConnectionError:
        print("❌ Connection Error: Could not connect to the server")
        print("💡 Make sure the server is running on port 3006")
    except requests.exceptions.Timeout:
        print("❌ Timeout Error: Request timed out")
    except Exception as e:
        print(f"❌ Unexpected Error: {str(e)}")

if __name__ == "__main__":
    test_chat_api() 