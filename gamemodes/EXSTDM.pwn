#include <a_samp>
#include <streamer>
#include <a_mysql>
#include <sscanf2>
#include <Pawn.CMD>
#include <foreach>
#define AC_MASTER
#include <anticheat>
// change MAX_PLAYERS to the amount of players (slots) you want
// It is by default 1000 (as of 0.3.7 version)
#undef	  	MAX_PLAYERS
#define	 	MAX_PLAYERS			50
#define	 	MAX_TEAMS			50

#include 	<a_mysql>

// MySQL configuration
#define		MYSQL_HOST 			"127.0.0.1"
#define		MYSQL_USER 			"root"
#define		MYSQL_PASSWORD 		""
#define		MYSQL_DATABASE 		"exs_db"

// how many seconds until it kicks the player for taking too long to login
#define		SECONDS_TO_LOGIN 	30

// default spawn point: Las Venturas (The High Roller)
#define 	DEFAULT_POS_X 		1958.3783
#define 	DEFAULT_POS_Y 		1343.1572
#define 	DEFAULT_POS_Z 		15.3746
#define 	DEFAULT_POS_A 		270.1425
#define     MAX_DUELOS_ACTIVOS      50

// MySQL connection handle
new MySQL: g_SQL;


new Duelo_temp_USERID[MAX_PLAYERS];
new Duelo_temp_APUESTA[MAX_PLAYERS];
new Duelo_temp_Arma1[MAX_PLAYERS];
new Duelo_temp_Arma2[MAX_PLAYERS];
new Duelo_temp_Lugar[MAX_PLAYERS];
new bool:Invitado[MAX_PLAYERS];
new Duelo_temp_INVI_POR[MAX_PLAYERS];
new Tiempo_Invitacion[MAX_PLAYERS];

new MuertePickup[MAX_PLAYERS];
new SalidaTeam;

new Text:TextdrawLobby[11];
new Text:StatsInfo;
new PlayerText:StatsInfoUser[MAX_PLAYERS];

new RachaKills[MAX_PLAYERS];
new TeamSelected[MAX_PLAYERS];

new Iterator:TeamsActivos<MAX_TEAMS>;
new Iterator:PickupVidaActivos<MAX_TEAMS>;

new ActualizarInfo[MAX_PLAYERS];

new UltimaOferta__EXS[MAX_PLAYERS];
new UltimaOferta__COSTO[MAX_PLAYERS];
new UltimaOferta__TIME[MAX_PLAYERS];
new UltimaOferta__USERID[MAX_PLAYERS];
new TiempoOfertarEXS[MAX_PLAYERS];
new bool:EnBase[MAX_PLAYERS];
enum E_PLAYERS
{
	ID,
	Name[MAX_PLAYER_NAME],
	Password[65], // the output of SHA256_PassHash function (which was added in 0.3.7 R1 version) is always 256 bytes in length, or the equivalent of 64 Pawn cells
	Correo[128],
	Salt[17],
	Kills,
	Score,
	Dinero,
	Skin,
	Admin,
	CasaID,
	ClimaID,
	TiempoSAN,
	HoraID,
	EXS,
	d_ganados,
	d_perdidos,
	e_ganados,
	Piezas,
	Deaths,
	Float: X_Pos,
	Float: Y_Pos,
	Float: Z_Pos,
	Float: A_Pos,
	Interior,
	Team,
	Rank,
	//Estados config on/off
	bool:DuelosEstado,
	bool:MPsEstado,
	bool:SpawnHouseEstado,
	bool:InfoRankEstado,
	bool:MusicEventEstado,
	
	bool:EstadoDesert,
	bool:EstadoEscopeta,
	bool:EstadoSPAS,
	bool:EstadoMP5,
	bool:EstadoAK47,
	bool:EstadoM4,
	bool:EstadoRifle,
	bool:EstadoSniper,
	bool:EstadoBate,
	bool:EstadoKatana,
	bool:EstadoMotosierra,
	bool:EstadoGranada,
	bool:EstadoGranadaDH,
	
    bool:EnLobby,
	Cache: Cache_ID,
	bool: IsLoggedIn,
	LoginAttempts,
	LoginTimer
};


new Player[MAX_PLAYERS][E_PLAYERS];

enum E_TEAM
{
	ID,
	Nombre[40],
	Estado,
	Rango1[MAX_PLAYER_NAME],
	Rango2[MAX_PLAYER_NAME],
	Rango3[MAX_PLAYER_NAME],
	Rango4[MAX_PLAYER_NAME],
	Rango5[MAX_PLAYER_NAME],
	Color[11],
	KillsTotal,
	Float:SalidaX,
	Float:SalidaY,
	Float:SalidaZ

};
new TeamInfo[MAX_TEAMS][E_TEAM];

new g_MysqlRaceCheck[MAX_PLAYERS];

// dialog data
enum
{
	DIALOG_UNUSED,
	DIALOG_LOGIN,
	//REGISTRO
	DIALOG_REGISTER,
	DIALOG_REGISTER_CORREO,
	
	//DIALOGOS LOBBY
	DIALOG_SELECT_TEAM,
	DIALOG_AYUDA,
	DIALOG_CUENTA,
	
	DIALOG_CONFIG,
	DIALOG_CONFIG_ARMAS,
	DIALOG_CONFIG_CLIMA,
	DIALOG_CONFIG_HORA,
	DIALOG_CONFIG_ESTILO_PELEA,
	DIALOG_LUGAR_DUELO,
	DIALOG_ARMAS_DUELO,
	DIALOG_ARMAS
};

main() {}


