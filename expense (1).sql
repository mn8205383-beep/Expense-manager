-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Oct 27, 2026 at 07:58 PM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `expense`
--

DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`phpforpr`@`localhost` PROCEDURE `get_user_authorities_sp` (IN `_userId` VARCHAR(250) CHARSET utf8)   BEGIN

SELECT category.role       AS role,
       system_links.id     AS link_id,
       system_actions.id   AS action_id
FROM user_authority
LEFT JOIN system_links   ON user_authority.action = system_links.id
LEFT JOIN category       ON system_links.category_id = category.id
LEFT JOIN system_actions ON system_actions.link_id = system_links.id
WHERE user_authority.user_id = _userId;

END$$

CREATE DEFINER=`phpforpr`@`localhost` PROCEDURE `get_user_menu_sp` (IN `_userId` VARCHAR(250) CHARSET utf8)   BEGIN

SELECT category.id   AS category_id,
       category.name AS category_name,
       category.role AS role,
       system_links.id   AS link_id,
       system_links.name AS link_name,system_links.link
FROM user_authority
LEFT JOIN system_links ON user_authority.action = system_links.id
LEFT JOIN category     ON system_links.category_id = category.id
WHERE user_authority.user_id = _userId
GROUP BY system_links.id
ORDER BY category.role, system_links.id;

END$$

CREATE DEFINER=`phpforpr`@`localhost` PROCEDURE `get_user_statement_sp` (IN `_userId` VARCHAR(50) CHARSET utf8, IN `_from` DATE, IN `_to` DATE)   BEGIN
set @tbalance = 0;
set @expense = 0;
set @income = 0;
if(_from  = '0000-00-00')THEN

CREATE TEMPORARY TABLE tb SELECT expense.date,expense.user_id,
if(type = 'income',amount,0)income,
if(type = 'expense',amount,0)'expense',
if(type = 'income',@tbalance:=@tbalance+amount,@tbalance:=@tbalance-amount)
'Balance'
FROM expense WHERE expense.user_id = _userId ORDER by expense.date ASC;
SELECT * FROM tb
UNION
SELECT '','',sum(income),sum(expense),@tbalance FROM tb;
ELSE
CREATE TEMPORARY TABLE tb SELECT expense.date,expense.user_id,
if(type = 'income',amount,0)income,
if(type = 'expense',amount,0)'expense',
if(type = 'income',@tbalance:=@tbalance+amount,@tbalance:=@tbalance-amount)
'Balance'
FROM expense WHERE expense.user_id = _userId AND expense.date 
BETWEEN _from and _to ORDER by expense.date ASC;
SELECT * FROM tb
UNION
SELECT '','',sum(income),SUM(expense),@tbalance FROM tb;
END if;
END$$

CREATE DEFINER=`phpforpr`@`localhost` PROCEDURE `login_sp` (IN `_username` VARCHAR(250) CHARSET utf8, IN `_password` VARCHAR(250) CHARSET utf8)   BEGIN
if EXISTS(SELECT * FROM users WHERE users.username =_username 
 AND users.password = MD5(_password)) THEN 
  
 IF EXISTS( SELECT * FROM users WHERE users.username = _username
  AND users.status = 'Active')  THEN
  SELECT * FROM users WHERE users.username = _username;
  
  ELSE
  SELECT 'Locked'Msg;
 END IF;
 
 
 ELSE
 
 SELECT 'Deny'Msg;
 END IF;




END$$

CREATE DEFINER=`phpforpr`@`localhost` PROCEDURE `register_expense_sp` (IN `_id` INT, IN `_amount` FLOAT(11,2), IN `_type` VARCHAR(50) CHARSET utf8, IN `_desc` TEXT CHARSET utf8, IN `_userId` VARCHAR(50) CHARSET utf8)   BEGIN

if EXISTS(SELECT*FROM expense WHERE expense.id=_id)THEN
UPDATE expense SET expense.amount =_amount, expense.type =_type,
expense.description = _desc WHERE expense.id = _id;
SELECT 'Updated' as message;

ELSE

if(_type = 'expense')THEN
if((SELECT get_user_balance_fn(_userId) < _amount))THEN
SELECT 'Deny' as message;

ELSE

INSERT INTO expense(expense.amount,expense.type,expense.description,expense.user_id)
VALUES(_amount,_type,_desc,_userId);

SELECT'Registered'as message;


END if;

ELSE
INSERT INTO expense(expense.amount,expense.type,expense.description,expense.user_id)
VALUES(_amount,_type,_desc,_userId);

SELECT'Registered'as message;
END if;
END if;
END$$

--
-- Functions
--
CREATE DEFINER=`phpforpr`@`localhost` FUNCTION `get_user_balance_fn` (`_userId` VARCHAR(250) CHARSET utf8) RETURNS FLOAT(11,2)  BEGIN
SET @balance = 0.00;
SET @income= (SELECT SUM(expense.amount)FROM expense WHERE expense.type
= 'income' AND expense.user_id= _userId);

