#!/bin/bash
# bind-roles.sh– Связывание пользователей с ролями

echo "=========================================="
echo "Создание привязок пользователей к ролям"
echo "=========================================="

# 1. ClusterRoleBinding для аудиторов (viewer)
echo "Создание ClusterRoleBinding для группы auditors..."
cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: auditors-viewer-binding
subjects:
- kind: User
  name: auditor-ivanov
  apiGroup: rbac.authorization.k8s.io
- kind: User
  name: auditor-petrov
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: viewer
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: auditors-security-binding
subjects:
- kind: User
  name: auditor-ivanov
  apiGroup: rbac.authorization.k8s.io
- kind: User
  name: auditor-petrov
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: security-auditor
  apiGroup: rbac.authorization.k8s.io
EOF

# 2. ClusterRoleBinding для DevOps
echo "Создание ClusterRoleBinding для devops..."
cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: devops-cluster-reader
subjects:
- kind: User
  name: devops-volkov
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: cluster-reader
  apiGroup: rbac.authorization.k8s.io
EOF

# 3. RoleBinding для разработчиков в неймспейсе dev
echo "Создание RoleBinding для разработчиков..."
cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: developer-smirnov-binding
  namespace: dev
subjects:
- kind: User
  name: developer-smirnov
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: developer
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: developer-kuznetsov-binding
  namespace: dev
subjects:
- kind: User
  name: developer-kuznetsov
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: developer
  apiGroup: rbac.authorization.k8s.io
EOF

# 4. RoleBinding для DevOps в неймспейсах
echo "Создание RoleBinding для DevOps..."
cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: devops-dev-binding
  namespace: dev
subjects:
- kind: User
  name: devops-volkov
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: devops-engineer
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: devops-staging-binding
  namespace: staging
subjects:
- kind: User
  name: devops-volkov
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: devops-engineer
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: devops-prod-binding
  namespace: production
subjects:
- kind: User
  name: devops-volkov
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: devops-engineer-prod
  apiGroup: rbac.authorization.k8s.io
EOF

# 5. ClusterRoleBinding для администратора
echo "Создание ClusterRoleBinding для администратора..."
cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-binding
subjects:
- kind: User
  name: admin-sokolov
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: cluster-admin
  apiGroup: rbac.authorization.k8s.io
EOF

echo "✅ Все привязки созданы!"