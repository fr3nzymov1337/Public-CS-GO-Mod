// #define MONEY_UL 1
#if defined MONEY_UL
	#include <money_ul> 
#endif // MONEY_UL 

#define PLUGIN "[CS:GO MOD] BuyMenu"
#define VERSION "2.0"
#define AUTHOR "Danakt Frost"

#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <cstrike>
#include <fakemeta>
#include <hamsandwich>
#include <fun>
#include <nvault>

#define FILE_NAME "csgo/csgo_buymenu"
#define FILE_FORMAT "ini"

#define ADD_BMM 1
#define ADD_ZP 2
#define ADD_CMD 3

#define XTRA_OFS_PLAYER 5
#define m_rgAmmo_Slot0 376

enum{
	BMM_PISTOLS = 1, 
	BMM_SHOTGUNS, 
	BMM_SMG, 
	BMM_RIFLES, 
	BMM_MACHINEGUNS ,	
	BMM_EQUIP, 
	BMM_UNCATEGORIZED
}

const BMM_TEAM_NO_ONE = 0; 
const BMM_TEAM_ANY = 0; 
const BMM_TEAM_ALL = ( 1<<1 );
const BMM_TEAM_T = ( 2<<4 );
const BMM_TEAM_CT = ( 2<<5 );

new g_szTitles[ 8 ][ ] = {
	"", //0
	"BMM_PISTOLS", 
	"BMM_SHOTGUNS", 
	"BMM_SMG", 
	"BMM_RIFLES", 
	"BMM_MACHINEGUNS", 
	"BMM_EQUIP", 
	"BMM_UNCATEGORIZED"
}

enum _:AmmoDatas
{
	Amount,
	Cost,
	Max
}

enum _:AmmoIds
{
	ammo_none,
	ammo_338magnum = 1,
	ammo_762nato,
	ammo_556natobox,
	ammo_556nato,
	ammo_buckshot,
	ammo_45acp,
	ammo_57mm,
	ammo_50ae,
	ammo_357sig,
	ammo_9mm
}

enum _:WeaponType
{
	Primary,
	Secondary
}

new const g_iAmmoWeaponSharedBitSum[AmmoIds][WeaponType] = {
	{0, 0},
	{( 1<<CSW_AWP ), 0},
	{( 1<<CSW_SCOUT | 1<<CSW_G3SG1 | 1<<CSW_AK47 ), 0},
	{( 1<<CSW_M249 ), 0},
	{( 1<<CSW_AUG | 1<<CSW_SG550 | 1<<CSW_GALIL | 1<<CSW_FAMAS | 1<<CSW_M4A1 | 1<<CSW_SG552 ), 0},
	{( 1<<CSW_XM1014 | 1<<CSW_M3 ), 0},
	{( 1<<CSW_MAC10 | 1<<CSW_UMP45), (1<<CSW_USP )},
	{( 1<<CSW_P90 ), ( 1<<CSW_FIVESEVEN )},
	{0, ( 1<<CSW_DEAGLE )},
	{0, ( 1<<CSW_P228 )},
	{( 1<<CSW_MP5NAVY | 1<<CSW_TMP), (1<<CSW_ELITE | 1<<CSW_GLOCK18 )}
}

new const g_szAmmoNames[AmmoIds][] = {
	"",
	"338magnum",
	"762nato",
	"556natobox",
	"556nato",
	"buckshot",
	"45acp",
	"57mm",
	"50ae",
	"357sig",
	"9mm"
}

new g_iAmmoDatas[AmmoIds][AmmoDatas] = {
	{-1,  -1,  -1},
	{10, 125,  30}, // 338magnum
	{30,  80,  90}, // 762nato
	{30,  60, 200}, // 556natobox
	{30,  60,  90}, // 556nato
	{ 8,  65,  32}, // buckshot
	{12,  25, 100}, // 45acp
	{50,  50, 100}, // 57mm
	{ 7,  40,  35}, // 50ae
	{13,  50,  52}, // 357sig
	{30,  20, 120}  // 9mm
}

// Words for remove from names of items
new const g_szToreplace[ ][ ] = {"\r", "\w", "[CSO] ", "[Rifle] ", "[Sn. Rifle] ", "[Sniper Rifle] ", "[Machinegun] ", "[Automat] ", "[Pistol] ", "[", "]", '^"' };

// Disabling ZP natives is produced to maintain Extra Items without Zombie Plague Mod.
new const g_native_name[][] = { "zp_get_user_zombie", "zp_get_user_nemesis", "zp_get_user_survivor", "_get_user_survivor", "zp_get_user_first_zombie", "zp_get_user_last_zombie", "zp_get_user_last_human", 
"zp_get_user_zombie_class", "zp_get_user_next_class", "zp_set_user_zombie_class", "zp_get_user_ammo_packs", "zp_set_user_ammo_packs", "zp_get_zombie_maxhealth", "zp_get_user_batteries", 
"zp_set_user_batteries", "zp_get_user_nightvision", "zp_set_user_nightvision", "zp_infect_user", "zp_disinfect_user", "zp_make_user_nemesis", "zp_make_user_survivor", "zp_respawn_user", 
"zp_force_buy_extra_item", "zp_override_user_model", "zp_has_round_started", "zp_is_nemesis_round", "zp_is_survivor_round", "zp_is_swarm_round", "zp_is_plague_round", "zp_get_zombie_count", 
"zp_get_human_count", "zp_get_nemesis_count", "zp_get_survivor_count", "zp_register_zombie_class", "zp_get_extra_item_id", "zp_get_zombie_class_id", "zp_get_zombie_class_info" }; 

//Weapons bitsum
const PRIMARY_WEAPONS_BIT_SUM = 
( 1<<CSW_SCOUT | 1<<CSW_XM1014 | 1<<CSW_MAC10 | 1<<CSW_AUG | 1<<CSW_UMP45 | 1<<CSW_SG550 | 1<<CSW_GALIL | 1<<CSW_FAMAS | 1<<CSW_AWP )|
( 1<<CSW_MP5NAVY | 1<<CSW_M249 | 1<<CSW_M3 | 1<<CSW_M4A1 | 1<<CSW_TMP | 1<<CSW_G3SG1 | 1<<CSW_SG552 | 1<<CSW_AK47 | 1<<CSW_P90 );
const PISTOLS_BIT_SUM = ( 1<<CSW_USP | 1<<CSW_GLOCK18 | 1<<CSW_DEAGLE | 1<<CSW_ELITE | 1<<CSW_FIVESEVEN | 1<<CSW_P228 );

//List of weapons commands
new const standart_wpn_cmds[ ][ ] = {"p228", "228compact", "shield", "scout", "hegren", "xm1014", "autoshotgun", "mac10", "aug", "bullpup","sgren",
"elites", "fn57", "fiveseven", "ump45", "sg550", "krieg550", "galil", "defender", "famas", "clarion", "usp", "km45", "glock", "9x19mm", "awp", "magnum", "mp",
"smg", "m2493", "m3", "12gauge", "m4a1", "tmp", "mp", "g3sg1", "d3au1", "flash", "deagle", "nighthawk", "sg552", "krieg", "ak47", "cv47", "p90", "c90"};

//Vars
new g_Buymenu, g_Submenu; 
new g_pCvarMode, g_pCvarMultiple, g_pCvarMultMin, g_pCvarMultNum, g_pCvarAutobuyLimit, g_pCvarBuyzone, g_pCvarBuytime, g_pCvarAutoAmmo;
new g_iCount = 0, g_SubmenuType[ 33 ], g_iWeaponsNum[ 8 ] = 0;
new g_EditMode[ 33 ], g_iEditNum[ 33 ], g_Registred[ 128 ] = 0;
new g_szDataName[ 128 ][ 64 ], g_iDataCost[ 128 ], g_iDataTeam[ 128 ], g_iDataType[ 128 ], g_iDataSource[ 128 ], g_iDataAccess[ 128 ], g_szDataCmd[ 128 ][ 64 ], g_iDataCmdAcc[ 128 ] = 0;
new g_BmmItemSelected, g_ZpItemSelected, g_FwdReturn;
new g_szFilename[ 256 ];
new bool:g_bBmOp[ 33 ], bool:g_bSmOp[ 33 ];
new g_RebuyWeapon[ 2 ][ 33 ], g_RebuyWeaponNew[ 2 ][ 33 ];
new g_iMapBuyBlock = 0;
new Float:g_flRoundStartTime;
new g_iBotMoney[ 33 ];

new const g_szPickAmmoSound[] = "items/9mmclip1.wav"

new g_hVault;
new const g_szVaultFile[] = "bmm_stats";


