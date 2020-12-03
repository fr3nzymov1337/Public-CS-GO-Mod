#include <amxmodx>
#include <cstrike>
#include <fakemeta>
#include <hamsandwich>
#if AMXX_VERSION_NUM < 183
	#include <colorchat>
#endif	

#define ACCESS_LEVEL_IMMUNITY (ADMIN_MENU|ADMIN_LEVEL_H) // Уровень доступа позволяющий беспрепятственно сидеть в зрителях
#define TIME_AFK_CHECK 15.0 // Интервал между проверками игроков, чем меньше значение, тем больше нагрузка на сервер.
#define MAX_AFK_WARNING 3 // Количество предупреждений после которых последует наказание.
#define TIME_SPECT_CHECK 60.0 // Интервал между проверками зрителей, чем меньше значение, тем больше нагрузка на сервер.
#define MAX_SPECT_CHECK_PL 2 // Количество проверок игрока на нахождение в зрителях, после которых его кикнет
#define MIN_PLAYERS_CHECK 30 // Минимальное количество игроков, когда включается функция проверки зрителей.
#define BOMB_TRANSFER // Передавать ли бомбу игрокам, если игрок AFK. [Закомментируйте, если хотите, чтобы бомба просто выкидывалась]
		      // !!! Включение прибавит чутка нагрузки !!!
#pragma semicolon 1

#define TASK_AFK_CHECK 139734

#define BIT_VALID(%1,%2) (%1 & (1 << (%2 & 31)))
#define BIT_ADD(%1,%2) %1 |= (1 << (%2 & 31))
#define BIT_SUB(%1,%2) %1 &= ~(1 << (%2 & 31))

new Float:g_fOldOrigin[33][3], Float:g_fOldAngles[33][3];
new g_iBitClientValid, g_iWarning[33];
new g_iMaxPlayers;
new g_count[33];
new name[32];

public plugin_init()
{
	register_plugin("[CS:GO MOD] AFK Control", "0.4.1", "Freedo.m | neygomon");
	RegisterHam(Ham_Spawn, "player", "Ham_PlayerSpawn_Post", 1);
	RegisterHam(Ham_Killed, "player", "Ham_PlayerKilled_Post", 1);
	g_iMaxPlayers = get_maxplayers();
	set_task(TIME_SPECT_CHECK, "SpectatorCheck", .flags = "b");
}

public client_putinserver(id)
{
	if(is_user_bot(id) || is_user_hltv(id)) return;
	BIT_ADD(g_iBitClientValid, id);
	g_count[id] = 0;
}

public client_disconnect(id)
{
	if(task_exists(id+TASK_AFK_CHECK)) remove_task(id+TASK_AFK_CHECK);
	BIT_SUB(g_iBitClientValid, id);
}	
	
public Ham_PlayerSpawn_Post(id)
{
	if(!is_user_alive(id)) return;
	g_iWarning[id] = 0;
	
	pev(id, pev_origin, g_fOldOrigin[id]);
	pev(id, pev_angles, g_fOldAngles[id]);
	
	if(task_exists(id+TASK_AFK_CHECK)) remove_task(id+TASK_AFK_CHECK);
	set_task(TIME_AFK_CHECK, "AfkCheck", id+TASK_AFK_CHECK, _, _, "b");
}

public Ham_PlayerKilled_Post(id) remove_task(id+TASK_AFK_CHECK);
	
public AfkCheck(id)
{	
	id -= TASK_AFK_CHECK;
	new Float:fNewOrigin[3], Float:fNewAngles[3];
	pev(id, pev_origin, fNewOrigin);
	pev(id, pev_angles, fNewAngles);
	if(xs_vec_equal(g_fOldOrigin[id], fNewOrigin) && xs_vec_equal(g_fOldAngles[id], fNewAngles))
	{	
		get_user_name(id, name, charsmax(name));
		
		if(++g_iWarning[id] >= MAX_AFK_WARNING)
		{
			user_kill(id, 1);
			engclient_cmd(id, "jointeam", "6");
			client_cmd(id, "spk events/friend_died");
			client_print_color(0, 0, "^1[^4CS:GO^1] Игрок %s был перемещен в зрители, так как был AFK", name);
		}
		else  client_cmd(id, "spk events/tutor_msg");
		client_print_color(id, 0, "^1[^4CS:GO^1] Вы не проявляете активность! Предупреждения: ^4%i/%i", g_iWarning[id], MAX_AFK_WARNING);
		
		if(user_has_weapon(id, CSW_C4))
		{
			engclient_cmd(id, "drop", "weapon_c4");
			client_print_color(0, 0, "^1[^4CS:GO^1] Игрок %s выкинул бомбу, так как находится AFK", name);
#if defined BOMB_TRANSFER		
			for(new i = 1; i <= g_iMaxPlayers; i++)
			{
				if(i != id && is_user_alive(i) && cs_get_user_team(i) == CS_TEAM_T)
				{
					new iWeaponC4 = engfunc(EngFunc_FindEntityByString, -1, "classname", "weapon_c4");
					if(pev_valid(iWeaponC4))
					{
						new iOwner = pev(iWeaponC4, pev_owner);
						if(iOwner > g_iMaxPlayers)
						{
							set_pev(iOwner, pev_flags, pev(iOwner, pev_flags) | FL_ONGROUND);
							dllfunc(DLLFunc_Touch, iOwner, i);
						}
					}
					break;
				}
			}
#endif			
		}
	}
	else
	{
		if(g_iWarning[id]) g_iWarning[id] = 0;
		xs_vec_copy(fNewOrigin, g_fOldOrigin[id]);
		xs_vec_copy(fNewAngles, g_fOldAngles[id]);
	}
}

public SpectatorCheck()
{
	if(get_playersnum() < MIN_PLAYERS_CHECK) return;
	static i, iFlags;
	for(i=1; i < g_iMaxPlayers; i++)
	{
		if(BIT_VALID(g_iBitClientValid, i))
		{
			if(iFlags || (iFlags = get_user_flags(i) & ACCESS_LEVEL_IMMUNITY))
			{
				switch(_:cs_get_user_team(i)) 
				{
					case 3: if(++g_count[i] >= MAX_SPECT_CHECK_PL) AfkPunishment(i);
				}	
			}
		}
	}
}

public AfkPunishment(i)
{
	get_user_name(i, name, charsmax(name));
	client_print_color(0, 0, "^1[^4CS:GOl^1] Игрок^3 %s ^1удален за длительное нахождение в спектрах.", name);
	server_cmd("kick #%d ^"Вы были кикнуты из-за длительного нахождения в зрителях.^"", get_user_userid(i));
}	
	
stock bool:xs_vec_equal(const Float:vec1[], const Float:vec2[])
	return (vec1[0] == vec2[0]) && (vec1[1] == vec2[1]) && (vec1[2] == vec2[2]);

stock xs_vec_copy(const Float:vecIn[], Float:vecOut[])
{
	vecOut[0] = vecIn[0];
	vecOut[1] = vecIn[1];
	vecOut[2] = vecIn[2];
}
