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
    request_id INT NOT NULL,                                            -- which request id request is being applied ot (links to walkRequest table)
    walker_id INT NOT NULL,
    owner_id INT NOT NULL,
    rating INT CHECK (rating BETWEEN 1 AND 5),
    comments TEXT,
    rated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (request_id) REFERENCES WalkRequests(request_id),
    FOREIGN KEY (walker_id) REFERENCES Users(user_id),
    FOREIGN KEY (owner_id) REFERENCES Users(user_id),
    CONSTRAINT unique_rating_per_walk UNIQUE (request_id)
);