# xonshbot IRC setup

# xonshbot is free software: you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation, either version 2 of the License, or (at your option) any later
# version.

# You should have received a copy of the GNU General Public License along with
# xonshbot.  If not, see <http://www.gnu.org/licenses/>.


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
IRC_RELEVANT_MESSAGE_START = b"PRIVMSG " + $IRC_CHANNEL.encode()

def send_irc_msg(msg):
    if not isinstance(msg, bytes):
        msg = msg.encode()
    o = ("PRIVMSG %s :" % $IRC_CHANNEL).encode() + msg + b'\r\n'
    XONSHBOT_WRITE_LOCK.acquire()
    IRC_SOCKET.send(("PRIVMSG %s :" % $IRC_CHANNEL).encode() + msg + b'\r\n')
    XONSHBOT_WRITE_LOCK.release()
SENDMSG['IRC'] = send_irc_msg


# buffers for input from irc and gitter
IRC_INPUT_BUFFER = b""


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
            if sender == b'PING':
                IRC_SOCKET.send(b'PONG'+i[4:])
            elif rest.startswith(IRC_RELEVANT_MESSAGE_START):
                msg = rest.split(b':', 1)[-1]
                print('IRC', i)
                for i in SENDMSG:
                    if i == 'IRC':
                        continue
                    SENDMSG[i](b'`' + sender + b'` (IRC) says: ' + msg)


class IRCThread(Thread):
    def __init__(self):
        Thread.__init__(self)
        self.start()
    def run(self):
        handle_irc()

HANDLERS['IRC'] = IRCThread()
