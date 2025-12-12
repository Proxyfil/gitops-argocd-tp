# Déploiement ArgoCD - Guide d'utilisation

Ce guide explique comment déployer l'application microservices avec ArgoCD en utilisant le pattern **App of Apps** et les **ApplicationSets**.

## 📋 Prérequis

1. **Cluster Kubernetes** fonctionnel
2. **ArgoCD** installé sur le cluster
3. **Repository Git** distant configuré (GitHub, GitLab, etc.)
4. **ArgoCD CLI** installé (optionnel mais recommandé)

## 🚀 Installation d'ArgoCD (si nécessaire)

```bash
# Créer le namespace ArgoCD
kubectl create namespace argocd

# Installer ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Attendre que les pods soient prêts
kubectl wait --for=condition=Ready pods --all -n argocd --timeout=300s

# Exposer l'interface ArgoCD (port-forward)
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Récupérer le mot de passe admin initial
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

Accédez à ArgoCD : https://localhost:8080  
Username: `admin`  
Password: (celui récupéré ci-dessus)

## 📝 Configuration du Repository

**IMPORTANT** : Avant de déployer, vous devez :

1. **Pousser ce code vers un repository Git distant**

```bash
# Ajouter le remote (remplacer par votre URL)
git remote add origin https://github.com/YOUR_USERNAME/gitops-argocd-tp.git

