import asyncio
import threading
import time
from feedy import Feedy

app = Feedy('feeds.shelve')

@app.add('https://stackoverflow.com/feeds/tag?tagnames=xonsh&sort=newest')
@app.add('https://unix.stackexchange.com/feeds/tag?tagnames=xonsh&sort=newest')
def stackoverflow_question(info, body):
    # site_title, site_subtitle, site_url, fetched_at, article_title, article_url, published_at, updated_at
    msg = "New question on StackOverflow: {article_title} {article_url}".format(**info)
    gitter_send_msg(msg)
    send_irc_msg(msg)


def run():
    while True:
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)
        app.run()
        time.sleep(60*60)  # 1 hour

HANDLERS['FEEDS'] = threading.Thread(name="feeds", target=run, daemon=True)
HANDLERS['FEEDS'].start()
