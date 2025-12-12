#!/bin/bash

# Script pour mettre à jour les URLs du repository dans tous les manifests ArgoCD
# Usage: ./update-repo-url.sh https://github.com/YOUR_USERNAME/gitops-argocd-tp.git

if [ -z "$1" ]; then
  echo "❌ Erreur: URL du repository manquante"
  echo "Usage: $0 <REPO_URL>"
  echo "Exemple: $0 https://github.com/votre-username/gitops-argocd-tp.git"
  exit 1
fi

REPO_URL="$1"

echo "🔄 Mise à jour des URLs du repository vers: $REPO_URL"

# Trouver et remplacer dans tous les fichiers YAML ArgoCD
find argocd/ -name "*.yaml" -type f -exec sed -i "s|REPLACE_WITH_YOUR_REPO_URL|$REPO_URL|g" {} \;

echo "✅ URLs mises à jour dans les fichiers suivants:"
grep -r "$REPO_URL" argocd/ --include="*.yaml" | cut -d: -f1 | sort -u

echo ""
echo "📝 N'oubliez pas de commiter et pousser les changements:"
echo "   git add argocd/"
echo "   git commit -m 'Update repository URLs in ArgoCD manifests'"
echo "   git push"