SET @expense= (SELECT SUM(expense.amount)FROM expense WHERE expense.type
= 'expense' AND expense.user_id= _userId);

SET @balance = (ifnull(@income,0) - ifnull(@expense,0));
RETURN @balance;


END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `category`
--

CREATE TABLE `category` (
  `id` int(11) NOT NULL,
  `name` varchar(250) NOT NULL,
  `icon` varchar(50) NOT NULL,
  `role` varchar(250) NOT NULL,
  `date` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `category`
--

INSERT INTO `category` (`id`, `name`, `icon`, `role`, `date`) VALUES
(16, 'super ', 'FA-HOME', 'SuperAdmin', '2026-10-04 11:17:22'),
(17, 'subscriber', 'FA-HOME', 'Subscriber', '2026-10-08 16:58:17'),
(18, 'Dashboard', 'FA-HOME', 'Dashboard', '2026-10-14 16:39:13');

-- --------------------------------------------------------

--
-- Table structure for table `expense`
--

CREATE TABLE `expense` (
  `id` int(11) NOT NULL,
  `amount` float(11,2) NOT NULL,
  `type` varchar(15) NOT NULL,
  `description` text NOT NULL,
  `user_id` varchar(50) NOT NULL,
  `date` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `expense`
--

INSERT INTO `expense` (`id`, `amount`, `type`, `description`, `user_id`, `date`) VALUES
(120, 5.00, 'income', 'BARBER ( TIMO JARIS)', 'USR001', '2026-09-16 06:48:18'),
(121, 12.00, 'income', 'from ajax', 'USR001', '2026-09-16 11:24:54'),
(122, 3.00, 'income', 'cunto', 'USR001', '2026-09-16 13:25:58'),
(123, 20.00, 'expense', 'from ajax', 'USR001', '2026-09-16 13:28:28'),
(126, 0.00, '', '', 'USR001', '2026-09-24 15:36:37'),
(127, 0.00, '', '', 'USR001', '2026-09-24 15:36:42');

-- --------------------------------------------------------

--
-- Table structure for table `system_actions`
--

CREATE TABLE `system_actions` (
  `id` int(11) NOT NULL,
  `name` varchar(250) NOT NULL,
  `action` varchar(250) NOT NULL,
  `link_id` int(11) NOT NULL,
  `date` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `system_actions`
--

INSERT INTO `system_actions` (`id`, `name`, `action`, `link_id`, `date`) VALUES
(4, 'Update users', 'update_user', 39, '2026-10-07 17:51:21'),
(5, 'Register Users', ' register_user', 39, '2026-10-08 17:31:23'),
(6, 'Delete User', ' delete_user_info', 39, '2026-10-08 17:32:54'),
(7, 'Dashboard', 'Dashboard', 42, '2026-10-08 17:33:42'),
(8, 'Register Expense', 'register_expense', 43, '2026-10-08 17:35:42'),
(9, 'Update Expense', 'update_expense', 43, '2026-10-08 17:36:36'),
(10, 'Delete Expense', 'delete_expense_info', 43, '2026-10-08 17:38:45'),
(11, 'Register Category', 'register_category', 44, '2026-10-08 17:42:41'),
(12, 'Update Category', ' update_category', 44, '2026-10-08 17:44:42'),
(13, 'Delete Category', ' delete_category_info', 44, '2026-10-08 17:45:14'),
(14, 'User Authority', 'read_system_authroties', 48, '2026-10-08 17:48:44'),
(15, 'Register System Action', 'register_system_action', 45, '2026-10-22 10:52:25'),
(16, 'Register System Link', 'register_link', 46, '2026-10-22 10:55:39'),
(17, 'User Statement', 'get_user_statement', 47, '2026-10-22 10:59:41');

-- --------------------------------------------------------

--
-- Stand-in structure for view `system_authority`
-- (See below for the actual view)
--
CREATE TABLE `system_authority` (
`id` int(11)
,`category` varchar(250)
,`icon` varchar(50)
,`role` varchar(250)
,`link_id` int(11)
,`name` varchar(250)
,`action_id` int(11)
,`action_name` varchar(250)
);

-- --------------------------------------------------------

--
-- Table structure for table `system_links`
--

CREATE TABLE `system_links` (
  `id` int(11) NOT NULL,
  `name` varchar(250) NOT NULL,
  `link` varchar(250) NOT NULL,
  `category_id` int(11) NOT NULL,
  `date` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `system_links`
--

INSERT INTO `system_links` (`id`, `name`, `link`, `category_id`, `date`) VALUES
(39, 'user', 'user.php', 16, '2026-10-07 12:09:48'),
(42, 'Dashboard', 'dashboad.php', 18, '2026-10-08 17:10:08'),
(43, 'Expense', 'expense.php', 17, '2026-10-08 17:21:02'),
(44, 'Category', 'category.php', 16, '2026-10-08 17:22:20'),
(45, 'System Actions', 'system_actions.php', 16, '2026-10-08 17:23:09'),
(46, 'System Links', 'system_links.php', 16, '2026-10-08 17:26:55'),
(47, 'User statement', 'user_statement.php', 17, '2026-10-08 17:27:46'),
(48, 'User Authority', 'user_authority.php', 16, '2026-10-08 17:28:40');

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `id` varchar(250) NOT NULL,
  `username` varchar(250) NOT NULL,
  `password` varchar(250) NOT NULL,
  `status` varchar(250) NOT NULL DEFAULT 'Active',
  `image` varchar(250) NOT NULL,
  `date` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`id`, `username`, `password`, `status`, `image`, `date`) VALUES
('USR001', 'SUBWAY', '202cb962ac59075b964b07152d234b70', 'Active', 'USR001.png', '2026-09-29 12:00:05'),
('USR002', 'mohamed nour ahmed', '202cb962ac59075b964b07152d234b70', 'Active', 'USR002.png', '2026-10-17 18:38:23'),
('USR003', 'mc dev3123', '202cb962ac59075b964b07152d234b70', 'Active', 'USR003.png', '2026-10-22 17:34:57');

-- --------------------------------------------------------

--
-- Table structure for table `user_authority`
--

CREATE TABLE `user_authority` (
  `id` int(11) NOT NULL,
  `user_id` varchar(15) NOT NULL,
  `action` varchar(250) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `user_authority`
--

INSERT INTO `user_authority` (`id`, `user_id`, `action`) VALUES
(1, 'USR001', '42'),
(2, 'USR001', '43'),
(3, 'USR001', '47'),
(4, 'USR001', '39'),
(5, 'USR001', '44'),
(6, 'USR001', '45'),
(7, 'USR001', '46'),
(8, 'USR001', '48'),
(9, 'USR001', '42'),
(10, 'USR001', '43'),
(11, 'USR001', '47'),
(12, 'USR001', '39'),
(13, 'USR001', '44'),
(14, 'USR001', '45'),
(15, 'USR001', '46'),
(16, 'USR001', '48'),
(17, 'USR001', '42'),
(18, 'USR001', '43'),
(19, 'USR001', '47'),
(20, 'USR001', '39'),
(21, 'USR001', '44'),
(22, 'USR001', '45'),
(23, 'USR001', '46'),
(24, 'USR001', '48'),
(25, 'USR002', '42'),
(26, 'USR002', '43'),
(27, 'USR002', '47'),
(28, 'USR002', '39'),
(29, 'USR002', '44'),
(30, 'USR002', '45'),
(31, 'USR002', '46'),
(32, 'USR002', '48');

-- --------------------------------------------------------

--
-- Structure for view `system_authority`
--
DROP TABLE IF EXISTS `system_authority`;

CREATE ALGORITHM=UNDEFINED DEFINER=`phpforpr`@`localhost` SQL SECURITY DEFINER VIEW `system_authority`  AS SELECT `category`.`id` AS `id`, `category`.`name` AS `category`, `category`.`icon` AS `icon`, `category`.`role` AS `role`, `system_links`.`id` AS `link_id`, `system_links`.`name` AS `name`, `system_actions`.`id` AS `action_id`, `system_actions`.`name` AS `action_name` FROM ((`category` left join `system_links` on(`category`.`id` = `system_links`.`category_id`)) left join `system_actions` on(`system_links`.`id` = `system_actions`.`link_id`)) ORDER BY `category`.`role` ASC, `system_links`.`id` ASC, `system_actions`.`id` ASC ;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `category`
--
ALTER TABLE `category`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `expense`
--
ALTER TABLE `expense`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `system_actions`
--
ALTER TABLE `system_actions`
  ADD PRIMARY KEY (`id`),
  ADD KEY `action_link` (`link_id`);

--
-- Indexes for table `system_links`
--
ALTER TABLE `system_links`
  ADD PRIMARY KEY (`id`),
  ADD KEY `system_link_category` (`category_id`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `username` (`username`);

--
-- Indexes for table `user_authority`
--
ALTER TABLE `user_authority`
  ADD PRIMARY KEY (`id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `category`
--
ALTER TABLE `category`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=21;

--
-- AUTO_INCREMENT for table `expense`
--
ALTER TABLE `expense`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=128;

--
-- AUTO_INCREMENT for table `system_actions`
--
ALTER TABLE `system_actions`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=18;

--
-- AUTO_INCREMENT for table `system_links`
--
ALTER TABLE `system_links`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=49;

--
-- AUTO_INCREMENT for table `user_authority`
--
ALTER TABLE `user_authority`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=33;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `system_actions`
--
ALTER TABLE `system_actions`
  ADD CONSTRAINT `action_link` FOREIGN KEY (`link_id`) REFERENCES `system_links` (`id`) ON UPDATE CASCADE;

--
-- Constraints for table `system_links`
--
ALTER TABLE `system_links`
  ADD CONSTRAINT `system_link_category` FOREIGN KEY (`category_id`) REFERENCES `category` (`id`) ON UPDATE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
