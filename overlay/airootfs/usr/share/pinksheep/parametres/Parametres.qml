// PinkSheep — Paramètres (prototype). Logique : bin/pinksheep-parametres (objet « ps »).
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    id: fenetre
    width: 900
    height: 620
    minimumWidth: 720
    minimumHeight: 480
    visible: true
    title: "Paramètres PinkSheep"
    color: c.fond

    // Couleurs du fond d'écran (matugen), rose PinkSheep par défaut
    readonly property var c: ps.couleurs
    property int rubrique: 0

    // « pinksheep-parametres son » ouvre directement la rubrique Son
    function simplifier(t) {
        return t.toLowerCase().normalize("NFD").replace(/[\u0300-\u036f]/g, "").replace(/ /g, "-")
    }
    Component.onCompleted: {
        for (let i = 0; i < rubriques.length; i++)
            if (simplifier(rubriques[i].nom) === simplifier(rubriqueDemandee)) rubrique = i
    }

    // ── Le contenu : rubriques → cartes → boutons (identifiants d'actions) ──
    readonly property var rubriques: [
        { nom: "Apparence", icone: "🎨", cartes: [
            { titre: "Fond d'écran", texte: "Toutes les couleurs du bureau suivent le fond (barre, terminal, fenêtres…).",
              boutons: [ { l: "Choisir un fond", a: "fond_choisir" }, { l: "Au hasard", a: "fond_hasard" } ] },
            { titre: "Style du bureau", texte: "PinkSheep (par défaut) ou Hyprlust. Une sauvegarde de tes réglages est faite avant.",
              boutons: [ { l: "Style PinkSheep", a: "style_pinksheep" }, { l: "Style Hyprlust", a: "style_hyprlust" } ] },
            { titre: "Applis GTK et Qt", texte: "Thèmes, polices et curseurs des applis (Firefox, Dolphin…).",
              boutons: [ { l: "Applis GTK", a: "gtk" }, { l: "Applis Qt", a: "qt" } ] }
        ] },
        { nom: "Son", icone: "🔊", cartes: [
            { titre: "Son et micro", texte: "Volume par appli, sortie (casque, enceinte Bluetooth…), micro.",
              boutons: [ { l: "Ouvrir le mélangeur", a: "son" } ] }
        ] },
        { nom: "Réseau", icone: "📶", cartes: [
            { titre: "Wi-Fi et réseau", texte: "Réseaux enregistrés, mots de passe Wi-Fi, connexion filaire, VPN.",
              boutons: [ { l: "Réglages réseau", a: "reseau" } ] },
            { titre: "Bluetooth", texte: "Appairer une enceinte, un casque, une manette.",
              boutons: [ { l: "Appareils Bluetooth", a: "bluetooth" } ] }
        ] },
        { nom: "Écrans", icone: "🖥", cartes: [
            { titre: "Écrans", texte: "Résolution, fréquence, position et échelle de chaque écran.",
              boutons: [ { l: "Disposition des écrans", a: "ecrans" } ] },
            { titre: "Clavier et souris", texte: "Disposition du clavier, vitesse de la souris, pavé tactile : dans tes réglages perso (perso.lua), jamais écrasés.",
              boutons: [ { l: "Ouvrir perso.lua", a: "clavier" } ] }
        ] },
        { nom: "Fenêtres", icone: "🪟", cartes: [
            { titre: "Boutons sur les fenêtres", texte: "Réduire, agrandir, fermer à la souris. L'installation compile un module (quelques minutes).",
              etat: "boutons",
              boutons: [ { l: "Installer / activer", a: "boutons_on" }, { l: "Enlever", a: "boutons_off" } ] }
        ] },
        { nom: "Démarrage", icone: "🐑", cartes: [
            { titre: "Écran de chargement", texte: "L'écran PinkSheep animé pendant le démarrage. Ton mot de passe sera demandé dans le terminal.",
              etat: "chargement",
              boutons: [ { l: "Activer", a: "chargement_on" }, { l: "Messages du système", a: "chargement_off" } ] },
            { titre: "Menu de démarrage", texte: "Le menu GRUB aux couleurs de PinkSheep, ou le menu texte en cas de souci.",
              etat: "grub",
              boutons: [ { l: "Thème PinkSheep", a: "grub_theme" }, { l: "Menu texte", a: "grub_texte" } ] }
        ] },
        { nom: "Mises à jour", icone: "🔄", cartes: [
            { titre: "Mises à jour", texte: "Système (Arch), applis Flatpak et PinkSheep, en une fois.",
              maj: true,
              boutons: [ { l: "Tout mettre à jour", a: "maj_tout" }, { l: "Nouvelle version de PinkSheep ?", a: "maj_verifier" } ] },
            { titre: "Raccourcis clavier", texte: "La liste de tous les raccourcis (aussi avec SUPER + H).",
              boutons: [ { l: "Voir les raccourcis", a: "aide" } ] }
        ] }
    ]

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // ── Colonne des rubriques ──────────────────────────────
        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: 220
            color: c.surface

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 4

                Text {
                    text: "Paramètres"
                    color: c.primaire
                    font.pixelSize: 22
                    font.bold: true
                    Layout.bottomMargin: 2
                }
                Text {
                    text: ps.version()
                    color: c.discret
                    font.pixelSize: 12
                    Layout.bottomMargin: 12
                }

                Repeater {
                    model: fenetre.rubriques
                    delegate: Rectangle {
                        required property var modelData
                        required property int index
                        Layout.fillWidth: true
                        Layout.preferredHeight: 40
                        radius: 12
                        color: fenetre.rubrique === index ? c.conteneur
                             : (survol.hovered ? Qt.alpha(c.primaire, 0.12) : "transparent")
                        HoverHandler { id: survol }
                        TapHandler { onTapped: fenetre.rubrique = index }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 12
                            text: modelData.icone + "   " + modelData.nom
                            color: fenetre.rubrique === index ? c.texte : c.discret
                            font.pixelSize: 15
                            font.bold: fenetre.rubrique === index
                        }
                    }
                }
                Item { Layout.fillHeight: true }
            }
        }

        // ── Cartes de la rubrique choisie ──────────────────────
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: availableWidth

            ColumnLayout {
                width: parent.width
                spacing: 14

                Text {
                    Layout.topMargin: 22
                    Layout.leftMargin: 26
                    text: fenetre.rubriques[fenetre.rubrique].nom
                    color: c.texte
                    font.pixelSize: 26
                    font.bold: true
                }

                Repeater {
                    model: fenetre.rubriques[fenetre.rubrique].cartes
                    delegate: Rectangle {
                        id: carte
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.leftMargin: 22
                        Layout.rightMargin: 22
                        implicitHeight: contenu.implicitHeight + 32
                        radius: 18
                        color: c.surface
                        border.color: Qt.alpha(c.contour, 0.35)

                        property string etatTexte: modelData.etat ? ps.etat(modelData.etat) : ""

                        ColumnLayout {
                            id: contenu
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 16
                            spacing: 8

                            Text {
                                text: carte.modelData.titre
                                color: c.texte
                                font.pixelSize: 17
                                font.bold: true
                            }
                            Text {
                                Layout.fillWidth: true
                                text: carte.modelData.texte
                                textFormat: Text.PlainText
                                color: c.discret
                                font.pixelSize: 13
                                wrapMode: Text.WordWrap
                            }
                            Text {
                                visible: carte.etatTexte !== ""
                                text: "● " + carte.etatTexte
                                color: c.primaire
                                font.pixelSize: 13
                            }
                            Text {
                                visible: carte.modelData.maj === true
                                Layout.fillWidth: true
                                text: ps.majTexte
                                color: c.primaire
                                font.pixelSize: 13
                                wrapMode: Text.WordWrap
                                Component.onCompleted: if (carte.modelData.maj === true) ps.verifierMaj()
                            }

                            Flow {
                                Layout.fillWidth: true
                                Layout.topMargin: 4
                                spacing: 8
                                Repeater {
                                    model: carte.modelData.boutons
                                    delegate: Button {
                                        id: bouton
                                        required property var modelData
                                        readonly property bool ok: ps.disponible(modelData.a)
                                        text: ok ? modelData.l : modelData.l + " (non installé)"
                                        enabled: ok
                                        onClicked: ps.lancer(modelData.a)
                                        ToolTip.visible: hovered && !ok
                                        ToolTip.text: "Programme manquant : " + ps.manquant(modelData.a)
                                        contentItem: Text {
                                            text: bouton.text
                                            color: bouton.ok ? c.sur_primaire : c.discret
                                            font.pixelSize: 13
                                            font.bold: true
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter
                                        }
                                        background: Rectangle {
                                            implicitHeight: 36
                                            implicitWidth: 120
                                            radius: 18
                                            color: !bouton.ok ? Qt.alpha(c.contour, 0.25)
                                                 : bouton.down ? Qt.darker(c.primaire, 1.2)
                                                 : bouton.hovered ? Qt.lighter(c.primaire, 1.08) : c.primaire
                                        }
                                        leftPadding: 18
                                        rightPadding: 18
                                    }
                                }
                            }
                        }
                    }
                }
                Item { Layout.preferredHeight: 20 }
            }
        }
    }

    // Échap ferme la fenêtre
    Shortcut { sequence: "Escape"; onActivated: fenetre.close() }
}