public OnGameModeInit()
{
    UsePlayerPedAnims();
	new MySQLOpt: option_id = mysql_init_options();

	mysql_set_option(option_id, AUTO_RECONNECT, true); // it automatically reconnects when loosing connection to mysql server

	g_SQL = mysql_connect(MYSQL_HOST, MYSQL_USER, MYSQL_PASSWORD, MYSQL_DATABASE, option_id); // AUTO_RECONNECT is enabled for this connection handle only
	if (g_SQL == MYSQL_INVALID_HANDLE || mysql_errno(g_SQL) != 0)
	{
		print("MySQL connection failed. Server is shutting down.");
		SendRconCommand("exit"); // close the server if there is no connection
		return 1;
	}

	print("MySQL connection is successful.");

	// if the table has been created, the "SetupPlayerTable" function does not have any purpose so you may remove it completely
	//SetupPlayerTable();
	
	//
	CreateDynamic3DTextLabel("Presiona {8690e0}Y {FFFFFF}para comprar armas", 0xFFFFFFFF, 2329.4946,-1141.6570,1050.4922, 15.0,INVALID_PLAYER_ID,INVALID_VEHICLE_ID, 1, -1,-1,-1, 100.0);

	SalidaTeam = CreateDynamicPickup(19605, 1,2324.3906,-1149.5472,1050.7101,-1, -1, -1,30.0);
	DisableInteriorEnterExits();
	CargarTextDrawsLobby();
	//Mafioso vehículos

	CreateVehicle(560,2174.8394,-2266.3718,13.0448,226.4185,39,39,120);
	CreateVehicle(560,2167.0764,-2274.0769,13.0443,226.3587,39,39,120);
	CreateVehicle(560,2159.6240,-2279.7139,13.0288,225.6630,39,39,120);
	CreateVehicle(522,2188.4141,-2254.5857,13.0256,227.0318,39,39,120);
	CreateVehicle(522,2190.0857,-2252.7896,13.0549,233.1197,39,39,120);
	
	
	//Motero vehiculos
    CreateVehicle(463,1887.6654,-2027.4518,12.9417,180.5804,3,3,120); // //Moteros vehicle freeway
	CreateVehicle(463,1883.4153,-2027.3689,12.9323,180.9135,3,3,120); // //Moteros vehicle freeway
	CreateVehicle(463,1878.5465,-2027.4851,12.9397,180.8847,3,3,120); // //Moteros vehicle freeway
	CreateVehicle(403,1873.3048,-2033.9310,14.0814,280.0268,3,3,120); // //Moteros vehicle Trailer

	//Groove Street
    CreateVehicle(536,2482.8918,-1654.8175,13.1130,88.3504,86,86,120); // coche groove 1
	CreateVehicle(566,2473.4773,-1683.8734,13.2850,327.5403,86,86,120); // coche groove 2
	CreateVehicle(468,2499.5979,-1684.3402,13.0887,19.8442,86,86,120); // coche groove 3
	CreateVehicle(468,2501.2732,-1683.9790,13.0923,24.1305,86,86,120); // coche groove 4
	CreateVehicle(536,2512.8455,-1671.8163,13.2072,42.6129,86,86,120); // coche groove 5


	//Vagabundos
	CreateVehicle(405,2189.8481,-1799.1582,13.3513,359.6827,2,2,120); // Vagabundos coche 1
	CreateVehicle(424,2164.4270,-1809.2600,13.2154,248.9376,2,2,120); // Vagabundos coche 2
	CreateVehicle(568,2165.5188,-1792.4004,13.2248,270.7703,2,2,120); // Vagabundos coche 3
	
    
    new query[180];
	mysql_format(g_SQL,query,sizeof(query),"SELECT * FROM `teams` where `estado`='1'");
	mysql_tquery(g_SQL, query, "CargarTeams","d",1);
	
	//Textdraws
	//Player Textdraws
	

	StatsInfo = TextDrawCreate(437.000000, 308.000000, "~g~Ranking de equipos:~n~~w~ ] Los domadores                           5000");
	TextDrawFont(StatsInfo, 2);
	TextDrawLetterSize(StatsInfo, 0.166666, 1.099997);
	TextDrawTextSize(StatsInfo, 621.000000, 0.000000);
	TextDrawSetOutline(StatsInfo, 1);
	TextDrawSetShadow(StatsInfo, 0);
	TextDrawAlignment(StatsInfo, 1);
	TextDrawColor(StatsInfo, -1);
	TextDrawBackgroundColor(StatsInfo, 255);
	TextDrawBoxColor(StatsInfo, 50);
	TextDrawUseBox(StatsInfo, 0);
	TextDrawSetProportional(StatsInfo, 1);
	TextDrawSetSelectable(StatsInfo, 0);

	
	SetTimer("ActualizarRanking",1000,true);
	SetTimer("BajarTiempos",1000,true);
	return 1;
}
forward BajarTiempos();
public BajarTiempos(){
	foreach(Player,i){
	    if(!AC_IsPlayerAFK(i)){
         	if(Player[i][IsLoggedIn] == true){

         	    if(Player[i][TiempoSAN] > 0) {
         	        new string[80];
         	        Player[i][TiempoSAN]--;
         	        TogglePlayerControllable(i,0);
     	            format(string, sizeof(string),"Tiempo en jail: ~n~~r~%d ~w~horas ~r~%d ~w~min ~r~%d ~w~segundos",Player[i][TiempoSAN]/3600,Player[i][TiempoSAN]/60,Player[i][TiempoSAN]%(60));
     	            GameTextForPlayer(i, string, 1000, 4);


         	    }
         	    if(UltimaOferta__TIME[i] > 0){
         	        UltimaOferta__TIME[i]--;
         	    }
         	    if(TiempoOfertarEXS[i] > 0){
         	        TiempoOfertarEXS[i]--;
         	    }
         	    if(Tiempo_Invitacion[i]> 0){
         	        Tiempo_Invitacion[i]--;
         	        if(Tiempo_Invitacion[i] == 0){
         	            Duelo_temp_USERID[i] = -1;
						Duelo_temp_APUESTA[i] = -1;
						Duelo_temp_Arma1[i] = -1;
						Duelo_temp_Arma2[i] = -1;
						Duelo_temp_Lugar[i] = -1;
						Invitado[i] = false;
						Invitado[Duelo_temp_USERID[i]] = false;
						Duelo_temp_INVI_POR[Duelo_temp_USERID[i]] = -1;
		
         	        
         	        }
                }
         	}
     	}
	}
	return 1;
}
forward CargarTeams(d);
public CargarTeams(d){
    if(cache_num_rows() == 0)
	{
		print("No se encontró ningún team");
		return 1;
	}
	switch(d)
	{
		case 1:
		{
			new Rows = cache_num_rows();
			for(new i = 0; i < Rows; i++)
			{
                cache_get_value_int(i, "id", TeamInfo[i+4][ID]);
                cache_get_value(i, "nombre", TeamInfo[i+4][Nombre],40);
                cache_get_value(i, "Color", TeamInfo[i+4][Color],11);
                cache_get_value_int(i, "estado", TeamInfo[i+4][Estado]);
                cache_get_value(i, "Rango1", TeamInfo[i+4][Rango1],24);
                cache_get_value(i, "Rango2", TeamInfo[i+4][Rango2],24);
                cache_get_value(i, "Rango3", TeamInfo[i+4][Rango3],24);
                cache_get_value(i, "Rango4", TeamInfo[i+4][Rango4],24);
                cache_get_value(i, "Rango5", TeamInfo[i+4][Rango5],24);
                cache_get_value_int(i, "KillsTotal", TeamInfo[i+4][KillsTotal]);
                cache_get_value_float(i, "salida_x", TeamInfo[i+4][SalidaX]);
                cache_get_value_float(i, "salida_y", TeamInfo[i+4][SalidaY]);
                cache_get_value_float(i, "salida_z", TeamInfo[i+4][SalidaZ]);
                Iter_Add(TeamsActivos, i+4);
			}
		}

	}
    return 1;
}
forward ActualizarRanking();
public ActualizarRanking()
{   
    new query[180];
	mysql_format(g_SQL,query,sizeof(query),"SELECT * FROM `teams` where `estado`='1' ORDER BY `KillsTotal` DESC");
	mysql_tquery(g_SQL, query, "Actualizacion","d",1);
	
	
   
    return 1;
}
forward Actualizacion(d);
public Actualizacion(d){
	new nombre[40];
	new kills;
	new newtext[41];
    new strfinal[1000] = "~g~Ranking de equipos:~n~";
	new Rows = cache_num_rows();
	for(new i = 0; i < Rows; i++)
	{
	    cache_get_value(i, "nombre", nombre);
	    cache_get_value_int(i, "KillsTotal", kills);
	    format(newtext, sizeof(newtext), "~w~] %s_____%d~n~", nombre,kills);
		strcat(strfinal, newtext);
	}
	
	TextDrawSetString(StatsInfo, strfinal);

}
stock CargarTextDrawsLobby(){
	//Textdraws
	TextdrawLobby[0] = TextDrawCreate(320.000000, 1.000000, "_");
	TextDrawFont(TextdrawLobby[0], 1);
	TextDrawLetterSize(TextdrawLobby[0], 0.600000, 7.150004);
	TextDrawTextSize(TextdrawLobby[0], 302.500000, 642.500000);
	TextDrawSetOutline(TextdrawLobby[0], 1);
	TextDrawSetShadow(TextdrawLobby[0], 0);
	TextDrawAlignment(TextdrawLobby[0], 2);
	TextDrawColor(TextdrawLobby[0], -1);
	TextDrawBackgroundColor(TextdrawLobby[0], 255);
	TextDrawBoxColor(TextdrawLobby[0], 135);
	TextDrawUseBox(TextdrawLobby[0], 1);
	TextDrawSetProportional(TextdrawLobby[0], 1);
	TextDrawSetSelectable(TextdrawLobby[0], 0);

	TextdrawLobby[1] = TextDrawCreate(318.000000, 63.000000, "_");
	TextDrawFont(TextdrawLobby[1], 1);
	TextDrawLetterSize(TextdrawLobby[1], 0.600000, 0.300004);
	TextDrawTextSize(TextdrawLobby[1], 302.500000, 642.500000);
	TextDrawSetOutline(TextdrawLobby[1], 1);
	TextDrawSetShadow(TextdrawLobby[1], 0);
	TextDrawAlignment(TextdrawLobby[1], 2);
	TextDrawColor(TextdrawLobby[1], -1);
	TextDrawBackgroundColor(TextdrawLobby[1], 255);
	TextDrawBoxColor(TextdrawLobby[1], -25227009);
	TextDrawUseBox(TextdrawLobby[1], 1);
	TextDrawSetProportional(TextdrawLobby[1], 1);
	TextDrawSetSelectable(TextdrawLobby[1], 0);

	TextdrawLobby[2] = TextDrawCreate(320.000000, 395.000000, "_");
	TextDrawFont(TextdrawLobby[2], 1);
	TextDrawLetterSize(TextdrawLobby[2], 0.600000, 5.899999);
	TextDrawTextSize(TextdrawLobby[2], 302.500000, 642.500000);
	TextDrawSetOutline(TextdrawLobby[2], 1);
	TextDrawSetShadow(TextdrawLobby[2], 0);
	TextDrawAlignment(TextdrawLobby[2], 2);
	TextDrawColor(TextdrawLobby[2], -1);
	TextDrawBackgroundColor(TextdrawLobby[2], 255);
	TextDrawBoxColor(TextdrawLobby[2], 135);
	TextDrawUseBox(TextdrawLobby[2], 1);
	TextDrawSetProportional(TextdrawLobby[2], 1);
	TextDrawSetSelectable(TextdrawLobby[2], 0);

	TextdrawLobby[3] = TextDrawCreate(320.000000, 395.000000, "_");
	TextDrawFont(TextdrawLobby[3], 1);
	TextDrawLetterSize(TextdrawLobby[3], 0.600000, 0.250004);
	TextDrawTextSize(TextdrawLobby[3], 302.500000, 638.000000);
	TextDrawSetOutline(TextdrawLobby[3], 1);
	TextDrawSetShadow(TextdrawLobby[3], 0);
	TextDrawAlignment(TextdrawLobby[3], 2);
	TextDrawColor(TextdrawLobby[3], -1);
	TextDrawBackgroundColor(TextdrawLobby[3], 255);
	TextDrawBoxColor(TextdrawLobby[3], -25227009);
	TextDrawUseBox(TextdrawLobby[3], 1);
	TextDrawSetProportional(TextdrawLobby[3], 1);
	TextDrawSetSelectable(TextdrawLobby[3], 0);

	TextdrawLobby[4] = TextDrawCreate(385.000000, 41.000000, "EXTREME SHOTS");
	TextDrawFont(TextdrawLobby[4], 2);
	TextDrawLetterSize(TextdrawLobby[4], 0.383333, 1.600000);
	TextDrawTextSize(TextdrawLobby[4], 400.000000, 17.000000);
	TextDrawSetOutline(TextdrawLobby[4], 1);
	TextDrawSetShadow(TextdrawLobby[4], 0);
	TextDrawAlignment(TextdrawLobby[4], 3);
	TextDrawColor(TextdrawLobby[4], -1);
	TextDrawBackgroundColor(TextdrawLobby[4], 255);
	TextDrawBoxColor(TextdrawLobby[4], 50);
	TextDrawUseBox(TextdrawLobby[4], 0);
	TextDrawSetProportional(TextdrawLobby[4], 1);
	TextDrawSetSelectable(TextdrawLobby[4], 0);

	TextdrawLobby[5] = TextDrawCreate(57.000000, 413.000000, "CREDITOS");
	TextDrawFont(TextdrawLobby[5], 2);
	TextDrawLetterSize(TextdrawLobby[5], 0.304166, 1.700000);
	TextDrawTextSize(TextdrawLobby[5], 16.500000, 90.500000);
	TextDrawSetOutline(TextdrawLobby[5], 1);
	TextDrawSetShadow(TextdrawLobby[5], 0);
	TextDrawAlignment(TextdrawLobby[5], 2);
	TextDrawColor(TextdrawLobby[5], -1);
	TextDrawBackgroundColor(TextdrawLobby[5], 255);
	TextDrawBoxColor(TextdrawLobby[5], 200);
	TextDrawUseBox(TextdrawLobby[5], 0);
	TextDrawSetProportional(TextdrawLobby[5], 1);
	TextDrawSetSelectable(TextdrawLobby[5], 1);

	TextdrawLobby[6] = TextDrawCreate(320.000000, 400.000000, "_");
	TextDrawFont(TextdrawLobby[6], 1);
	TextDrawLetterSize(TextdrawLobby[6], 0.600000, 5.200007);
	TextDrawTextSize(TextdrawLobby[6], 332.000000, 96.000000);
	TextDrawSetOutline(TextdrawLobby[6], 1);
	TextDrawSetShadow(TextdrawLobby[6], 0);
	TextDrawAlignment(TextdrawLobby[6], 2);
	TextDrawColor(TextdrawLobby[6], -1);
	TextDrawBackgroundColor(TextdrawLobby[6], 255);
	TextDrawBoxColor(TextdrawLobby[6], -25227009);
	TextDrawUseBox(TextdrawLobby[6], 1);
	TextDrawSetProportional(TextdrawLobby[6], 1);
	TextDrawSetSelectable(TextdrawLobby[6], 0);

	TextdrawLobby[7] = TextDrawCreate(319.000000, 414.000000, "JUGAR");
	TextDrawFont(TextdrawLobby[7], 2);
	TextDrawLetterSize(TextdrawLobby[7], 0.370832, 1.949999);
	TextDrawTextSize(TextdrawLobby[7], 16.500000, 90.500000);
	TextDrawSetOutline(TextdrawLobby[7], 1);
	TextDrawSetShadow(TextdrawLobby[7], 0);
	TextDrawAlignment(TextdrawLobby[7], 2);
	TextDrawColor(TextdrawLobby[7], -1);
	TextDrawBackgroundColor(TextdrawLobby[7], 255);
	TextDrawBoxColor(TextdrawLobby[7], 200);
	TextDrawUseBox(TextdrawLobby[7], 0);
	TextDrawSetProportional(TextdrawLobby[7], 1);
	TextDrawSetSelectable(TextdrawLobby[7], 1);

	TextdrawLobby[8] = TextDrawCreate(469.000000, 413.000000, "CUENTA");
	TextDrawFont(TextdrawLobby[8], 2);
	TextDrawLetterSize(TextdrawLobby[8], 0.304166, 1.700000);
	TextDrawTextSize(TextdrawLobby[8], 16.500000, 90.500000);
	TextDrawSetOutline(TextdrawLobby[8], 1);
	TextDrawSetShadow(TextdrawLobby[8], 0);
	TextDrawAlignment(TextdrawLobby[8], 2);
	TextDrawColor(TextdrawLobby[8], -1);
	TextDrawBackgroundColor(TextdrawLobby[8], 255);
	TextDrawBoxColor(TextdrawLobby[8], 200);
	TextDrawUseBox(TextdrawLobby[8], 0);
	TextDrawSetProportional(TextdrawLobby[8], 1);
	TextDrawSetSelectable(TextdrawLobby[8], 1);

	TextdrawLobby[9] = TextDrawCreate(584.000000, 413.000000, "CONFIG");
	TextDrawFont(TextdrawLobby[9], 2);
	TextDrawLetterSize(TextdrawLobby[9], 0.304166, 1.700000);
	TextDrawTextSize(TextdrawLobby[9], 16.500000, 90.500000);
	TextDrawSetOutline(TextdrawLobby[9], 1);
	TextDrawSetShadow(TextdrawLobby[9], 0);
	TextDrawAlignment(TextdrawLobby[9], 2);
	TextDrawColor(TextdrawLobby[9], -1);
	TextDrawBackgroundColor(TextdrawLobby[9], 255);
	TextDrawBoxColor(TextdrawLobby[9], 200);
	TextDrawUseBox(TextdrawLobby[9], 0);
	TextDrawSetProportional(TextdrawLobby[9], 1);
	TextDrawSetSelectable(TextdrawLobby[9], 1);
	
	TextdrawLobby[10] = TextDrawCreate(178.000000, 414.000000, "AYUDA");
	TextDrawFont(TextdrawLobby[10], 2);
	TextDrawLetterSize(TextdrawLobby[10], 0.324999, 1.700000);
	TextDrawTextSize(TextdrawLobby[10], 16.500000, 90.500000);
	TextDrawSetOutline(TextdrawLobby[10], 1);
	TextDrawSetShadow(TextdrawLobby[10], 0);
	TextDrawAlignment(TextdrawLobby[10], 2);
	TextDrawColor(TextdrawLobby[10], -1);
	TextDrawBackgroundColor(TextdrawLobby[10], 255);
	TextDrawBoxColor(TextdrawLobby[10], 200);
	TextDrawUseBox(TextdrawLobby[10], 0);
	TextDrawSetProportional(TextdrawLobby[10], 1);
	TextDrawSetSelectable(TextdrawLobby[10], 1);
}
#define     COLOR_SELECT_TD 	0x00FF00FF
new select[MAX_PLAYERS];
forward ReenviarSelect(playerid);
public ReenviarSelect(playerid){
	SelectTextDraw(playerid, COLOR_SELECT_TD);
	return 1;
}
stock EnviarLobby(playerid){

	for(new n = 0; n < 80; n++){
	    SendClientMessage(playerid, 0xFFFFFFAA, "");
	}

	Player[playerid][EnLobby] = true;
	SetPlayerScore(playerid,Player[playerid][Score]);
	TogglePlayerControllable(playerid,0);
	for(new i = 0; i < 11; i++){
		TextDrawShowForPlayer(playerid,TextdrawLobby[i]);
	}
	SelectTextDraw(playerid, COLOR_SELECT_TD);
	select[playerid] = SetTimerEx("ReenviarSelect", 1000, true, "i", playerid);
    ResetPlayerMoney(playerid);
    GivePlayerMoney(playerid,Player[playerid][Dinero]);
    EnviarPosicion(playerid,2324.419921,-1145.568359,1050.710083,12,playerid+random(5));
	SetPlayerTeam(playerid, TeamSelected[playerid]);
	if(Player[playerid][TiempoSAN] > 0){
	    return SendClientMessage(playerid,-1,"{FF0000}>!< {FFFFFF}Te encuentras sancionado, Cumple tu condena para jugar.");
	}
	SendClientMessage(playerid, 0xFFFFFFAA, "{99A4FF}• {FFFFFF}Bienvenido a la comunidad {99A4FF}Extreme Shots TDM");
	SendClientMessage(playerid, 0xFFFFFFAA, "{99A4FF}• {FFFFFF}Recuerda leer las {99A4FF}/reglas {FFFFFF}y {99A4FF}/comandos {FFFFFF}del servidor.");
	SendClientMessage(playerid, 0xFFFFFFAA, "{99A4FF}• {FFFFFF}Para configurar tu armas, clima, hora revisa {99A4FF}/config");
	
    
	return 1;
}
stock EnviarPosicion(playerid,Float:X,Float:Y,Float:Z,interior,vw){
    SetPlayerPos(playerid, X, Y, Z);
    SetPlayerInterior(playerid,interior);
    SetPlayerVirtualWorld(playerid,vw);
    return 1;
}
stock ChatAdmin(playerid,texto[]){
    new string[128];
	format(string,sizeof(string),"%s: %s",Player[playerid][Name],texto);
	foreach(Player,i){
	    SendClientMessage(i, 0x0BB52EFF, string);
	}
	return 1;
}
stock LogToAdmin(texto[]){
	foreach(Player,i){
	    if(Player[i][Admin]> 0){
	        SendClientMessage(i, 0x0BB52EFF, texto);
	    }
	    
	}
	return 1;
}
new tempidteam[MAX_PLAYERS][MAX_TEAMS];
public OnPlayerClickTextDraw(playerid, Text:clickedid)
{
    if(clickedid == TextdrawLobby[7]) //Click en "JUGAR"
    {
		new string[156];
		new string2[300];
		new string_concat[300+156];
		new u = 0;
		format(string, 300, "{07922B}Groove Street\t{FFFFFF}Público\n{CACACA}Mafiosos\t{FFFFFF}Público\n{10C2F0}Vagabundos\t{FFFFFF}Público\n{540B0B}Moteros\t{FFFFFF}Público\n");
		foreach (new i : TeamsActivos){
		    if(TeamInfo[i][Estado] == 1 ){
		        format(string2, sizeof(string2), "%s{%s}%s\t{FFFFFF}Premium",string2,TeamInfo[i][Color],TeamInfo[i][Nombre]);
		    	format(string2, sizeof(string2), "%s\n", string2);
		    	tempidteam[playerid][u+4] = i;
		    	u++;
		    }
		    
		}
		format(string_concat, 300, "%s%s",string,string2);
		ShowPlayerDialog(playerid, DIALOG_SELECT_TEAM, DIALOG_STYLE_TABLIST, "{002BFF}• {FFFF00}• {FF0000}• {FFFFFF}Elige equipo",string_concat,
		"Elegir", "X");
		return 1;
    }
    
    if(clickedid == TextdrawLobby[5]){//click en "CREDITOS"
         SendClientMessage(playerid, 0xFFFFFFAA, "CREDITOS");
         CancelSelectTextDraw(playerid);
         return 1;
    }
    
    if(clickedid == TextdrawLobby[10]){

        MostrarAyuda(playerid);
        return 1;
    }
    if(clickedid == TextdrawLobby[8]){
        MostrarDatosCuenta(playerid);
        return 1;
    }
    if(clickedid == TextdrawLobby[9]){
        MostrarConfig(playerid);
        return 1;
    }
    
    return 0;
}
stock MostrarAyuda(playerid){
    new str[1136+1];
	format(str, sizeof(str), "%s{8690e0} COMANDOS GENERALES:\n{FFFFFF}/Cuenta  (Estadísticas de la cuenta).\n/Creditos (Personal encargado del servidor).\n/Reglas (Normas de la comuni", str);
	format(str, sizeof(str), "%sdad).\n/Animaciones (Animaciones del jugador).\n/Pagar (Dar dinero a jugadores).\n/Reportar (Reportar a jugadores).\n/Tienda (Comprar accesorios, autos, armas, etc).\n/ID (Visualizar Ping, FPS, P", str);
	format(str, sizeof(str), "%sL de jugadores).\n/Niveles (Beneficios por score).\n/Actualizaciones (Mejoras del servidor).\n/Radios (Estaciones de radio online).\n/EXS (Vender moneda del servidor).\n/Comprar (Aceptar compra).", str);
	format(str, sizeof(str), "%s\n/Skills (Habilidad de cada arma).\n/Amasinfo (Bonificación de cada arma).\n/Config (Activar o desactivar opciones).\n\n{8690e0} ACCESORIOS:\n{FFFFFF}/Accesorios (Activar o desactivar las prenda", str);
	format(str, sizeof(str), "%ss).\n/Editaraccesorios (Editar posición de prendas).\n/Venderaccesorios (Vender prenda).\n\n{8690e0} EQUIPO:\n{FFFFFF}/Equipos (Elegir un equipo).\n/R (Hablar por radio)\n/Equipo (Informacion de", str);
	format(str, sizeof(str), "%sl equipo) {FFFF00}(Premium)\n{FFFFFF}/Abandonar (Salir del equipo) {FFFF00}(Premium)\n{FFFFFF}{FF0000}Nota: {FFFFFF}Creación de equipo premium tiene un costo de {1AFF00}$2.000.000.", str);

	ShowPlayerDialog(playerid, DIALOG_AYUDA, DIALOG_STYLE_MSGBOX, "{002BFF}• {FFFF00}• {FF0000}• {FFFFFF}Comandos", str, "Siguiente", "X");
}
stock MostrarDatosCuenta(playerid){
    new str[508+1];
	format(str, sizeof(str), "%s{5FBEFD}•  {FFFFFF}Nombre: %s\n{5FBEFD}•  {FFFFFF}Score: %d\n{5FBEFD}•  {FFFFFF}Dinero: %d\n{5FBEFD}•  {FFFFFF}Ropa: %d\n{5FBEFD}•  {FFFFFF}Administ", str,Player[playerid][Name],Player[playerid][Score],Player[playerid][Dinero],Player[playerid][Skin]);
	format(str, sizeof(str), "%srador: %d\n{5FBEFD}•  {FFFFFF}Asesinatos: %d\n{5FBEFD}•  {FFFFFF}Muertes: %d\n{5FBEFD}•  {FFFFFF}Duelos Ganados: %d\n{5FBEFD}•  {FFFFFF}Duelos Perdidos: %d\n{5FBEFD}•  {FFFFFF}Eventos Ganados: %d\n{5F", str,Player[playerid][Admin],Player[playerid][Kills],Player[playerid][Deaths],Player[playerid][d_ganados],Player[playerid][d_perdidos],Player[playerid][e_ganados]);
	format(str, sizeof(str), "%sBEFD}•  {FFFFFF}Casa: %d\n{5FBEFD}•  {FFFFFF}Piezas: %d\n{5FBEFD}•  {FFFF00}EXS: %d\n{5FBEFD}•  {FFFFFF}Armas especiales: Vacío - Vacío - Vacío - Vacío\n", str,Player[playerid][CasaID],Player[playerid][Piezas],Player[playerid][EXS]);

	ShowPlayerDialog(playerid, DIALOG_CUENTA, DIALOG_STYLE_MSGBOX, "{002BFF}• {FFFF00}• {FF0000}• {FFFFFF}Cuenta", str, "Aceptar", "");
}
stock MostrarTiendaArmas(playerid){
    new str[500];
    format(str, sizeof(str), "Arma\tPrecio\tMunición\n{5FBEFD}• {FFFFFF}9mm silenciada\t$300\t200\n{5FBEFD}• {FFFFFF}Escopeta\t$400\t50\n{5FBEFD}• {FFFFFF}SPAS\t$1200\t70\n{5FBEFD}• {FFFFFF}MP5\t$500\t100\n{5FBEFD}• {FFFFFF}AK-47\t$500\t100\n{5FBEFD}• {FFFFFF}M4\t$600\t150\n{5FBEFD}• {FFFFFF}Rifle\t$500\t50\n{5FBEFD}• {FFFFFF}Sniper\t$500\t700\n{5FBEFD}• {FFFFFF}Motosierra\t$400\t50\n{5FBEFD}• {FFFFFF}Granada\t$600\t1\n{5FBEFD}• {FFFFFF}Chaleco antibalas\t$1000\t1\n", str);
	ShowPlayerDialog(playerid, DIALOG_ARMAS, DIALOG_STYLE_TABLIST_HEADERS, "{002BFF}• {FFFF00}• {FF0000}• {FFFFFF}Armas",str,"Comprar", "X");
}

