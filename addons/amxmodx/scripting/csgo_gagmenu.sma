#include <amxmodx>
#include <amxmisc>
#include <engine>

#define DEFAULT_TIME 600.0 		// In Seconds
#define ADMIN_FLAG ADMIN_RESERVATION	// flag adm

enum ( <<= 1 ) {
	GAG_CHAT = 1,
	GAG_TEAMSAY,
	GAG_VOICE
};

enum _:GagData {
	GAG_AUTHID[ 35 ],
	GAG_TIME,
	GAG_START,
	GAG_FLAGS
};

new g_szAuthid[ 33 ][ 35 ]; // STEAM_0:X:XXXXXXXX
new g_iThinker, g_iGagged;
new bool:g_bColoredMenus, Trie:g_tArrayPos, Array:g_aGagData, Array:g_aGagTimes, g_iTotalGagTimes;
new g_iMenuOption[ 33 ], g_iMenuPosition[ 33 ], g_iMenuPlayers[ 33 ][ 32 ], g_iMenuFlags[ 33 ];

public plugin_init( ) {
	register_plugin( "[CS:GO MOD] AMXX GAG", "1.3", "xPaw & Exolent" );
	
	register_clcmd( "say",        "CmdSay" );
	register_clcmd( "say_team",   "CmdTeamSay" );
	
	register_concmd( "amx_gag",       "CmdGagPlayer",   ADMIN_KICK, "<nick or #userid> <time> <a|b|c>" );
	register_concmd( "amx_ungag",     "CmdUnGagPlayer", ADMIN_KICK, "<nick or #userid>" );
	register_concmd( "amx_gagmenu",   "CmdGagMenu",     ADMIN_KICK, "- displays gag menu" );
	register_srvcmd( "amx_gag_times", "CmdSetBanTimes" );
	
	register_menu( "Gag Menu", 1023, "ActionGagMenu" );
	register_menu( "Gag Flags", 1023, "ActionGagFlags" );
	register_message( get_user_msgid( "SayText" ), "MessageSayText" );
	
	g_tArrayPos = TrieCreate( );
	g_aGagData  = ArrayCreate( GagData );
	g_aGagTimes = ArrayCreate( );
	g_bColoredMenus = bool:colored_menus( );
	
	// this is used for ungag in the menu
	ArrayPushCell( g_aGagTimes, 0 );
	
	// Gag times for the gag menu (amx_gagmenu)
	// Default values: 60 300 600 1800 3600 7200 86400
	
	// Load up standart times
	ArrayPushCell( g_aGagTimes, 60 );
	ArrayPushCell( g_aGagTimes, 300 );
	ArrayPushCell( g_aGagTimes, 600 );
	ArrayPushCell( g_aGagTimes, 1800 );
	ArrayPushCell( g_aGagTimes, 3600 );
	ArrayPushCell( g_aGagTimes, 7200 );
	ArrayPushCell( g_aGagTimes, 86400 );
	
	g_iTotalGagTimes = ArraySize( g_aGagTimes );
	
	// Set up entity-thinker
	new const szClassname[ ] = "gag_thinker";
	
	g_iThinker = create_entity( "info_target" );
	entity_set_string( g_iThinker, EV_SZ_classname, szClassname );
	
	register_think( szClassname, "FwdThink" );
}

public CmdSetBanTimes( ) {
	new iArgs = read_argc( );
	
	if( iArgs <= 1 ) {
		server_print( "Usage: amx_gag_times <time1> [time2] [time3] ..." );
		
		return PLUGIN_HANDLED;
	}
	
	ArrayClear( g_aGagTimes );
	
	// this is used for ungag in the menu
	ArrayPushCell( g_aGagTimes, 0 );
	
	new szBuffer[ 32 ], iTime;
	for( new i = 1; i < iArgs; i++ ) {
		read_argv( i, szBuffer, 31 );
		
		if( !is_str_num( szBuffer ) ) {
			server_print( "* Время должно быть целым!" );
			
			continue;
		}
		
		iTime = str_to_num( szBuffer );
		
		if( iTime <= 0 ) {
			server_print( "* Время должно быть больше 0!" );
			
			continue;
		}
		
		if( iTime > 86400 ) {
			server_print( "* Время более 86400 не допустимо!" );
			
			continue;
		}
		
		ArrayPushCell( g_aGagTimes, iTime );
	}
	
	g_iTotalGagTimes = ArraySize( g_aGagTimes );
	
	return PLUGIN_HANDLED;
}

