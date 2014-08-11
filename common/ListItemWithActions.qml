/*
 * Copyright (C) 2012-2014 Canonical, Ltd.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.2
import Ubuntu.Components 1.1
import Ubuntu.Components.ListItems 0.1 as ListItem


ListItem.Standard {  // CUSTOM
//Item {
    id: root

    property Action leftSideAction: null
    property list<Action> rightSideActions
    property double defaultHeight: units.gu(8)
    property bool locked: false
    property Action activeAction: null
    property var activeItem: null
    property bool triggerActionOnMouseRelease: false
    property alias color: main.color
    default property alias contents: main.children

    property bool reorderable: false  // CUSTOM
    property bool reordering: false  // CUSTOM

    readonly property double actionWidth: units.gu(5)
    readonly property double leftActionWidth: units.gu(10)
    readonly property double actionThreshold: actionWidth * 0.4
    readonly property double threshold: 0.4
    readonly property string swipeState: main.x == 0 ? "Normal" : main.x > 0 ? "LeftToRight" : "RightToLeft"
    readonly property alias swipping: mainItemMoving.running

    signal itemClicked(var mouse)
    signal itemPressAndHold(var mouse)

    signal reorder(int from, int to)  // CUSTOM

    onItemPressAndHold: reordering = reorderable && !reordering  // CUSTOM
    onReorderingChanged: {  // CUSTOM
        if (reordering) {
            resetSwipe()
        }

        for (var j=0; j < main.children.length; j++) {
            main.children[j].anchors.rightMargin = reordering ? actionReorder.width + units.gu(2) : 0
        }

        parent.state = reordering ? "reorder" : "normal"
    }

    function returnToBoundsRTL()
    {
        var actionFullWidth = actionWidth + units.gu(2)
        var xOffset = Math.abs(main.x)
        var index = Math.min(Math.floor(xOffset / actionFullWidth), rightSideActions.length)
        var j;  // CUSTOM

        if (index < 1) {
            main.x = 0

            resetPrimed()  // CUSTOM
        } else if (index === rightSideActions.length) {
            main.x = -rightActionsView.width

            for (j=0; j < rightSideActions.length; j++) {  // CUSTOM
                rightActionsRepeater.itemAt(j).primed = true
            }
        } else {
            main.x = -(actionFullWidth * index)

            for (j=0; j < rightSideActions.length; j++) {  // CUSTOM
                rightActionsRepeater.itemAt(j).primed = j === index
            }
        }
    }

    function returnToBoundsLTR()
    {
        var finalX = leftActionWidth
        if (main.x > (finalX * root.threshold))
            main.x = finalX
        else {
            main.x = 0

            resetPrimed()  // CUSTOM
        }

        if (leftSideAction !== null) {  // CUSTOM
            leftActionIcon.primed = main.x > (finalX * root.threshold)
        }
    }

    function returnToBounds()
    {
        if (main.x < 0) {
            returnToBoundsRTL()
        } else if (main.x > 0) {
            returnToBoundsLTR()
        } else {  // CUSTOM
            resetPrimed()  // CUSTOM
        }
    }

    function contains(item, point)
    {
        return (point.x >= item.x) && (point.x <= (item.x + item.width)) && (point.y >= item.y) && (point.y <= (item.y + item.height));
    }

    function getActionAt(point)
    {
        if (contains(leftActionView, point)) {
            return leftSideAction
        } else if (contains(rightActionsView, point)) {
            var newPoint = root.mapToItem(rightActionsView, point.x, point.y)
            for (var i = 0; i < rightActionsRepeater.count; i++) {
                var child = rightActionsRepeater.itemAt(i)
                if (contains(child, newPoint)) {
                    return i
                }
            }
        }
        return -1
    }

    function updateActiveAction()
    {
        if ((main.x <= -root.actionWidth) &&
            (main.x > -rightActionsView.width)) {
            var actionFullWidth = actionWidth + units.gu(2)
            var xOffset = Math.abs(main.x)
            var index = Math.min(Math.floor(xOffset / actionFullWidth), rightSideActions.length)
            index = index - 1
            if (index > -1) {
                root.activeItem = rightActionsRepeater.itemAt(index)
                root.activeAction = root.rightSideActions[index]
            }
        } else {
            root.activeAction = null
        }
    }

    function resetPrimed()  // CUSTOM
    {
        if (leftSideAction !== null) {
            leftActionIcon.primed = false
        }

        for (var j=0; j < rightSideActions.length; j++) {
            rightActionsRepeater.itemAt(j).primed = false
        }
    }

    function resetSwipe()
    {
        main.x = 0

        resetPrimed()  // CUSTOM
    }

    Connections {  // CUSTOM
        target: mainView
        onListItemSwiping: {
            if (i !== index) {
                root.resetSwipe();
            }
        }
    }

    Connections {  // CUSTOM
        target: root.parent
        onStateChanged: reordering = root.parent.state === "reorder"
        onVisibleChanged: {
            if (!visible) {
                reordering = false
            }
        }
    }

    Component.onCompleted: reordering = root.parent.state === "reorder"  // CUSTOM

    /* CUSTOM Dim Component */
    Rectangle {
        id: listItemDim
        anchors {
            fill: parent
        }

        color: mouseArea.pressed ? styleMusic.common.black : "transparent"
        opacity: 0.1

        property bool dim: false

        Behavior on color {
            ColorAnimation {
                duration: UbuntuAnimation.SlowDuration
            }
        }
    }

    // CUSTOM remove animation
    SequentialAnimation {
        id: removeAnimation

        property var action

        UbuntuNumberAnimation {
            target: root
            duration: UbuntuAnimation.BriskDuration
            property: "height";
            to: 0
        }
        ScriptAction {
            script: removeAnimation.action.trigger()
        }
    }

    height: defaultHeight
    clip: height !== defaultHeight

    Rectangle {
        id: leftActionView

        anchors {
            top: parent.top
            bottom: parent.bottom
            right: main.left
        }
        width: root.leftActionWidth + actionThreshold
        visible: leftSideAction
        color: "red"

        Icon {
            id: leftActionIcon
            anchors {
                centerIn: parent
                horizontalCenterOffset: actionThreshold / 2
            }
            objectName: "swipeDeleteAction"  // CUSTOM
            name: leftSideAction ? leftSideAction.iconName : ""
            color: Theme.palette.selected.field
            height: units.gu(3)
            width: units.gu(3)

            property bool primed: false  // CUSTOM
        }
    }

    Item {
       id: rightActionsView

       anchors {
           top: main.top
           left: main.right
           leftMargin: reordering ? actionReorder.width : units.gu(1)  // CUSTOM
           bottom: main.bottom
       }
       visible: rightSideActions.length > 0
       width: rightActionsRepeater.count > 0 ? rightActionsRepeater.count * (root.actionWidth + units.gu(2)) + actionThreshold : 0

       Rectangle {  // CUSTOM
           anchors {
               bottom: parent.bottom
               left: parent.left
               top: parent.top
           }
           color: styleMusic.common.black
           opacity: 0.7
           width: parent.width + actionThreshold
       }

       Row {
           anchors {
               fill: parent
               leftMargin: units.gu(2)  // CUSTOM
           }
           spacing: units.gu(2)
           Repeater {
               id: rightActionsRepeater

               model: rightSideActions
               Item {
                   property alias image: img

                   anchors {
                       top: parent.top
                       bottom: parent.bottom
                   }
                   width: root.actionWidth

                   property alias primed: img.primed  // CUSTOM

                   Icon {
                       id: img

                       anchors.centerIn: parent
                       objectName: rightSideActions[index].objectName  // CUSTOM
                       width: units.gu(3)
                       height: units.gu(3)
                       name: iconName
                       color: root.activeAction === modelData || !root.triggerActionOnMouseRelease ? UbuntuColors.orange : styleMusic.common.white  // CUSTOM

                       property bool primed: false  // CUSTOM
                   }
               }
           }
       }
    }

    Rectangle {
        id: main
        objectName: "mainItem"

        anchors {
            top: parent.top
            bottom: parent.bottom
        }

        width: parent.width

        Behavior on x {
            UbuntuNumberAnimation {
                id: mainItemMoving

                easing.type: Easing.OutElastic
                duration: UbuntuAnimation.SlowDuration
            }
        }
    }

    /* CUSTOM Reorder Component */
    Rectangle {
        id: actionReorder
        anchors {
            bottom: parent.bottom
            right: main.right
            rightMargin: units.gu(1)
            top: parent.top
        }
        color: "transparent"
        width: units.gu(4)
        visible: reordering

        Icon {
            anchors {
                horizontalCenter: parent.horizontalCenter
                verticalCenter: parent.verticalCenter
            }
            name: "navigation-menu"  // TODO: use proper image
            height: width
            width: units.gu(3)
        }

        MouseArea {
            id: actionReorderMouseArea
            anchors {
                fill: parent
            }
            property int startY: 0
            property int startContentY: 0

            onPressed: {
                root.parent.parent.interactive = false;  // stop scrolling of listview
                startY = root.y;
                startContentY = root.parent.parent.contentY;
                root.z += 10;  // force ontop of other elements

                console.debug("Reorder listitem pressed", root.y)
            }
            onMouseYChanged: root.y += mouse.y - (root.height / 2);
            onReleased: {
                console.debug("Reorder diff by position", getDiff());

                var diff = getDiff();

                // Remove the height of the actual item if moved down
                if (diff > 0) {
                    diff -= 1;
                }

                root.parent.parent.interactive = true;  // reenable scrolling

                if (diff === 0) {
                    // Nothing has changed so reset the item
                    // z index is restored after animation
                    resetListItemYAnimation.start();
                }
                else {
                    var newIndex = index + diff;

                    if (newIndex < 0) {
                        newIndex = 0;
                    }
                    else if (newIndex > root.parent.parent.count - 1) {
                        newIndex = root.parent.parent.count - 1;
                    }

                    root.z -= 10;  // restore z index
                    reorder(index, newIndex)
                }
            }

            function getDiff() {
                // Get the amount of items that have been passed over (by centre)
                return Math.round((((root.y - startY) + (root.parent.parent.contentY - startContentY)) / root.height) + 0.5);
            }
        }

        SequentialAnimation {
            id: resetListItemYAnimation
            UbuntuNumberAnimation {
                target: root;
                property: "y";
                to: actionReorderMouseArea.startY
            }
            ScriptAction {
                script: {
                    root.z -= 10;  // restore z index
                }
            }
        }
    }

    SequentialAnimation {
        id: triggerAction

        property var currentItem: root.activeItem ? root.activeItem.image : null

        running: false
        ParallelAnimation {
            UbuntuNumberAnimation {
                target: triggerAction.currentItem
                property: "opacity"
                from: 1.0
                to: 0.0
                duration: UbuntuAnimation.SlowDuration
                easing {type: Easing.InOutBack; }
            }
            UbuntuNumberAnimation {
                target: triggerAction.currentItem
                properties: "width, height"
                from: units.gu(3)
                to: root.actionWidth
                duration: UbuntuAnimation.SlowDuration
                easing {type: Easing.InOutBack; }
            }
        }
        PropertyAction {
            target: triggerAction.currentItem
            properties: "width, height"
            value: units.gu(3)
        }
        PropertyAction {
            target: triggerAction.currentItem
            properties: "opacity"
            value: 1.0
        }
        ScriptAction {
            script: root.activeAction.triggered(root)
        }
        PauseAnimation {
            duration: 500
        }
        UbuntuNumberAnimation {
            target: main
            property: "x"
            to: 0
        }
        ScriptAction {
            script: resetPrimed()
        }
    }

    MouseArea {
        id: mouseArea

        property bool locked: root.locked || ((root.leftSideAction === null) && (root.rightSideActions.count === 0)) || reordering  // CUSTOM
        property bool manual: false

        anchors.fill: parent
        drag {
            target: locked ? null : main
            axis: Drag.XAxis
            minimumX: rightActionsView.visible ? -(rightActionsView.width + root.actionThreshold) : 0
            maximumX: leftActionView.visible ? leftActionView.width : 0
        }

        onReleased: {
            if (root.triggerActionOnMouseRelease && root.activeAction) {
                triggerAction.start()
            } else {
                root.returnToBounds()
                root.activeAction = null
            }
        }
        onClicked: {
            if (reordering) {  // CUSTOM
                reordering = false
            }
            else if (main.x === 0) {
                root.itemClicked(mouse)
            } else if (main.x > 0) {
                var action = getActionAt(Qt.point(mouse.x, mouse.y))
                if (action && action !== -1) {
                    //action.triggered(root)
                    removeAnimation.action = action  // CUSTOM
                    removeAnimation.start()  // CUSTOM
                }
            } else {
                var actionIndex = getActionAt(Qt.point(mouse.x, mouse.y))
                if (actionIndex !== -1) {
                    root.activeItem = rightActionsRepeater.itemAt(actionIndex)
                    root.activeAction = root.rightSideActions[actionIndex]
                    triggerAction.start()
                    return
                }
            }
            root.resetSwipe()
        }

        onPositionChanged: {
            if (mouseArea.pressed) {
                updateActiveAction()

                listItemSwiping(index)  // CUSTOM
            }
        }
        onPressAndHold: {
            if (main.x === 0) {
                root.itemPressAndHold(mouse)
            }
        }
        z: -1
    }
}