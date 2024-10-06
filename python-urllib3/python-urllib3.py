import urllib3

url = "http://127.0.0.1:8000/get"
con = urllib3.PoolManager(num_pools=2)

result = 0
for i in range(5_000):
    response = con.request("GET", url, headers={"connection": "keep-alive"})
    result = result + int(response.data)
print(result)