/*****************************************
	Main functions
*****************************************/
public plugin_init()
{
	register_plugin( PLUGIN, VERSION, AUTHOR );
	register_dictionary( "csgo_settings.txt" );

	g_pCvarBuytime = get_cvar_pointer( "mp_buytime" );
	g_pCvarMode = register_cvar( "bmm_on", "1" );
	g_pCvarMultiple = register_cvar( "bmm_multiple", "1" );
	g_pCvarMultMin = register_cvar( "bmm_multiple_min", "100" );
	g_pCvarMultNum = register_cvar( "bmm_multiple_num", "1000" );
	g_pCvarAutobuyLimit = register_cvar( "bmm_autobuy_limit", "5000" );
	g_pCvarBuyzone = register_cvar( "bmm_buyzone", "1" );
	g_pCvarAutoAmmo = register_cvar( "bmm_autoammo", "1" );

	register_clcmd( "buy" , "clcmd_buy" );
	register_clcmd( "shop" , "clcmd_buy" );
	register_clcmd( "client_buy_open" , "clcmd_client_buy_open" );
	register_clcmd( "autobuy" , "clcmd_autobuy" );
	register_clcmd( "cl_autobuy" , "clcmd_autobuy" );
	register_clcmd( "cl_setautobuy", "clcmd_autobuy" )
	register_clcmd( "rebuy" , "clcmd_rebuy" );
	register_clcmd( "cl_rebuy" , "clcmd_rebuy" );
	register_clcmd( "cl_setrebuy", "clcmd_rebuy" )
	register_clcmd( "buyequip" , "clcmd_buyequip" );
	register_clcmd( "buyammo1" , "clcmd_buyammo_primary" );
	register_clcmd( "buyammo2" , "clcmd_buyammo_secondary" );

	register_clcmd( "amx_bmm_category" , "cat_menu", ADMIN_CVAR );
	register_concmd( "amx_bmm_additem" , "add_item_console", ADMIN_CVAR );
	register_concmd( "amx_bmm_clear" , "config_clear", ADMIN_CVAR );
	register_concmd( "amx_bmm_stats" , "stats_count", ADMIN_KICK );

	register_logevent("RoundStart", 2, "1=Round_Start");
	RegisterHam( Ham_Spawn, "player", "fwdPlayerSpawn", 1 ); 

	get_configsdir( g_szFilename, 255 );
	format( g_szFilename, 255, "%s/%s.%s", g_szFilename, FILE_NAME, FILE_FORMAT );
	fclose( fopen( g_szFilename, "a+" ) );

	load_cmd_items();

	g_BmmItemSelected = CreateMultiForward( "bmm_item_selected", ET_CONTINUE, FP_CELL, FP_CELL );
	g_ZpItemSelected = CreateMultiForward( "zp_extra_item_selected", ET_CONTINUE, FP_CELL, FP_CELL );
}

public plugin_cfg()
{
	g_hVault = nvault_open( g_szVaultFile );
	if ( g_hVault == INVALID_HANDLE )
		set_fail_state( "Error opening nVault" );
}

public plugin_end()
{
	nvault_close( g_hVault );
	DestroyForward( g_BmmItemSelected );
	DestroyForward( g_ZpItemSelected );
}

//Replace standart buymenu
public clcmd_buy( id )
{
	if( get_pcvar_num( g_pCvarMode ) == 0 )
		return PLUGIN_CONTINUE;

	if( !CanBuy( id ) )
		return PLUGIN_HANDLED; 

	g_iEditNum[ id ] = -1; 
	g_EditMode[ id ] = 0; 
	buymenu_m( id );

	return PLUGIN_HANDLED; 
}

//Replace standart GUI-buymenu
public clcmd_client_buy_open( id )
{
	if( get_pcvar_num( g_pCvarMode ) == 0 )
		return PLUGIN_CONTINUE;

	if( !CanBuy( id ) )
		return PLUGIN_HANDLED; 

	static msg_buyclose; if ( !msg_buyclose ) msg_buyclose = get_user_msgid( "BuyClose" );
	message_begin( MSG_ONE, msg_buyclose, _, id ), message_end();
	clcmd_buy( id );

	return PLUGIN_HANDLED; 
}

//Replace equipments menu
public clcmd_buyequip( id )
{
	if( get_pcvar_num( g_pCvarMode ) == 0 )
		return PLUGIN_CONTINUE;

	if( !CanBuy( id ) )
		return PLUGIN_HANDLED; 

	new bool:bEquipPres = false;

	if( g_iWeaponsNum[ BMM_EQUIP ] > 0 )
		bEquipPres = true;

	if( bEquipPres )
	{
		g_iEditNum[ id ] = -1; 
		g_EditMode[ id ] = 0; 
		g_SubmenuType[ id ] = BMM_EQUIP;
		submenu_m( id );
	}else
		client_print( id, print_center, "%L", id, "BMM_NOEQUIP");

	return PLUGIN_HANDLED; 
}

//Replace buying primary ammo
public clcmd_buyammo_primary( id )
{
	if( get_pcvar_num( g_pCvarMode ) == 0 )
		return PLUGIN_CONTINUE;

	if( !CanBuy( id ) )
		return PLUGIN_HANDLED; 

	GiveAmmo( id, Primary );
	return PLUGIN_HANDLED; 
}

//Replace buying secondary ammo
public clcmd_buyammo_secondary( id )
{
	if( get_pcvar_num( g_pCvarMode ) == 0 )
		return PLUGIN_CONTINUE;

	if( !CanBuy( id ) )
		return PLUGIN_HANDLED; 

	GiveAmmo( id, Secondary );
	return PLUGIN_HANDLED; 
}

//Open categories menu (amx_bmm_category)
public cat_menu( id, level, cid )
{
	if( !cmd_access( id, level, cid, 1 ) )
		return PLUGIN_HANDLED;
	g_EditMode[ id ] = 1; 
	g_iEditNum[ id ] = -1; 
	buymenu_m( id );

	return PLUGIN_HANDLED;
}

//Lock registered commands
public client_command(id)
{
	if( get_pcvar_num( g_pCvarMode ) == 0 )
		return PLUGIN_CONTINUE;

	new szCmd[ 128 ];
	read_argv( 0, szCmd, 127 );

	new iPres=0;
	for( new i = 0 ; i < sizeof standart_wpn_cmds ; i++ )
	{
		for( new j = 0 ; j < sizeof g_szDataCmd ; j++ )
			if( equal( standart_wpn_cmds[ i ], g_szDataCmd[ j ] ) )
				iPres++;
		if( equal( szCmd, standart_wpn_cmds[ i ]) && iPres == 0 )
			return PLUGIN_HANDLED;
	}

	for( new i = 0 ; i < sizeof g_szDataCmd ; i++ )
		if( equali( szCmd, g_szDataCmd[ i ] ) )
		{
			if( g_iDataCmdAcc[ i ] == 0 )
			{
				client_print(id, print_console, "Error");
				return PLUGIN_HANDLED;
			}
			else
			{
				g_iDataCmdAcc[ i ] = 0;
				return PLUGIN_CONTINUE;
			}
		}

	return PLUGIN_CONTINUE;
}

//Start of round
public RoundStart(){
    g_flRoundStartTime = get_gametime();
}

//Spawn of player
public fwdPlayerSpawn( id )
{
	if( get_pcvar_num( g_pCvarMode ) == 0 || !is_user_alive( id ) )
		return PLUGIN_CONTINUE;

	AutoAmmo( id )

	if( is_user_bot( id ) )
	{
		g_iBotMoney[ id ] = GetUserMoney( id );
		if( !CanBuy( id ) )
			return PLUGIN_CONTINUE;
		remove_task( id+1513 );
		set_task(1.0, "bot_buy", id+1513 );
	}

	for( new q = 0; q < 2; q++ )
	{
		g_RebuyWeapon[ q ][ id ] = g_RebuyWeaponNew[ q ][ id ];
		g_RebuyWeaponNew[ q ][ id ] = -1;
	}

	return PLUGIN_CONTINUE;
}

