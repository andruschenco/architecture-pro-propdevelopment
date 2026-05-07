#!/bin/bash
# validate-security.sh – Проверка работы Gatekeeper

set -e

echo "========================================="
echo "Проверка Gatekeeper констрейнтов"
echo "========================================="

# Проверка установки Gatekeeper
echo "1. Проверка установки Gatekeeper..."
if kubectl get ns gatekeeper-system &>/dev/null; then
    echo "✅ Gatekeeper установлен"
else
    echo "❌ Gatekeeper не установлен"
    echo "   Установите: kubectl apply -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper/release-3.14/deploy/gatekeeper.yaml"
fi

echo ""
echo "2. Применение constraint templates..."
kubectl apply -f ../gatekeeper/constraint-templates/privileged.yaml
kubectl apply -f ../gatekeeper/constraint-templates/hostpath.yaml
kubectl apply -f ../gatekeeper/constraint-templates/runasnonroot.yaml

echo ""
echo "3. Применение constraints..."
kubectl apply -f ../gatekeeper/constraints/privileged.yaml
kubectl apply -f ../gatekeeper/constraints/hostpath.yaml
kubectl apply -f ../gatekeeper/constraints/runasnonroot.yaml

echo ""
echo "4. Проверка статуса constraints..."
sleep 5
kubectl get constraints

echo ""
echo "5. Очистка"
kubectl delete namespace audit-zone --ignore-not-found

echo "========================================="
echo "Проверка завершена"
echo "========================================="
