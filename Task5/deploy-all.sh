#!/bin/bash
# deploy-all.sh – Полное развертывание Task5

set -e

echo "========================================="
echo "Задание 5: Управление трафиком в Kubernetes"
echo "========================================="

# Создание namespace
kubectl create namespace network-policy-demo 2>/dev/null || true
kubectl config set-context --current --namespace=network-policy-demo

# Развертывание сервисов
echo ""
echo "1. Развертывание сервисов..."
kubectl run front-end-app --image=nginx --labels="role=front-end" --expose --port=80
kubectl run back-end-api-app --image=nginx --labels="role=back-end-api" --expose --port=80
kubectl run admin-front-end-app --image=nginx --labels="role=admin-front-end" --expose --port=80
kubectl run admin-back-end-api-app --image=nginx --labels="role=admin-back-end-api" --expose --port=80

# Ожидание готовности
echo ""
echo "2. Ожидание готовности подов..."
sleep 15
kubectl get pods

# Применение сетевых политик
echo ""
echo "3. Применение сетевых политик..."
kubectl apply -f non-admin-api-allow-g.yaml

# Проверка
echo ""
echo "4. Проверка сетевых политик..."
kubectl get networkpolicies

echo ""
echo "✅ Развертывание завершено!"
echo ""
echo "Для проверки доступа выполните:"
echo "  kubectl exec -it front-end-app -- wget -qO- http://back-end-api-app"
echo "  kubectl exec -it front-end-app -- wget -qO- --timeout=2 http://admin-back-end-api-app"