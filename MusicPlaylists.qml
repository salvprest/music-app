/*
 * Copyright (C) 2013, 2014
 *      Andrew Hayzen <ahayzen@gmail.com>
 *      Daniel Holm <d.holmen@gmail.com>
 *      Victor Thompson <victor.thompson@gmail.com>
 *
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
import Ubuntu.Components.ListItems 0.1
import Ubuntu.Components.Popups 0.1
import Ubuntu.Components.ListItems 0.1 as ListItem
import QtMultimedia 5.0
import QtQuick.LocalStorage 2.0
import "settings.js" as Settings
import "scrobble.js" as Scrobble
import "playlists.js" as Playlists
import "common"
import "common/ExpanderItems"

// page for the playlists
MusicPage {
    id: listspage
    // TRANSLATORS: this is the name of the playlists page shown in the tab header.
    // Remember to keep the translation short to fit the screen width
    title: i18n.tr("Playlists")

    property string playlistTracks: ""
    property string oldPlaylistName: ""
    property string oldPlaylistIndex: ""
    property string oldPlaylistID: ""
    property string inPlaylist: ""

    tools: ToolbarItems {
        ToolbarButton {
            action: Action {
                objectName: "newplaylistButton"
                text: i18n.tr("New playlist")
                iconSource: "images/add.svg"
                onTriggered: {
                    customdebug("New playlist.")
                    PopupUtils.open(newPlaylistDialog, mainView)
                }
            }
        }
    }

    // Edit name of playlist dialog
    Component {
        id: editPlaylistDialog
        Dialog {
            id: dialogueEditPlaylist
            // TRANSLATORS: this is a title of a dialog with a prompt to rename a playlist
            title: i18n.tr("Change name")
            text: i18n.tr("Enter the new name of the playlist.")
            TextField {
                id: playlistName
                placeholderText: oldPlaylistName
            }
            ListItem.Standard {
                id: editplaylistoutput
                visible: false
            }

            Button {
                text: i18n.tr("Change")
                onClicked: {
                    editplaylistoutput.visible = true
                    if (playlistName.text.length > 0) { // make sure something is acually inputed
                        var editList = Playlists.namechangePlaylist(oldPlaylistName,playlistName.text) // change the name of the playlist in DB
                        console.debug("Debug: User changed name from "+oldPlaylistName+" to "+playlistName.text)
                        playlistModel.model.set(oldPlaylistIndex, {"name": playlistName.text})
                        PopupUtils.close(dialogueEditPlaylist)
                        if (inPlaylist) {
                            playlistInfoLabel.text = playlistName.text
                        }
                    }
                    else {
                        editplaylistoutput.text = i18n.tr("You didn't type in a name.")
                    }
                }
            }
            Button {
                text: i18n.tr("Cancel")
                color: styleMusic.dialog.buttonColor
                onClicked: PopupUtils.close(dialogueEditPlaylist)
            }
        }
    }

    // Remove playlist dialog
    Component {
        id: removePlaylistDialog
        Dialog {
            id: dialogueRemovePlaylist
            // TRANSLATORS: this is a title of a dialog with a prompt to delete a playlist
            title: i18n.tr("Are you sure?")
            text: i18n.tr("This will delete your playlist.")

            Button {
                text: i18n.tr("Remove")
                onClicked: {
                    // removing playlist
                    Playlists.removePlaylist(oldPlaylistID, oldPlaylistName) // remove using both ID and name, if playlists has similair names
                    playlistModel.model.remove(oldPlaylistIndex)
                    PopupUtils.close(dialogueRemovePlaylist)
                }
            }
            Button {
                text: i18n.tr("Cancel")
                color: styleMusic.dialog.buttonColor
                onClicked: PopupUtils.close(dialogueRemovePlaylist)
            }
        }
    }

    MusicSettings {
        id: musicSettings
    }

    ListView {
        id: playlistslist
        objectName: "playlistslist"
        anchors.fill: parent
        anchors.bottomMargin: musicToolbar.mouseAreaOffset + musicToolbar.minimizedHeight
        model: playlistModel.model
        delegate: playlistDelegate
        onCountChanged: {
            customdebug("onCountChanged: " + playlistslist.count)
        }
        onCurrentIndexChanged: {
            customdebug("tracklist.currentIndex = " + playlistslist.currentIndex)
        }

        Component {
            id: playlistDelegate
            ListItem.Standard {
                id: playlist
                property string name: model.name
                property string count: model.count
                property var covers: Playlists.getPlaylistCovers(name)
                height: styleMusic.common.itemHeight
                iconFrame: false

                MusicRow {
                    covers: playlist.covers
                    column: Column {
                        spacing: units.gu(1)
                        Label {
                            id: playlistCount
                            color: styleMusic.common.subtitle
                            elide: Text.ElideRight
                            fontSize: "x-small"
                            height: units.gu(2)
                            maximumLineCount: 1
                            text: i18n.tr("%1 song", "%1 songs", playlist.count).arg(playlist.count)
                            wrapMode: Text.NoWrap
                            verticalAlignment: Text.AlignVCenter
                        }
                        Label {
                            id: playlistName
                            color: styleMusic.common.music
                            elide: Text.ElideRight
                            fontSize: "medium"
                            height: units.gu(2)
                            maximumLineCount: 1
                            text: playlist.name
                            wrapMode: Text.NoWrap
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                }

                Expander {
                    id: expandable
                    anchors {
                        fill: parent
                    }
                    listItem: playlist
                    model: {"name": name, "id": id, "index": index}
                    row: Row {
                        EditPlaylist {

                        }
                        DeletePlaylist {

                        }
                    }
                }

                onClicked: {
                    albumTracksModel.filterPlaylistTracks(name)
                    songsPage.isAlbum = false
                    songsPage.line1 = "Playlist"
                    songsPage.line2 = model.name
                    songsPage.covers =  playlist.covers
                    songsPage.title = i18n.tr("Playlist")

                    mainPageStack.push(songsPage)
                }
            }
        }
    }
}
