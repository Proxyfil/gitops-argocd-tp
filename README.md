# GitOps ArgoCD TP - Multi-Environment Microservices Deployment


# Script pour mettre à jour les URLs du repository dans tous les manifests ArgoCDCe projet implémente une architecture GitOps complète pour le déploiement d'une application microservices sur Kubernetes en utilisant ArgoCD.

# Usage: ./update-repo-url.sh https://github.com/YOUR_USERNAME/gitops-argocd-tp.git

## 🏗️ Architecture

if [ -z "$1" ]; then

  echo "❌ Erreur: URL du repository manquante"L'application se compose de 4 microservices :

  echo "Usage: $0 <REPO_URL>"- **Frontend** : Interface utilisateur (Nginx)

  echo "Exemple: $0 https://github.com/votre-username/gitops-argocd-tp.git"- **Backend** : API REST (Node.js)

  exit 1- **Database** : PostgreSQL (avec StatefulSet et persistence)

fi- **Redis** : Cache en mémoire



REPO_URL="$1"## 📁 Structure du projet



echo "🔄 Mise à jour des URLs du repository vers: $REPO_URL"```

gitops-argocd-tp/

# Trouver et remplacer dans tous les fichiers YAML ArgoCD├── charts/                      # Helm charts des microservices

find argocd/ -name "*.yaml" -type f -exec sed -i "s|REPLACE_WITH_YOUR_REPO_URL|$REPO_URL|g" {} \;│   ├── frontend/

│   ├── backend/

echo "✅ URLs mises à jour dans les fichiers suivants:"│   ├── database/

grep -r "$REPO_URL" argocd/ --include="*.yaml" | cut -d: -f1 | sort -u│   └── redis/

├── envs/                        # Values files par environnement

echo ""│   ├── dev/

echo "📝 N'oubliez pas de commiter et pousser les changements:"│   ├── staging/

echo "   git add argocd/"│   └── production/

echo "   git commit -m 'Update repository URLs in ArgoCD manifests'"└── argocd/                      # Définitions ArgoCD

echo "   git push"    ├── applications/

    └── applicationsets/
```

## 🚀 Déploiements

### Environnements

Le projet supporte 3 environnements avec des configurations différentes :

| Environnement | Replicas | Resources | Ingress | HPA | Volume DB |
|--------------|----------|-----------|---------|-----|-----------|
| **dev** | 1 | Minimales | ❌ | ❌ | 1Gi |
| **staging** | 2 | Moyennes | ✅ | ❌ | 5Gi |
| **production** | 5+ | Élevées | ✅ + TLS | ✅ | 20Gi |

### Ordre de déploiement (Sync Waves)

Les microservices sont déployés dans l'ordre suivant grâce aux sync waves ArgoCD :
1. **Wave 0** : Database + Redis (infrastructure)
2. **Wave 1** : Backend (dépend de la DB et Redis)
3. **Wave 2** : Frontend (dépend du Backend)

## 🛠️ Prérequis

- Kubernetes cluster (Minikube, Kind, K3s, etc.)
- kubectl configuré
- Helm 3.x
- ArgoCD installé sur le cluster
- Git

## 📦 Installation

### Option 1 : Déploiement avec ArgoCD (Recommandé)

**Voir le guide complet** : [argocd/DEPLOYMENT.md](argocd/DEPLOYMENT.md)

```bash
# 1. Installer ArgoCD sur votre cluster
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# 2. Pousser ce repository vers Git et mettre à jour les URLs
git remote add origin https://github.com/YOUR_USERNAME/gitops-argocd-tp.git
git push -u origin master

# 3. Déployer avec App of Apps (dev uniquement)
kubectl apply -f argocd/applications/app-of-apps.yaml

# OU déployer tous les environnements avec ApplicationSet
kubectl apply -f argocd/applicationsets/microservices-appset.yaml
```

### Option 2 : Test local avec Helm (sans ArgoCD)

#### 1. Validation des Helm Charts

```bash
# Lint tous les charts
helm lint charts/frontend
helm lint charts/backend
helm lint charts/database
helm lint charts/redis

# Générer les templates pour vérification
helm template frontend charts/frontend -f envs/dev/frontend-values.yaml
helm template backend charts/backend -f envs/dev/backend-values.yaml
helm template database charts/database -f envs/dev/database-values.yaml
helm template redis charts/redis -f envs/dev/redis-values.yaml
```

#### 2. Installation manuelle

```bash
# Créer le namespace
kubectl create namespace dev

# Installer les charts avec Helm
helm install database charts/database -f envs/dev/database-values.yaml -n dev
helm install redis charts/redis -f envs/dev/redis-values.yaml -n dev
helm install backend charts/backend -f envs/dev/backend-values.yaml -n dev
helm install frontend charts/frontend -f envs/dev/frontend-values.yaml -n dev

# Vérifier les déploiements
kubectl get all -n dev
```

#### 3. Nettoyage

```bash
helm uninstall frontend backend database redis -n dev
kubectl delete namespace dev
```

## 🔐 Sécurité

⚠️ **Important** : Les secrets dans ce repository sont des exemples et **NE DOIVENT PAS** être utilisés en production.

Pour la production, utilisez :
- **Sealed Secrets** (Bitnami)
- **External Secrets Operator**
- **HashiCorp Vault**

## 📝 Principes GitOps respectés

✅ **Déclaratif** : Tout l'état du système est décrit dans des manifestes  
✅ **Versionné** : Git est la source unique de vérité  
✅ **Automatique** : ArgoCD synchronise automatiquement  
✅ **Réconciliation** : Détection et correction automatique des drifts  

## 🎯 Fonctionnalités implémentées

- ✅ Helm charts modulaires et réutilisables
- ✅ Configuration multi-environnement (dev/staging/production)
- ✅ Gestion des resources (requests/limits)
- ✅ Health checks (liveness & readiness probes)
- ✅ Persistence pour PostgreSQL (StatefulSet + PVC)
- ✅ Autoscaling (HPA) pour production
- ✅ Ingress avec support TLS pour production
- ✅ Sync waves pour orchestrer l'ordre de déploiement
- ✅ ConfigMaps et Secrets pour la configuration

## 🔄 Workflow GitOps

1. Développeur modifie un fichier values ou un chart
2. Commit et push vers Git
3. ArgoCD détecte le changement
4. ArgoCD synchronise automatiquement le cluster
5. Le cluster converge vers l'état désiré

## 📚 Documentation complémentaire

- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [Helm Documentation](https://helm.sh/docs/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)

## 👥 Auteur

Travail Pratique - Formation GitOps & ArgoCD

## 📄 Licence

Projet éducatif