stock MostrarConfig(playerid){
    new DuelosEstadoX[22] = "{FF0000}OFF";
	new MPsEstadoX[22] = "{FF0000}OFF";
	new SpawnHouseEstadoX[22] = "{FF0000}OFF";
	new InfoRankEstadoX[22] = "{FF0000}OFF";
	new MusicEventEstadoX[22] = "{FF0000}OFF";
    
	if(Player[playerid][DuelosEstado] == true){ DuelosEstadoX = "{1FFF02}ON"; }
	if(Player[playerid][MPsEstado] == true){ MPsEstadoX = "{1FFF02}ON"; }
	if(Player[playerid][SpawnHouseEstado] == true){ SpawnHouseEstadoX = "{1FFF02}ON"; }
	if(Player[playerid][InfoRankEstado] == true){ InfoRankEstadoX = "{1FFF02}ON"; }
	if(Player[playerid][MusicEventEstado] == true){ MusicEventEstadoX = "{1FFF02}ON"; }
//%sConfiguración\tEstado\n{5FBEFD}• {FFFFFF}Configuración de armas\t\n{5FBEFD}• {FFFFFF}Configuración de clima\t\n{5FBEFD}• {FFFFFF}Configuración de hora\t\n{5FBEFD}• {FFFFFF}Configuración de peleas\t\n{5FBEFD}• {FFFFFF}Cambiar contraseña\t\n{5FBEFD}• {FFFFFF}Mensajes privados\t%s\n{5FBEFD}• {FFFFFF}Invitación de duelos\t%s\n{5FBEFD}• {FFFFFF}Sonidos de racha\t%s\n{5FBEFD}• {FFFFFF}Musica de eventos\t%s\n{5FBEFD}• {FFFFFF}Aparecer en casa\t%s\n{5FBEFD}• {FFFFFF}Información y Ranking\t%s\n
    new str[550];
    format(str, sizeof(str), "Configuración\tEstado\n{5FBEFD}• {FFFFFF}Configuración de armas\t\n{5FBEFD}• {FFFFFF}Configuración de clima\t\n{5FBEFD}• {FFFFFF}Configuración de hora\t\n{5FBEFD}• {FFFFFF}Configuración de peleas\t\n{5FBEFD}• {FFFFFF}Cambiar contraseña\t\n{5FBEFD}• {FFFFFF}Mensajes privados\t%s\n{5FBEFD}• {FFFFFF}Invitación de duelos\t%s\n{5FBEFD}• {FFFFFF}Sonidos de racha\t{FF0000}OFF\n",MPsEstadoX,DuelosEstadoX);
    format(str, sizeof(str), "%s{5FBEFD}• {FFFFFF}Musica de eventos\t%s\n{5FBEFD}• {FFFFFF}Aparecer en casa\t%s\n{5FBEFD}• {FFFFFF}Información y Ranking\t%s\n",str,MusicEventEstadoX,SpawnHouseEstadoX,InfoRankEstadoX);
	ShowPlayerDialog(playerid, DIALOG_CONFIG, DIALOG_STYLE_TABLIST_HEADERS, "{002BFF}• {FFFF00}• {FF0000}• {FFFFFF}Configuración general",str,"Elegir", "X");
	return 1;
}
public OnGameModeExit()
{
	// save all player data before closing connection
	for (new i = 0, j = GetPlayerPoolSize(); i <= j; i++) // GetPlayerPoolSize function was added in 0.3.7 version and gets the highest playerid currently in use on the server
	{
		if (IsPlayerConnected(i))
		{
			// reason is set to 1 for normal 'Quit'
			OnPlayerDisconnect(i, 1);
		}
	}

	mysql_close(g_SQL);
	return 1;
}

public OnPlayerConnect(playerid)
{
    StatsInfoUser[playerid] = CreatePlayerTextDraw(playerid, 28.000000, 308.000000, "~b~Equipos: ~w~Vagabundos~n~~y~Ping: ~w~101 - ~g~FPS: ~w~ 101 - ~r~PL: 0.00");
	PlayerTextDrawFont(playerid, StatsInfoUser[playerid], 2);
	PlayerTextDrawLetterSize(playerid, StatsInfoUser[playerid], 0.187499, 1.199997);
	PlayerTextDrawTextSize(playerid, StatsInfoUser[playerid], 359.000000, 51.500000);
	PlayerTextDrawSetOutline(playerid, StatsInfoUser[playerid], 1);
	PlayerTextDrawSetShadow(playerid, StatsInfoUser[playerid], 0);
	PlayerTextDrawAlignment(playerid, StatsInfoUser[playerid], 1);
	PlayerTextDrawColor(playerid, StatsInfoUser[playerid], -1);
	PlayerTextDrawBackgroundColor(playerid, StatsInfoUser[playerid], 255);
	PlayerTextDrawBoxColor(playerid, StatsInfoUser[playerid], 50);
	PlayerTextDrawUseBox(playerid, StatsInfoUser[playerid], 0);
	PlayerTextDrawSetProportional(playerid, StatsInfoUser[playerid], 1);
	PlayerTextDrawSetSelectable(playerid, StatsInfoUser[playerid], 0);
	
	g_MysqlRaceCheck[playerid]++;

	// reset player data
	static const empty_player[E_PLAYERS];
	Player[playerid] = empty_player;

	GetPlayerName(playerid, Player[playerid][Name], MAX_PLAYER_NAME);

	// send a query to recieve all the stored player data from the table
	new query[103];
	mysql_format(g_SQL, query, sizeof query, "SELECT * FROM `players` WHERE `username` = '%e' LIMIT 1", Player[playerid][Name]);
	mysql_tquery(g_SQL, query, "OnPlayerDataLoaded", "dd", playerid, g_MysqlRaceCheck[playerid]);
	return 1;
}
public OnPlayerKeyStateChange(playerid, newkeys, oldkeys){
	
    if(newkeys == KEY_YES){
        if(IsPlayerInRangeOfPoint(playerid,10.0, 2329.4946,-1141.6570,1050.4922)){
			MostrarTiendaArmas(playerid);
			return 1;
		}

	}
	
	return 1;
}
public OnPlayerDisconnect(playerid, reason)
{
	if(Invitado[playerid] == true){
		Duelo_temp_USERID[playerid] = -1;
		Duelo_temp_APUESTA[playerid] = -1;
		Duelo_temp_Arma1[playerid] = -1;
		Duelo_temp_Arma2[playerid] = -1;
		Duelo_temp_Lugar[playerid] = -1;
		Invitado[playerid] = false;
		Invitado[Duelo_temp_USERID[playerid]] = false;
		Duelo_temp_INVI_POR[Duelo_temp_USERID[playerid]] = -1;

	}
    KillTimer(ActualizarInfo[playerid]);
    PlayerTextDrawDestroy(playerid, StatsInfoUser[playerid]);
    ActualizarUserDB(playerid,"TiempoSAN",Player[playerid][TiempoSAN]);
	g_MysqlRaceCheck[playerid]++;
	UpdatePlayerData(playerid, reason);

	// if the player was kicked (either wrong password or taking too long) during the login part, remove the data from the memory
	if (cache_is_valid(Player[playerid][Cache_ID]))
	{
		cache_delete(Player[playerid][Cache_ID]);
		Player[playerid][Cache_ID] = MYSQL_INVALID_CACHE;
	}

	// if the player was kicked before the time expires (30 seconds), kill the timer
	if (Player[playerid][LoginTimer])
	{
		KillTimer(Player[playerid][LoginTimer]);
		Player[playerid][LoginTimer] = 0;
	}
	// sets "IsLoggedIn" to false when the player disconnects, it prevents from saving the player data twice when "gmx" is used
	Player[playerid][IsLoggedIn] = false;
	KillTimer(select[playerid]);
	
	RachaKills[playerid] = 0;
	TeamSelected[playerid] = NO_TEAM;
	UltimaOferta__EXS[playerid] = 0;
	UltimaOferta__COSTO[playerid]= 0;
	UltimaOferta__TIME[playerid]= 0;
	UltimaOferta__USERID[playerid]= 0;
	TiempoOfertarEXS[playerid]= 0;

	return 1;
}

public OnPlayerGiveDamage(playerid, damagedid, Float:amount, weaponid, bodypart)
{
    return 1;
}
public OnPlayerTakeDamage(playerid, issuerid, Float:amount, weaponid, bodypart)
{
    if(issuerid != INVALID_PLAYER_ID && weaponid == 49)
    {
        new autoid = GetPlayerVehicleID(issuerid);
        SetVehicleToRespawn(autoid);
        new Float:xp,Float:yp,Float:zp;
		GetPlayerPos(issuerid,xp,yp,zp);
	    EnviarPosicion(issuerid,xp,yp,zp+5.3,0,0);
	    SendClientMessage(issuerid,-1,"{FF0000}>!< {FFFFFF}Fuistes slapeado y el vehículo reiniciado.");
	    
    }
    return 1;
}
new oldfps[MAX_PLAYERS];

stock GetPlayerFPS(playerid)
{
	SetPVarInt(playerid,"DrunkL",GetPlayerDrunkLevel(playerid));
	if(GetPVarInt(playerid,"DrunkL") < 100){
	    SetPlayerDrunkLevel(playerid,2000);
	}
	else{
	    if(GetPVarInt(playerid,"LDrunkL") != GetPVarInt(playerid,"DrunkL"))
		{
	        SetPVarInt(playerid,"FPS",(GetPVarInt(playerid,"LDrunkL") - GetPVarInt(playerid,"DrunkL")));
	        SetPVarInt(playerid, "LDrunkL", GetPVarInt(playerid, "DrunkL"));
	        if((GetPVarInt(playerid, "FPS") > 0) && (GetPVarInt(playerid,"FPS") < 256))
			{
				oldfps[playerid] = GetPVarInt(playerid,"FPS") - 1;
	            return GetPVarInt(playerid,"FPS") - 1;
	        }
	    }
	}
	return oldfps[playerid];
	
}


