/*
 * Copyright (C) 2013, 2014
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
import "common"


MusicPage {
    id: mainpage
    objectName: "genresPage"
    title: i18n.tr("Genres")

    CardView {
        id: genreCardView
        itemWidth: units.gu(12)
        model: SortFilterModel {
            id: genresModelFilter
            model: GenresModel {
                id: genresModel
                store: musicStore
            }
            filter.property: "genre"
            filter.pattern: /\S+/
        }

        delegate: Card {
            id: genreCard
            coverSources: []
            objectName: "genresPageGridItem" + index
            primaryText: model.genre
            secondaryTextVisible: false

            property string album: ""

            AlbumsModel {
                id: albumGenreModel
                genre: model.genre
                store: musicStore
            }

            Repeater {
                id: albumGenreModelRepeater
                model: AlbumsModel {
                    genre: model.genre
                    store: musicStore
                }

                delegate: Item {
                    property string art: model.art
                }
                property var covers: []
                signal finished()

                onFinished: {
                    genreCard.coverSources = covers
                }
                onItemAdded: {
                    covers.push({art: item.art});

                    if (index === count - 1) {
                        finished();
                    }
                }
            }

            onClicked: {
                songsPage.covers = genreCard.coverSources
                songsPage.album = undefined
                songsPage.isAlbum = true
                songsPage.genre = model.genre;
                songsPage.title = i18n.tr("Genre")
                songsPage.line2 = model.genre
                songsPage.line1 = i18n.tr("Genre")


                mainPageStack.push(songsPage)
            }
        }
    }
}
