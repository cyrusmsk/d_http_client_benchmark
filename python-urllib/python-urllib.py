import urllib3

url = "http://127.0.0.1:8000"
conn = urllib3.connection_from_url(url)

result = 0
for i in range(5_000):
    response = conn.request("GET", "/get", headers={"connection": "keep-alive"})
    result = result + int(response.data)
print(result)
