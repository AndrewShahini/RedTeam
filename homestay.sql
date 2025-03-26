-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: localhost
-- Generation Time: Mar 24, 2025 at 05:57 PM
-- Server version: 10.4.28-MariaDB
-- PHP Version: 8.2.4

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `homestay`
--

-- --------------------------------------------------------

--
-- Table structure for table `CLIENT`
--

CREATE TABLE `CLIENT` (
  `clientId` int(11) NOT NULL,
  `firstName` varchar(20) NOT NULL,
  `lastName` varchar(20) NOT NULL,
  `email` varchar(50) NOT NULL CHECK (`email` regexp '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$'),
  `password` varchar(15) NOT NULL,
  `phoneNumber` varchar(10) NOT NULL,
  `dateOfBirth` date NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `CLIENT`
--
ALTER TABLE `CLIENT`
  ADD PRIMARY KEY (`clientId`),
  ADD UNIQUE KEY `phoneNumber` (`phoneNumber`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;


 CREATE TABLE REVIEW(
  reviewID INT NOT NULL,
  clientID INT NOT NULL,
  Rating INT CHECK (Rating >= 0 AND Rating <= 5) NOT NULL,
  Comment VARCHAR (50) NOT NULL,
  Date DATE NOT NULL
  );


  ALTER TABLE REVIEW
  ADD PRIMARY KEY (reviewID);

  ALTER TABLE REVIEW
  ADD FOREIGN KEY (clientID) REFERENCES CLIENT(clientID);

  CREATE TABLE BOOKING(
  bookingID INT NOT NULL PRIMARY KEY,
  clientID INT NOT NULL FOREIGN KEY REFERENCES CLIENT(clientID),
  startDate DATE NOT NULL,
  endDate DATE NOT NULL,
  total DECIMAL (7,2) NOT NULL,
  numberOfPeople INT CHECK (numberOfPeople >=1) NOT NULL,
  note varchar(50)
  );


CREATE TRIGGER trg_check_booking_dates_insert
ON BOOKING
INSTEAD OF INSERT
AS
BEGIN
 
  IF EXISTS (
    SELECT 1
    FROM inserted
    WHERE endDate <= startDate
  )
  BEGIN
    RAISERROR('endDate must be later than startDate.', 16, 1);
    ROLLBACK;
    RETURN;
  END

  
  INSERT INTO BOOKING (bookingID, clientID, startDate, endDate, total, numberOfPeople, note)
  SELECT bookingID, clientID, startDate, endDate, total, numberOfPeople, note
  FROM inserted;
END;

CREATE TABLE PAYMENT(
paymentID INT NOT NULL PRIMARY KEY,
bookingID INT FOREIGN KEY REFERENCES BOOKING(bookingID) NOT NULL,
paidAmount DECIMAL (7, 2) NOT NULL,
paymentDate DATE NOT NULL,
paymentMethod VARCHAR (20) CHECK (paymentMethod IN ('credit', 'e-transfer'))
);

--Create trigger to see if payment date between start date and end date 
CREATE TRIGGER trg_payment_insert
ON PAYMENT
INSTEAD OF INSERT
AS
BEGIN

  IF EXISTS (
    SELECT 1
    FROM inserted i
    JOIN BOOKING b ON i.BookingID = b.bookingID
    WHERE i.PaymentDate < b.startDate OR i.PaymentDate > b.endDate
  )
  BEGIN
    RAISERROR('PaymentDate must be within booking period.', 16, 1);
    ROLLBACK;
    RETURN;
  END

  IF EXISTS (
    SELECT 1
    FROM inserted i
    JOIN BOOKING b ON i.BookingID = b.bookingID
    WHERE i.PaidAmount > b.total
  )
  BEGIN
    RAISERROR('Paid amount cannot be greater than booking total.', 16, 1);
    ROLLBACK;
    RETURN;
  END

  UPDATE b
  SET b.total = b.total - i.PaidAmount
  FROM BOOKING b
  JOIN inserted i ON b.bookingID = i.BookingID;

  INSERT INTO PAYMENT (PaymentID, BookingID, PaidAmount, PaymentDate, PaymentMethod)
  SELECT PaymentID, BookingID, PaidAmount, PaymentDate, PaymentMethod
  FROM inserted;
END;



CREATE TABLE DESCRIPTION(
descriptionID INT NOT NULL PRIMARY KEY,
description VARCHAR(100) NOT NULL
);

CREATE TABLE IMAGES(
imageID INT NOT NULL PRIMARY KEY,
imageLink VARCHAR NOT NULL,
description VARCHAR (100)
);

CREATE TABLE DESCRIPTION_IMAGES (
descriptionID INT NOT NULL,
imageID INT NOT NULL,
PRIMARY KEY (descriptionID, imageID),
FOREIGN KEY (descriptionID) REFERENCES DESCRIPTION(descriptionID),
FOREIGN KEY (imageID) REFERENCES IMAGES(imageID)
);


CREATE TABLE ADMIN (
adminID INT PRIMARY KEY,
email VARCHAR NOT NULL UNIQUE CHECK (email LIKE '%@%.%'),
password VARCHAR CHECK (LEN(password) >= 8) NOT NULL 
);