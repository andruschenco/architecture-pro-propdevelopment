#!/bin/bash
# verify-admission.sh – Проверка работы PodSecurity Admission

set -e

NAMESPACE="audit-zone"
INSECURE_DIR="../insecure-manifests"
SECURE_DIR="../secure-manifests"

echo "========================================="
echo "Проверка PodSecurity Admission"
echo "========================================="

# Создание namespace
echo "1. Создание namespace с restricted политикой..."
kubectl apply -f ../01-create-namespace.yaml

echo ""
echo "2. Проверка небезопасных подов (должны быть отклонены)"
echo "-----------------------------------------"

for pod in 01-privileged-pod 02-hostpath-pod 03-root-user-pod; do
    echo -n "  Проверка $pod: "
    if kubectl apply -f "$INSECURE_DIR/$pod.yaml" 2>&1 | grep -q "Forbidden\|denied"; then
        echo "✅ БЛОКИРОВАН"
    else
        echo "❌ ПРОПУЩЕН"
    fi
done

echo ""
echo "3. Применение безопасных подов (должны быть разрешены)"
echo "-----------------------------------------"

for pod in 01-secure 02-secure 03-secure; do
    echo -n "  Проверка $pod: "
    if kubectl apply -f "$SECURE_DIR/$pod.yaml" 2>&1 | grep -q "created"; then
        echo "✅ РАЗРЕШЁН"
    else
        echo "❌ ОТКЛОНЁН"
    fi
done

echo ""
echo "4. Очистка"
kubectl delete namespace $NAMESPACE --ignore-not-found

echo "========================================="
echo "Проверка завершена"
echo "========================================="