forward ActualizarInfoz(playerid);
public ActualizarInfoz(playerid){
	if(Player[playerid][IsLoggedIn] == true){
	    if(Player[playerid][InfoRankEstado] == true){
		    new name[40] = "ninguno";
			if(TeamSelected[playerid] == 0) { name = "Groove Street"; }
			else if(TeamSelected[playerid] == 1) name = "Mafiosos";
			else if(TeamSelected[playerid] == 2) name = "Vagabundos";
			else if(TeamSelected[playerid] == 3) name = "Moteros";
			if(TeamSelected[playerid] > 3){
			    format(name, sizeof(name), "%s",TeamInfo[TeamSelected[playerid]][Nombre]);
			}
		    new tdstring[130];
		    format(tdstring, 130, "~b~Equipos: ~w~%s~n~~y~Ping: ~w~%d - ~g~FPS: ~w~ %d - ~r~PL: %.2f",name,GetPlayerPing(playerid),GetPlayerFPS(playerid),NetStats_PacketLossPercent(playerid));
		 	PlayerTextDrawSetString(playerid, StatsInfoUser[playerid], tdstring);

		}
	}
	return 1;
}
public OnPlayerSpawn(playerid)
{
	EnBase[playerid] = true;
    if(Player[playerid][InfoRankEstado] == true){
 		TextDrawShowForPlayer(playerid,StatsInfo);
	    PlayerTextDrawShow(playerid, StatsInfoUser[playerid]);
	    KillTimer(ActualizarInfo[playerid]);
     	ActualizarInfo[playerid] = SetTimerEx("ActualizarInfoz", 500, true, "i", playerid);

	}
	EnviarPosicion(playerid,2324.419921,-1145.568359,1050.710083,12,TeamSelected[playerid]);
	SetPlayerTeam(playerid, TeamSelected[playerid]);
	DarArmasNivel(playerid);
	ResetPlayerMoney(playerid);
 	GivePlayerMoney(playerid,Player[playerid][Dinero]);
	return 1;
}

public OnPlayerPickUpDynamicPickup(playerid,pickupid){
    if(pickupid == SalidaTeam)
    { 
        EnBase[playerid] = false;
	    switch(TeamSelected[playerid]){
	        case 0: return EnviarPosicion(playerid,2495.3730,-1686.3546,13.5142,0,0); //groove
	        case 1: return EnviarPosicion(playerid,2179.9829,-2256.3647,14.7734,0,0); //Vagabundos
	        case 2: return EnviarPosicion(playerid,2142.2515,-1803.2446,16.1475,0,0); //Mafiosos
	        case 3: return EnviarPosicion(playerid,1872.7041,-2020.2061,13.5469,0,0); //Moteros
	    }
		new idt = Player[playerid][Team];
		if(TeamSelected[playerid] >= 4){
            return EnviarPosicion(playerid,TeamInfo[idt][SalidaX],TeamInfo[idt][SalidaY],TeamInfo[idt][SalidaZ],0,0);
		}
		return 1;
		
    }
    foreach (new i : PickupVidaActivos){
        if(pickupid == MuertePickup[i])
    	{
    	    new Float:vida;
			GetPlayerHealth(playerid,vida);
			new Float:valor = 100-vida;
			if(valor  >= 45){
			    SetPlayerHealth(playerid,vida+45);
			}
			else if(valor < 45){
			    SetPlayerHealth(playerid,vida+valor);
			}
			DestroyDynamicPickup(MuertePickup[i]);
            Iter_Remove(PickupVidaActivos, i);
            
    	}
    }
    
    return 1;
}

forward VerificacionCorreo(playerid,inputtext[]);
public VerificacionCorreo(playerid,inputtext[]){

    if(cache_num_rows() == 0)
    {

		ShowPlayerDialog(playerid, DIALOG_REGISTER, DIALOG_STYLE_PASSWORD, "{002BFF}•{FFFF00}•{FF0000}• {FFFFFF}Registro", "{FFFFFF}Bienvenido a la comunidad de Extreme Shot TDM.\n\nPor favor introduce una contraseña:", "Ingresar", "X");
	}
	else
	{
		SendClientMessage(playerid,-1,"Este correo electrónico ya se encuentra registrado.");
		SendClientMessage(playerid,-1,"Si necesitas ayuda para recuperar tu cuenta, ingresa al discord oficial.");
		DelayedKick(playerid);
	}
	return 1;
}

public OnPlayerDeath(playerid, killerid, reason)
{
    
	new Float:posx,Float:posy,Float:posz;
	GetPlayerPos(playerid,posx,posy,posz);
	new randomz = random(20);
    MuertePickup[playerid+randomz] = CreateDynamicPickup(1240, 19,posx,posy,posz,-1, -1, -1,30.0);
    Iter_Add(PickupVidaActivos, playerid+randomz);
    SendDeathMessage(killerid, playerid, reason); // Shows the kill in the killfeed
	new name[128];
	RachaKills[killerid]++;
    UpdatePlayerDeaths(playerid);
	UpdatePlayerKills(killerid);
	if(reason == 24){
	    DarDinero(killerid,800);
	    GameTextForPlayer(killerid, "~g~+ ~w~$800", 5000, 4);
	}
	else if(reason == 25){
	    DarDinero(killerid,50);
	    GameTextForPlayer(killerid, "~g~+ ~w~$100", 5000, 4);
	}
	else if(reason == 27){
	    DarDinero(killerid,50);
	    GameTextForPlayer(killerid, "~g~+ ~w~$50", 5000, 4);
	}
	else if(reason == 34){
	    DarDinero(killerid,1000);
	    GameTextForPlayer(killerid, "~g~+ ~w~$1000", 5000, 4);
	}
	
	if(RachaKills[killerid] < 7){
	    SetPlayerWantedLevel(killerid, RachaKills[killerid]);
	}
	if(RachaKills[killerid] == 6 ){
		format(name, 128, "{FA6119}%s superó la racha de 6 asesinatos, acabalo por $3.000",Player[killerid][Name]);
	    SendClientMessageToAll(-1,name);
	    SetPlayerHealth(killerid,100);
	    SetPlayerArmour(killerid,100);
 	}
 	
 	if(RachaKills[playerid] > 5){
 	    DarDinero(killerid,3000);
	    format(name, 128, "{FA6119}%s acabó con la racha de %s, obteniendo $3.000",Player[killerid][Name],Player[playerid][Name]);
	    SendClientMessageToAll(-1,name);
	    SetPlayerHealth(killerid,100);
	    SetPlayerArmour(killerid,100);
 	}
	
    RachaKills[playerid] = 0;
    SetPlayerWantedLevel(playerid, 0);
    QuitarDinero(playerid,100);
 	
	return 1;
}
stock ActualizarUserDB(playerid,name_var[],valor){
	new query[145];
	mysql_format(g_SQL, query, sizeof query, "UPDATE `players` SET `%s` = %d WHERE `id` = %d LIMIT 1",name_var,valor,Player[playerid][ID]);
	mysql_tquery(g_SQL, query);
	return 1;
}

