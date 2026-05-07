# Задание 5. Управление трафиком внутри кластера Kubernetes


## Часть 0. Проверка программной инфраструктуры
### Шаг 0.0 Убедиться что запущен Docker Desktop

### Шаг 0.1 Проверка установленного дистрибутива

```powershell
wsl --list --verbose
```
Должен быть дистрибутив со статусом `Running`. <br> Если нет, запустить:
```powershell
# Возникает ошибка при запуске minikube -> Exiting due to DRV_AS_ROOT: The "docker" driver should not be used with root privileges.
# место wsl --distribution Ubuntu --user root
# используем -> wsl -d Ubuntu
```
---
### Шаг 0.2. Вход в WSL
```powershell
# Просто введите
wsl -d Ubuntu
```
---
### Шаг 0.3: Проверить статус Minikube
```bash
# Проверка статуса
minikube status

# Если Minikube не запущен, запустите его
# (вариант CNI ниже) minikube start --driver=docker
```
### Шаг 0.3: Запустить Minikube с CNI плагином (не работают сетевые политики)

```bash
# Вариант A: С Calico (рекомендуется)
minikube start --driver=docker --cni=calico --cpus=2 --memory=4096
```
### Шаг 0.4: Перейти в директорию проекта 

```bash
# Нужно использовать Ваш путь, он будет отличаться от моего
cd /mnt/e/YaPracticumArc/architecture-pro-propdevelopment/Task5
```

______________________________________________
___
# Быстрый вариант для запуска и проверки

## Полный скрипт развертывания и настройки (`deploy-all.sh`)
```bash
./deploy-all.sh
````

______________________________________________
# Если хочется пройти по шагам

---
## Часть 1. Развертывание сервисов
```bash
./deploy-services.sh
```

#### Успешный результат выглядит так  
```
=========================================
Развертывание сервисов в Kubernetes
=========================================
namespace/network-policy-demo created
Context "minikube" modified.
Создание front-end-app...
service/front-end-app created
pod/front-end-app created
Создание back-end-api-app...
service/back-end-api-app created
pod/back-end-api-app created
Создание admin-front-end-app...
service/admin-front-end-app created
pod/admin-front-end-app created
Создание admin-back-end-api-app...
service/admin-back-end-api-app created
pod/admin-back-end-api-app created

✅ Все сервисы развернуты!

NAME                     READY   STATUS              RESTARTS   AGE   IP       NODE       NOMINATED NODE   READINESS GATES
admin-back-end-api-app   0/1     ContainerCreating   0          1s    <none>   minikube   <none>           <none>
admin-front-end-app      0/1     ContainerCreating   0          3s    <none>   minikube   <none>           <none>
back-end-api-app         0/1     ContainerCreating   0          3s    <none>   minikube   <none>           <none>
front-end-app            0/1     ContainerCreating   0          4s    <none>   minikube   <none>           <none>
NAME                     TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)   AGE
admin-back-end-api-app   ClusterIP   10.102.186.120   <none>        80/TCP    2s
admin-front-end-app      ClusterIP   10.101.239.238   <none>        80/TCP    3s
back-end-api-app         ClusterIP   10.108.96.149    <none>        80/TCP    4s
front-end-app            ClusterIP   10.106.252.195   <none>        80/TCP    5s
```

## Часть 2. Сетевые политики

#### Политика 1: Разрешить трафик между front-end и back-end-api (`non-admin-api-allow-g.yaml`)
[non-admin-api-allow-g.yaml](non-admin-api-allow-g.yaml)

#### Политика 2: Разрешить трафик между admin-front-end и admin-back-end-api
[non-admin-api-allow-g.yaml](non-admin-api-allow-g.yaml)

#### Политика 3: Запретить весь остальной трафик (deny-all)
[non-admin-api-allow-g.yaml](non-admin-api-allow-g.yaml)

## Часть 3. Применение сетевых политик

```bash
# Применить политики
kubectl apply -f non-admin-api-allow-g.yaml

# Проверить созданные политики
kubectl get networkpolicies
```

```bash
# удаление сетевых политик - может пригодиться в случае некорректной работы 
kubectl delete netpol --all -n network-policy-demo
```


#### Успешный результат выглядит так
```
professional@User-PC:/mnt/e/YaPracticumArc/architecture-pro-propdevelopment/Task5$ kubectl apply -f non-admin-api-allow-g.yaml
networkpolicy.networking.k8s.io/frontend-backend-allow created
networkpolicy.networking.k8s.io/backend-frontend-allow created
networkpolicy.networking.k8s.io/admin-frontend-backend-allow created
networkpolicy.networking.k8s.io/admin-backend-frontend-allow created
networkpolicy.networking.k8s.io/deny-all created
professional@User-PC:/mnt/e/YaPracticumArc/architecture-pro-propdevelopment/Task5$ kubectl get networkpolicies
NAME                           POD-SELECTOR              AGE
admin-backend-frontend-allow   role=admin-front-end      64s
admin-frontend-backend-allow   role=admin-back-end-api   64s
backend-frontend-allow         role=front-end            64s
deny-all                       <none>                    64s
frontend-backend-allow         role=back-end-api         64s
professional@User-PC:/mnt/e/YaPracticumArc/architecture-pro-propdevelopment/Task5$
```

## Часть 4. Проверка сетевых политик
```bash
./test-network-policies-g.sh
```

## Часть 5. Очистка ресурсов (`cleanup.sh`)
```bash
./cleanup.sh
```

### Проверка вручную (альтернатива скриптам)

```bash
# Получить IP адреса подов
kubectl get pods -o wide

# Проверка доступа между front-end и back-end-api (должно работать)
kubectl exec -it front-end-app -- wget -qO- http://back-end-api-app

# Проверка доступа между front-end и admin-back-end-api (НЕ должно работать)
kubectl exec -it front-end-app -- wget -qO- --timeout=2 http://admin-back-end-api-app

# Проверка через временный под
kubectl run test-$RANDOM --rm -i -t --image=alpine -- sh
# Внутри контейнера:
wget -qO- http://front-end-app
wget -qO- http://back-end-api-app
wget -qO- http://admin-front-end-app
exit
```

### Ожидаемые результаты

| Соединение                           | Статус      | Причина                                |
|--------------------------------------|-------------|----------------------------------------|
| front-end → back-end-api             | ✅ Разрешено | NetworkPolicy разрешает                |
| back-end-api → front-end             | ✅ Разрешено | NetworkPolicy разрешает (двустороннее) |
| admin-front-end → admin-back-end-api | ✅ Разрешено | NetworkPolicy разрешает                |
| admin-back-end-api → admin-front-end | ✅ Разрешено | NetworkPolicy разрешает                |
| front-end → admin-back-end-api       | ❌ Запрещено | Нет разрешающей политики               |
| back-end-api → admin-front-end       | ❌ Запрещено | Нет разрешающей политики               |
| admin-front-end → back-end-api       | ❌ Запрещено | Нет разрешающей политики               |
| admin-back-end-api → front-end       | ❌ Запрещено | Нет разрешающей политики               |
