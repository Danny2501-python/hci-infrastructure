# MetalLB Setup Guide

## 📋 Tổng quan

MetalLB cung cấp **LoadBalancer** cho Kubernetes cluster on-premise (không dùng cloud provider).

**Setup hiện tại:**
- **Namespace**: `default`
- **Mode**: L2 (Layer 2)
- **IP Range**: `192.168.1.200-192.168.1.250`
- **FRR**: Disabled (lightweight mode)

---

## � Cài đặt MetalLB

### **Option 1: Cài đặt Lightweight (Khuyến nghị)**

Dùng config tối ưu cho L2 mode (không cần BGP/FRR):

```bash
# Install với values lightweight
helm install metallb ./metallb/ \
  -n default \
  -f ./metallb/values-lightweight.yaml
```

**Lợi ích:**
- ✅ Chỉ 2 containers (thay vì 8)
- ✅ Ít tài nguyên hơn (50m CPU, 64Mi RAM)
- ✅ Đủ cho L2 mode

### **Option 2: Cài đặt Full (với BGP/FRR)**

Nếu cần BGP mode:

```bash
# Install với values mặc định
helm install metallb ./metallb/ -n default
```

**Lưu ý:** Sẽ có 7 containers trong speaker pod.

---

## ⚙️ Cấu hình IP Pool

### **Bước 1: Đợi pods ready**

```bash
# Kiểm tra pods
kubectl get pods -n default -l app.kubernetes.io/name=metallb

# Đợi ready
kubectl wait --for=condition=ready pod \
  -l app.kubernetes.io/name=metallb \
  -n default \
  --timeout=120s
```

### **Bước 2: Apply IP Pool**

```bash
kubectl apply -f ./metallb/metallb-ippool.yaml
```

### **Bước 3: Kiểm tra**

```bash
# Xem IP Pool
kubectl get ipaddresspool -n default

# Xem L2 Advertisement
kubectl get l2advertisement -n default

# Output:
# NAME           IPADDRESSPOOLS
# default-pool   ["192.168.1.200-192.168.1.250"]
# default-l2     ["default-pool"]
```

---

## 🔧 Tùy chỉnh IP Range

### **Sửa file `metallb-ippool.yaml`:**

```yaml
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: default-pool
  namespace: default  # ← Phải khớp với namespace install
spec:
  addresses:
  - 192.168.1.200-192.168.1.250  # ← Thay đổi range ở đây
```

### **Apply lại:**

```bash
kubectl apply -f ./metallb/metallb-ippool.yaml
```

---

## 🎯 Sử dụng với Services

### **Tạo Service LoadBalancer:**

```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-service
  namespace: default
spec:
  type: LoadBalancer  # ← MetalLB sẽ tự động cấp IP
  ports:
    - port: 80
      targetPort: 8080
  selector:
    app: my-app
```

### **Kiểm tra External IP:**

```bash
kubectl get svc my-service

# Output:
# NAME         TYPE           EXTERNAL-IP      PORT(S)
# my-service   LoadBalancer   192.168.1.200    80:xxxxx/TCP
```

### **Test kết nối:**

```bash
# Từ Windows hoặc máy trong LAN
curl http://192.168.1.200
```

---

## 🔄 Reinstall / Upgrade

### **Reinstall với config mới:**

```bash
# 1. Uninstall
helm uninstall metallb -n default

# 2. Xóa IP Pool
kubectl delete -f ./metallb/metallb-ippool.yaml

# 3. Install lại
helm install metallb ./metallb/ \
  -n default \
  -f ./metallb/values-lightweight.yaml

# 4. Đợi pods ready
kubectl wait --for=condition=ready pod \
  -l app.kubernetes.io/name=metallb \
  -n default \
  --timeout=120s

# 5. Apply IP Pool
kubectl apply -f ./metallb/metallb-ippool.yaml
```

### **Upgrade (giữ config):**

```bash
helm upgrade metallb ./metallb/ \
  -n default \
  -f ./metallb/values-lightweight.yaml
```

---

## 🗑️ Uninstall

```bash
# 1. Xóa IP Pool trước
kubectl delete -f ./metallb/metallb-ippool.yaml

# 2. Uninstall Helm chart
helm uninstall metallb -n default

# 3. Xóa CRDs (nếu cần)
kubectl delete crd \
  ipaddresspools.metallb.io \
  l2advertisements.metallb.io \
  bgpadvertisements.metallb.io \
  bgppeers.metallb.io \
  communities.metallb.io
```

---

## 🐛 Troubleshooting

### **Pods không ready:**

```bash
# Xem logs controller
kubectl logs -n default -l app.kubernetes.io/component=controller

# Xem logs speaker
kubectl logs -n default -l app.kubernetes.io/component=speaker
```

### **Service không được cấp IP:**

```bash
# Kiểm tra IP Pool
kubectl get ipaddresspool -n default

# Kiểm tra events
kubectl describe svc <service-name>

# Kiểm tra logs controller
kubectl logs -n default -l app.kubernetes.io/component=controller
```

### **Webhook error khi apply IP Pool:**

```bash
# Đợi pods ready trước
kubectl wait --for=condition=ready pod \
  -l app.kubernetes.io/name=metallb \
  -n default \
  --timeout=120s

# Sau đó apply lại
kubectl apply -f ./metallb/metallb-ippool.yaml
```

---

## � So sánh L2 vs BGP

| Tiêu chí | L2 Mode (hiện tại) | BGP Mode |
|----------|-------------------|----------|
| **Setup** | ✅ Đơn giản | ⚠️ Phức tạp |
| **Router config** | ✅ Không cần | ❌ Phải config BGP |
| **Subnet** | ⚠️ Cùng subnet only | ✅ Cross-subnet |
| **Failover** | ~10s | ~1s |
| **Containers** | 2 | 8 |
| **Use case** | Dev/Lab | Production |

---

## �📚 Tài liệu tham khảo

- [MetalLB Official Docs](https://metallb.universe.tf/)
- [L2 Configuration](https://metallb.universe.tf/configuration/#layer-2-configuration)
- [BGP Configuration](https://metallb.universe.tf/configuration/#bgp-configuration)
- [Helm Chart Values](./values.yaml)
- [Lightweight Values](./values-lightweight.yaml)
- [IP Pool Config](./metallb-ippool.yaml)

---

## 💡 Tips

### **Giảm resources hơn nữa:**

Sửa `values-lightweight.yaml`:

```yaml
controller:
  resources:
    requests:
      cpu: 25m
      memory: 32Mi

speaker:
  resources:
    requests:
      cpu: 25m
      memory: 32Mi
```

### **Chỉ chạy speaker trên nodes cụ thể:**

```yaml
speaker:
  nodeSelector:
    metallb: enabled
```

Sau đó label nodes:
```bash
kubectl label node <node-name> metallb=enabled
```

### **Enable BGP sau này:**

```bash
helm upgrade metallb ./metallb/ \
  -n default \
  --set speaker.frr.enabled=true
```