public plugin_end( ) {
	TrieDestroy( g_tArrayPos );
	ArrayDestroy( g_aGagData );
	ArrayDestroy( g_aGagTimes );
}

public client_putinserver( id ) {
	if( CheckGagFlag( id, GAG_VOICE ) )
		set_speak( id, SPEAK_MUTED );
	
	// default flags to "abc"
	g_iMenuFlags[ id ] = GAG_CHAT | GAG_TEAMSAY | GAG_VOICE;
}

public client_authorized( id )
	get_user_authid( id, g_szAuthid[ id ], 34 );

public client_disconnect( id ) {
	if( TrieKeyExists( g_tArrayPos, g_szAuthid[ id ] ) ) {
		new szName[ 32 ];
		get_user_name( id, szName, 31 );
		
		new iPlayers[ 32 ], iNum, iPlayer;
		get_players( iPlayers, iNum, "ch" );
		
		for( new i; i < iNum; i++ ) {
			iPlayer = iPlayers[ i ];
			
			if( get_user_flags( iPlayer ) & ADMIN_FLAG )
				client_print( iPlayer, print_chat, "* Заткнутый игрок ^"%s<%s>^" отсоединился! *", szName, g_szAuthid[ id ] );
		}
	}
	
	g_szAuthid[ id ][ 0 ] = '^0';
}

public client_infochanged( id ) {
	if( !CheckGagFlag( id, ( GAG_CHAT | GAG_TEAMSAY ) ) )
		return;
	
	static const name[ ] = "name";
	
	static szNewName[ 32 ], szOldName[ 32 ];
	get_user_info( id, name, szNewName, 31 );
	get_user_name( id, szOldName, 31 );
	
	if( !equal( szNewName, szOldName ) ) {
		client_print( id, print_chat, "* Заткнутые игроки не могут менять имя! *" );
		
		set_user_info( id, name, szOldName );
	}
}

public MessageSayText( ) {
	static const Cstrike_Name_Change[ ] = "#Cstrike_Name_Change";
	
	new szMessage[ sizeof( Cstrike_Name_Change ) + 1 ];
	get_msg_arg_string( 2, szMessage, sizeof( szMessage ) - 1 );
	
	if( equal( szMessage, Cstrike_Name_Change ) ) {
		new szName[ 32 ], id;
		for( new i = 3; i <= 4; i++ ) {
			get_msg_arg_string( i, szName, 31 );
			
			id = get_user_index( szName );
			
			if( is_user_connected( id ) ) {
				if( CheckGagFlag( id, ( GAG_CHAT | GAG_TEAMSAY ) ) )
					return PLUGIN_HANDLED;
				
				break;
			}
		}
	}
	
	return PLUGIN_CONTINUE;
}

public FwdThink( const iEntity ) {
	if( !g_iGagged )
		return;
	
	new Float:fGametime;
	fGametime = get_gametime( );
	
	new data[ GagData ], id, szName[ 32 ];
	for( new i = 0; i < g_iGagged; i++ ) {
		ArrayGetArray( g_aGagData, i, data );
		
		if( ( Float:data[ GAG_START ] + Float:data[ GAG_TIME ] - 0.5 ) <= fGametime ) {
			id = find_player( "c", data[ GAG_AUTHID ] );
			
			if( is_user_connected( id ) ) {
				get_user_name( id, szName, 31 );
				
				client_print( 0, print_chat, "* Игрок ^"%s^" теперь без кляпа *", szName );
			}
			
			DeleteGag( i );
			
			i--;
		}
	}
	
	if( !g_iGagged )
		return;
	
	new Float:flNextTime = 999999.9;
	for( new i = 0; i < g_iGagged; i++ ) {
		ArrayGetArray( g_aGagData, i, data );
		
		flNextTime = floatmin( flNextTime, Float:data[ GAG_START ] + Float:data[ GAG_TIME ] );
	}
	
	entity_set_float( iEntity, EV_FL_nextthink, flNextTime );
}

public CmdSay( const id )
	return CheckSay( id, 0 );

public CmdTeamSay( const id )
	return CheckSay( id, 1 );

