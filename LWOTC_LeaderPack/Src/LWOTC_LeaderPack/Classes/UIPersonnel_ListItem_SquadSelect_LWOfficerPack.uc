//---------------------------------------------------------------------------------------
//  FILE:    UIPersonnel_SquadSelect_LWOfficerPack.uc
//  AUTHOR:  Amineri (Long War Studios)
//  PURPOSE: Provides custom behavior for personnel selection screen when
//           selecting soldiers to take on a mission.
//			 Extends functionality to prevent more than one officer from being selected.
//--------------------------------------------------------------------------------------- 
class UIPersonnel_ListItem_SquadSelect_LWOfficerPack extends UIPersonnel_SoldierListItem;

var localized string strOfficerAlreadySelectedStatus;

var UIICon OfficerIcon;

//override in order to retrieve custom status string for 2nd+ officers
simulated function UpdateData()
{
	local XComGameState_Unit Unit;
	local string UnitLoc, status, statusTimeLabel, statusTimeValue, classIcon, rankIcon, flagIcon;	
	local int iRank;
	local X2SoldierClassTemplate SoldierClass;
	
	Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitRef.ObjectID));

	iRank = Unit.GetRank();

	SoldierClass = Unit.GetSoldierClassTemplate();

	//this is the new code here
	GetPersonnelStatusWithOfficer(Unit, status, statusTimeLabel, statusTimeValue);
	if( statusTimeValue == "" )
		statusTimeValue = "---";

	flagIcon = Unit.GetCountryTemplate().FlagImage;
	rankIcon = class'UIUtilities_Image'.static.GetRankIcon(iRank, SoldierClass.DataName);
	classIcon = SoldierClass.IconImage;

	// if personnel is not staffed, don't show location
	if( class'UIUtilities_Strategy'.static.DisplayLocation(Unit) )
		UnitLoc = class'UIUtilities_Strategy'.static.GetPersonnelLocation(Unit);
	else
		UnitLoc = "";

	AS_UpdateDataSoldier(Caps(Unit.GetName(eNameType_Full)),
					Caps(Unit.GetName(eNameType_Nick)),
					Caps(`GET_RANK_ABBRV(Unit.GetRank(), SoldierClass.DataName)),
					rankIcon,
					Caps(SoldierClass != None ? SoldierClass.DisplayName : ""),
					classIcon,
					status,
					statusTimeValue $"\n" $ Class'UIUtilities_Text'.static.CapsCheckForGermanScharfesS(Class'UIUtilities_Text'.static.GetSizedText( statusTimeLabel, 12)),
					UnitLoc,
					flagIcon,
					false, 
					(Unit.ShowPromoteIcon()),
					false ); 

	AddGenericOfficerIcon(Unit);
}

//helper to add generic officer icon
simulated function AddGenericOfficerIcon(XComGameState_Unit Unit)
{

	if (class'LWOfficerUtilities'.static.IsOfficer(Unit))
	{
		if (OfficerIcon == none) 
		{
			OfficerIcon = Spawn(class'UIIcon', self).InitIcon('abilityIcon1MC', class'LWOfficerUtilities'.static.GetGenericIcon(), false, true, 18);
		} else {
			OfficerIcon.Show();
		}
		OfficerIcon.OriginTopLeft();
		OfficerIcon.SetPosition(101, 24);
	} else {
		if (OfficerIcon != none)
		{
			OfficerIcon.Hide();
		}
	}
}

//intercepts the base game call to GetPersonnelStatusSeparate to insert custom status if unit is officer and squad already has one
static function GetPersonnelStatusWithOfficer(XComGameState_Unit Unit, out string Status, out string TimeLabel, out string TimeValue, optional int MyFontSize = -1)
{
	local bool bUnitInSquad, bAllowWoundedSoldiers;
	local GeneratedMissionData MissionData;
	local XComGameState_HeadquartersXCom HQState;

	HQState = `XCOMHQ;

	bUnitInSquad = HQState.IsUnitInSquad(Unit.GetReference());

	MissionData = HQState.GetGeneratedMissionData(HQState.MissionRef.ObjectID);
	bAllowWoundedSoldiers = MissionData.Mission.AllowDeployWoundedUnits;

	if (!bUnitInSquad && class'LWOfficerUtilities'.static.IsOfficer(Unit) && class'LWOfficerUtilities'.static.HasOfficerInSquad() && !bAllowWoundedSoldiers)
	{
		Status = class'UIUtilities_Text'.static.GetColoredText(default.strOfficerAlreadySelectedStatus, eUIState_Bad, MyFontSize);
		TimeLabel = class'UIUtilities_Text'.static.GetColoredText(TimeLabel, eUIState_Bad, MyFontSize);
		TimeValue = "";
		return;
	}
	class'UIUtilities_Strategy'.static.GetPersonnelStatusSeparate(Unit, Status, TimeLabel, TimeValue, MyFontSize);
}