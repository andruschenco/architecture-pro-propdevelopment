# Задание 7. Аудит и обеспечение соответствия политике безопасности контейнеров (PSP / PodSecurity / OPA Gatekee


###### Для Windows процесс отличается, так как Docker работает через WSL 2 (Windows Subsystem for Linux) или Hyper-V. Самый эффективный способ автоматизировать настройку — использовать PowerShell.

#### Ниже представлен скрипт, который включает необходимые компоненты Windows и устанавливает Docker Desktop через менеджер пакетов winget.

```powershell
## PowerShell-скрипт для настройки Docker Compose
Запустите PowerShell от имени администратора и выполните:

# 1. Включение компонентов Windows для WSL 2
Write-Host "--- Включение WSL и Виртуальной машины ---" -ForegroundColor Cyan
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
# 2. Установка Docker Desktop (включает Docker Engine и Compose)
Write-Host "--- Установка Docker Desktop через winget ---" -ForegroundColor Cyan
winget install -e --id Docker.DockerDesktop
# 3. Установка WSL ядра (если еще не установлено)
Write-Host "--- Обновление WSL ядра ---" -ForegroundColor Cyan
wsl --update

Write-Host "✅ Настройка завершена! ПЕРЕЗАГРУЗИТЕ компьютер для применения изменений." -ForegroundColor Green
Write-Host "После перезагрузки запустите Docker Desktop и примите соглашение."
```


---
## Структура файлов

| Путь                               | Описание                             |
|------------------------------------|--------------------------------------|
| `01-create-namespace.yaml`         | Namespace с PodSecurity restricted   |
| `insecure-manifests/`              | Небезопасные поды (3 шт.)            |
| `secure-manifests/`                | Исправленные безопасные поды (3 шт.) |
| `gatekeeper/constraint-templates/` | Шаблоны ограничений (3 шт.)          |
| `gatekeeper/constraints/`          | Ограничения для audit-zone (3 шт.)   |
| `verify/`                          | Скрипты верификации (2 шт.)          |
| `audit-policy.yaml`                | Политика аудита Kubernetes           |

## Проверка работы

# Пошаговая инструкция проверки Задания 7

## Подготовка: Проверка окружения

```bash
# Проверить, что кластер работает
kubectl cluster-info
kubectl get nodes
```

```
professional@User-PC:/mnt/c/Windows/system32$ kubectl cluster-info
nodesKubernetes control plane is running at https://kubernetes.docker.internal:6443
CoreDNS is running at https://kubernetes.docker.internal:6443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy

To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.
professional@User-PC:/mnt/c/Windows/system32$ kubectl get nodes
NAME             STATUS   ROLES           AGE    VERSION
docker-desktop   Ready    control-plane   3d2h   v1.34.1
professional@User-PC:/mnt/c/Windows/system32$
```


---

## Шаг 1: Создание namespace audit-zone с PodSecurity restricted

```bash
cd /mnt/p/YaPracticumArc/architecture-pro-propdevelopment/Task7$

# Применить namespace
kubectl apply -f Task7/01-create-namespace.yaml

# Проверить, что namespace создан
kubectl get namespace audit-zone

# Проверить наличие лейблов PodSecurity
kubectl get namespace audit-zone -o yaml | grep -A5 "labels:"
```

**Ожидаемый результат:** namespace `audit-zone` создан с лейблами `pod-security.kubernetes.io/enforce=restricted`

---

## Шаг 2: Проверка небезопасных подов (должны быть отклонены)

```bash
# Переключаем контекст на namespace audit-zone
kubectl config set-context --current --namespace=audit-zone

# 2.1. Проверка привилегированного пода
echo "=== Проверка privileged-pod ==="
kubectl apply -f insecure-manifests/01-privileged-pod.yaml

# 2.2. Проверка пода с hostPath
echo "=== Проверка hostpath-pod ==="
kubectl apply -f insecure-manifests/02-hostpath-pod.yaml

# 2.3. Проверка пода от root
echo "=== Проверка root-user-pod ==="
kubectl apply -f insecure-manifests/03-root-user-pod.yaml
```

**Ожидаемый результат:** все три команды должны вернуть ошибку вида:
```
Error from server (Forbidden): ... violates PodSecurity "restricted:latest"
```

---

## Шаг 3: Проверка безопасных подов (должны быть разрешены)

```bash
# 3.1. Безопасный под (исправленный привилегированный)
kubectl apply -f secure-manifests/01-secure.yaml

# 3.2. Безопасный под без hostPath
kubectl apply -f secure-manifests/02-secure.yaml

# 3.3. Безопасный под с non-root пользователем
kubectl apply -f secure-manifests/03-secure.yaml

# Проверить, что поды создались
kubectl get pods -n audit-zone
```

