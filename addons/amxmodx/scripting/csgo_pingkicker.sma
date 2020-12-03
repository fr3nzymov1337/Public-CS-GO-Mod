#include <amxmodx>

#define ACCESS_LEVEL_IMMUNITY 	(ADMIN_MENU|ADMIN_LEVEL_H)	 // Уровень доступа позволяющий пропускать проверку на пинг.
#define MAX_ALLOWED_PING 	100				 // Максимально допустимый пинг, превышение этого значения выкидывает игрока с сервера.
#define MAX_FLUX		30			// Максимальные скачки пинга, если привышение то выкидывает с сервера
#define MAX_ALLOWED_LOSS 	20 			// Максимально допустимая потеря пакетов loss, превышение этого значения выкидывает игрока с сервера.
#define MAX_WARNING_CHECK 	5			// Количество предупреждений после которых последует наказание.
#define INTERVAL_CHECK 		10.0 			// Интервал между проверками, чем меньше значение, тем больше нагрузка на сервер.
#define CHECK_COUNT 		MAX_WARNING_CHECK + 3 	// Количество проверок определенного игрока ( снижаем и без того маленькую нагрузку xD )

#define is_immunity(%0) ((get_user_flags(%0) & ACCESS_LEVEL_IMMUNITY) || is_user_bot(%0) || is_user_hltv(%0))

#define	get_bit(%1,%2)	(%1 & (1 << (%2 & 31)))
#define	set_bit(%1,%2)	%1 |= (1 << (%2 & 31))
#define	clr_bit(%1,%2)	%1 &= ~(1 << (%2 & 31))

new g_iWarning[33], g_iCountCheck[33], g_iLastPing[33], g_iBitValid;

public plugin_init()
{
	register_plugin("[CS:GO MOD] Ping Kicker", "1.31", "neugomon");
	set_task(INTERVAL_CHECK, "PingCheck", .flags = "b");
}

public client_putinserver(id)
{
	if(is_immunity(id)) return;
	set_bit(g_iBitValid, id);
	g_iWarning[id] = g_iCountCheck[id] = 0;
}

public client_disconnect(id)
	clr_bit(g_iBitValid, id);

public PingCheck()
{
	static i, iPing, iLoss, players[32], pcount;
	get_players(players, pcount, "ch")
	
	for(i=0; i < pcount; i++)
	{
		if(!get_bit(g_iBitValid, players[i])) continue;
		if(++g_iCountCheck[players[i]] < CHECK_COUNT)
		{
			get_user_ping(players[i], iPing, iLoss)
			
			if(iPing >= MAX_ALLOWED_PING || iLoss > MAX_ALLOWED_LOSS || abs(iPing - g_iLastPing[players[i]]) > MAX_FLUX) 
			{
				if(++g_iWarning[players[i]] >= MAX_WARNING_CHECK)
				{					
					static name[32]; get_user_name(players[i], name, charsmax(name));
					ChatColor("^1[^4CS:GO^1] ^3%s ^1был удален с сервера за плохое соединение!", name);
					server_cmd("kick #%d ^"Вы были кикнуты из-за плохого соединения^"", get_user_userid(players[i]));
				}
			}
			else if(g_iWarning[players[i]]) g_iWarning[players[i]]--;
			g_iLastPing[players[i]] = iPing;	
		}
	}
}

stock ChatColor(const szMessage[], any:...)
{
	static pnum, players[32], szMsg[190], IdMsg; 
	vformat(szMsg, charsmax(szMsg), szMessage, 2);
	
	if(!IdMsg) IdMsg = get_user_msgid("SayText");
	
	get_players(players, pnum, "ch");
	
	for(new i; i < pnum; i++)
	{
		message_begin(MSG_ONE, IdMsg, .player = players[i]);
		write_byte(players[i]);
		write_string(szMsg);
		message_end();
	}
}
