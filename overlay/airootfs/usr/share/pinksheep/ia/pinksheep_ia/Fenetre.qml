import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    id: fenetre
    width: 620; height: 520
    visible: true
    title: "Assistant PinkSheep"
    color: couleurs.fond

    property bool occupe: false

    ListModel { id: fil }

    Connections {
        target: pont
        function onMessage(qui, texte) { fil.append({ qui: qui, texte: texte, ident: "", resume: "" }); vue.positionViewAtEnd() }
        function onProposition(ident, resume) { fil.append({ qui: "proposition", texte: "", ident: ident, resume: resume }); vue.positionViewAtEnd() }
        function onOccupe(o) { fenetre.occupe = o }
    }

    Component.onCompleted: fil.append({ qui: "ia", texte: accueil, ident: "", resume: "" })

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        // En-tête : mouton + titre
        RowLayout {
            spacing: 10
            Image { source: iconeMouton; sourceSize.width: 36; sourceSize.height: 36; Layout.preferredWidth: 36; Layout.preferredHeight: 36 }
            Label { text: "Assistant PinkSheep"; color: couleurs.primaire; font.pixelSize: 20; font.bold: true }
            Item { Layout.fillWidth: true }
            BusyIndicator { running: fenetre.occupe; visible: running; Layout.preferredWidth: 26; Layout.preferredHeight: 26 }
        }

        // Fil de la conversation
        ListView {
            id: vue
            Layout.fillWidth: true; Layout.fillHeight: true
            clip: true; spacing: 8
            model: fil
            delegate: Item {
                width: vue.width
                height: bulle.height
                Rectangle {
                    id: bulle
                    readonly property bool deMoi: model.qui === "moi"
                    anchors.right: deMoi ? parent.right : undefined
                    width: Math.min(contenu.implicitWidth + 24, vue.width * 0.85)
                    height: contenu.implicitHeight + 20
                    radius: 14
                    color: deMoi ? couleurs.primaire
                         : model.qui === "erreur" ? Qt.rgba(1, 0.42, 0.5, 0.18)
                         : couleurs.surface
                    border.width: model.qui === "proposition" ? 1 : 0
                    border.color: couleurs.secondaire

                    ColumnLayout {
                        id: contenu
                        x: 12; y: 10
                        width: Math.min(implicitWidth, vue.width * 0.85 - 24)
                        spacing: 8
                        Label {
                            visible: model.qui !== "proposition"
                            text: model.texte
                            wrapMode: Text.Wrap
                            Layout.maximumWidth: vue.width * 0.85 - 24
                            color: bulle.deMoi ? couleurs.sur_primaire : model.qui === "erreur" ? couleurs.erreur : couleurs.texte
                            font.pixelSize: 14
                        }
                        Label {
                            visible: model.qui === "proposition"
                            text: "Je propose : " + model.resume + " ?"
                            wrapMode: Text.Wrap
                            Layout.maximumWidth: vue.width * 0.85 - 24
                            color: couleurs.texte; font.pixelSize: 14
                        }
                        RowLayout {
                            visible: model.qui === "proposition"
                            spacing: 8
                            Button {
                                id: faire
                                text: "Faire"
                                onClicked: { pont.faire(model.ident); faire.enabled = false; annuler.enabled = false }
                                background: Rectangle { radius: 10; color: faire.enabled ? couleurs.primaire : couleurs.discret }
                                contentItem: Label { text: faire.text; color: couleurs.sur_primaire; horizontalAlignment: Text.AlignHCenter; font.bold: true }
                            }
                            Button {
                                id: annuler
                                text: "Annuler"
                                onClicked: { pont.annuler(model.ident); faire.enabled = false; annuler.enabled = false }
                                background: Rectangle { radius: 10; color: "transparent"; border.color: couleurs.discret }
                                contentItem: Label { text: annuler.text; color: couleurs.texte; horizontalAlignment: Text.AlignHCenter }
                            }
                        }
                    }
                }
            }
        }

        // Saisie
        Rectangle {
            Layout.fillWidth: true
            height: 46; radius: 23
            color: couleurs.surface
            border.color: saisie.activeFocus ? couleurs.primaire : "transparent"
            TextField {
                id: saisie
                anchors.fill: parent; anchors.leftMargin: 18; anchors.rightMargin: 18
                placeholderText: "Ex. : ouvre mon CV, mets le volume à 30…"
                placeholderTextColor: couleurs.discret
                color: couleurs.texte; font.pixelSize: 14
                background: null
                focus: true
                enabled: !fenetre.occupe
                onAccepted: { pont.envoyer(text); text = "" }
            }
        }
    }

    Shortcut { sequence: "Escape"; onActivated: Qt.quit() }
}
