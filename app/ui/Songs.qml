/*
 * Copyright (C) 2013, 2014, 2015
 *      Andrew Hayzen <ahayzen@gmail.com>
 *      Daniel Holm <d.holmen@gmail.com>
 *      Victor Thompson <victor.thompson@gmail.com>
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

import QtQuick 2.3
import Ubuntu.Components 1.1
import Ubuntu.MediaScanner 0.1
import Ubuntu.Thumbnailer 0.1
import QtMultimedia 5.0
import QtQuick.LocalStorage 2.0
import "../logic/playlists.js" as Playlists
import "../components"
import "../components/ListItemActions"


MusicPage {
    id: songsPage
    objectName: "songsPage"
    title: i18n.tr("Songs")
    searchable: true
    searchResultsCount: songsModelFilter.count
    state: "default"
    states: [
        PageHeadState {
            name: "default"
            head: songsPage.head
            actions: Action {
                iconName: "search"
                onTriggered: songsPage.state = "search"
            }
        },
        PageHeadState {
            id: selectionState
            name: "selection"
            backAction: Action {
                text: i18n.tr("Cancel selection")
                iconName: "back"
                onTriggered: {
                    tracklist.clearSelection()
                    tracklist.state = "normal"
                }
            }
            head: songsPage.head
            actions: [
                Action {
                    iconName: "select"
                    text: i18n.tr("Select All")
                    onTriggered: {
                        if (tracklist.selectedItems.length === tracklist.model.count) {
                            tracklist.clearSelection()
                        } else {
                            tracklist.selectAll()
                        }
                    }
                },
                Action {
                    enabled: tracklist.selectedItems.length !== 0
                    iconName: "add-to-playlist"
                    text: i18n.tr("Add to playlist")
                    onTriggered: {
                        var items = []

                        for (var i=0; i < tracklist.selectedItems.length; i++) {
                            items.push(makeDict(tracklist.model.get(tracklist.selectedItems[i], tracklist.model.RoleModelData)));
                        }

                        mainPageStack.push(Qt.resolvedUrl("AddToPlaylist.qml"),
                                           {"chosenElements": items})

                        tracklist.closeSelection()
                    }
                },
                Action {
                    enabled: tracklist.selectedItems.length > 0
                    iconName: "add"
                    text: i18n.tr("Add to queue")
                    onTriggered: {
                        var items = []

                        for (var i=0; i < tracklist.selectedItems.length; i++) {
                            items.push(tracklist.model.get(tracklist.selectedItems[i], tracklist.model.RoleModelData));
                        }

                        trackQueue.appendList(items)

                        tracklist.closeSelection()
                    }
                }
            ]
        },
        SearchHeadState {
            id: searchHeader
            thisPage: songsPage
        }
    ]

    // Hack for autopilot otherwise Albums appears as MusicPage
    // due to bug 1341671 it is required that there is a property so that
    // qml doesn't optimise using the parent type
    property bool bug1341671workaround: true

    ListView {
        id: tracklist
        anchors {
            bottomMargin: units.gu(2)
            fill: parent
            topMargin: units.gu(2)
        }
        highlightFollowsCurrentItem: false
        objectName: "trackstab-listview"
        model: SortFilterModel {
            id: songsModelFilter
            property alias rowCount: songsModel.rowCount
            model: SongsModel {
                id: songsModel
                store: musicStore
            }
            sort.property: "title"
            sort.order: Qt.AscendingOrder
            sortCaseSensitivity: Qt.CaseInsensitive
            filter.property: "title"
            filter.pattern: new RegExp(searchHeader.query, "i")
            filterCaseSensitivity: Qt.CaseInsensitive
        }

        Component.onCompleted: {
            // FIXME: workaround for qtubuntu not returning values depending on the grid unit definition
            // for Flickable.maximumFlickVelocity and Flickable.flickDeceleration
            var scaleFactor = units.gridUnit / 8;
            maximumFlickVelocity = maximumFlickVelocity * scaleFactor;
            flickDeceleration = flickDeceleration * scaleFactor;
        }

        // Requirements for ListItemWithActions
        property var selectedItems: []

        signal clearSelection()
        signal closeSelection()
        signal selectAll()

        onClearSelection: selectedItems = []
        onCloseSelection: {
            clearSelection()
            state = "normal"
        }
        onStateChanged: {
            if (state === "multiselectable") {
                songsPage.state = "selection"
            } else {
                searchHeader.query = ""  // force query back to default
                songsPage.state = "default"
            }
        }

        onSelectAll: {
            var tmp = selectedItems

            for (var i=0; i < model.count; i++) {
                if (tmp.indexOf(i) === -1) {
                    tmp.push(i)
                }
            }

            selectedItems = tmp
        }
        onVisibleChanged: {
            if (!visible) {
                closeSelection()
            }
        }

        delegate: trackDelegate
        Component {
            id: trackDelegate

            ListItemWithActions {
                id: track
                objectName: "tracksPageListItem" + index
                height: units.gu(7)

                multiselectable: true
                rightSideActions: [
                    AddToQueue {
                    },
                    AddToPlaylist {

                    }
                ]

                onItemClicked: {
                    if (songsPage.state === "search") {  // only play single track when searching
                        trackQueue.clear()
                        trackQueue.append(songsModelFilter.get(index))
                        trackQueueClick(0)
                    } else {
                        trackClicked(songsModelFilter, index)  // play track
                    }
                }

                MusicRow {
                    id: musicRow
                    anchors {
                        verticalCenter: parent.verticalCenter
                    }
                    imageSource: {"art": model.art}
                    column: Column {
                        Label {
                            id: trackTitle
                            color: styleMusic.common.music
                            fontSize: "small"
                            objectName: "tracktitle"
                            text: model.title
                        }

                        Label {
                            id: trackArtist
                            color: styleMusic.common.subtitle
                            fontSize: "x-small"
                            text: model.author
                        }
                    }
                }

                states: State {
                    name: "Current"
                    when: track.ListView.isCurrentItem
                }
            }
        }
    }
}

