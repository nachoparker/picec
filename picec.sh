#!/bin/bash
 
# Simple script to control your Raspberry Pi with your TV remote using libcec
#
# Copyleft 2017 by Ignacio Nunez Hernanz <nacho _a_t_ ownyourbits _d_o_t_ com>
# GPL licensed (see end of file) * Use at your own risk!
#
# You can set this to be run in your desktop "startup programs", or 
# at the last line of /etc/rc.local, just to say a couple options
#
# keys:
#   OK   - launch kodi 
#   up   - launch browser
#   down - change wallpaper (this is a custom script of mine)
#   left - suspend my desktop computer
#   back - exit desktop session
#
# You can hit 'stop' to enter "mouse mode", or 'play' to exit it.
# In "mouse mode" you can move around the mouse with the remote arrows, hit ok
# to double-click.
#
# This is just an example to provide ideas, so you should change what each button does.
#
 
USER=pi                        # user that will be logged in
OSDCOLOR=red                   # color for xosd messages
MOUSESPEED=50                  # how many pixels a mouse will move on each press
#dbg=echo                      # uncomment to just print the command without executing it
VERBOSE=0                      # print echov lines
#DRY_RUN="yes"                 # uncomment to actually ignore button presses
 
type cec-client &>/dev/null || { echo "cec-client is requiered"; exit; }
type xdotool    &>/dev/null || NOXDOTOOL=#
 
USR_CMD="su - $USER -c"
_XAUTH="/home/$USER/.Xauthority"
 
function          d(){ eval "$NOXDOTOOL $@"                                            ; }
function      echov(){ [[ "$VERBOSE" == "1" ]] && echo $@                              ; }
function filter_key(){ grep -q "key pressed: $1 .* duration" <( echo "$2" )            ; }
function mouse_move(){ XAUTHORITY="$_XAUTH" DISPLAY=:0 xdotool mousemove_relative -- $@; }
function mouseclick(){ XAUTHORITY="$_XAUTH" DISPLAY=:0 xdotool click --repeat 2 1      ; }
function    osdecho(){ type osd_cat &>/dev/null && echo "$@" | \
                       XAUTHORITY="$_XAUTH" DISPLAY=:0 osd_cat -ptop -Acenter -c$OSDCOLOR; }
 
while :; do 
  cec-client | while read l; do
    echov $l
 
    [[ "$DRY_RUN" != "" ]] && continue
 
     pgrep kodi && { echov "Ignoring key, because Kodi is running"; continue; }
 
    if  filter_key "select" "$l"; then
      [[ "$MOUSEMODE" == "1" ]] && mouseclick || {
        $dbg $USR_CMD kodi
        killall cec-client
      }
      break
    fi
    if  filter_key "up" "$l"; then
      [[ "$MOUSEMODE" == "1" ]] && mouse_move 0 -$MOUSESPEED || \
      $dbg $USR_CMD "DISPLAY=\":0\" x-www-browser" &
    fi  
    if  filter_key "left" "$l"; then
      [[ "$MOUSEMODE" == "1" ]] && mouse_move -$MOUSESPEED 0 || \
        $dbg nohup su - nacho -c "ssh nacho@desktop sudo pm-suspend" &
    fi  
    if  filter_key "down" "$l"; then
      [[ "$MOUSEMODE" == "1" ]] && mouse_move 0 $MOUSESPEED || \
        $dbg $USR_CMD "DISPLAY=\":0\" /home/pi/.config/lxsession/LXDE-pi/random_wp.sh" 
    fi  
    if  filter_key "right" "$l"; then
      [[ "$MOUSEMODE" == "1" ]] && mouse_move $MOUSESPEED 0 
    fi
    if  filter_key "exit" "$l"; then
      $dbg $USR_CMD "pkill -SIGTERM -f lxsession"
    fi  
    if  filter_key "stop" "$l"; then
d     echov   "mouse mode on"
d     osdecho "mouse mode on"
d     MOUSEMODE=1
    fi
    if  filter_key "play" "$l"; then
      echov   "mouse mode off"
      osdecho "mouse mode off"
      MOUSEMODE=0
    fi
  done
done
 
# License
#
# This script is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This script is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this script; if not, write to the
# Free Software Foundation, Inc., 59 Temple Place, Suite 330,
# Boston, MA  02111-1307  USA
