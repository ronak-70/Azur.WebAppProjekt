-- Run this script in Azure SQL Query Editor or Azure Data Studio
-- after creating your Azure SQL Database

CREATE TABLE Items (
    id          INT IDENTITY(1,1) PRIMARY KEY,
    name        NVARCHAR(255) NOT NULL,
    description NVARCHAR(1000),
    created_at  DATETIME2 DEFAULT GETDATE()
);

-- Insert sample data
INSERT INTO Items (name, description) VALUES
    ('Sample Item 1', 'This is the first test item'),
    ('Sample Item 2', 'This is the second test item');

-- Verify
SELECT * FROM Items;
