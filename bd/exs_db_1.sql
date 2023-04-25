-- phpMyAdmin SQL Dump
-- version 5.2.0
-- https://www.phpmyadmin.net/
--
-- Servidor: 127.0.0.1
-- Tiempo de generación: 12-12-2022 a las 14:29:51
-- Versión del servidor: 10.4.24-MariaDB
-- Versión de PHP: 7.4.29

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de datos: `exs_db`
--

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `log_user`
--

CREATE TABLE `log_user` (
  `id` int(11) NOT NULL,
  `iduser` int(11) NOT NULL,
  `razon` text NOT NULL DEFAULT 'No especificada',
  `fecha` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Volcado de datos para la tabla `log_user`
--

INSERT INTO `log_user` (`id`, `iduser`, `razon`, `fecha`) VALUES
(1, 3, 'Le diste $800 a Amahel_Rodrigues', '2022-11-23 13:24:58'),
(2, 4, 'Recibistes $800 de XxxxxxO', '2022-11-23 13:24:58'),
(3, 4, 'Le diste $11 a Amahel_Rodrigues', '2022-11-23 13:25:40'),
(4, 4, 'Recibistes $11 de Amahel_Rodrigues', '2022-11-23 13:25:40'),
(5, 3, 'Le diste $11 a Amahel_Rodrigues', '2022-11-23 13:29:04'),
(6, 4, 'Recibistes $11 de XxxxxxO', '2022-11-23 13:29:04'),
(7, 3, 'Le diste $2 a Amahel_Rodrigues', '2022-11-23 15:02:42'),
(8, 4, 'Recibistes $2 de XxxxxxO', '2022-11-23 15:02:42'),
(9, 4, 'Le diste $513 a XxxxxxO', '2022-11-23 15:03:07'),
(10, 3, 'Recibistes $513 de Amahel_Rodrigues', '2022-11-23 15:03:07'),
(11, 3, 'Sancionado por XxxxxxO Tiempo: 120 - raz?n feo', '2022-11-23 18:00:44'),
(12, 3, 'Sancionado por XxxxxxO Tiempo: 5 - razon: pruebas', '2022-11-23 18:10:06'),
(13, 2, 'Sancionado por Natazho_Lyonne Tiempo: 120 - razon: Feo', '2022-11-23 21:26:42'),
(14, 2, 'Sancionado por Natazho_Lyonne Tiempo: 0 - razon: liberar', '2022-11-23 21:28:59'),
(15, 4, 'Sancionado por XxxxxxO Tiempo: 1000 - razon: feo', '2022-11-26 12:00:58'),
(16, 2, 'Le diste $10000 a Amahel_Rodrigues', '2022-11-26 16:16:01'),
(17, 4, 'Recibistes $10000 de Natazho_Lyonne', '2022-11-26 16:16:01'),
(18, 2, 'Le diste $100000 a Amahel_Rodrigues', '2022-11-26 16:18:35'),
(19, 4, 'Recibistes $100000 de Natazho_Lyonne', '2022-11-26 16:18:35'),
(20, 2, 'Le diste $100000 a Amahel_Rodrigues', '2022-11-26 16:18:39'),
(21, 4, 'Recibistes $100000 de Natazho_Lyonne', '2022-11-26 16:18:39'),
(22, 2, 'Le diste $28717 a Amahel_Rodrigues', '2022-11-26 16:18:46'),
(23, 4, 'Recibistes $28717 de Natazho_Lyonne', '2022-11-26 16:18:46'),
(24, 2, 'Le diste $1000000 a Amahel_Rodrigues', '2022-11-26 16:18:51'),
(25, 4, 'Recibistes $1000000 de Natazho_Lyonne', '2022-11-26 16:18:51'),
(26, 2, 'Sancionado por Natazho_Lyonne Tiempo: 120 - razon: guapo', '2022-11-26 16:37:54'),
(27, 2, 'Sancionado por Natazho_Lyonne Tiempo: 0 - razon: guapo', '2022-11-26 16:38:20'),
(28, 4, 'Sancionado por Natazho_Lyonne Tiempo: 10 - razon: feo mmverga', '2022-11-26 16:48:54'),
(29, 2, 'Sancionado por Natazho_Lyonne Tiempo: 1 - razon: feo', '2022-11-26 16:55:04'),
(30, 2, 'Sancionado por Natazho_Lyonne Tiempo: 5 - razon: feo', '2022-11-26 16:55:14'),
(31, 2, 'Sancionado por Natazho_Lyonne Tiempo: 5 - razon: feo', '2022-11-26 16:55:24');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `log_user_team`
--

CREATE TABLE `log_user_team` (
  `id` int(11) NOT NULL,
  `user_id` int(11) DEFAULT NULL,
  `team_id` int(11) DEFAULT NULL,
  `kills` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Volcado de datos para la tabla `log_user_team`
--

INSERT INTO `log_user_team` (`id`, `user_id`, `team_id`, `kills`) VALUES
(1, 3, 1, 36);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `players`
--

CREATE TABLE `players` (
  `id` int(11) NOT NULL,
  `username` varchar(24) NOT NULL,
  `password` char(64) NOT NULL,
  `e_correo` varchar(128) DEFAULT NULL,
  `rankadmin` int(2) NOT NULL DEFAULT 0,
  `Dinero` int(11) NOT NULL DEFAULT 0,
  `Score` int(11) NOT NULL DEFAULT 0,
  `salt` char(16) NOT NULL,
  `kills` mediumint(8) NOT NULL DEFAULT 0,
  `deaths` mediumint(8) NOT NULL DEFAULT 0,
  `interior` tinyint(3) NOT NULL DEFAULT 0,
  `u_team` int(2) NOT NULL DEFAULT 0,
  `u_rank` int(1) NOT NULL DEFAULT 0,
  `d_ganados` int(11) NOT NULL DEFAULT 0,
  `d_perdidos` int(11) NOT NULL DEFAULT 0,
  `e_ganados` int(11) NOT NULL DEFAULT 0,
  `CasaID` int(11) NOT NULL DEFAULT 0,
  `EXS` int(11) NOT NULL,
  `Piezas` int(11) NOT NULL DEFAULT 0,
  `Skin` int(4) NOT NULL DEFAULT -1,
  `DuelosEstado` tinyint(1) NOT NULL DEFAULT 0,
  `MPsEstado` tinyint(1) NOT NULL DEFAULT 0,
  `SpawnHouseEstado` tinyint(1) NOT NULL DEFAULT 0,
  `InfoRankEstado` tinyint(1) NOT NULL DEFAULT 0,
  `MusicEventEstado` tinyint(1) NOT NULL DEFAULT 0,
  `EstadoDesert` tinyint(1) NOT NULL DEFAULT 1,
  `EstadoEscopeta` tinyint(1) NOT NULL DEFAULT 1,
  `EstadoSPAS` tinyint(1) NOT NULL DEFAULT 1,
  `EstadoMP5` tinyint(1) NOT NULL DEFAULT 1,
  `EstadoAK47` tinyint(1) NOT NULL DEFAULT 1,
  `EstadoM4` tinyint(1) NOT NULL DEFAULT 1,
  `EstadoRifle` tinyint(1) NOT NULL DEFAULT 1,
  `EstadoSniper` tinyint(1) NOT NULL DEFAULT 1,
  `EstadoBate` tinyint(1) NOT NULL DEFAULT 1,
  `EstadoKatana` tinyint(1) NOT NULL DEFAULT 1,
  `EstadoMotosierra` tinyint(1) NOT NULL DEFAULT 1,
  `EstadoGranada` tinyint(1) NOT NULL DEFAULT 1,
  `EstadoGranadaDH` tinyint(1) NOT NULL DEFAULT 1,
  `ClimaID` int(11) NOT NULL DEFAULT 0,
  `HoraID` int(11) NOT NULL,
  `TiempoSAN` int(11) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Volcado de datos para la tabla `players`
--

INSERT INTO `players` (`id`, `username`, `password`, `e_correo`, `rankadmin`, `Dinero`, `Score`, `salt`, `kills`, `deaths`, `interior`, `u_team`, `u_rank`, `d_ganados`, `d_perdidos`, `e_ganados`, `CasaID`, `EXS`, `Piezas`, `Skin`, `DuelosEstado`, `MPsEstado`, `SpawnHouseEstado`, `InfoRankEstado`, `MusicEventEstado`, `EstadoDesert`, `EstadoEscopeta`, `EstadoSPAS`, `EstadoMP5`, `EstadoAK47`, `EstadoM4`, `EstadoRifle`, `EstadoSniper`, `EstadoBate`, `EstadoKatana`, `EstadoMotosierra`, `EstadoGranada`, `EstadoGranadaDH`, `ClimaID`, `HoraID`, `TiempoSAN`) VALUES
(1, 'Angel', '53C0C365485AD0BBEC1BACFE355B530130CF46766FDD06CE5F9DDCAD30555C99', '@asdasd.com', 0, 0, 0, ']{ug*l}O\"n/.-s8>', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0),
(2, 'Natazho_Lyonne', '55692D7D6E40D5416057071C3243181D37CD78C61E02F6B7E8D49C1DB500A314', 'asdasdasd', 5, 3512, 5028, '/pj9;6xG}<esjH}2', 28, 1, 0, 0, 0, 0, 0, 0, 0, 990, 0, -1, 0, 1, 0, 1, 0, 1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 20, 0),
(3, 'XxxxxxO', 'F7A5F705B412637612240FBDA446EDFF5DECB412A3FF93E6CC49B492EAD8A113', 'asd@.com', 5, 29650, 38, 'Hl:OJ[`e\"*|!=cLD', 56, 23, 0, 1, 0, 0, 0, 0, 0, 0, 0, -1, 1, 0, 0, 1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 5, 12, 0),
(4, 'MartinZ', 'FB7AFD52BCA43C859D74353B009A672C3E6EA436E6D36337AF1DEC8CC14ECA07', 'angel@.', 0, 1245005, 22, 'Q_y>+0du+`]>erbC', 24, 84, 0, 0, 0, 0, 0, 0, 0, 30, 0, -1, 1, 0, 0, 1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 12, 0);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `teams`
--

CREATE TABLE `teams` (
  `id` int(11) NOT NULL,
  `nombre` varchar(40) NOT NULL DEFAULT 'No asignado',
  `KillsTotal` int(11) NOT NULL DEFAULT 0,
  `estado` int(11) NOT NULL DEFAULT 1,
  `fecha_creacion` date NOT NULL DEFAULT current_timestamp(),
  `Rango1` varchar(24) NOT NULL,
  `Rango2` varchar(24) NOT NULL,
  `Rango3` varchar(24) NOT NULL,
  `Rango4` varchar(24) NOT NULL,
  `Rango5` varchar(24) NOT NULL,
  `salida_x` float NOT NULL,
  `salida_y` float NOT NULL,
  `salida_z` float NOT NULL,
  `Color` varchar(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Volcado de datos para la tabla `teams`
--

INSERT INTO `teams` (`id`, `nombre`, `KillsTotal`, `estado`, `fecha_creacion`, `Rango1`, `Rango2`, `Rango3`, `Rango4`, `Rango5`, `salida_x`, `salida_y`, `salida_z`, `Color`) VALUES
(1, 'Los FauX', 41, 1, '2022-11-21', 'a', 'b', 'c', 'd', 'e', 0, 0, 0, 'FFFF00'),
(2, 'Los gorditos', 200, 1, '2022-11-21', 'a', 'b', 'c', 'd', 'e', 0, 0, 0, '00FFFF');

--
-- Índices para tablas volcadas
--

--
-- Indices de la tabla `log_user`
--
ALTER TABLE `log_user`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `log_user_team`
--
ALTER TABLE `log_user_team`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `players`
--
ALTER TABLE `players`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `username` (`username`);

--
-- Indices de la tabla `teams`
--
ALTER TABLE `teams`
  ADD PRIMARY KEY (`id`);

--
-- AUTO_INCREMENT de las tablas volcadas
--

--
-- AUTO_INCREMENT de la tabla `log_user`
--
ALTER TABLE `log_user`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=32;

--
-- AUTO_INCREMENT de la tabla `log_user_team`
--
ALTER TABLE `log_user_team`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT de la tabla `players`
--
ALTER TABLE `players`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT de la tabla `teams`
--
ALTER TABLE `teams`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