/*****************************************
	Main Buy Menu
*****************************************/
public buymenu_m( id )
{
	if ( g_EditMode[ id ] == 0 &&
	( get_user_team( id ) == 0
	|| cs_get_user_team( id ) == CS_TEAM_SPECTATOR
	|| !is_user_alive( id )
	|| !is_user_connected( id )	
	|| !get_user_buyzone( id ) )
	|| get_pcvar_num( g_pCvarMode ) == 0 )
		return PLUGIN_CONTINUE; 

	new szTitle[ 256 ];

	g_bBmOp[ id ] = true; 
	if ( g_iEditNum[ id ] != -1 )
		format( szTitle, 255, "\r%L:", id, "BMM_NEW_CAT" );
	else if ( g_EditMode[ id ] == 1 )
		format( szTitle, 255, "\r%L:", id, "BMM_CHANGE_CAT" );
	else	
		format( szTitle, 255, "%L:", id, "BMM_BUYITEM" );
	
	g_Buymenu = menu_create( szTitle, "buymenu_handler" );

	//Main categories
	for( new i = 1; i < 6; i++ )
	{
		format( szTitle, 255, "%s%L", ( g_iWeaponsNum[ i ] > 0 || g_iEditNum[ id ] != -1 ) ? ( ( g_EditMode[ id ] != 0 ) ? "\y" : "\w" ) : "\d", id, g_szTitles[ i ] );
		new nums[ 2 ]; 
		num_to_str( i, nums, 1 );
		menu_additem( g_Buymenu, szTitle, nums );
	}
	menu_addblank( g_Buymenu, 0 );

	//Ammo
	if ( g_EditMode[ id ] == 0 && g_iEditNum[ id ] == -1 )
	{
		format( szTitle, 255, "%L", id, "BMM_PRIMARY_AMMO" );
		menu_additem( g_Buymenu, szTitle, "6" );
		format( szTitle, 255, "%L", id, "BMM_SECONDARY_AMMO" );
		menu_additem( g_Buymenu, szTitle, "7" );
		menu_addblank( g_Buymenu, 0 );
	}

	//Equipment
	format( szTitle, 255, "%s%L", ( g_iWeaponsNum[ BMM_EQUIP ] > 0 || g_iEditNum[ id ] != -1 ) ? ( ( g_EditMode[ id ] != 0 )?"\y":"\w" ):"\d", id, "BMM_EQUIP" );
	menu_additem( g_Buymenu, szTitle, "8" );
	
	//Uncategorised
	if ( g_iWeaponsNum[ BMM_UNCATEGORIZED ] > 0 || g_iEditNum[ id ] != -1 )
	{
		format( szTitle, 255, "%s%L", ( g_EditMode[ id ] != 0 ) ? "\y" : "\w", id, g_szTitles[ 7 ] );
		menu_additem( g_Buymenu, szTitle, "9" );
	}
	else menu_addblank( g_Buymenu, 1 );
		
	if ( g_EditMode[ id ] != 0 )
		for( new i = 1; i < 3; i++ )
			menu_addblank( g_Buymenu, 1 );

	format( szTitle, 255, "%s%L", ( g_EditMode[ id ] != 0 ) ? "\y" : "\w", id, "BMM_EXIT" );
	if ( g_EditMode[ id ] == 0 ) menu_setprop( g_Buymenu, MPROP_NUMBER_COLOR, "\r" );
	menu_additem( g_Buymenu, szTitle, "MENU_EXIT" );

	menu_setprop( g_Buymenu, MPROP_PERPAGE, 0 );
	menu_display( id, g_Buymenu, 0 );
	return PLUGIN_CONTINUE; 
}

// Handler Main Menu
public buymenu_handler( id, buymenu, item )
{
	if ( g_EditMode[ id ] == 0 &&
	( cs_get_user_team( id ) == CS_TEAM_UNASSIGNED
	|| item == MENU_EXIT || !is_user_alive( id )
	|| !is_user_connected( id ) )
	|| ( !get_user_buyzone( id ) && g_EditMode[ id ] == 0 )
	|| get_pcvar_num( g_pCvarMode ) == 0 )
	{
		menu_destroy( buymenu );
		g_bBmOp[ id ] = false; 
		return PLUGIN_HANDLED; 
	}

	new data[ 6 ], szName[ 64 ]; 
	new iAccess, callback; 

	menu_item_getinfo( buymenu, item, iAccess, data, charsmax( data ), szName, charsmax( szName ), callback );
	new key = str_to_num( data );

	if ( g_iEditNum[ id ] != -1 )
	{
		new oldtype = g_iDataType[ g_iEditNum[ id ] ]; 
		for( new i = 1; i < 6; i++ )
			if ( key == i ) g_iDataType[ g_iEditNum[ id ] ] = i; 
		switch( key )
		{
			case 6: GiveAmmo( id, Primary );
			case 7: GiveAmmo( id, Secondary );
			case 8: g_iDataType[ g_iEditNum[ id ] ] = BMM_EQUIP; 
			case 9: if ( g_iWeaponsNum[ BMM_UNCATEGORIZED ] > 0 || g_iEditNum[ id ] != -1 )
				g_iDataType[ g_iEditNum[ id ] ] = BMM_UNCATEGORIZED; 
		}
		g_iWeaponsNum[ oldtype ]--; 
		g_iWeaponsNum[ g_iDataType[ g_iEditNum[ id ] ] ]++; 
		g_SubmenuType[ id ] = oldtype; 

		new readdata[ 128 ], line = 0, alr = 0, len, 
		wpname[ 64 ], wptype[ 8 ], wpsource[ 2 ], wpinf[ 128 ], wpcost[ 8 ], wpteam[ 16 ], wpaccess[ 32 ], wpcmd[ 64 ]; 
		while( ( line = read_file( g_szFilename, line, readdata, 127, len ) ) )
		{
			if ( !len || readdata[ 0 ] == ';' || readdata[ 0 ] == '/' )
				continue; 

			if( g_iDataSource[ g_iEditNum[ id ] ] != ADD_CMD )
			{
				parse( readdata, wpname, 63, wptype, 8, wpsource, 1, wpcost, 8, wpteam, 16, wpaccess, 32 );
				if ( equali( wpname, g_szDataName[ g_iEditNum[ id ] ] ) )
				{
					format( wpinf, 127, "^"%s^" %d %d %d %d %d^r", g_szDataName[ g_iEditNum[ id ] ], g_iDataType[ g_iEditNum[ id ] ], g_iDataSource[ g_iEditNum[ id ] ], g_iDataCost[ g_iEditNum[ id ] ], g_iDataTeam[ g_iEditNum[ id ] ], g_iDataAccess[ g_iEditNum[ id ] ] );
					write_file( g_szFilename, wpinf, line-1 );
					alr++; 
				}
			}
			else
			{
				parse( readdata, wpname, 63, wptype, 8, wpsource, 1, wpcost, 7, wpteam, 15, wpaccess, 31, wpcmd, 63 );
				if ( equali( wpname, g_szDataName[ g_iEditNum[ id ] ] ) )
				{
					format( wpinf, 127, "^"%s^" %d %d %d %d %d ^"%s^"^r", g_szDataName[ g_iEditNum[ id ] ], g_iDataType[ g_iEditNum[ id ] ], g_iDataSource[ g_iEditNum[ id ] ], g_iDataCost[ g_iEditNum[ id ] ], g_iDataTeam[ g_iEditNum[ id ] ], g_iDataAccess[ g_iEditNum[ id ] ], g_szDataCmd[ g_iEditNum[ id ] ] );
					write_file( g_szFilename, wpinf, line-1 );
					alr++; 
				}
			}
		}
		if ( alr == 0 ) write_file( g_szFilename, wpinf );

		g_iEditNum[ id ] = -1;
		client_print( id, print_chat, "[BMM] %L", id, "BMM_CHANGED" );
	}
	else
	{
		for( new i = 1; i < 6; i++ )
			if ( key == i ) g_SubmenuType[ id ] = i; 
		switch( key )
		{
			case 6: GiveAmmo( id, Primary );
			case 7: GiveAmmo( id, Secondary );
			case 8: g_SubmenuType[ id ] = BMM_EQUIP; 
			case 9: if ( g_iWeaponsNum[ BMM_UNCATEGORIZED ] > 0 || g_iEditNum[ id ] != -1 )
				g_SubmenuType[ id ] = BMM_UNCATEGORIZED; 
		}
	}
	if( key != 6 && key != 7 )
	{
		if ( key != 0 && g_iWeaponsNum[ g_SubmenuType[ id ] ] == 0 ) buymenu_m( id );
		else if ( key != 0 ) submenu_m( id );
	}

	return PLUGIN_CONTINUE; 
}

/*****************************************
	Items Buy Menu
*****************************************/