stock DarArmasNivel(playerid){
	if(Player[playerid][EstadoDesert]){
	    GivePlayerWeapon(playerid,24,99999);
	}
    if(Player[playerid][Score] >= 250){ //Nivel 2
		SetPlayerArmour(playerid,10);
		if(Player[playerid][EstadoEscopeta] == true){
		    GivePlayerWeapon(playerid,25,99999);
		}

	}
	if(Player[playerid][Score] >= 500){ //Nivel 3
		SetPlayerArmour(playerid,20);
		if(Player[playerid][EstadoMP5] == true){
		    GivePlayerWeapon(playerid,29,99999);
		}
		if(Player[playerid][EstadoSPAS] == true){
		    GivePlayerWeapon(playerid,27,99999);
		}
	}
	if(Player[playerid][Score] >= 750){ //Nivel 4
		SetPlayerArmour(playerid,30);
		if(Player[playerid][EstadoAK47] == true){
		    GivePlayerWeapon(playerid,29,99999);
		}
	}
	if(Player[playerid][Score] >= 1500){ //Nivel 5
		SetPlayerArmour(playerid,40);
		if(Player[playerid][EstadoM4] == true){
		    GivePlayerWeapon(playerid,31,99999);
		}
	}
	if(Player[playerid][Score] >= 2050){ //Nivel 6
		SetPlayerArmour(playerid,50);
		if(Player[playerid][EstadoRifle] == true){
		    GivePlayerWeapon(playerid,33,99999);
		}
	}
	if(Player[playerid][Score] >= 2600){ //Nivel 7
		SetPlayerArmour(playerid,60);
		if(Player[playerid][EstadoSniper] == true){
		    GivePlayerWeapon(playerid,34,99999);
		}
	}
	if(Player[playerid][Score] >= 3500){ //Nivel 8
		SetPlayerArmour(playerid,100);
		if(Player[playerid][EstadoRifle] == true){
		    GivePlayerWeapon(playerid,33,99999);
		}
	}
	return 1;
}
public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
	switch (dialogid)
	{
		case DIALOG_UNUSED: return 1; // Useful for dialogs that contain only information and we do nothing depending on whether they responded or not

		case DIALOG_LOGIN:
		{
			if (!response) return Kick(playerid);

			new hashed_pass[65];
			SHA256_PassHash(inputtext, Player[playerid][Salt], hashed_pass, 65);

			if (strcmp(hashed_pass, Player[playerid][Password]) == 0)
			{
				//correct password, spawn the player


				// sets the specified cache as the active cache so we can retrieve the rest player data
				cache_set_active(Player[playerid][Cache_ID]);

				AssignPlayerData(playerid);

				// remove the active cache from memory and unsets the active cache as well
				cache_delete(Player[playerid][Cache_ID]);
				Player[playerid][Cache_ID] = MYSQL_INVALID_CACHE;
				Player[playerid][IsLoggedIn] = true;

				// spawn the player to their last saved position after login
				TogglePlayerControllable(playerid,0);
				SetSpawnInfo(playerid, NO_TEAM, 24, 2493.9678,-1661.8716,13.3359,1.2420, 0, 0, 0, 0, 0, 0);
				if(Player[playerid][Skin] >= 0){
				    SetPlayerSkin(playerid,Player[playerid][Skin]);
				}
				SetPlayerVirtualWorld(playerid, Player[playerid][ID]);
				TogglePlayerControllable(playerid,0);
				Player[playerid][EnLobby] = false;
				SpawnPlayer(playerid);
				EnviarLobby(playerid);
			}
			else
			{
				Player[playerid][LoginAttempts]++;

				if (Player[playerid][LoginAttempts] >= 3)
				{
					SendClientMessage(playerid,-1,"{FF0000}>!< {FFFFFF}Fallastes 3 veces la contraseña.");
					DelayedKick(playerid);
				}
				
				else{
					SendClientMessage(playerid,-1,"{FF0000}>!< {FFFFFF}La contraseña es incorrecta.");
					ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_PASSWORD, "{002BFF}•{FFFF00}•{FF0000}• {FFFFFF}Ingresar", "{FFFFFF}Bienvenido a la comunidad de Extreme Shot TDM.\n\nPor favor introduce una contraseña:", "Ingresar", "X");
				}
			}
		}
		//SISTEMA DE REGISTRO
		case DIALOG_REGISTER:
		{
		
			if (!response) return Kick(playerid);

			if (strlen(inputtext) <= 5){
			    SendClientMessage(playerid,-1,"{FF0000}>!< {FFFFFF}La contraseña debe ser mayor a 5 caracteres.");
			 	return ShowPlayerDialog(playerid, DIALOG_REGISTER, DIALOG_STYLE_PASSWORD, "{002BFF}•{FFFF00}•{FF0000}• {FFFFFF}Registro", "{FFFFFF}Bienvenido a la comunidad de Extreme Shot TDM.\n\nPor favor introduce una contraseña:", "Ingresar", "X");
            }
			// 16 random characters from 33 to 126 (in ASCII) for the salt
			for (new i = 0; i < 16; i++) Player[playerid][Salt][i] = random(94) + 33;
			SHA256_PassHash(inputtext, Player[playerid][Salt], Player[playerid][Password], 65);

			new query[221];
			mysql_format(g_SQL, query, sizeof query, "INSERT INTO `players` (`username`, `password`,`e_correo`, `salt`) VALUES ('%e', '%s', '%e', '%e')", Player[playerid][Name], Player[playerid][Password], Player[playerid][Correo],Player[playerid][Salt]);
			mysql_tquery(g_SQL, query, "OnPlayerRegister", "d", playerid);
		}
		case DIALOG_REGISTER_CORREO:{
			if (!response) return Kick(playerid);
			if(strlen(inputtext) > 128){ SendClientMessage(playerid,-1,"{FF0000}>!< {FFFFFF}El correo supera los 128 caracteres."); return ShowPlayerDialog(playerid, DIALOG_REGISTER_CORREO, DIALOG_STYLE_INPUT, "{002BFF}•{FFFF00}•{FF0000}• {FFFFFF}Correo Electrónico", "{FFFFFF}Para recuperar tu cuenta en un futuro necesitas registrar un correo válido.\n\nPor favor introduce un correo:", "Aceptar", "X"); }
			if(strfind(inputtext, "@", true) == -1 || strfind(inputtext, ".", true) == -1){
			    SendClientMessage(playerid,-1,"{FF0000}>!< {FFFFFF}El correo es inválido.");
				return ShowPlayerDialog(playerid, DIALOG_REGISTER_CORREO, DIALOG_STYLE_INPUT, "{002BFF}•{FFFF00}•{FF0000}• {FFFFFF}Correo Electrónico", "{FFFFFF}Para recuperar tu cuenta en un futuro necesitas registrar un correo válido.\n\nPor favor introduce un correo:", "Aceptar", "X");
			}
			else{
			    new query[221];
                format(Player[playerid][Correo], 128, "%s", inputtext);
                mysql_format(g_SQL,query,sizeof(query),"SELECT * FROM `players` WHERE `e_correo`='%e'  LIMIT 1",inputtext);
				mysql_tquery(g_SQL, query, "VerificacionCorreo","is", playerid,inputtext);
				
			}
		}
		case DIALOG_SELECT_TEAM:{
		    if (!response) return 1;
			if(Player[playerid][TiempoSAN] > 0) return SendClientMessage(playerid,-1,"{FF0000}>!< {FFFFFF}Te encuentras sancionado, Cumple tu condena para jugar.");
		    switch(listitem){
		        case 0:{
		            SetSpawnInfo(playerid, 0, 105, 2493.9678,-1661.8716,13.3359,1.2420, 0, 0, 0, 0, 0, 0);
                    SetPlayerColor(playerid, 0x07922BFF);
		            QuitarLobby(playerid);
		            TeamSelected[playerid] = 0;
		            SetPlayerTeam(playerid, TeamSelected[playerid]);
		            return SpawnPlayer(playerid);
                }
		        case 1:{

		            SetSpawnInfo(playerid, 1, 120, 2493.9678,-1661.8716,13.3359,1.2420, 0, 0, 0, 0, 0, 0);
		            SetPlayerColor(playerid, 0xCACACAFF);
		            QuitarLobby(playerid);
					TeamSelected[playerid] = 1;
					SetPlayerTeam(playerid, TeamSelected[playerid]);
		            return SpawnPlayer(playerid);
		        }
		        case 2:{

		            SetSpawnInfo(playerid, 2, 132, 2493.9678,-1661.8716,13.3359,1.2420, 0, 0, 0, 0, 0, 0);
		            SetPlayerColor(playerid, 0x10C2F0FF);
		            QuitarLobby(playerid);
		            TeamSelected[playerid] = 2;
		            SetPlayerTeam(playerid, TeamSelected[playerid]);
		            return SpawnPlayer(playerid);
                }
		        case 3:{

		            SetSpawnInfo(playerid, 3, 100, 2493.9678,-1661.8716,13.3359,1.2420, 0, 0, 0, 0, 0, 0);
		            SetPlayerColor(playerid, 0x540B0BFF);
		            QuitarLobby(playerid);
		            TeamSelected[playerid] = 3;
		            SetPlayerTeam(playerid, TeamSelected[playerid]);
		            return SpawnPlayer(playerid);
		        }
		    }
            new teamid = tempidteam[playerid][listitem];
            if(Player[playerid][Team] == TeamInfo[teamid][ID]){
				 new string[50];
				 SetSpawnInfo(playerid,Player[playerid][Team], 24, 2493.9678,-1661.8716,13.3359,1.2420, 0, 0, 0, 0, 0, 0);
                 format(string, 128, "Elejistes el equipo: %s", TeamInfo[teamid][Nombre]);
                 TeamSelected[playerid] = teamid;
                 SpawnPlayer(playerid);
                 
                 format(string, 10, "%sff", TeamInfo[teamid][Color]);
                 new color = HexToInt(string);
                 SetPlayerColor(playerid, color);
                 QuitarLobby(playerid);
            }
            else{
                return SendClientMessage(playerid,-1,"No perteneces a este equipo.");
            }
		    
		}
		case DIALOG_AYUDA:{
			if (!response) return 1;
			new str[1136+1];
			format(str, sizeof(str), "%s{8690e0} DUELOS:\n{FFFFFF}/Duelo  (Enviar invitación de duelos).\n/Aceptar duelo \n/Rechazar duelo", str);
			format(str, sizeof(str), "%s\n\n{8690e0} EVENTOS Y MINIJUEGOS:\n{FFFFFF}/Unirse (Ingresar a un evento en progreso).", str);
			format(str, sizeof(str), "%s\n/Minijuegos (Ingresar a un minijuego).\n/Salir (Abandonar evento o minijuego).\n\n{8690e0}CARCEL:\n{FFFFFF}/Tiempo (Visualizar minutos de cárcel).", str);
			format(str, sizeof(str), "%s\n\n{8690e0} VEHÍCULOS:\n{FFFFFF} /Misautos (Traer tus vehículos a tu posición).\n/Venderautos\n/Pintar\n\n{8690e0}CASAS:\n{FFFFFF}/comprarcasa (Adquirar una casa).\n/Puerta (Abrir y cerrar la casa).\n/Vendercasa\nPodrás comprar un interior para tu casa en {FFFF00}/tienda.", str);

			ShowPlayerDialog(playerid, 9999, DIALOG_STYLE_MSGBOX, "{002BFF}• {FFFF00}• {FF0000}• {FFFFFF}Comandos", str, "Aceptar", "");
		}
		case DIALOG_ARMAS:{
		    if(!response) return 1;
		    switch(listitem)
		    {
		        case 0:{
		            if(Player[playerid][Dinero] < 300) return SendClientMessage(playerid,-1,"Necesitas $300 para comprar 9mm silenciada.");
					QuitarDinero(playerid,300);
					GivePlayerWeapon(playerid,23,200);
		        }
		        case 1:{
		            if(Player[playerid][Dinero] < 400) return SendClientMessage(playerid,-1,"Necesitas $400 para comprar Escopeta.");
					QuitarDinero(playerid,400);
					GivePlayerWeapon(playerid,25,50);
				}
				case 2:{
		            if(Player[playerid][Dinero] < 400) return SendClientMessage(playerid,-1,"Necesitas $1200 para comprar SPAS.");
					QuitarDinero(playerid,1200);
					GivePlayerWeapon(playerid,27,70);
				}
				case 3:{
		            if(Player[playerid][Dinero] < 400) return SendClientMessage(playerid,-1,"Necesitas $500 para comprar MP5.");
					QuitarDinero(playerid,500);
					GivePlayerWeapon(playerid,29,100);
				}
				case 4:{
		            if(Player[playerid][Dinero] < 500) return SendClientMessage(playerid,-1,"Necesitas $500 para comprar AK-47.");
					QuitarDinero(playerid,500);
					GivePlayerWeapon(playerid,30,100);
				}
				case 5:{
		            if(Player[playerid][Dinero] < 600) return SendClientMessage(playerid,-1,"Necesitas $600 para comprar M4.");
					QuitarDinero(playerid,600);
					GivePlayerWeapon(playerid,31,150);
				}
				case 6:{
		            if(Player[playerid][Dinero] < 500) return SendClientMessage(playerid,-1,"Necesitas $500 para comprar Rifle.");
					QuitarDinero(playerid,500);
					GivePlayerWeapon(playerid,33,50);
				}
				case 7:{
		            if(Player[playerid][Dinero] < 700) return SendClientMessage(playerid,-1,"Necesitas $700 para comprar Sniper.");
					QuitarDinero(playerid,700);
					GivePlayerWeapon(playerid,34,50);
				}
				case 8:{
		            if(Player[playerid][Dinero] < 400) return SendClientMessage(playerid,-1,"Necesitas $400 para comprar Sniper.");
					QuitarDinero(playerid,400);
					GivePlayerWeapon(playerid,9,1);
				}
				case 9:{
		            if(Player[playerid][Dinero] < 600) return SendClientMessage(playerid,-1,"Necesitas $600 para comprar Granada.");
					QuitarDinero(playerid,600);
					GivePlayerWeapon(playerid,16,1);
				}
				case 10:{
		            if(Player[playerid][Dinero] < 1000) return SendClientMessage(playerid,-1,"Necesitas $1000 para comprar Chaleco antibalas.");
					QuitarDinero(playerid,1000);
					SetPlayerArmour(playerid,100);
				}
		    }
		}
		case DIALOG_CONFIG:{
		    if(!response) return 1;
		    switch(listitem){
		        case 0:{
		            new str[550];
		            new EstadoDesertX[22] = "{FF0000}OFF";
					new EstadoEscopetaX[22] = "{FF0000}OFF";
					new EstadoSPASX[22] = "{FF0000}OFF";
					new EstadoMP5X[22] = "{FF0000}OFF";
					new EstadoAK47X[22] = "{FF0000}OFF";
					new EstadoM4X[22] = "{FF0000}OFF";
					new EstadoRifleX[22] = "{FF0000}OFF";
					new EstadoSniperX[22] = "{FF0000}OFF";
					new EstadoBateX[22] = "{FF0000}OFF";
					new EstadoKatanaX[22] = "{FF0000}OFF";
					new EstadoMotosierraX[22] = "{FF0000}OFF";
					new EstadoGranadaX[22] = "{FF0000}OFF";
					new EstadoGranadaDHX[22] = "{FF0000}OFF";
					if(Player[playerid][EstadoDesert] == true){ EstadoDesertX = "{1FFF02}ON"; }
					if(Player[playerid][EstadoEscopeta] == true){ EstadoEscopetaX = "{1FFF02}ON"; }
					if(Player[playerid][EstadoSPAS] == true){ EstadoSPASX = "{1FFF02}ON"; }
					if(Player[playerid][EstadoMP5] == true){ EstadoMP5X = "{1FFF02}ON"; }
					if(Player[playerid][EstadoAK47] == true){ EstadoAK47X = "{1FFF02}ON"; }
					if(Player[playerid][EstadoM4] == true){ EstadoM4X = "{1FFF02}ON"; }
					if(Player[playerid][EstadoRifle] == true){ EstadoRifleX = "{1FFF02}ON"; }
					if(Player[playerid][EstadoSniper] == true){ EstadoSniperX = "{1FFF02}ON"; }
					if(Player[playerid][EstadoBate] == true){ EstadoBateX = "{1FFF02}ON"; }
					if(Player[playerid][EstadoKatana] == true){ EstadoKatanaX = "{1FFF02}ON"; }
					if(Player[playerid][EstadoMotosierra] == true){ EstadoMotosierraX = "{1FFF02}ON"; }
					if(Player[playerid][EstadoGranada] == true){ EstadoGranadaX = "{1FFF02}ON"; }
					if(Player[playerid][EstadoGranadaDH] == true){ EstadoGranadaDHX = "{1FFF02}ON"; }
				    format(str, sizeof(str), "Configuración\tEstado\n{5FBEFD}• {FFFFFF}Desert Eagle\t%s\n{5FBEFD}• {FFFFFF}Escopeta\t%s\n{5FBEFD}• {FFFFFF}Spas\t%s\n{5FBEFD}• {FFFFFF}MP5\t%s\n{5FBEFD}• {FFFFFF}AK-47\t%s\n{5FBEFD}• {FFFFFF}M4\t%s\n{5FBEFD}• {FFFFFF}Rifle\t%s\n{5FBEFD}• {FFFFFF}Sniper\t%s\n{5FBEFD}• {FFFFFF}Bate\t%s\n{5FBEFD}• {FFFFFF}Katana\t%s\n{5FBEFD}• {FFFFFF}Motosierra\t%s\n{5FBEFD}• {FFFFFF}Granada\t%s\n{5FBEFD}• {FFFFFF}Granada de humo\t%s ",
					EstadoDesertX,EstadoEscopetaX,EstadoSPASX,EstadoMP5X,EstadoAK47X,EstadoM4X,EstadoRifleX,EstadoSniperX,EstadoBateX,EstadoKatanaX,EstadoMotosierraX,EstadoGranadaX,EstadoGranadaDHX);
					ShowPlayerDialog(playerid, DIALOG_CONFIG_ARMAS, DIALOG_STYLE_TABLIST_HEADERS, "{002BFF}• {FFFF00}• {FF0000}• {FFFFFF}Configuración de armas",str,"Cambiar", "<");
		        }
		        case 1:{
		            new str[27+1];
					format(str, sizeof(str), "%s{FFFFFF}Ingresa ID de clima:", str);
					ShowPlayerDialog(playerid, DIALOG_CONFIG_CLIMA, DIALOG_STYLE_INPUT, "{002BFF}• {FFFF00}• {FF0000}• {FFFFFF}Configuración de clima", str, "Cambiar", "<");
		        }
		      	case 2:{
		            new str[27+1];
					format(str, sizeof(str), "%s{FFFFFF}Ingresa la hora:", str);
					ShowPlayerDialog(playerid, DIALOG_CONFIG_HORA, DIALOG_STYLE_INPUT, "{002BFF}• {FFFF00}• {FF0000}• {FFFFFF}Configuración de hora", str, "Cambiar", "<");
		        }
		        case 3:{
		            new str[227+1];
					format(str, sizeof(str), "%s{5FBEFD}• {FFFFFF}Estilo de pelea 1\n{5FBEFD}• {FFFFFF}Estilo de pelea 2\n{5FBEFD}• {FFFFFF}Estilo de pelea 3\n{5FBEFD}• {FFFFFF}Estilo de pelea 4\n{5F", str);
					format(str, sizeof(str), "%sBEFD}• {FFFFFF}Estilo de pelea 5\n{5FBEFD}• {FFFFFF}Estilo de pelea 6\n", str);
					ShowPlayerDialog(playerid, DIALOG_CONFIG_ESTILO_PELEA, DIALOG_STYLE_LIST, "{002BFF}• {FFFF00}• {FF0000}• {FFFFFF}Configuración de peleas", str, "Cambiar", "<");
		        }
		        case 4:{
		            SendClientMessage(playerid,-1,"Contraseña config.");
		        }
		        case 5:{
		            if(Player[playerid][MPsEstado] == true){
		                Player[playerid][MPsEstado] = false;
		                ActualizarUserDB(playerid,"MPsEstado",0);
		            }
		            else{
		                Player[playerid][MPsEstado] = true;
		                ActualizarUserDB(playerid,"MPsEstado",1);
		            }
		            SendClientMessage(playerid,-1,"{FF0000}>!< {FFFFFF}Configuración cambiada.");
		        }
		        case 6:{
		            if(Player[playerid][DuelosEstado] == true){
		                Player[playerid][DuelosEstado] = false;
		                ActualizarUserDB(playerid,"DuelosEstado",0);

		            }
		            else{
		                Player[playerid][DuelosEstado] = true;
		                ActualizarUserDB(playerid,"DuelosEstado",1);
		            }
		            SendClientMessage(playerid,-1,"{FF0000}>!< {FFFFFF}Configuración cambiada.");
		        }
		        case 7:{
		            SendClientMessage(playerid,-1,"Sonido racha config");
		        }
		        case 8:{
		            if(Player[playerid][MusicEventEstado] == true){
		                Player[playerid][MusicEventEstado] = false;
		                ActualizarUserDB(playerid,"MusicEventEstado",0);
		            }
		            else{
		                Player[playerid][MusicEventEstado] = true;
		                ActualizarUserDB(playerid,"MusicEventEstado",1);
						
		            }
		            SendClientMessage(playerid,-1,"{FF0000}>!< {FFFFFF}Configuración cambiada.");
		        }
		        case 9:{
		            if(Player[playerid][SpawnHouseEstado] == true){
		                Player[playerid][SpawnHouseEstado] = false;
		                ActualizarUserDB(playerid,"SpawnHouseEstado",0);
		            }
		            else{
		                Player[playerid][SpawnHouseEstado] = true;
		                ActualizarUserDB(playerid,"SpawnHouseEstado",1);
						
		            }
		            SendClientMessage(playerid,-1,"{FF0000}>!< {FFFFFF}Configuración cambiada.");
		        }
		        case 10:{
		            if(Player[playerid][InfoRankEstado] == true){
		                Player[playerid][InfoRankEstado] = false;
		                ActualizarUserDB(playerid,"InfoRankEstado",0);
		                TextDrawHideForPlayer(playerid,StatsInfo);
	    				PlayerTextDrawHide(playerid, StatsInfoUser[playerid]);
		                KillTimer(ActualizarInfo[playerid]);
		            }
		            else{
		                Player[playerid][InfoRankEstado] = true;
		                ActualizarUserDB(playerid,"InfoRankEstado",1);
		                TextDrawShowForPlayer(playerid,StatsInfo);
	    				PlayerTextDrawShow(playerid, StatsInfoUser[playerid]);
     					ActualizarInfo[playerid] = SetTimerEx("ActualizarInfoz", 500, true, "i", playerid);
						
		            }
		            SendClientMessage(playerid,-1,"{FF0000}>!< {FFFFFF}Configuración cambiada.");
		        }
		    }
		    
		}
		case DIALOG_CONFIG_ARMAS:{
		    if(!response) return MostrarConfig(playerid);
		    switch(listitem){
				case 0: {//Desert
				    if(Player[playerid][EstadoDesert] == true){
		                Player[playerid][EstadoDesert] = false;
		                ActualizarUserDB(playerid,"EstadoDesert",0);
		            }
		            else{
		                Player[playerid][EstadoDesert] = true;
		                ActualizarUserDB(playerid,"EstadoDesert",1);

		            }
		            SendClientMessage(playerid,-1,"{FF0000}>!< {FFFFFF}Configuración cambiada.");
				}
				case 1: { //escopeta
				    if(Player[playerid][EstadoEscopeta] == true){
		                Player[playerid][EstadoEscopeta] = false;
		                ActualizarUserDB(playerid,"EstadoEscopeta",0);
		            }
		            else{
		                Player[playerid][EstadoEscopeta] = true;
		                ActualizarUserDB(playerid,"EstadoEscopeta",1);

		            }
		            SendClientMessage(playerid,-1,"{FF0000}>!< {FFFFFF}Configuración cambiada.");
				}
				case 2: { //spas
				    if(Player[playerid][EstadoSPAS] == true){
		                Player[playerid][EstadoSPAS] = false;
		                ActualizarUserDB(playerid,"EstadoSPAS",0);
		            }
		            else{
		                Player[playerid][EstadoSPAS] = true;
		                ActualizarUserDB(playerid,"EstadoSPAS",1);

		            }
		            SendClientMessage(playerid,-1,"{FF0000}>!< {FFFFFF}Configuración cambiada.");
				}
				case 3: { //MP5
				    if(Player[playerid][EstadoMP5] == true){
		                Player[playerid][EstadoMP5] = false;
		                ActualizarUserDB(playerid,"EstadoMP5",0);
		            }
		            else{
		                Player[playerid][EstadoMP5] = true;
		                ActualizarUserDB(playerid,"EstadoMP5",1);

		            }
		            SendClientMessage(playerid,-1,"{FF0000}>!< {FFFFFF}Configuración cambiada.");
				}
				case 4: { //AK47
				    if(Player[playerid][EstadoAK47] == true){
		                Player[playerid][EstadoAK47] = false;
		                ActualizarUserDB(playerid,"EstadoAK47",0);
		            }
		            else{
		                Player[playerid][EstadoAK47] = true;
		                ActualizarUserDB(playerid,"EstadoAK47",1);

		            }
		            SendClientMessage(playerid,-1,"{FF0000}>!< {FFFFFF}Configuración cambiada.");
				}
				case 5: { //M4
				    if(Player[playerid][EstadoM4] == true){
		                Player[playerid][EstadoM4] = false;
		                ActualizarUserDB(playerid,"EstadoM4",0);
		            }
		            else{
		                Player[playerid][EstadoM4] = true;
		                ActualizarUserDB(playerid,"EstadoM4",1);

		            }
		            SendClientMessage(playerid,-1,"{FF0000}>!< {FFFFFF}Configuración cambiada.");
				}
				case 6: { //Rifle
				    if(Player[playerid][EstadoRifle] == true){
		                Player[playerid][EstadoRifle] = false;
		                ActualizarUserDB(playerid,"EstadoRifle",0);
		            }
		            else{
		                Player[playerid][EstadoRifle] = true;
		                ActualizarUserDB(playerid,"EstadoRifle",1);

		            }
		            SendClientMessage(playerid,-1,"{FF0000}>!< {FFFFFF}Configuración cambiada.");
				}
				case 7: { //Sniper
				    if(Player[playerid][EstadoSniper] == true){
		                Player[playerid][EstadoSniper] = false;
		                ActualizarUserDB(playerid,"EstadoSniper",0);
		            }
		            else{
		                Player[playerid][EstadoSniper] = true;
		                ActualizarUserDB(playerid,"EstadoSniper",1);

		            }
		            SendClientMessage(playerid,-1,"{FF0000}>!< {FFFFFF}Configuración cambiada.");
				}
				case 8: { //Bate
				    if(Player[playerid][EstadoBate] == true){
		                Player[playerid][EstadoBate] = false;
		                ActualizarUserDB(playerid,"EstadoBate",0);
		            }
		            else{
		                Player[playerid][EstadoBate] = true;
		                ActualizarUserDB(playerid,"EstadoBate",1);

		            }
		            SendClientMessage(playerid,-1,"{FF0000}>!< {FFFFFF}Configuración cambiada.");
				}
				case 9: { //Katana
				    if(Player[playerid][EstadoKatana] == true){
		                Player[playerid][EstadoKatana] = false;
		                ActualizarUserDB(playerid,"EstadoKatana",0);
		            }
		            else{
		                Player[playerid][EstadoKatana] = true;
		                ActualizarUserDB(playerid,"EstadoKatana",1);

		            }
		            SendClientMessage(playerid,-1,"{FF0000}>!< {FFFFFF}Configuración cambiada.");
				}
				case 10: { //Motosierra
				    if(Player[playerid][EstadoMotosierra] == true){
		                Player[playerid][EstadoMotosierra] = false;
		                ActualizarUserDB(playerid,"EstadoMotosierra",0);
		            }
		            else{
		                Player[playerid][EstadoMotosierra] = true;
		                ActualizarUserDB(playerid,"EstadoMotosierra",1);

		            }
		            SendClientMessage(playerid,-1,"{FF0000}>!< {FFFFFF}Configuración cambiada.");
				}
				case 11: { //Granada
				    if(Player[playerid][EstadoGranada] == true){
		                Player[playerid][EstadoGranada] = false;
		                ActualizarUserDB(playerid,"EstadoGranada",0);
		            }
		            else{
		                Player[playerid][EstadoGranada] = true;
		                ActualizarUserDB(playerid,"EstadoGranada",1);

		            }
		            SendClientMessage(playerid,-1,"{FF0000}>!< {FFFFFF}Configuración cambiada.");
				}
				case 12: { //Granada de humo
				    if(Player[playerid][EstadoGranadaDH] == true){
		                Player[playerid][EstadoGranadaDH] = false;
		                ActualizarUserDB(playerid,"EstadoGranadaDH",0);
		            }
		            else{
		                Player[playerid][EstadoGranadaDH] = true;
		                ActualizarUserDB(playerid,"EstadoGranadaDH",1);

		            }
		            SendClientMessage(playerid,-1,"{FF0000}>!< {FFFFFF}Configuración cambiada.");
				}
		    }
		}
	
		case DIALOG_CONFIG_CLIMA:{
			if(!response) return MostrarConfig(playerid);
			if(IsNumeric(inputtext)){
			    new iValue = strval(inputtext);
			    Player[playerid][ClimaID] = iValue;
            	SetPlayerWeather(playerid,Player[playerid][ClimaID]);
            	ActualizarUserDB(playerid,"ClimaID",Player[playerid][ClimaID]);
            	SendClientMessage(playerid,-1,"{FF0000}>!< {FFFFFF}Configuración cambiada.");
			}
			else{
				SendClientMessage(playerid,-1,"{FF0000}>!< {FFFFFF}Ingrese un valor válido.");
			}
		}
		case DIALOG_CONFIG_HORA:{
			if(!response) return MostrarConfig(playerid);
			if(IsNumeric(inputtext)){
			    new iValue = strval(inputtext);
            	Player[playerid][HoraID] = iValue;
            	SetPlayerTime(playerid,Player[playerid][HoraID],0);
            	ActualizarUserDB(playerid,"HoraID",Player[playerid][HoraID]);
            	SendClientMessage(playerid,-1,"{FF0000}>!< {FFFFFF}Configuración cambiada.");
			}
			else{
				SendClientMessage(playerid,-1,"{FF0000}>!< {FFFFFF}Ingrese un valor válido.");
			}
		}
		/*
		AddPlayerClass(24,1323.8142,2125.2693,11.0156,317.0964,0,0,0,0,0,0); // // Estadio LV: JUGADOR 1{
		AddPlayerClass(24,1354.4550,2159.5139,11.0156,140.8655,0,0,0,0,0,0); // // Estadio LV: JUGADOR 2{
		new Duelo_temp_USERID[MAX_PLAYERS];
		new Duelo_temp_APUESTA[MAX_PLAYERS];

		*/
		case DIALOG_CONFIG_ESTILO_PELEA:{
		    switch(listitem){
		        case 0:{ }
		        case 1:{ }
		        case 2:{ }
		        case 3:{ }
		        case 4:{ }
		        case 5:{ }
		    }
		}
		case DIALOG_LUGAR_DUELO:{
		    if(!response) return 1;
		    new str[240];
		    format(str, sizeof(str), "{5FBEFD}• {FFFFFF}Desert Eagle\n{5FBEFD}• {FFFFFF}Escopeta\n{5FBEFD}• {FFFFFF}Spas\n{5FBEFD}• {FFFFFF}MP5\n{5FBEFD}• {FFFFFF}AK-47\n{5FBEFD}• {FFFFFF}M4\n{5FBEFD}• {FFFFFF}Rifle\n{5FBEFD}• {FFFFFF}Sniper\n{5FBEFD}• {FFFFFF}Escopeta recortada\n{5FBEFD}• {FFFFFF}Desert-eagle - Escopeta\n{5FBEFD}• {FFFFFF}Desert-eagle - SPAS\n{5FBEFD}• {FFFFFF}Desert-eagle - MP5\n{5FBEFD}• {FFFFFF}Desert-eagle - M4 ");
			ShowPlayerDialog(playerid, DIALOG_ARMAS_DUELO, DIALOG_STYLE_TABLIST, "{002BFF}• {FFFF00}• {FF0000}• {FFFFFF}Armas",str,"Cambiar", "<");
		}
		case DIALOG_ARMAS_DUELO:
		{
		    if(!response) return 1;
		    new string[240],invitado_id = Duelo_temp_USERID[playerid],arma1,arma2,lugar;
		    SendClientMessage(invitado_id,-1,"---------------------------------------------------------------");
		    format(string,sizeof(string),"{FFFF00}El usuario %s te invitó a jugar un duelo. Armas: ",Player[playerid][Name]);
		    switch(listitem){
				case 0:{ strcat(string, "Desert Eagle"); arma1 = 24; lugar = 1;}
				case 1:{ strcat(string, "Escopeta"); arma1 = 25; lugar = 2;}
				case 2:{ strcat(string, "SPAS"); arma1 = 27; lugar = 3;}
				case 3:{ strcat(string, "MP5"); arma1 = 29; lugar = 4;}
				case 4:{ strcat(string, "AK-47"); arma1 = 30; lugar = 5;}
				case 5:{ strcat(string, "M4"); arma1 = 31; lugar = 6;}
				case 6:{ strcat(string, "Rifle"); arma1 = 33; lugar = 7;}
				case 7:{ strcat(string, "Sniper"); arma1 = 34; lugar = 8;}
				case 8:{ strcat(string, "Escopeta recortada"); arma1 = 26 ; lugar = 9;}
				case 9:{ strcat(string, "Desert eagle - Escopeta"); arma1 = 24; arma2 = 25; lugar = 10;}
				case 10:{ strcat(string, "Desert eagle - SPAS"); arma1 = 24; arma2 = 27; lugar = 11;}
				case 11:{ strcat(string, "Desert eagle - MP5"); arma1 = 24; arma2 = 29; lugar = 12;}
				case 12:{ strcat(string, "Desert eagle - M4"); arma1 = 24; arma2 = 31; lugar = 13;}
		    }
            SendClientMessage(invitado_id,-1,string);
            SendClientMessage(invitado_id,-1,"{FFFF00}Utiliza {FFFFFF}/aceptar duelo{FFFF00}. Para aceptar la invitación.");
            SendClientMessage(invitado_id,-1,"---------------------------------------------------------------");
			Duelo_temp_Arma1[playerid] = arma1;
			Duelo_temp_Arma2[playerid] = arma2;
			Duelo_temp_Lugar[playerid] = lugar;
			Invitado[playerid] = true;
			Invitado[invitado_id] = true;
			Tiempo_Invitacion[playerid] = 20;
			Duelo_temp_INVI_POR[invitado_id] = playerid;
			
		}
		default: return 0; // dialog ID was not found, search in other scripts
	}
	return 1;
}
IsNumeric(szInput[]) {

	new
		iChar,
		i = 0;

	while ((iChar = szInput[i++])) if (!('0' <= iChar <= '9')) return 0;
	return 1;
}
//-----------------------------------------------------

