#include <amxmodx>
#include <cstrike>
#include <fakemeta>
#include <fun>
#include <bmm>

#define PLUGIN "[CS:GO MOD] BuyMenu Addon"
#define VERSION "0.2"
#define AUTHOR "Danakt Frost"

//Pistols
#define GLOCK18		1
#define USP		1
#define P228		1
#define DEAGLE		1
#define ELITE		1
#define FIVESEVEN	1

//Shotguns
#define M3		1
#define XM1014		1

//SMG
#define MAC10		1
#define TMP		1
#define MP5NAVY		1
#define UMP45		1
#define P90		1

//Rifles
#define GALIL		1
#define AK47		1
#define FAMAS		1
#define SCOUT		1
#define M4A1		1
#define AUG		1
#define SG550		1
#define SG552		1
#define AWP		1
#define G3SG1		1

//Machineguns
#define M249		1

//Equipment
#define KEVLAR		1
#define VESTHELM	1
#define FLASHBANG	1
#define HEGRENADE	1
#define SMOKE		1
#define NIGHTVISION	0
#define DEFUSE		1
#define SHEILD		0

/*************************************/

new g_itemid[ 32 ];
new g_itemid_equip[ 8 ];

//List of standart weapons
new const g_szWeapons[][][] = {

	//Pistols
	#if GLOCK18 == 1
		{ "Glock-18", "glock18" },
	#endif
	#if USP == 1
		{ "USP-S", "usp" },
	#endif
	#if P228 == 1
		{ "P250", "p228" },
	#endif
	#if DEAGLE == 1
		{ "Desert Eagle", "deagle" },
	#endif
	#if ELITE == 1
		{ "Dual Berretas", "elite" },
	#endif
	#if FIVESEVEN == 1
		{ "Five-Seven", "fiveseven" },
	#endif

	//Shotguns
	#if M3 == 1
		{ "Nova", "m3" },
	#endif
	#if XM1014 == 1
		{ "XM-1014", "xm1014" },
	#endif

	//SMG
	#if MAC10 == 1
		{ "MAC-10", "mac10" },
	#endif
	#if TMP == 1
		{ "MP-9", "tmp" },
	#endif
	#if MP5NAVY == 1
		{ "MP5-SD", "mp5navy" },
	#endif
	#if UMP45 == 1
		{ "UMP-45", "ump45" },
	#endif
	#if P90 == 1
		{ "P-90", "p90" },
	#endif

	//Rifles
	#if GALIL == 1
		{ "Galil AR", "galil" },
	#endif
	#if AK47 == 1
		{ "AK-47", "ak47" },
	#endif
	#if FAMAS == 1
		{ "FAMAS", "famas" },
	#endif
	#if SCOUT == 1
		{ "SSG-08", "scout" },
	#endif
	#if M4A1 == 1
		{ "M4A1-S", "m4a1" },
	#endif
	#if AUG == 1
		{ "AUG A3", "aug" },
	#endif
	#if SG550 == 1
		{ "Scar-20", "sg550" },
	#endif
	#if SG552 == 1
		{ "SG-553", "sg552" },
	#endif
	#if AWP == 1
		{ "AWP", "awp" },
	#endif
	#if G3SG1 == 1
		{ "G3-SG1", "g3sg1" },
	#endif

	//Machineguns
	#if M249 == 1
		{ "Negev", "m249" }
	#endif
}

