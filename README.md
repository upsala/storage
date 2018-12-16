
##Chests and Showcase with Digilines

![Screenshot 3](screenshots/screenshot3.png?raw=true "Screenshot 3")

- Default Chests (1-4)
- Chests which can only take items of the same type (5-8)
- Locked Chessts (2,4,6,8)
- Chests which shows the first item in it, above the chest (3,4,7,8)
- All chests can be connected with pipes from the pipeworks-mod and with digilines from the digilines-mod.
- If an pipe is connected from the bottom of the chest, and the chest receives an 'eject'-command from an digiline,
    the pipe will be filled with an item from the chest.


![Screenshot 1](screenshots/screenshot1.png?raw=true "Screenshot 1")

1) The name of the digiline-channel
2) Commands & Events which from the digiline-connection
3) Contents of the chest
4) Player-content
5) Takes all items from the chest into the player-inventory
6) Like 5, but only if the player has the same items
7) Puts all items from the player-inventory into the chest
8) Like 7, but only if the chest has the same items
9) Sort the items in the chest

##Digiline
###Commands:
- eject [ &lt;pos&gt; | &lt;item&gt; ]
	Ejects the first stack, or the stack at &lt;pos&gt; or &lt;item&gt; into an connected pipe at the bottom of the chest
	
-	count [ &lt;pos&gt; | &lt;item&gt; ]
- get [ &lt;pos&gt; ]
	Return the itemstring of the item at position &lt;pos&gt; in the chest
- full
	Tests, if the chest is full
- empty
	Tests, if the chest is empty
- find <item>

- sort
	Sorts the items in the chest

###Events:
  - put <item>
  - take <item>
  - full
  - empty





![Screenshot 2](screenshots/screenshot2.png?raw=true "Screenshot 2")

Define a channel and send an item-string (e.g. default:cobble) with digilines to display this item.