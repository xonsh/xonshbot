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
import time
import atexit
import select
import string
import socket

from threading import Thread, Lock

XONSHBOT_WRITE_LOCK = Lock()

$XONSH_SHOW_TRACEBACK = True
HANDLERS = {}
COMMANDS = {}
SENDMSG = {}

# grab the individual modules we are using
source irc_setup.xsh
source gitter_setup.xsh

# grab other commands, etc
source custom.xsh

# keep us alive
while any(HANDLERS[i].is_alive() for i in HANDLERS):
    time.sleep(0.1)
