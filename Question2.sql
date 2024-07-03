CREATE TABLE Measurements (
    Lot_No TEXT,
    Unit TEXT,
    Product_Code TEXT,
  	T_Height REAL,
  	T_Weight REAL
);

CREATE TABLE ProductionSequence (
    Order_ID INTEGER,
    Date TEXT,
    Product_Family TEXT,
    Variant TEXT
);

CREATE TABLE Specifications (
    Product_Code TEXT,
    T_Name TEXT,
    LSL REAL,
    USL REAL,
    Target REAL
);

INSERT INTO Specifications (Product_Code, T_Name, LSL, USL, Target) VALUES
('LIF001_B', 'T_height', 7.22, 10.57, 8.78),
('LIF001_Y', 'T_height', 6.78, 10.07, 8.36),
('LIF002_R', 'T_height', 7.22, 10.57, 8.78),
('LIF002_Y', 'T_height', 6.78, 10.07, 8.36),
('LIF001_B', 'T_weight', 360, 470, 410),
('LIF001_Y', 'T_weight', 329, 500, 410),
('LIF002_R', 'T_weight', 329, 500, 385),
('LIF002_Y', 'T_weight', 329, 500, 410);

INSERT INTO Measurements (Lot_No, Unit, Product_Code, T_Height, T_Weight) VALUES
('DLS0081', 1, 'LIF001_B', 8.644, 384.63),
('DLS0081', 2, 'LIF001_B', 9.228, 384.63),
('DLS0081', 3, 'LIF001_B', 8.811, 385.19),
('DLS0081', 4, 'LIF001_B', 9.08, 385.19),
('DLS0082', 1, 'LIF001_Y', 10.549, 375),
('DLS0082', 2, 'LIF001_Y', 10.524, 378.89),
('DLS0082', 3, 'LIF001_Y', 9.028, 386.11),
('DLS0082', 4, 'LIF001_Y', 10.973, 391.3),
('DNM0021', 1, 'LIF002_R', 10.571, 289.19),
('DNM0021', 2, 'LIF002_R', 8.7, 320.43),
('DNM0021', 3, 'LIF002_R', 8.652, 323.2),
('DNM0021', 4, 'LIF002_R', 9.308, 326.07),
('DNM0022', 1, 'LIF002_Y', 8.455, 516.11),
('DNM0022', 2, 'LIF002_Y', 7.521, 521.48),
('DNM0022', 3, 'LIF002_Y', 8.301, 526.48),
('DNM0022', 4, 'LIF002_Y', 8.482, 531.11);

INSERT INTO ProductionSequence (Order_ID, Date, Product_Family, Variant) VALUES
(1, '5/14/2022', 'LIF001', 'B'),
(2, '6/2/2022', 'LIF001', 'Y'),
(3, '6/17/2022', 'LIF001', 'B'),
(4, '7/1/2022', 'LIF003', 'B'),
(5, '7/17/2022', 'LIF002', 'R'),
(6, '8/5/2022', 'LIF002', 'Y'),
(7, '8/19/2022', 'LIF002', 'G'),
(8, '9/1/2022', 'LIF001', 'G'),
(9, '9/15/2022', 'LIF002', 'Y');


/*Question 2.1*/

/*Grouping by product code and calculating the mean and sample standard deviation for height and weight*/

SELECT 
    Product_Code,
    AVG(T_Height) AS Mean_Height,
    SQRT(SUM((T_Height - Mean_Height)*(T_Height - Mean_Height)) / (COUNT(*) - 1)) AS Std_Dev_Height, /*calculating sample std*/
    AVG(T_Weight) AS Mean_Weight,
    SQRT(SUM((T_Weight - Mean_Weight)*(T_Weight - Mean_Weight)) / (COUNT(*) - 1)) AS Std_Dev_Weight
FROM (
    SELECT /*calculating the mean height and weight for each product code in the inner query*/
        Product_Code,
        T_Height,
        T_Weight,
        AVG(T_Height) OVER (PARTITION BY Product_Code) AS Mean_Height,
        AVG(T_Weight) OVER (PARTITION BY Product_Code) AS Mean_Weight
    FROM 
        Measurements
) AS sub
GROUP BY Product_Code;



/*Question 2.2*/


WITH Defects AS (  /*creating the CTE*/
    SELECT 
        ps.Product_Family,
        m.Unit,
        CASE 		/*checking for defects based on USL*/
            WHEN s.T_Name = 'T_height' AND m.T_Height > s.USL THEN 1 
            WHEN s.T_Name = 'T_weight' AND m.T_Weight > s.USL THEN 1 
            ELSE 0 
        END AS Is_Defect
    FROM Measurements m
    JOIN Specifications s ON m.Product_Code = s.Product_Code /*joining the specification table on */
    JOIN (
        SELECT DISTINCT 	/*selecting distinct product family and variant to avoid redundancy in counting defects*/
            Product_Family,
            Variant
        FROM ProductionSequence
    ) ps ON m.Product_Code LIKE ps.Product_Family || '_' || ps.Variant || '%'  /*joining Measurements table to productionSequence to check if product code matches*/
)
SELECT 
    Product_Family,
    SUM(Is_Defect) AS Defect_Count	/*selecting product family and summing up the Is_Defect values*/ 
FROM Defects
GROUP BY Product_Family             /*grouping the result by product family*/
ORDER BY Defect_Count DESC;        /*ordering the result in descending order by Defect_Count*/


/*Q3*/

WITH Defects AS (   /*creating the CTE*/
    SELECT 
        ps.Product_Family,
        m.Lot_No,
        CASE 			/*checking for defects based on USL*/
            WHEN s.T_Name = 'T_height' AND m.T_Height > s.USL THEN 1 
            WHEN s.T_Name = 'T_weight' AND m.T_Weight > s.USL THEN 1 
            ELSE 0 
        END AS Is_Defect
    FROM Measurements m
    JOIN Specifications s ON m.Product_Code = s.Product_Code 
    JOIN (
        SELECT DISTINCT     /*selecting distinct product family and variant to avoid redundancy in counting defects*/
            Product_Family,
            Variant
        FROM ProductionSequence
    ) ps ON m.Product_Code LIKE ps.Product_Family || '_' || ps.Variant || '%'  
)	/*joining Measurements table to productionSequence and matching product code with product family and variant*/																		
SELECT             
    Product_Family,
    Lot_No,
    SUM(Is_Defect) AS Defect_Count
FROM Defects
GROUP BY Product_Family, Lot_No  /*grouping the result by product family*/
ORDER BY Defect_Count DESC;      /*ordering the result in descending order by Defect_Count*/


