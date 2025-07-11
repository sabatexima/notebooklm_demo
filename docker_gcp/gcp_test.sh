docker build ../ -t notebooklm-gcp -f Dockerfile_gcp
docker run -p 8080:8080 --name gcp-test notebooklm-gcp