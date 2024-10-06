import httpx

result = 0
headers = {"connection": "keep-alive"}
with httpx.Client(headers = headers) as client:
    for i in range(5000):
        r = client.get('http://127.0.0.1:8000/get')
        result = result + int(r.content)
print(result)
