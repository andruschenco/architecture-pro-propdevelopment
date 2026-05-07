#!/bin/bash
# create-users.sh – Создание пользователей Kubernetes

set -e

CERTS_DIR="./certs"
CONFIG_DIR="./kubeconfigs"

# Создание директорий
mkdir -p ${CERTS_DIR} ${CONFIG_DIR}

# Получение IP Minikube
MINIKUBE_IP=$(minikube ip)
KUBE_API_SERVER="https://${MINIKUBE_IP}:8443"

# Пути к CA сертификату Minikube
MINIKUBE_PATH="$HOME/.minikube"
CA_CRT="${MINIKUBE_PATH}/ca.crt"
CA_KEY="${MINIKUBE_PATH}/ca.key"

# Проверка существования файлов CA
if [ ! -f "$CA_CRT" ] || [ ! -f "$CA_KEY" ]; then
    echo "Ошибка: CA файлы не найдены в $MINIKUBE_PATH"
    echo "Убедитесь, что Minikube запущен: minikube status"
    exit 1
fi

# Функция создания пользователя
create_user() {
    local USERNAME=$1
    local USER_GROUPS=$2
    local KEY_FILE="${CERTS_DIR}/${USERNAME}.key"
    local CSR_FILE="${CERTS_DIR}/${USERNAME}.csr"
    local CRT_FILE="${CERTS_DIR}/${USERNAME}.crt"
    local KUBECONFIG_FILE="${CONFIG_DIR}/${USERNAME}.kubeconfig"

    echo "Создание пользователя: ${USERNAME} (группы: ${USER_GROUPS})"

    # Генерация приватного ключа
    openssl genrsa -out "${KEY_FILE}" 2048

    # Создание CSR
    openssl req -new -key "${KEY_FILE}" -out "${CSR_FILE}" -subj "/CN=${USERNAME}/O=${USER_GROUPS}"

    # Подписание сертификата
    openssl x509 -req -in "${CSR_FILE}" -CA "${CA_CRT}" -CAkey "${CA_KEY}" -CAcreateserial \
        -out "${CRT_FILE}" -days 365 -sha256

    # Создание kubeconfig
    kubectl config set-cluster propdevelopment \
        --certificate-authority="${CA_CRT}" \
        --embed-certs=true \
        --server="${KUBE_API_SERVER}" \
        --kubeconfig="${KUBECONFIG_FILE}"

    kubectl config set-credentials "${USERNAME}" \
        --client-certificate="${CRT_FILE}" \
        --client-key="${KEY_FILE}" \
        --embed-certs=true \
        --kubeconfig="${KUBECONFIG_FILE}"

    kubectl config set-context "${USERNAME}-context" \
        --cluster=propdevelopment \
        --user="${USERNAME}" \
        --kubeconfig="${KUBECONFIG_FILE}"

    kubectl config use-context "${USERNAME}-context" \
        --kubeconfig="${KUBECONFIG_FILE}"

    echo "✅ Пользователь ${USERNAME} создан"
}

# Создание пользователей
create_user "auditor-ivanov" "auditors"
create_user "auditor-petrov" "auditors"
create_user "developer-smirnov" "developers"
create_user "developer-kuznetsov" "developers"
create_user "devops-volkov" "devops"
create_user "admin-sokolov" "admins"

echo ""
echo "✅ Все пользователи созданы!"
echo "Kubeconfig файлы: ${CONFIG_DIR}"
echo ""
echo "Содержимое директории ${CONFIG_DIR}:"
ls -la ${CONFIG_DIR}