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
    owner_id INT NOT NULL,                              -- Links which user owns the dog (Via FK to users table)
    name VARCHAR(50) NOT NULL,                          -- dog name
    size ENUM('small', 'medium', 'large') NOT NULL,     -- dog size (small, med or lrg)
    FOREIGN KEY (owner_id) REFERENCES Users(user_id)    -- FK. to ensure all dogs must have a user
);

CREATE TABLE WalkRequests (
    request_id INT AUTO_INCREMENT PRIMARY KEY,
    dog_id INT NOT NULL,
    requested_time DATETIME NOT NULL,
    duration_minutes INT NOT NULL,
    location VARCHAR(255) NOT NULL,
    status ENUM('open', 'accepted', 'completed', 'cancelled') DEFAULT 'open',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (dog_id) REFERENCES Dogs(dog_id)
);

CREATE TABLE WalkApplications (
    application_id INT AUTO_INCREMENT PRIMARY KEY,
    request_id INT NOT NULL,
    walker_id INT NOT NULL,
    applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status ENUM('pending', 'accepted', 'rejected') DEFAULT 'pending',
    FOREIGN KEY (request_id) REFERENCES WalkRequests(request_id),
    FOREIGN KEY (walker_id) REFERENCES Users(user_id),
    CONSTRAINT unique_application UNIQUE (request_id, walker_id)
);

CREATE TABLE WalkRatings (
    rating_id INT AUTO_INCREMENT PRIMARY KEY,
    request_id INT NOT NULL,
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