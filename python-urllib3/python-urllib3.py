import urllib3

url = "http://127.0.0.1:8000/get"
http = urllib3.PoolManager()

for i in range(1000):
    response = http.request("GET", url, headers={"connection": "keep-alive"})
    print(response)
