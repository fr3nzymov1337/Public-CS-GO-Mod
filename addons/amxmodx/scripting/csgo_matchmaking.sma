#include <amxmodx>
#include <cstrike>
#include <hamsandwich>
#include <fun>
#include <cstrike>

#define HUD_TASK	1.0
#define HUD_ID		74358293

#define VOTEMAP_END	// При окончании матча вызывать смену карты, экспериментально.

#if defined VOTEMAP_END
native VoteMap()	// Голосование за карту, из плагина csgo_mapchooser.amxx
#endif

new g_hud
new team_tt, team_ct, rounds
new bool:last_round, bool:warm_up, iTimer, iWeaponNum[33]

new const g_Weapons[][32] =
{
	"weapon_awp",
	"weapon_deagle",
	"weapon_m4a1",
	"weapon_ak47",
	"weapon_scout"
}
new const g_WeaponID[] =
{
	CSW_AWP,
	CSW_DEAGLE,
	CSW_M4A1,
	CSW_AK47,
	CSW_SCOUT
}

public plugin_init()
{
	register_plugin("[CS:GO MOD] Matchmaking System", "1.2", "Hozon / x FR3NZYMOV x")
	set_task(HUD_TASK, "informer", HUD_ID, "", 0, "b", 0)
	
	register_logevent("Round_Start", 2, "1=Round_Start")
	register_event("SendAudio", "t_win", "a", "2&%!MRAD_terwin")
	register_event("SendAudio", "ct_win", "a", "2&%!MRAD_ctwin")
	
	RegisterHam(Ham_Killed, "player", "RespawnPlayer", true)
	
	g_hud = CreateHudSyncObj()
	warm_up = true
	iTimer = 60
}

public client_disconnect(id) remove_task(id)

public Round_Start()
{
	if(warm_up)
		return PLUGIN_HANDLED
		
	rounds++
	
	if(rounds >= 30)
	{
		if(team_tt == team_ct)
		{
			last_round = true
			return PLUGIN_HANDLED
		}
		if(team_tt > team_ct)
			client_print(0, print_center, "Победила команда террористов! Со счётом: %d/%d", team_tt, team_ct)
		else if(team_tt < team_ct)
			client_print(0, print_center, "Победила команда спецназа! Со счётом: %d/%d", team_ct, team_tt)
			
		rounds = 0
		team_tt = 0
		team_ct = 0
		last_round = false
		server_cmd("sv_restartround 1")
		#if defined VOTEMAP_END
		VoteMap()
		#endif
	}
	
	if(team_tt == 16 || team_ct == 16)
	{
		if(team_tt == 16)
			client_print(0, print_center, "Победила команда террористов! Со счётом: %d/%d", team_tt, team_ct)
		
		if(team_ct == 16)
			client_print(0, print_center, "Победила команда спецназа! Со счётом: %d/%d", team_ct, team_tt)
		
		rounds = 0
		team_tt = 0
		team_ct = 0
		last_round = false
		server_cmd("sv_restartround 1")
		#if defined VOTEMAP_END
		VoteMap()
		#endif
	}
	return PLUGIN_HANDLED
}

public t_win() team_tt++
public ct_win() team_ct++

public informer()
{
	new szMessage[512], iLen = 0
	
	if(warm_up)
	{
		if(iTimer > 0)
		{
			iTimer--
			iLen += formatex(szMessage[iLen], charsmax(szMessage) - iLen, "Разминка: %d секунд", iTimer)
		}
		else
		{
			warm_up = false
			server_cmd("sv_restartround 1")
		}
	}
	else
	{
		if(last_round)
			iLen += formatex(szMessage[iLen], charsmax(szMessage) - iLen, "		Решающий раунд!^n| TT: %d | 	| CT: %d |", rounds, team_tt, team_ct)
		else
			iLen += formatex(szMessage[iLen], charsmax(szMessage) - iLen, "		%d / 30^n| TT: %d | 	| CT: %d |", rounds, team_tt, team_ct)
	}
	set_hudmessage(0, 255, 255, -1.0, 0.06, 0, 0.0, HUD_TASK + 0.1, 0.0, 0.0, -1)
	ShowSyncHudMsg(0, g_hud, szMessage)
}

public RespawnPlayer(victim)
{
	if(!is_user_connected(victim) || is_user_alive(victim))
		return HAM_IGNORED
	
	if(warm_up)
		set_task(2.0, "Respawn", victim)
		
	return HAM_IGNORED
}

public Respawn(id)
{
	ExecuteHamB(Ham_CS_RoundRespawn, id)
	
	iWeaponNum[id] = random_num(0, sizeof(g_Weapons))
	
	give_item(id, g_Weapons[iWeaponNum[id]])
	cs_set_user_bpammo(id, g_WeaponID[iWeaponNum[id]], 255)
	
	give_item(id, "weapon_hegrenade")
	give_item(id, "weapon_flashbang")
	cs_set_user_bpammo(id, CSW_FLASHBANG, 2)
	give_item(id, "weapon_smokegrenade")
}
