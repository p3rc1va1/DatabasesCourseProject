--Databases course project
--1
-- Creating the tables based on the schema
CREATE TABLE Books (
    BookID INT IDENTITY(1,1) PRIMARY KEY,
    ISBN VARCHAR(13) NOT NULL UNIQUE,
    Title VARCHAR(255) NOT NULL,
    AuthorID INT NOT NULL,
    GenreID INT NOT NULL,
    Price DECIMAL(10, 2) NOT NULL,
    StockQuantity INT NOT NULL,
    FOREIGN KEY (AuthorID) REFERENCES Authors(AuthorID),
    FOREIGN KEY (GenreID) REFERENCES Genres(GenreID)
);

CREATE TABLE Authors (
    AuthorID INT IDENTITY(1,1) PRIMARY KEY,
    Name VARCHAR(255) NOT NULL,
    Bio TEXT
);

CREATE TABLE Customers (
    CustomerID INT IDENTITY(1,1) PRIMARY KEY,
    Name VARCHAR(255) NOT NULL,
    Email VARCHAR(255) NOT NULL UNIQUE,
    Phone VARCHAR(20),
    Address TEXT
);

CREATE TABLE Orders (
    OrderID INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID INT NOT NULL,
    OrderDate DATETIME NOT NULL DEFAULT GETDATE(),
    TotalAmount DECIMAL(10, 2),
    FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID)
);

CREATE TABLE OrderDetails (
    OrderDetailID INT IDENTITY(1,1) PRIMARY KEY,
    OrderID INT NOT NULL,
    BookID INT NOT NULL,
    Quantity INT NOT NULL,
    Price DECIMAL(10, 2) NOT NULL,
    FOREIGN KEY (OrderID) REFERENCES Orders(OrderID),
    FOREIGN KEY (BookID) REFERENCES Books(BookID)
);

CREATE TABLE Genres (
    GenreID INT IDENTITY(1,1) PRIMARY KEY,
    GenreName VARCHAR(255) NOT NULL UNIQUE
);

--2
-- to fill in with some data totally not ai generated xD
INSERT INTO Authors (Name, Bio)
VALUES 
('J.K. Rowling', 'British author, best known for the Harry Potter series.'),
('George R.R. Martin', 'American novelist and short story writer in the fantasy genre.'),
('J.R.R. Tolkien', 'English writer, poet, and academic, best known for The Lord of the Rings.');

INSERT INTO Genres (GenreName)
VALUES 
('Fantasy'), 
('Science Fiction'), 
('Mystery'), 
('Non-Fiction');

INSERT INTO Books (ISBN, Title, AuthorID, GenreID, Price, StockQuantity)
VALUES 
('9780747532743', 'Harry Potter and the Philosophers Stone', 1, 1, 19.99, 50),
('9780553103540', 'A Game of Thrones', 2, 1, 24.99, 40),
('9780345339706', 'The Fellowship of the Ring', 3, 1, 15.99, 60),
('9780140449136', 'The Art of War', 2, 4, 12.99, 20);

INSERT INTO Customers (Name, Email, Phone, Address)
VALUES 
('Alice Smith', 'alice.smith@example.com', '123-456-7890', '123 Elm Street, Springfield'),
('Bob Johnson', 'bob.johnson@example.com', '987-654-3210', '456 Oak Street, Shelbyville'),
('Carol White', 'carol.white@example.com', '555-555-5555', '789 Pine Street, Capital City');

INSERT INTO Orders (CustomerID, OrderDate, TotalAmount)
VALUES 
(1, '2024-12-01', 49.98),
(2, '2024-12-02', 15.99),
(3, '2024-12-03', 24.99);

INSERT INTO OrderDetails (OrderID, BookID, Quantity, Price)
VALUES 
(1, 1, 2, 19.99),
(2, 3, 1, 15.99),
(3, 2, 1, 24.99);


SELECT * FROM Authors

-- to delete a row
DELETE FROM Authors
Where AuthorID = 2;

-- to delete a table
TRUNCATE TABLE Authors;

--3
-- to sort books by ascending price and descending title
SELECT *
FROM Books
ORDER BY Price ASC, Title DESC;

-- Aggregate Functions
SELECT 
    COUNT(OrderID) AS TotalOrders,
    SUM(TotalAmount) AS TotalRevenue,
    AVG(TotalAmount) AS AverageOrderAmount
