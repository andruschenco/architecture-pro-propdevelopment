#!/usr/bin/env python3
import json
import sys

def analyze_audit_log(file_path):
    """
    Анализирует Kubernetes audit.log на наличие подозрительных событий.
    """
    suspicious_events = []

    print(f"Анализ файла: {file_path}")

    try:
        with open(file_path, 'r') as f:
            for line_num, line in enumerate(f, 1):
                line = line.strip()
                if not line:
                    continue

                try:
                    event = json.loads(line)
                except json.JSONDecodeError:
                    print(f"Предупреждение: Не удалось разобрать JSON в строке {line_num}. Пропускаем.", file=sys.stderr)
                    continue

                # Проверка 1: Доступ к secrets
                if event.get('objectRef', {}).get('resource') == 'secrets' and event.get('verb') == 'get':
                    event['_comment'] = "Обнаружен доступ к секрету (чтение)"
                    suspicious_events.append(event)
                    continue # Избегаем дублирования, если подходит под несколько условий

                # Проверка 2: kubectl exec в чужой под
                if event.get('verb') == 'create' and event.get('objectRef', {}).get('subresource') == 'exec':
                    event['_comment'] = "Обнаружена команда 'kubectl exec' в поде"
                    suspicious_events.append(event)
                    continue

                # Проверка 3: Создание привилегированного пода
                # Ищем операцию create или patch для пода
                if event.get('objectRef', {}).get('resource') == 'pods' and event.get('verb') in ['create', 'patch']:
                    # Проверяем requestObject на наличие привилегированного контейнера
                    # Обработка для разных stage (RequestReceived, RequestResponse)
                    request_obj = event.get('requestObject')
                    if request_obj and request_obj.get('kind') == 'Pod':
                        containers = request_obj.get('spec', {}).get('containers', [])
                        for container in containers:
                            if container.get('securityContext', {}).get('privileged') == True:
                                event['_comment'] = f"Обнаружено событие '{event.get('verb')}' привилегированного пода: {request_obj.get('metadata', {}).get('name')}"
                                suspicious_events.append(event)
                                break # Добавляем событие один раз
                    continue

                # Проверка 4: Действия с rolebindings / clusterrolebindings
                if event.get('objectRef', {}).get('resource') in ['rolebindings', 'clusterrolebindings']:
                    event['_comment'] = "Обнаружено изменение/создание привязки RBAC"
                    suspicious_events.append(event)
                    continue

                # Проверка 5: Пользователи с высокими привилегиями (члены groups: system:masters)
                # Считаем любую операцию от "мастеров" потенциально интересной, но логируем только если это не рутинные watch-запросы
                user_groups = event.get('user', {}).get('groups', [])
                if 'system:masters' in user_groups and event.get('verb') not in ['watch', 'list']:
                    event['_comment'] = f"Действие от пользователя с правами администратора (system:masters): {event.get('user', {}).get('username')}"
                    suspicious_events.append(event)
                    continue

                # Проверка 6: Конфликты и ошибки доступа (403, 409) для системных ресурсов
                response_status = event.get('responseStatus', {})
                if response_status.get('code') in [403, 409]:
                    resource = event.get('objectRef', {}).get('resource')
                    verb = event.get('verb')
                    if resource and verb:
                        event['_comment'] = f"Неуспешная операция (код {response_status.get('code')}): {verb} {resource}"
                        suspicious_events.append(event)
                        continue

    except FileNotFoundError:
        print(f"Ошибка: Файл '{file_path}' не найден.", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"Произошла непредвиденная ошибка: {e}", file=sys.stderr)
        sys.exit(1)

    # Сохраняем результат
    output_file = 'audit-extract.json'
    with open(output_file, 'w') as f:
        json.dump(suspicious_events, f, indent=2)

    print(f"Анализ завершен. Найдено {len(suspicious_events)} подозрительных событий.")
    print(f"Результат сохранен в файл: {output_file}")

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Использование: python audit-filter.py <путь_к_audit.log>")
        sys.exit(1)

    audit_log_path = sys.argv[1]
    analyze_audit_log(audit_log_path)

