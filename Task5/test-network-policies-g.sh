#!/bin/bash
# test-network-policies.sh – Проверка доступности сервисов

echo "========================================="
echo "Проверка сетевых политик"
echo "========================================="

# Функция проверки доступа
test_access() {
    local FROM_POD=$1
    local TO_SERVICE=$2
    local EXPECTED=$3

    echo -n "Проверка: $FROM_POD -> $TO_SERVICE ... "

    RESULT=$(kubectl exec -i $FROM_POD -- curl -s --connect-timeout 2 http://$TO_SERVICE 2>&1)

    if [ $? -eq 0 ] && [ "$EXPECTED" == "SUCCESS" ]; then
        echo "✅ ДОСТУП РАЗРЕШЁН (OK)"
    elif [ $? -ne 0 ] && [ "$EXPECTED" == "FAIL" ]; then
        echo "❌ ДОСТУП ЗАПРЕЩЁН (OK)"
    else
        echo "⚠️  НЕСООТВЕТСТВИЕ"
    fi
}

# Ожидание готовности всех подов
echo "Ожидание готовности подов..."
sleep 10

# Получение имен подов
FRONT_END=$(kubectl get pods -l role=front-end -o jsonpath='{.items[0].metadata.name}')
BACK_END_API=$(kubectl get pods -l role=back-end-api -o jsonpath='{.items[0].metadata.name}')
ADMIN_FRONT=$(kubectl get pods -l role=admin-front-end -o jsonpath='{.items[0].metadata.name}')
ADMIN_BACK=$(kubectl get pods -l role=admin-back-end-api -o jsonpath='{.items[0].metadata.name}')

echo ""
echo "=== ПОЗИТИВНЫЕ ТЕСТЫ (должны работать) ==="
echo ""

# Разрешенные соединения
test_access $FRONT_END "back-end-api-app" "SUCCESS"
test_access $BACK_END_API "front-end-app" "SUCCESS"
test_access $ADMIN_FRONT "admin-back-end-api-app" "SUCCESS"
test_access $ADMIN_BACK "admin-front-end-app" "SUCCESS"

echo ""
echo "=== НЕГАТИВНЫЕ ТЕСТЫ (должны быть запрещены) ==="
echo ""

# Запрещенные соединения (cross-pair)
test_access $FRONT_END "admin-back-end-api-app" "FAIL"
test_access $BACK_END_API "admin-front-end-app" "FAIL"
test_access $ADMIN_FRONT "back-end-api-app" "FAIL"
test_access $ADMIN_BACK "front-end-app" "FAIL"

echo ""
echo "=== ДОПОЛНИТЕЛЬНЫЕ ПРОВЕРКИ ==="
echo ""

# Проверка через временный тестовый под (alpine)
echo "Проверка из временного пода:"
kubectl run test-$RANDOM --rm -i -t --image=alpine --restart=Never -- sh -c "
    echo -n 'front-end -> back-end-api: '
    wget -qO- --timeout=2 http://front-end-app 2>/dev/null && echo 'OK' || echo 'FAIL'
    echo -n 'front-end -> admin-back-end-api: '
    wget -qO- --timeout=2 http://admin-back-end-api-app 2>/dev/null && echo 'OK' || echo 'FAIL'
"

echo ""
echo "✅ Проверка завершена"