CheckSay( const id, const bTeam ) {
	new iArrayPos;
	if( TrieGetCell( g_tArrayPos, g_szAuthid[ id ], iArrayPos ) ) {
		new data[ GagData ];
		ArrayGetArray( g_aGagData, iArrayPos, data );
		
		new const iFlags[ ] = { GAG_CHAT, GAG_TEAMSAY };
		
		if( data[ GAG_FLAGS ] & iFlags[ bTeam ] ) {
			new szInfo[ 32 ], iLen, iTime = floatround( ( Float:data[ GAG_START ] + Float:data[ GAG_TIME ] ) - get_gametime( ) ), iMinutes = iTime / 60, iSeconds = iTime % 60;
			
			if( iMinutes > 0 )
				iLen = formatex( szInfo, 31, "%i minute%s", iMinutes, iMinutes == 1 ? "" : "s" );
			if( iSeconds > 0 )
				formatex( szInfo[ iLen ], 31 - iLen, "%s%i second%s", iLen ? " and " : "", iSeconds, iSeconds == 1 ? "" : "s" );
			
			client_print( id, print_chat, "* %s осталось до снятия кляпа! *", szInfo );
			client_print( id, print_center, "* Вы заткнуты %s в чате! *", bTeam ? " team" : "" );
			
			return PLUGIN_HANDLED;
		}
	}
	
	return PLUGIN_CONTINUE;
}

public CmdGagPlayer( const id, const iLevel, const iCid ) {
	if( !cmd_access( id, iLevel, iCid, 2 ) ) {
		console_print( id, "* Пункты: a - Чат | b - Командный чат | c - Голосовое общение" );
		
		return PLUGIN_HANDLED;
	}
	
	new szArg[ 32 ];
	read_argv( 1, szArg, 31 );
	
	new iPlayer = cmd_target( id, szArg, CMDTARGET_OBEY_IMMUNITY | CMDTARGET_NO_BOTS );
	
	if( !iPlayer )
		return PLUGIN_HANDLED;
	
	new szName[ 20 ];
	get_user_name( iPlayer, szName, 19 );
	
	if( TrieKeyExists( g_tArrayPos, g_szAuthid[ iPlayer ] ) ) {
		console_print( id, "* Игрок ^"%s^" уже с кляпом! *", szName );
		
		return PLUGIN_HANDLED;
	}
	
	new szFlags[ 4 ], Float:flGagTime;
	read_argv( 2, szArg, 31 );
	
	if( !szArg[ 0 ] ) { // No time entered
		flGagTime = DEFAULT_TIME;
		
		formatex( szFlags, 3, "abc" );
		} else {
		if( is_str_num( szArg ) ) { // Seconds entered
			flGagTime = floatstr( szArg );
			
			if( flGagTime > 86400.0 )
				flGagTime = 86400.0;
			} else {
			console_print( id, "* Значение должно быть в секундах!" );
			
			return PLUGIN_HANDLED;
		}
		
		read_argv( 3, szArg, 31 );
		
		if( !szArg[ 0 ] ) // No flag entered
			formatex( szFlags, 3, "abc" );
		else
			formatex( szFlags, 3, szArg );
	}
	
	new iFlags = read_flags( szFlags );
	
	new data[ GagData ];
	data[ GAG_START ] = _:get_gametime( );
	data[ GAG_TIME ]  = _:flGagTime;
	data[ GAG_FLAGS ] = iFlags;
	copy( data[ GAG_AUTHID ], 34, g_szAuthid[ iPlayer ] );
	
	TrieSetCell( g_tArrayPos, g_szAuthid[ iPlayer ], g_iGagged );
	ArrayPushArray( g_aGagData, data );
	
	new szFrom[ 64 ];
	
	if( iFlags & GAG_CHAT )
		formatex( szFrom, 63, "say" );
	
	if( iFlags & GAG_TEAMSAY ) {
		if( !szFrom[ 0 ] )
			formatex( szFrom, 63, "say_team" );
		else
			format( szFrom, 63, "%s / say_team", szFrom );
	}
	
	if( iFlags & GAG_VOICE ) {
		set_speak( iPlayer, SPEAK_MUTED );
		
		if( !szFrom[ 0 ] )
			formatex( szFrom, 63, "voicecomm" );
		else
			format( szFrom, 63, "%s / voicecomm", szFrom );
	}
	
	g_iGagged++;
	
	new Float:flGametime = get_gametime( ), Float:flNextThink;
	flNextThink = entity_get_float( g_iThinker, EV_FL_nextthink );
	
	if( !flNextThink || flNextThink > ( flGametime + flGagTime ) )
		entity_set_float( g_iThinker, EV_FL_nextthink, flGametime + flGagTime );
	
	new szInfo[ 32 ], szAdmin[ 20 ], iTime = floatround( flGagTime ), iMinutes = iTime / 60, iSeconds = iTime % 60;
	get_user_name( id, szAdmin, 19 );
	
	if( !iMinutes )
		formatex( szInfo, 31, "%i second%s", iSeconds, iSeconds == 1 ? "" : "s" );
	else
		formatex( szInfo, 31, "%i minute%s", iMinutes, iMinutes == 1 ? "" : "s" );
	
	show_activity( id, szAdmin, "Заткнут %s за разговоры на %s! (%s)", szName, szInfo, szFrom );
	
	console_print( id, "Вы заткнуты ^"%s^" (%s) !", szName, szFrom );
	
	log_amx( "Gag: ^"%s<%s>^" has gagged ^"%s<%s>^" for %i minutes. (%s)", szAdmin, g_szAuthid[ id ], szName, g_szAuthid[ iPlayer ], floatround( flGagTime / 60 ), szFrom );
	
	return PLUGIN_HANDLED;
}