stock QuitarDinero(playerid,cantidad){
    Player[playerid][Dinero] -= cantidad;
	GivePlayerMoney(playerid,-cantidad);

	ActualizarUserDB(playerid,"Dinero",Player[playerid][Dinero]);
}
stock DarDinero(playerid,cantidad){
    Player[playerid][Dinero] += cantidad;
	GivePlayerMoney(playerid,cantidad);
	ActualizarUserDB(playerid,"Dinero",Player[playerid][Dinero]);
}
stock DarEXS(playerid,cantidad){
    Player[playerid][EXS] += cantidad;
    ActualizarUserDB(playerid,"EXS",Player[playerid][EXS]);
   
}
stock QuitarEXS(playerid,cantidad){
    Player[playerid][EXS] -= cantidad;
    ActualizarUserDB(playerid,"EXS",Player[playerid][EXS]);

}
stock HexToInt(string[])
{
    if(!string[0]) return 0;
    new cur = 1, res = 0;
    for(new i = strlen(string); i > 0; i--)
    {
        res += cur * (string[i - 1] - ((string[i - 1] < 58) ? (48) : (55)));
        cur = cur * 16;
    }
    return res;
}
stock QuitarLobby(playerid){
	Player[playerid][EnLobby]=false;
	for(new i = 0; i < 11; i++){
		TextDrawHideForPlayer(playerid,TextdrawLobby[i]);
	}
	CancelSelectTextDraw(playerid);
	KillTimer(select[playerid]);
}
forward OnPlayerDataLoaded(playerid, race_check);
public OnPlayerDataLoaded(playerid, race_check)
{
	
	if (race_check != g_MysqlRaceCheck[playerid]) return Kick(playerid);

	if(cache_num_rows() > 0)
	{
		
		cache_get_value(0, "password", Player[playerid][Password], 65);
		cache_get_value(0, "salt", Player[playerid][Salt], 17);

	
		Player[playerid][Cache_ID] = cache_save();

		ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_PASSWORD, "{002BFF}•{FFFF00}•{FF0000}• {FFFFFF}Ingresar", "{FFFFFF}Bienvenido a la comunidad de Extreme Shot TDM.\n\nPor favor introduce una contraseña:", "Ingresar", "X");

		

	}
	else
	{
		//Empezar registro solicitando el correo electronico:

		ShowPlayerDialog(playerid, DIALOG_REGISTER_CORREO, DIALOG_STYLE_INPUT, "{002BFF}•{FFFF00}•{FF0000}• {FFFFFF}Correo Electrónico", "{FFFFFF}Para recuperar tu cuenta en un futuro necesitas registrar un correo válido.\n\nPor favor introduce un correo:", "Aceptar", "X");
	}
	return 1;
}



