#!/bin/bash
# deploy-services.sh – Развертывание четырех сервисов Nginx с метками

echo "========================================="
echo "Развертывание сервисов в Kubernetes"
echo "========================================="

# Создание namespace для задания (опционально, можно использовать default)
kubectl create namespace network-policy-demo 2>/dev/null || echo "Namespace уже существует"
kubectl config set-context --current --namespace=network-policy-demo

# 1. Front-end сервис
echo "Создание front-end-app..."
kubectl run front-end-app --image=nginx --labels="role=front-end" --expose --port=80

# 2. Back-end API сервис
echo "Создание back-end-api-app..."
kubectl run back-end-api-app --image=nginx --labels="role=back-end-api" --expose --port=80

# 3. Admin Front-end сервис
echo "Создание admin-front-end-app..."
kubectl run admin-front-end-app --image=nginx --labels="role=admin-front-end" --expose --port=80

# 4. Admin Back-end API сервис
echo "Создание admin-back-end-api-app..."
kubectl run admin-back-end-api-app --image=nginx --labels="role=admin-back-end-api" --expose --port=80

echo ""
echo "✅ Все сервисы развернуты!"
echo ""

# Проверка статуса подов
kubectl get pods -o wide

# Проверка сервисов
kubectl get svc