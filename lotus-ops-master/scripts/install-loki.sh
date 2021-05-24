#!/usr/bin/env bash
sudo mkdir -p $HOME/disk_md0/loki/index
sudo mkdir -p $HOME/disk_md0/loki/chunks
sudo chmod -R 777 $HOME/disk_md0/loki

sudo tee $HOME/disk_md0/loki/loki-config.yaml <<-'EOF'
auth_enabled: false

server:
  http_listen_port: 3100

ingester:
  lifecycler:
    address: 127.0.0.1
    ring:
      kvstore:
        store: inmemory
      replication_factor: 1
    final_sleep: 0s
  chunk_idle_period: 5m
  chunk_retain_period: 30s
  max_transfer_retries: 0

schema_config:
  configs:
    - from: 2018-04-15
      store: boltdb
      object_store: filesystem
      schema: v11
      index:
        prefix: index_
        period: 168h

storage_config:
  boltdb:
    directory: /loki/index
  filesystem:
    directory: /loki/chunks

limits_config:
  enforce_metric_name: false
  reject_old_samples: true
  reject_old_samples_max_age: 168h

chunk_store_config:
  max_look_back_period: 0s

table_manager:
  retention_deletes_enabled: false
  retention_period: 0s
EOF

sudo docker pull grafana/loki:latest
sudo docker run -d \
  -p 3100:3100 \
  -v ~/disk_md0/loki:/loki \
  -v ~/disk_md0/loki/index:/loki/index \
  -v ~/disk_md0/loki/chunks:/loki/chunks \
  --name loki \
  grafana/loki:latest \
  --config.file=/loki/loki-config.yaml
