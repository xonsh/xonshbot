# xonshbot: IRC <-> Gitter.im bridge
# with some Github integration
# written in xonsh :)

# Copyright (c) 2016 Adam J Hartz <hartz@mit.edu>

# xonshbot is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.

# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.


import os
import re
import sys
import json
import time
import atexit
import select
import string
import socket
import traceback

from urllib.parse import urlencode
from urllib.request import Request, urlopen

from threading import Thread, Lock

$XONSH_SHOW_TRACEBACK = True
$RAISE_SUBPROC_ERROR = True

XONSHBOT_WRITE_LOCK = Lock()

$REPO_SHORT_NAME = $GITTER_ROOM.split('/')[-1]
HANDLERS = {}
COMMANDS = {}
SENDMSG = {}


def handle_commands(sender, msg_text, recipient=None, types=None):
    if isinstance(msg_text, bytes):
        msg_text = msg_text.decode()
    msg_text = msg_text.lstrip()
    body = msg_text.lstrip().split(' ')
    for i in COMMANDS:
        if body[0] == '!%s' % i:
            try:
                result = COMMANDS[i](sender, ' '.join(body[1:]))
            except:
                exc_type, exc_value, exc_traceback = sys.exc_info()
                exc = traceback.format_exception_only(exc_type, exc_value)[-1]
                result = "ERROR running command %r: %s" % ('!' + i, exc)
            if isinstance(result, (str, bytes)):
                result = [result]
            for i in result:
                if types is None:
                    types = SENDMSG
                for s in types:
                    SENDMSG[s](i, recipient)


def default_mention_response(sender):
    things = list(SENDMSG.keys())
    nthings = len(things)
    if nthings == 0:
        return None
    if nthings == 1:
        others = things[0]
    elif nthings == 2:
        others = '%s and %s'  % tuple(things)
    else:
        others = ', '.join(things[:-1]) + ', and ' + things[-1]
    for i in things:
        msg = '%s: I am a bot.  I just relay messages between %s.' % (sender, others)
        SENDMSG[i](msg)


# grab the individual modules we are using
source irc_setup.xsh
source gitter_setup.xsh

# grab other commands, etc
source commands.xsh

source feeds.xsh

try:
    source custom.xsh
except:
    pass

# keep us alive
while any(HANDLERS[i].is_alive() for i in HANDLERS):
    time.sleep(0.1)
