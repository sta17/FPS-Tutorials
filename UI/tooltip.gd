extends Control

@onready var tooltip:Control = $"."
@onready var tooltipName:Label = $Anchor/NinePatchRect/MarginContainer/GridContainer/Tooltip_Name
@onready var tooltipDesc:Label = $Anchor/NinePatchRect/MarginContainer/GridContainer/Tooltip_Properties
@onready var tooltipLoreTitle:Label = $Anchor/NinePatchRect/MarginContainer/GridContainer/Tooltip_Lore_Title
@onready var tooltipLoreDesc:Label = $Anchor/NinePatchRect/MarginContainer/GridContainer/Tooltip_Lore_Desc
@onready var tooltipRank:Label = $Anchor/NinePatchRect/MarginContainer/GridContainer/Tooltip_Rank

func setTooltip(item:InventoryItem):
	setToolTipName(item.name)
	setToolTipDesc("")
	setToolTipLore(item.lore)
	setToolTipRank(item.rank)

func setToolTipName(newName: String):
	tooltipName.text = newName
		
func setToolTipDesc(desc: String):
	if desc == "" or !desc:
		tooltipDesc.visible = false
	else:
		tooltipDesc.visible = true
		tooltipDesc.text = desc

func setToolTipLore(lore: String,title = "Lore"):
	if lore == "" or !lore:
		tooltipLoreTitle.visible = false
		tooltipLoreDesc.visible = false
	else:
		tooltipLoreTitle.visible = true
		tooltipLoreDesc.visible = true
		tooltipLoreTitle.text = title
		tooltipLoreDesc.text = lore

func setToolTipRank(Rank: ItemCategory,dohide:bool=false):
	if dohide or !Rank:
		tooltipRank.visible = false
	else:
		tooltipRank.visible = true
		tooltipRank.label_settings.font_color = Rank.color
		tooltipRank.text = Rank.name

func show_tooltip():
	tooltip.visible = true
	
func hide_tooltip():
	tooltip.visible = false
