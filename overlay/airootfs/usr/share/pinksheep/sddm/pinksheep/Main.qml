// ╭──────────────────────────────────────────────────────────╮
// │  PinkSheep — écran de connexion (thème SDDM, Qt 6)        │
// │  Utilise seulement QtQuick et les objets fournis par      │
// │  SDDM : sddm, userModel, sessionModel, keyboard, config.  │
// ╰──────────────────────────────────────────────────────────╯
import QtQuick
import QtQuick.Controls

Rectangle {
    id: racine
    width: 1920
    height: 1080
    color: "#1a1220"

    readonly property color accent:  config.accent ? config.accent : "#ff7eb6"
    readonly property color fond:    "#1a1220"
    readonly property color surface: "#2a1d33"
    readonly property color texte:   "#f5e6ef"
    readonly property color discret: "#a58fa8"
    readonly property real  echelle: Math.max(0.75, Math.min(width / 1920, height / 1080))

    property int utilisateurIndex: userModel.lastIndex >= 0 ? userModel.lastIndex : 0
    property int sessionIndex: sessionModel.lastIndex >= 0 ? sessionModel.lastIndex : 0
    property string message: ""

    function nomUtilisateur(i) {
        var n = userModel.data(userModel.index(i, 0), Qt.UserRole + 1)
        return n ? n : ""
    }
    function nomAffiche(i) {
        var r = userModel.data(userModel.index(i, 0), Qt.UserRole + 2)
        return (r && r.length > 0) ? r : nomUtilisateur(i)
    }
    function seConnecter() {
        message = ""
        sddm.login(nomUtilisateur(utilisateurIndex), motDePasse.text, sessionIndex)
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            racine.message = "Mot de passe incorrect"
            motDePasse.text = ""
            motDePasse.forceActiveFocus()
            secousse.start()
        }
        function onLoginSucceeded() { racine.message = "" }
    }

    // ── Fond ──────────────────────────────────────────────
    Image {
        anchors.fill: parent
        source: config.background ? config.background : "fond.png"
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
    }
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: "#cc1a1220" }
            GradientStop { position: 0.55; color: "#551a1220" }
            GradientStop { position: 1.0; color: "#991a1220" }
        }
    }

    // ── Horloge (à gauche) ────────────────────────────────
    Column {
        anchors.left: parent.left
        anchors.leftMargin: 120 * racine.echelle
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6 * racine.echelle

        Text {
            id: heure
            color: racine.texte
            font.pixelSize: 140 * racine.echelle
            font.weight: Font.Light
            text: Qt.formatTime(new Date(), "HH:mm")
        }
        Text {
            id: date
            color: racine.accent
            font.pixelSize: 34 * racine.echelle
            font.capitalization: Font.Capitalize
            text: new Date().toLocaleDateString(Qt.locale("fr_FR"), "dddd d MMMM")
        }
        Timer {
            interval: 1000; running: true; repeat: true
            onTriggered: {
                heure.text = Qt.formatTime(new Date(), "HH:mm")
                date.text = new Date().toLocaleDateString(Qt.locale("fr_FR"), "dddd d MMMM")
            }
        }
    }

    // ── Carte de connexion (à droite) ─────────────────────
    Rectangle {
        id: carte
        width: 440 * racine.echelle
        height: colonne.implicitHeight + 70 * racine.echelle
        anchors.right: parent.right
        anchors.rightMargin: 160 * racine.echelle
        anchors.verticalCenter: parent.verticalCenter
        radius: 28 * racine.echelle
        color: "#cc1a1220"
        border.color: Qt.rgba(1, 0.49, 0.71, 0.45)
        border.width: 2

        SequentialAnimation {
            id: secousse
            NumberAnimation { target: carte; property: "anchors.rightMargin"; to: 160 * racine.echelle + 14; duration: 50 }
            NumberAnimation { target: carte; property: "anchors.rightMargin"; to: 160 * racine.echelle - 14; duration: 70 }
            NumberAnimation { target: carte; property: "anchors.rightMargin"; to: 160 * racine.echelle; duration: 50 }
        }

        Column {
            id: colonne
            anchors.centerIn: parent
            width: parent.width - 70 * racine.echelle
            spacing: 18 * racine.echelle

            // Avatar : photo du compte si elle existe, sinon le mouton
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 130 * racine.echelle; height: width; radius: width / 2
                color: racine.surface
                border.color: racine.accent; border.width: 3
                Image {
                    anchors.fill: parent; anchors.margins: 10 * racine.echelle
                    source: "logo.png"
                    fillMode: Image.PreserveAspectFit
                }
            }

            // Nom de l'utilisateur, avec flèches s'il y a plusieurs comptes
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 16 * racine.echelle
                Text {
                    visible: userModel.count > 1
                    text: "‹"; color: racine.accent
                    font.pixelSize: 34 * racine.echelle
                    MouseArea {
                        anchors.fill: parent; anchors.margins: -10
                        onClicked: racine.utilisateurIndex = (racine.utilisateurIndex + userModel.count - 1) % userModel.count
                    }
                }
                Text {
                    text: racine.nomAffiche(racine.utilisateurIndex)
                    color: racine.texte
                    font.pixelSize: 30 * racine.echelle
                    font.weight: Font.DemiBold
                }
                Text {
                    visible: userModel.count > 1
                    text: "›"; color: racine.accent
                    font.pixelSize: 34 * racine.echelle
                    MouseArea {
                        anchors.fill: parent; anchors.margins: -10
                        onClicked: racine.utilisateurIndex = (racine.utilisateurIndex + 1) % userModel.count
                    }
                }
            }

            // Mot de passe
            TextField {
                id: motDePasse
                objectName: "motDePasse"
                width: parent.width
                height: 56 * racine.echelle
                echoMode: TextInput.Password
                passwordCharacter: "●"
                color: racine.texte
                font.pixelSize: 20 * racine.echelle
                horizontalAlignment: TextInput.AlignHCenter
                focus: true
                background: Rectangle {
                    radius: 16 * racine.echelle
                    color: racine.surface
                    border.color: motDePasse.activeFocus ? racine.accent : "#4a3a50"
                    border.width: 2
                }
                Text {
                    anchors.centerIn: parent
                    visible: motDePasse.text.length === 0
                    text: "Mot de passe"
                    color: racine.discret
                    font.pixelSize: 18 * racine.echelle
                }
                Keys.onReturnPressed: racine.seConnecter()
                Keys.onEnterPressed: racine.seConnecter()
                Component.onCompleted: forceActiveFocus()
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: racine.message.length > 0 ? racine.message
                      : ((keyboard && keyboard.capsLock) ? "Majuscules activées" : " ")
                color: racine.message.length > 0 ? "#ff6b8a" : racine.discret
                font.pixelSize: 16 * racine.echelle
            }

            // Bouton Connexion
            Rectangle {
                width: parent.width
                height: 54 * racine.echelle
                radius: 16 * racine.echelle
                color: zoneConnexion.pressed ? Qt.darker(racine.accent, 1.2)
                       : (zoneConnexion.containsMouse ? Qt.lighter(racine.accent, 1.1) : racine.accent)
                Text {
                    anchors.centerIn: parent
                    text: "Se connecter"
                    color: racine.fond
                    font.pixelSize: 20 * racine.echelle
                    font.weight: Font.DemiBold
                }
                MouseArea {
                    id: zoneConnexion
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: racine.seConnecter()
                }
            }
        }
    }

    // ── Barre du bas : session, clavier, extinction ───────
    Row {
        anchors.left: parent.left
        anchors.leftMargin: 40 * racine.echelle
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 30 * racine.echelle
        spacing: 24 * racine.echelle

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "🐑  " + (sddm.hostName ? sddm.hostName : "PinkSheep")
            color: racine.discret
            font.pixelSize: 18 * racine.echelle
        }

        ComboBox {
            id: choixSession
            visible: sessionModel.rowCount() > 1
            width: 240 * racine.echelle
            height: 44 * racine.echelle
            model: sessionModel
            textRole: "name"
            currentIndex: racine.sessionIndex
            onActivated: function(i) { racine.sessionIndex = i }
            font.pixelSize: 16 * racine.echelle
            contentItem: Text {
                leftPadding: 14 * racine.echelle
                text: "Session : " + choixSession.displayText
                color: racine.texte
                font: choixSession.font
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
            }
            background: Rectangle {
                radius: 12 * racine.echelle
                color: "#aa2a1d33"
                border.color: "#4a3a50"
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: !!(keyboard && keyboard.layouts && keyboard.layouts.length > 0)
            text: "⌨  " + ((keyboard && keyboard.layouts && keyboard.layouts.length > keyboard.currentLayout && keyboard.currentLayout >= 0)
                           ? keyboard.layouts[keyboard.currentLayout].shortName.toUpperCase() : "")
            color: racine.discret
            font.pixelSize: 18 * racine.echelle
        }
    }

    Row {
        anchors.right: parent.right
        anchors.rightMargin: 40 * racine.echelle
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 30 * racine.echelle
        spacing: 14 * racine.echelle

        Repeater {
            model: [
                { libelle: "Veille",     action: "veille",    dispo: sddm.canSuspend },
                { libelle: "Redémarrer", action: "redemarrer", dispo: sddm.canReboot },
                { libelle: "Éteindre",   action: "eteindre",  dispo: sddm.canPowerOff }
            ]
            delegate: Rectangle {
                required property var modelData
                visible: modelData.dispo
                width: etiquette.implicitWidth + 36 * racine.echelle
                height: 44 * racine.echelle
                radius: 12 * racine.echelle
                color: zone.containsMouse ? "#cc3a2645" : "#aa2a1d33"
                border.color: zone.containsMouse ? racine.accent : "#4a3a50"
                Text {
                    id: etiquette
                    anchors.centerIn: parent
                    text: modelData.libelle
                    color: racine.texte
                    font.pixelSize: 16 * racine.echelle
                }
                MouseArea {
                    id: zone
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        if (modelData.action === "veille") sddm.suspend()
                        else if (modelData.action === "redemarrer") sddm.reboot()
                        else sddm.powerOff()
                    }
                }
            }
        }
    }
}
