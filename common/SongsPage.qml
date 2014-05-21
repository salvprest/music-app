/*
 * Copyright (C) 2014 Andrew Hayzen <ahayzen@gmail.com>
 *                    Daniel Holm <d.holmen@gmail.com>
 *                    Victor Thompson <victor.thompson@gmail.com>
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

import QtQuick 2.0
import Ubuntu.Components 0.1
import Ubuntu.Components.ListItems 0.1 as ListItem
import QtQuick.LocalStorage 2.0
import "../meta-database.js" as Library
import "ExpanderItems"

Page {
    id: songStackPage
    anchors.bottomMargin: units.gu(.5)
    tools: null
    visible: false

    property string line1: ""
    property string line2: ""
    property string songtitle: ""
    property var covers: []
    property string length: ""
    property string file: ""
    property string year: ""
    property bool isAlbum: false

    onVisibleChanged: {
        if (visible) {
            musicToolbar.setPage(songStackPage, null, mainPageStack)
        }
    }

    ListView {
        id: albumtrackslist
        anchors {
            bottomMargin: wideAspect ? musicToolbar.fullHeight : musicToolbar.mouseAreaOffset + musicToolbar.minimizedHeight
            fill: parent
        }
        clip: true
        delegate: albumTracksDelegate
        model: albumTracksModel.model
        width: parent.width
        header: ListItem.Standard {
            id: albumInfo
            width: parent.width
            height: units.gu(22)

            CoverRow {
                id: albumImage
                anchors {
                    top: parent.top
                    left: parent.left
                    margins: units.gu(1)
                }
                count: songStackPage.covers.length
                size: units.gu(20)
                covers: songStackPage.covers
                spacing: units.gu(2)
            }

            Label {
                id: albumArtist
                objectName: "songspage-albumartist"
                wrapMode: Text.NoWrap
                maximumLineCount: 1
                fontSize: "small"
                color: styleMusic.common.subtitle
                anchors.left: albumImage.right
                anchors.leftMargin: units.gu(1)
                anchors.top: parent.top
                anchors.topMargin: units.gu(1.5)
                anchors.right: parent.right
                anchors.rightMargin: units.gu(1.5)
                elide: Text.ElideRight
                text: line1
            }
            Label {
                id: albumLabel
                wrapMode: Text.NoWrap
                maximumLineCount: 2
                fontSize: "medium"
                color: styleMusic.common.music
                anchors.left: albumImage.right
                anchors.leftMargin: units.gu(1)
                anchors.top: albumArtist.bottom
                anchors.topMargin: units.gu(0.8)
                anchors.right: parent.right
                anchors.rightMargin: units.gu(1.5)
                elide: Text.ElideRight
                text: line2
            }
            Label {
                id: albumYear
                wrapMode: Text.NoWrap
                maximumLineCount: 1
                fontSize: "x-small"
                color: styleMusic.common.subtitle
                anchors.left: albumImage.right
                anchors.leftMargin: units.gu(1)
                anchors.top: albumLabel.bottom
                anchors.topMargin: units.gu(2)
                anchors.right: parent.right
                anchors.rightMargin: units.gu(1.5)
                elide: Text.ElideRight
                text: isAlbum ? i18n.tr(year + " | %1 song", year + " | %1 songs", albumTracksModel.model.count).arg(albumTracksModel.model.count)
                              : i18n.tr("%1 song", "%1 songs", albumTracksModel.model.count).arg(albumTracksModel.model.count)

            }

            // Play
            Rectangle {
                id: playRow
                anchors.top: albumYear.bottom
                anchors.topMargin: units.gu(1)
                anchors.left: albumImage.right
                anchors.leftMargin: units.gu(1)
                color: "transparent"
                height: units.gu(4)
                width: units.gu(15)
                Image {
                    id: playTrack
                    objectName: "songspage-playtrack"
                    anchors.verticalCenter: parent.verticalCenter
                    source: "../images/add-to-playback.png"
                    height: styleMusic.common.expandedItem
                    width: styleMusic.common.expandedItem
                }
                Label {
                    anchors.left: playTrack.right
                    anchors.leftMargin: units.gu(0.5)
                    anchors.verticalCenter: parent.verticalCenter
                    fontSize: "small"
                    color: styleMusic.common.subtitle
                    width: parent.width - playTrack.width - units.gu(1)
                    text: i18n.tr("Play all")
                    wrapMode: Text.WordWrap
                    maximumLineCount: 3
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        trackClicked(albumTracksModel, 0)  // play track
                        if (isAlbum) {
                            Library.addRecent(pageItem.line2, pageItem.line1, pageItem.cover, pageItem.line2, "album")
                            mainView.hasRecent = true
                            recentModel.filterRecent()
                        } else if (pageItem.line1 == "Playlist") {
                            Library.addRecent(pageItem.line2, "Playlist", pageItem.cover, pageItem.line2, "playlist")
                            mainView.hasRecent = true
                            recentModel.filterRecent()
                        }
                    }
                }
            }

            // Queue
            Rectangle {
                id: queueAllRow
                anchors.top: playRow.bottom
                anchors.topMargin: units.gu(1)
                anchors.left: albumImage.right
                anchors.leftMargin: units.gu(1)
                color: "transparent"
                height: units.gu(4)
                width: units.gu(15)
                Image {
                    id: queueAll
                    objectName: "songspage-queue-all"
                    anchors.verticalCenter: parent.verticalCenter
                    source: "../images/add.svg"
                    height: styleMusic.common.expandedItem
                    width: styleMusic.common.expandedItem
                }
                Label {
                    anchors.left: queueAll.right
                    anchors.leftMargin: units.gu(0.5)
                    anchors.verticalCenter: parent.verticalCenter
                    fontSize: "small"
                    color: styleMusic.common.subtitle
                    width: parent.width - queueAll.width - units.gu(1)
                    text: i18n.tr("Add to queue")
                    wrapMode: Text.WordWrap
                    maximumLineCount: 3
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        addQueueFromModel(albumTracksModel)
                    }
                }
            }
        }

        Component {
            id: albumTracksDelegate

            ListItem.Standard {
                id: track
                objectName: "songspage-track"
                iconFrame: false
                progression: false
                height: isAlbum ? styleMusic.albums.itemHeight : styleMusic.common.albumSize + units.gu(2)

                MouseArea {
                    anchors.fill: parent
                    onDoubleClicked: {
                    }
                    onClicked: {
                        if (focus == false) {
                            focus = true
                        }
                        trackClicked(albumTracksModel, index)  // play track
                        if (isAlbum) {
                            Library.addRecent(pageItem.line2, pageItem.line1, pageItem.cover, pageItem.line2, "album")
                            mainView.hasRecent = true
                            recentModel.filterRecent()
                        } else if (pageItem.line1 == "Playlist") {
                            Library.addRecent(pageItem.line2, "Playlist", pageItem.cover, pageItem.line2, "playlist")
                            mainView.hasRecent = true
                            recentModel.filterRecent()
                        }
                    }
                }

                Rectangle {
                    id: trackContainer;
                    anchors {
                        fill: parent
                        rightMargin: expandable.expanderButtonWidth
                    }
                    color: "transparent"

                    UbuntuShape {
                        id: trackCover
                        anchors {
                            left: parent.left
                            leftMargin: units.gu(2)
                            top: parent.top
                            topMargin: units.gu(1)
                        }
                        width: styleMusic.common.albumSize
                        height: styleMusic.common.albumSize
                        visible: !isAlbum
                        image: Image {
                            source: model.cover !== "" ? model.cover : Qt.resolvedUrl("../images/music-app-cover@30.png")
                            onStatusChanged: {
                                if (status === Image.Error) {
                                    source = Qt.resolvedUrl("../images/music-app-cover@30.png")
                                }
                            }
                        }
                    }

                    Label {
                        id: trackArtist
                        wrapMode: Text.NoWrap
                        maximumLineCount: 2
                        fontSize: "x-small"
                        color: styleMusic.common.subtitle
                        visible: !isAlbum
                        anchors {
                            left: trackCover.right
                            leftMargin: units.gu(2)
                            top: parent.top
                            topMargin: units.gu(1.5)
                            right: parent.right
                            rightMargin: units.gu(1.5)
                        }
                        elide: Text.ElideRight
                        text: model.artist
                    }

                    Label {
                        id: trackTitle
                        objectName: "songspage-tracktitle"
                        wrapMode: Text.NoWrap
                        maximumLineCount: 1
                        fontSize: "medium"
                        color: styleMusic.common.subtitle
                        anchors {
                            left: isAlbum ? parent.left : trackCover.right
                            leftMargin: units.gu(2)
                            top: isAlbum ? parent.top : trackArtist.bottom
                            topMargin: units.gu(1)
                            right: parent.right
                            rightMargin: units.gu(1.5)
                        }
                        elide: Text.ElideRight
                        text: model.title
                    }

                    Label {
                        id: trackAlbum
                        wrapMode: Text.NoWrap
                        maximumLineCount: 2
                        fontSize: "xx-small"
                        color: styleMusic.common.subtitle
                        visible: !isAlbum
                        anchors {
                            left: trackCover.right
                            leftMargin: units.gu(2)
                            top: trackTitle.bottom
                            topMargin: units.gu(2)
                            right: parent.right
                            rightMargin: units.gu(1.5)
                        }
                        elide: Text.ElideRight
                        text: model.album
                    }
                }

                Expander {
                    id: expandable
                    anchors {
                        fill: parent
                    }
                    listItem: track
                    model: albumTracksModel.model.get(index)
                    row: Row {
                        AddToPlaylist {

                        }
                        AddToQueue {

                        }
                    }
                }

                Component.onCompleted: {
                    if (index === 0)
                    {
                        songStackPage.file = model.file;
                        songStackPage.year = model.year;
                    }
                }
            }
        }
    }
}
