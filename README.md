
```
docker build -t morph:early_release .

docker run -v .:/app morph:early_release python3 /app/scraper.py
```