#!/usr/bin/env python3
import http.client
import json
import time

def make_request(host, port, method, path, headers=None, body=None):
    """Make HTTP request"""
    try:
        conn = http.client.HTTPConnection(host, port, timeout=3)
        conn.request(method, path, body=body, headers=headers or {})
        resp = conn.getresponse()
        data = resp.read().decode()
        conn.close()
        return resp.status, data
    except Exception as e:
        return None, str(e)

def main():
    api_key = "tm_key_9babda464b5cc9ce83c368c30a4e048eafc0c10e19f2cd240f66e3b85176a164"
    
    print("=" * 60)
    print("TESTING EVALUATION-SERVICE SETUP")
    print("=" * 60)
    
    # 1. Test flag-service
    print("\n[1] Testing flag-service /health...")
    status, data = make_request('127.0.0.1', 8002, 'GET', '/health')
    if status == 200:
        print(f"    ✓ Status {status}: {data}")
    else:
        print(f"    ✗ Error: {data}")
        return
    
    # 2. Create a flag
    print("\n[2] Creating flag 'enable-new-dashboard'...")
    headers = {
        'Authorization': f'Bearer {api_key}',
        'Content-Type': 'application/json'
    }
    body = json.dumps({
        "name": "enable-new-dashboard",
        "description": "Feature para novo dashboard",
        "is_enabled": True
    })
    status, data = make_request('127.0.0.1', 8002, 'POST', '/flags', headers=headers, body=body)
    if status == 201 or status == 200:
        print(f"    ✓ Status {status}: Flag created")
    else:
        print(f"    ✗ Status {status}: {data}")
        
    # 3. Test targeting-service
    print("\n[3] Testing targeting-service /health...")
    status, data = make_request('127.0.0.1', 8003, 'GET', '/health')
    if status == 200:
        print(f"    ✓ Status {status}: {data}")
    else:
        print(f"    ✗ Error: {data}")
        return
    
    # 4. Create a targeting rule
    print("\n[4] Creating targeting rule for 'enable-new-dashboard'...")
    headers = {
        'Authorization': f'Bearer {api_key}',
        'Content-Type': 'application/json'
    }
    body = json.dumps({
        "flag_name": "enable-new-dashboard",
        "is_enabled": True,
        "rules": {
            "type": "PERCENTAGE",
            "value": 50
        }
    })
    status, data = make_request('127.0.0.1', 8003, 'POST', '/rules', headers=headers, body=body)
    if status == 201 or status == 200:
        print(f"    ✓ Status {status}: Rule created")
    else:
        print(f"    ✗ Status {status}: {data}")
    
    # 5. Test evaluation-service health
    print("\n[5] Testing evaluation-service /health...")
    status, data = make_request('127.0.0.1', 8004, 'GET', '/health')
    if status == 200:
        print(f"    ✓ Status {status}: {data}")
    else:
        print(f"    ✗ Error: {data}")
        return
    
    # 6. Test evaluation
    print("\n[6] Testing evaluation endpoint...")
    for user_id in ['user-1', 'user-abc', 'user-xyz']:
        status, data = make_request('127.0.0.1', 8004, 'GET', f'/evaluate?user_id={user_id}&flag_name=enable-new-dashboard')
        if status == 200:
            result = json.loads(data) if data else {}
            print(f"    ✓ {user_id}: {result.get('result', '?')}")
        else:
            print(f"    ✗ {user_id}: Status {status}")
    
    print("\n" + "=" * 60)
    print("SETUP COMPLETE!")
    print("=" * 60)
    print("\nNow check the logs:")
    print("  docker compose logs -f evaluation-service")
    print("\nAnd check DynamoDB events:")
    print("  docker compose exec localstack awslocal dynamodb scan --table-name analytics")

if __name__ == '__main__':
    main()
