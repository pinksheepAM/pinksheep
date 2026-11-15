/* PinkSheep : diaporama affiché pendant l'installation */
import QtQuick 2.15
import calamares.slideshow 1.0

Presentation {
    id: presentation

    function nextSlide() { presentation.goToNextSlide(); }

    Timer {
        interval: 9000
        running: presentation.activatedInCalamares
        repeat: true
        onTriggered: nextSlide()
    }

    Rectangle { anchors.fill: parent; color: "#1a1220"; z: -1 }

    Slide {
        Image {
            id: logo1
            source: "logo.png"
            width: 180; height: 180
            fillMode: Image.PreserveAspectFit
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top; anchors.topMargin: 40
        }
        Text {
            anchors.top: logo1.bottom; anchors.topMargin: 24
            width: parent.width; horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            color: "#f5e6ef"; font.pixelSize: 22
            text: "<b>Bienvenue sur PinkSheep</b><br/><br/>" +
                  "L'installation télécharge le système, les pilotes et les applis.<br/>" +
                  "Compte 10 à 30 minutes selon ta connexion."
        }
    }

    Slide {
        Image {
            id: apercu
            source: "diapo-themes.png"
            width: parent.width * 0.7; height: parent.height * 0.6
            fillMode: Image.PreserveAspectFit
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top; anchors.topMargin: 20
        }
        Text {
            anchors.top: apercu.bottom; anchors.topMargin: 16
            width: parent.width; horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            color: "#f5e6ef"; font.pixelSize: 20
            text: "<b>SUPER + W</b> : choisis un fond d'écran,<br/>tout le bureau prend ses couleurs."
        }
    }

    Slide {
        Text {
            anchors.centerIn: parent
            width: parent.width * 0.8; horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            color: "#f5e6ef"; font.pixelSize: 20
            text: "<b>Les raccourcis à retenir</b><br/><br/>" +
                  "<font color='#ff7eb6'>SUPER + H</font>  tous les raccourcis<br/>" +
                  "<font color='#ff7eb6'>SUPER + Espace</font>  lancer une appli<br/>" +
                  "<font color='#ff7eb6'>SUPER + Entrée</font>  terminal<br/>" +
                  "<font color='#ff7eb6'>SUPER + E</font>  fichiers<br/>" +
                  "<font color='#ff7eb6'>SUPER + Q</font>  fermer une fenêtre<br/>" +
                  "<font color='#ff7eb6'>SUPER + 1…0</font>  changer de bureau"
        }
    }

    Slide {
        Text {
            anchors.centerIn: parent
            width: parent.width * 0.8; horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            color: "#f5e6ef"; font.pixelSize: 20
            text: "<b>Dans le terminal</b><br/><br/>" +
                  "<font color='#ff7eb6'>y</font>  fichiers avec Yazi<br/>" +
                  "<font color='#ff7eb6'>maj</font>  mettre tout le système à jour<br/>" +
                  "<font color='#ff7eb6'>SUPER + SHIFT + M</font>  ta musique (rmpc)<br/>" +
                  "<font color='#ff7eb6'>SUPER + Y</font>  YouTube sans navigateur"
        }
    }
}
