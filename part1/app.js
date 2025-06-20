var express = require('express');
var path = require('path');
var cookieParser = require('cookie-parser');
var logger = require('morgan');
var mysql = require('mysql2/promise');

var app = express();

app.use(logger('dev'));
app.use(express.json());
app.use(express.urlencoded({ extended: false }));
app.use(cookieParser());

let db;

(async () => {
  try {
    // Connect to MySQL without specifying a database
    const connection = await mysql.createConnection({
      host: 'localhost',
      user: 'root',
      password: '' // Set your MySQL root password
    });

    // Create the database if it doesn't exist
    await connection.query('CREATE DATABASE IF NOT EXISTS DogWalkService');
    await connection.end();

    // Now connect to the created database
    db = await mysql.createConnection({
      host: 'localhost',
      user: 'root',
      password: '',
      database: 'DogWalkService'
    });

    // Create a table if it doesn't exist
    await db.execute(`
      CREATE TABLE IF NOT EXISTS Users (
        user_id INT AUTO_INCREMENT PRIMARY KEY,
        username VARCHAR(50) UNIQUE NOT NULL,
        email VARCHAR (100) UNIQUE NOT NULL,
        password_hash VARCHAR(255) NOT NULL,
        role ENUM('owner', 'walker') NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);

    await db.execute(`
      CREATE TABLE IF NOT EXISTS Dogs (
        dog_id INT AUTO_INCREMENT PRIMARY KEY,
        owner_id INT NOT NULL,
        name VARCHAR(50) NOT NULL,
        size ENUM('small', 'medium', 'large') NOT NULL,
        FOREIGN KEY (owner_id) REFERENCES Users(user_id)
      )
    `);

    await db.execute(`
      CREATE TABLE IF NOT EXISTS WalkRequests  (
        request_id  INT AUTO_INCREMENT PRIMARY KEY,
        dog_id INT NOT NULL,
        requested_time DATETIME NOT NULL,
        duration_minutes INT NOT NULL,
        location VARCHAR(255) NOT NULL,
        status ENUM('open', 'accepted', 'completed', 'cancelled') DEFAULT 'open',
        FOREIGN KEY (dog_id) REFERENCES Dogs(dog_id)
      )
    `);

    await db.execute(`
      CREATE TABLE IF NOT EXISTS WalkApplications  (
        application_id INT AUTO_INCREMENT PRIMARY KEY,
        request_id INT NOT NULL,
        walker_id INT NOT NULL,
        applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        status ENUM('pending', 'accepted', 'rejected') DEFAULT 'pending',
        FOREIGN KEY (request_id) REFERENCES WalkRequests(request_id),
        FOREIGN KEY (walker_id) REFERENCES Users(dog_id),
        CONSTRAINT unique_application UNIQUE (request_id, walker_id)
      )
    `);

    await db.execute(`
      CREATE TABLE IF NOT EXISTS WalkRatings  (
        rating_id  INT AUTO_INCREMENT PRIMARY KEY,
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
      )
    `);


    // Insert data if table is empty
    const [userRows] = await db.execute('SELECT COUNT(*) AS count FROM Users');
    if (userRows[0].count === 0) {
      // insert users
      await db.execute(`
        INSERT INTO Users (username, email, password_hash, role) VALUES
        ('alice123', 'alice@example.com', 'hashed123', 'owner'),
        ('bobwalker', 'bob@example.com', 'hashed456', 'walker'),
        ('carol123', 'carol@example.com', 'hashed789', 'owner'),
        ('jarrydwong', 'jarryd@example.com', 'hashed321', 'walker'),
        ('veronica123', 'veronica@example.com', 'hashed654', 'owner')
      `);

      // insert dogs
      await db.execute(`
        INSERT INTO Dogs (owner_id, name, size) VALUES
        ((SELECT user_id FROM Users WHERE username = 'alice123'), 'Max', 'medium'),
        ((SELECT user_id FROM Users WHERE username = 'carol123'), 'Bella', 'small'),
        ((SELECT user_id FROM Users WHERE username = 'carol123'), 'Pacup', 'medium'),
        ((SELECT user_id FROM Users WHERE username = 'carol123'), 'Paris', 'small'),
        ((SELECT user_id FROM Users WHERE username = 'veronica123'), 'Doggo', 'large')
      `);

      // insert walk requests
      await db.execute(`
        INSERT INTO WalkRequests (dog_id, requested_time, duration_minutes, location, status) VALUES
        ((SELECT dog_id FROM Dogs WHERE name = 'Max'), '2025-06-10 08:00:00', 30, 'Parklands', 'open'),
        ((SELECT dog_id FROM Dogs WHERE name = 'Bella'), '2025-06-10 09:30:00', 45, 'Beachside Ave', 'accepted'),
        ((SELECT dog_id FROM Dogs WHERE name = 'Pacup'), '2025-06-10 10:30:00', 60, 'Parklands', 'open'),
        ((SELECT dog_id FROM Dogs WHERE name = 'Paris'), '2025-06-10 11:30:00', 45, 'Parklands', 'open'),
        ((SELECT dog_id FROM Dogs WHERE name = 'Doggo'), '2025-06-08 12:00:00', 60, 'SomeBeach', 'completed')
      `);

    }
  } catch (err) {
    console.error('Error setting up database. Ensure Mysql is running: service mysql start', err);
  }
})();

// Route 1 for /api/dogs
app.get('/api/dogs', async (req, res) => {
  try {
    const [dogs] = await db.execute(`
        SELECT
            d.name as dog_name,
            d.size,
            u.username as owner_username
      FROM Dogs d
      JOIN Users u ON d.owner_id = u.user_id
      ORDER BY d.name
    `);
    res.json(dogs);
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch dogs' });
  }
});

// Route 2 for /api/walkrequests/open
app.get('/api/walkrequests/open', async (req, res) => {
  try {
    const [requests] = await db.execute(`
        SELECT
            wr.request_id,
            d.name as dog_name,
            wr.requested_time,
            wr.duration_minutes,
            wr.location,
            u.username as owner_username
        FROM WalkRequests wr
        JOIN Dogs d ON wr.dog_id = d.dog_id
        JOIN Users u ON d.owner_id = u.user_id
        WHERE wr.status = 'open'
        ORDER BY wr.requested_time
    `);
    res.json(requests);
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch open walk requests' });
  }
});

// Route 3: /api/walkers/summary - Return walker summary with ratings and completed walks
app.get('/api/walkers/summary', async (req, res) => {
  try {
    const [walkers] = await db.execute(`
        SELECT
            u.username as walker_username,
            COALESCE(COUNT(wr.rating_id), 0) as total_ratings,
            CASE
                WHEN COUNT(wr.rating_id) > 0 THEN ROUND(AVG(wr.rating), 1)
                ELSE NULL
            END as average_rating,
            COALESCE(completed_walks.walk_count, 0) as completed_walks
        FROM Users u
        LEFT JOIN WalkRatings wr ON u.user_id = wr.walker_id
        LEFT JOIN (
            SELECT
                wa.walker_id,
                COUNT(*) as walk_count
            FROM WalkApplications wa
            JOIN WalkRequests wreq ON wa.request_id = wreq.request_id
            WHERE wa.status = 'accepted' AND wreq.status = 'completed'
            GROUP BY wa.walker_id
      ) completed_walks ON u.user_id = completed_walks.walker_id
      WHERE u.role = 'walker'
      GROUP BY u.user_id, u.username, completed_walks.walk_count
      ORDER BY u.username
    `);
    res.json(walkers);
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch walker summary' });
  }
});

app.use(express.static(path.join(__dirname, 'public')));

module.exports = app;