FROM Orders;

-- Pagination
SELECT *
FROM Books
ORDER BY Title ASC
OFFSET 0 ROWS FETCH NEXT 5 ROWS ONLY;

-- Total number of books grouped by genre
SELECT 
    G.GenreName,
    COUNT(B.BookID) AS TotalBooks
FROM Genres G
LEFT JOIN Books B ON G.GenreID = B.GenreID
GROUP BY G.GenreName
ORDER BY TotalBooks DESC;


--4
--inner join 
-- Retrieve books with their authors
SELECT B.Title AS BookTitle, A.Name AS AuthorName
FROM Books B
INNER JOIN Authors A ON B.AuthorID = A.AuthorID;

--left join 
-- Retrieve all authors and the books they have written
SELECT A.Name AS AuthorName, B.Title AS BookTitle
FROM Authors A
LEFT JOIN Books B ON A.AuthorID = B.AuthorID;

--Right join 
-- Retrieve all books and their authors
SELECT B.Title AS BookTitle, A.Name AS AuthorName
FROM Books B
RIGHT JOIN Authors A ON B.AuthorID = A.AuthorID;

--join three tables 
-- Retrieve customer orders with book titles and total order amounts
SELECT C.Name AS CustomerName, O.OrderDate, B.Title AS BookTitle, OD.Quantity, OD.Price
FROM Customers C
INNER JOIN Orders O ON C.CustomerID = O.CustomerID
INNER JOIN OrderDetails OD ON O.OrderID = OD.OrderID
INNER JOIN Books B ON OD.BookID = B.BookID;

--create a view 
-- Create a view for customer orders with book details
CREATE VIEW CustomerOrdersView AS
SELECT C.Name AS CustomerName, O.OrderDate, B.Title AS BookTitle, OD.Quantity, OD.Price
FROM Customers C
INNER JOIN Orders O ON C.CustomerID = O.CustomerID
INNER JOIN OrderDetails OD ON O.OrderID = OD.OrderID
INNER JOIN Books B ON OD.BookID = B.BookID;

SELECT * FROM CustomerOrdersView;

--5
-- Stored Procedure to generate a sales report for a specific date range
CREATE PROCEDURE GenerateSalesReport
    @StartDate DATE,
    @EndDate DATE
AS
BEGIN
    SELECT O.OrderID, C.Name AS CustomerName, O.OrderDate, SUM(OD.Quantity * OD.Price) AS TotalOrderAmount
    FROM Orders O
    INNER JOIN Customers C ON O.CustomerID = C.CustomerID
    INNER JOIN OrderDetails OD ON O.OrderID = OD.OrderID
    WHERE O.OrderDate BETWEEN @StartDate AND @EndDate
    GROUP BY O.OrderID, C.Name, O.OrderDate
    ORDER BY O.OrderDate;
END;

-- function to calculate the total stock value of books
CREATE FUNCTION CalculateTotalStockValue()
RETURNS DECIMAL(18,2)
AS
BEGIN
    DECLARE @TotalValue DECIMAL(18,2);
    SELECT @TotalValue = SUM(Price * StockQuantity) FROM Books;
    RETURN @TotalValue;
END;

-- sql trigger to update stock quantity when a new order is placed
CREATE TRIGGER UpdateStockQuantity
ON OrderDetails
AFTER INSERT
AS
BEGIN
    UPDATE B
    SET B.StockQuantity = B.StockQuantity - I.Quantity
    FROM Books B
    INNER JOIN INSERTED I ON B.BookID = I.BookID;
END;

-- Manual transaction to handle order processing
BEGIN TRANSACTION;

-- Insert a new order
DECLARE @NewOrderID INT;
INSERT INTO Orders (CustomerID, OrderDate, TotalAmount)
VALUES (1, GETDATE(), 100.00);

-- Get the newly created OrderID
SET @NewOrderID = SCOPE_IDENTITY();

-- Insert details for the new order
INSERT INTO OrderDetails (OrderID, BookID, Quantity, Price)
VALUES (@NewOrderID, 1, 2, 50.00);

-- Check for errors and commit or rollback
IF @@ERROR = 0
    COMMIT TRANSACTION;
ELSE
    ROLLBACK TRANSACTION;