forward OnPlayerRegister(playerid);
public OnPlayerRegister(playerid)
{
	

	Player[playerid][ID] = cache_insert_id();
	Player[playerid][IsLoggedIn] = true;
	SetSpawnInfo(playerid, NO_TEAM, 24, 2493.9678,-1661.8716,13.3359,1.2420, 0, 0, 0, 0, 0, 0);
	TogglePlayerControllable(playerid,0);
	Player[playerid][EnLobby] = false;
	SpawnPlayer(playerid);
	EnviarLobby(playerid);
	return 1;
}

forward _KickPlayerDelayed(playerid);
public _KickPlayerDelayed(playerid)
{
	Kick(playerid);
	return 1;
}


//-----------------------------------------------------

AssignPlayerData(playerid)
{
	cache_get_value_int(0, "id", Player[playerid][ID]);

	cache_get_value_int(0, "kills", Player[playerid][Kills]);
	cache_get_value_int(0, "deaths", Player[playerid][Deaths]);
	cache_get_value_int(0, "interior", Player[playerid][Interior]);
	cache_get_value(0, "e_correo", Player[playerid][Correo],128);
	cache_get_value_int(0, "Skin", Player[playerid][Skin]);
	cache_get_value_int(0, "rankadmin", Player[playerid][Admin]);
	cache_get_value_int(0, "u_team", Player[playerid][Team]);
	cache_get_value_int(0, "u_rank", Player[playerid][Rank]);
	cache_get_value_int(0, "Dinero", Player[playerid][Dinero]);
	cache_get_value_int(0, "TiempoSAN", Player[playerid][TiempoSAN]);
	cache_get_value_int(0, "Score", Player[playerid][Score]);
	cache_get_value_int(0, "d_ganados", Player[playerid][d_ganados]);
	cache_get_value_int(0, "d_perdidos", Player[playerid][d_perdidos]);
	cache_get_value_int(0, "e_ganados", Player[playerid][e_ganados]);
	cache_get_value_int(0, "EXS", Player[playerid][EXS]);
	cache_get_value_int(0, "CasaID", Player[playerid][CasaID]);
	cache_get_value_int(0, "Piezas", Player[playerid][Piezas]);
	cache_get_value_int(0, "DuelosEstado", Player[playerid][DuelosEstado]);
	cache_get_value_int(0, "MPsEstado", Player[playerid][MPsEstado]);
	cache_get_value_int(0, "SpawnHouseEstado", Player[playerid][SpawnHouseEstado]);
	cache_get_value_int(0, "InfoRankEstado", Player[playerid][InfoRankEstado]);
	cache_get_value_int(0, "MusicEventEstado", Player[playerid][MusicEventEstado]);
	
	cache_get_value_int(0, "EstadoDesert", Player[playerid][EstadoDesert]);
	cache_get_value_int(0, "EstadoEscopeta", Player[playerid][EstadoEscopeta]);
	cache_get_value_int(0, "EstadoSPAS", Player[playerid][EstadoSPAS]);
	cache_get_value_int(0, "EstadoMP5", Player[playerid][EstadoMP5]);
	cache_get_value_int(0, "EstadoAK47", Player[playerid][EstadoAK47]);
	cache_get_value_int(0, "EstadoM4", Player[playerid][EstadoM4]);
	cache_get_value_int(0, "EstadoRifle", Player[playerid][EstadoRifle]);
	cache_get_value_int(0, "EstadoSniper", Player[playerid][EstadoSniper]);
	cache_get_value_int(0, "EstadoBate", Player[playerid][EstadoBate]);
	cache_get_value_int(0, "EstadoKatana", Player[playerid][EstadoKatana]);
	cache_get_value_int(0, "EstadoMotosierra", Player[playerid][EstadoMotosierra]);
	cache_get_value_int(0, "EstadoGranada", Player[playerid][EstadoGranada]);
	cache_get_value_int(0, "EstadoGranadaDH", Player[playerid][EstadoGranadaDH]);
	
	cache_get_value_int(0, "ClimaID", Player[playerid][ClimaID]);
	cache_get_value_int(0, "HoraID", Player[playerid][HoraID]);
    SetPlayerWeather(playerid,Player[playerid][ClimaID]);
    SetPlayerTime(playerid,Player[playerid][HoraID],0);
	
	return 1;
}

DelayedKick(playerid, time = 500)
{
	SetTimerEx("_KickPlayerDelayed", time, false, "d", playerid);
	return 1;
}

/*SetupPlayerTable()
{
	mysql_tquery(g_SQL, "CREATE TABLE IF NOT EXISTS `players` (`id` int(11) NOT NULL AUTO_INCREMENT,`username` varchar(24) NOT NULL,`password` char(64) NOT NULL,`salt` char(16) NOT NULL,`kills` mediumint(8) NOT NULL DEFAULT '0',`deaths` mediumint(8) NOT NULL DEFAULT '0',`x` float NOT NULL DEFAULT '0',`y` float NOT NULL DEFAULT '0',`z` float NOT NULL DEFAULT '0',`angle` float NOT NULL DEFAULT '0',`interior` tinyint(3) NOT NULL DEFAULT '0', PRIMARY KEY (`id`), UNIQUE KEY `username` (`username`))");
	return 1;
}*/

UpdatePlayerData(playerid, reason)
{
	if (Player[playerid][IsLoggedIn] == false) return 0;

	// if the client crashed, it's not possible to get the player's position in OnPlayerDisconnect callback
	// so we will use the last saved position (in case of a player who registered and crashed/kicked, the position will be the default spawn point)
	if (reason == 1)
	{
		GetPlayerPos(playerid, Player[playerid][X_Pos], Player[playerid][Y_Pos], Player[playerid][Z_Pos]);
		GetPlayerFacingAngle(playerid, Player[playerid][A_Pos]);
	}

	new query[145];
	mysql_format(g_SQL, query, sizeof query, "UPDATE `players` SET `Dinero` = %d WHERE `id` = %d LIMIT 1", Player[playerid][Dinero], Player[playerid][ID]);
	mysql_tquery(g_SQL, query);
	return 1;
}
UpdatePlayerDeaths(playerid){
    if (playerid == INVALID_PLAYER_ID) return 0;
    if (Player[playerid][IsLoggedIn] == false) return 0;
	Player[playerid][Deaths]++;
	ActualizarUserDB(playerid,"deaths",Player[playerid][Deaths]);
	return 1;
}
UpdatePlayerKills(killerid)
{
	// we must check before if the killer wasn't valid (connected) player to avoid run time error 4
	if(killerid == INVALID_PLAYER_ID) return 0;
	if(Player[killerid][IsLoggedIn] == false) return 0;
    new query[150];
	Player[killerid][Kills]++;
	Player[killerid][Score]++;
	SetPlayerScore(killerid,Player[killerid][Score]);
	if(TeamSelected[killerid]  > 3){
	    TeamInfo[TeamSelected[killerid]][KillsTotal]++;
		mysql_format(g_SQL, query, sizeof query, "UPDATE `teams` SET `KillsTotal` = KillsTotal+1 WHERE `id` = %d LIMIT 1",Player[killerid][Team]);
		mysql_tquery(g_SQL, query);
		
		mysql_format(g_SQL, query, sizeof query, "UPDATE `log_user_team` SET `kills` = kills+1 WHERE `user_id` = %d AND `team_id` = %d LIMIT 1",Player[killerid][ID],Player[killerid][Team]);
		mysql_tquery(g_SQL, query);
	}
	
	
    ActualizarUserDB(killerid,"kills",Player[killerid][Kills]);
    ActualizarUserDB(killerid,"Score",Player[killerid][Score]);


	return 1;
}
//COMANDOS ADMINISTRATIVOS
#define AYUDANTE 			1
#define MODERADOR 			2
#define MODERADORGLOBAL 	3
#define ADMINISTRADOR 		4
#define DUENO 				5
CMD:irco(playerid,params[]){
    if (Player[playerid][IsLoggedIn] == false) return 1;
	new id,Float:p_x,Float:p_y,Float:p_z;
	if(Player[playerid][Admin] < MODERADOR) return 1;
    if(sscanf(params, "fff", p_x,p_y,p_z)) return SendClientMessage(playerid,-1,"Modo de uso: /irco <Posicion_x> <Posicion_y> <Posicion_z>");
    {
        if(!IsPlayerConnected(id)) return SendClientMessage(playerid,-1,"Jugador no conectado.");
        if(Player[id][IsLoggedIn] == false) return SendClientMessage(playerid,-1,"El jugador ingresado está ingresando.");

		EnviarPosicion(playerid,p_x,p_y,p_z,0,0);
		GameTextForPlayer(playerid, "Transportado!", 3000, 3);
    }
	return 1;
}
CMD:ir(playerid,params[]){
    if (Player[playerid][IsLoggedIn] == false) return 1;
	new id;
	if(Player[playerid][Admin] < MODERADOR) return 1;
    if(sscanf(params, "d", id)) return SendClientMessage(playerid,-1,"Modo de uso: /ir <ID>");
    {
        if(!IsPlayerConnected(id)) return SendClientMessage(playerid,-1,"Jugador no conectado.");
        if(Player[id][IsLoggedIn] == false) return SendClientMessage(playerid,-1,"El jugador ingresado está ingresando.");
		new interiorid = GetPlayerInterior(id);
		new vwid = GetPlayerVirtualWorld(id);
		new Float:xid,Float:yid,Float:zid;
		GetPlayerPos(id,xid,yid,zid);
		EnviarPosicion(playerid,xid,yid,zid,interiorid,vwid);
		new string[144];
		format(string,sizeof(string),"~w~Transportado a~n~ ~g~%s.",Player[id][Name]);
		GameTextForPlayer(playerid, string, 3000, 3);
    }
	return 1;
}
alias:ir("go","irjugador")

//
CMD:traer(playerid,params[]){
    if (Player[playerid][IsLoggedIn] == false) return 1;
	new id;
	if(Player[playerid][Admin] < MODERADOR) return 1;
    if(sscanf(params, "d", id)) return SendClientMessage(playerid,-1,"Modo de uso: /traer <ID>");
    {
        if(!IsPlayerConnected(id)) return SendClientMessage(playerid,-1,"Jugador no conectado.");
        if(Player[id][IsLoggedIn] == false) return SendClientMessage(playerid,-1,"El jugador ingresado está ingresando.");
		new interiorid = GetPlayerInterior(playerid);
		new vwid = GetPlayerVirtualWorld(playerid);
		new Float:xid,Float:yid,Float:zid;
		GetPlayerPos(playerid,xid,yid,zid);
		EnviarPosicion(id,xid,yid,zid,interiorid,vwid);
		new string[144];
		format(string,sizeof(string),"~w~Traiste a~n~ ~g~%s.",Player[id][Name]);
		GameTextForPlayer(playerid, string, 3000, 3);
    }
	return 1;
}

//
CMD:san(playerid,params[]){
    if(Player[playerid][IsLoggedIn] == false) return 1;
    if(Player[playerid][Admin] < MODERADOR) return 1;
	new id,tiempo,razon[124];

    if(sscanf(params, "dds[124]", id,tiempo,razon)) return SendClientMessage(playerid,-1,"Modo de uso: /san <ID> <tiempo (EN SEGUNDOS) > <razón>");
    {
        if(!IsPlayerConnected(id)) return SendClientMessage(playerid,-1,"Jugador no conectado.");
        if(Player[id][IsLoggedIn] == false) return SendClientMessage(playerid,-1,"El jugador ingresado está ingresando.");
		Player[id][TiempoSAN] = tiempo;
		KillTimer(select[playerid]);
		EnviarLobby(id);
		new string[128];
		format(string, sizeof(string),"{8690e0}%s fue sancionado por %s Razón: %s",Player[id][Name],Player[playerid][Name],razon);
		SendClientMessageToAll(-1,string);
		ActualizarUserDB(playerid,"TiempoSAN",tiempo);

		new query[221];
		mysql_format(g_SQL, query, sizeof query, "INSERT INTO `log_user` (`iduser`,`razon`) VALUES ('%d','Sancionado por %s Tiempo: %d - razon: %s')", Player[id][ID],Player[playerid][Name],tiempo,razon);
		mysql_query(g_SQL, query);
    }
	return 1;
}
CMD:a(playerid,params[]){
    if(Player[playerid][IsLoggedIn] == false) return 1;
    if(Player[playerid][Admin] < AYUDANTE) return 1;
	new texto[124];

    if(sscanf(params, "s[124]", texto)) return SendClientMessage(playerid,-1,"Modo de uso: /a <texto>");
    {
        ChatAdmin(playerid,texto);
    }
	return 1;
}