public submenu_m( id )
{
	if ( g_EditMode[ id ] == 0 && ( cs_get_user_team( id ) == CS_TEAM_UNASSIGNED || cs_get_user_team( id ) == CS_TEAM_SPECTATOR || !is_user_alive( id ) || !is_user_connected( id ) || !get_user_buyzone( id ) ) || get_pcvar_num( g_pCvarMode ) == 0 )
		return PLUGIN_CONTINUE; 

	g_bSmOp[ id ] = true; 
	new submenuTitle[ 128 ]; 

	//Title and description of submenu
	for( new i = 1; i < 8; i++ ) if ( g_SubmenuType[ id ] == i )
	{
			if ( g_EditMode[ id ] != 1 )
			{
				format( submenuTitle, 255, "%L %L", id, "BMM_BUY", id, g_szTitles[ i ] );
				if ( i == BMM_PISTOLS )
				{
					new desc[ 32 ]; 
					format( desc, 31, "^n(%L)", id, "BMM_SECONDARY" );
					add( submenuTitle, 255, desc );
				}
				else if ( i != BMM_EQUIP && i != BMM_UNCATEGORIZED )
				{
					new desc[ 32 ]; 
					format( desc, 31, "^n(%L)", id, "BMM_PRIMARY" );
					add( submenuTitle, 255, desc );
				}
				new iCost[ 32 ]; 
				format( iCost, 31, "\R$ %L", id, "BMM_COST" );
				add( submenuTitle, 255, iCost );
			}
			else
			{
				format( submenuTitle, 255, "%L", id, g_szTitles[ i ] );
			}
		}

	if ( g_EditMode[ id ] == 1 ) add( submenuTitle, 255, "^n\rСменить категорию" );

	g_Submenu = menu_create( submenuTitle, "submenu_handler" );

	new iIndex = 1, szIndex[ 8 ];
	new szItemName[ 64 ]; 

	// Include the new weapons in menu
	for( new i = 1; i <= g_iCount; i++ )
	{
		if ( g_EditMode[ id ] == 1 )
		{
			if ( g_SubmenuType[ id ] != g_iDataType[ i ] )
				continue; 

			formatex( szItemName, 63, "\w%s", g_szDataName[ i ] );
		}
		else
		{
			new iTeam = g_iDataTeam[ i ]; 
			if ( !check_user_team( id, iTeam ) || g_SubmenuType[ id ] != g_iDataType[ i ] || !g_szDataName[ i ][ 0 ] )
				continue; 
		
			new iCost = g_iDataCost[ i ], iMoney; 
			iMoney = GetUserMoney( id );

			if ( get_pcvar_num( g_pCvarMultiple ) && g_iDataCost[ i ] < get_pcvar_num( g_pCvarMultMin ) )
				iCost *= get_pcvar_num( g_pCvarMultNum );

			//If money cost more than 16000, cost sets to 16000
			#if !defined MONEY_UL
				if ( iCost > 16000 ) iCost = 16000; 
			#endif // MONEY_UL

			if ( g_iDataAccess[ i ] == ADMIN_ALL || get_user_flags( id ) & g_iDataAccess[ i ] )
			{
				if ( iCost == 0 )
					formatex( szItemName, 63, "\w%s \R\y%L", g_szDataName[ i ], id, "BMM_FREE" );
				else
				{
					if ( iMoney - iCost > -1 )
					{
						formatex( szItemName, 63, "\w%s \R\y$%d", g_szDataName[ i ], iCost );
					}
					else
						formatex( szItemName, 63, "\d%s \R\r$%d", g_szDataName[ i ], iCost );
				}
			}
			else
			{
				formatex( szItemName, 63, "\d%s\R\r%L", g_szDataName[ i ], id, "BMM_NOACCESS" );
			}
		}
		num_to_str( iIndex++, szIndex, 7 );
		if ( g_EditMode[ id ] == 0 ) menu_setprop( g_Submenu, MPROP_NUMBER_COLOR, "\r" );
		menu_additem( g_Submenu, szItemName, szIndex );
	}

	formatex( szItemName, 63, "%L", id, "BMM_BACK" );
	menu_setprop( g_Submenu, MPROP_BACKNAME, szItemName );
	formatex( szItemName, 63, "%L", id, "BMM_NEXT" );
	menu_setprop( g_Submenu, MPROP_NEXTNAME, szItemName );

	formatex( szItemName, 63, "%L", id, "BMM_EXIT" );
	menu_setprop( g_Submenu, MPROP_EXITNAME, szItemName );

        if( 9 <= iIndex <= 10 )
	{
		if( iIndex == 9 )
			menu_addblank( g_Submenu, 1 );

		menu_setprop( g_Submenu, MPROP_PERPAGE, 0 );
		menu_additem( g_Submenu, szItemName, "MENU_EXIT" );
	}else{
		menu_setprop( g_Submenu, MPROP_EXIT, MEXIT_ALL );
	}

	menu_display( id, g_Submenu, 0 );
	return PLUGIN_CONTINUE; 
}

// Handler Items Menu 
public submenu_handler( id, submenu, item )
{
	if ( g_EditMode[ id ] == 0 && ( cs_get_user_team( id ) == CS_TEAM_UNASSIGNED
	|| item == MENU_EXIT
	|| !is_user_alive( id )
	|| !is_user_connected( id ) )
	|| ( !get_user_buyzone( id ) && g_EditMode[ id ] == 0 )
	|| get_pcvar_num( g_pCvarMode ) == 0 )
	{
		menu_destroy( submenu );
		g_bSmOp[ id ] = false; 
		return PLUGIN_HANDLED;
	}

	new data[ 6 ], szName[ 64 ]; 
	new iAccess, callback; 
	menu_item_getinfo( submenu, item, iAccess, data, charsmax( data ), szName, charsmax( szName ), callback );
	new key = str_to_num( data );

	new iIndex = 1; 
	for( new i = 1; i <= g_iCount; i++ )
	{
		if ( g_EditMode[ id ] == 1 )
		{
			if ( g_SubmenuType[ id ] != g_iDataType[ i ] )
				continue;

			if ( key == iIndex )
			{
				g_iEditNum[ id ] = i; 
				buymenu_m( id );
			}
		}
		else
		{
			new iTeam = g_iDataTeam[ i ]; 
			if ( !check_user_team( id, iTeam ) || g_SubmenuType[ id ] != g_iDataType[ i ] || !g_szDataName[ i ][ 0 ])
				continue; 

			if ( key == iIndex )
			{
				if ( g_iDataAccess[ i ] == ADMIN_ALL || get_user_flags( id ) & g_iDataAccess[ i ] )
				{
					new iCost = g_iDataCost[ i ], iMoney;
					iMoney = GetUserMoney( id );
	
					if ( get_pcvar_num( g_pCvarMultiple ) && g_iDataCost[ i ] < get_pcvar_num( g_pCvarMultMin ) && g_iDataSource[ i ] == ADD_ZP )
						iCost *= get_pcvar_num( g_pCvarMultNum );

					#if !defined MONEY_UL
						if ( iCost > 16000 ) iCost = 16000; 
					#endif // MONEY_UL

					if ( iMoney - iCost > -1 )
					{
						WeaponBuy( id, i, iCost )

						g_RebuyWeaponNew[ ( g_iDataType[ i ] == 1 ? 0 : 1 ) ][ id ] = i;

						new iTempNum, tempStr[16] 
						iTempNum = nvault_get( g_hVault , g_szDataName[ i ] ) + 1;
						num_to_str( iTempNum , tempStr , 15 );
						nvault_set( g_hVault , g_szDataName[ i ] , tempStr );

						menu_destroy( submenu );
					}
					else
					{
						client_print( id, print_center, "#Cstrike_TitlesTXT_Not_Enough_Money" );
						submenu_m( id );

						// blink money
						message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("BlinkAcct"), _, id)
						write_byte(2) // times
						message_end()
					}
				}
				else
				{
					client_print(id, print_chat, "[BMM] %L", id, "BMM_NOACCESS_MSG");
					submenu_m( id );
				}
			}
		}
		iIndex++; 
	}
	return PLUGIN_CONTINUE; 
}

