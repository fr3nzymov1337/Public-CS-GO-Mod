#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>

#define is_user_valid(%0)		(%0 && %0 < g_iMaxPlayers)
#define MAXPLAYERS				32
#define MAXLENGTH				28
#define linux_diff_player		5
#define m_iTeam 				114
#define m_iDeaths				444

#define DAMAGE_FOR_ASSIST		70 	// Сколько процентов урона от хп надо нанести игроку, чтобы засчитало помощь в убийстве
#define MONEY_FOR_ASSIST		300	// Сколько денег платить игроку, совершившему помощь в убийстве. Если сумма меньше или равна нулю, то тогда оплаты не будет.
#define FRAGS_FOR_ASSIST			// Объявите, чтобы игроку, помогшему в убийстве начислялся фраг 
//#define FFA						// Объявите, если Ваш сервер использует FFA режим.
//#define HLTV_FIX					// Объявие, если Ваш сервер использует HLTV прокси.

#if MONEY_FOR_ASSIST > 0
	#define MAXMONEY			16000 // Максимальное количество денег, при котором помощник по убийству больше не будет получать денежное вознаграждение
	#include <cstrike>
#endif

//#define DEBUG

#if AMXX_VERSION_NUM < 183
	#define client_disconnected client_disconnect
#endif

enum _:PLAYER_DATA
{
	DAMAGE_ON[MAXPLAYERS + 1],
	ASSISTANT_NAME[32],
	ASSISTANT,
	MAXHEALTH,
	CONNECTED,
	TEAM
}

new g_ePlayerData[MAXPLAYERS + 1][PLAYER_DATA], g_iMaxPlayers, HamHook:g_pHamSpawnPost

public plugin_init()
{
	register_plugin("[CS:GO MOD] Kill Assist", "0.9", "Spection")
	RegisterHam(Ham_TakeDamage, "player", "Ham_PlayerTakeDamage_Pre", false)
	RegisterHam(Ham_Killed, "player", "Ham_PlayerKilled_Pre", false)
	DisableHamForward((g_pHamSpawnPost = RegisterHam(Ham_Killed, "player", "Ham_PlayerKilled_Post", true)))
	RegisterHam(Ham_Spawn, "player", "Ham_PlayerSpawn_Post", true)
	
	register_event("HLTV", "Event_HLTV", "a", "1=0", "2=0")
	
	#if defined DEBUG
		register_clcmd("assist", "ClCmd_Assist")
	#endif
	g_iMaxPlayers = get_maxplayers() + 1
} 

public Event_HLTV()
{
	for(new i = 1; i < g_iMaxPlayers; i++)
	{
		if(g_ePlayerData[i][CONNECTED])
		{
			g_ePlayerData[i][ASSISTANT] = 0
			arrayset(g_ePlayerData[i][DAMAGE_ON], 0, MAXPLAYERS + 1)
			g_ePlayerData[i][ASSISTANT_NAME] = ""
		}
	}
}

public client_putinserver(id) g_ePlayerData[id][CONNECTED] = true

public client_disconnected(id) 
{
	g_ePlayerData[id][ASSISTANT] = 0
	arrayset(g_ePlayerData[id][DAMAGE_ON], 0, MAXPLAYERS + 1)
	g_ePlayerData[id][ASSISTANT_NAME] = ""
	g_ePlayerData[id][CONNECTED] = false
}

public Ham_PlayerSpawn_Post(id) 
{
	#if !defined FFA
		g_ePlayerData[id][TEAM] = get_pdata_int(id, m_iTeam, linux_diff_player)
	#endif
	g_ePlayerData[id][MAXHEALTH] = pev(id, pev_health) 
	g_ePlayerData[id][ASSISTANT] = 0
	g_ePlayerData[id][ASSISTANT_NAME] = ""
}
	
public Ham_PlayerKilled_Pre(iVictim, iKiller)
{
	if(g_ePlayerData[g_ePlayerData[iVictim][ASSISTANT]][CONNECTED]) g_ePlayerData[g_ePlayerData[iVictim][ASSISTANT]][DAMAGE_ON][iVictim] = 0
	if(!is_user_valid(iKiller)) return HAM_IGNORED
	g_ePlayerData[iKiller][DAMAGE_ON][iVictim] = 0
	if(iKiller == g_ePlayerData[iVictim][ASSISTANT] || iKiller == iVictim || !g_ePlayerData[iVictim][ASSISTANT_NAME][0]) return HAM_IGNORED
	
	static szBuffer[64], szName[32], iLen[2]
	get_user_name(iKiller, szName, charsmax(szName))
	iLen[0] = strlen(szName)
	iLen[1] = strlen(g_ePlayerData[iVictim][ASSISTANT_NAME])
	if(iLen[0] > MAXLENGTH / 2)
	{
		if(iLen[1] > MAXLENGTH / 2)
		{
			if(iLen[0] - MAXLENGTH / 2 > 1)
			{
				if(iLen[1] - MAXLENGTH / 2 > 1)
				{
					strclip(szName, charsmax(szName), MAXLENGTH / 2)
					strclip(g_ePlayerData[iVictim][ASSISTANT_NAME], 31, MAXLENGTH / 2)
				}
				else strclip(szName, charsmax(szName), MAXLENGTH / 2 - (iLen[1] - MAXLENGTH / 2))
			}
			else strclip(g_ePlayerData[iVictim][ASSISTANT_NAME], 31, MAXLENGTH / 2 - (iLen[0] - MAXLENGTH / 2))
		}
		else strclip(szName, charsmax(szName), MAXLENGTH - iLen[1])	
	}
	else if(iLen[1] > MAXLENGTH / 2) strclip(g_ePlayerData[iVictim][ASSISTANT_NAME], 31, MAXLENGTH - iLen[0])
	
	formatex(szBuffer, charsmax(szBuffer), "%s + %s", szName, g_ePlayerData[iVictim][ASSISTANT_NAME])
	
	if(g_ePlayerData[g_ePlayerData[iVictim][ASSISTANT]][CONNECTED]) 
	{	
	#if MONEY_FOR_ASSIST > 0 
		cs_set_user_money(g_ePlayerData[iVictim][ASSISTANT], min(cs_get_user_money(g_ePlayerData[iVictim][ASSISTANT]) + MONEY_FOR_ASSIST, MAXMONEY))
	#endif
	
	#if defined FRAGS_FOR_ASSIST
		set_pev(g_ePlayerData[iVictim][ASSISTANT], pev_frags, float(pev(g_ePlayerData[iVictim][ASSISTANT], pev_frags) + 1))
		static iMsgScoreInfo 
		if(!iMsgScoreInfo) iMsgScoreInfo = get_user_msgid("ScoreInfo")
		message_begin(MSG_ALL, iMsgScoreInfo)
		write_byte(g_ePlayerData[iVictim][ASSISTANT])
		write_short(pev(g_ePlayerData[iVictim][ASSISTANT], pev_frags))
		write_short(get_pdata_int(g_ePlayerData[iVictim][ASSISTANT], m_iDeaths, linux_diff_player))
		write_short(0)
		write_short(g_ePlayerData[g_ePlayerData[iVictim][ASSISTANT]][TEAM])
		message_end();
	#endif
	}
	g_ePlayerData[iVictim][ASSISTANT] = 0
	set_user_fake_name(iKiller, szBuffer)
	EnableHamForward(g_pHamSpawnPost)
	return HAM_IGNORED
}

