# xonshbot Gitter setup

# xonshbot is free software: you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation, either version 2 of the License, or (at your option) any later
# version.

# You should have received a copy of the GNU General Public License along with
# xonshbot.  If not, see <http://www.gnu.org/licenses/>.

GITTER_API_URL = 'https://api.gitter.im/v1/'
GITTER_REQUEST_HEADERS = {'Authorization': 'Bearer %s' % $GITTER_APIKEY.strip(),
                          'Accept': 'application/json'}


def gitter_request(url, data=None):
    if data is not None:
        data = urlencode(data).encode()
    r = Request(GITTER_API_URL + url, headers=GITTER_REQUEST_HEADERS, data=data)
    o = json.loads(urlopen(r).read().decode())
    return o

def get_gitter_stream():
    r = Request('https://stream.gitter.im/v1/rooms/%s/chatMessages' % GITTER_ROOM_ID,
                headers=GITTER_REQUEST_HEADERS)
    return urlopen(r)

$XONSH_SHOW_TRACEBACK = True

# find room id and user id
GITTER_ROOM_ID = gitter_request('rooms', {'uri': $GITTER_ROOM})['id']
_g_user = gitter_request('user')[0]
GITTER_USER_ID = _g_user['id']
GITTER_USERNAME = _g_user['username']

GITTER_MSG_URL = 'rooms/' + GITTER_ROOM_ID + '/chatMessages'

def gitter_send_msg(msg):
    # msg is a _bytes_ object, so we need to convert
    if isinstance(msg, bytes):
        msg = msg.decode()
    XONSHBOT_WRITE_LOCK.acquire()
    gitter_request(GITTER_MSG_URL, {'text': msg})
    XONSHBOT_WRITE_LOCK.release()

SENDMSG['GITTER'] = gitter_send_msg

GITTER_INPUT_BUFFER = b""
GITTER_STREAM = get_gitter_stream()

def handle_gitter():
    global GITTER_INPUT_BUFFER
    while True:
        x = GITTER_STREAM.read(1)
        gitter_to_consider = GITTER_INPUT_BUFFER + x
        new_msgs = gitter_to_consider.split(b'\n')
        GITTER_INPUT_BUFFER = new_msgs.pop()
        new_ids = []
        for msg in new_msgs:
            try:
                msg = json.loads(msg.decode())
            except:
                continue
            m_sender_id = msg['fromUser']['username']
            if m_sender_id == GITTER_USERNAME:
                continue
            m_id = msg['id']
            m_body = msg['text'].splitlines()
            if len(m_body) > 3:
                m_body = m_body[:3]
                m_url = 'https://gitter.im/%s?at=%s' % ($GITTER_ROOM, m_id)
                m_body += ['[Full message on Gitter.im: %s]' % m_url]
            for line in m_body:
                for i in msg['issues']:
                    line = line.replace('#' + i['number'],
                                        '#%s (%sissues/%s)' % (i['number'],
                                                               $GITHUB_URL,
                                                               i['number']))
                for i in SENDMSG:
                    if i != 'GITTER':
                        SENDMSG[i]('<@%s>: ' % msg['fromUser']['username'] + line)
            if len(m_body) == 1:
                handle_commands(m_sender_id, m_body[0])
            if GITTER_USERNAME in {i['screenName'] for i in msg['mentions']}:
                default_mention_response('@' + m_sender_id)
            new_ids.append(m_id)
        # now that we're here, mark these messages as read
        for m_id in new_ids:
            try:
                gitter_request('user/%s/rooms/%s/unreadItems' % (GITTER_USER_ID, GITTER_ROOM_ID),
                               {'chat': '["%s"]' % m_id}) 
            except:
                pass


class GitterThread(Thread):
    def __init__(self):
        Thread.__init__(self)
        self.start()
    def run(self):
        handle_gitter()


HANDLERS['GITTER'] = GitterThread()