/*****************************************
	Register BMM items
*****************************************/
public add_item_bmm( plugin, params )
{
	new szName[ 64 ], szTempName[ 64 ]; 
	get_string( 1, szName, 63 );
	bmm_name_clear( szName, 63 );
	szTempName = szName;
	for( new i = 1; i <= g_iCount; i++ )
		if ( equali( szName, g_szDataName[ i ] ) )
		{
			g_Registred[ g_iCount ]++;
			format( szName, 63, "%s(%d)", szTempName, g_Registred[ g_iCount ] );
		}

	//Increasing the number of weapons
	g_iCount++; 

	new readdata[ 128 ], line = 0, alr = 0, len, 
	wpname[ 64 ], wptype[ 8 ], wpsource[ 2 ], wpinf[ 128 ], wpcost[ 8 ], wpteam[ 16 ], wpaccess[ 32 ]; 
	while( ( line = read_file( g_szFilename, line, readdata, 127, len ) ) )
	{
		parse( readdata, wpname, 63, wptype, 8, wpsource, 1, wpcost, 8, wpteam, 16, wpaccess, 32 );
		if ( !len || readdata[ 0 ] == ';' || readdata[ 0 ] == '/' )
			continue; 

		if ( equali( wpname, szName ) )
		{
			g_iDataType[ g_iCount ] = str_to_num( wptype );
			g_iDataCost[ g_iCount ] = str_to_num( wpcost );
			g_iDataTeam[ g_iCount ] = str_to_num( wpteam );
			g_iDataAccess[ g_iCount ] = str_to_num( wpaccess );
			alr++;
		}
	}

	g_szDataName[ g_iCount ] = szName; 
	g_iDataSource[ g_iCount ] = ADD_BMM; 
	bmm_name_clear( g_szDataName[ g_iCount ], 63 );

	if ( alr == 0 )
	{
		if ( !get_param( 5 ) ) g_iDataAccess[ g_iCount ] = ADMIN_ALL; 
		else g_iDataAccess[ g_iCount ] = get_param( 5 );
		g_iDataCost[ g_iCount ] = get_param( 2 );
		g_iDataTeam[ g_iCount ] = get_param( 3 );
		if ( !get_param( 4 ) ) g_iDataType[ g_iCount ] = BMM_UNCATEGORIZED; 
		else g_iDataType[ g_iCount ] = get_param( 4 );
		format( wpinf, 127, "^"%s^" %d %d %d %d %d^r", g_szDataName[ g_iCount ], g_iDataType[ g_iCount ], g_iDataSource[ g_iCount ], g_iDataCost[ g_iCount ], g_iDataTeam[ g_iCount ], g_iDataAccess[ g_iCount ] );
		write_file( g_szFilename, wpinf );
	}

	g_iWeaponsNum[ g_iDataType[ g_iCount ] ]++; 
	return g_iCount; 
}


/*****************************************
	Register ZP Extra items
*****************************************/
public add_item_zp( plugin, params )
{
	new szName[ 64 ], szTempName[ 64 ]; 
	get_string( 1, szName, 63 );
	bmm_name_clear( szName, 63 );
	szTempName = szName;
	for( new i = 1; i <= g_iCount; i++ )
		if ( equali( szName, g_szDataName[ i ] ) )
		{
			g_Registred[ g_iCount ]++;
			format( szName, 63, "%s(%d)", szTempName, g_Registred[ g_iCount ] );
		}

	//Increasing the number of weapons
	g_iCount++; 

	new readdata[ 128 ], line = 0, alr = 0, len, 
	wpname[ 64 ], wptype[ 8 ], wpsource[ 2 ], wpinf[ 128 ], wpcost[ 8 ], wpteam[ 16 ], wpaccess[ 32 ]; 
	while( ( line = read_file( g_szFilename, line, readdata, 127, len ) ) )
	{
		parse( readdata, wpname, 63, wptype, 8, wpsource, 1, wpcost, 8, wpteam, 16, wpaccess, 32 );
		if( !len || readdata[ 0 ] == ';' || readdata[ 0 ] == '/' )
			continue;

		if( equali( wpname, szName ) )
		{
			g_iDataType[ g_iCount ] = str_to_num( wptype );
			g_iDataCost[ g_iCount ] = str_to_num( wpcost );
			g_iDataTeam[ g_iCount ] = str_to_num( wpteam );
			g_iDataAccess[ g_iCount ] = str_to_num( wpaccess );
			alr++;
		}
	}
	g_szDataName[ g_iCount ] = szName; 
	g_iDataSource[ g_iCount ] = ADD_ZP; 
	bmm_name_clear( g_szDataName[ g_iCount ], 63 );

	if ( alr == 0 )
	{
		g_iDataType[ g_iCount ] = BMM_UNCATEGORIZED; 
		g_iDataAccess[ g_iCount ] = ADMIN_ALL; 
		g_iDataCost[ g_iCount ] = get_param( 2 );
		g_iDataTeam[ g_iCount ] = get_param( 3 );
		format( wpinf, 127, "^"%s^" %d %d %d %d %d^r", g_szDataName[ g_iCount ], g_iDataType[ g_iCount ], g_iDataSource[ g_iCount ], g_iDataCost[ g_iCount ], g_iDataTeam[ g_iCount ], g_iDataAccess[ g_iCount ] );
		write_file( g_szFilename, wpinf);
	}
	g_iWeaponsNum[ g_iDataType[ g_iCount ] ]++; 
	return g_iCount; 
}

/*****************************************
	Register clcmd's
*****************************************/
public add_item_console( id, level, cid )
{
	if( !cmd_access( id, level, cid, 1 ) )
		return PLUGIN_HANDLED;

	if(read_argc()<6)
	{
		client_print(id, print_console, "Usage: amx_bmm_additem <item name> <cost> <team> <flags (^"^" or ^"0^" if you want to allow for all)> <command>");
		client_print(id, print_console, "Sample: amx_bmm_additem ^"AK47^" 2500 CT bcd ^"ak47^"");
		return PLUGIN_HANDLED;
	}
	new szName[ 64 ], wpinf[ 128 ], szTempName[ 64 ];
	read_argv( 1, szName, 63 );
	remove_quotes( szName );
	bmm_name_clear( szName, 63 );
	szTempName = szName;
	for( new i = 1; i <= g_iCount; i++ )
		if ( equali( szName, g_szDataName[ i ] ) )
		{
			g_Registred[ g_iCount ]++;
			format( szName, 63, "%s(%d)", szTempName, g_Registred[ g_iCount ] );
		}

	//Increasing the number of weapons
	g_iCount++; 

	new cmd[ 64 ], iCost[ 8 ], iTeam[ 32 ], iAccess[ 32 ];
	read_argv( 2, iCost, 7 ), read_argv( 3, iTeam, 31 ), read_argv( 4, iAccess, 31 ), read_argv( 5, cmd, 63 );
	remove_quotes( iCost ), remove_quotes( iTeam ), remove_quotes( iAccess ), remove_quotes( cmd );

	g_iDataType[ g_iCount ] = BMM_UNCATEGORIZED;
	g_szDataCmd[ g_iCount ] = cmd;

	g_iDataAccess[ g_iCount ] = read_flags( iAccess ); 

	g_iDataSource[ g_iCount ] = ADD_CMD; 
	g_szDataName[ g_iCount ] = szName;
	g_iDataCost[ g_iCount ] = str_to_num( iCost );

	if( containi( iTeam, "CT" ) != -1 )
		g_iDataTeam[ g_iCount ] = BMM_TEAM_CT;
	else if( containi( iTeam, "T" ) != -1 )
		g_iDataTeam[ g_iCount ] = BMM_TEAM_T;
	if( containi( iTeam, "ALL" ) != -1 || containi( iTeam, "ANY" ) != -1 )
		g_iDataTeam[ g_iCount ] = ( BMM_TEAM_CT | BMM_TEAM_T );

	format( wpinf, 127, "^"%s^" %d 3 %d %d %d ^"%s^"^r", g_szDataName[ g_iCount ], g_iDataType[ g_iCount ], g_iDataCost[ g_iCount ], g_iDataTeam[ g_iCount ], g_iDataAccess[ g_iCount ], g_szDataCmd[ g_iCount ] );
	write_file( g_szFilename, wpinf );

	bmm_name_clear( g_szDataName[ g_iCount ], 63 );
	g_iWeaponsNum[ g_iDataType[ g_iCount ] ]++; 


	return PLUGIN_HANDLED;
}

//Loading registered commands
public load_cmd_items()
{
	new readdata[ 128 ], line = 0, len, 
	wpname[ 64 ], wptype[ 8 ], wpsource[ 2 ], wpcost[ 8 ], wpteam[ 16 ], wpaccess[ 32 ], wpcmd[ 64 ]; 
	while( ( line = read_file( g_szFilename, line, readdata, 127, len ) ) )
	{
		parse( readdata, wpname, 63, wptype, 8, wpsource, 1, wpcost, 8, wpteam, 16, wpaccess, 32, wpcmd, 63 );
		if( !len || readdata[ 0 ] == ';' || readdata[ 0 ] == '/' || str_to_num( wpsource ) != ADD_CMD )
			continue; 

		//Increasing the number of weapons
		g_iCount++; 

		g_szDataName[ g_iCount ] = wpname;
		g_iDataType[ g_iCount ] = str_to_num( wptype );
		g_iDataSource[ g_iCount ] = ADD_CMD;
		g_iDataCost[ g_iCount ] = str_to_num( wpcost );
		g_iDataTeam[ g_iCount ] = str_to_num( wpteam );
		g_iDataAccess[ g_iCount ] = str_to_num( wpaccess );
		g_szDataCmd[ g_iCount ] = wpcmd;

		g_iWeaponsNum[ g_iDataType[ g_iCount ] ]++; 
	}
}

