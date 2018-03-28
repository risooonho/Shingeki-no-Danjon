extends KinematicBody2D

const SPEED = 320
const MEDITATION_TIME = 3

onready var UI = $Camera/UI
var texture_cache = {}

var direction = 1
var static_time = 0

var attacking = false

func _physics_process(delta):
	var move = Vector2()
	
	static_time += delta
	if static_time >= MEDITATION_TIME: SkillBase.inc_stat("Meditation")
	
	if Input.is_key_pressed(KEY_UP):
		move.y = -1
		change_dir(0)
	if Input.is_key_pressed(KEY_DOWN):
		move.y = 1
		change_dir(2)
	if Input.is_key_pressed(KEY_LEFT):
		move.x = -1
		change_dir(3)
	if Input.is_key_pressed(KEY_RIGHT):
		move.x = 1
		change_dir(1)
	
	move = move.normalized() * SPEED
	
	if !attacking and Input.is_action_just_pressed("Attack"):
		Res.play_sample(self, "Sword")
		$ArmAnimator.play("SwordAttackRight")
		attacking = true
	
	if Input.is_action_just_pressed("Spell1") and PlayerStats.get_skill(0) and PlayerStats.mana > PlayerStats.get_skill(0).cost:
		cast_spell(0)
	
	if randi()%10 == 0: PlayerStats.mana += 1
	UI.soft_refresh()
	
	if SkillBase.has_skill("FastWalk") and Input.is_key_pressed(KEY_SHIFT): move *= 3
	SkillBase.inc_stat("PixelsTravelled", int(move.length())) ##działa też na ścianach :/
	
	if move != Vector2():
		static_time = 0
		if $BodyAnimator.assigned_animation != "WalkRight":
			change_texture($Body, ["Back", "Right", "Front", "Left"][direction], "BodyWalk")
			$Body.hframes = 9
			$BodyAnimator.play("WalkRight")
	else:
		change_texture($Body, ["Back", "Right", "Front", "Left"][direction], "Body")
		$Body.hframes = 1
		$BodyAnimator.play("Idle")
	
	move_and_slide(move)

func damage(attacker, amount, knockback):
	Res.create_instance("DamageNumber").damage(self, amount)
	SkillBase.inc_stat("DamageTaken", amount)
	PlayerStats.health -= amount
	UI.soft_refresh()
	move_and_slide((position - attacker.position).normalized() * 1000 * knockback)

func _on_animation_finished(anim_name):
	if anim_name == "SwordAttackRight":
		attacking = false

func _on_attack_hit(collider):
	if collider.get_parent().is_in_group("enemies"):
		SkillBase.inc_stat("OneHanded")
		SkillBase.inc_stat("Melee")
		collider.get_parent().damage(PlayerStats.get_damage())

func change_dir(dir):
	direction = dir
	var d = ["Back", "Right", "Front", "Left"][dir]
#	change_texture($Body, d, "Body")
	change_texture($Body/RightArm, d, "SwordAttack", ["Left", "Back"])
	change_texture($Body/LeftArm, d, "ShieldOn", ["Right", "Back"])

func change_texture(sprite, direction, texture, on_back = []):
	sprite.texture = Res.get_resource("res://Sprites/Player/" + direction + "/" + texture + ".png")
	sprite.show_behind_parent = on_back.has(direction)

func cast_spell(slot):
	var spell = PlayerStats.get_skill(slot)
	PlayerStats.mana -= spell.cost
	for stat in spell.stats:
		SkillBase.inc_stat(stat)
	
	var projectile = Res.create_instance("Projectiles/" + spell.projectile)
	get_parent().add_child(projectile)
	projectile.position = position
	projectile.direction = direction
	projectile.intiated()
	
	projectile.damage = spell.damage
	for stat in spell.scalling.keys():
		projectile.damage += int(PlayerStats[stat] * spell.scalling[stat])
	
	if SkillBase.has_skill("FireAffinity"): projectile.damage *= 3 ##hack