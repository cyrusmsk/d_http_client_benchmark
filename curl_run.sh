for i in {1..1000};
do
    curl -H 'Accept-Encoding: gzip' 'http://127.0.0.1:8000/get';
done