/*****************************************
	Autobuy function
*****************************************/
public clcmd_autobuy( id )
{
	if( get_pcvar_num( g_pCvarMode ) == 0 )
		return PLUGIN_CONTINUE;

	if( !CanBuy( id ) || !get_user_buyzone( id ) )
		return PLUGIN_HANDLED;

	new iCostSum = 0, iMoney;

	new iGunsNums[ 2 ][ 128 ], iGunsCost[ 2 ][ 128 ], iGNum[ 2 ] = {0, 0}
	for( new s = 0; s < 2; s++ ) for( new q = 0; q <= g_iCount; q++ )
	{
		new iTeam = g_iDataTeam[ q ];
		if( check_user_team( id, iTeam ) )
		{
			if( ( g_iDataAccess[ q ] == ADMIN_ALL || get_user_flags( id ) & g_iDataAccess[ q ] ) && ( ( g_iDataType[ q ] == 1 && s == 0 ) || ( g_iDataType[ q ] != 1 && g_iDataType[ q ] != 2 && g_iDataType[ q ] != 6 && g_iDataType[ q ] != 7 && s == 1 ) ) )
			{
				iGunsNums[ s ][ iGNum[ s ] ] = q;
				iGunsCost[ s ][ iGNum[ s ] ] = g_iDataCost[ q ];
				if ( get_pcvar_num( g_pCvarMultiple ) && g_iDataCost[ q ] < get_pcvar_num( g_pCvarMultMin ) && g_iDataSource[ q ] == ADD_ZP ) iGunsCost[ q ][ iGNum[ s ] ] *= get_pcvar_num( g_pCvarMultNum );
				iGNum[ s ]++;
			}
		}
	}

	new iTempNum, iTempCost;
	for( new q = 0; q < 2; q++ )
	{
		for( new i = 0; i <= iGNum[ q ]; i++ ) for( new j = i+1 ; j <= iGNum[ q ]; j++ )
		{
			if( iGunsCost[ q ][ i ] < iGunsCost[ q ][ j ] )
			{
				iTempNum = iGunsNums[ q ][ i ]
				iTempCost = iGunsCost[ q ][ i ]
			       
				iGunsCost[ q ][ i ] = iGunsCost[ q ][ j ];
				iGunsCost[ q ][ j ] = iTempCost;
			       
				iGunsNums[ q ][ i ] = iGunsNums[ q ][ j ];
				iGunsNums[ q ][ j ] = iTempNum;
			}
		}
	}

	iMoney = GetUserMoney( id );
	
	if( iMoney > get_pcvar_num( g_pCvarAutobuyLimit ) )
	{
		new iCostLimitSec, iCostLimitPrim, pCvarLimit, buynum = -1;
		pCvarLimit = get_pcvar_num( g_pCvarAutobuyLimit );
		iCostSum += 650;

		iCostLimitSec = floatround( ( pCvarLimit - 650 ) * 0.25, floatround_floor );
		iCostLimitPrim =  floatround( ( pCvarLimit - 650 ) * 0.75 , floatround_floor );
	
		if( iGunsNums[ 0 ][ 0 ] && !iGunsNums[ 1 ][ 0 ] )
		{
			iCostLimitSec = pCvarLimit - 650;
			iCostLimitPrim = 0;
		}else if( !iGunsNums[ 0 ][ 0 ] && iGunsNums[ 1 ][ 0 ]  ){
			iCostLimitSec = 0
			iCostLimitPrim =  pCvarLimit - 650;
		}

		if( g_iCount > 0 )
		{
			for( new q = 0; q < 2; q++ )
			{
				if( iGunsNums[ q ][ 0 ] )
				{
					for( new i = 0; i < iGNum[ q ]; i++ )
					{
						if( iGunsCost[ q ][ i ] <= ( q < 1 ? iCostLimitSec : iCostLimitPrim ) && !equal( g_szDataName[ iGunsNums[ q ][ i ] ], "Schmidt Scout" ) )
						{
							buynum = i;
							break;
						}
					}
	
					if( WeaponBuy( id, iGunsNums[ q ][ buynum ], 0 ) == 0 )
						iCostSum += iGunsCost[ q ][ buynum ];

					g_RebuyWeaponNew[ ( g_iDataType[ iGunsNums[ q ][ buynum ] ] == 1 ? 0 : 1 ) ][ id ] = iGunsNums[ q ][ buynum ];
				}
			}
		}

		if( iCostSum + 350 <= pCvarLimit )
		{
			iCostSum += 350;
			give_item( id, "item_assaultsuit" );
		}else
			give_item( id, "item_kevlar" );

		for( new i = 0; i < 4; i++ )
			if( iMoney > iCostSum )
			{
				iCostSum+=GiveAmmo( id, Primary, 0 );
				iCostSum+=GiveAmmo( id, Secondary, 0 );
			}

		if( iCostSum > iMoney ) iCostSum = iMoney;
		SetUserMoney( id, iMoney - iCostSum, 1 );
	}
	else if( iMoney < get_pcvar_num( g_pCvarAutobuyLimit ) )
	{
		if ( iMoney-650 > -1 )
		{
			iCostSum = 650;

			new iCostLimitSec, iCostLimitPrim, buynum[ 2 ] = { -1, -1 };
			iCostLimitSec = floatround( ( iMoney - 650 ) * 0.25, floatround_floor );
			iCostLimitPrim =  floatround( ( iMoney - 650 ) * 0.75 , floatround_floor );

			for( new q = 0; q < 2; q++ ) for( new i = 0; i < iGNum[ q ]; i++ )
				if( iGunsCost[ q ][ i ] <= ( q < 1 ? iCostLimitSec : iCostLimitPrim ) )
				{
					buynum[ q ] = i;
					break;
				}
			if( buynum[ 0 ] == -1 || buynum[ 1 ] == -1 ){
				for( new i = 0; i < iGNum[ 0 ]; i++ )
					if( iGunsCost[ 0 ][ i ] <= iMoney-650 )
					{
						buynum[ 0 ] = i;
						break;
					}
				if( buynum[ 0 ]!=-1 )
				{
					if( WeaponBuy( id, iGunsNums[ 0 ][ buynum[ 0 ] ], 0 ) == 0 )
						iCostSum += iGunsCost[ 0 ][ buynum[ 0 ] ];
					g_RebuyWeaponNew[ ( g_iDataType[ iGunsNums[ 0 ][ buynum[ 0 ] ] ] == 1 ? 0 : 1 ) ][ id ] = iGunsNums[ 0 ][ buynum[ 0 ] ];
				}

				if( ( iMoney - iCostSum - 350 ) < 0 )
					give_item( id, "item_kevlar" );
				else
				{
					iCostSum += 350
					give_item( id, "item_assaultsuit" );
				}

				for( new i = 0; i < 4; i++ )
					if( iMoney > iCostSum )
					{
						iCostSum+=GiveAmmo( id, Primary, 0 );
						iCostSum+=GiveAmmo( id, Secondary, 0 );
					}
		
				if( iCostSum > iMoney ) iCostSum = iMoney;
				SetUserMoney( id, iMoney - iCostSum, 1 );

			}
			else
			{
				if( ( iMoney - iCostSum - 350 ) < 0 )
					give_item( id, "item_kevlar" );
				else
				{
					iCostSum += 350
					give_item( id, "item_assaultsuit" );
				}

				for( new q = 0; q < 2; q++ )
				{
					if( WeaponBuy( id, iGunsNums[ q ][ buynum[ q ] ], 0 ) == 0 )
						iCostSum += iGunsCost[ q ][ buynum[ q ] ];
					g_RebuyWeaponNew[ ( g_iDataType[ iGunsNums[ q ][ buynum[ q ] ] ] == 1 ? 0 : 1 ) ][ id ] = iGunsNums[ q ][ buynum[ q ] ];
				}

				for( new i = 0; i < 4; i++ )
					if( iMoney > iCostSum )
					{
						iCostSum+=GiveAmmo( id, Primary, 0 );
						iCostSum+=GiveAmmo( id, Secondary, 0 );
					}
		
				if( iCostSum > iMoney ) iCostSum = iMoney;
				SetUserMoney( id, iMoney - iCostSum, 1 );
			}
		}
	}

	return PLUGIN_HANDLED;
}

