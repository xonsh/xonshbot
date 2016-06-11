# xonshbot built-in commands

# Copyright (c) 2016 Adam J Hartz <hartz@mit.edu>

# xonshbot is free software: you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation, either version 2 of the License, or (at your option) any later
# version.

# You should have received a copy of the GNU General Public License along with
# xonshbot.  If not, see <http://www.gnu.org/licenses/>.


def _clone(sender, rest_of_line):
    # here, ignore the rest of the line and return instructions for cloning the
    # repo (toy example)
    return ['You can clone xonsh with the following command: `$ git clone https://github.com/%s`' % $GITTER_ROOM]

def _about(sender, rest_of_line):
    return ("I am Lou Carcolh, a bot designed to keep xonsh's IRC and Gitter "
            'rooms in sync.  I am written in xonsh, and my source code is '
            'available here: https://github.com/xonsh/xonshbot')

GITHUB_API_URL = 'https://api.github.com/'

def github_request(url):
    return json.loads(urlopen(GITHUB_API_URL + url).read().decode())

def _stars(sender, rest_of_line):
    nstars = github_request('repos/%s' % $GITTER_ROOM)['stargazers_count']
    return '%s currently has %d stargazers' % ($GITTER_ROOM, nstars)


COMMANDS['clone'] = _clone
COMMANDS['bot'] = _about
COMMANDS['stars'] = _stars
