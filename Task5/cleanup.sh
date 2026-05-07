#!/bin/bash
# cleanup.sh – Удаление всех ресурсов

echo "Удаление сервисов и подов..."
kubectl delete pod front-end-app back-end-api-app admin-front-end-app admin-back-end-api-app 2>/dev/null || true
kubectl delete svc front-end-app back-end-api-app admin-front-end-app admin-back-end-api-app 2>/dev/null || true

echo "Удаление сетевых политик..."
kubectl delete networkpolicy --all 2>/dev/null || true

echo "Удаление namespace..."
kubectl delete namespace network-policy-demo 2>/dev/null || true

echo "✅ Очистка завершена"