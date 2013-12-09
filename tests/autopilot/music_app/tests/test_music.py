# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
# Copyright 2013 Canonical
#
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License version 3, as published
# by the Free Software Foundation.

"""Music app autopilot tests."""

from __future__ import absolute_import

from autopilot.matchers import Eventually
from testtools.matchers import Equals, Is, Not, LessThan, NotEquals

from music_app.tests import MusicTestCase


class TestMainWindow(MusicTestCase):

    def setUp(self):
        super(TestMainWindow, self).setUp()
        self.assertThat(
            self.main_view.visible, Eventually(Equals(True)))
        #wait for activity indicator to stop spinning
        spinner = lambda: self.main_view.get_spinner().running
        self.assertThat(spinner, Eventually(Equals(False)))

    def test_reads_music_library(self):
        """ tests if the music library is populated from our
        fake mediascanner database"""

        # populate queue
        first_genre_item = self.main_view.get_first_genre_item()
        self.pointing_device.click_object(first_genre_item)

        title = lambda: self.main_view.currentTracktitle
        artist = lambda: self.main_view.currentArtist
        self.assertThat(title,
                        Eventually(Equals("Foss Yeaaaah! (Radio Edit)")))
        self.assertThat(artist, Eventually(Equals("Benjamin Kerensa")))

    def test_play_pause_library(self):
        """ Test playing and pausing a track (Music Library must exist) """

        # populate queue
        first_genre_item = self.main_view.get_first_genre_item()
        self.pointing_device.click_object(first_genre_item)

        # click back button
        back_button = self.main_view.get_back_button()
        self.pointing_device.click_object(back_button)

        self.main_view.show_toolbar()
        playbutton = self.main_view.get_play_button()

        """ Track is playing"""
        self.assertThat(self.main_view.isPlaying, Eventually(Equals(True)))
        self.pointing_device.click_object(playbutton)

        """ Track is not playing"""
        self.assertThat(self.main_view.isPlaying, Eventually(Equals(False)))

        """ Track is playing"""
        self.pointing_device.click_object(playbutton)
        self.assertThat(self.main_view.isPlaying, Eventually(Equals(True)))

    def test_play_pause_now_playing(self):
        """ Test playing and pausing a track (Music Library must exist) """

        # populate queue
        first_genre_item = self.main_view.get_first_genre_item()
        self.pointing_device.click_object(first_genre_item)

        playbutton = self.main_view.get_now_playing_play_button()

        """ Track is playing"""
        self.assertThat(self.main_view.isPlaying, Eventually(Equals(True)))
        self.pointing_device.click_object(playbutton)

        """ Track is not playing"""
        self.assertThat(self.main_view.isPlaying, Eventually(Equals(False)))

        """ Track is playing"""
        self.pointing_device.click_object(playbutton)
        self.assertThat(self.main_view.isPlaying, Eventually(Equals(True)))

    def test_next(self):
        """ Test going to next track (Music Library must exist) """

        # populate queue
        first_genre_item = self.main_view.get_first_genre_item()
        self.pointing_device.click_object(first_genre_item)

        forwardbutton = self.main_view.get_forward_button()

        title = lambda: self.main_view.currentTracktitle
        artist = lambda: self.main_view.currentArtist
        self.assertThat(title,
                        Eventually(Equals("Foss Yeaaaah! (Radio Edit)")))
        self.assertThat(artist, Eventually(Equals("Benjamin Kerensa")))

        """ Track is playing"""
        self.assertThat(self.main_view.isPlaying, Equals(True))
        self.pointing_device.click_object(forwardbutton)

        """ Track is playing"""
        self.assertThat(self.main_view.isPlaying, Eventually(Equals(True)))
        self.assertThat(title, Eventually(Equals("Swansong")))
        self.assertThat(artist, Eventually(Equals("Josh Woodward")))

    def test_previous_and_mp3(self):
        """ Test going to previous track, last item must be an MP3
            (Music Library must exist) """

        # populate queue
        first_genre_item = self.main_view.get_first_genre_item()
        self.pointing_device.click_object(first_genre_item)

        playbutton = self.main_view.get_now_playing_play_button()

        """ Pause track """
        self.pointing_device.click_object(playbutton)
        self.assertThat(self.main_view.isPlaying, Eventually(Equals(False)))

        """ Repeat is off """
        repeatbutton = self.main_view.get_repeat_button()
        self.pointing_device.click_object(repeatbutton)

        previousbutton = self.main_view.get_previous_button()

        title = lambda: self.main_view.currentTracktitle
        artist = lambda: self.main_view.currentArtist
        self.assertThat(title,
                        Eventually(Equals("Foss Yeaaaah! (Radio Edit)")))
        self.assertThat(artist, Eventually(Equals("Benjamin Kerensa")))

        """ Select previous """
        self.pointing_device.click_object(previousbutton)

        """ Track is playing """
        self.assertThat(self.main_view.isPlaying, Eventually(Equals(True)))
        self.assertThat(title, Eventually(Equals("TestMP3Title")))
        self.assertThat(artist, Eventually(Equals("TestMP3Artist")))

    def test_shuffle(self):
        """ Test shuffle (Music Library must exist) """

        # populate queue
        first_genre_item = self.main_view.get_first_genre_item()
        self.pointing_device.click_object(first_genre_item)

        shufflebutton = self.main_view.get_shuffle_button()

        forwardbutton = self.main_view.get_forward_button()

        previousbutton = self.main_view.get_previous_button()

        playbutton = self.main_view.get_now_playing_play_button()

        title = lambda: self.main_view.currentTracktitle
        artist = lambda: self.main_view.currentArtist
        self.assertThat(title,
                        Eventually(Equals("Foss Yeaaaah! (Radio Edit)")))
        self.assertThat(artist, Eventually(Equals("Benjamin Kerensa")))

        """ Track is playing, shuffle is turned on"""
        self.assertThat(self.main_view.isPlaying, Equals(True))
        self.pointing_device.click_object(shufflebutton)
        self.assertThat(self.main_view.random, Eventually(Equals(True)))

        forward = True
        count = 0
        while True:
            self.assertThat(count, LessThan(100))

            if (not self.main_view.toolbarShown):
                self.main_view.show_toolbar()

            if forward:
                self.pointing_device.click_object(forwardbutton)
            else:
                self.pointing_device.click_object(previousbutton)

            """ Track is playing"""
            self.assertThat(self.main_view.isPlaying,
                            Eventually(Equals(True)))
            if (self.main_view.currentTracktitle == "TestMP3Title" and
                    self.main_view.currentArtist == "TestMP3Artist"):
                break
            else:
                """ Show toolbar if hidden """
                if (not self.main_view.toolbarShown):
                    self.main_view.show_toolbar()

                """ Pause track """
                self.pointing_device.click_object(playbutton)
                self.assertThat(self.main_view.isPlaying,
                                Eventually(Equals(False)))
                forward = not forward
                count += 1

    def test_show_albums_sheet(self):
        """tests navigating to the Albums tab and displaying the album sheet"""

        artistName = "Benjamin Kerensa"

        # switch to albums tab
        self.main_view.switch_to_tab("albumstab")

        #select album
        albumartist = self.main_view.get_albums_albumartist(artistName)
        self.pointing_device.click_object(albumartist)

        #get album sheet album artist
        sheet_albumartist = self.main_view.get_album_sheet_artist()
        self.assertThat(sheet_albumartist.text, Eventually(Equals(artistName)))

        # click on close button to close album sheet
        closebutton = self.main_view.get_album_sheet_close_button()
        self.pointing_device.click_object(closebutton)
        self.assertThat(self.main_view.get_albumstab(), Not(Is(None)))

    def test_add_song_to_queue_from_albums_sheet(self):
        """tests navigating to the Albums tab and adding a song to queue"""

        trackTitle = "Foss Yeaaaah! (Radio Edit)"
        artistName = "Benjamin Kerensa"

        # get number of tracks in queue before queuing a track
        initialtracksCount = self.main_view.get_queue_track_count()

        # switch to albums tab
        self.main_view.switch_to_tab("albumstab")

        #select album
        albumartist = self.main_view.get_albums_albumartist(artistName)
        self.pointing_device.click_object(albumartist)

        #get album sheet album artist
        sheet_albumartist = self.main_view.get_album_sheet_artist()
        self.assertThat(sheet_albumartist.text, Eventually(Equals(artistName)))

        #get track item to add to queue
        trackicon = self.main_view.get_album_sheet_listview_trackicon(
            trackTitle)
        self.pointing_device.click_object(trackicon)

        #click on Add to queue
        queueTrackImage = self.main_view.get_album_sheet_queuetrack_image()
        self.pointing_device.click_object(queueTrackImage)

        # verify track queue has added one to initial value
        endtracksCount = self.main_view.get_queue_track_count()
        self.assertThat(endtracksCount, Equals(initialtracksCount + 1))

        #Assert that the song added to the list is not playing
        self.assertThat(self.main_view.currentIndex,
                        Eventually(NotEquals(endtracksCount)))
        self.assertThat(self.main_view.isPlaying, Eventually(Equals(False)))

        #verify song's metadata matches the item added to the Now Playing view
        queueArtistName = self.main_view.get_queue_now_playing_artist(
            artistName)
        self.assertThat(str(queueArtistName.text), Equals(artistName))
        queueTrackTitle = self.main_view.get_queue_now_playing_title(
            trackTitle)
        self.assertThat(str(queueTrackTitle.text), Equals(trackTitle))

        # click on close button to close album sheet
        closebutton = self.main_view.get_album_sheet_close_button()
        self.pointing_device.click_object(closebutton)
        self.assertThat(self.main_view.get_albumstab(), Not(Is(None)))

    def test_add_songs_to_queue_from_songs_tab_and_play(self):
        """tests navigating to the Songs tab and adding the library to the
           queue with the selected item being played. """

        trackTitle = "Foss Yeaaaah! (Radio Edit)"
        artistName = "Benjamin Kerensa"

        # get number of tracks in queue before queuing a track
        initialtracksCount = self.main_view.get_queue_track_count()

        # switch to songs tab
        self.main_view.switch_to_tab("trackstab")

        # get track item to add to queue
        trackitem = self.main_view.get_songs_tab_tracktitle(trackTitle)
        self.pointing_device.click_object(trackitem)

        # verify track queue has added all songs to initial value
        endtracksCount = self.main_view.get_queue_track_count()
        self.assertThat(endtracksCount, Equals(initialtracksCount + 3))

        # Assert that the song added to the list is playing
        self.assertThat(self.main_view.currentIndex,
                        Eventually(NotEquals(endtracksCount)))
        self.assertThat(self.main_view.isPlaying, Eventually(Equals(True)))

        # verify song's metadata matches the item added to the Now Playing view
        queueArtistName = self.main_view.get_queue_now_playing_artist(
            artistName)
        self.assertThat(str(queueArtistName.text), Equals(artistName))
        queueTrackTitle = self.main_view.get_queue_now_playing_title(
            trackTitle)
        self.assertThat(str(queueTrackTitle.text), Equals(trackTitle))

    def test_add_song_to_queue_from_songs_tab(self):
        """tests navigating to the Songs tab and adding a song from the library
           to the queue via the expandable list view item. """

        trackTitle = "Foss Yeaaaah! (Radio Edit)"
        artistName = "Benjamin Kerensa"

        # get number of tracks in queue before queuing a track
        initialtracksCount = self.main_view.get_queue_track_count()

        # switch to songs tab
        self.main_view.switch_to_tab("trackstab")

        # get track item to add to queue
        trackitem = self.main_view.get_songs_tab_trackimage(trackTitle)
        self.pointing_device.click_object(trackitem)
        addtoqueueLabel = self.main_view.get_songs_tab_add_to_queue_label()
        self.pointing_device.click_object(addtoqueueLabel)

        # verify track queue has added all songs to initial value
        endtracksCount = self.main_view.get_queue_track_count()
        self.assertThat(endtracksCount, Equals(initialtracksCount + 1))

        # Assert that the song added to the list is not playing
        self.assertThat(self.main_view.currentIndex,
                        Eventually(NotEquals(endtracksCount)))
        self.assertThat(self.main_view.isPlaying, Eventually(Equals(False)))

        # verify song's metadata matches the item added to the Now Playing view
        queueArtistName = self.main_view.get_queue_now_playing_artist(
            artistName)
        self.assertThat(str(queueArtistName.text), Equals(artistName))
        queueTrackTitle = self.main_view.get_queue_now_playing_title(
            trackTitle)
        self.assertThat(str(queueTrackTitle.text), Equals(trackTitle))

    def test_create_playlist_from_songs_tab(self):
        """tests navigating to the Songs tab and creating a playlist by
           selecting a song to add it to a new playlist. """

        trackTitle = "Foss Yeaaaah! (Radio Edit)"

        # switch to songs tab
        self.main_view.switch_to_tab("trackstab")

        # get track item to add to queue
        trackitem = self.main_view.get_songs_tab_trackimage(trackTitle)
        self.pointing_device.click_object(trackitem)
        addtoplaylistLbl = self.main_view.get_songs_tab_add_to_playlist_label()
        self.pointing_device.click_object(addtoplaylistLbl)

        # get initial list view playlist count
        playlist_count = self.main_view.get_addtoplaylistview()[0].count

        # click on New playlist button
        newplaylistButton = self.main_view.get_newplaylistButton()[0]
        self.pointing_device.click_object(newplaylistButton)

        # input playlist name
        playlistNameFld = self.main_view.get_newPlaylistDialog_name_textfield()
        self.pointing_device.click_object(playlistNameFld)
        self.keyboard.type("MyPlaylist")

        # click on get_newPlaylistDialog create Button
        createButton = self.main_view.get_newPlaylistDialog_createButton()
        self.pointing_device.click_object(createButton)

        # verify playlist has been sucessfully created
        palylist_final_count = self.main_view.get_addtoplaylistview()[0].count
        self.assertThat(palylist_final_count, Equals(playlist_count + 1))
        playlist = self.main_view.get_playlistname("MyPlaylist")
        self.assertThat(playlist, Not(Is(None)))

        # select playlist to add song to
        self.pointing_device.click_object(playlist)

        # verify song has been added to playlist
        playlistslist = self.main_view.get_playlistslist()
        self.assertThat(playlistslist.count, Equals(1))
