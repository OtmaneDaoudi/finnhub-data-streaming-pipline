mkdir -p data/kafka data/zookeeper
sudo chmod og+w -R data
docker-compose down
docker-compose up -d