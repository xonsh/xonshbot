def _clone(sender, rest_of_line):
    # here, ignore the rest of the line and return instructions for cloning the
    # repo (toy example)
    return ['You can clone xonsh with the following command: `$ git clone https://github.com/xonsh/xonsh`']

def _about(sender, rest_of_line):
    return ("I am Lou Carcolh, a bot designed to keep xonsh's IRC and Gitter "
            'rooms in sync.  I am written in xonsh, and my source code is '
            'available here: https://github.com/xonsh/xonshbot')

GITHUB_API_URL = 'https://api.github.com/'

def github_request(url):
    return json.loads(urlopen(GITHUB_API_URL + url).read().decode())

def _stars(sender, rest_of_line):
    print('here')
    nstars = github_request('repos/xonsh/xonsh')['stargazers_count']
    print('nstars', nstars)
    return 'xonsh currently has %d stargazers' % nstars


COMMANDS['clone'] = _clone
COMMANDS['bot'] = _about
COMMANDS['stars'] = _stars
