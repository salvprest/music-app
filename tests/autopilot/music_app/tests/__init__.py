# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
# Copyright 2013 Canonical
#
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License version 3, as published
# by the Free Software Foundation.

"""Music app autopilot tests."""

import tempfile

try:
    from unittest import mock
except ImportError:
    import mock
import os
import os.path
import shutil
#import subprocess
import logging
import music_app

from autopilot.input import Mouse, Touch, Pointer
from autopilot.platform import model
from autopilot.testcase import AutopilotTestCase

from music_app import emulators

from ubuntuuitoolkit import (
    base,
    emulators as toolkit_emulators
)


logger = logging.getLogger(__name__)


class MusicTestCase(AutopilotTestCase):

    """A common test case class that provides several useful methods for
    music-app tests.

    """
    if model() == 'Desktop':
        scenarios = [('with mouse', dict(input_device_class=Mouse))]
    else:
        scenarios = [('with touch', dict(input_device_class=Touch))]

    working_dir = os.getcwd()
    local_location_dir = os.path.dirname(os.path.dirname(working_dir))
    local_location = local_location_dir + "/music-app.qml"
    installed_location = "/usr/share/music-app/music-app.qml"
    sqlite_dir = os.path.expanduser(
        "~/.local/share/com.ubuntu.music/Databases")
    backup_dir = sqlite_dir + ".backup"

    def setup_environment(self):
        if os.path.exists(self.local_location):
            launch = self.launch_test_local
            test_type = 'local'
        elif os.path.exists(self.installed_location):
            launch = self.launch_test_installed
            test_type = 'deb'
        else:
            launch = self.launch_test_click
            test_type = 'click'
        return launch, test_type

    def setUp(self):
        #backup and wipe db's before testing
        self.temp_move_sqlite_db()
        self.addCleanup(self.restore_sqlite_db)

        launch, self.test_type = self.setup_environment()
        if self.test_type != 'click':
            self.home_dir = self._patch_home()
        else:
            self.home_dir = self._save_home()
        self._create_music_library()
        self.pointing_device = Pointer(self.input_device_class.create())
        super(MusicTestCase, self).setUp()
        launch()

    def launch_test_local(self):
        logger.debug("Running via local installation")
        self.app = self.launch_test_application(
            base.get_qmlscene_launch_command(),
            self.local_location,
            app_type='qt',
            emulator_base=toolkit_emulators.UbuntuUIToolkitEmulatorBase)

    def launch_test_installed(self):
        logger.debug("Running via installed debian package")
        self.app = self.launch_test_application(
            base.get_qmlscene_launch_command(),
            self.installed_location,
            app_type='qt',
            emulator_base=toolkit_emulators.UbuntuUIToolkitEmulatorBase)

    def launch_test_click(self):
        logger.debug("Running via click package")
        self.app = self.launch_click_package(
            "com.ubuntu.music",
            emulator_base=toolkit_emulators.UbuntuUIToolkitEmulatorBase)

    def _save_home(self):
        logger.debug('Saving HOME')
        home_dir = os.environ['HOME']
        backup_list = ('Music', )  # '.cache/mediascanner')
        backup_path = [os.path.join(home_dir, i) for i in backup_list]
        backups = [(i, '%s.bak' % i) for i in backup_path if os.path.exists(i)]
        for b in backups:
            logger.debug('backing up %s to %s' % b)
            try:
                shutil.rmtree(b[1])
            except:
                pass
            shutil.move(b[0], b[1])
            #self.addCleanup(shutil.move(b[1], b[0]))
        return home_dir

    def _patch_home(self):
        #make a temp dir
        temp_dir = tempfile.mkdtemp()
        #delete it, and recreate it to the length
        #required so our patching the db works
        #require a length of 25
        shutil.rmtree(temp_dir)
        temp_dir = temp_dir.ljust(25, 'X')
        os.mkdir(temp_dir)
        logger.debug("Created fake home directory " + temp_dir)
        self.addCleanup(shutil.rmtree, temp_dir)
        #if the Xauthority file is in home directory
        #make sure we copy it to temp home, otherwise do nothing
        xauth = os.path.expanduser(os.path.join('~', '.Xauthority'))
        if os.path.isfile(xauth):
            logger.debug("Copying .Xauthority to fake home " + temp_dir)
            shutil.copyfile(
                os.path.expanduser(os.path.join('~', '.Xauthority')),
                os.path.join(temp_dir, '.Xauthority'))
        patcher = mock.patch.dict('os.environ', {'HOME': temp_dir})
        patcher.start()
        logger.debug("Patched home to fake home directory " + temp_dir)
        self.addCleanup(patcher.stop)
        return temp_dir

    def _create_music_library(self):
        logger.debug("Creating music library for %s test" % self.test_type)
        logger.debug("Home set to %s" % self.home_dir)
        musicpath = os.path.join(self.home_dir, 'Music')
        logger.debug("Music path set to %s" % musicpath)
        mediascannerpath = os.path.join(self.home_dir, '.cache/mediascanner')
        os.mkdir(musicpath)
        logger.debug("Mediascanner path set to %s" % mediascannerpath)

        #set content path
        content_dir = os.path.join(os.path.dirname(music_app.__file__),
                                   'content')

        logger.debug("Content dir set to %s" % content_dir)

        #stop media scanner
        #if self.test_type == 'click':
        #    subprocess.check_call(['stop', 'mediascanner'])

        #copy content
        shutil.copy(os.path.join(content_dir, '1.ogg'), musicpath)
        shutil.copy(os.path.join(content_dir, '2.ogg'), musicpath)
        shutil.copy(os.path.join(content_dir, '3.mp3'), musicpath)
        if self.test_type != 'click':
            shutil.copytree(os.path.join(content_dir, 'mediascanner'),
                            mediascannerpath)

        logger.debug("Music copied, files " + str(os.listdir(musicpath)))

        if self.test_type != 'click':
            self._patch_mediascanner_home(mediascannerpath)
            logger.debug(
                "Mediascanner database copied, files " +
                str(os.listdir(mediascannerpath)))

        #start media scanner
        #if self.test_type == 'click':
        #    subprocess.check_call(['start', 'mediascanner'])

    def _patch_mediascanner_home(self, mediascannerpath):
        #do some inline db patching
        #patch mediaindex to proper home
        #these values are dependent upon our sampled db
        logger.debug("Patching fake mediascanner database")
        relhome = self.home_dir[1:]
        dblocation = "home/autopilot-music-app"
        dbfoldername = "d15682c3-89f1-4e41-abfc-531e4740e5a7"
        #patch mediaindex
        self._file_find_replace(mediascannerpath +
                                "/mediaindex", dblocation, relhome)

        #patch file indexes
        index_template = '%s/%s/_%%s.cfs' % (mediascannerpath, dbfoldername)
        for i in range(5):
            self._file_find_replace(index_template % i, dblocation, relhome)

    def _file_find_replace(self, in_filename, find, replace):
        #replace all occurences of string find with string replace
        #in the given file
        out_filename = in_filename + ".tmp"
        infile = open(in_filename, 'r')
        outfile = open(out_filename, 'w')
        for s in infile.xreadlines():
            outfile.write(s.replace(find, replace))
        infile.close()
        outfile.close()

        #remove original file and copy new file back
        os.remove(in_filename)
        os.rename(out_filename, in_filename)

    def temp_move_sqlite_db(self):
        try:
            shutil.rmtree(self.backup_dir)
        except:
            pass
        else:
            logger.warning("Prexisting backup database found and removed")

        try:
            shutil.move(self.sqlite_dir, self.backup_dir)
        except:
            logger.warning("No current database found")
        else:
            logger.debug("Backed up database")

    def restore_sqlite_db(self):
        if os.path.exists(self.backup_dir):
            if os.path.exists(self.sqlite_dir):
                try:
                    shutil.rmtree(self.sqlite_dir)
                except:
                    logger.error("Failed to remove test database and restore" /
                                 "database")
                    return
            try:
                shutil.move(self.backup_dir, self.sqlite_dir)
            except:
                logger.error("Failed to restore database")

    @property
    def player(self):
        return self.main_view.get_player()

    @property
    def main_view(self):
        return self.app.select_single(emulators.MainView)
