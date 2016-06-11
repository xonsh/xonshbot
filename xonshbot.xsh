# xonshbot: IRC <-> Gitter.im bridge
# with some Github integration
# written in xonsh :)

# xonshbot is free software: you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation, either version 2 of the License, or (at your option) any later
# version.

# You should have received a copy of the GNU General Public License along with
# xonshbot.  If not, see <http://www.gnu.org/licenses/>.

import re
import sys
import json
import time
import atexit
import select
import string
import socket

from urllib.parse import urlencode
from urllib.request import Request, urlopen

from threading import Thread, Lock

XONSHBOT_WRITE_LOCK = Lock()

$XONSH_SHOW_TRACEBACK = True
HANDLERS = {}
COMMANDS = {}
SENDMSG = {}


def handle_commands(sender, msg_text):
    if isinstance(msg_text, bytes):
        msg_text = msg_text.decode()
    msg_text = msg_text.lstrip()
    body = msg_text.lstrip().split(' ')
    for i in COMMANDS:
        if body[0] == '!%s' % i:
            result = COMMANDS[i](sender, ' '.join(body[1:]))
            if isinstance(result, (str, bytes)):
                result = [result]
            for i in result:
                for s in SENDMSG:
                    SENDMSG[s](i)


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
source custom.xsh

# keep us alive
while any(HANDLERS[i].is_alive() for i in HANDLERS):
    time.sleep(0.1)
