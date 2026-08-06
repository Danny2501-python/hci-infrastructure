# Kafka KRaft (Isolated Mode) & Schema Registry cho sci-lakehouse

Thư mục này chứa cấu hình triển khai **Apache Kafka** chạy trên chế độ **KRaft Tách Biệt (Isolated Mode - 1 Controller Pod + 1 Broker Pod riêng)** tích hợp **Confluent Schema Registry** và **Kafka UI** cho dự án `sci-lakehouse`.

---

## 🚀 Các thành phần được triển khai

1. **Kafka Controller Pod** (`kafka-dev-controller`):
   - Role: `controller` (Node ID = 1)
   - Port: `9093`
   - Path lưu trữ: `/mnt/data/kafka-controller`
2. **Kafka Broker Pod** (`kafka-dev-broker`):
   - Role: `broker` (Node ID = 2)
   - Port: `9092`
   - Path lưu trữ: `/mnt/data/kafka-broker`
3. **Confluent Schema Registry** (`kafka-dev-schema-registry`):
   - Port: `8081`
4. **Kafka UI** (`kafka-dev-kafka-ui`):
   - Port: `8080`

---

## 🛠️ 1. Triển khai bằng Helm (Kubernetes / Minikube)

### Cài đặt Release:
```bash
# Triển khai Helm Chart vào namespace default
helm install kafka-dev ./kafka-dev -n default
```

### Kiểm tra trạng thái:
```bash
kubectl get pods -n default -l app.kubernetes.io/instance=kafka-dev
```

### Port-forward để truy cập từ máy host:
```bash
# Port-forward Kafka UI
kubectl port-forward svc/kafka-dev-kafka-ui 8080:8080 -n default

# Port-forward Schema Registry
kubectl port-forward svc/kafka-dev-schema-registry 8081:8081 -n default

# Port-forward Kafka Broker
kubectl port-forward svc/kafka-dev-broker 9092:9092 -n default
```

---

## 🐳 2. Triển khai nhanh bằng Docker Compose (Standalone)

```bash
cd kafka-dev
docker-compose up -d
```

---

## 🌐 Địa chỉ truy cập dịch vụ

- **Kafka Broker Service**: `kafka-dev-broker:9092`
- **Kafka Controller Service**: `kafka-dev-controller:9093`
- **Schema Registry REST API**: `http://localhost:8081`
- **Kafka Web UI**: `http://localhost:8080`