public CmdUnGagPlayer( const id, const iLevel, const iCid ) {
	if( !cmd_access( id, iLevel, iCid, 2 ) )
		return PLUGIN_HANDLED;
	
	new szArg[ 32 ];
	read_argv( 1, szArg, 31 );
	
	if( equali( szArg, "@all" ) ) {
		if( !g_iGagged ) {
			console_print( id, "Нету игроков с кляпом!" );
			
			return PLUGIN_HANDLED;
		}
		
		while( g_iGagged ) DeleteGag( 0 ); // Excellent by Exolent
		
		if( entity_get_float( g_iThinker, EV_FL_nextthink ) > 0.0 )
			entity_set_float( g_iThinker, EV_FL_nextthink, 0.0 );
		
		console_print( id, "Вы убрали кляп у всех игроков!" );
		
		new szAdmin[ 32 ];
		get_user_name( id, szAdmin, 31 );
		
		show_activity( id, szAdmin, "Снят кляп со всех игроков." );
		
		log_amx( "UnGag: ^"%s<%s>^" has ungagged all players.", szAdmin, g_szAuthid[ id ] );
		
		return PLUGIN_HANDLED;
	}
	
	new iPlayer = cmd_target( id, szArg, CMDTARGET_OBEY_IMMUNITY | CMDTARGET_NO_BOTS );
	
	if( !iPlayer )
		return PLUGIN_HANDLED;
	
	new szName[ 32 ];
	get_user_name( iPlayer, szName, 31 );
	
	new iArrayPos;
	if( !TrieGetCell( g_tArrayPos, g_szAuthid[ iPlayer ], iArrayPos ) ) {
		console_print( id, "Игрок ^"%s^" без кляпа!", szName );
		
		return PLUGIN_HANDLED;
	}
	
	DeleteGag( iArrayPos );
	
	new szAdmin[ 32 ];
	get_user_name( id, szAdmin, 31 );
	
	show_activity( id, szAdmin, "* Размолк %s.", szName );
	
	console_print( id, "* Вы сняли кляп^"%s^"!", szName );
	
	log_amx( "UnGag: ^"%s<%s>^" has ungagged ^"%s<%s>^"", szAdmin, g_szAuthid[ id ], szName, g_szAuthid[ iPlayer ] );
	
	return PLUGIN_HANDLED;
}

public CmdGagMenu( const id, const iLevel, const iCid ) {
	if( !cmd_access( id, iLevel, iCid, 1 ) )
		return PLUGIN_HANDLED;
	
	g_iMenuOption[ id ] = 0;
	arrayset( g_iMenuPlayers[ id ], 0, 32 );
	
	DisplayGagMenu( id, g_iMenuPosition[ id ] = 0 );
	
	return PLUGIN_HANDLED;
}

#define PERPAGE 6