/*****************************************
	Rebuy function
*****************************************/

public clcmd_rebuy( id )
{
	if( get_pcvar_num( g_pCvarMode ) == 0 )
		return PLUGIN_CONTINUE;

	if( !CanBuy( id ) || !get_user_buyzone( id ) )
		return PLUGIN_HANDLED;

	for( new q = 0; q < 2; q++ )
	{
		if( g_RebuyWeapon[ q ][ id ] != -1 )
		{
			new iCost = g_iDataCost[ g_RebuyWeapon[ q ][ id ] ], iMoney;
			iMoney = GetUserMoney( id );
	
			if ( get_pcvar_num( g_pCvarMultiple ) && g_iDataCost[ g_RebuyWeapon[ q ][ id ] ] < get_pcvar_num( g_pCvarMultMin ) && g_iDataSource[ g_RebuyWeapon[ q ][ id ] ] == ADD_ZP )
				iCost *= get_pcvar_num( g_pCvarMultNum );

			#if !defined MONEY_UL
				if ( iCost > 16000 ) iCost = 16000; 
			#endif // MONEY_UL
			if ( iMoney - iCost > -1 )
			{
				WeaponBuy( id, g_RebuyWeapon[ q ][ id ], iCost );
				g_RebuyWeaponNew[ q ][ id ] = g_RebuyWeapon[ q ][ id ];

				new iTempNum, tempStr[16] 
				iTempNum = nvault_get( g_hVault , g_szDataName[ g_RebuyWeapon[ q ][ id ] ] ) + 1;
				num_to_str( iTempNum , tempStr , 15 );
				nvault_set( g_hVault , g_szDataName[ g_RebuyWeapon[ q ][ id ] ] , tempStr );

			}
		}
	}
	return PLUGIN_HANDLED;
}

public client_connect(id)
{
	for( new q = 0; q < 2; q++ )
	{
		g_RebuyWeapon[ q ][ id ] = -1;
		g_RebuyWeaponNew[ q ][ id ] = -1;
	}
}

public client_disconnect(id)
{
	for( new q = 0; q < 2; q++ )
	{
		g_RebuyWeapon[ q ][ id ] = -1;
		g_RebuyWeaponNew[ q ][ id ] = -1;
	}
}

/*****************************************
	Calculation statistics
*****************************************/
public stats_count( id, level, cid )
{
	if( !cmd_access( id, level, cid, 1 ) )
		return PLUGIN_HANDLED;

	if( !g_iCount ){
		console_print( id, "^n[BMM] %L" , id, "BMM_NOWEAPONS");
		return PLUGIN_HANDLED;
	}

	new buyCount, mainBuyCount, Float:flBuyPercent, szBuyPercentStr[ 16 ];
	static sortArrayCount[ 128 ], sortArrayName[ 128 ][ 64 ], sortArrayIndex[ 128 ];

	for( new i = 1; i <= g_iCount; i++ )
	{
		sortArrayCount[ i ] = nvault_get( g_hVault , g_szDataName[ i ] );
		sortArrayName[ i ] = g_szDataName[ i ];
		sortArrayIndex[ i ] = i;

		mainBuyCount += nvault_get( g_hVault , g_szDataName[ i ] );
	}
	
	new iTempCount, iTempIndex, szTempName[ 64 ];
	for( new i = 1; i <= g_iCount; i++ ) for( new j = i+1 ; j <= g_iCount; j++ )
	{
		if( sortArrayCount[ i ] < sortArrayCount[ j ] )
		{
			iTempCount = sortArrayCount[ i ];
			szTempName = sortArrayName[ i ];
			iTempIndex = sortArrayIndex[ i ];
		       
			sortArrayName[ i ] = sortArrayName[ j ];
			sortArrayCount[ i ] = sortArrayCount[ j ];
			sortArrayIndex[ i ] = sortArrayIndex[ j ];
		       
			sortArrayCount[ j ] = iTempCount;
			sortArrayName[ j ] = szTempName;
			sortArrayIndex[ j ] = iTempIndex;
		}      
	}

	console_print( id, "^n[BMM] %L:^n #	%L				%L	    %L" , id, "BMM_STATS", id, "BMM_NAME", id, "BMM_PER", id, "BMM_PUR");
	new iNum = 0;
	for( new i = 1; i <= g_iCount; i++ )
	{
		iNum++;

		buyCount = sortArrayCount[ i ];
		flBuyPercent = float( buyCount ) / ( float( mainBuyCount ) / 100 );

		format( szBuyPercentStr , ( flBuyPercent == 100.0 ? 5 :( flBuyPercent >= 10.0) ? 4 : 3 ) , "%f" , flBuyPercent );
		if( flBuyPercent < 10.0 )
			format( szBuyPercentStr , 4 , " %s" , szBuyPercentStr );

		new shortSpaces[33], iNameLen;
		iNameLen = 32 - strlen( sortArrayName[ i ] );
		
		for( new q = 0; q < iNameLen; q++ )
		{
			if( iNameLen > 0 ) add( shortSpaces, 32, " " );
		}

		console_print( id, " %d	%s%s%s%s               %d" , iNum , sortArrayName[ i ] , shortSpaces , szBuyPercentStr , ( id==0 ? "%" : "%%" ) , buyCount);
	}
	console_print( id, "%L^n", id, "BMM_TOTAL", mainBuyCount);

	return PLUGIN_HANDLED;
}


/*****************************************
	Clearing config
*****************************************/
public config_clear( id, level, cid )
{
	if( !cmd_access( id, level, cid, 1 ) )
	{
		return PLUGIN_HANDLED;
	}

	new readdata[ 128 ], line = 0, len, 
	wpname[ 64 ], wnum = 0;
	while( ( line = read_file( g_szFilename, line, readdata, 127, len ) ) )
	{
		new alr=0;
		parse( readdata, wpname, 63 );
		for( new i = 1; i <= g_iCount; i++ )
			if( equali( wpname, g_szDataName[ i ] ) )
			{
				alr++;
				wnum++;
			}
		if( alr == 0 )
			write_file( g_szFilename, "", line-1 );
	}
	console_print( id, "%s", id, "BMM_CLEARED" );
	return PLUGIN_HANDLED;
}


/*****************************************
	Bots support
*****************************************/
public bot_buy( id )
{
	id-=1513;

	strip_user_weapons( id );
	give_item( id, "weapon_knife" );

	new iGunsNums[ 2 ][ 128 ], iHgNum = 0, iGNum = 0;
	for( new i = 1; i <= g_iCount; i++ )
	{
		if ( g_iDataType[ i ] == 1 )
		{
			iGunsNums[ 0 ][ iHgNum ] = i;
			iHgNum++;
		}
		else if( g_iDataType[ i ] != 6 && g_iDataType[ i ] != 7 )
		{
			iGunsNums[ 1 ][ iGNum ] = i
			iGNum++;
		}
	}

	for( new q = 0; q < 2; q++ )
	{
		for( new w = 1; w <= g_iCount; w++ )
		{
			if( ( q > 0 ? iGNum : iHgNum ) == 0 )
				continue;

			new i;
			i = random_num( 1 , ( q > 0 ? iGNum : iHgNum ) - 1 );

			new iCost = g_iDataCost[ i ];
	
			if ( get_pcvar_num( g_pCvarMultiple ) && g_iDataCost[ i ] < get_pcvar_num( g_pCvarMultMin ) && g_iDataSource[ i ] == ADD_ZP ) iCost *= get_pcvar_num( g_pCvarMultNum );
			#if !defined MONEY_UL
				if ( iCost > 16000 ) iCost = 16000; 
			#endif // MONEY_UL
			if ( g_iBotMoney[ id ] - iCost > -1 )
			{
				WeaponBuy( id, iGunsNums[ q ][ i ], iCost );
				g_iBotMoney[ id ] -= iCost;
				break;
			}
			else
				continue;
		}
	}
	SetUserMoney( id, g_iBotMoney[ id ], 1 );
}

/*****************************************
	Blocking buymenu on maps
	with restricting to buy weapons
*****************************************/

public plugin_precache()
{
	register_forward( FM_KeyValue, "fwdKeyValue", 1 );
	precache_sound( g_szPickAmmoSound );
}

