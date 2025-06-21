const express = require('express');
const router = express.Router();
const db = require('../models/db');

// GET all users (for admin/testing)
router.get('/', async (req, res) => {
  try {
    const [rows] = await db.query('SELECT user_id, username, email, role FROM Users');
    res.json(rows);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch users' });
  }
});

// GET logged-in user's dogs                          [ADDED FOR QUESTION 15]
router.get('/my-dogs', async (req, res) => {
  try {
    if (!req.session.user) {
      return res.status(401).json({ error: 'Not logged in' });
    }

    const [rows] = await db.query(`
      SELECT dog_id, name FROM Dogs
      WHERE owner_id = ?
    `, [req.session.user.user_id]);

    res.json(rows);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch dogs' });
  }
});


// GET just dogs for the home page table              [ADDED FOR QUESTION 17]
router.get('/dogs', async (req, res) => {
  try {
    const [dogs] = await db.execute(`
      SELECT
        d.dog_id,
        d.name as dog_name,
        d.size,
        d.owner_id,
        u.username as owner_username
      FROM Dogs d
      JOIN Users u ON d.owner_id = u.user_id
      ORDER BY d.dog_id
    `);
    res.json(dogs);
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch dogs' });
  }
});

// POST a new user (simple signup)
router.post('/register', async (req, res) => {
  const { username, email, password, role } = req.body;

  try {
    const [result] = await db.query(`
      INSERT INTO Users (username, email, password_hash, role)
      VALUES (?, ?, ?, ?)
    `, [username, email, password, role]);

    res.status(201).json({ message: 'User registered', user_id: result.insertId });
  } catch (error) {
    res.status(500).json({ error: 'Registration failed' });
  }
});

router.get('/me', (req, res) => {
  if (!req.session.user) {
    return res.status(401).json({ error: 'Not logged in' });
  }
  res.json(req.session.user);
});

// POST login                                         [QUESTION 13 VERSION]
router.post('/login', async (req, res) => {
  const { email, password } = req.body;

  try {
    const [rows] = await db.query(`
      SELECT user_id, username, role FROM Users
      WHERE email = ? AND password_hash = ?
    `, [email, password]);

    if (rows.length === 0) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    // Store user in session                          [added for QUESTION 13]
    req.session.user = rows[0];

    res.json({
      message: 'Login successful',
      user: rows[0],
      redirectTo: rows[0].role === 'owner' ? '/owner-dashboard.html' : '/walker-dashboard.html' // Redirect section added too
    });
  } catch (error) {
    res.status(500).json({ error: 'Login failed' });
  }
});

// POST logout                                        [added for QUESTION 14]
router.post('/logout', (req, res) => {
  req.session.destroy((err) => {
    if (err) {
      return res.status(500).json({ error: 'Logout failed' });
    }
    res.clearCookie('connect.sid'); // this clears the session cookie
    res.json({ message: 'Logout successful' });
  });
});

module.exports = router;