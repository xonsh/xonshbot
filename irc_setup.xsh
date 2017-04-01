# xonshbot IRC setup

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


IRC_COMMANDS = {}

# connect to IRC
IRC_SOCKET = socket.socket()
IRC_SOCKET.connect(($IRC_SERVER, ${...}.get("IRC_PORT", 6667)))

def _quit_irc():
    IRC_SOCKET.send(b"QUIT :back to hastingues...\r\n")
    IRC_SOCKET.close()

atexit.register(_quit_irc)


# identify ourselves
IRC_SOCKET.send(("NICK %s\r\n" % $IRC_NICK).encode())
IRC_SOCKET.send(("USER %s %s nonsense :%s\r\n" % (${...}.get("IRC_IDENT_USERNAME", "xonshbot"),
                                ${...}.get("IRC_IDENT_HOSTNAME", "xonshbot"),
                                ${...}.get("IRC_IDENT_FULLNAME", "Xonsh Bot"))).encode())
IRC_SOCKET.send(("JOIN %s\r\n" % $IRC_CHANNEL).encode())
IRC_SOCKET.send(("PRIVMSG Nickserv :identify %s\r\n" % $IRC_PASSWD).encode())


# some constants for use in IRC
IRC_CHANNEL_MSG_START = b"PRIVMSG " + $IRC_CHANNEL.encode()
IRC_PRIVATE_MSG_START = b"PRIVMSG " + $IRC_NICK.encode()
IRC_NOTICE_START = b"NOTICE " + $IRC_NICK.encode()


def send_irc_msg(msg, to=None):
    for i in msg.splitlines():
        _simple_send_irc_msg(i, to)


def _simple_send_irc_msg(msg, to=None):
    if not isinstance(msg, bytes):
        msg = msg.encode()
    if to is None:
        to = $IRC_CHANNEL
        style = "PRIVMSG"
    elif isinstance(to, bytes):
        to = to.decode()
        style = "NOTICE"
    XONSHBOT_WRITE_LOCK.acquire()
    IRC_SOCKET.send(("%s %s :" % (style, to)).encode() + msg + b'\r\n')
    XONSHBOT_WRITE_LOCK.release()
SENDMSG['IRC'] = send_irc_msg


# buffers for input from irc and gitter
IRC_INPUT_BUFFER = b""

IRC_WELCOME_MESSAGE = [
("Welcome to %s!  You're in the right place to discuss %s, including issues, "
 "suggestions for improvement, or questions about normal use.") % ($IRC_CHANNEL, $REPO_SHORT_NAME),

("%s also has a chat room on Gitter.im (https://gitter.im/%s).  The conversations "
 "in these two rooms are kept in sync by a bot named %s.  Messages from %s are typically "
 "just relaying conversation from actual users in the Gitter.im channel.") % ($REPO_SHORT_NAME,
                                                                              $GITTER_ROOM,
                                                                              $IRC_NICK,
                                                                              $IRC_NICK),

("%s is running on software that is licensed under the GNU Affero General Public "
 "License, version 3+ (https://www.gnu.org/licenses/agpl-3.0-standalone.html).  "
 "The bot's source code is available at https://github.com/xonsh/xonshbot.") % $IRC_NICK ]


# handle irc input
def handle_irc():
    while True:
        global IRC_INPUT_BUFFER
        try:
            irc_to_consider = IRC_INPUT_BUFFER + IRC_SOCKET.recv(1024)
        except:
            continue
        lines = irc_to_consider.split(b'\r\n')
        if len(lines) == 0:
            continue
        IRC_INPUT_BUFFER = lines.pop()
        for i in lines:
            sender, rest = i.split(b' ', 1)
            sender = sender[1:sender.find(b'!')]
            if i.startswith(b'PING'):
                IRC_SOCKET.send(b'PONG'+i[4:]+b'\r\n')
            elif rest.startswith(IRC_CHANNEL_MSG_START):
                msg = rest.split(b':', 1)[-1]
                if msg.startswith(b'\x01ACTION'):
                    resp = b'- **<' + sender + b'>** ' + msg[7:-1]
                else:
                    resp = b'**<' + sender + b'>**: ' + msg
                for i in SENDMSG:
                    if i == 'IRC':
                        continue
                    SENDMSG[i](resp)
                handle_commands(sender.decode(), msg.decode())
                if (($IRC_NICK.encode() + b':') in msg or
                        ($IRC_NICK.encode() + b',') in msg or
                        (b'@' + $IRC_NICK.encode()) in msg):
                    default_mention_response(sender.decode())
            elif (rest.startswith(IRC_PRIVATE_MSG_START) or
                  rest.startswith(IRC_NOTICE_START)):
                msg = rest.split(b':', 1)[-1]
                handle_commands(sender.decode(), msg.decode(), sender, ['IRC'])
            elif rest.startswith(b"JOIN") and sender != $IRC_NICK.encode():
                for i in IRC_WELCOME_MESSAGE:
                    SENDMSG['IRC'](i, sender)


class IRCThread(Thread):
    def __init__(self):
        Thread.__init__(self, daemon=True)
        self.start()
    def run(self):
        handle_irc()

HANDLERS['IRC'] = IRCThread()
