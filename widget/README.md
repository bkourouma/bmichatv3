# BMI Chat Widget

Un widget de chat intégrable pour permettre aux visiteurs de votre site web d'interagir avec l'assistante IA BMI.

## 🚀 Fonctionnalités

- **Chat en temps réel** avec l'assistante Akissi
- **Interface moderne** et responsive
- **Personnalisation complète** (couleurs, position, messages)
- **Intégration simple** en quelques lignes de code
- **Sécurisé** avec gestion des sessions
- **Analytics** pour suivre les interactions

## 📦 Installation

### 1. Inclure le script

Ajoutez le script du widget dans le `<head>` de votre page HTML :

```html
<script src="https://api.bmi-chat.com/widget/chat-widget.js"></script>
```

### 2. Initialiser le widget

Ajoutez le code d'initialisation juste avant la fermeture de `</body>` :

```html
<script>
  BMIWidget.init({
    position: 'right',           // 'left' ou 'right'
    accentColor: '#3b82f6',     // Couleur d'accent
    companyName: 'BMI',         // Nom de votre entreprise
    assistantName: 'Akissi',    // Nom de l'assistant
    welcomeMessage: 'Bonjour ! Je suis Akissi, votre assistante BMI. Comment puis-je vous aider ?'
  });
</script>
```

## ⚙️ Configuration

### Options disponibles

| Option | Type | Défaut | Description |
|--------|------|--------|-------------|
| `position` | string | `'right'` | Position du widget (`'left'` ou `'right'`) |
| `accentColor` | string | `'#3b82f6'` | Couleur d'accent du widget |
| `companyName` | string | `'BMI'` | Nom de votre entreprise |
| `assistantName` | string | `'Akissi'` | Nom de l'assistant IA |
| `welcomeMessage` | string | `'Bonjour ! Je suis Akissi...'` | Message de bienvenue |
| `apiUrl` | string | `'https://api.bmi-chat.com/widget'` | URL de l'API (optionnel) |

### Exemple de configuration complète

```javascript
BMIWidget.init({
  position: 'left',
  accentColor: '#10b981',
  companyName: 'Mon Entreprise',
  assistantName: 'Mon Assistant',
  welcomeMessage: 'Bonjour ! Je suis là pour vous aider. Que puis-je faire pour vous ?'
});
```

## 🎨 Personnalisation

### Couleurs

Vous pouvez personnaliser les couleurs du widget :

```javascript
BMIWidget.init({
  accentColor: '#10b981',  // Vert
  // ou
  accentColor: '#f59e0b',  // Orange
  // ou
  accentColor: '#ef4444',  // Rouge
});
```

### Position

Le widget peut être positionné à gauche ou à droite :

```javascript
BMIWidget.init({
  position: 'left',   // Gauche
  // ou
  position: 'right',  // Droite (par défaut)
});
```

## 🔧 API

### Méthodes disponibles

#### `BMIWidget.init(options)`
Initialise le widget avec les options spécifiées.

#### `BMIWidget.open()`
Ouvre manuellement la fenêtre de chat.

#### `BMIWidget.close()`
Ferme manuellement la fenêtre de chat.

#### `BMIWidget.sendMessage(message)`
Envoie un message programmatiquement.

### Exemple d'utilisation avancée

```javascript
// Initialiser le widget
BMIWidget.init({
  position: 'right',
  accentColor: '#3b82f6'
});

// Ouvrir le chat après 5 secondes
setTimeout(() => {
  BMIWidget.open();
}, 5000);

// Envoyer un message automatiquement
setTimeout(() => {
  BMIWidget.sendMessage('Bonjour !');
}, 6000);
```

## 📱 Responsive

Le widget s'adapte automatiquement à tous les appareils :

- **Desktop** : Fenêtre de chat complète
- **Mobile** : Interface optimisée pour les écrans tactiles
- **Tablet** : Adaptation automatique de la taille

## 🔒 Sécurité

- **HTTPS obligatoire** pour la production
- **Sessions sécurisées** avec identifiants uniques
- **Validation des données** côté client et serveur
- **Pas de stockage local** des conversations sensibles

## 🚀 Développement

### Installation des dépendances

```bash
cd widget
npm install
```

### Développement local

```bash
npm run dev
```

Le widget sera disponible sur `http://localhost:3004`

### Build de production

```bash
npm run build
```

Les fichiers de production seront générés dans le dossier `dist/`

### Test

```bash
npm run test
```

## 📊 Analytics

Le widget collecte automatiquement des métriques anonymes :

- Nombre de conversations
- Temps de réponse moyen
- Questions les plus fréquentes
- Taux de satisfaction

Ces données sont disponibles dans le dashboard BMI Chat.

## 🐛 Dépannage

### Le widget ne s'affiche pas

1. Vérifiez que le script est bien chargé
2. Vérifiez la console pour les erreurs JavaScript
3. Assurez-vous que l'URL de l'API est accessible

### Erreurs de connexion

1. Vérifiez votre connexion internet
2. Assurez-vous que l'API BMI Chat est opérationnelle
3. Vérifiez les paramètres de configuration

### Problèmes d'affichage

1. Vérifiez que le z-index du widget est suffisant
2. Assurez-vous qu'aucun élément CSS n'interfère
3. Testez sur différents navigateurs

## 📞 Support

Pour toute question ou problème :

- **Email** : support@bmi-chat.com
- **Documentation** : https://docs.bmi-chat.com
- **GitHub** : https://github.com/bmi-chat/widget

## 📄 Licence

Ce widget est distribué sous licence MIT. Voir le fichier `LICENSE` pour plus de détails.

---

**Version** : 1.0.0  
**Dernière mise à jour** : Janvier 2024  
**Compatibilité** : Chrome 80+, Firefox 75+, Safari 13+, Edge 80+ 