# Pousser le code
git push -u origin master
```

2. **Mettre à jour les URLs dans les manifests ArgoCD**

Remplacer `REPLACE_WITH_YOUR_REPO_URL` dans les fichiers suivants :
- `argocd/applications/app-of-apps.yaml`
- `argocd/applications/*-dev.yaml`
- `argocd/applicationsets/microservices-appset.yaml`

Exemple avec sed :
```bash
# Remplacer automatiquement (adapter l'URL)
REPO_URL="https://github.com/YOUR_USERNAME/gitops-argocd-tp.git"

find argocd/ -name "*.yaml" -type f -exec sed -i "s|REPLACE_WITH_YOUR_REPO_URL|$REPO_URL|g" {} \;

# Commiter le changement
git add argocd/
git commit -m "Update repository URLs in ArgoCD manifests"
git push
```

## 🎯 Méthode 1 : Déploiement avec App of Apps (Recommandé pour Dev)

Cette méthode déploie uniquement l'environnement **dev** avec le pattern App of Apps.

### Étape 1 : Déployer l'App of Apps parent

```bash
kubectl apply -f argocd/applications/app-of-apps.yaml
```

### Étape 2 : Vérifier dans l'interface ArgoCD

L'application `app-of-apps` va créer automatiquement :
- `frontend-dev`
- `backend-dev`
- `database-dev`
- `redis-dev`

### Étape 3 : Synchroniser (si auto-sync désactivé)

```bash
# Via CLI
argocd app sync app-of-apps

# Ou via l'interface web : cliquer sur "Sync" pour chaque app
```

### Vérification

```bash
# Voir toutes les applications ArgoCD
kubectl get applications -n argocd

# Voir les pods dans le namespace dev
kubectl get pods -n dev

# Voir tous les services
kubectl get svc -n dev
```

## 🌍 Méthode 2 : Déploiement Multi-Environnement avec ApplicationSet

Cette méthode déploie **tous les microservices** sur **tous les environnements** (dev, staging, production) en une seule commande.

### Déployer l'ApplicationSet

```bash
kubectl apply -f argocd/applicationsets/microservices-appset.yaml
```

### Ce qui sera créé automatiquement

L'ApplicationSet va générer **12 applications** (4 microservices × 3 environnements) :

**Dev :**
- `frontend-dev`
- `backend-dev`
- `database-dev`
- `redis-dev`

**Staging :**
- `frontend-staging`
- `backend-staging`
- `database-staging`
- `redis-staging`

**Production :**
- `frontend-production`
- `backend-production`
- `database-production`
- `redis-production`

### Vérification

```bash
# Voir toutes les applications générées
kubectl get applications -n argocd

# Voir les namespaces créés
kubectl get namespaces

# Voir les pods par environnement
kubectl get pods -n dev
kubectl get pods -n staging
kubectl get pods -n production
```

## 🔄 Ordre de déploiement (Sync Waves)

Les sync waves garantissent l'ordre de déploiement :

```
Wave 0 (infrastructure) → Wave 1 (backend) → Wave 2 (frontend)
```

- **Wave 0** : Database et Redis déployés en premier
- **Wave 1** : Backend déployé après (dépend de DB et Redis)
- **Wave 2** : Frontend déployé en dernier (dépend du Backend)

## 🛠️ Commandes utiles

### Via ArgoCD CLI

```bash
# Lister toutes les applications
argocd app list

# Voir les détails d'une application
argocd app get frontend-dev

# Synchroniser une application
argocd app sync frontend-dev

# Synchroniser toutes les applications
argocd app sync --all

# Voir les logs
argocd app logs frontend-dev

# Supprimer une application
argocd app delete frontend-dev
```

### Via kubectl

```bash
# Voir toutes les applications ArgoCD
kubectl get applications -n argocd

# Voir les détails d'une application
kubectl get application frontend-dev -n argocd -o yaml

# Forcer la synchronisation
kubectl patch application frontend-dev -n argocd --type merge -p '{"metadata":{"annotations":{"argocd.argoproj.io/refresh":"hard"}}}'
```

## 🔧 Configuration de la synchronisation automatique

Les applications sont configurées avec `automated sync` :

```yaml
syncPolicy:
  automated:
    prune: true        # Supprime les resources obsolètes
    selfHeal: true     # Restaure si modification manuelle
```

Pour désactiver la synchro auto (recommandé en production) :

```bash
argocd app set frontend-production --sync-policy none
```

## 🧹 Nettoyage

### Supprimer un environnement

```bash
# Supprimer toutes les apps dev
argocd app delete frontend-dev backend-dev database-dev redis-dev

# Ou supprimer le namespace (attention aux PVC !)
kubectl delete namespace dev
```

### Supprimer l'ApplicationSet

```bash
kubectl delete -f argocd/applicationsets/microservices-appset.yaml

# Cela supprimera toutes les applications générées
```

### Supprimer ArgoCD complètement

```bash
kubectl delete -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl delete namespace argocd
```

## 🐛 Troubleshooting

### Application bloquée en "OutOfSync"

```bash
# Forcer la synchronisation
argocd app sync frontend-dev --force

# Voir les différences
argocd app diff frontend-dev
```

### Erreur "Unable to create application"

Vérifier que l'URL du repository est correcte :
```bash
kubectl get application frontend-dev -n argocd -o yaml | grep repoURL
```

### Pods qui ne démarrent pas

```bash
# Vérifier les events
kubectl describe pod <pod-name> -n dev

# Voir les logs
kubectl logs <pod-name> -n dev
```

### PVC bloqué en "Pending"

```bash
# Vérifier les PVC
kubectl get pvc -n dev

# Voir pourquoi il est pending
kubectl describe pvc <pvc-name> -n dev

# Solution : installer un storage provisioner (ex: local-path-provisioner pour Kubernetes local)
```

## 📊 Monitoring

### Via l'interface ArgoCD

1. Accéder à https://localhost:8080
2. Voir l'arborescence des applications
3. Cliquer sur une application pour voir :
   - Status de sync
   - Health status
   - Resource tree
   - Logs des pods

### Via CLI

```bash
# Voir le statut de santé
argocd app get frontend-dev --show-operation

# Voir l'historique des syncs
argocd app history frontend-dev
```

## 🎓 Bonnes pratiques

1. **Production** : Désactiver auto-sync, utiliser manual sync
2. **Secrets** : Utiliser Sealed Secrets ou External Secrets Operator
3. **Rollback** : Utiliser l'historique ArgoCD pour revenir en arrière
4. **Notifications** : Configurer les notifications ArgoCD (Slack, etc.)
5. **RBAC** : Configurer les permissions ArgoCD par équipe

## 📚 Ressources

- [Documentation ArgoCD](https://argo-cd.readthedocs.io/)
- [ApplicationSet Documentation](https://argo-cd.readthedocs.io/en/stable/user-guide/application-set/)
- [Sync Waves](https://argo-cd.readthedocs.io/en/stable/user-guide/sync-waves/)
