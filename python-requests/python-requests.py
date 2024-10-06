import requests

url = "http://127.0.0.1:8000/get"

result = 0
with requests.Session() as s:
    for i in range(5_000):
        response = s.get(url, headers={"connection": "keep-alive"})
        result = result + int(response.content)
print(result)
