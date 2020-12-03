#if defined _bmm_included
  #endinput
#endif
#define _bmm_included

/* Teams for bmm_add_item() */
#define BMM_TEAM_NO_ONE 0
#define BMM_TEAM_ANY 0
#define BMM_TEAM_ALL (1<<1)
#define BMM_TEAM_T (2<<4)
#define BMM_TEAM_CT (2<<5)

/* Categories for bmm_add_item() */
enum{
	BMM_PISTOLS = 1, 
	BMM_SHOTGUNS, 
	BMM_SMG, 
	BMM_RIFLES, 
	BMM_MACHINEGUNS ,	
	BMM_EQUIPMENT,
	BMM_UNCATEGORIZED
}

#define BMM_PISTOL 1
#define BMM_HANDGUNS 1
#define BMM_SHOTGUN 2
#define BMM_SMG 3
#define BMM_SUBMACHINE 3
#define BMM_RIFLE 4
#define BMM_MACHINE 5
#define BMM_MGUNS 5
#define BMM_EQUIP 6

 /**
 * Registers a custom item which will be added to the buy menu
 * 
 * Note: The returned item ID can be later used to catch item
 * purchase events for the bmm_item_selected() forward.
 *
 * @param name			Caption to display on the menu.
 * @param cost			Money to be deducted on purchase.
 * @param teams			Bitsum of teams which should be applied for the item.
 * @param type			Category number which should be applied for the item.
 * @param access			Level for access to the item. Deafult: ADMIN_ALL.
 * @return				An internal extra item ID.
 */
native bmm_add_item( const name[], cost, team, type, access=ADMIN_ALL );

/**
* Called when a player check item
 *
 * @param id				Player index.
 * @param itemid			Item ID.
 */
forward bmm_item_selected( id, itemid );

 /**
 * Returns users money.
 */
native bmm_get_user_money( id );

 /**
 * Gives money to user.
 * 
 * @param id				Player index.
 * @param money			Money amoun.
 * @param flash			If flash is 1, the difference between new and old amount will flash red or green.
 */
native bmm_set_user_money( id, money, flash=1 );