public ActionGagMenu( const id, const iKey ) {
	switch( iKey ) {
		case 6: DisplayGagFlags( id );
			case 7: {
			++g_iMenuOption[ id ];
			g_iMenuOption[ id ] %= g_iTotalGagTimes;
			
			DisplayGagMenu( id, g_iMenuPosition[ id ] );
		}
		case 8: DisplayGagMenu( id, ++g_iMenuPosition[ id ] );
			case 9: DisplayGagMenu( id, --g_iMenuPosition[ id ] );
			default: {
			new iPlayer = g_iMenuPlayers[ id ][ g_iMenuPosition[ id ] * PERPAGE + iKey ];
			
			if( !g_iMenuOption[ id ] )
				client_cmd( id, "amx_ungag #%i", get_user_userid( iPlayer ) );
			else {
				new szFlags[ 4 ];
				get_flags( g_iMenuFlags[ id ], szFlags, 3 );
				
				client_cmd( id, "amx_gag #%i %i %s", get_user_userid( iPlayer ), ArrayGetCell( g_aGagTimes, g_iMenuOption[ id ] ), szFlags );
			}
			
			DisplayGagMenu( id, g_iMenuPosition[ id ] );
		}
	}
}

// I just copied this from AMXX Ban menu, so don't blame me :D
DisplayGagMenu( const id, iPosition ) {
	if( iPosition < 0 ) {
		arrayset( g_iMenuPlayers[ id ], 0, 32 );
		
		return;
	}
	
	new iPlayers[ 32 ], iNum, iCount, szMenu[ 512 ], iPlayer, iFlags, szName[ 32 ];
	get_players( iPlayers, iNum, "ch" ); // Ignore bots and hltv
	
	new iStart = iPosition * PERPAGE;
	
	if( iStart >= iNum )
		iStart = iPosition = g_iMenuPosition[ id ] = 0;
	
	new iEnd = iStart + PERPAGE, iKeys = MENU_KEY_0 | MENU_KEY_8;
	new iLen = formatex( szMenu, 511, g_bColoredMenus ? "\r[#] \yМеню кляпа\R\w%i/%i^n^n" : "\r[#] \yМеню кляпа \w%i/%i^n^n", iPosition + 1, ( ( iNum + PERPAGE - 1 ) / PERPAGE ) );
	
	new bool:bUngag = bool:!g_iMenuOption[ id ];
	
	if( iEnd > iNum ) iEnd = iNum;
	
	for( new i = iStart; i < iEnd; ++i ) {
		iPlayer = iPlayers[ i ];
		iFlags  = get_user_flags( iPlayer );
		get_user_name( iPlayer, szName, 31 );
		
		if( iPlayer == id || ( iFlags & ADMIN_IMMUNITY ) || bUngag != TrieKeyExists( g_tArrayPos, g_szAuthid[ iPlayer ] ) ) {
			++iCount;
			
			if( g_bColoredMenus )
				iLen += formatex( szMenu[ iLen ], 511 - iLen, "\d[%i] %s^n", iCount, szName );
			else
				iLen += formatex( szMenu[ iLen ], 511 - iLen, "[#] %s^n", szName );
			} else {
			iKeys |= ( 1 << iCount );
			++iCount;
			
			iLen += formatex( szMenu[ iLen ], 511 - iLen, g_bColoredMenus ? "\r[%i] \w %s\y%s\r%s^n" : "[%i] %s%s%s^n", iCount, szName, TrieKeyExists( g_tArrayPos, g_szAuthid[ iPlayer ] ) ? " GAGGED" : "", ( ~iFlags & ADMIN_USER ? " *" : "" ) );
		}
	}
	
	g_iMenuPlayers[ id ] = iPlayers;
	
	new szFlags[ 4 ];
	get_flags( g_iMenuFlags[ id ], szFlags, 3 );
	
	iLen += formatex( szMenu[ iLen ], 511 - iLen, g_bColoredMenus ? ( bUngag ? "^n\d[7] Пункты: %s" : "^n\r[7]\y Пункты:\w %s" ) : ( bUngag ? "^n[#] Пункты: %s" : "^n[7] Пункты: %s" ), szFlags );
	
	if( !bUngag )
	{
		iKeys |= MENU_KEY_7;
		
		new iSeconds = ArrayGetCell( g_aGagTimes, g_iMenuOption[ id ] );
		new iTime    = iSeconds / 60;
		
		iLen += formatex( szMenu[ iLen ], 511 - iLen, g_bColoredMenus ? "^n\r[8]\y Время:\w %i %s^n" : "^n[8] Кляп на %i %s^n", ( iSeconds > 60 ? iTime : iSeconds ), ( iSeconds > 60 ? "минут" : "секунд" ) );
	}
	else
		iLen += copy( szMenu[ iLen ], 511 - iLen, g_bColoredMenus ? "^n\r[8]\w Убрать кляп^n" : "^n[8] Убрать кляп^n" );
	
	if( iEnd != iNum ) {
		formatex( szMenu[ iLen ], 511 - iLen, g_bColoredMenus ? "^n\r[9]\w Далее...^n\r[0]\w %s" : "^n[9] Далее...^n[0] %s", iPosition ? "Назад" : "Выход" );
		iKeys |= MENU_KEY_9;
	} else
	formatex( szMenu[ iLen ], 511 - iLen, g_bColoredMenus ? "^n\r[0]\y %s" : "^n[0] %s", iPosition ? "Назад" : "Выход" );
	
	show_menu( id, iKeys, szMenu, -1, "Gag Menu" );
}

