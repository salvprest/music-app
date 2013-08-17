# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
# Copyright 2013 Canonical
#
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License version 3, as published
# by the Free Software Foundation.

"""Music app autopilot tests."""

from __future__ import absolute_import

import tempfile

import mock
import os
import os.path
import shutil

from autopilot.matchers import Eventually
from testtools.matchers import Equals
from testtools.matchers import Contains

from music_app.tests import MusicTestCase


class TestMainWindow(MusicTestCase):

    def setUp(self):
        self._patch_home()
        self._create_music_library()
        super(TestMainWindow, self).setUp()
        self.assertThat(
            self.main_window.get_qml_view().visible, Eventually(Equals(True)))

    def tearDown(self):
        super(TestMainWindow, self).tearDown()

    def _patch_home(self):
        temp_dir = tempfile.mkdtemp()
        #print('patched home: ' + temp_dir)
        self.addCleanup(shutil.rmtree, temp_dir)
        patcher = mock.patch.dict('os.environ', {'HOME': temp_dir})
        patcher.start()
        self.addCleanup(patcher.stop)
        
    def _create_music_library(self):
        home = os.environ['HOME']
        musicpath = home + '/Music'
        os.mkdir(musicpath)
        
        # this needs the package 'example-content' installed:
        shutil.copy('/usr/share/example-content/'
            +'Ubuntu_Free_Culture_Showcase/Josh Woodward - Swansong.ogg', 
            musicpath)
        
        shutil.copy('/usr/share/music-app/tests/autopilot/music_app/content/'
            +'Benjamin_Kerensa_-_Foss_Yeaaaah___Radio_Edit_.mp3',
            musicpath)
        
    def test_reads_music_from_home(self):
        """ tests if the music library is populated from our fake home
	directory

	"""

        main = self.app.select_single("MainView", objectName = "music")
        title = lambda: main.currentTracktitle
        artist = lambda: main.currentArtist
        self.assertThat(title, Eventually(Equals("Foss Yeaaaah! (Radio Edit)")))
        self.assertThat(artist, Eventually(Equals("Benjamin Kerensa")))

    def test_play(self):
        """ Test Playing a track (Music Library must exist) """

        button = self.app.select_single("UbuntuShape", objectName = "playshape")
        main = self.app.select_single("MainView", objectName = "music")

        """ Track is not playing"""
        self.assertThat(main.isPlaying, Equals(False))
        self.pointing_device.click_object(button)

        """ Track is playing"""
        self.assertThat(main.isPlaying, Eventually(Equals(True)))

    def test_pause(self):
        """ Test Pausing a track (Music Library must exist) """

        button = self.app.select_single("UbuntuShape", objectName = "playshape")
        main = self.app.select_single("MainView", objectName = "music")

        """ Track is not playing"""
        self.assertThat(main.isPlaying, Equals(False))
        self.pointing_device.click_object(button)

        """ Track is playing"""
        self.assertThat(main.isPlaying, Eventually(Equals(True)))
        self.pointing_device.click_object(button)

        """ Track is not playing"""
        self.assertThat(main.isPlaying, Eventually(Equals(False)))

    def test_next(self):
        """ Test going to next track (Music Library must exist) """

        button = self.app.select_single("UbuntuShape",
			                objectName = "forwardshape")
        main = self.app.select_single("MainView", objectName = "music")
        title = lambda: main.currentTracktitle
        artist = lambda: main.currentArtist
        self.assertThat(title, Eventually(Equals("Foss Yeaaaah! (Radio Edit)")))
        self.assertThat(artist, Eventually(Equals("Benjamin Kerensa")))

        """ Track is not playing"""
        self.assertThat(main.isPlaying, Equals(False))
        self.pointing_device.click_object(button)

        """ Track is playing"""
        self.assertThat(main.isPlaying, Eventually(Equals(True)))
        self.assertThat(title, Eventually(Equals("Swansong")))
        self.assertThat(artist, Eventually(Equals("Josh Woodward")))


