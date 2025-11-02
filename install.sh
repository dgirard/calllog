#!/bin/bash

# Script d'installation de CallLog avec saisie audio

echo "==================================="
echo "   CallLog v1.3.0 - Installation   "
echo "==================================="
echo ""

# Vérifier si adb est installé
if ! command -v adb &> /dev/null; then
    echo "❌ adb n'est pas installé. Installez Android SDK tools."
    exit 1
fi

# Vérifier les appareils connectés
echo "🔍 Recherche des appareils Android..."
DEVICES=$(adb devices | grep -v "List" | grep "device$")

if [ -z "$DEVICES" ]; then
    echo "❌ Aucun appareil Android connecté."
    echo ""
    echo "📱 Pour connecter votre appareil :"
    echo "   1. Activez le mode développeur sur votre téléphone"
    echo "   2. Activez le débogage USB"
    echo "   3. Connectez votre téléphone via USB"
    echo "   4. Acceptez l'autorisation de débogage sur votre téléphone"
    echo ""
    echo "Puis relancez ce script."
    exit 1
fi

echo "✅ Appareil(s) détecté(s) :"
echo "$DEVICES"
echo ""

# Chemin vers l'APK
APK_PATH="build/app/outputs/flutter-apk/app-release.apk"

# Vérifier si l'APK existe
if [ ! -f "$APK_PATH" ]; then
    echo "❌ APK non trouvé. Exécutez d'abord :"
    echo "   flutter build apk --release"
    exit 1
fi

# Installer l'APK
echo "📦 Installation de CallLog..."
adb install -r "$APK_PATH"

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Installation réussie !"
    echo ""
    echo "🎉 NOUVELLES FONCTIONNALITÉS :"
    echo "   • 🎤 Saisie vocale des événements"
    echo "   • 🤖 Extraction automatique des dates et détails"
    echo "   • 📅 Gestion complète des événements"
    echo ""
    echo "📝 Comment utiliser la saisie vocale :"
    echo "   1. Allez dans Événements → Ajouter (+)"
    echo "   2. Appuyez sur 'Enregistrer' 🎤"
    echo "   3. Décrivez votre événement à voix haute"
    echo "   4. L'app remplit automatiquement le formulaire !"
    echo ""
    echo "💡 Exemples de phrases :"
    echo "   • 'Vacances du 10 au 15 août à la plage'"
    echo "   • 'RDV dentiste demain à 14h'"
    echo "   • 'Anniversaire de Marie le 25 mars'"
    echo ""

    # Lancer l'app
    echo "🚀 Lancement de l'application..."
    adb shell monkey -p com.example.calllog -c android.intent.category.LAUNCHER 1 &> /dev/null

    echo "✅ CallLog est maintenant ouvert sur votre appareil !"
else
    echo ""
    echo "❌ Erreur lors de l'installation."
    echo "   Vérifiez que l'application n'est pas déjà ouverte."
fi