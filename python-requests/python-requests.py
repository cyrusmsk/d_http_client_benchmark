import requests

url = "http://127.0.0.1:8000/get"

result = 0
for i in range(5_000):
    response = requests.get(url, headers={"connection": "keep-alive"})
    result = result + int(response.content)
print(result)