public Ham_PlayerKilled_Post(iVictim, iKiller)
{
	DisableHamForward(g_pHamSpawnPost)
	#if AMXX_VERSION_NUM >= 183 && defined HLTV_FIX
		set_task(0.1, "task_resetinfo", iKiller + 64)
	#else
		reset_user_info(iKiller)
	#endif
}

#if AMXX_VERSION_NUM >= 183 && defined HLTV_FIX
public task_resetinfo(id) reset_user_info(id - 64)
#endif

public Ham_PlayerTakeDamage_Pre(iVictim, iWeapon, iAttacker, Float:fDamage)
{
	if(!is_user_valid(iAttacker) || iVictim == iAttacker) return HAM_IGNORED
	#if !defined FFA
		if(g_ePlayerData[iVictim][TEAM] == g_ePlayerData[iAttacker][TEAM]) return HAM_IGNORED
	#endif
	g_ePlayerData[iAttacker][DAMAGE_ON][iVictim] += floatround(fDamage)
	if(g_ePlayerData[iAttacker][DAMAGE_ON][iVictim] >= (float(g_ePlayerData[iVictim][MAXHEALTH]) * (DAMAGE_FOR_ASSIST.0 / 100.0)) && !g_ePlayerData[iVictim][ASSISTANT])
	{
		get_user_name(iAttacker, g_ePlayerData[iVictim][ASSISTANT_NAME], 31)
		g_ePlayerData[iVictim][ASSISTANT] = iAttacker
	}
	return HAM_IGNORED
}

stock reset_user_info(id)
{
	new szUserInfo[256]
	copy_infokey_buffer(engfunc(EngFunc_GetInfoKeyBuffer, id), szUserInfo, charsmax(szUserInfo))
	#if defined HLTV_FIX
	for(new i = 1; i < g_iMaxPlayers; i++)
	{
		if(!is_user_hltv(i) && g_ePlayerData[i][CONNECTED])
		{
			message_begin(MSG_ONE, SVC_UPDATEUSERINFO, _, i)
	#else
			message_begin(MSG_ALL, SVC_UPDATEUSERINFO)
	#endif
			write_byte(id - 1)
			write_long(get_user_userid(id))
			write_string(szUserInfo)
			write_long(0)
			write_long(0)
			write_long(0)
			write_long(0)
			message_end()
	#if defined HLTV_FIX
		}
	}
	#endif
}

stock set_user_fake_name(const id, const name[])
{
	#if defined HLTV_FIX
	for(new i = 1; i < g_iMaxPlayers; i++)
	{
		if(!is_user_hltv(i) && g_ePlayerData[i][CONNECTED])
		{
			message_begin(MSG_ONE, SVC_UPDATEUSERINFO, _, i)
	#else
			message_begin(MSG_ALL, SVC_UPDATEUSERINFO)
	#endif
			write_byte(id - 1)
			write_long(get_user_userid(id))
			write_char('\')
			write_char('n')
			write_char('a')
			write_char('m')
			write_char('e')
			write_char('\')
			write_string(name)
			for(new i; i < 16; i++) write_byte(0)
			message_end()
	#if defined HLTV_FIX
		}
	}
	#endif
}

stock strclip(szString[], iSize, iClip)
{
	copy(szString, iClip - 2, szString)
	add(szString, iSize, "..")
}

#if defined DEBUG
public ClCmd_Assist()
{
	new id[3], szArg[64]
	for(new i; i < 3; i++)
	{
		read_argv(i + 1, szArg, charsmax(szArg))
		id[i] = str_to_num(szArg)
	}
	g_ePlayerData[id[2]][ASSISTANT] = id[1]
	get_user_name(id[1], g_ePlayerData[id[2]][ASSISTANT_NAME], 31)
	ExecuteHamB(Ham_Killed, id[2], id[0], 0)
}
#endif