//Buying info of standart weapons
new const g_iWeapons[][] = {

	//Pistols
	#if GLOCK18 == 1
		{ 400, BMM_TEAM_T, BMM_PISTOLS }, // glock18
	#endif
	#if USP == 1
		{ 500, BMM_TEAM_CT, BMM_PISTOLS }, // usp-s
	#endif
	#if P228 == 1
		{ 300, BMM_TEAM_ALL, BMM_PISTOLS }, // p250
	#endif
	#if DEAGLE == 1
		{ 650, BMM_TEAM_ALL, BMM_PISTOLS }, // deagle
	#endif
	#if ELITE == 1
		{ 1000, BMM_TEAM_ALL, BMM_PISTOLS }, // dual berretas
	#endif
	#if FIVESEVEN == 1
		{ 750, BMM_TEAM_CT, BMM_PISTOLS }, // fiveseven  
	#endif

	//Shotguns
	#if M3 == 1
		{ 1700, BMM_TEAM_ALL, BMM_SHOTGUNS }, // nova
	#endif
	#if XM1014 == 1
		{ 3000, BMM_TEAM_ALL, BMM_SHOTGUNS }, // xm1014
	#endif


	//SMG
	#if MAC10 == 1
		{ 1400, BMM_TEAM_T, BMM_SMG }, // mac10
	#endif
	#if TMP == 1
		{ 1250, BMM_TEAM_CT, BMM_SMG }, // mp9
	#endif
	#if MP5NAVY == 1
		{ 1850, BMM_TEAM_T, BMM_SMG }, // mp5-sd
	#endif
	#if UMP45 == 1
		{ 1700, BMM_TEAM_ALL, BMM_SMG }, // ump45
	#endif
	#if P90 == 1
		{ 2350, BMM_TEAM_ALL, BMM_SMG }, // p90
	#endif

	//Rifles
	#if GALIL == 1
		{ 2000, BMM_TEAM_T, BMM_RIFLES }, // galil
	#endif
	#if AK47 == 1
		{ 2700, BMM_TEAM_T, BMM_RIFLES }, // ak47
	#endif
	#if FAMAS == 1
		{ 2250, BMM_TEAM_CT, BMM_RIFLES }, // famas
	#endif
	#if SCOUT == 1
		{ 1700, BMM_TEAM_ALL, BMM_RIFLES }, // ssg-08
	#endif
	#if M4A1 == 1
		{ 3100, BMM_TEAM_CT, BMM_RIFLES }, // m4a1-s
	#endif
	#if AUG == 1
		{ 3500, BMM_TEAM_CT, BMM_RIFLES }, // aug
	#endif
	#if SG550 == 1
		{ 4200, BMM_TEAM_CT, BMM_RIFLES }, // scar-20
	#endif
	#if SG552 == 1
		{ 3500, BMM_TEAM_T, BMM_RIFLES }, // sg553
	#endif
	#if AWP == 1
		{ 4750, BMM_TEAM_ALL, BMM_RIFLES }, // awp
	#endif
	#if G3SG1 == 1
		{ 5000, BMM_TEAM_T, BMM_RIFLES }, // g3sg1
	#endif

	//Machineguns
	#if M249 == 1
		{ 5750, BMM_TEAM_ALL, BMM_MACHINEGUNS } // negev
	#endif
}

public plugin_init()
{
	register_plugin( PLUGIN, VERSION, AUTHOR );

	//Primary and secondary weapons
	for( new i = 0; i < sizeof( g_szWeapons ); i++ )
	{
		g_itemid[ i ] = bmm_add_item( g_szWeapons[ i ][ 0 ], g_iWeapons[ i ][ 0 ], g_iWeapons[ i ][ 1 ], g_iWeapons[ i ][ 2 ] );
	}

	//Equipment
	#if KEVLAR == 1
		g_itemid_equip[ 0 ] = bmm_add_item( "Броня", 650, BMM_TEAM_ALL, BMM_EQUIP );
	#endif
	#if VESTHELM == 1
		g_itemid_equip[ 1 ] = bmm_add_item( "Броня + Шлём", 1000, BMM_TEAM_ALL, BMM_EQUIP );
	#endif
	#if FLASHBANG == 1
		g_itemid_equip[ 2 ] = bmm_add_item( "Световая Граната", 200, BMM_TEAM_ALL, BMM_EQUIP );
	#endif
	#if HEGRENADE == 1
		g_itemid_equip[ 3 ] = bmm_add_item( "Взрывная Граната", 300, BMM_TEAM_ALL, BMM_EQUIP );
	#endif
	#if SMOKE == 1
		g_itemid_equip[ 4 ] = bmm_add_item( "Дымовая Граната", 300, BMM_TEAM_ALL, BMM_EQUIP );
	#endif
	#if NIGHTVISION == 1
		g_itemid_equip[ 5 ] = bmm_add_item( "Ночное Видение", 1250, BMM_TEAM_ALL, BMM_EQUIP );
	#endif
	#if DEFUSE == 1
		g_itemid_equip[ 6 ] = bmm_add_item( "Набор сапёра", 200, BMM_TEAM_CT, BMM_EQUIP );
	#endif
	#if SHEILD == 1
		g_itemid_equip[ 7 ] = bmm_add_item( "Тактический Щит", 2200, BMM_TEAM_CT, BMM_EQUIP );
	#endif
}


