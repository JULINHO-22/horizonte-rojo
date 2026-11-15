extends SceneTree
const Recursos := preload("res://scripts/mecanicas/recursos_mision.gd")

func _initialize() -> void:
	call_deferred("_probar")

func _probar() -> void:
	for polvo: String in Recursos.RECARGA_SOLAR:
		var clima := Recursos.new()
		assert(clima.iniciar_sol(polvo))
		assert(not clima.iniciar_sol("bajo"))
		assert(clima.activar_oxigeno())
		var antes: int = clima.estado().reservas.energia
		var intervalo: float = Recursos.RECARGA_SOLAR[polvo]
		if is_finite(intervalo):
			clima.avanzar(intervalo - 0.25)
			assert(clima.estado().reservas.energia == antes)
			clima.avanzar(0.25)
			assert(clima.estado().reservas.energia == antes + 1)
		else:
			clima.avanzar(120)
			assert(clima.estado().reservas.energia == antes)
		assert(clima.estado().reservas.oxigeno == 8)

	var aleatorio := Recursos.new()
	assert(aleatorio.iniciar_sol() and Recursos.POLVOS_NORMALES.has(aleatorio.estado().polvo))
	assert(aleatorio.aplicar_perdidas("tormenta_prueba", {"energia": 20}))
	assert(not aleatorio.aplicar_perdidas("tormenta_prueba", {"oxigeno": 8}))
	assert(aleatorio.estado().sin_luz and aleatorio.estado().reservas.oxigeno == 8)

	var agotada := Recursos.new()
	assert(agotada.iniciar_sol("tormenta"))
	agotada.avanzar(63)
	assert(agotada.estado().reservas.oxigeno == 1)
	agotada.avanzar(1.5)
	assert(agotada.estado().derrota == "oxigeno_agotado")
	assert(not agotada.activar_oxigeno())

	var noche_insegura := Recursos.new()
	assert(noche_insegura.iniciar_sol("medio"))
	assert(not noche_insegura.dormir())
	assert(noche_insegura.estado().derrota == "aire_sin_activar")

	var cultivo := Recursos.new()
	assert(cultivo.iniciar_sol("bajo"))
	assert(cultivo.activar_oxigeno())
	assert(cultivo.sembrar("lechuga"))
	assert(not cultivo.comer("lechuga"))
	assert(not cultivo.sembrar("lechuga"))
	cultivo.avanzar(200)
	assert(cultivo.estado().reservas.alimento == 0 and cultivo.estado().derrota == "")
	assert(cultivo.comer("lechuga"))
	assert(cultivo.estado().reservas.alimento == 2)
	assert(cultivo.dormir())
	assert(cultivo.estado().reservas.alimento == 2)

	var hielo := Recursos.new()
	assert(hielo.iniciar_sol("medio"))
	assert(not hielo.purificar_hielo())
	assert(hielo.recoger_hielo())
	assert(hielo.purificar_hielo())
	assert(hielo.estado().reservas.agua == 6)
	assert(hielo.recoger_hielo())
	assert(not hielo.purificar_hielo() and hielo.estado().hielo == 1)
	var anterior := hielo.estado()
	assert(not hielo.aplicar_decision("fallo", {"energia": -4, "agua": -7}))
	assert(hielo.estado() == anterior)
	assert(hielo.aplicar_decision("turno", {"energia": -7}))
	assert(hielo.estado().sin_luz and hielo.estado().derrota == "")
	assert(not hielo.aplicar_decision("turno", {"agua": -1}))
	hielo.avanzar(15)
	assert(not hielo.estado().sin_luz)

	var campana := Recursos.new()
	for dia in range(1, 6):
		assert(campana.iniciar_sol("bajo"))
		assert(campana.estado().sol == dia)
		campana.avanzar(7.5)
		var copia := Recursos.new()
		assert(copia.restaurar_estado(campana.guardar_estado()))
		copia.avanzar(0.5)
		assert(copia.estado().reservas.oxigeno == campana.estado().reservas.oxigeno - 1)
		var invalido := campana.guardar_estado()
		invalido.reservas.agua = -1
		assert(not copia.restaurar_estado(invalido))
		assert(campana.aplicar_decision("reservas_de_prueba", {"agua": 5, "energia": 12}))
		if dia == 3:
			assert(campana.usar_tanques_emergencia())
			assert(campana.estado().reservas.oxigeno == 6)
		else:
			assert(campana.activar_oxigeno())
		var reservas: Dictionary = campana.estado().reservas
		assert(campana.dormir())
		assert(campana.estado().reservas == reservas)
	assert(campana.estado().terminado and not campana.iniciar_sol("bajo"))
	print("RECURSOS_OK: clima, cultivos, agua, derrotas, guardado y continuidad de cinco soles.")
	quit()
