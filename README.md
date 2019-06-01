
# Chests and Showcase with Digilines and an Auto-Filter

![Screenshot 3](screenshots/screenshot3.png?raw=true "Screenshot 3")

- Default Chests (1-4)
- Chests which can only take items of the same type (5-8)
- Locked Chests (2,4,6,8)
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

## Digiline-Commands
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

## Digiline-Events:
  - put <item>
  - take <item>
  - full / not full
  - empty / not found
  - count
  - get
  - items
  - found / not found
  



# Showcase

![Screenshot 2](screenshots/screenshot2.png?raw=true "Screenshot 2")

Define a channel and send an item-string (e.g. default:cobble) with digilines to display this item.


# Autofilter

![Screenshot 4](screenshots/screenshot4.png?raw=true "Screenshot 4")

![Screenshot 5](screenshots/screenshot5.png?raw=true "Screenshot 5")

An Item-Filter which works like the Pipeworks-Sorting-Pipe. You can choose an item which can pass this filter.
If 'Self-learning' is enabled and the Filteritem is empty, the first item, which reaches the filter sets the filteritem.

Optionally, the Filteritem is displayed above the filter.


# Buffer

![Screenshot 6](screenshots/screenshot6.png?raw=true "Screenshot 6")

An Buffer, which stores all items, which it gets and only ejects items 
if the box is full, or if stackwise is enabled full stackes are ejected.


# Distributor

![Screenshot 7](screenshots/screenshot7.png?raw=true "Screenshot 7")
![Screenshot 8](screenshots/screenshot8.png?raw=true "Screenshot 8")

A distributor is a chest, that fills the inventory of the players which are standing around it.
It can be connected with pipes. The player-names can be optionally filtered by names (seperated by ';')
If the limit-switch is enabled, the inventory of the player is only filled, when he has no such material inside.