//COMANDOS PARA EL DUEÑO:
CMD:darexs(playerid,params[]){
    if(Player[playerid][IsLoggedIn] == false) return 1;
    if(Player[playerid][Admin] < DUENO) return 1;
	new id,cantidad;

    if(sscanf(params, "dd", id,cantidad)) return SendClientMessage(playerid,-1,"Modo de uso: /darexs <ID> <CANTIDAD>");
    {
		if(cantidad <= 0) return SendClientMessage(playerid,-1,"Necesitas dar un cantidad positiva. Si deseas quitar use /quitarexs");
        if(!IsPlayerConnected(id)) return SendClientMessage(playerid,-1,"Jugador no conectado.");
        if(Player[id][IsLoggedIn] == false) return SendClientMessage(playerid,-1,"El jugador ingresado está ingresando.");
		DarEXS(id,cantidad);
		new string[88];
		format(string, sizeof(string),"{19D35B}Tus %d EXS, fueron acreditadas.",cantidad);
		SendClientMessage(id,-1,string);
		format(string, sizeof(string),"{19D35B}Le distes %d EXS al jugador %s.",cantidad,Player[id][Name]);
		SendClientMessage(playerid,-1,string);

    }
	return 1;
}
//COMANDOS SERVIDOR
CMD:kill(playerid, params[])
{
	if (Player[playerid][IsLoggedIn] == false) return 1;
	SetPlayerHealth(playerid,0);
	return 1;
	 
}
CMD:cuenta(playerid, params[])
{
	if (Player[playerid][IsLoggedIn] == false) return 1;
	MostrarDatosCuenta(playerid);
	return 1;

}
CMD:comandos(playerid, params[])
{
	if (Player[playerid][IsLoggedIn] == false) return 1;
	MostrarAyuda(playerid);
	return 1;

}
alias:comandos("ayuda")
CMD:config(playerid, params[])
{
	if (Player[playerid][IsLoggedIn] == false) return 1;
	MostrarConfig(playerid);
	return 1;

}
CMD:equipos(playerid, params[]){
    if (Player[playerid][IsLoggedIn] == false) return 1;
	if(EnBase[playerid] == false) return SendClientMessage(playerid,-1,"Necesitas estar en la base de tu equipo.");
	EnviarLobby(playerid);
	return 1;
}
alias:equipos("teams")
CMD:niveles(playerid, params[])
{
	if (Player[playerid][IsLoggedIn] == false) return 1;
	new str[706+1];
	format(str, sizeof(str), "%s{8690e0} Nivel 1 (Score 0):\t\t{FFFFFF}Desert Eagle\n{8690e0} Nivel 2 (Score 250):\t\t{FFFFFF}Desert Eagle | Escopeta | Chaleco: 10% \n{8690e0} Nivel ", str);
	format(str, sizeof(str), "%s3 (Score 500):\t\t{FFFFFF}Desert Eagle | SPAS | MP5 | Chaleco: 20% \n{8690e0} Nivel 4 (Score 750):\t\t{FFFFFF}Desert Eagle | SPAS | MP5 | AK-47| Chaleco: 30% \n{8690e0} Nivel 5 (Score 1500):\t\t{FFF", str);
	format(str, sizeof(str), "%sFFF}Desert Eagle | SPAS | MP5 | M4 | Chaleco: 40% \n{8690e0} Nivel 6 (Score 2050):\t\t{FFFFFF}Desert Eagle | SPAS | MP5 | M4 | Rifle | Chaleco: 50% \n{8690e0} Nivel 7 (Score 2600):\t\t{FFFFFF}Desert", str);
	format(str, sizeof(str), "%s Eagle | SPAS | MP5 | M4 | Sniper | Chaleco: 60% \n{8690e0} Nivel 8 (Score 3500):\t\t{FFFFFF}Desert Eagle | SPAS | MP5 | M4 | Rifle | Chaleco: 100% \n", str);

	ShowPlayerDialog(playerid, 5011, DIALOG_STYLE_MSGBOX, "{002BFF}• {FFFF00}• {FF0000}• {FFFFFF}Niveles", str, "Accept", "Cancel");
	return 1;

}
CMD:pagar(playerid,params[]){
    if (Player[playerid][IsLoggedIn] == false) return 1;
	new id,dinero;
    if(sscanf(params, "dd", id,dinero)) return SendClientMessage(playerid,-1,"Modo de uso: /pagar <ID> <Monto>");
	{
        if(dinero <= 0) { return SendClientMessage(playerid,-1,"No tienes esa cantidad de dinero."); }
    	if(Player[playerid][Dinero] < dinero) { return SendClientMessage(playerid,-1,"No tienes esa cantidad de dinero."); }
        if(Player[id][IsLoggedIn] == false) return SendClientMessage(playerid,-1,"El jugador ingresado está ingresando.");
        if(playerid == id) return SendClientMessage(playerid,-1,"No puedes pagarte a tí mismo.");
		DarDinero(id,dinero);
		QuitarDinero(playerid,dinero);
		new text[80];
		format(text, sizeof(text), "Le diste {00CC00}$%d {FFFFFF}a %s",dinero,Player[id][Name]);
		SendClientMessage(playerid,-1,text);
		format(text, sizeof(text), "%s te ha enviado {00CC00}$%d",Player[playerid][Name],dinero);
		SendClientMessage(id,-1,text);
		
		new query[221];
		mysql_format(g_SQL, query, sizeof query, "INSERT INTO `log_user` (`iduser`,`razon`) VALUES ('%d','Le diste $%d a %s')", Player[playerid][ID], dinero,Player[id][Name]);
		mysql_query(g_SQL, query);
        mysql_format(g_SQL, query, sizeof query, "INSERT INTO `log_user` (`iduser`,`razon`) VALUES ('%d','Recibistes $%d de %s')", Player[id][ID],dinero,Player[playerid][Name]);
		mysql_query(g_SQL, query);
    }
	return 1;
}

CMD:id(playerid, params[])
{
	new string[144], giveplayerid;
	if(sscanf(params, "r", giveplayerid)) return SendClientMessage(playerid, -1, "Modo de uso: /id <nombre/id>");

        else if (!IsPlayerConnected(giveplayerid)) SendClientMessage(playerid,-1,"No se encontró ningún jugador.");

		else
		{
		    new Hour, Minute, Second;
		    gettime(Hour, Minute, Second);
		    new Year, Month, Day;
			getdate(Year, Month, Day);
			format(string,sizeof(string),"%s {FFFFFF}| ID: {99A4FF}%d {FFFFFF}| {00FF27}FPS: {99A4FF}%d {FFFFFF}| Packetloss: {99A4FF}%.2f {FFFFFF}| Ping: {99A4FF}%d",Player[giveplayerid][Name],giveplayerid,GetPlayerFPS(giveplayerid),NetStats_PacketLossPercent(giveplayerid),GetPlayerPing(giveplayerid));
		    SendClientMessage(playerid,0x99A4FFFF,string);
		    format(string,sizeof(string),"Hora: {99A4FF}%02d:%02d:%02d {FFFFFF}| Fecha: {99A4FF}%02d/%02d/%d",Hour, Minute, Second,Day, Month, Year);
		    SendClientMessage(playerid,-1,string);

		}
	return 1;
}
CMD:exs(playerid,params[]){
    if (Player[playerid][IsLoggedIn] == false) return 1;
	new id,exs,precio;
    new string[144];
    if(sscanf(params, "ddd", id,exs,precio)) return SendClientMessage(playerid,-1,"Modo de uso: /exs <ID> <cantidad> <precio>");
    {
        if(exs <= 0) { return SendClientMessage(playerid,-1,"No tienes esa cantidad de EXS."); }
    	if(Player[playerid][EXS] < exs) { return SendClientMessage(playerid,-1,"No tienes esa cantidad de EXS."); }
    	if(!IsPlayerConnected(id)) return SendClientMessage(playerid,-1,"Jugador no conectado.");
    	
        if(Player[id][IsLoggedIn] == false) return SendClientMessage(playerid,-1,"El jugador ingresado está ingresando.");
        if(playerid == id) return SendClientMessage(playerid,-1,"No puedes pagarte a tí mismo.");
        if(TiempoOfertarEXS[playerid] > 0) {
        	format(string,sizeof(string),"Espera %d para volver a ofertar.",TiempoOfertarEXS[playerid]);
			return SendClientMessage(playerid,-1,string);
		}
        UltimaOferta__EXS[id] = exs;
        UltimaOferta__COSTO[id] = precio;
        UltimaOferta__TIME[id] = 30;
        UltimaOferta__USERID[id] = playerid;
        
        
        format(string,sizeof(string),"El usuario %s te ofrece {FFCD49}%d EXS {FFFFFF}por el precio de {59FF8A}$%d{FFFFFF}. Usa {FF7043}/aceptar EXS{FFFFFF}.",Player[playerid][Name],exs,precio);
        SendClientMessage(id,-1,string);
        SendClientMessage(id,-1,"Tienes 30 segundos para aceptar.");
        format(string,sizeof(string),"Ofrecistes {FFCD49}%d EXS {FFFFFF}al jugador %s por el precio de {59FF8A}$%d{FFFFFF}.",exs,Player[playerid][Name],precio);
        SendClientMessage(playerid,-1,string);
		TiempoOfertarEXS[playerid] = 20;
    }
	return 1;
}

CMD:aceptar(playerid,params[]){
    if (Player[playerid][IsLoggedIn] == false) return 1;
    new item[24];
    if(sscanf(params, "s[24]", item)) return SendClientMessage(playerid,-1,"Modo de uso: /aceptar <nombre>");
    {
        if(strcmp(item, "exs", true) == 0){
			
            if(UltimaOferta__TIME[playerid] == 0) return SendClientMessage(playerid,-1,"Nadie te a ofrecido EXS.");
            if(!IsPlayerConnected(UltimaOferta__USERID[playerid])) return SendClientMessage(playerid,-1,"El jugador que te ofreció no esta conectado.");
            if(Player[playerid][Dinero] < UltimaOferta__COSTO[playerid]) return SendClientMessage(playerid,-1,"No tienes el dinero para aceptar la oferta.");
            if(Player[UltimaOferta__USERID[playerid]][EXS] < UltimaOferta__EXS[playerid]) return SendClientMessage(playerid,-1,"El usuario ya no tienes esa cantidad de EXS ofrecidos.");
            new string[144];
            format(string,sizeof(string),"El usuario %s aceptó %d EXS al jugador %s por el precio de $%d",Player[playerid][Name],UltimaOferta__EXS[playerid],Player[UltimaOferta__USERID[playerid]][Name],UltimaOferta__COSTO[playerid]);
            LogToAdmin(string);
            QuitarDinero(playerid,UltimaOferta__COSTO[playerid]);
            DarDinero(UltimaOferta__USERID[playerid],UltimaOferta__COSTO[playerid]);
            DarEXS(playerid,UltimaOferta__EXS[playerid]);
            QuitarEXS(UltimaOferta__USERID[playerid],UltimaOferta__EXS[playerid]);
            
            SendClientMessage(UltimaOferta__USERID[playerid],-1,"{5DFF8D}La oferta fue aceptada.");
            UltimaOferta__EXS[playerid] = -1;
	        UltimaOferta__COSTO[playerid] = -1;
	        UltimaOferta__TIME[playerid] = -1;
	        UltimaOferta__USERID[playerid] = -1;
	        SendClientMessage(playerid,-1,"{5DFF8D}La oferta fue aceptada.");

	        
            
        }
        if(strcmp(item, "duelo", true) == 0){

			if(Duelo_temp_INVI_POR[playerid] <= 0) return SendClientMessage(playerid,-1,"Nadie te invitó a un duelo.");
			new string[144];
			format(string,sizeof(string),"El jugador %s aceptó el duelo contra %s",Player[playerid],Player[Duelo_temp_INVI_POR[playerid]][Name]);
			SendClientMessageToAll(-1,string);


        }
    }
	return 1;
}
alias:aceptar("acept")


alias:san("sancionar","jail")

CMD:mp(playerid,params[]){
    if(Player[playerid][IsLoggedIn] == false) return 1;
	new id,texto[124];

    if(sscanf(params, "ds[124]", id,texto)) return SendClientMessage(playerid,-1,"Modo de uso: /mp <ID> <Mensaje>");
    {
        if(!IsPlayerConnected(id)) return SendClientMessage(playerid,-1,"Jugador no conectado.");
        if(Player[id][IsLoggedIn] == false) return SendClientMessage(playerid,-1,"El jugador está ingresando.");
        if(playerid == id) return SendClientMessage(playerid,-1,"No puedes enviarte MP a tí mismo.");
        if(Player[playerid][MPsEstado] == false) return SendClientMessage(playerid,-1,"Tienes los mensajes privados desactivos. use /config.");
        if(Player[id][MPsEstado] == false) return SendClientMessage(playerid,-1,"Este usuario tiene los mensajes privados desactivados.");
		SendClientMessage(playerid,-1,"{8690e0}Mensaje privado enviado.");
		format(texto,sizeof(texto),"{8690e0}[MP de %s(ID: %d)]: {FFFFFF}%s ",Player[playerid][Name],playerid,texto);
		SendClientMessage(id,-1,texto);
    }
	return 1;
}

alias:mp("mensaje","privado")
CMD:duelo(playerid,params[]){
    if(Player[playerid][IsLoggedIn] == false) return 1;
    new id,apuesta;
    if(sscanf(params, "dd", id,apuesta)) return SendClientMessage(playerid,-1,"Modo de uso: /duelo <ID> <Apuesta>");
    {
        if(!IsPlayerConnected(id)) return SendClientMessage(playerid,-1,"Jugador no conectado.");
        if(Player[id][IsLoggedIn] == false) return SendClientMessage(playerid,-1,"El jugador está ingresando.");
        if(apuesta < 0) { return SendClientMessage(playerid,-1,"Debe ser un valor positivo, igual o mayor a 0."); }
    	if(Player[playerid][Dinero] < apuesta) { return SendClientMessage(playerid,-1,"No tienes esa cantidad de dinero."); }
        if(playerid == id) return SendClientMessage(playerid,-1,"No puedes enviarte Duelo a tí mismo.");
        if(Player[playerid][DuelosEstado] == false) return SendClientMessage(playerid,-1,"Tienes las invitaciones a duelos desactivados. use /config.");
        if(Player[id][DuelosEstado] == false) return SendClientMessage(playerid,-1,"Este usuario tiene las invitaciones a duelo desactivados.");
        if(Tiempo_Invitacion[playerid] > 0) return SendClientMessage(playerid,-1,"Ya tienes una invitación pendiente.");
        new str[590];
        Duelo_temp_USERID[playerid] = id;
		Duelo_temp_APUESTA[playerid] = apuesta;
    	format(str, sizeof(str), "{5FBEFD}• {FFFFFF}Campo de beisbol LV\n{5FBEFD}• {FFFFFF}Edificio LS\n{5FBEFD}• {FFFFFF}Campo de juego SF\n{5FBEFD}• {FFFFFF}Verdant bluffs\n{5FBEFD}• {FFFFFF}Castillo del diablo\n{5FBEFD}• {FFFFFF}The Camel Toe\n{5FBEFD}• {FFFFFF}Yellow bell\n{5FBEFD}• {FFFFFF}Area restringida\n{5FBEFD}• {FFFFFF}Liberty city");
		ShowPlayerDialog(playerid, DIALOG_LUGAR_DUELO, DIALOG_STYLE_TABLIST_HEADERS, "{002BFF}• {FFFF00}• {FF0000}• {FFFFFF}Lugar del duelo",str,"Elegir", "Cancelar");
		
		
    }
    return 1;
}