**Ожидаемый результат:** все три пода должны быть в статусе `Running` или `ContainerCreating`

---

## Шаг 4: Установка Gatekeeper (если не установлен)

```bash
# Проверить, установлен ли Gatekeeper
kubectl get ns gatekeeper-system

# Если не установлен, установить
kubectl apply -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper/release-3.14/deploy/gatekeeper.yaml

# Дождаться готовности
kubectl wait --for=condition=ready pod -l gatekeeper.sh/system=yes -n gatekeeper-system --timeout=120s

# Проверить, что поды Gatekeeper работают
kubectl get pods -n gatekeeper-system
```

**Ожидаемый результат:** все поды в `gatekeeper-system` в статусе `Running`

---

## Шаг 5: Применение constraint templates Gatekeeper

```bash
# Применить шаблоны ограничений
kubectl apply -f gatekeeper/constraint-templates/privileged.yaml
kubectl apply -f gatekeeper/constraint-templates/hostpath.yaml
kubectl apply -f gatekeeper/constraint-templates/runasnonroot.yaml

# Проверить, что шаблоны созданы
kubectl get constrainttemplates
```

**Ожидаемый результат:** три constrainttemplates: `disallowprivileged`, `disallowhostpath`, `disallowroot`

---

## Шаг 6: Применение constraints Gatekeeper

```bash
# Применить ограничения для audit-zone
kubectl apply -f gatekeeper/constraints/privileged.yaml
kubectl apply -f gatekeeper/constraints/hostpath.yaml
kubectl apply -f gatekeeper/constraints/runasnonroot.yaml

# Проверить статус constraints
kubectl get constraints

# Посмотреть детали
kubectl describe constraint disallow-privileged
kubectl describe constraint disallow-hostpath
kubectl describe constraint disallow-root
```

**Ожидаемый результат:** все constraints в статусе `Created` или `Enforced`

---

## Шаг 7: Проверка Gatekeeper в действии

```bash
# 7.1. Попытка создания привилегированного пода (должен быть заблокирован Gatekeeper)
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: test-gatekeeper-privileged
  namespace: audit-zone
spec:
  containers:
  - name: nginx
    image: nginx
    securityContext:
      privileged: true
EOF

# 7.2. Попытка создания пода с hostPath (должен быть заблокирован)
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: test-gatekeeper-hostpath
  namespace: audit-zone
spec:
  containers:
  - name: nginx
    image: nginx
  volumes:
  - name: host
    hostPath:
      path: /
EOF

# 7.3. Попытка создания пода без runAsNonRoot (должен быть заблокирован)
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: test-gatekeeper-nonroot
  namespace: audit-zone
spec:
  containers:
  - name: nginx
    image: nginx
    securityContext:
      runAsNonRoot: false
EOF
```

**Ожидаемый результат:** все три пода должны быть отклонены с ошибкой от Gatekeeper:
```
Error from server (Forbidden): admission webhook "validation.gatekeeper.sh" denied the request
```

---

## Шаг 8: Очистка

```bash
# Удалить тестовые поды
kubectl delete pod test-gatekeeper-privileged --ignore-not-found 2>/dev/null
kubectl delete pod test-gatekeeper-hostpath --ignore-not-found 2>/dev/null
kubectl delete pod test-gatekeeper-nonroot --ignore-not-found 2>/dev/null

# Удалить безопасные поды
kubectl delete -f secure-manifests/01-secure.yaml --ignore-not-found 2>/dev/null
kubectl delete -f secure-manifests/02-secure.yaml --ignore-not-found 2>/dev/null
kubectl delete -f secure-manifests/03-secure.yaml --ignore-not-found 2>/dev/null

# Удалить namespace (опционально)
kubectl delete namespace audit-zone --ignore-not-found

# Вернуть контекст в default
kubectl config set-context --current --namespace=default
```

---

## Сводная таблица ожидаемых результатов

| Проверка | Что проверяем          | Ожидаемый результат          |
|----------|------------------------|------------------------------|
| Шаг 1    | PodSecurity restricted | Namespace с лейблами created |
| Шаг 2    | Небезопасные поды      | ❌ Forbidden (PodSecurity)    |
| Шаг 3    | Безопасные поды        | ✅ Created/Running            |
| Шаг 5    | Constraint templates   | ✅ Created                    |
| Шаг 6    | Constraints            | ✅ Created/Enforced           |
| Шаг 7    | Gatekeeper блокировка  | ❌ Denied by Gatekeeper       |