public ActionGagFlags( const id, const iKey ) {
	switch( iKey ) {
		case 9: DisplayGagMenu( id, g_iMenuPosition[ id ] );
			default: {
			g_iMenuFlags[ id ] ^= ( 1 << iKey );
			
			DisplayGagFlags( id );
		}
	}
}

DisplayGagFlags( const id ) {
	new szMenu[ 512 ];
	new iLen = copy( szMenu, 511, g_bColoredMenus ? "\r[#] \yПункты кляпа^n^n" : "Gag Flags^n^n" );
	
	if( g_bColoredMenus ) {
		iLen += formatex( szMenu[ iLen ], 511 - iLen, "\r[1]\w Чат: \y%s^n", ( g_iMenuFlags[ id ] & GAG_CHAT ) ? "[+]" : "[-]" );
		iLen += formatex( szMenu[ iLen ], 511 - iLen, "\r[2]\w Командный чат: \y%s^n", ( g_iMenuFlags[ id ] & GAG_TEAMSAY ) ? "[+]" : "[-]" );
		iLen += formatex( szMenu[ iLen ], 511 - iLen, "\r[3]\w Голос: \y%s^n", ( g_iMenuFlags[ id ] & GAG_VOICE ) ? "[+]" : "[-]" );
		} else {
		iLen += formatex( szMenu[ iLen ], 511 - iLen, "[1] Чат: %s^n", ( g_iMenuFlags[ id ] & GAG_CHAT ) ? "[+]" : "[-]" );
		iLen += formatex( szMenu[ iLen ], 511 - iLen, "[2] Командный чат: \y%s^n", ( g_iMenuFlags[ id ] & GAG_TEAMSAY ) ? "[+]" : "[-]" );
		iLen += formatex( szMenu[ iLen ], 511 - iLen, "[3] Голос: %s^n", ( g_iMenuFlags[ id ] & GAG_VOICE ) ? "[+]" : "[-]" );
	}
	
	copy( szMenu[ iLen ], 511 - iLen, g_bColoredMenus ? "^n\r[0] \wНазад" : "^n[0] Назад" );
	
	show_menu( id, ( MENU_KEY_1 | MENU_KEY_2 | MENU_KEY_3 | MENU_KEY_0 ), szMenu, -1, "Gag Flags" );
}

CheckGagFlag( const id, const iFlag ) {
	new iArrayPos;
	
	if( TrieGetCell( g_tArrayPos, g_szAuthid[ id ], iArrayPos ) ) {
		new data[ GagData ];
		ArrayGetArray( g_aGagData, iArrayPos, data );
		
		return ( data[ GAG_FLAGS ] & iFlag );
	}
	
	return 0;
}

DeleteGag( const iArrayPos ) {
	new data[ GagData ];
	ArrayGetArray( g_aGagData, iArrayPos, data );
	
	if( data[ GAG_FLAGS ] & GAG_VOICE ) {
		new iPlayer = find_player( "c", data[ GAG_AUTHID ] );
		if( is_user_connected( iPlayer ) )
			set_speak( iPlayer, SPEAK_NORMAL );
	}
	
	TrieDeleteKey( g_tArrayPos, data[ GAG_AUTHID ] );
	ArrayDeleteItem( g_aGagData, iArrayPos );
	g_iGagged--;
	
	for( new i = iArrayPos; i < g_iGagged; i++ ) {
		ArrayGetArray( g_aGagData, i, data );
		TrieSetCell( g_tArrayPos, data[ GAG_AUTHID ], i );
	}
}