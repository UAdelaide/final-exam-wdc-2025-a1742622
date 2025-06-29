DROP DATABASE IF EXISTS DogWalkService;
CREATE DATABASE DogWalkService;
USE DogWalkService;
CREATE TABLE Users (                                    -- stores all USERS
    user_id INT AUTO_INCREMENT PRIMARY KEY,             -- Unique ID for each person
    username VARCHAR(50) UNIQUE NOT NULL,               -- username
    email VARCHAR(100) UNIQUE NOT NULL,                 -- email
    password_hash VARCHAR(255) NOT NULL,                -- encrypted password storage
    role ENUM('owner', 'walker') NOT NULL,              -- user's role whether they are a "walker" or an "owner"
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP      -- records when account was made/
);

CREATE TABLE Dogs (                                     -- stores all DOGS
    dog_id INT AUTO_INCREMENT PRIMARY KEY,              -- Unique id for each dog
    owner_id INT NOT NULL,                              -- which user owns the dog (Links to users table)
    name VARCHAR(50) NOT NULL,                          -- dog name
    size ENUM('small', 'medium', 'large') NOT NULL,     -- dog size (small, med or lrg)
    FOREIGN KEY (owner_id) REFERENCES Users(user_id)    -- FK. to ensure all dogs must have a user
);

CREATE TABLE WalkRequests (                             -- stores when owners need somone to walk their dog
    request_id INT AUTO_INCREMENT PRIMARY KEY,          -- Unique ID for each wqalk request
    dog_id INT NOT NULL,                                -- which dog needs walking (Links to dog table)
    requested_time DATETIME NOT NULL,                   -- when walk was requested
    duration_minutes INT NOT NULL,                      -- how long the walk was
    location VARCHAR(255) NOT NULL,                     -- location of dog?
    status ENUM('open', 'accepted', 'completed', 'cancelled') DEFAULT 'open',   -- status of walk request
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,     -- records when request was created
    FOREIGN KEY (dog_id) REFERENCES Dogs(dog_id)        -- FK. to link back to a specific dog
);

CREATE TABLE WalkApplications (                         -- stores when walkers want to walk an owners dog
    application_id INT AUTO_INCREMENT PRIMARY KEY,      -- Uniqie ID for each walk request
    request_id INT NOT NULL,                            -- which walk request is being applied ot (links to walkRequest table)
    walker_id INT NOT NULL,                             -- which walker is applyinhg
    applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,     -- when walk was requested
    status ENUM('pending', 'accepted', 'rejected') DEFAULT 'pending',   -- status of walk applcation
    FOREIGN KEY (request_id) REFERENCES WalkRequests(request_id),       -- FK. walk request actually exists
    FOREIGN KEY (walker_id) REFERENCES Users(user_id),                  -- FK. walk request connects to a user
    CONSTRAINT unique_application UNIQUE (request_id, walker_id)        -- walker cannot apply to the same reuqest twice
);

CREATE TABLE WalkRatings (                                              -- stores all WALKRATINGS
    rating_id INT AUTO_INCREMENT PRIMARY KEY,                           -- Unique ID for each rating
    request_id INT NOT NULL,                                            -- which request is being rated (links to request table)
    walker_id INT NOT NULL,                                             -- which walker is being rated (links to walker table)
    owner_id INT NOT NULL,                                              -- which owner is being rated (links to owner table)
    rating INT CHECK (rating BETWEEN 1 AND 5),                          -- the rating
    comments TEXT,                                                      -- the comment
    rated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,                       -- created at
    FOREIGN KEY (request_id) REFERENCES WalkRequests(request_id),       -- FK. walk being completed
    FOREIGN KEY (walker_id) REFERENCES Users(user_id),                  -- FK. walker who walked the dog
    FOREIGN KEY (owner_id) REFERENCES Users(user_id),                   -- FK. Dow owner giving the rating
    CONSTRAINT unique_rating_per_walk UNIQUE (request_id)               -- each walk can only have 1 rating
);



-- Adding new data for question 5

-- Users:
INSERT INTO Users (username, email, password_hash, role) VALUES
('alice123', 'alice@example.com', 'hashed123', 'owner'),
('bobwalker', 'bob@example.com', 'hashed456', 'walker'),
('carol123', 'carol@example.com', 'hashed789', 'owner'),
('jarrydwong', 'jarryd@example.com', 'hashed321', 'walker'),
('veronica123', 'veronica@example.com', 'hashed654', 'owner');

-- Dogs:
INSERT INTO Dogs (owner_id, name, size) VALUES
((SELECT user_id FROM Users WHERE username = 'alice123'), 'Max', 'medium'),
((SELECT user_id FROM Users WHERE username = 'carol123'), 'Bella', 'small'),
((SELECT user_id FROM Users WHERE username = 'carol123'), 'Pacup', 'medium'),
((SELECT user_id FROM Users WHERE username = 'carol123'), 'Paris', 'small'),
((SELECT user_id FROM Users WHERE username = 'veronica123'), 'Doggo', 'large');

-- Wallk Requests:
INSERT INTO WalkRequests (dog_id, requested_time, duration_minutes, location, status) VALUES
((SELECT dog_id FROM Dogs WHERE name = 'Max'), '2025-06-10 08:00:00', 30, 'Parklands', 'open'),
((SELECT dog_id FROM Dogs WHERE name = 'Bella'), '2025-06-10 09:30:00', 45, 'Beachside Ave', 'accepted'),
((SELECT dog_id FROM Dogs WHERE name = 'Pacup'), '2025-06-10 10:30:00', 60, 'Beachside Ave', 'open'),
((SELECT dog_id FROM Dogs WHERE name = 'Paris'), '2025-06-10 11:30:00', 45, 'Beachside Ave', 'open'),
((SELECT dog_id FROM Dogs WHERE name = 'Doggo'), '2025-06-08 12:00:00', 60, 'SomeBeach', 'completed');