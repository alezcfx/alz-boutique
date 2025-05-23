CREATE TABLE IF NOT EXISTS player_boutique (
    identifier VARCHAR(50) PRIMARY KEY,
    credits INT DEFAULT 0
);

CREATE TABLE IF NOT EXISTS purchase_history (
    id INT AUTO_INCREMENT PRIMARY KEY,
    identifier VARCHAR(50) NOT NULL,
    item_name VARCHAR(50) NOT NULL,
    item_label VARCHAR(50) NOT NULL,
    price INT NOT NULL,
    purchase_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS pending_items (
    id INT AUTO_INCREMENT PRIMARY KEY,
    identifier VARCHAR(50) NOT NULL,
    category VARCHAR(50) NOT NULL,
    item_name VARCHAR(50) NOT NULL,
    item_label VARCHAR(50) NOT NULL,
    quantity INT NOT NULL DEFAULT 1,
    price INT NOT NULL,
    purchase_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS boutique_admins (
    id INT AUTO_INCREMENT PRIMARY KEY,
    identifier VARCHAR(50) NOT NULL UNIQUE,
    added_by VARCHAR(50) NOT NULL,
    added_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
