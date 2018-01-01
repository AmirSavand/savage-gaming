-- players

CREATE TABLE `players` (
 `id` int(11) NOT NULL AUTO_INCREMENT,
 `name` varchar(50) NOT NULL,
 `money` int(11) NOT NULL DEFAULT '0',
 `admin` int(11) NOT NULL DEFAULT '0',
 `rank` int(11) NOT NULL DEFAULT '0',
 `kills` int(11) NOT NULL DEFAULT '0',
 PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- cars

CREATE TABLE `cars` (
 `id` int(11) NOT NULL AUTO_INCREMENT,
 `type` int(11) NOT NULL DEFAULT '1',
 `owner` int(11) NOT NULL DEFAULT '0',
 `price` int(11) NOT NULL DEFAULT '0',
 `model` int(11) NOT NULL,
 `engine` int(11) NOT NULL DEFAULT '1000',
 `comps` varchar(100) NOT NULL DEFAULT '0 0 0 0 0 0 0 0 0 0 0 0 0',
 `colors` varchar(50) NOT NULL DEFAULT '-1 -1 -1',
 `x` float NOT NULL,
 `y` float NOT NULL,
 `z` float NOT NULL,
 `a` float NOT NULL,
 PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- items

CREATE TABLE `items` (
 `player` int(11) NOT NULL,
 `item` int(11) NOT NULL,
 `count` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- perks

CREATE TABLE `perks` (
 `player` int(11) NOT NULL,
 `perk` int(11) NOT NULL,
 `status` tinyint(1) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1
