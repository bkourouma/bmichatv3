# BMI Chat Widget - Guide d'utilisation

## 🎯 Vue d'ensemble

Le module Widget de BMI Chat permet de créer des widgets de chat intégrables que vous pouvez ajouter à votre site web public pour permettre aux visiteurs d'interagir avec l'assistante IA BMI.

## 🚀 Fonctionnalités principales

### ✅ Création de widgets
- Interface intuitive pour créer des widgets personnalisés
- Configuration complète (couleurs, position, messages)
- Génération automatique de code d'intégration

### ✅ Gestion des widgets
- Liste de tous vos widgets créés
- Modification et suppression des widgets
- Aperçu en temps réel des configurations

### ✅ Personnalisation avancée
- Choix de la position (gauche/droite)
- Couleurs d'accent personnalisées
- Messages de bienvenue personnalisés
- Nom de l'assistant et de l'entreprise

### ✅ Intégration simple
- Code d'intégration en une seule ligne
- Compatible avec tous les sites web
- Responsive et moderne

## 📋 Comment utiliser

### 1. Accéder à la page Widgets

1. Connectez-vous à votre dashboard BMI Chat
2. Cliquez sur "Widgets" dans la barre de navigation
3. Vous verrez la liste de vos widgets existants

### 2. Créer un nouveau widget

1. Cliquez sur "Créer un widget"
2. Remplissez les informations de base :
   - **Nom du widget** : Nom pour identifier votre widget
   - **Description** : Description optionnelle
3. Configurez l'apparence :
   - **Position** : Gauche ou droite de l'écran
   - **Couleur d'accent** : Couleur principale du widget
4. Configurez le chat :
   - **Nom de l'entreprise** : Votre nom d'entreprise
   - **Nom de l'assistant** : Nom de l'assistant IA
   - **Message de bienvenue** : Message affiché au démarrage
5. Cliquez sur "Créer le widget"

### 3. Intégrer le widget sur votre site

1. Après avoir créé le widget, cliquez sur l'icône "Aperçu"
2. Copiez le code d'intégration fourni
3. Collez ce code dans le `<head>` de votre page HTML

Exemple de code d'intégration :
```html
<script src="https://api.bmi-chat.com/widget/chat-widget.js"></script>
<script>
  BMIWidget.init({
    position: 'right',
    accentColor: '#3b82f6',
    companyName: 'BMI',
    assistantName: 'Akissi',
    welcomeMessage: 'Bonjour ! Je suis Akissi, votre assistante BMI. Comment puis-je vous aider ?'
  });
</script>
```

### 4. Gérer vos widgets

- **Modifier** : Cliquez sur l'icône crayon pour modifier un widget
- **Aperçu** : Cliquez sur l'icône œil pour voir l'aperçu et le code
- **Copier le code** : Cliquez sur l'icône presse-papiers pour copier le code
- **Supprimer** : Cliquez sur l'icône poubelle pour supprimer un widget

## 🎨 Personnalisation

### Couleurs disponibles

Vous pouvez utiliser n'importe quelle couleur hexadécimale :

```javascript
// Bleu (par défaut)
accentColor: '#3b82f6'

// Vert
accentColor: '#10b981'

// Orange
accentColor: '#f59e0b'

// Rouge
accentColor: '#ef4444'

// Violet
accentColor: '#8b5cf6'
```

### Positions

```javascript
// Droite (par défaut)
position: 'right'

// Gauche
position: 'left'
```

### Messages personnalisés

```javascript
// Message de bienvenue personnalisé
welcomeMessage: 'Bonjour ! Je suis là pour vous aider avec vos questions sur nos services.'

// Nom de l'assistant personnalisé
assistantName: 'Mon Assistant'

// Nom de l'entreprise
companyName: 'Mon Entreprise'
```

## 🔧 Configuration avancée

### Options de configuration complètes

```javascript
BMIWidget.init({
  // Position du widget
  position: 'right', // 'left' ou 'right'
  
  // Couleur d'accent
  accentColor: '#3b82f6',
  
  // Informations de l'entreprise
  companyName: 'BMI',
  assistantName: 'Akissi',
  
  // Message de bienvenue
  welcomeMessage: 'Bonjour ! Je suis Akissi, votre assistante BMI. Comment puis-je vous aider ?',
  
  // URL de l'API (optionnel, pour développement)
  apiUrl: 'https://api.bmi-chat.com/widget'
});
```

### API JavaScript

Le widget expose plusieurs méthodes que vous pouvez utiliser :

```javascript
// Ouvrir le chat programmatiquement
BMIWidget.open();

// Fermer le chat programmatiquement
BMIWidget.close();

// Envoyer un message automatiquement
BMIWidget.sendMessage('Bonjour !');
```

## 📱 Responsive Design

Le widget s'adapte automatiquement à tous les appareils :

- **Desktop** : Fenêtre de chat complète (350px de large)
- **Tablet** : Adaptation automatique de la taille
- **Mobile** : Interface optimisée pour les écrans tactiles

## 🔒 Sécurité

- **HTTPS obligatoire** en production
- **Sessions sécurisées** avec identifiants uniques
- **Validation des données** côté client et serveur
- **Pas de stockage local** des conversations sensibles

## 📊 Analytics

Le widget collecte automatiquement des métriques anonymes :

- Nombre de conversations
- Temps de réponse moyen
- Questions les plus fréquentes
- Taux de satisfaction

Ces données sont disponibles dans votre dashboard BMI Chat.

## 🐛 Dépannage

### Le widget ne s'affiche pas

1. Vérifiez que le script est bien chargé dans le `<head>`
2. Vérifiez la console du navigateur pour les erreurs JavaScript
3. Assurez-vous que l'URL de l'API est accessible

### Erreurs de connexion

1. Vérifiez votre connexion internet
2. Assurez-vous que l'API BMI Chat est opérationnelle
3. Vérifiez les paramètres de configuration

### Problèmes d'affichage

1. Vérifiez que le z-index du widget est suffisant (9999)
2. Assurez-vous qu'aucun élément CSS n'interfère
3. Testez sur différents navigateurs

## 📞 Support

Pour toute question ou problème :

- **Email** : support@bmi-chat.com
- **Documentation** : https://docs.bmi-chat.com
- **GitHub** : https://github.com/bmi-chat/widget

## 🔄 Versions

- **Version actuelle** : 1.0.0
- **Dernière mise à jour** : Janvier 2024
- **Compatibilité** : Chrome 80+, Firefox 75+, Safari 13+, Edge 80+

---

**Note** : Ce guide sera mis à jour régulièrement avec les nouvelles fonctionnalités et améliorations du widget. 