public fwdKeyValue( ent, kvdid )
{
	if( pev_valid( ent ) )
	{
		new szClassname[ 32 ], szKeyname[ 32 ], szKeyvalue[ 32 ];
		get_kvd( kvdid, KV_ClassName, szClassname, 31 );
		get_kvd( kvdid, KV_KeyName, szKeyname, 31 );
		get_kvd( kvdid, KV_Value, szKeyvalue, 31 );

		if( equali( szClassname, "info_map_parameters" ) && equali( szKeyname, "buying" ) )
				if( str_to_num( szKeyvalue ) != 0 )
					g_iMapBuyBlock = str_to_num( szKeyvalue );

					// The "buying" key may has 4 values:
					// 0 – all can buy, 1 – only CT can buy,
					// 2 – only Terrorists can buy, 3 – no one can buy

	}
	return FMRES_IGNORED;
}


/*****************************************
	Buy weapon function
*****************************************/

WeaponBuy( id, wpnid, cost )
{
	if( !CanBuy( id ) )
		return PLUGIN_HANDLED_MAIN;
	g_FwdReturn = 0;

	if ( g_iDataType[ wpnid ] == 1 ) drop_weapons( id, 2 );
	else if ( g_iDataType[ wpnid ] != 6 && g_iDataType[ wpnid ] != 7 ) drop_weapons( id, 1 );

	if ( g_iDataSource[ wpnid ] == ADD_ZP )
		ExecuteForward( g_ZpItemSelected, g_FwdReturn, id, wpnid );
	else if ( g_iDataSource[ wpnid ] == ADD_BMM )
		ExecuteForward( g_BmmItemSelected, g_FwdReturn, id, wpnid );
	else if ( g_iDataSource[ wpnid ] == ADD_CMD )
	{
		g_iDataCmdAcc[ wpnid ] = 1;
		client_cmd( id, "%s", g_szDataCmd[ wpnid ] );
	}

	AutoAmmo( id )

	if( g_FwdReturn >= PLUGIN_HANDLED )
		return PLUGIN_HANDLED;

	new iMoney = GetUserMoney( id );
	SetUserMoney( id, iMoney - cost, 1 );

	return PLUGIN_CONTINUE;
}

/*****************************************
	Give ammo
*****************************************/
GiveAmmo( id, iWeaponType, iMoneyTake=1 )
{
	if( !CanBuy( id ) )
		return PLUGIN_HANDLED;

	new iMoney, iWeapons, iCost, iSum, iMax;
	new bool:bHadWeapon;

	iMoney = GetUserMoney( id );
	iWeapons = pev( id, pev_weapons );

	for( new i=1; i<AmmoIds; i++ )
	{
		iMax = g_iAmmoDatas[ i ][ Max ];
		if( get_pdata_int(id, m_rgAmmo_Slot0 + i, XTRA_OFS_PLAYER) < iMax )
		{
			iCost = g_iAmmoDatas[ i ][ Cost ];
			if( iWeapons & g_iAmmoWeaponSharedBitSum[ i ][ iWeaponType ] )
			{
				bHadWeapon = true;
				if( iMoney >= iCost )
				{
					if( ExecuteHamB( Ham_GiveAmmo, id, g_iAmmoDatas[i][Amount], g_szAmmoNames[i], iMax) != -1 )
					{
						iSum += iCost;
						if( iMoneyTake )
							SetUserMoney( id, iMoney - iCost, 1 );
					}
				}
			}
		}
	}

	if( !bHadWeapon )
	{
		return 0;
	}

	emit_sound(id, CHAN_ITEM, g_szPickAmmoSound, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	return iSum;
}

AutoAmmo( id )
{
	if( get_pcvar_num( g_pCvarAutoAmmo ) && is_user_alive( id ) && is_user_connected( id ) )
	{
		new iWeapons, iMax;
		iWeapons = pev( id, pev_weapons );
	
		for( new iWeaponType = 0; iWeaponType < 2; iWeaponType++ )
		{
			for( new i = 1; i < AmmoIds; i++ )
			{
				iMax = g_iAmmoDatas[ i ][ Max ];
				if( get_pdata_int(id, m_rgAmmo_Slot0 + i, XTRA_OFS_PLAYER) < iMax )
				{
					if( iWeapons & g_iAmmoWeaponSharedBitSum[ i ][ iWeaponType ] )
					{
						ExecuteHamB( Ham_GiveAmmo, id, iMax, g_szAmmoNames[i], iMax )
					}
				}
			}
		}
	}
}

/*****************************************
	Сhecking the possibility of buying
*****************************************/
CanBuy( id )
{
	if( get_user_buyzone( id ) && is_user_alive( id ) )
	{
		new Float:flBuyTime;
		if( !( get_gametime() < g_flRoundStartTime + ( flBuyTime = get_pcvar_float( g_pCvarBuytime ) * 60.0 ) ) )
		{
			if( get_pcvar_num( g_pCvarBuyzone ) )
			{
				new szBuyTime[8];
				num_to_str( floatround( flBuyTime ), szBuyTime, 7 );
	
				message_begin( MSG_ONE, get_user_msgid("TextMsg"), .player=id );
				write_byte( print_center );
				write_string( "#Cant_buy" );
				write_string( szBuyTime );
				message_end();

				return 0;
			}else
				return 1;
		}

		if( ( g_iMapBuyBlock == 1 && cs_get_user_team( id ) == CS_TEAM_CT ) || ( g_iMapBuyBlock == 2 && cs_get_user_team( id ) == CS_TEAM_T ) || g_iMapBuyBlock == 3 )
		{
			if( cs_get_user_team( id ) == CS_TEAM_T && get_user_buyzone( id ) )
				client_print( id, print_center, "#Cstrike_TitlesTXT_Terrorist_cant_buy" );
			else if( cs_get_user_team( id ) == CS_TEAM_CT && get_user_buyzone( id ) )
				client_print( id, print_center, "#Cstrike_TitlesTXT_CT_cant_buy" );
			return 0;
		}
	}
	return 1;
}

/*****************************************/

//Cleaning trash from the names of weapons
stock bmm_name_clear( szName[ ], len )
{
	for( new i = 0 ; i < sizeof g_szToreplace ; i++ )
		replace_all( szName, len, g_szToreplace[ i ], "" );
	if ( equal( szName[ 0 ], " " ) ) replace( szName, 63, " ", "" );
	return szName; 
}

//Comparison of bitsum of player team and weapon team
stock bool:check_user_team( id, iTeam )
{
	if ( iTeam & BMM_TEAM_ALL || iTeam & BMM_TEAM_ANY ) iTeam = ( BMM_TEAM_T | BMM_TEAM_CT );

	if( ( cs_get_user_team( id ) == CS_TEAM_CT && iTeam & BMM_TEAM_CT ) || ( cs_get_user_team( id ) == CS_TEAM_T && iTeam & BMM_TEAM_T) )
		return true;
	return false;
}

//Detecting buyzone
stock get_user_buyzone( id )
{
	if( get_pcvar_num( g_pCvarBuyzone ) == 1 )
		return cs_get_user_buyzone( id );
	return 1
}

//Setting the amount of money
public SetUserMoney( id, money, flash )
{
	#if defined MONEY_UL
		cs_set_user_money_ul( id, money, flash );
	#else // MONEY_UL
		cs_set_user_money( id, money, flash );
	#endif // MONEY_UL
}

//Getting the amount of money
public GetUserMoney( id )
{
	#if defined MONEY_UL
		return cs_get_user_money_ul( id );
	#else // MONEY_UL
		return cs_get_user_money( id );
	#endif // MONEY_UL
	
}

//Dropping weapons
stock drop_weapons( id, dropwhat )
{
	new weapons[ 32 ], i, weaponid, iIndex = 0; 
	get_user_weapons( id, weapons, iIndex );
	for( i = 0; i < iIndex; i++ )
	{
		weaponid = weapons[ i ]; 
		if ( ( dropwhat == 1 && ( ( 1<<weaponid ) & PRIMARY_WEAPONS_BIT_SUM ) ) || ( dropwhat == 2 && ( ( 1<<weaponid ) & PISTOLS_BIT_SUM ) ) )
		{
			static wname[ 32 ]; 
			get_weaponname( weaponid, wname, sizeof wname-1 );
			engclient_cmd( id, "drop", wname );
		}
	}
}

public plugin_natives()
{
	register_native( "zp_register_extra_item", "add_item_zp" );
	register_native( "bmm_add_item", "add_item_bmm" );
	register_native( "bmm_get_user_money", "GetUserMoney", 1 );
	register_native( "bmm_set_user_money", "SetUserMoney", 1 );

	/* Grounding ZP natives */
	for( new i = 0 ; i < sizeof(g_native_name) ; i++ ) 
		register_native( g_native_name[ i ], "zp_return_false" ); 
}

/* Disabling ZP natives is produced to maintain Extra Items without Zombie Plague Mod. */
public zp_return_false() return false;
