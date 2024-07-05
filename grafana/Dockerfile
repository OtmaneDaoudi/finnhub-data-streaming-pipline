FROM grafana/grafana:9.5.20

# Adds 1s refresh time
COPY ./grafana.ini /etc/grafana/grafana.ini

# Install cassandra data source
RUN grafana cli plugins install hadesarchitect-cassandra-datasource

COPY ./dashboard.json /var/lib/grafana/dashboards/