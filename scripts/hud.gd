extends CanvasLayer

func _on_health_updated(health):
	
	$Health.text = str(health) + "%"

func _on_coin_collected(coins):
	
	$Coins/Coins.text = str(coins)