public bmm_item_selected( id, itemid )
{
	//Primary and secondary weapons
	for( new i = 0; i < sizeof( g_szWeapons ); i++ )
	{
		if( itemid == g_itemid[ i ] )
		{
			new szItem[ 32 ];
			format( szItem, 31, "weapon_%s", g_szWeapons[ i ][ 1 ] );
			give_item( id, szItem );
		}
	}

	//Kevlar
	if( itemid == g_itemid_equip[ 0 ] )
	{
		new CsArmorType:iArmorType;
		new iArmor = cs_get_user_armor( id, iArmorType );
		if( iArmor < 100 )
		{
			give_item( id, "item_kevlar" );
		}else{
			client_print( id,  print_center, "#Cstrike_TitlesTXT_Already_Have_Kevlar" );
			return PLUGIN_HANDLED;
		}
	}

	//Vesthelm
	else if( itemid == g_itemid_equip[ 1 ] )
	{
		new CsArmorType:iArmorType;
		new iArmor = cs_get_user_armor( id, iArmorType );

		if( iArmorType ==  CS_ARMOR_VESTHELM )
		{
			if( iArmor < 100 )
			{
				give_item( id, "item_assaultsuit" );
			}else{
				client_print( id,  print_center, "#Cstrike_TitlesTXT_Already_Have_Kevlar_Helmet" );
				return PLUGIN_HANDLED;
			}
		}else if( iArmorType ==  CS_ARMOR_KEVLAR )
		{
			if( iArmor < 100 )
			{
				give_item( id, "item_assaultsuit" );
			}else{
				give_item( id, "item_assaultsuit" );
				bmm_set_user_money( id, bmm_get_user_money( id ) - 350 );
				return PLUGIN_HANDLED;
			}
		}else
			give_item( id, "item_assaultsuit" );
	}

	//Flashbang
	else if( itemid == g_itemid_equip[ 2 ] )
	{
		if( cs_get_user_bpammo( id, CSW_FLASHBANG ) > 0 )
		{
			if( cs_get_user_bpammo( id, CSW_FLASHBANG ) == 1 )
			{
				give_item( id, "weapon_flashbang" );
			}else{
				client_print( id,  print_center, "#Cstrike_TitlesTXT_Cannot_Carry_Anymore" );
				return PLUGIN_HANDLED;
			}
		}else{
			give_item( id, "weapon_flashbang" );
		}
	}

	//HE Grenade
	else if( itemid == g_itemid_equip[ 3 ] )
	{
		if( cs_get_user_bpammo( id, CSW_HEGRENADE ) > 0 )
		{
			client_print( id,  print_center, "#Cstrike_TitlesTXT_Cannot_Carry_Anymore" );
			return PLUGIN_HANDLED;
		}else{
			give_item( id, "weapon_hegrenade" );
		}
	}

	//Smoke
	else if( itemid == g_itemid_equip[ 4 ] )
	{
		if( cs_get_user_bpammo( id, CSW_SMOKEGRENADE ) > 0 )
		{
			client_print( id,  print_center, "#Cstrike_TitlesTXT_Cannot_Carry_Anymore" );
			return PLUGIN_HANDLED;
		}else{
			give_item( id, "weapon_smokegrenade" );
		}
	}

	//Night Vision
	else if( itemid == g_itemid_equip[ 5 ] )
	{
		if( get_pdata_int( id,129, 5 ) & ( 1<<0 ) )
		{
			client_print( id,  print_center, "#Cstrike_TitlesTXT_Already_Have_One" );
			return PLUGIN_HANDLED;
		}else{
			set_pdata_int( id, 129, ( get_pdata_int(id, 129) | ( 1<<0 ) ) )
		}
	}

	//Defuse kit
	else if( itemid == g_itemid_equip[ 6 ] )
	{
		if( cs_get_user_defuse( id ) )
		{
			client_print( id,  print_center, "#Cstrike_TitlesTXT_Already_Have_One" );
			return PLUGIN_HANDLED;
		}else{
			cs_set_user_defuse( id );
		}
	}

	//Shield
	else if( itemid == g_itemid_equip[ 7 ] )
	{
		if( cs_get_user_shield( id ) )
		{
			client_print( id,  print_center, "#Cstrike_TitlesTXT_Already_Have_One" );
			return PLUGIN_HANDLED;
		}else{
			give_item( id, "weapon_shield" );
		}
	}

	return PLUGIN_CONTINUE;
}