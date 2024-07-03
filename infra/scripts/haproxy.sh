#!/bin/bash

# Parse output.json
output=$(cat output.json)

# Fetch worker instances
workers=$(echo "$output" | jq -r '.worker_ips' | tr ',' '\n')

# Fetch master instances
masters=$(echo "$output" | jq -r '.master_ips' | tr ',' '\n')

# Start writing the HAProxy configuration
cat <<EOF > ../configuration/haproxy.cfg
global
        log /dev/log    local0
        log /dev/log    local1 notice
        chroot /var/lib/haproxy
        stats socket /run/haproxy/admin.sock mode 660 level admin expose-fd listeners
        stats timeout 30s
        user haproxy
        group haproxy
        daemon

        # Default SSL material locations
        ca-base /etc/ssl/certs
        crt-base /etc/ssl/private

        # See: https://ssl-config.mozilla.org/#server=haproxy&server-version=2.0.3&config=intermediate
        ssl-default-bind-ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384
        ssl-default-bind-ciphersuites TLS_AES_128_GCM_SHA256:TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256
        ssl-default-bind-options ssl-min-ver TLSv1.2 no-tls-tickets

defaults
        log     global
        mode    http
        option  httplog
        option  dontlognull
        timeout connect 5000
        timeout client  50000
        timeout server  50000
        errorfile 400 /etc/haproxy/errors/400.http
        errorfile 403 /etc/haproxy/errors/403.http
        errorfile 408 /etc/haproxy/errors/408.http
        errorfile 500 /etc/haproxy/errors/500.http
        errorfile 502 /etc/haproxy/errors/502.http
        errorfile 503 /etc/haproxy/errors/503.http
        errorfile 504 /etc/haproxy/errors/504.http

frontend kubernetes
        bind 0.0.0.0:6443
        mode tcp
        option tcplog
        default_backend master-nodes

frontend Grafana_front
        bind 0.0.0.0:8080
        mode http
        default_backend grafana_back

frontend Kafdrop_front
        bind 0.0.0.0:8082
        mode http
        default_backend kaf_back

frontend Spark
        bind 0.0.0.0:8081
        mode http
        default_backend spark_back

backend master-nodes
        mode tcp
        balance roundrobin
        option tcp-check
EOF

# Loop to fill master nodes
for master in $masters; do
    echo "        server $master $master:6443 check fall 3 rise 2" >> ../configuration/haproxy.cfg
done

# Backend configurations for workers
cat <<EOF >> ../configuration/haproxy.cfg

backend grafana_back
        mode http
EOF

for worker in $workers; do
    echo "        server $worker $worker:32000 check fall 3 rise 2" >> ../configuration/haproxy.cfg
done

cat <<EOF >> ../configuration/haproxy.cfg

backend kaf_back
        mode http
EOF

for worker in $workers; do
    echo "        server $worker $worker:33000 check fall 3 rise 2" >> ../configuration/haproxy.cfg
done

cat <<EOF >> ../configuration/haproxy.cfg

backend spark_back
        mode http
EOF

for worker in $workers; do
    echo "        server $worker $worker:34000 check fall 3 rise 2" >> ../configuration/haproxy.cfg
done

echo "HAProxy configuration generated in haproxy.cfg"