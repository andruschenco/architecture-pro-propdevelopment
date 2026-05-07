
Задание 6. Аудит активности пользователей и обнаружение инцидентов

---

### 1. Краткий отчёт по выявленным событиям (`analysis.md`)
[analysis.md](analysis.md)

**примечание:** Предоставленный лог аудита не содержит явно вредоносных событий, описанных в задании. Он отражает нормальную, стабильную работу кластера. Поэтому отчет построен на основе анализа, демонстрирующего выявление *потенциально* опасных действий, и включает как реальные события из лога, так и раздел о том, какие данные нужны для полноценного расследования.

---

### 2. Выжимка из audit.log с подозрительными событиями (`audit-extract.json`)
[audit-extract.json](audit-extract.json)

Этот файл содержит реальные события из лога, которые соответствуют критериям поиска и могут быть интересны с точки зрения безопасности. 


---

### 3. Скрипт фильтрации audit.log (`audit-filter.py`)
[audit-filter.py](audit-filter.py)
Этот скрипт на Python воспроизводит логику фильтрации.
Он анализирует лог и создаст файл `audit-extract.json` с отфильтрованными событиями.
Для запуска можно воспользоваться cmd.

```cmd
run_filter.cmd
```

---

Как удалось настроить аудит, единственный из 55 вариантов это вариант предложенный Денисом Чекушиным. 

### в minikube в Linux добавить audit-policy

```bash
mkdir -p ~/.minikube/files/etc/ssl/certs

cat <<EOF > ~/.minikube/files/etc/ssl/certs/audit-policy.yaml
apiVersion: audit.k8s.io/v1
kind: Policy
rules:
- level: RequestResponse
  verbs: ["create", "delete", "update", "patch", "get", "list"]
  resources:
    - group: ""
      resources: ["pods", "secrets", "configmaps", "serviceaccounts", "roles", "rolebindings"]
- level: Metadata
  resources:
    - group: ""
      resources: ["*"]
      EOF
```

### Запустить
```bash
minikube start \
--driver=docker \
--extra-config=apiserver.audit-policy-file=/etc/ssl/certs/audit-policy.yaml \
#--extra-config=apiserver.audit-log-path=-
--extra-config=apiserver.audit-log-path=/etc/ssl/certs/audit.log
```

